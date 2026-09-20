package com.homesweethome.service;

import com.homesweethome.entity.Family;
import com.homesweethome.entity.FamilyMember;
import com.homesweethome.entity.GlobalTask;
import com.homesweethome.repository.GlobalTaskRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.ZonedDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class GlobalTaskService {

    private final GlobalTaskRepository globalTaskRepository;

    @Transactional
    public GlobalTask createTask(
            Family family,
            String title,
            String description,
            String originModule,
            FamilyMember createdBy,
            FamilyMember assignedTo,
            ZonedDateTime dueDate
    ) {
        GlobalTask newTask = GlobalTask.builder()
                .family(family)
                .title(title)
                .description(description)
                .originModule(originModule)
                .createdBy(createdBy)
                .assignedTo(assignedTo)
                .dueDate(dueDate)
                .status("PENDING")
                .build();

        return globalTaskRepository.save(newTask);
    }

    @Transactional(readOnly = true)
    public List<GlobalTask> getAllTasksForFamily(UUID familyId) {
        return globalTaskRepository.findByFamilyIdOrderByCreatedAtDesc(familyId);
    }

    @Transactional(readOnly = true)
    public GlobalTask getTaskById(UUID taskId) {
        return globalTaskRepository.findById(taskId)
                .orElseThrow(() -> new IllegalArgumentException("Task not found with ID: " + taskId));
    }

    @Transactional
    public GlobalTask updateTask(
            UUID taskId,
            String title,
            String description,
            String originModule,
            FamilyMember assignedTo,
            ZonedDateTime dueDate
    ) {
        GlobalTask task = globalTaskRepository.findById(taskId)
                .orElseThrow(() -> new IllegalArgumentException("Task not found with ID: " + taskId));

        task.setTitle(title);
        task.setDescription(description);
        task.setOriginModule(originModule);
        task.setAssignedTo(assignedTo);
        task.setDueDate(dueDate);

        return globalTaskRepository.save(task);
    }

    @Transactional
    public GlobalTask completeTask(UUID taskId, FamilyMember completer) {
        GlobalTask task = globalTaskRepository.findById(taskId)
                .orElseThrow(() -> new IllegalArgumentException("Task not found with ID: " + taskId));
        
        task.setStatus("COMPLETED");
        task.setCompletedAt(ZonedDateTime.now());
        task.setCompletedBy(completer); 
        
        return globalTaskRepository.save(task);
    }

    @Transactional
    public void deleteTask(UUID taskId) {
        GlobalTask task = globalTaskRepository.findById(taskId)
                .orElseThrow(() -> new IllegalArgumentException("Task not found with ID: " + taskId));
        globalTaskRepository.delete(task);
    }
}