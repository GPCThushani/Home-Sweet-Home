package com.homesweethome.repository;

import com.homesweethome.entity.GardenPlant;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.*;

public interface GardenPlantRepository extends JpaRepository<GardenPlant, Long> {
    List<GardenPlant> findByFamilyId(String familyId);
    Optional<GardenPlant> findByIdAndFamilyId(Long id, String familyId);
}