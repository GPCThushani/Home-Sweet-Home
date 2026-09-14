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

    // Defaulting to Sri Lanka time as discussed in the architecture
    @Builder.Default
    @Column(length = 50)
    private String timezone = "Asia/Colombo"; 

    @CreationTimestamp
    @Column(updatable = false)
    private ZonedDateTime createdAt;
}
