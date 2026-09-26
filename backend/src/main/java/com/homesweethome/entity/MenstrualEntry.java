package com.homesweethome.entity;

import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDate;

@Entity
@Table(name = "menstrual_entries")
@Data
public class MenstrualEntry {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long cycleId;

    @Column(nullable = false)
    private String familyId;

    @Column(nullable = false)
    private String familyMemberId;

    @Column(nullable = false)
    private LocalDate date;

    private String flow;
    // NONE / LIGHT / MEDIUM / HEAVY

    @Column(columnDefinition = "TEXT")
    private String symptoms;

    private String mood;

    @Column(columnDefinition = "TEXT")
    private String notes;
}