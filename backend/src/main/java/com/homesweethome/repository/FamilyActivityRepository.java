package com.homesweethome.repository;

import com.homesweethome.entity.FamilyActivity;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface FamilyActivityRepository extends JpaRepository<FamilyActivity, Long> {
    List<FamilyActivity> findByFamilyIdAndScheduled(String familyId, boolean scheduled);
    List<FamilyActivity> findByFamilyId(String familyId);
}