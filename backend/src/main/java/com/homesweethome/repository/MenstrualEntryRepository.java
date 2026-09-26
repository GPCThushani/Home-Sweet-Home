package com.homesweethome.repository;

import com.homesweethome.entity.MenstrualEntry;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface MenstrualEntryRepository
        extends JpaRepository<MenstrualEntry, Long> {

    List<MenstrualEntry> findByFamilyIdAndFamilyMemberIdAndDateBetween(
            String familyId,
            String familyMemberId,
            java.time.LocalDate start,
            java.time.LocalDate end
    );
}