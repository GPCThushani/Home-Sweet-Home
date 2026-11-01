package com.homesweethome.entity;
import jakarta.persistence.*;
import lombok.Data;
import java.util.UUID;
@Entity @Table(name = "pet_care_instructions") @Data
public class PetCareInstructions {
    @Id private UUID petId;
    @Column(nullable = false) private UUID familyId;
    private String foodType;
    private String foodBrand;
    private String portionSize;
    @Column(length = 2000) private String feedingInstructions;
    @Column(length = 2000) private String dietaryNotes;
    @Column(length = 2000) private String exerciseInstructions;
    private Integer walkingMinutes;
    @Column(length = 2000) private String groomingInstructions;
    @Column(length = 2000) private String bathingInstructions;
    @Column(length = 2000) private String generalInstructions;
    @Column(length = 2000) private String handlingInstructions;
}
