package com.homesweethome.controller;

import com.homesweethome.dto.CreateFamilyRequest;
import com.homesweethome.dto.JoinFamilyRequest;
import com.homesweethome.entity.Family;
import com.homesweethome.entity.FamilyMember;
import com.homesweethome.entity.User;
import com.homesweethome.repository.UserRepository;
import com.homesweethome.service.FamilyService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/families")
@RequiredArgsConstructor
public class FamilyController {

    private final FamilyService familyService;
    private final UserRepository userRepository;

    @GetMapping("/user")
    public ResponseEntity<List<Family>> getFamiliesByUserEmail(@RequestParam String email) {
        List<Family> families = familyService.getFamiliesByUserEmail(email);
        return ResponseEntity.ok(families);
    }

    @PostMapping
    public ResponseEntity<Family> createFamily(@RequestBody CreateFamilyRequest request) {
        User creator = userRepository.findById(request.creatorId())
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        Family newFamily = familyService.createFamily(
                request.familyName(),
                request.timezone(),
                creator,
                request.creatorNickname(),
                request.avatarPath()
        );

        return ResponseEntity.ok(newFamily);
    }

    @PostMapping("/{familyId}/join")
    public ResponseEntity<FamilyMember> joinFamily(
            @PathVariable UUID familyId,
            @RequestBody JoinFamilyRequest request) {
        
        User user = userRepository.findById(request.userId())
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        FamilyMember member = familyService.joinFamily(
                familyId, user, request.nickname(), request.role()
        );

        return ResponseEntity.ok(member);
    }

    // NEW: Join family via invite code endpoint
    @PostMapping("/join-by-code")
    public ResponseEntity<?> joinFamilyByCode(@RequestBody Map<String, String> request) {
        try {
            String inviteCode = request.get("inviteCode");
            String userIdStr = request.get("userId");
            String nickname = request.get("nickname");
            String role = request.get("role");

            if (inviteCode == null || userIdStr == null) {
                return ResponseEntity.badRequest().body(Map.of("error", "inviteCode and userId are required"));
            }

            Family family = familyService.findByInviteCode(inviteCode);
            User user = userRepository.findById(UUID.fromString(userIdStr))
                    .orElseThrow(() -> new IllegalArgumentException("User not found"));

            FamilyMember member = familyService.joinFamily(
                    family.getId(),
                    user,
                    nickname != null ? nickname : "Member",
                    role != null ? role : "MEMBER"
            );

            return ResponseEntity.ok(Map.of(
                    "message", "Successfully joined family!",
                    "familyName", family.getName(),
                    "familyId", family.getId().toString()
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
}