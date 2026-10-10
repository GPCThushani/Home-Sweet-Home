package com.homesweethome.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDate;

@Entity
@Table(name = "garden_plants")
@Data
public class GardenPlant {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "family_id", nullable = false)
    private String familyId;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private String category;

    private LocalDate addedDate;

    @PrePersist
    public void prePersist() {
        if (addedDate == null) {
            addedDate = LocalDate.now();
        }
    }
}