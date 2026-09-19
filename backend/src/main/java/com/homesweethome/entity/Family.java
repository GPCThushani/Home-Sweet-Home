package com.homesweethome.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.time.ZonedDateTime;
import java.util.UUID;

@Entity
@Table(name = "families")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Family {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false)
    private String name; // e.g., "The Perera Family"

    @Column(length = 255)
    private String motto; // e.g., "Together Always"

    @Column(name = "member_count")
    @Builder.Default
    private int memberCount = 1;

    @Column(name = "admin_email", nullable = false)
    private String adminEmail; // Links the family to the creator's email

    @Column(name = "avatar_path")
    private String avatarPath; // Custom or preset avatar path/URL

    @Column(name = "invite_code", unique = true)
    private String inviteCode; // <-- NEW: Unique code for members to join

    @Builder.Default
    @Column(length = 50)
    private String timezone = "Asia/Colombo"; 

    @CreationTimestamp
    @Column(updatable = false)
    private ZonedDateTime createdAt;
}