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
    
    // 1. Fetch memberships by email with user fetched
    @Query("SELECT fm FROM FamilyMember fm JOIN FETCH fm.user u WHERE u.email = :email")
    List<FamilyMember> findByUserEmail(@Param("email") String email);
    
    // 2. Check membership by IDs
    Optional<FamilyMember> findByUserIdAndFamilyId(UUID userId, UUID familyId);

    // 3. Fetch all members with user joined to prevent lazy loading nulls
    @Query("SELECT fm FROM FamilyMember fm JOIN FETCH fm.user WHERE fm.family.id = :familyId")
    List<FamilyMember> findByFamilyId(@Param("familyId") UUID familyId);

    // 4. Find specific family member record by family and user entities
    @Query("SELECT fm FROM FamilyMember fm WHERE fm.family = :family AND fm.user = :user")
    Optional<FamilyMember> findByFamilyAndUser(@Param("family") Family family, @Param("user") User user);

    // 5. Fetch registered members with user joined
    @Query("SELECT fm FROM FamilyMember fm JOIN FETCH fm.user WHERE fm.family.id = :familyId AND fm.user IS NOT NULL")
    List<FamilyMember> findByFamilyIdAndUserIsNotNull(@Param("familyId") UUID familyId);
}