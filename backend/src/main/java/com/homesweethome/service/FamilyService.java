package com.homesweethome.service;

import com.homesweethome.entity.Family;
import com.homesweethome.entity.FamilyMember;
import com.homesweethome.entity.User;
import com.homesweethome.repository.FamilyMemberRepository;
import com.homesweethome.repository.FamilyRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class FamilyService {

    private final FamilyRepository familyRepository;
    private final FamilyMemberRepository familyMemberRepository;

    @Transactional
    public Family createFamily(String familyName, String timezone, User creator, String creatorNickname) {
        // 1. Create and save the new Family
        Family newFamily = Family.builder()
                .name(familyName)
                .timezone(timezone != null && !timezone.isEmpty() ? timezone : "Asia/Colombo")
                .build();
        
        Family savedFamily = familyRepository.save(newFamily);

        // 2. Automatically link the creator as the first member with the 'PARENT' role
        FamilyMember creatorMember = FamilyMember.builder()
                .user(creator)
                .family(savedFamily)
                .role("PARENT") // Defaulting to PARENT for the creator
                .nickname(creatorNickname) // e.g., "Amma" or "Thaththa"
                .build();

        familyMemberRepository.save(creatorMember);

        return savedFamily;
    }
}