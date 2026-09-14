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

import java.util.UUID;

@RestController
@RequestMapping("/api/families")
@RequiredArgsConstructor
public class FamilyController {

    private final FamilyService familyService;
    private final UserRepository userRepository;

    @PostMapping
    public ResponseEntity<Family> createFamily(@RequestBody CreateFamilyRequest request) {
        // 1. Verify the user actually exists in the database
        User creator = userRepository.findById(request.creatorId())
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        // 2. Trigger the transactional service to create the Family and FamilyMember bridge
        Family newFamily = familyService.createFamily(
                request.familyName(),
                request.timezone(),
                creator,
                request.creatorNickname()
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
}