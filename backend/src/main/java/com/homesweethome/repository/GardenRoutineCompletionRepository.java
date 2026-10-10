package com.homesweethome.repository;

import com.homesweethome.entity.GardenRoutineCompletion;
import org.springframework.data.jpa.repository.JpaRepository;
import java.time.LocalDate;
import java.util.*;

public interface GardenRoutineCompletionRepository extends JpaRepository<GardenRoutineCompletion, Long> {
    Optional<GardenRoutineCompletion> findByRoutineIdAndOccurrenceDate(Long routineId, LocalDate occurrenceDate);
    List<GardenRoutineCompletion> findByRoutineIdOrderByCompletedAtDesc(Long routineId);
    List<GardenRoutineCompletion> findByFamilyIdOrderByCompletedAtDesc(String familyId);
    void deleteByRoutineId(Long routineId);
}