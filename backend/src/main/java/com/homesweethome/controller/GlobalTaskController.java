package com.homesweethome.controller;

import com.homesweethome.dto.CreateTaskRequest;
import com.homesweethome.dto.TaskResponse;
import jakarta.validation.Valid;
import org.springframework.web.server.ResponseStatusException;
import com.homesweethome.dto.UpdateTaskRequest;
import com.homesweethome.entity.Family;
import com.homesweethome.entity.FamilyMember;
import com.homesweethome.entity.GlobalTask;
import com.homesweethome.repository.FamilyMemberRepository;
import com.homesweethome.repository.FamilyRepository;
import com.homesweethome.service.GlobalTaskService;
import lombok.RequiredArgsConstructor;
import com.homesweethome.service.FamilyAccessService;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/tasks")
@RequiredArgsConstructor
@org.springframework.transaction.annotation.Transactional
public class GlobalTaskController {

    private final FamilyAccessService access;

    private final GlobalTaskService globalTaskService;
    private final FamilyRepository familyRepository;
    private final FamilyMemberRepository familyMemberRepository;

    @PostMapping
    public ResponseEntity<TaskResponse> createTask(@Valid @RequestBody CreateTaskRequest request, Authentication authentication) {
        access.requireMembership(request.familyId());
        Family family = familyRepository.findById(request.familyId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Family not found"));
                
        FamilyMember creator = access.currentMember(family.getId());
        if (request.creatorMemberId() != null && !request.creatorMemberId().equals(creator.getId())) {
            throw new AccessDeniedException("You cannot create a task as another member");
        }
        FamilyMember assignee = authorizedAssignee(request.assignedToMemberId(), family.getId());

        GlobalTask newTask = globalTaskService.createTask(
                family, 
                request.title(), 
                request.description(), 
                request.originModule(), 
                creator, 
                assignee, 
                request.dueDate()
        );

        return ResponseEntity.status(HttpStatus.CREATED).body(TaskResponse.from(newTask));
    }

    @GetMapping("/family/{familyId}")
    public ResponseEntity<List<TaskResponse>> getFamilyTasks(@PathVariable UUID familyId) {
        access.requireMembership(familyId);
        List<GlobalTask> tasks = globalTaskService.getAllTasksForFamily(familyId);
        return ResponseEntity.ok(tasks.stream().map(TaskResponse::from).toList());
    }

    @PutMapping("/{taskId}")
    public ResponseEntity<TaskResponse> updateTask(@PathVariable UUID taskId, @Valid @RequestBody UpdateTaskRequest request) {
        GlobalTask task = globalTaskService.getTaskById(taskId);
        access.requireMembership(task.getFamily().getId());
        FamilyMember assignee = authorizedAssignee(request.assignedToMemberId(), task.getFamily().getId());

        GlobalTask updatedTask = globalTaskService.updateTask(
                taskId,
                request.title(),
                request.description(),
                request.originModule(),
                assignee,
                request.dueDate()
        );

        return ResponseEntity.ok(TaskResponse.from(updatedTask));
    }

    @PutMapping("/{taskId}/complete")
    public ResponseEntity<TaskResponse> completeTask(@PathVariable UUID taskId, Authentication authentication) {
        GlobalTask task = globalTaskService.getTaskById(taskId);
        
        FamilyMember completer = access.currentMember(task.getFamily().getId());

        GlobalTask completedTask = globalTaskService.completeTask(taskId, completer);
        return ResponseEntity.ok(TaskResponse.from(completedTask));
    }

    @DeleteMapping("/{taskId}")
    public ResponseEntity<Void> deleteTask(@PathVariable UUID taskId) {
        access.requireMembership(globalTaskService.getTaskById(taskId).getFamily().getId());
        globalTaskService.deleteTask(taskId);
        return ResponseEntity.noContent().build();
    }
    private FamilyMember authorizedAssignee(UUID memberId, UUID familyId) {
        if (memberId == null) return null;
        FamilyMember member = familyMemberRepository.findById(memberId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Member not found"));
        if (!familyId.equals(member.getFamily().getId())) {
            throw new AccessDeniedException("Assignee belongs to another family");
        }
        return member;
    }

    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<java.util.Map<String,String>> taskError(ResponseStatusException ex) {
        return ResponseEntity.status(ex.getStatusCode()).body(java.util.Map.of("error", ex.getReason() == null ? "Task request failed" : ex.getReason()));
    }

}