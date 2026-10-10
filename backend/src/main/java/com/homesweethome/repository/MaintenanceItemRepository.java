package com.homesweethome.repository;

import com.homesweethome.entity.MaintenanceItem;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface MaintenanceItemRepository extends JpaRepository<MaintenanceItem, Long> {
    List<MaintenanceItem> findByFamilyIdAndActiveTrueOrderByIdAsc(String familyId);
    Optional<MaintenanceItem> findByIdAndFamilyId(Long id, String familyId);
}