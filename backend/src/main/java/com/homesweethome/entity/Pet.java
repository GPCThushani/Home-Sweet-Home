package com.homesweethome.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "pets")
@Data
public class Pet {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false)
    private UUID familyId;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private String type; // Dog, Cat, Bird, Parrot, Fish, Rabbit, Guinea Pigs, Turtle, Other

    private String breed;
    private String gender;
    private LocalDate dateOfBirth;
    private Double weightKg;
    private String color;
    private String microchipId;

    @Column(length = 1000)
    private String specialNotes;

    private String photoUrl;
}