package com.homesweethome.entity;

import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDate;

@Entity
@Table(
    name = "health_profiles",
    uniqueConstraints = {
        @UniqueConstraint(
            name = "uk_health_family_member",
            columnNames = {"family_id", "family_member_id"}
        )
    }
)
@Data
public class HealthProfile {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "family_id", nullable = false)
    private String familyId;

    @Column(name = "family_member_id", nullable = false)
    private String familyMemberId;

    // Personal information

    private LocalDate dateOfBirth;

    private String bloodType;

    // Physical information

    private Double heightCm;

    private Double weightKg;

    // Medical information

    @Column(columnDefinition = "TEXT")
    private String allergies;

    @Column(columnDefinition = "TEXT")
    private String knownConditions;

    @Column(columnDefinition = "TEXT")
    private String previousSurgeries;

    @Column(columnDefinition = "TEXT")
    private String previousHospitalizations;

    @Column(columnDefinition = "TEXT")
    private String specialMedicalNotes;

    // Physician

    private String primaryPhysicianName;

    private String primaryPhysicianPhone;

    private String hospitalOrClinic;

    // Insurance

    private String insuranceProvider;

    private String insurancePolicyNumber;

    private LocalDate insuranceExpiryDate;

    // Emergency

    private String emergencyContactName;

    private String emergencyContactRelationship;

    private String emergencyContactPhone;

    // Women's health

    @Column(nullable = false)
    private boolean womensHealthEnabled = false;

    // Sharing

    @Column(nullable = false)
    private boolean emergencyAccessEnabled = true;

    @Column(nullable = false)
    private boolean familyHealthSummaryVisible = true;
}