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
@Table(name = "users")
@Data // Lombok: Generates getters, setters, toString, etc.
@NoArgsConstructor // Lombok: Generates an empty constructor required by JPA
@AllArgsConstructor // Lombok: Generates a full constructor
@Builder // Lombok: Helps us easily build User objects later
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(nullable = false)
    private String passwordHash;

    @CreationTimestamp
    @Column(updatable = false)
    private ZonedDateTime createdAt;
}
