package com.homesweethome.service;

import com.homesweethome.dto.PetEntryRequest;
import com.homesweethome.entity.*;
import com.homesweethome.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import java.time.*;
import java.util.*;

@Service
@RequiredArgsConstructor
public class PetEntryService {
    private static final Set<String> KINDS = Set.of("VACCINATION", "HEALTH", "MEDICATION", "WEIGHT", "VET");
    private final PetEntryRepository entries;
    private final PetAccessService petAccess;
    private final FamilyAccessService familyAccess;
    private final FamilyRepository families;
    private final FamilyMemberRepository members;
    private final GlobalTaskRepository tasks;
    private final GlobalTaskService taskService;

    public List<PetEntry> list(UUID petId, String kind) {
        petAccess.require(petId);
        validKind(kind);
        return entries.findByPetIdAndKindOrderByRecordDateDesc(petId, kind);
    }
    public PetEntry get(UUID petId, String kind, UUID entryId) {
        petAccess.require(petId);
        validKind(kind);
        return entries.findByIdAndPetIdAndKind(entryId, petId, kind)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Pet record not found"));
    }
    @Transactional
    public PetEntry save(UUID petId, String kind, UUID entryId, PetEntryRequest request) {
        Pet pet = petAccess.require(petId);
        validKind(kind);
        PetEntry entry = entryId == null ? new PetEntry() : get(petId, kind, entryId);
        if (entryId == null) {
            entry.setPetId(petId); entry.setFamilyId(pet.getFamilyId()); entry.setKind(kind);
            entry.setCreatedAt(Instant.now());
        }
        entry.setTitle(required(request.title(), 255, "A record title is required"));
        entry.setRecordType(optional(request.recordType(), 32));
        entry.setRecordDate(request.recordDate());
        entry.setNextDueDate(request.nextDueDate());
        entry.setAppointmentAt(request.appointmentAt());
        entry.setDescription(optional(request.description(), 2000));
        entry.setDiagnosisTreatment(optional(request.diagnosisTreatment(), 2000));
        entry.setVeterinarian(optional(request.veterinarian(), 255));
        entry.setClinic(optional(request.clinic(), 255));
        entry.setNotes(optional(request.notes(), 2000));
        entry.setDosage(optional(request.dosage(), 255));
        entry.setFrequency(optional(request.frequency(), 255));
        entry.setStartDate(request.startDate());
        entry.setEndDate(request.endDate());
        entry.setInstructions(optional(request.instructions(), 2000));
        entry.setWeightKg(request.weightKg());
        entry.setAssignedMemberId(request.assignedMemberId());
        entry.setReminderTask(Boolean.TRUE.equals(request.reminderTask()));
        if (request.assignedMemberId() != null) requireMember(request.assignedMemberId(), pet.getFamilyId());
        if (entry.getWeightKg() != null && (!Double.isFinite(entry.getWeightKg()) || entry.getWeightKg() <= 0 || entry.getWeightKg() > 10000))
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Weight must be positive");
        if (entry.getStartDate() != null && entry.getEndDate() != null && entry.getEndDate().isBefore(entry.getStartDate()))
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "End date precedes start date");
        switch (kind) {
            case "VACCINATION" -> {
                if (entry.getRecordDate() == null) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Administration date is required");
                if (entry.getNextDueDate() != null && entry.getNextDueDate().isBefore(entry.getRecordDate()))
                    throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Next due date precedes administration");
                entry.setStatus("COMPLETED");
            }
            case "HEALTH" -> {
                if (entry.getRecordDate() == null) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Record date is required");
                if (entry.getRecordType() == null) entry.setRecordType("OTHER");
                if (entry.getRecordType() == null || !Set.of("ALLERGY", "CONDITION", "ILLNESS", "TREATMENT", "OTHER").contains(entry.getRecordType()))
                    throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Choose a valid health record type");
                entry.setStatus(null);
            }
            case "MEDICATION" -> {
                if (entry.getDosage() == null || entry.getFrequency() == null || entry.getStartDate() == null)
                    throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Dosage, frequency and start date are required");
                entry.setStatus(null);
            }
            case "WEIGHT" -> {
                if (entry.getRecordDate() == null || entry.getWeightKg() == null)
                    throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Weight and date are required");
                entry.setStatus(null);
            }
            case "VET" -> {
                if (entry.getAppointmentAt() == null || entry.getClinic() == null)
                    throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Appointment time and clinic are required");
                String status = request.status() == null ? "UPCOMING" : request.status().toUpperCase(Locale.ROOT);
                if (!Set.of("UPCOMING", "COMPLETED", "CANCELLED").contains(status))
                    throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid visit status");
                entry.setStatus(status);
            }
        }
        if (entry.isReminderTask() && !"VACCINATION".equals(kind) && !"VET".equals(kind))
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Reminders are available for vaccinations and vet visits");
        if (entry.isReminderTask() && (("VACCINATION".equals(kind) && entry.getNextDueDate() == null)
                || ("VET".equals(kind) && !"UPCOMING".equals(entry.getStatus()))))
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "An upcoming date is required for a reminder");
        entry = entries.saveAndFlush(entry);
        synchronizeReminder(entry, pet);
        return entry;
    }
    @Transactional
    public void delete(UUID petId, String kind, UUID entryId) {
        PetEntry entry = get(petId, kind, entryId);
        tasks.findBySourcePetEntryId(entryId).stream().filter(t -> !"COMPLETED".equals(t.getStatus())).forEach(tasks::delete);
        entries.delete(entry);
    }
    private void synchronizeReminder(PetEntry entry, Pet pet) {
        List<GlobalTask> pending = tasks.findBySourcePetEntryId(entry.getId()).stream()
                .filter(t -> !"COMPLETED".equals(t.getStatus())).toList();
        if (!entry.isReminderTask()) { pending.forEach(tasks::delete); return; }
        Family family = families.findById(pet.getFamilyId()).orElseThrow();
        ZonedDateTime due = "VET".equals(entry.getKind()) ? entry.getAppointmentAt()
                : entry.getNextDueDate().atTime(9, 0).atZone(ZoneId.of(family.getTimezone()));
        if (due.isBefore(ZonedDateTime.now())) { pending.forEach(tasks::delete); return; }
        FamilyMember assignee = entry.getAssignedMemberId() == null ? null : requireMember(entry.getAssignedMemberId(), pet.getFamilyId());
        String title = ("VET".equals(entry.getKind()) ? "Vet visit: " : "Vaccination due: ") + pet.getName() + " — " + entry.getTitle();
        if (pending.isEmpty()) {
            GlobalTask task = taskService.createTask(family, title, entry.getDescription(), "PETS",
                    familyAccess.currentMember(family.getId()), assignee, due);
            task.setSourcePetId(pet.getId()); task.setSourcePetEntryId(entry.getId()); tasks.save(task);
        } else {
            GlobalTask first = pending.get(0);
            first.setTitle(title); first.setDueDate(due); first.setAssignedTo(assignee);
            tasks.save(first);
            pending.stream().skip(1).forEach(tasks::delete);
        }
    }
    private FamilyMember requireMember(UUID memberId, UUID familyId) {
        return members.findById(memberId).filter(m -> familyId.equals(m.getFamily().getId()))
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST, "Assignee is not in this family"));
    }
    private void validKind(String kind) {
        if (!KINDS.contains(kind)) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Unknown pet record type");
    }
    private String required(String value, int max, String message) {
        String result = optional(value, max);
        if (result == null) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, message);
        return result;
    }
    private String optional(String value, int max) {
        if (value == null || value.isBlank()) return null;
        String result = value.trim();
        if (result.length() > max) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Pet record details are too long");
        return result;
    }
}
