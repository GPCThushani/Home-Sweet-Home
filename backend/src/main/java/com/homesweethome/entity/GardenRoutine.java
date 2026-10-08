package com.homesweethome.entity;

import jakarta.persistence.*;
import lombok.Data;

@Entity
@Table(name = "garden_routines")
@Data
public class GardenRoutine {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "family_id", nullable = false)
    private String familyId;

    @Column(nullable = false)
    private String title;

    @Column(nullable = false)
    private String frequency;

    @Column(nullable = false)
    private boolean completed = false;
    
    @Column(nullable = false)
    private boolean isQuickAction = false;
}