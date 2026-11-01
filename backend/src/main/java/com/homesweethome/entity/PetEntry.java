package com.homesweethome.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.time.*;
import java.util.UUID;

@Entity
@Table(name = "pet_entries")
@Data
public class PetEntry {
    @Id @GeneratedValue(strategy = GenerationType.UUID) private UUID id;
    @Column(nullable = false) private UUID familyId;
    @Column(nullable = false) private UUID petId;
    @Column(nullable = false, length = 32) private String kind;
    @Column(nullable = false, length = 255) private String title;
    @Column(length = 32) private String recordType;
    private LocalDate recordDate;
    private LocalDate nextDueDate;
    private ZonedDateTime appointmentAt;
    @Column(length = 32) private String status;
    @Column(length = 2000) private String description;
    @Column(length = 2000) private String diagnosisTreatment;
    private String veterinarian;
    private String clinic;
    @Column(length = 2000) private String notes;
    private String dosage;
    private String frequency;
    private LocalDate startDate;
    private LocalDate endDate;
    @Column(length = 2000) private String instructions;
    private Double weightKg;
    private UUID assignedMemberId;
    private boolean reminderTask;
    private Instant createdAt;

    @Transient
    public String getComputedStatus() {
        if (!"VACCINATION".equals(kind)) return status;
        if (nextDueDate == null) return "COMPLETED";
        return nextDueDate.isBefore(LocalDate.now()) ? "OVERDUE" : "UPCOMING";
    }
}
