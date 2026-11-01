package com.homesweethome.repository;

import com.homesweethome.entity.GlobalTask;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface GlobalTaskRepository extends JpaRepository<GlobalTask, UUID> {
    @org.springframework.data.jpa.repository.Lock(jakarta.persistence.LockModeType.PESSIMISTIC_WRITE)
    @org.springframework.data.jpa.repository.Query("select task from GlobalTask task where task.id = :id")
    java.util.Optional<GlobalTask> findForUpdate(@org.springframework.data.repository.query.Param("id") UUID id);
    
    // Fetch ALL tasks (pending and completed) for the family feed
    List<GlobalTask> findByFamilyIdOrderByCreatedAtDesc(UUID familyId);
    List<GlobalTask> findBySourceCareScheduleId(UUID id);
    List<GlobalTask> findBySourcePetEntryId(UUID id);
    List<GlobalTask> findBySourcePetIdAndStatusOrderByCompletedAtDesc(UUID petId, String status);
    List<GlobalTask> findBySourcePetId(UUID petId);
}
