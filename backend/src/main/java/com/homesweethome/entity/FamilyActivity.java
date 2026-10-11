package com.homesweethome.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDate;
import java.time.LocalTime;

@Entity
@Table(name = "family_activities")
@Data
public class FamilyActivity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "family_id", nullable = false)
    private String familyId;

    @Column(nullable = false)
    private String title;

    private String description;
    
    @Column(name = "image_url")
    private String imageUrl;

    private LocalDate scheduledDate;
    private LocalTime scheduledTime;

    // true = Coming Together (scheduled), false = Someday Together (bucket list)
    @Column(nullable = false)
    private boolean scheduled = false;

    private String createdBy;
}