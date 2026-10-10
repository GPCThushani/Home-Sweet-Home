package com.homesweethome.entity;

import jakarta.persistence.*;
import lombok.Data;

@Entity
@Table(name = "garden_setup")
@Data
public class GardenSetup {
    @Id
    @Column(name = "family_id")
    private String familyId;
    private boolean initialized;
}