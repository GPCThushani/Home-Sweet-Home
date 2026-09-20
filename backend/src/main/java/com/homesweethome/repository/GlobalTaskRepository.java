package com.homesweethome.repository;

import com.homesweethome.entity.GlobalTask;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface GlobalTaskRepository extends JpaRepository<GlobalTask, UUID> {
    
    // Fetch ALL tasks (pending and completed) for the family feed
    List<GlobalTask> findByFamilyIdOrderByCreatedAtDesc(UUID familyId);
}