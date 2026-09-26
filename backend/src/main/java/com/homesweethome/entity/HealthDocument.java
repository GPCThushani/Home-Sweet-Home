package com.homesweethome.entity;

import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDate;

@Entity
@Table(name = "health_documents")
@Data
public class HealthDocument {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String familyId;

    @Column(nullable = false)
    private String familyMemberId;

    private String title;

    private String category;

    private String fileUrl;

    private String fileName;

    private LocalDate uploadedDate;

    private boolean protectedRecord = true;
}