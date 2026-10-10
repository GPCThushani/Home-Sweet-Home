package com.homesweethome.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDate;

@Entity
@Table(name = "maintenance_items")
@Data
public class MaintenanceItem {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "family_id", nullable = false)
    private String familyId;

    @Column(nullable = false)
    private String title;

    // APPLIANCE or SERVICE
    @Column(nullable = false)
    private String category; 

    // DAILY, WEEKLY, MONTHLY, EVERY_N_DAYS, ANNUAL, AS_NEEDED
    @Column(nullable = false)
    private String frequencyType = "AS_NEEDED";

    private Integer intervalDays;
    
    // For Gas Cylinders: typical usage in days (e.g., 60 days)
    private Integer estimatedUsageDays;

    private LocalDate lastServicedDate;
    private LocalDate nextDueDate;

    @Column(name = "provider_id")
    private Long providerId;

    @Column(nullable = false)
    private boolean active = true;
}