package com.homesweethome.controller;
import com.homesweethome.dto.PetCareScheduleRequest;
import com.homesweethome.entity.PetCareSchedule;
import com.homesweethome.service.PetCareScheduleService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import java.util.*;

@RestController @RequestMapping("/api/pets/{petId}/care-schedules") @RequiredArgsConstructor
public class PetCareScheduleController {
    private final PetCareScheduleService service;
    @GetMapping public List<PetCareSchedule> list(@PathVariable UUID petId) { return service.list(petId); }
    @GetMapping("/{id}") public PetCareSchedule get(@PathVariable UUID petId, @PathVariable UUID id) { return service.get(petId, id); }
    @PostMapping public ResponseEntity<PetCareSchedule> create(@PathVariable UUID petId, @RequestBody PetCareScheduleRequest input) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.save(petId, null, input));
    }
    @PutMapping("/{id}") public PetCareSchedule update(@PathVariable UUID petId, @PathVariable UUID id, @RequestBody PetCareScheduleRequest input) {
        return service.save(petId, id, input);
    }
    @DeleteMapping("/{id}") public ResponseEntity<Void> delete(@PathVariable UUID petId, @PathVariable UUID id) {
        service.delete(petId, id); return ResponseEntity.noContent().build();
    }
}
