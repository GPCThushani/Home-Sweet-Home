package com.homesweethome.repository;

import com.homesweethome.entity.HealthProfile;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface HealthProfileRepository
        extends JpaRepository<HealthProfile, Long> {

    Optional<HealthProfile> findByFamilyIdAndFamilyMemberId(
            String familyId,
            String familyMemberId
    );
}