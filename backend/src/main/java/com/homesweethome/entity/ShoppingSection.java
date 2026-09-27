package com.homesweethome.entity;

import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "shopping_sections")
@Data
public class ShoppingSection {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "family_id", nullable = false)
    private String familyId;

    @Column(nullable = false)
    private String sectionKey;

    @Column(nullable = false)
    private String title;

    @Column(length = 500)
    private String description;

    @Column(nullable = false)
    private boolean customSection = true;

    @ElementCollection
    @CollectionTable(
            name = "shopping_section_categories",
            joinColumns = @JoinColumn(name = "section_id")
    )
    @Column(name = "category_name")
    private List<String> categories = new ArrayList<>();

    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;

    @PrePersist
    public void prePersist() {
        LocalDateTime now = LocalDateTime.now();

        if (createdAt == null) {
            createdAt = now;
        }

        if (updatedAt == null) {
            updatedAt = now;
        }

        if (categories == null) {
            categories = new ArrayList<>();
        }
    }

    @PreUpdate
    public void preUpdate() {
        updatedAt = LocalDateTime.now();

        if (categories == null) {
            categories = new ArrayList<>();
        }
    }
}