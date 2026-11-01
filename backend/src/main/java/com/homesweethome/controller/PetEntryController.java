package com.homesweethome.controller;
import com.homesweethome.dto.PetEntryRequest;
import com.homesweethome.entity.PetEntry;
import com.homesweethome.service.PetEntryService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import java.util.*;

@RestController
@RequestMapping("/api/pets/{petId}/entries/{kind}")
@RequiredArgsConstructor
public class PetEntryController {
    private final PetEntryService service;
    @GetMapping public List<PetEntry> list(@PathVariable UUID petId, @PathVariable String kind) { return service.list(petId, kind); }
    @GetMapping("/{id}") public PetEntry get(@PathVariable UUID petId, @PathVariable String kind, @PathVariable UUID id) { return service.get(petId, kind, id); }
    @PostMapping public ResponseEntity<PetEntry> create(@PathVariable UUID petId, @PathVariable String kind, @RequestBody PetEntryRequest input) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.save(petId, kind, null, input));
    }
    @PutMapping("/{id}") public PetEntry update(@PathVariable UUID petId, @PathVariable String kind, @PathVariable UUID id, @RequestBody PetEntryRequest input) {
        return service.save(petId, kind, id, input);
    }
    @DeleteMapping("/{id}") public ResponseEntity<Void> delete(@PathVariable UUID petId, @PathVariable String kind, @PathVariable UUID id) {
        service.delete(petId, kind, id); return ResponseEntity.noContent().build();
    }
}
