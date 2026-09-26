package com.homesweethome.entity;

import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDate;

@Entity
@Table(name = "health_records")
@Data
public class HealthRecord {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String familyId;

    @Column(nullable = false)
    private String familyMemberId;

    @Column(nullable = false)
    private String category;
    /*
        LAB_RESULT
        PRESCRIPTION
        DIAGNOSIS
        IMAGING
        HOSPITAL_VISIT
        PROCEDURE
        VACCINATION
        DISCHARGE_SUMMARY
        MEDICAL_NOTE
        OTHER
    */

    @Column(nullable = false)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String details;

    private LocalDate recordDate;

    private String doctorName;

    @PrePersist
    public void prePersist() {
        if (recordDate == null) {
            recordDate = LocalDate.now();
        }
    }
}