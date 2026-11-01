package com.homesweethome.controller;

import com.homesweethome.dto.PetProfileRequest;
import com.homesweethome.entity.Pet;
import com.homesweethome.repository.PetRepository;
import com.homesweethome.repository.*;
import com.homesweethome.service.FamilyAccessService;
import com.homesweethome.service.PetDocumentStorage;
import com.homesweethome.service.PetPhotoStorage;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/pets")
@RequiredArgsConstructor
public class PetController {
    private final PetRepository pets;
    private final FamilyAccessService access;
    private final PetPhotoStorage photos;
    private final PetDocumentStorage documentStorage;
    private final PetDocumentRepository documents;
    private final PetEntryRepository entries;
    private final PetCareScheduleRepository schedules;
    private final PetCareInstructionsRepository instructions;
    private final GlobalTaskRepository tasks;

    @GetMapping("/{familyId}")
    public List<Pet> list(@PathVariable UUID familyId) {
        access.requireMembership(familyId);
        return pets.findByFamilyId(familyId);
    }

    @GetMapping("/item/{id}")
    public Pet get(@PathVariable UUID id) { return owned(id); }

    @PostMapping("/{familyId}")
    public ResponseEntity<Pet> create(@PathVariable UUID familyId, @RequestBody PetProfileRequest input) {
        access.requireMembership(familyId);
        Pet pet = new Pet();
        pet.setFamilyId(familyId);
        copy(input, pet);
        return ResponseEntity.status(HttpStatus.CREATED).body(pets.save(pet));
    }

    @PutMapping({"/{id}", "/update/{id}"})
    public Pet update(@PathVariable UUID id, @RequestBody PetProfileRequest input) {
        Pet pet = owned(id);
        copy(input, pet);
        return pets.save(pet);
    }

    @PostMapping(value = "/{id}/photo", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public Pet uploadPhoto(@PathVariable UUID id, @RequestParam MultipartFile file) {
        Pet pet = owned(id);
        pet.setPhotoUrl(photos.save(pet, file));
        return pets.save(pet);
    }

    @GetMapping("/{id}/photo")
    public ResponseEntity<byte[]> photo(@PathVariable UUID id) {
        Pet pet = owned(id);
        if (!("/api/pets/" + id + "/photo").equals(pet.getPhotoUrl()))
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Photo unavailable");
        return ResponseEntity.ok().contentType(MediaType.parseMediaType(photos.type(pet))).body(photos.read(pet));
    }

    @DeleteMapping("/{id}")
    @Transactional
    public ResponseEntity<Void> delete(@PathVariable UUID id) {
        Pet pet = owned(id);
        tasks.findBySourcePetId(id).stream()
                .filter(task -> !"COMPLETED".equals(task.getStatus()))
                .forEach(tasks::delete);
        documents.findByPetIdOrderByUploadedAtDesc(id).forEach(doc -> {
            documents.delete(doc);
            documentStorage.removeAfterCommit(doc);
        });
        entries.deleteAll(entries.findByPetId(id));
        schedules.deleteAll(schedules.findByPetId(id));
        instructions.findById(id).ifPresent(instructions::delete);
        pets.delete(pet);
        photos.deleteAfterCommit(pet);
        return ResponseEntity.noContent().build();
    }

    private Pet owned(UUID id) {
        Pet pet = pets.findById(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Pet not found"));
        access.requireMembership(pet.getFamilyId());
        return pet;
    }

    private void copy(PetProfileRequest input, Pet pet) {
        pet.setName(required(input.name(), 255, "Pet name is required"));
        pet.setType(required(input.type(), 255, "Pet type is required"));
        pet.setBreed(optional(input.breed(), 255));
        pet.setGender(optional(input.gender(), 255));
        pet.setColor(optional(input.color(), 255));
        pet.setMicrochipId(optional(input.microchipId(), 255));
        pet.setSpecialNotes(optional(input.specialNotes(), 1000));
        if (input.dateOfBirth() != null && input.dateOfBirth().isAfter(LocalDate.now()))
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Date of birth cannot be in the future");
        if (input.weightKg() != null && (!Double.isFinite(input.weightKg()) || input.weightKg() <= 0 || input.weightKg() > 10000))
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Weight must be a positive number");
        pet.setDateOfBirth(input.dateOfBirth());
        pet.setWeightKg(input.weightKg());
        // A client can choose an app preset. Uploaded photo paths are assigned only by the photo endpoint.
        String preset = input.photoUrl();
        if (preset != null && preset.startsWith("assets/images/pets/") && !preset.contains(".."))
            pet.setPhotoUrl(preset);
        else if (preset != null && !preset.isBlank() && !preset.equals(pet.getPhotoUrl()))
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Upload a photo using the photo endpoint");
    }

    private String required(String value, int limit, String message) {
        String result = optional(value, limit);
        if (result == null) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, message);
        return result;
    }
    private String optional(String value, int limit) {
        if (value == null || value.isBlank()) return null;
        String result = value.trim();
        if (result.length() > limit) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Pet details are too long");
        return result;
    }
}
