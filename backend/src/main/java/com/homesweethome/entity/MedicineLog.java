package com.homesweethome.entity;

import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDateTime;

@Entity
@Table(name = "medicine_logs")
@Data
public class MedicineLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String familyId;

    @Column(nullable = false)
    private String familyMemberId;

    @Column(nullable = false)
    private Long medicineId;

    @Column(nullable = false)
    private LocalDateTime scheduledAt;

    private LocalDateTime takenAt;

    @Column(nullable = false)
    private String status;
    // PENDING / TAKEN / SKIPPED / MISSED

    private String recordedByMemberId;

    @Column(columnDefinition = "TEXT")
    private String notes;
}