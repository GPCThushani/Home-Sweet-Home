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
        Family newFamily = Family.builder()
                .name(familyName)
                .timezone(timezone != null && !timezone.isEmpty() ? timezone : "Asia/Colombo")
                .adminEmail(creator.getEmail())
                .memberCount(1)
                .avatarPath(avatarPath) // <-- Saves the selected avatar path/asset
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
                .nickname(nickname)
                .role(role)
                .build();

        return familyMemberRepository.save(newMember);
    }

    public List<Family> getFamiliesByUserEmail(String email) {
        List<FamilyMember> memberships = familyMemberRepository.findByUserEmail(email);
        return memberships.stream()
                .map(FamilyMember::getFamily)
                .distinct()
                .toList();
    }
}