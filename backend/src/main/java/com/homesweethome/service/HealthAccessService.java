package com.homesweethome.service;

import com.homesweethome.entity.FamilyProfile;
import com.homesweethome.repository.FamilyProfileRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class HealthAccessService {
    private final FamilyAccessService familyAccess;
    private final FamilyProfileRepository profiles;

    public void requireProfile(String familyId, String profileId) {
        UUID family = canonicalUuid(familyId);
        familyAccess.requireMembership(family);
        UUID profile = canonicalUuid(profileId);
        if (!profiles.existsByIdAndFamilyId(profile, family)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Household profile not found in this family");
        }
    }

    // Writers serialize on the household person, not an account/membership.
    // This also protects first profile saves and medicine stock updates.
    public void lockProfile(String familyId, String profileId) {
        requireProfile(familyId, profileId);
        FamilyProfile profile = profiles.findHealthProfileForUpdate(canonicalUuid(profileId))
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Household profile not found"));
        if (!profile.getFamily().getId().equals(canonicalUuid(familyId))) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Household profile not found in this family");
        }
    }

    public String actorProfileId(String familyId) {
        return profiles.findByFamilyIdAndLinkedUserEmailIgnoreCase(canonicalUuid(familyId),
                familyAccess.authenticatedEmail()).map(profile -> profile.getId().toString()).orElse(null);
    }

    private UUID canonicalUuid(String value) {
        try {
            UUID uuid = UUID.fromString(value);
            if (!uuid.toString().equals(value)) throw new IllegalArgumentException();
            return uuid;
        } catch (IllegalArgumentException | NullPointerException ex) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "A valid household profile and family UUID are required");
        }
    }
}
