package com.homesweethome.entity;

import jakarta.persistence.*;
import lombok.Data;

import java.util.UUID;

@Entity
@Table(name = "family_profiles")
@Data
public class FamilyProfile {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "family_id", nullable = false)
    private Family family;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private String role;

    private String gender;

    @Column(name = "invite_preferred")
    private boolean invitePreferred = false;

    @Column(name = "linked_user_email")
    private String linkedUserEmail;
}