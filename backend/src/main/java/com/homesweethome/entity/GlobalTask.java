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
@Table(name = "global_tasks")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GlobalTask {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    // Links the task to the specific digital home
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "family_id", nullable = false)
    private Family family;

    @Column(nullable = false)
    private String title;

    // Tells the frontend which icon/color to use (e.g., 'PETS', 'FINANCE')
    @Column(name = "origin_module", nullable = false, length = 50)
    private String originModule; 

    // Lombok builder default ensures new tasks are always PENDING
    @Builder.Default
    @Column(length = 50)
    private String status = "PENDING";

    // Who needs to do the task
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "assigned_to")
    private FamilyMember assignedTo;

    // Who created the task
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by")
    private FamilyMember createdBy;

    private ZonedDateTime dueDate;

    @CreationTimestamp
    @Column(updatable = false)
    private ZonedDateTime createdAt;

    private ZonedDateTime completedAt;
}