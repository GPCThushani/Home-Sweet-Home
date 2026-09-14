package com.homesweethome.repository;

import com.homesweethome.entity.FamilyMember;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface FamilyMemberRepository extends JpaRepository<FamilyMember, UUID> {
    
    // Finds everyone living in a specific digital home
    List<FamilyMember> findByFamilyId(UUID familyId);
    
    // Checks if a user is already part of a specific family
    Optional<FamilyMember> findByUserIdAndFamilyId(UUID userId, UUID familyId);
}