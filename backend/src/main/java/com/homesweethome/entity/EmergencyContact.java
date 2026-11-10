package com.homesweethome.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.util.UUID;

@Entity
@Table(name = "emergency_contacts")
@Data
public class EmergencyContact {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false)
    private UUID familyId;

    private UUID familyProfileId;

    @Column(nullable = false)
    private String fullName;

    @Column(nullable = false)
    private String relationship;

    @Column(nullable = false)
    private String phoneNumber;

    private String altPhoneNumber;
    private String email;
    private String address;
    private String category;
    private String priority;
    
    @Column(length = 500)
    private String notes;
}