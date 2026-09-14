package com.homesweethome.repository;

import com.homesweethome.entity.GlobalTask;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface GlobalTaskRepository extends JpaRepository<GlobalTask, UUID> {
    
    // Fetch all tasks for the family feed
    List<GlobalTask> findByFamilyId(UUID familyId);
    
    // Fetch tasks by family and status (e.g., all "PENDING" tasks)
    List<GlobalTask> findByFamilyIdAndStatus(UUID familyId, String status);
}
