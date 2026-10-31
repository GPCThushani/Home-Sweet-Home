package com.homesweethome.repository;

import com.homesweethome.entity.Family;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;
import java.util.Optional;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

@Repository
public interface FamilyRepository extends JpaRepository<Family, UUID> {
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select family from Family family where family.id = :id")
    Optional<Family> findByIdForUpdate(@Param("id") UUID id);

    // Find families created/managed by this email
    List<Family> findByAdminEmail(String adminEmail);
}
