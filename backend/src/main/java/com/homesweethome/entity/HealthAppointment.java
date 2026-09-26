package com.homesweethome.entity;

import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "health_appointments")
@Data
public class HealthAppointment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String familyId;

    @Column(nullable = false)
    private String familyMemberId;

    private String doctorName;

    private String specialty;

    private String hospitalOrClinic;

    private LocalDateTime appointmentDateTime;

    private String reason;

    @Column(columnDefinition = "TEXT")
    private String notes;

    private LocalDate followUpDate;

    private String accompanyingMemberId;

    private String status;
    // UPCOMING / COMPLETED / CANCELLED
}