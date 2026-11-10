package com.homesweethome.controller;

import com.homesweethome.entity.EmergencyContact;
import com.homesweethome.repository.EmergencyContactRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/emergency-contacts")
@RequiredArgsConstructor
public class EmergencyContactController {

    private final EmergencyContactRepository repository;

    @GetMapping("/{familyId}")
    public ResponseEntity<List<EmergencyContact>> getContacts(@PathVariable UUID familyId) {
        return ResponseEntity.ok(repository.findByFamilyId(familyId));
    }

    @PostMapping("/{familyId}")
    public ResponseEntity<EmergencyContact> createContact(
            @PathVariable UUID familyId,
            @RequestBody EmergencyContact contact
    ) {
        contact.setFamilyId(familyId);
        EmergencyContact saved = repository.save(contact);
        return ResponseEntity.status(HttpStatus.CREATED).body(saved);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteContact(@PathVariable UUID id) {
        if (repository.existsById(id)) {
            repository.deleteById(id);
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.notFound().build();
    }
}