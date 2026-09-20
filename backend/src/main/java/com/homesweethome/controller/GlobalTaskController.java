package com.homesweethome.controller;

import com.homesweethome.dto.CreateTaskRequest;
import com.homesweethome.entity.Family;
import com.homesweethome.entity.FamilyMember;
import com.homesweethome.entity.GlobalTask;
import com.homesweethome.entity.User;
import com.homesweethome.repository.FamilyMemberRepository;
import com.homesweethome.repository.FamilyRepository;
import com.homesweethome.repository.UserRepository;
import com.homesweethome.service.GlobalTaskService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/tasks")
@RequiredArgsConstructor
public class GlobalTaskController {

    private final GlobalTaskService globalTaskService;
    private final FamilyRepository familyRepository;
    private final FamilyMemberRepository familyMemberRepository;
    private final UserRepository userRepository;

    // 1. Create a new task
    @PostMapping
    public ResponseEntity<GlobalTask> createTask(@RequestBody CreateTaskRequest request, Authentication authentication) {
        Family family = familyRepository.findById(request.familyId())
                .orElseThrow(() -> new IllegalArgumentException("Family not found"));
                
        FamilyMember creator = null;
        
        if (request.creatorMemberId() != null) {
            creator = familyMemberRepository.findById(request.creatorMemberId()).orElse(null);
        }

        // Fallback: If creatorMemberId wasn't provided or found, look up via authenticated user email
        if (creator == null && authentication != null) {
            String email = authentication.getName();
            User user = userRepository.findByEmail(email).orElse(null);
            if (user != null) {
                creator = familyMemberRepository.findByFamilyAndUser(family, user).orElse(null);
            }
        }

        // Ultimate fallback: If still null, grab the first member of this family
        if (creator == null) {
            List<FamilyMember> members = familyMemberRepository.findByFamilyId(family.getId());
            if (!members.isEmpty()) {
                creator = members.get(0);
            } else {
                throw new IllegalArgumentException("No valid family member found to attribute as task creator.");
            }
        }
                
        FamilyMember assignee = null;
        if (request.assignedToMemberId() != null) {
            assignee = familyMemberRepository.findById(request.assignedToMemberId()).orElse(null);
        }

        GlobalTask newTask = globalTaskService.createTask(
                family, request.title(), request.originModule(), creator, assignee, request.dueDate()
        );

        return ResponseEntity.ok(newTask);
    }

    // 2. Get the unified feed for a specific family
    @GetMapping("/family/{familyId}")
    public ResponseEntity<List<GlobalTask>> getFamilyTasks(@PathVariable UUID familyId) {
        List<GlobalTask> tasks = globalTaskService.getPendingTasksForFamily(familyId);
        return ResponseEntity.ok(tasks);
    }

    // 3. Mark a task as completed
    @PutMapping("/{taskId}/complete")
    public ResponseEntity<GlobalTask> completeTask(@PathVariable UUID taskId) {
        GlobalTask completedTask = globalTaskService.completeTask(taskId);
        return ResponseEntity.ok(completedTask);
    }
}