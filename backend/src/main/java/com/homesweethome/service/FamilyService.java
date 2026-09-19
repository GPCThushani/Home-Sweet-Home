package com.homesweethome.service;

import com.homesweethome.entity.Family;
import com.homesweethome.entity.FamilyMember;
import com.homesweethome.entity.User;
import com.homesweethome.repository.FamilyMemberRepository;
import com.homesweethome.repository.FamilyRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class FamilyService {

    private final FamilyRepository familyRepository;
    private final FamilyMemberRepository familyMemberRepository;

    @Transactional
    public Family createFamily(String familyName, String timezone, User creator, String creatorNickname, String avatarPath) {
        // Generate a friendly unique invite code
        String uniqueInviteCode = "HSH-" + UUID.randomUUID().toString().substring(0, 6).toUpperCase();

        Family newFamily = Family.builder()
                .name(familyName)
                .timezone(timezone != null && !timezone.isEmpty() ? timezone : "Asia/Colombo")
                .adminEmail(creator.getEmail())
                .memberCount(1)
                .avatarPath(avatarPath)
                .inviteCode(uniqueInviteCode) // <-- Saves generated invite code
                .build();
        
        Family savedFamily = familyRepository.save(newFamily);

        FamilyMember creatorMember = FamilyMember.builder()
                .user(creator)
                .family(savedFamily)
                .role("PARENT")
                .nickname(creatorNickname != null && !creatorNickname.isEmpty() ? creatorNickname : "Admin")
                .build();

        familyMemberRepository.save(creatorMember);

        return savedFamily;
    }

    @Transactional
    public FamilyMember joinFamily(UUID familyId, User user, String nickname, String role) {
        Family family = familyRepository.findById(familyId)
                .orElseThrow(() -> new IllegalArgumentException("Family not found"));

        FamilyMember newMember = FamilyMember.builder()
                .family(family)
                .user(user)
                .nickname(nickname != null && !nickname.isEmpty() ? nickname : "Member")
                .role(role != null && !role.isEmpty() ? role : "MEMBER")
                .build();

        // Increment member count on the family entity
        family.setMemberCount(family.getMemberCount() + 1);
        familyRepository.save(family);

        return familyMemberRepository.save(newMember);
    }

    // Lookup family by invite code
    public Family findByInviteCode(String inviteCode) {
        return familyRepository.findAll().stream()
                .filter(f -> f.getInviteCode() != null && f.getInviteCode().equalsIgnoreCase(inviteCode.trim()))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Invalid invite code. Family not found."));
    }

    public List<Family> getFamiliesByUserEmail(String email) {
        List<FamilyMember> memberships = familyMemberRepository.findByUserEmail(email);
        return memberships.stream()
                .map(FamilyMember::getFamily)
                .distinct()
                .toList();
    }
}