package com.homesweethome.entity;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
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

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "family_id", nullable = false)
    @JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
    private Family family;

    @Column(nullable = false)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "origin_module", nullable = false, length = 50)
    private String originModule;

    @Builder.Default
    @Column(nullable = false, length = 50)
    private String status = "PENDING";

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "assigned_to")
    @JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
    private FamilyMember assignedTo;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by")
    @JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
    private FamilyMember createdBy;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "completed_by")
    @JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
    private FamilyMember completedBy; // <-- RECORD WHO ACTUALLY COMPLETED IT

    private ZonedDateTime dueDate;

    @CreationTimestamp
    @Column(updatable = false)
    private ZonedDateTime createdAt;

    private ZonedDateTime completedAt;
}