package com.homesweethome.dto;

import java.time.LocalDate;

public record PetProfileRequest(String name, String type, String breed, String gender,
        LocalDate dateOfBirth, Double weightKg, String color, String microchipId,
        String specialNotes, String photoUrl) {}
