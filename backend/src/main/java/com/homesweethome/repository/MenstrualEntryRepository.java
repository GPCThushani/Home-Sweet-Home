package com.homesweethome.repository;

import com.homesweethome.entity.MenstrualEntry;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface MenstrualEntryRepository
        extends JpaRepository<MenstrualEntry, Long> {

    Optional<MenstrualEntry> findByFamilyIdAndFamilyMemberIdAndDate(String familyId, String memberId, java.time.LocalDate date);

    List<MenstrualEntry> findByFamilyIdAndFamilyMemberIdAndDateBetween(
            String familyId,
            String familyMemberId,
            java.time.LocalDate start,
            java.time.LocalDate end
    );
}
