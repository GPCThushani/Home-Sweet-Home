package com.homesweethome.repository;

import com.homesweethome.entity.MaintenanceRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface MaintenanceRecordRepository extends JpaRepository<MaintenanceRecord, Long> {
    List<MaintenanceRecord> findByFamilyIdOrderByServiceDateDesc(String familyId);
    List<MaintenanceRecord> findByItemIdOrderByServiceDateDesc(Long itemId);
    void deleteByItemId(Long itemId);
}