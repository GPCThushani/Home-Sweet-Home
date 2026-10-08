package com.homesweethome.repository;

import com.homesweethome.entity.GardenPlant;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface GardenPlantRepository extends JpaRepository<GardenPlant, Long> {
    List<GardenPlant> findByFamilyId(String familyId);
}