package com.homesweethome.service;

import com.homesweethome.entity.Pet;
import com.homesweethome.repository.PetRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class PetAccessService {
    private final PetRepository pets;
    private final FamilyAccessService familyAccess;
    public Pet require(UUID petId) {
        Pet pet = pets.findById(petId).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Pet not found"));
        familyAccess.requireMembership(pet.getFamilyId());
        return pet;
    }
}
