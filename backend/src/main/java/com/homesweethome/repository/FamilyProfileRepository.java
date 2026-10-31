package com.homesweethome.repository;

import com.homesweethome.entity.FamilyProfile;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

@Repository
public interface FamilyProfileRepository
        extends JpaRepository<FamilyProfile, UUID> {

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select profile from FamilyProfile profile where profile.id = :id")
    Optional<FamilyProfile> findHealthProfileForUpdate(@Param("id") UUID id);

    List<FamilyProfile> findByFamilyId(UUID familyId);

    boolean existsByIdAndFamilyId(UUID id, UUID familyId);

    Optional<FamilyProfile> findByFamilyIdAndLinkedUserEmailIgnoreCase(
            UUID familyId,
            String linkedUserEmail
    );
}
