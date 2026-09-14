package com.homesweethome.controller;

import com.homesweethome.dto.CreateTaskRequest;
import com.homesweethome.entity.Family;
import com.homesweethome.entity.FamilyMember;
import com.homesweethome.entity.GlobalTask;
import com.homesweethome.repository.FamilyMemberRepository;
import com.homesweethome.repository.FamilyRepository;
import com.homesweethome.service.GlobalTaskService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
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

    // 1. Create a new task
    @PostMapping
    public ResponseEntity<GlobalTask> createTask(@RequestBody CreateTaskRequest request) {
        Family family = familyRepository.findById(request.familyId())
                .orElseThrow(() -> new IllegalArgumentException("Family not found"));
                
        FamilyMember creator = familyMemberRepository.findById(request.creatorMemberId())
                .orElseThrow(() -> new IllegalArgumentException("Creator not found"));
                
        FamilyMember assignee = null;
        if (request.assignedToMemberId() != null) {
            assignee = familyMemberRepository.findById(request.assignedToMemberId())
                    .orElseThrow(() -> new IllegalArgumentException("Assignee not found"));
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
}