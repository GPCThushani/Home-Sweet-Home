package com.homesweethome.controller;

import com.homesweethome.entity.*;
import com.homesweethome.repository.*;
import lombok.RequiredArgsConstructor;
import com.homesweethome.service.HealthAccessService;
import com.homesweethome.service.HealthDocumentStorage;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;
import java.util.Objects;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.List;

@RestController
@RequestMapping("/api/health")
@RequiredArgsConstructor
@org.springframework.transaction.annotation.Transactional
public class HealthController {

    private final HealthAccessService access;

    private final HealthProfileRepository profileRepository;
    private final MedicineRepository medicineRepository;
    private final MedicineLogRepository medicineLogRepository;
    private final MedicineScheduleRepository scheduleRepository;
    private final HealthAppointmentRepository appointmentRepository;
    private final HealthRecordRepository recordRepository;
    private final HealthDocumentRepository documentRepository;
    private final HealthDocumentStorage documentStorage;
    private final MenstrualCycleRepository cycleRepository;
    private final MenstrualEntryRepository menstrualEntryRepository;

    @GetMapping("/profile/{familyId}/{memberId}")
    public ResponseEntity<HealthProfile> getProfile(@PathVariable String familyId, @PathVariable String memberId) {
        access.requireProfile(familyId, memberId);
        return profileRepository.findByFamilyIdAndFamilyMemberId(familyId, memberId)
                .map(ResponseEntity::ok)
                .orElseGet(() -> {
                    HealthProfile profile = new HealthProfile();
                    profile.setFamilyId(familyId);
                    profile.setFamilyMemberId(memberId);
                    profile.setEmergencyAccessEnabled(true);
                    profile.setFamilyHealthSummaryVisible(true);
                    return ResponseEntity.ok(profile);
                });
    }

    @PutMapping("/profile/{familyId}/{memberId}")
    public ResponseEntity<HealthProfile> updateProfile(
            @PathVariable String familyId,
            @PathVariable String memberId,
            @RequestBody HealthProfile incoming
    ) {
        access.lockProfile(familyId, memberId);
        if ((incoming.getDateOfBirth() != null && incoming.getDateOfBirth().isAfter(LocalDate.now()))
                || (incoming.getHeightCm() != null && incoming.getHeightCm() <= 0)
                || (incoming.getWeightKg() != null && incoming.getWeightKg() <= 0))
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Check date of birth, height and weight");
        HealthProfile profile = profileRepository.findByFamilyIdAndFamilyMemberId(familyId, memberId)
                .orElseGet(HealthProfile::new);

        profile.setFamilyId(familyId);
        profile.setFamilyMemberId(memberId);
        profile.setDateOfBirth(incoming.getDateOfBirth());
        profile.setBloodType(incoming.getBloodType());
        profile.setHeightCm(incoming.getHeightCm());
        profile.setWeightKg(incoming.getWeightKg());
        profile.setAllergies(incoming.getAllergies());
        profile.setKnownConditions(incoming.getKnownConditions());
        profile.setPreviousSurgeries(incoming.getPreviousSurgeries());
        profile.setPreviousHospitalizations(incoming.getPreviousHospitalizations());
        profile.setSpecialMedicalNotes(incoming.getSpecialMedicalNotes());
        profile.setPrimaryPhysicianName(incoming.getPrimaryPhysicianName());
        profile.setPrimaryPhysicianPhone(incoming.getPrimaryPhysicianPhone());
        profile.setHospitalOrClinic(incoming.getHospitalOrClinic());
        profile.setInsuranceProvider(incoming.getInsuranceProvider());
        profile.setInsurancePolicyNumber(incoming.getInsurancePolicyNumber());
        profile.setInsuranceExpiryDate(incoming.getInsuranceExpiryDate());
        profile.setEmergencyContactName(incoming.getEmergencyContactName());
        profile.setEmergencyContactRelationship(incoming.getEmergencyContactRelationship());
        profile.setEmergencyContactPhone(incoming.getEmergencyContactPhone());
        profile.setWomensHealthEnabled(incoming.isWomensHealthEnabled());
        profile.setEmergencyAccessEnabled(incoming.isEmergencyAccessEnabled());
        profile.setFamilyHealthSummaryVisible(incoming.isFamilyHealthSummaryVisible());

        return ResponseEntity.ok(profileRepository.save(profile));
    }

    @GetMapping("/medicines/{familyId}/{memberId}")
    public ResponseEntity<List<Medicine>> getMedicines(@PathVariable String familyId, @PathVariable String memberId) {
        access.requireProfile(familyId, memberId);
        return ResponseEntity.ok(medicineRepository.findByFamilyIdAndFamilyMemberIdAndActiveTrue(familyId, memberId));
    }

    @PostMapping("/medicines/{familyId}/{memberId}")
    public ResponseEntity<Medicine> addMedicine(@PathVariable String familyId, @PathVariable String memberId, @RequestBody Medicine medicine) {
        access.lockProfile(familyId, memberId);
        validateMedicine(medicine);
        medicine.setId(null);
        medicine.setFamilyId(familyId);
        medicine.setFamilyMemberId(memberId);
        medicine.setActive(true);
        if (medicine.getRemainingQuantity() == null) {
            medicine.setRemainingQuantity(medicine.getQuantity());
        }
        return ResponseEntity.ok(medicineRepository.save(medicine));
    }

    @PutMapping("/medicines/{id}")
    public ResponseEntity<Medicine> updateMedicine(@PathVariable Long id, @RequestBody Medicine incoming) {
        return medicineRepository.findById(id)
                .map(med -> {
                    access.lockProfile(med.getFamilyId(), med.getFamilyMemberId());
                    validateMedicine(incoming);
                    med.setName(incoming.getName());
                    med.setGenericName(incoming.getGenericName());
                    med.setBrandName(incoming.getBrandName());
                    med.setStartDate(incoming.getStartDate());
                    med.setEndDate(incoming.getEndDate());
                    med.setDosage(incoming.getDosage());
                    med.setFrequency(incoming.getFrequency());
                    med.setQuantity(incoming.getQuantity());
                    med.setRemainingQuantity(incoming.getRemainingQuantity());
                    med.setRefillThreshold(incoming.getRefillThreshold());
                    med.setInstructions(incoming.getInstructions());
                    return ResponseEntity.ok(medicineRepository.save(med));
                })
                .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/medicines/{id}")
    public ResponseEntity<Void> deleteMedicine(@PathVariable Long id) {
        Medicine owned = medicineRepository.findById(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
        access.lockProfile(owned.getFamilyId(), owned.getFamilyMemberId());
        for (MedicineSchedule schedule : scheduleRepository.findByMedicineIdAndActiveTrue(id)) { schedule.setActive(false); scheduleRepository.save(schedule); }
        owned.setActive(false);
        medicineRepository.save(owned);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/medicines/logs/{familyId}/{memberId}")
    public ResponseEntity<List<MedicineLog>> getMedicineLogs(@PathVariable String familyId, @PathVariable String memberId) {
        access.requireProfile(familyId, memberId);
        return ResponseEntity.ok(medicineLogRepository.findByFamilyIdAndFamilyMemberIdOrderByScheduledAtDesc(familyId, memberId));
    }

    @PostMapping("/medicines/logs")
    public ResponseEntity<MedicineLog> logMedicine(@RequestBody MedicineLog log) {
        access.lockProfile(log.getFamilyId(), log.getFamilyMemberId());
        Medicine medicine = medicineRepository.findById(log.getMedicineId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
        if (!Objects.equals(medicine.getFamilyId(), log.getFamilyId())
                || !Objects.equals(medicine.getFamilyMemberId(), log.getFamilyMemberId())) {
            throw new AccessDeniedException("Medicine does not belong to this family member");
        }
        log.setId(null);
        if (log.getStatus() == null) log.setStatus("TAKEN");
        if (!java.util.Set.of("TAKEN", "SKIPPED", "MISSED").contains(log.getStatus())) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid medication status");
        log.setRecordedByMemberId(access.actorProfileId(log.getFamilyId()));
        log.setTakenAt("TAKEN".equals(log.getStatus()) ? LocalDateTime.now() : null);
        if (log.getScheduledAt() == null) log.setScheduledAt(LocalDateTime.now());

        MedicineLog previous = medicineLogRepository.findByMedicineIdAndScheduledAt(log.getMedicineId(), log.getScheduledAt()).orElse(null);
        if (previous != null) {
            if (!previous.getStatus().equals(log.getStatus())) throw new ResponseStatusException(HttpStatus.CONFLICT, "A different status is already recorded for this dose");
            return ResponseEntity.ok(previous);
        }
        if (!medicine.isActive()) throw new ResponseStatusException(HttpStatus.CONFLICT, "Medicine is inactive");
        if ("TAKEN".equalsIgnoreCase(log.getStatus())) {
            medicineRepository.findById(log.getMedicineId()).ifPresent(med -> {
                if (med.getRemainingQuantity() != null && med.getRemainingQuantity() <= 0) throw new ResponseStatusException(HttpStatus.CONFLICT, "No doses remaining; update the medicine stock first");
                if (med.getRemainingQuantity() != null) {
                    med.setRemainingQuantity(med.getRemainingQuantity() - 1);
                    medicineRepository.save(med);
                }
            });
        }
        return ResponseEntity.ok(medicineLogRepository.save(log));
    }

    @GetMapping("/appointments/{familyId}/{memberId}")
    public ResponseEntity<List<HealthAppointment>> getAppointments(@PathVariable String familyId, @PathVariable String memberId) {
        access.requireProfile(familyId, memberId);
        return ResponseEntity.ok(appointmentRepository.findByFamilyIdAndFamilyMemberIdOrderByAppointmentDateTimeAsc(familyId, memberId));
    }

    @PostMapping("/appointments/{familyId}/{memberId}")
    public ResponseEntity<HealthAppointment> addAppointment(@PathVariable String familyId, @PathVariable String memberId, @RequestBody HealthAppointment appointment) {
        access.lockProfile(familyId, memberId);
        validateAppointment(appointment, familyId);
        appointment.setId(null);
        appointment.setFamilyId(familyId);
        appointment.setFamilyMemberId(memberId);
        if (appointment.getStatus() == null) appointment.setStatus("UPCOMING");
        return ResponseEntity.ok(appointmentRepository.save(appointment));
    }

    @PutMapping("/appointments/{id}")
    public ResponseEntity<HealthAppointment> updateAppointment(@PathVariable Long id, @RequestBody HealthAppointment incoming) {
        return appointmentRepository.findById(id)
                .map(app -> {
                    access.lockProfile(app.getFamilyId(), app.getFamilyMemberId());
                    validateAppointment(incoming, app.getFamilyId());
                    app.setDoctorName(incoming.getDoctorName());
                    app.setSpecialty(incoming.getSpecialty());
                    app.setHospitalOrClinic(incoming.getHospitalOrClinic());
                    app.setAppointmentDateTime(incoming.getAppointmentDateTime());
                    app.setReason(incoming.getReason());
                    app.setNotes(incoming.getNotes());
                    app.setFollowUpDate(incoming.getFollowUpDate());
                    app.setAccompanyingMemberId(incoming.getAccompanyingMemberId());
                    app.setStatus(incoming.getStatus());
                    return ResponseEntity.ok(appointmentRepository.save(app));
                })
                .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/appointments/{id}")
    public ResponseEntity<Void> deleteAppointment(@PathVariable Long id) {
        HealthAppointment owned = appointmentRepository.findById(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
        access.lockProfile(owned.getFamilyId(), owned.getFamilyMemberId());
        appointmentRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/records/{familyId}/{memberId}")
    public ResponseEntity<List<HealthRecord>> getRecords(@PathVariable String familyId, @PathVariable String memberId) {
        access.requireProfile(familyId, memberId);
        return ResponseEntity.ok(recordRepository.findByFamilyIdAndFamilyMemberIdOrderByRecordDateDesc(familyId, memberId));
    }

    @PostMapping("/records/{familyId}/{memberId}")
    public ResponseEntity<HealthRecord> addRecord(@PathVariable String familyId, @PathVariable String memberId, @RequestBody HealthRecord record) {
        access.lockProfile(familyId, memberId);
        required(record.getTitle(), "Record title");
        record.setId(null);
        record.setFamilyId(familyId);
        record.setFamilyMemberId(memberId);
        return ResponseEntity.ok(recordRepository.save(record));
    }

    @PutMapping("/records/{id}")
    public ResponseEntity<HealthRecord> updateRecord(@PathVariable Long id, @RequestBody HealthRecord incoming) {
        return recordRepository.findById(id)
                .map(rec -> {
                    access.lockProfile(rec.getFamilyId(), rec.getFamilyMemberId());
                    required(incoming.getTitle(), "Record title");
                    rec.setCategory(incoming.getCategory());
                    rec.setTitle(incoming.getTitle());
                    rec.setDetails(incoming.getDetails());
                    rec.setRecordDate(incoming.getRecordDate());
                    rec.setDoctorName(incoming.getDoctorName());
                    return ResponseEntity.ok(recordRepository.save(rec));
                })
                .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/records/{id}")
    public ResponseEntity<Void> deleteRecord(@PathVariable Long id) {
        HealthRecord owned = recordRepository.findById(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
        access.lockProfile(owned.getFamilyId(), owned.getFamilyMemberId());
        recordRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/documents/{familyId}/{memberId}")
    public ResponseEntity<List<HealthDocument>> getDocuments(@PathVariable String familyId, @PathVariable String memberId) {
        access.requireProfile(familyId, memberId);
        return ResponseEntity.ok(documentRepository.findByFamilyIdAndFamilyMemberIdOrderByUploadedDateDesc(familyId, memberId));
    }

    @PostMapping("/documents/{familyId}/{memberId}")
    public ResponseEntity<HealthDocument> addDocument(@PathVariable String familyId, @PathVariable String memberId, @RequestBody HealthDocument document) {
        access.lockProfile(familyId, memberId);
        document.setId(null);
        document.setFamilyId(familyId);
        document.setFamilyMemberId(memberId);
        if (document.getUploadedDate() == null) document.setUploadedDate(LocalDate.now());
        return ResponseEntity.ok(documentRepository.save(document));
    }

    @PostMapping(value = "/documents/{familyId}/{memberId}/upload", consumes = "multipart/form-data")
    public ResponseEntity<HealthDocument> uploadDocument(@PathVariable String familyId, @PathVariable String memberId,
            @RequestParam org.springframework.web.multipart.MultipartFile file,
            @RequestParam String title, @RequestParam(defaultValue = "Medical") String category) {
        access.lockProfile(familyId, memberId);
        if (title.isBlank() || title.length() > 255 || category.length() > 255) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "A document title and valid category are required");
        HealthDocument document = new HealthDocument();
        document.setFamilyId(familyId); document.setFamilyMemberId(memberId);
        document.setTitle(title.trim()); document.setCategory(category);
        String name = file.getOriginalFilename() == null ? "document" : file.getOriginalFilename().replaceAll("[\\\\/\\p{Cntrl}]", "_");
        document.setFileName(name.substring(0, Math.min(150, name.length())));
        document.setUploadedDate(LocalDate.now());
        documentRepository.saveAndFlush(document);
        document.setFileUrl("/api/health/documents/" + document.getId() + "/file");
        documentStorage.save(document, file);
        return ResponseEntity.ok(documentRepository.save(document));
    }

    @GetMapping("/documents/{id}/file")
    public ResponseEntity<byte[]> downloadDocument(@PathVariable Long id) {
        HealthDocument document = documentRepository.findById(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
        access.requireProfile(document.getFamilyId(), document.getFamilyMemberId());
        byte[] bytes = documentStorage.read(document);
        return ResponseEntity.ok().header("Content-Disposition", org.springframework.http.ContentDisposition.attachment()
                .filename(document.getFileName(), java.nio.charset.StandardCharsets.UTF_8).build().toString())
                .header("X-Content-Type-Options", "nosniff").header("Cache-Control", "no-store")
                .contentType(org.springframework.http.MediaType.parseMediaType(documentStorage.contentType(bytes))).body(bytes);
    }

    @DeleteMapping("/documents/{id}")
    public ResponseEntity<Void> deleteDocument(@PathVariable Long id) {
        HealthDocument owned = documentRepository.findById(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
        access.lockProfile(owned.getFamilyId(), owned.getFamilyMemberId());
        documentRepository.deleteById(id);
        documentStorage.removeAfterCommit(owned);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/womens-health/cycles/{familyId}/{memberId}")
    public ResponseEntity<List<MenstrualCycle>> getCycles(@PathVariable String familyId, @PathVariable String memberId) {
        access.requireProfile(familyId, memberId);
        return ResponseEntity.ok(cycleRepository.findByFamilyIdAndFamilyMemberIdOrderByStartDateDesc(familyId, memberId));
    }

    @PostMapping("/womens-health/cycles/{familyId}/{memberId}")
    public ResponseEntity<MenstrualCycle> addCycle(@PathVariable String familyId, @PathVariable String memberId, @RequestBody MenstrualCycle cycle) {
        access.lockProfile(familyId, memberId);
        if (cycle.getStartDate() == null || (cycle.getEndDate() != null && cycle.getEndDate().isBefore(cycle.getStartDate()))) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid cycle dates");
        if (cycleRepository.findByFamilyIdAndFamilyMemberIdOrderByStartDateDesc(familyId, memberId).stream().anyMatch(c -> c.getEndDate() == null)) throw new ResponseStatusException(HttpStatus.CONFLICT, "End the current period before starting another");
        List<MenstrualCycle> previousCycles = cycleRepository.findByFamilyIdAndFamilyMemberIdOrderByStartDateDesc(familyId, memberId);
        if (!previousCycles.isEmpty()) {
            MenstrualCycle previousCycle = previousCycles.get(0);
            if (!cycle.getStartDate().isAfter(previousCycle.getEndDate())) throw new ResponseStatusException(HttpStatus.CONFLICT, "New period must start after the previous period ends");
            previousCycle.setCycleLength((int) ChronoUnit.DAYS.between(previousCycle.getStartDate(), cycle.getStartDate()));
            cycleRepository.save(previousCycle);
        }
        if (cycle.getEndDate() != null) cycle.setPeriodLength((int) ChronoUnit.DAYS.between(cycle.getStartDate(), cycle.getEndDate()) + 1);
        cycle.setId(null);
        cycle.setFamilyId(familyId);
        cycle.setFamilyMemberId(memberId);
        return ResponseEntity.ok(cycleRepository.save(cycle));
    }

    @PutMapping("/womens-health/cycles/{cycleId}/end")
    public ResponseEntity<MenstrualCycle> endCycle(@PathVariable Long cycleId, @RequestParam LocalDate endDate) {
        return cycleRepository.findById(cycleId)
                .map(cycle -> {
                    access.lockProfile(cycle.getFamilyId(), cycle.getFamilyMemberId());
                    if (endDate.isBefore(cycle.getStartDate())) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "End date must follow start date");
                    cycle.setEndDate(endDate);
                    long periodLength = ChronoUnit.DAYS.between(cycle.getStartDate(), endDate) + 1;
                    cycle.setPeriodLength((int) periodLength);
                    return ResponseEntity.ok(cycleRepository.save(cycle));
                })
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/womens-health/entries")
    public ResponseEntity<MenstrualEntry> addMenstrualEntry(@RequestBody MenstrualEntry entry) {
        access.lockProfile(entry.getFamilyId(), entry.getFamilyMemberId());
        MenstrualCycle cycle = cycleRepository.findById(entry.getCycleId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
        if (!Objects.equals(cycle.getFamilyId(), entry.getFamilyId())
                || !Objects.equals(cycle.getFamilyMemberId(), entry.getFamilyMemberId())) {
            throw new AccessDeniedException("Cycle does not belong to this family member");
        }
        if (entry.getDate() == null || entry.getDate().isBefore(cycle.getStartDate())) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Entry date must follow the cycle start");
        if (cycleRepository.findByFamilyIdAndFamilyMemberIdOrderByStartDateDesc(entry.getFamilyId(), entry.getFamilyMemberId()).stream()
                .anyMatch(next -> next.getStartDate().isAfter(cycle.getStartDate()) && !entry.getDate().isBefore(next.getStartDate())))
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Entry belongs to a later cycle");
        entry.setId(menstrualEntryRepository.findByFamilyIdAndFamilyMemberIdAndDate(entry.getFamilyId(), entry.getFamilyMemberId(), entry.getDate()).map(MenstrualEntry::getId).orElse(null));
        return ResponseEntity.ok(menstrualEntryRepository.save(entry));
    }

    @GetMapping("/womens-health/entries/{familyId}/{memberId}")
    public ResponseEntity<List<MenstrualEntry>> getMenstrualEntries(
            @PathVariable String familyId, 
            @PathVariable String memberId,
            @RequestParam LocalDate start,
            @RequestParam LocalDate end) {
        access.requireProfile(familyId, memberId);
        return ResponseEntity.ok(menstrualEntryRepository.findByFamilyIdAndFamilyMemberIdAndDateBetween(familyId, memberId, start, end));
    }
    private void required(String value, String field) {
        if (value == null || value.isBlank() || value.length() > 255) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, field + " is required (maximum 255 characters)");
    }
    private void validateMedicine(Medicine medicine) {
        required(medicine.getName(), "Medicine name");
        if ((medicine.getQuantity() != null && medicine.getQuantity() < 0) || (medicine.getRemainingQuantity() != null && medicine.getRemainingQuantity() < 0)
                || (medicine.getRefillThreshold() != null && medicine.getRefillThreshold() < 0)
                || (medicine.getStartDate() != null && medicine.getEndDate() != null && medicine.getEndDate().isBefore(medicine.getStartDate())))
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Check medicine quantities and dates");
    }
    private void validateAppointment(HealthAppointment appointment, String familyId) {
        required(appointment.getDoctorName(), "Doctor name");
        if (appointment.getAppointmentDateTime() == null) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Appointment date and time are required");
        if (appointment.getStatus() != null && !java.util.Set.of("UPCOMING", "COMPLETED", "CANCELLED").contains(appointment.getStatus())) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid appointment status");
        if (appointment.getAccompanyingMemberId() != null && !appointment.getAccompanyingMemberId().isBlank()) access.requireProfile(familyId, appointment.getAccompanyingMemberId());
    }

    private Medicine scheduleMedicine(Long id) {
        Medicine medicine = medicineRepository.findById(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
        access.lockProfile(medicine.getFamilyId(), medicine.getFamilyMemberId());
        return medicine;
    }
    @GetMapping("/medicines/{medicineId}/schedules")
    public ResponseEntity<List<MedicineSchedule>> schedules(@PathVariable Long medicineId) {
        Medicine medicine = medicineRepository.findById(medicineId).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
        access.requireProfile(medicine.getFamilyId(), medicine.getFamilyMemberId());
        return ResponseEntity.ok(scheduleRepository.findByMedicineIdAndActiveTrue(medicineId));
    }
    @PostMapping("/medicines/{medicineId}/schedules")
    public ResponseEntity<MedicineSchedule> addSchedule(@PathVariable Long medicineId, @RequestBody MedicineSchedule schedule) {
        Medicine medicine = scheduleMedicine(medicineId);
        if (!medicine.isActive()) throw new ResponseStatusException(HttpStatus.CONFLICT, "Medicine is inactive");
        if (schedule.getScheduledTime() == null) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Schedule time is required");
        if (scheduleRepository.findByMedicineIdAndActiveTrue(medicineId).stream().anyMatch(existing -> existing.getScheduledTime().equals(schedule.getScheduledTime()))) throw new ResponseStatusException(HttpStatus.CONFLICT, "This medicine already has a dose at that time");
        schedule.setId(null); schedule.setMedicineId(medicineId); schedule.setActive(true);
        return ResponseEntity.ok(scheduleRepository.save(schedule));
    }
    @PutMapping("/medicines/schedules/{id}")
    public ResponseEntity<MedicineSchedule> updateSchedule(@PathVariable Long id, @RequestBody MedicineSchedule incoming) {
        MedicineSchedule schedule = scheduleRepository.findById(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
        Medicine medicine = scheduleMedicine(schedule.getMedicineId());
        if (!medicine.isActive() || !schedule.isActive()) throw new ResponseStatusException(HttpStatus.CONFLICT, "Schedule is inactive");
        if (incoming.getScheduledTime() == null) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Schedule time is required");
        if (scheduleRepository.findByMedicineIdAndActiveTrue(schedule.getMedicineId()).stream().anyMatch(existing -> !existing.getId().equals(id) && existing.getScheduledTime().equals(incoming.getScheduledTime()))) throw new ResponseStatusException(HttpStatus.CONFLICT, "This medicine already has a dose at that time");
        schedule.setScheduledTime(incoming.getScheduledTime()); schedule.setLabel(incoming.getLabel());
        return ResponseEntity.ok(scheduleRepository.save(schedule));
    }
    @DeleteMapping("/medicines/schedules/{id}")
    public ResponseEntity<Void> deleteSchedule(@PathVariable Long id) {
        MedicineSchedule schedule = scheduleRepository.findById(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
        scheduleMedicine(schedule.getMedicineId()); schedule.setActive(false); scheduleRepository.save(schedule);
        return ResponseEntity.noContent().build();
    }

    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<java.util.Map<String, String>> healthError(ResponseStatusException ex) {
        return ResponseEntity.status(ex.getStatusCode()).body(java.util.Map.of("error", ex.getReason() == null ? "Health request failed" : ex.getReason()));
    }
}
