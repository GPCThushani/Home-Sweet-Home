package com.homesweethome.controller;

import com.homesweethome.dto.CreateFamilyRequest;
import com.homesweethome.dto.JoinFamilyRequest;
import com.homesweethome.entity.Family;
import com.homesweethome.entity.FamilyMember;
import com.homesweethome.entity.FamilyProfile;
import com.homesweethome.entity.User;
import com.homesweethome.repository.FamilyMemberRepository;
import com.homesweethome.repository.FamilyProfileRepository;
import com.homesweethome.repository.UserRepository;
import com.homesweethome.service.FamilyRosterService;
import com.homesweethome.service.FamilyService;

import lombok.RequiredArgsConstructor;

import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/families")
@RequiredArgsConstructor
public class FamilyController {

    private final FamilyService familyService;
    private final FamilyRosterService familyRosterService;
    private final UserRepository userRepository;
    private final FamilyMemberRepository familyMemberRepository;
    private final FamilyProfileRepository familyProfileRepository;

    private String authenticatedEmail(
            Authentication authentication
    ) {
        if (authentication == null
                || !authentication.isAuthenticated()
                || "anonymousUser".equals(
                        authentication.getName()
                )) {
            throw new AccessDeniedException(
                    "Authentication required"
            );
        }

        return authentication.getName();
    }

    private void requireSelf(
            Authentication authentication,
            String email
    ) {
        if (!authenticatedEmail(authentication)
                .equalsIgnoreCase(email)) {
            throw new AccessDeniedException(
                    "You cannot act for another user"
            );
        }
    }

    private void requireMembership(
            UUID familyId,
            Authentication authentication
    ) {
        String email = authenticatedEmail(authentication);

        if (!familyMemberRepository
                .existsByFamilyIdAndUserEmail(
                        familyId,
                        email
                )) {
            throw new AccessDeniedException(
                    "You are not a member of this family"
            );
        }
    }

    private UUID optionalProfileId(
            String value
    ) {
        if (value == null || value.isBlank()) {
            return null;
        }

        return UUID.fromString(value);
    }

    private Map<String, Object> memberResponse(
            FamilyMember member
    ) {
        Map<String, Object> result =
                new LinkedHashMap<>();

        UUID familyId = member.getFamily().getId();
        String email = member.getUser().getEmail();

        FamilyProfile linkedProfile =
                familyProfileRepository
                        .findByFamilyId(familyId)
                        .stream()
                        .filter(profile ->
                                profile.getLinkedUserEmail() != null
                                        && profile.getLinkedUserEmail()
                                        .equalsIgnoreCase(email)
                        )
                        .findFirst()
                        .orElse(null);

        result.put("id", member.getId().toString());
        result.put("membershipId", member.getId().toString());
        result.put("userId",
                member.getUser().getId().toString());
        result.put("email", email);
        result.put("familyId", familyId.toString());

        result.put(
                "name",
                linkedProfile != null
                        ? linkedProfile.getName()
                        : member.getNickname()
        );

        result.put(
                "role",
                linkedProfile != null
                        ? linkedProfile.getRole()
                        : null
        );

        result.put("systemRole", member.getRole());
        result.put("relationship", linkedProfile != null ? linkedProfile.getRole() : null);
        result.put("nickname", member.getNickname());

        result.put(
                "profileId",
                linkedProfile != null
                        ? linkedProfile.getId().toString()
                        : null
        );

        result.put("hasAccount", true);
        result.put("joinedAt", member.getJoinedAt());

        return result;
    }

    @GetMapping("/user")
    public ResponseEntity<List<Family>>
    getFamiliesByUserEmail(
            @RequestParam String email,
            Authentication authentication
    ) {
        requireSelf(authentication, email);

        return ResponseEntity.ok(
                familyService.getFamiliesByUserEmail(email)
        );
    }

    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<Map<String, String>> familyError(ResponseStatusException exception) {
        return ResponseEntity.status(exception.getStatusCode()).body(Map.of("error",
                exception.getReason() == null ? "Family request failed" : exception.getReason()));
    }

    @PostMapping("/invitations/preview")
    public ResponseEntity<Map<String, Object>> previewInvitation(
            @RequestBody Map<String, String> request, Authentication authentication) {
        String email = authenticatedEmail(authentication);
        Family family = familyService.findByInviteCode(request.get("inviteCode"));
        return ResponseEntity.ok(Map.of("familyId", family.getId().toString(),
                "familyName", family.getName(), "profiles",
                familyRosterService.getInvitationProfiles(family.getId(), email)));
    }

    @GetMapping("/{familyId}/profiles")
    public ResponseEntity<List<Map<String, Object>>>
    getFamilyProfiles(
            @PathVariable UUID familyId,
            Authentication authentication
    ) {
        return ResponseEntity.ok(
                familyRosterService.getProfiles(
                        familyId,
                        authentication != null ? authentication.getName() : null
                )
        );
    }

    @GetMapping("/{familyId}/members")
    public ResponseEntity<List<Map<String, Object>>>
    getFamilyMembers(
            @PathVariable UUID familyId,
            Authentication authentication
    ) {
        requireMembership(familyId, authentication);
        List<Map<String, Object>> members =
                familyMemberRepository
                        .findByFamilyId(familyId)
                        .stream()
                        .map(this::memberResponse)
                        .toList();

        return ResponseEntity.ok(members);
    }

    @GetMapping("/{familyId}/members/logged")
    public ResponseEntity<List<Map<String, Object>>>
    getLoggedFamilyMembers(
            @PathVariable UUID familyId,
            Authentication authentication
    ) {
        requireMembership(familyId, authentication);
        List<Map<String, Object>> members =
                familyMemberRepository
                        .findByFamilyIdAndUserIsNotNull(familyId)
                        .stream()
                        .map(this::memberResponse)
                        .toList();

        return ResponseEntity.ok(members);
    }

    @PostMapping
    public ResponseEntity<Family> createFamily(
            @RequestBody CreateFamilyRequest request,
            Authentication authentication
    ) {
        User creator = userRepository
                .findById(request.creatorId())
                .orElseThrow(() ->
                        new IllegalArgumentException(
                                "User not found"
                        )
                );

        requireSelf(authentication, creator.getEmail());
        Family family = familyService.createFamilyWithProfiles(
                request.familyName(),
                request.timezone(),
                creator,
                request.creatorNickname(),
                request.avatarPath(),
                request.members(),
                request.creatorProfileIndex()
        );

        return ResponseEntity.ok(family);
    }

    @PostMapping("/{familyId}/join")
    public ResponseEntity<Map<String, Object>> joinFamily(
            @PathVariable UUID familyId,
            @RequestBody JoinFamilyRequest request,
            Authentication authentication
    ) {
        User user = (request.userId() == null
                ? userRepository.findByEmail(authenticatedEmail(authentication))
                : userRepository.findById(request.userId()))
                .orElseThrow(() ->
                        new IllegalArgumentException(
                                "User not found"
                        )
                );

        requireSelf(authentication, user.getEmail());
        if (!familyService.findByInviteCode(request.inviteCode()).getId().equals(familyId)) {
            throw new AccessDeniedException("Invalid invitation for this family");
        }
        FamilyMember member = familyService.joinFamily(
                familyId,
                user,
                request.nickname(),
                "MEMBER",
                request.profileId()
        );

        return ResponseEntity.ok(
                memberResponse(member)
        );
    }

    @PostMapping("/join-by-code")
    public ResponseEntity<?> joinFamilyByCode(
            @RequestBody Map<String, String> request,
            Authentication authentication
    ) {
        try {
            String inviteCode = request.get("inviteCode");
            String userIdStr = request.get("userId");
            String nickname = request.get("nickname");
            String profileIdStr = request.get("profileId");

            if (inviteCode == null || inviteCode.isBlank()) {
                return ResponseEntity.badRequest().body(
                        Map.of(
                                "error",
                                "inviteCode is required"
                        )
                );
            }

            Family family =
                    familyService.findByInviteCode(inviteCode);

            User user = (userIdStr == null
                    ? userRepository.findByEmail(authenticatedEmail(authentication))
                    : userRepository.findById(UUID.fromString(userIdStr)))
                    .orElseThrow(() ->
                            new IllegalArgumentException(
                                    "User not found"
                            )
                    );

            requireSelf(authentication, user.getEmail());
            UUID profileId =
                    optionalProfileId(profileIdStr);

            FamilyMember membership = familyService.joinFamily(
                    family.getId(),
                    user,
                    nickname,
                    "MEMBER",
                    profileId
            );

            return ResponseEntity.ok(
                    Map.of(
                            "message",
                            "Successfully joined family!",
                            "familyName",
                            family.getName(),
                            "familyId",
                            family.getId().toString(),
                            "membershipId", membership.getId().toString(),
                            "profileId", memberResponse(membership).get("profileId")
                    )
            );

        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(
                    Map.of("error", e.getMessage())
            );
        }
    }

    @PostMapping("/{familyId}/profiles/{profileId}/link-self")
    public ResponseEntity<?> linkMyProfile(
            @PathVariable UUID familyId,
            @PathVariable UUID profileId,
            Authentication authentication
    ) {
        requireMembership(familyId, authentication);
        String email = authenticatedEmail(authentication);

        User user = userRepository
                .findByEmail(email)
                .orElseThrow(() ->
                        new IllegalArgumentException(
                                "User not found"
                        )
                );

        familyRosterService.linkProfileToUser(
                familyId,
                profileId,
                user
        );

        return ResponseEntity.ok(
                Map.of(
                        "message",
                        "Profile linked successfully",
                        "profileId",
                        profileId.toString()
                )
        );
    }
}
