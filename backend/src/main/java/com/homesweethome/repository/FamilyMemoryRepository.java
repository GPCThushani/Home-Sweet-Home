package com.homesweethome.repository;

import com.homesweethome.entity.FamilyMemory;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface FamilyMemoryRepository extends JpaRepository<FamilyMemory, Long> {
    List<FamilyMemory> findByFamilyIdOrderByMemoryDateDesc(String familyId);
}