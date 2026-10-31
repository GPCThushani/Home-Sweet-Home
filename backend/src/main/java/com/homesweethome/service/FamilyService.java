
package com.homesweethome.service;

import com.homesweethome.dto.FamilyProfileInput;
import com.homesweethome.entity.Family;
import com.homesweethome.entity.FamilyMember;
import com.homesweethome.entity.FamilyProfile;
import com.homesweethome.repository.FamilyProfileRepository;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;
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
    private final FamilyRosterService familyRosterService;
    private final FamilyProfileRepository familyProfileRepository;

    @Transactional
    public Family createFamily(
            String familyName,
            String timezone,
            User creator,
            String creatorNickname,
            String avatarPath
    ) {
        if (familyName == null || familyName.isBlank()) {
            throw new IllegalArgumentException(
                    "Family name is required"
            );
        }

        String inviteCode;
        boolean codeExists;

        do {
            inviteCode = "HSH-" +
                    UUID.randomUUID()
                            .toString()
                            .substring(0, 6)
                            .toUpperCase();

            final String candidate = inviteCode;

            codeExists = familyRepository.findAll()
                    .stream()
                    .anyMatch(f ->
                            f.getInviteCode() != null
                                    && f.getInviteCode()
                                    .equalsIgnoreCase(candidate)
                    );

        } while (codeExists);

        Family family = Family.builder()
                .name(familyName.trim())
                .timezone(
                        timezone == null || timezone.isBlank()
                                ? "Asia/Colombo"
                                : timezone
                )
                .adminEmail(creator.getEmail())
                .memberCount(1)
                .avatarPath(avatarPath)
                .inviteCode(inviteCode)
                .build();

        Family savedFamily = familyRepository.save(family);

        FamilyMember creatorMember = FamilyMember.builder()
                .family(savedFamily)
                .user(creator)
                .role("PARENT")
                .nickname(
                        creatorNickname == null
                                || creatorNickname.isBlank()
                                ? "Admin"
                                : creatorNickname.trim()
                )
                .build();

        familyMemberRepository.save(creatorMember);

        return savedFamily;
    }

    @Transactional
    public Family createFamilyWithProfiles(
            String familyName,
            String timezone,
            User creator,
            String creatorNickname,
            String avatarPath,
            List<FamilyProfileInput> members,
            Integer creatorProfileIndex
    ) {
        if (members == null || members.isEmpty()) {
            throw new IllegalArgumentException(
                    "Add at least one family member"
            );
        }

        if (creatorProfileIndex == null
                || creatorProfileIndex < 0
                || creatorProfileIndex >= members.size()) {
            throw new IllegalArgumentException(
                    "Invalid creator profile selection"
            );
        }

        Family family = createFamily(
                familyName,
                timezone,
                creator,
                creatorNickname,
                avatarPath
        );

        familyRosterService.createInitialProfiles(
                family,
                creator,
                members,
                creatorProfileIndex
        );

        family.setMemberCount(members.size());

        return familyRepository.save(family);
    }

    @Transactional
    public FamilyMember joinFamily(
            UUID familyId,
            User user,
            String nickname,
            String role
    ) {
        return joinFamily(
                familyId,
                user,
                nickname,
                role,
                null
        );
    }

    @Transactional
    public FamilyMember joinFamily(
            UUID familyId,
            User user,
            String nickname,
            String role,
            UUID profileId
    ) {
        // All join/link writers lock the same existing family row. This covers
        // concurrent retries, two accounts claiming a profile, and one account
        // attempting to claim two different profiles without a schema change.
        Family family = familyRepository.findByIdForUpdate(familyId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Family not found"));
        FamilyMember existing = familyMemberRepository.findByUserIdAndFamilyId(user.getId(), familyId)
                .orElse(null);
        UUID targetId = profileId;
        if (targetId == null) {
            targetId = familyProfileRepository.findByFamilyIdAndLinkedUserEmailIgnoreCase(familyId, user.getEmail())
                    .map(FamilyProfile::getId).orElseThrow(() -> new ResponseStatusException(
                            HttpStatus.BAD_REQUEST, "Choose your existing household profile before joining"));
        }
        FamilyMember member = existing;
        if (member == null) {
            member = familyMemberRepository.save(FamilyMember.builder()
                    .family(family).user(user).role("MEMBER")
                    .nickname(nickname == null || nickname.isBlank() ? "Member" : nickname.trim()).build());
        }
        // Both operations participate in this transaction. A rejected claim
        // rolls back any new membership; no profile or membership is duplicated.
        familyRosterService.linkProfileToUser(familyId, targetId, user);
        return member;
    }

    @Transactional(readOnly = true)
    public Family findByInviteCode(String inviteCode) {
        if (inviteCode == null || inviteCode.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Invitation code is required"
            );
        }

        return familyRepository.findAll()
                .stream()
                .filter(f ->
                        f.getInviteCode() != null
                                && f.getInviteCode()
                                .equalsIgnoreCase(inviteCode.trim())
                )
                .findFirst()
                .orElseThrow(() ->
                        new ResponseStatusException(HttpStatus.BAD_REQUEST,
                                "Invalid family invitation code"
                        )
                );
    }

    @Transactional(readOnly = true)
    public List<Family> getFamiliesByUserEmail(String email) {
        return familyMemberRepository.findByUserEmail(email)
                .stream()
                .map(FamilyMember::getFamily)
                .distinct()
                .toList();
    }
}
