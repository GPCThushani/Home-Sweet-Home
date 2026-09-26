package com.homesweethome.controller;

import com.homesweethome.entity.*;
import com.homesweethome.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/health")
@RequiredArgsConstructor
public class HealthController {

    private final HealthProfileRepository profileRepository;
    private final MedicineRepository medicineRepository;
    private final HealthAppointmentRepository appointmentRepository;
    private final HealthRecordRepository recordRepository;
    private final HealthDocumentRepository documentRepository;
    private final MenstrualCycleRepository cycleRepository;
    // --- PROFILE ---
    @GetMapping("/profile/{familyId}/{memberId}")
    public ResponseEntity<HealthProfile> getProfile(@PathVariable String familyId, @PathVariable String memberId) {
        return profileRepository.findByFamilyIdAndFamilyMemberId(familyId, memberId)
                .map(ResponseEntity::ok)
                .orElseGet(() -> {
                    HealthProfile profile = new HealthProfile();
                    profile.setFamilyId(familyId);
                    profile.setFamilyMemberId(memberId);
                    profile.setEmergencyAccessEnabled(true);
                    profile.setFamilyHealthSummaryVisible(true);
                    return ResponseEntity.ok(profileRepository.save(profile));
                });
    }

    @PutMapping("/profile/{familyId}/{memberId}")
    public ResponseEntity<HealthProfile> updateProfile(
            @PathVariable String familyId,
            @PathVariable String memberId,
            @RequestBody HealthProfile incoming
    ) {
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

    // --- MEDICINES ---
    @GetMapping("/medicines/{familyId}/{memberId}")
    public ResponseEntity<List<Medicine>> getMedicines(@PathVariable String familyId, @PathVariable String memberId) {
        return ResponseEntity.ok(medicineRepository.findByFamilyIdAndFamilyMemberIdAndActiveTrue(familyId, memberId));
    }

    @PostMapping("/medicines/{familyId}/{memberId}")
    public ResponseEntity<Medicine> addMedicine(@PathVariable String familyId, @PathVariable String memberId, @RequestBody Medicine medicine) {
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
                    med.setName(incoming.getName());
                    med.setGenericName(incoming.getGenericName());
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
        medicineRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    // --- APPOINTMENTS ---
    @GetMapping("/appointments/{familyId}/{memberId}")
    public ResponseEntity<List<HealthAppointment>> getAppointments(@PathVariable String familyId, @PathVariable String memberId) {
        return ResponseEntity.ok(appointmentRepository.findByFamilyIdAndFamilyMemberIdOrderByAppointmentDateTimeAsc(familyId, memberId));
    }

    @PostMapping("/appointments/{familyId}/{memberId}")
    public ResponseEntity<HealthAppointment> addAppointment(@PathVariable String familyId, @PathVariable String memberId, @RequestBody HealthAppointment appointment) {
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
                    app.setDoctorName(incoming.getDoctorName());
                    app.setSpecialty(incoming.getSpecialty());
                    app.setHospitalOrClinic(incoming.getHospitalOrClinic());
                    app.setAppointmentDateTime(incoming.getAppointmentDateTime());
                    app.setReason(incoming.getReason());
                    app.setStatus(incoming.getStatus());
                    return ResponseEntity.ok(appointmentRepository.save(app));
                })
                .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/appointments/{id}")
    public ResponseEntity<Void> deleteAppointment(@PathVariable Long id) {
        appointmentRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    // --- RECORDS ---
    @GetMapping("/records/{familyId}/{memberId}")
    public ResponseEntity<List<HealthRecord>> getRecords(@PathVariable String familyId, @PathVariable String memberId) {
        return ResponseEntity.ok(recordRepository.findByFamilyIdAndFamilyMemberIdOrderByRecordDateDesc(familyId, memberId));
    }

    @PostMapping("/records/{familyId}/{memberId}")
    public ResponseEntity<HealthRecord> addRecord(@PathVariable String familyId, @PathVariable String memberId, @RequestBody HealthRecord record) {
        record.setId(null);
        record.setFamilyId(familyId);
        record.setFamilyMemberId(memberId);
        return ResponseEntity.ok(recordRepository.save(record));
    }

    @PutMapping("/records/{id}")
    public ResponseEntity<HealthRecord> updateRecord(@PathVariable Long id, @RequestBody HealthRecord incoming) {
        return recordRepository.findById(id)
                .map(rec -> {
                    rec.setCategory(incoming.getCategory());
                    rec.setTitle(incoming.getTitle());
                    rec.setDetails(incoming.getDetails());
                    rec.setRecordDate(incoming.getRecordDate());
                    return ResponseEntity.ok(recordRepository.save(rec));
                })
                .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/records/{id}")
    public ResponseEntity<Void> deleteRecord(@PathVariable Long id) {
        recordRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    // --- DOCUMENTS ---
    @GetMapping("/documents/{familyId}/{memberId}")
    public ResponseEntity<List<HealthDocument>> getDocuments(@PathVariable String familyId, @PathVariable String memberId) {
        return ResponseEntity.ok(documentRepository.findByFamilyIdAndFamilyMemberIdOrderByUploadedDateDesc(familyId, memberId));
    }

    @PostMapping("/documents/{familyId}/{memberId}")
    public ResponseEntity<HealthDocument> addDocument(@PathVariable String familyId, @PathVariable String memberId, @RequestBody HealthDocument document) {
        document.setId(null);
        document.setFamilyId(familyId);
        document.setFamilyMemberId(memberId);
        if (document.getUploadedDate() == null) document.setUploadedDate(LocalDate.now());
        return ResponseEntity.ok(documentRepository.save(document));
    }

    @DeleteMapping("/documents/{id}")
    public ResponseEntity<Void> deleteDocument(@PathVariable Long id) {
        documentRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    // --- WOMEN'S HEALTH ---
    @GetMapping("/womens-health/cycles/{familyId}/{memberId}")
    public ResponseEntity<List<MenstrualCycle>> getCycles(@PathVariable String familyId, @PathVariable String memberId) {
        return ResponseEntity.ok(cycleRepository.findByFamilyIdAndFamilyMemberIdOrderByStartDateDesc(familyId, memberId));
    }

    @PostMapping("/womens-health/cycles/{familyId}/{memberId}")
    public ResponseEntity<MenstrualCycle> addCycle(@PathVariable String familyId, @PathVariable String memberId, @RequestBody MenstrualCycle cycle) {
        cycle.setId(null);
        cycle.setFamilyId(familyId);
        cycle.setFamilyMemberId(memberId);
        return ResponseEntity.ok(cycleRepository.save(cycle));
    }

    @PutMapping("/womens-health/cycles/{cycleId}/end")
    public ResponseEntity<MenstrualCycle> endCycle(@PathVariable Long cycleId, @RequestParam LocalDate endDate) {
        return cycleRepository.findById(cycleId)
                .map(cycle -> {
                    cycle.setEndDate(endDate);
                    long periodLength = java.time.temporal.ChronoUnit.DAYS.between(cycle.getStartDate(), endDate) + 1;
                    cycle.setPeriodLength((int) periodLength);
                    return ResponseEntity.ok(cycleRepository.save(cycle));
                })
                .orElse(ResponseEntity.notFound().build());
    }
}