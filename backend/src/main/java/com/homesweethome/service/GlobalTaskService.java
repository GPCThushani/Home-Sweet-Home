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
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.AccessDeniedException;

@Service
@RequiredArgsConstructor
public class GlobalTaskService {

    private final GlobalTaskRepository globalTaskRepository;
    private final jakarta.persistence.EntityManager entityManager;

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
        validate(title, originModule);
        if (createdBy == null || !family.getId().equals(createdBy.getFamily().getId()) || (assignedTo != null && !family.getId().equals(assignedTo.getFamily().getId()))) throw new AccessDeniedException("Task members must belong to the family");
        GlobalTask newTask = GlobalTask.builder()
                .family(family)
                .title(title.trim())
                .description(description)
                .originModule(originModule)
                .createdBy(createdBy)
                .assignedTo(assignedTo)
                .dueDate(dueDate)
                .status("PENDING")
                .build();

        return globalTaskRepository.saveAndFlush(newTask);
    }

    @Transactional(readOnly = true)
    public List<GlobalTask> getAllTasksForFamily(UUID familyId) {
        return globalTaskRepository.findByFamilyIdOrderByCreatedAtDesc(familyId);
    }

    @Transactional(readOnly = true)
    public GlobalTask getTaskById(UUID taskId) {
        return globalTaskRepository.findById(taskId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Task not found"));
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
        GlobalTask task = locked(taskId);

        validate(title, originModule);
        if (assignedTo != null && !task.getFamily().getId().equals(assignedTo.getFamily().getId())) throw new AccessDeniedException("Assignee belongs to another family");
        task.setTitle(title.trim());
        task.setDescription(description);
        task.setOriginModule(originModule);
        task.setAssignedTo(assignedTo);
        task.setDueDate(dueDate);

        return globalTaskRepository.save(task);
    }

    @Transactional
    public GlobalTask completeTask(UUID taskId, FamilyMember completer) {
        GlobalTask task = locked(taskId);
        
        if (completer == null || !task.getFamily().getId().equals(completer.getFamily().getId())) throw new AccessDeniedException("Completer belongs to another family");
        if ("COMPLETED".equals(task.getStatus())) return task;
        task.setStatus("COMPLETED");
        task.setCompletedAt(ZonedDateTime.now().truncatedTo(java.time.temporal.ChronoUnit.MICROS));
        task.setCompletedBy(completer); 
        
        return globalTaskRepository.save(task);
    }

    @Transactional
    public void deleteTask(UUID taskId) {
        GlobalTask task = locked(taskId);
        globalTaskRepository.delete(task);
    }
    private GlobalTask locked(UUID id) {
        GlobalTask task = globalTaskRepository.findForUpdate(id)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Task not found"));
        // Authorization may already have loaded this entity before the write lock.
        // Refresh after locking so a concurrent completion cannot be overwritten.
        entityManager.refresh(task);
        return task;
    }
    private void validate(String title, String module) {
        if (title == null || title.isBlank() || title.length() > 255 || module == null || module.isBlank() || module.length() > 50)
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Task title and category are required and must fit their field limits");
    }

}