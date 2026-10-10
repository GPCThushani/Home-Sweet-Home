package com.homesweethome.entity;

import jakarta.persistence.*;
import lombok.Data;

@Entity
@Table(name = "service_providers")
@Data
public class ServiceProvider {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "family_id", nullable = false)
    private String familyId;

    @Column(name = "provider_name", nullable = false)
    private String providerName;

    @Column(name = "phone_number")
    private String phoneNumber;

    private String address;
    private String notes;
}