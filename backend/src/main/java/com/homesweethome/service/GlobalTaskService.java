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

    // Create a new task (can originate from Chores, Health, or Finance)
    public GlobalTask createTask(Family family, String title, String originModule, 
                                 FamilyMember createdBy, FamilyMember assignedTo, 
                                 ZonedDateTime dueDate) {
        
        GlobalTask newTask = GlobalTask.builder()
                .family(family)
                .title(title)
                .originModule(originModule) // e.g., "HEALTH", "CHORES"
                .createdBy(createdBy)
                .assignedTo(assignedTo)
                .dueDate(dueDate)
                // Note: status defaults to "PENDING" automatically via our Entity builder
                .build();

        return globalTaskRepository.save(newTask);
    }

    // Fetch the unified dashboard feed for a family
    public List<GlobalTask> getAllTasksForFamily(UUID familyId) {
        return globalTaskRepository.findByFamilyId(familyId);
    }

    // Fetch only pending tasks
    public List<GlobalTask> getPendingTasksForFamily(UUID familyId) {
        return globalTaskRepository.findByFamilyIdAndStatus(familyId, "PENDING");
    }

    // Mark a task as completed
    @Transactional
    public GlobalTask completeTask(UUID taskId) {
        GlobalTask task = globalTaskRepository.findById(taskId)
                .orElseThrow(() -> new IllegalArgumentException("Task not found with ID: " + taskId));
        
        task.setStatus("COMPLETED");
        task.setCompletedAt(ZonedDateTime.now());
        
        return globalTaskRepository.save(task);
    }
}