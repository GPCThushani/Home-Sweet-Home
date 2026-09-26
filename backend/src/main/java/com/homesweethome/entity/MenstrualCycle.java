package com.homesweethome.entity;

import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDate;

@Entity
@Table(name = "menstrual_cycles")
@Data
public class MenstrualCycle {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String familyId;

    @Column(nullable = false)
    private String familyMemberId;

    @Column(nullable = false)
    private LocalDate startDate;

    private LocalDate endDate;

    private Integer cycleLength;

    private Integer periodLength;

    @Column(columnDefinition = "TEXT")
    private String notes;
}