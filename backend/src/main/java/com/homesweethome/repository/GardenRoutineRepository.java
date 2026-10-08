package com.homesweethome.repository;

import com.homesweethome.entity.GardenRoutine;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface GardenRoutineRepository extends JpaRepository<GardenRoutine, Long> {
    List<GardenRoutine> findByFamilyIdAndIsQuickAction(String familyId, boolean isQuickAction);
}