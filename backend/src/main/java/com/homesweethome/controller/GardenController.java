package com.homesweethome.controller;

import com.homesweethome.entity.GardenPlant;
import com.homesweethome.entity.GardenRoutine;
import com.homesweethome.repository.GardenPlantRepository;
import com.homesweethome.repository.GardenRoutineRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/garden")
@RequiredArgsConstructor
public class GardenController {

    private final GardenPlantRepository plantRepository;
    private final GardenRoutineRepository routineRepository;

    // --- PLANTS ---
    @GetMapping("/plants/{familyId}")
    public ResponseEntity<List<GardenPlant>> getPlants(@PathVariable String familyId) {
        return ResponseEntity.ok(plantRepository.findByFamilyId(familyId));
    }

    @PostMapping("/plants/{familyId}")
    public ResponseEntity<GardenPlant> addPlant(@PathVariable String familyId, @RequestBody GardenPlant plant) {
        plant.setFamilyId(familyId);
        return ResponseEntity.ok(plantRepository.save(plant));
    }

    @DeleteMapping("/plants/{familyId}/{id}")
    public ResponseEntity<Void> deletePlant(@PathVariable String familyId, @PathVariable Long id) {
        plantRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    // --- ROUTINES & QUICK ACTIONS ---
    @GetMapping("/routines/{familyId}")
    public ResponseEntity<List<GardenRoutine>> getRoutines(@PathVariable String familyId, @RequestParam boolean quickAction) {
        return ResponseEntity.ok(routineRepository.findByFamilyIdAndIsQuickAction(familyId, quickAction));
    }

    @PostMapping("/routines/{familyId}")
    public ResponseEntity<GardenRoutine> saveRoutine(@PathVariable String familyId, @RequestBody GardenRoutine routine) {
        routine.setFamilyId(familyId);
        return ResponseEntity.ok(routineRepository.save(routine));
    }

    @PutMapping("/routines/{familyId}/{id}")
    public ResponseEntity<GardenRoutine> updateRoutine(@PathVariable String familyId, @PathVariable Long id, @RequestBody GardenRoutine incoming) {
        return routineRepository.findById(id).map(routine -> {
            routine.setTitle(incoming.getTitle());
            if (incoming.getFrequency() != null) routine.setFrequency(incoming.getFrequency());
            routine.setCompleted(incoming.isCompleted());
            return ResponseEntity.ok(routineRepository.save(routine));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/routines/{familyId}/{id}")
    public ResponseEntity<Void> deleteRoutine(@PathVariable String familyId, @PathVariable Long id) {
        routineRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}