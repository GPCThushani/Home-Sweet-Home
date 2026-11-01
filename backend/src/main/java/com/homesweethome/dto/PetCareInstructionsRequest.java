package com.homesweethome.dto;
public record PetCareInstructionsRequest(String foodType, String foodBrand, String portionSize,
        String feedingInstructions, String dietaryNotes, String exerciseInstructions, Integer walkingMinutes,
        String groomingInstructions, String bathingInstructions, String generalInstructions, String handlingInstructions) {}
