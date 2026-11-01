package com.homesweethome.controller;
import com.homesweethome.dto.*;
import com.homesweethome.entity.*;
import com.homesweethome.repository.*;
import com.homesweethome.service.PetAccessService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import java.util.*;

@RestController @RequestMapping("/api/pets/{petId}/daily-care") @RequiredArgsConstructor
public class PetDailyCareController {
    private final PetAccessService access;
    private final PetCareInstructionsRepository instructions;
    private final GlobalTaskRepository tasks;
    @GetMapping("/instructions")
    public PetCareInstructions get(@PathVariable UUID petId) {
        access.require(petId);
        return instructions.findById(petId).orElseGet(() -> {
            PetCareInstructions empty = new PetCareInstructions(); empty.setPetId(petId);
            empty.setFamilyId(access.require(petId).getFamilyId()); return empty;
        });
    }
    @PutMapping("/instructions") @Transactional
    public PetCareInstructions save(@PathVariable UUID petId, @RequestBody PetCareInstructionsRequest request) {
        Pet pet = access.require(petId);
        if (request.walkingMinutes() != null && (request.walkingMinutes() < 0 || request.walkingMinutes() > 1440))
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Walking duration must be between 0 and 1440 minutes");
        PetCareInstructions value = instructions.findById(petId).orElseGet(PetCareInstructions::new);
        value.setPetId(petId); value.setFamilyId(pet.getFamilyId());
        value.setFoodType(text(request.foodType(), 255)); value.setFoodBrand(text(request.foodBrand(), 255));
        value.setPortionSize(text(request.portionSize(), 255)); value.setFeedingInstructions(text(request.feedingInstructions(), 2000));
        value.setDietaryNotes(text(request.dietaryNotes(), 2000)); value.setExerciseInstructions(text(request.exerciseInstructions(), 2000));
        value.setWalkingMinutes(request.walkingMinutes()); value.setGroomingInstructions(text(request.groomingInstructions(), 2000));
        value.setBathingInstructions(text(request.bathingInstructions(), 2000)); value.setGeneralInstructions(text(request.generalInstructions(), 2000));
        value.setHandlingInstructions(text(request.handlingInstructions(), 2000));
        return instructions.save(value);
    }
    @GetMapping("/history") @Transactional(readOnly = true)
    public List<TaskResponse> history(@PathVariable UUID petId) {
        access.require(petId);
        return tasks.findBySourcePetIdAndStatusOrderByCompletedAtDesc(petId, "COMPLETED")
                .stream().filter(t -> "PETS".equals(t.getOriginModule())).map(TaskResponse::from).toList();
    }
    private String text(String value, int max) {
        if (value == null || value.isBlank()) return null;
        String result = value.trim();
        if (result.length() > max) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Care instructions are too long");
        return result;
    }
}
