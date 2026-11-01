package com.homesweethome.dto;
import java.time.*;
import java.util.UUID;
public record PetEntryRequest(String title, String recordType, LocalDate recordDate, LocalDate nextDueDate,
        ZonedDateTime appointmentAt, String status, String description, String diagnosisTreatment,
        String veterinarian, String clinic, String notes, String dosage, String frequency,
        LocalDate startDate, LocalDate endDate, String instructions, Double weightKg,
        UUID assignedMemberId, Boolean reminderTask) {}
