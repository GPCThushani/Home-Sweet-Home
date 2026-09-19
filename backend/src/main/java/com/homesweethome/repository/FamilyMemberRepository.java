package com.homesweethome.repository;

import com.homesweethome.entity.FamilyMember;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface FamilyMemberRepository extends JpaRepository<FamilyMember, UUID> {
    
    // Safely joins User to fetch family memberships by email via direct JPQL query
    @Query("SELECT fm FROM FamilyMember fm JOIN fm.user u WHERE u.email = :email")
    List<FamilyMember> findByUserEmail(@Param("email") String email);
    
    // Checks if a user is already part of a specific family
    Optional<FamilyMember> findByUserIdAndFamilyId(UUID userId, UUID familyId);
}