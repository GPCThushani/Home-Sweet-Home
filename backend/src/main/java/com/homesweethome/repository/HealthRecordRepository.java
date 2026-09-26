package com.homesweethome.repository;

import com.homesweethome.entity.HealthRecord;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface HealthRecordRepository
        extends JpaRepository<HealthRecord, Long> {

    List<HealthRecord> findByFamilyIdAndFamilyMemberIdOrderByRecordDateDesc(
            String familyId,
            String familyMemberId
    );
}