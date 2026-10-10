package com.homesweethome.controller;

import com.homesweethome.dto.*;
import com.homesweethome.entity.*;
import com.homesweethome.repository.GardenPlantRepository;
import com.homesweethome.service.GardenService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@RestController
@RequestMapping("/api/garden")
@RequiredArgsConstructor
public class GardenController {
    private final GardenPlantRepository plants;
    private final GardenService garden;

    @GetMapping("/plants/{familyId}")
    public List<GardenPlant> plants(@PathVariable String familyId){
        return plants.findByFamilyId(familyId);
    }

    @PostMapping("/plants/{familyId}")
    public GardenPlant addPlant(@PathVariable String familyId, @RequestBody GardenPlant plant){
        if(plant.getName() == null || plant.getName().isBlank() || plant.getCategory() == null || plant.getCategory().isBlank())
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Name and category required");
        plant.setId(null);
        plant.setFamilyId(familyId);
        return plants.save(plant);
    }

    @DeleteMapping("/plants/{familyId}/{id}")
    public ResponseEntity<Void> deletePlant(@PathVariable String familyId, @PathVariable Long id){
        GardenPlant p = plants.findByIdAndFamilyId(id, familyId).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
        plants.delete(p);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/routines/{familyId}")
    public List<GardenRoutineView> routines(@PathVariable String familyId, @RequestParam(defaultValue="false") boolean quickAction){
        return garden.list(familyId, quickAction);
    }

    @PostMapping("/routines/{familyId}")
    public GardenRoutineView addRoutine(@PathVariable String familyId, @RequestBody GardenRoutineRequest request){
        return garden.add(familyId, request);
    }

    @PutMapping("/routines/{familyId}/{id}")
    public GardenRoutineView editRoutine(@PathVariable String familyId, @PathVariable Long id, @RequestBody GardenRoutineRequest request){
        return garden.edit(familyId, id, request);
    }

    @PostMapping("/routines/{familyId}/{id}/complete")
    public GardenRoutineView complete(@PathVariable String familyId, @PathVariable Long id, Authentication auth){
        String username = (auth != null && auth.getName() != null) ? auth.getName() : "Family Member";
        return garden.complete(familyId, id, username);
    }

    @PostMapping("/routines/{familyId}/{id}/completion")
    public GardenRoutineView undo(@PathVariable String familyId, @PathVariable Long id){
        return garden.undo(familyId, id);
    }

    @DeleteMapping("/routines/{familyId}/{id}")
    public ResponseEntity<Void> deleteRoutine(@PathVariable String familyId, @PathVariable Long id){
        garden.delete(familyId, id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/routines/{familyId}/history")
    public List<GardenRoutineCompletion> history(@PathVariable String familyId){
        return garden.history(familyId);
    }
}