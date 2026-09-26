package com.homesweethome.entity;

import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDate;

@Entity
@Table(name = "medicines")
@Data
public class Medicine {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "family_id", nullable = false)
    private String familyId;

    @Column(name = "family_member_id", nullable = false)
    private String familyMemberId;

    @Column(nullable = false)
    private String name;

    private String genericName;

    private String brandName;

    private String dosage;

    private String frequency;

    private LocalDate startDate;

    private LocalDate endDate;

    private Integer quantity;

    private Integer remainingQuantity;

    private Integer refillThreshold;

    @Column(columnDefinition = "TEXT")
    private String instructions;

    private boolean active = true;
}