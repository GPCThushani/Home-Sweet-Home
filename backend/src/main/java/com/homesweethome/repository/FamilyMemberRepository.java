package com.homesweethome.repository;

import com.homesweethome.entity.Family;
import com.homesweethome.entity.FamilyMember;
import com.homesweethome.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface FamilyMemberRepository extends JpaRepository<FamilyMember, UUID> {
    
    // 1. Fetch memberships by email
    @Query("SELECT fm FROM FamilyMember fm JOIN fm.user u WHERE u.email = :email")
    List<FamilyMember> findByUserEmail(@Param("email") String email);
    
    // 2. Check membership by IDs
    Optional<FamilyMember> findByUserIdAndFamilyId(UUID userId, UUID familyId);

    // 3. Fetch all members belonging to a specific family ID using explicit JPQL query
    @Query("SELECT fm FROM FamilyMember fm WHERE fm.family.id = :familyId")
    List<FamilyMember> findByFamilyId(@Param("familyId") UUID familyId);

    // 4. Find specific family member record by family and user entities using explicit JPQL query
    @Query("SELECT fm FROM FamilyMember fm WHERE fm.family = :family AND fm.user = :user")
    Optional<FamilyMember> findByFamilyAndUser(@Param("family") Family family, @Param("user") User user);

    // 5. Fetch only family members who have an active registered/logged-in user account linked
    @Query("SELECT fm FROM FamilyMember fm WHERE fm.family.id = :familyId AND fm.user IS NOT NULL")
    List<FamilyMember> findByFamilyIdAndUserIsNotNull(@Param("familyId") UUID familyId);
}