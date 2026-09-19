package com.homesweethome.repository;

import com.homesweethome.entity.Family;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface FamilyRepository extends JpaRepository<Family, UUID> {
    // Find families created/managed by this email
    List<Family> findByAdminEmail(String adminEmail);
}