package com.homesweethome.entity;
import jakarta.persistence.*;
import lombok.Data;
import java.time.Instant;
import java.util.UUID;
@Entity @Table(name = "pet_documents") @Data
public class PetDocument {
    @Id @GeneratedValue(strategy = GenerationType.UUID) private UUID id;
    @Column(nullable = false) private UUID familyId;
    @Column(nullable = false) private UUID petId;
    @Column(nullable = false) private String title;
    @Column(nullable = false) private String category;
    @Column(nullable = false) private String fileName;
    @Column(nullable = false) private String contentType;
    @Column(nullable = false) private long fileSize;
    @Column(nullable = false) private Instant uploadedAt;
}
