package com.homesweethome.controller;

import com.homesweethome.entity.FamilyActivity;
import com.homesweethome.entity.FamilyMemory;
import com.homesweethome.repository.FamilyActivityRepository;
import com.homesweethome.repository.FamilyMemoryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/together")
@RequiredArgsConstructor
public class TogetherController {
    private final FamilyMemoryRepository memoryRepository;
    private final FamilyActivityRepository activityRepository;

    // --- Memories (Scrapbook) ---
    @GetMapping("/memories/{familyId}")
    public List<FamilyMemory> getMemories(@PathVariable String familyId) {
        return memoryRepository.findByFamilyIdOrderByMemoryDateDesc(familyId);
    }

    @PostMapping("/memories/{familyId}")
    public FamilyMemory addMemory(@PathVariable String familyId, @RequestBody FamilyMemory memory, Authentication auth) {
        memory.setFamilyId(familyId);
        String user = (auth != null && auth.getName() != null) ? auth.getName() : "Family Member";
        memory.setPostedBy(user);
        return memoryRepository.save(memory);
    }

    @DeleteMapping("/memories/{familyId}/{id}")
    public ResponseEntity<Void> deleteMemory(@PathVariable String familyId, @PathVariable Long id) {
        memoryRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    // --- Activities (Coming Together & Someday) ---
    @GetMapping("/activities/{familyId}")
    public List<FamilyActivity> getActivities(@PathVariable String familyId, @RequestParam(required = false) Boolean scheduled) {
        if (scheduled != null) {
            return activityRepository.findByFamilyIdAndScheduled(familyId, scheduled);
        }
        return activityRepository.findByFamilyId(familyId);
    }

    @PostMapping("/activities/{familyId}")
    public FamilyActivity saveActivity(@PathVariable String familyId, @RequestBody FamilyActivity activity, Authentication auth) {
        activity.setFamilyId(familyId);
        String user = (auth != null && auth.getName() != null) ? auth.getName() : "Family Member";
        activity.setCreatedBy(user);
        return activityRepository.save(activity);
    }

    @PutMapping("/activities/{familyId}/{id}/schedule")
    public FamilyActivity scheduleActivity(
            @PathVariable String familyId, 
            @PathVariable Long id, 
            @RequestBody FamilyActivity details) {
        FamilyActivity activity = activityRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Activity not found"));
        activity.setScheduled(true);
        activity.setScheduledDate(details.getScheduledDate());
        activity.setScheduledTime(details.getScheduledTime());
        return activityRepository.save(activity);
    }

    @DeleteMapping("/activities/{familyId}/{id}")
    public ResponseEntity<Void> deleteActivity(@PathVariable String familyId, @PathVariable Long id) {
        activityRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}