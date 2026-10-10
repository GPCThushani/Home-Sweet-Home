package com.homesweethome.repository;

import com.homesweethome.entity.GardenRoutine;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.*;

public interface GardenRoutineRepository extends JpaRepository<GardenRoutine, Long> {
    List<GardenRoutine> findByFamilyIdAndQuickActionAndActiveTrueOrderByIdAsc(String familyId, boolean quickAction);
    Optional<GardenRoutine> findByIdAndFamilyId(Long id, String familyId);
    boolean existsByFamilyId(String familyId);
}