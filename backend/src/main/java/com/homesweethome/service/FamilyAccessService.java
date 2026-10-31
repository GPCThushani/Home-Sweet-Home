package com.homesweethome.service;

import com.homesweethome.entity.FamilyMember;
import com.homesweethome.repository.FamilyMemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.AuthenticationCredentialsNotFoundException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class FamilyAccessService {
    private final FamilyMemberRepository members;

    public String authenticatedEmail() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated() || "anonymousUser".equals(auth.getName())) {
            throw new AuthenticationCredentialsNotFoundException("Authentication required");
        }
        return auth.getName();
    }

    public void requireMembership(String familyId) {
        try {
            requireMembership(UUID.fromString(familyId));
        } catch (IllegalArgumentException | NullPointerException ex) {
            throw new AccessDeniedException("Family access denied");
        }
    }

    public void requireMembership(UUID familyId) {
        if (familyId == null || !members.existsByFamilyIdAndUserEmail(familyId, authenticatedEmail())) {
            throw new AccessDeniedException("You are not a member of this family");
        }
    }

    public FamilyMember currentMember(UUID familyId) {
        requireMembership(familyId);
        return members.findByFamilyId(familyId).stream()
                .filter(member -> member.getUser().getEmail().equals(authenticatedEmail()))
                .findFirst().orElseThrow(() -> new AccessDeniedException("Family access denied"));
    }
}
