package com.homesweethome.entity;

import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalTime;

@Entity
@Table(name = "medicine_schedules")
@Data
public class MedicineSchedule {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long medicineId;

    @Column(nullable = false)
    private LocalTime scheduledTime;

    private String label;

    private boolean active = true;
}