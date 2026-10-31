package com.homesweethome.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "documents")
@Data
public class Document {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false)
    private UUID familyId;

    /** Null means that the document is shared by the whole household. */
    private UUID familyProfileId;

    @Column(nullable = false)
    private String title;

    @Column(nullable = false, length = 32)
    private String category;

    @Column(length = 1000)
    private String description;

    @Column(length = 255)
    private String fileName;

    @Column(length = 100)
    private String contentType;

    private Long fileSize;

    private Instant uploadedAt;

    @Column(length = 255)
    private String uploadedBy;

    // Kept for compatibility with existing metadata-only records.
    private String belongsTo;

    private LocalDate issueDate;

    private LocalDate expiryDate;

    private boolean remindBeforeExpiry;
}
