package com.homesweethome.repository;

import com.homesweethome.entity.MedicineLog;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface MedicineLogRepository
        extends JpaRepository<MedicineLog, Long> {

    List<MedicineLog> findByFamilyIdAndFamilyMemberIdOrderByScheduledAtDesc(
            String familyId,
            String familyMemberId
    );
}