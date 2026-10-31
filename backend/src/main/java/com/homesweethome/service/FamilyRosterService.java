
package com.homesweethome.service;

import com.homesweethome.dto.FamilyProfileInput;
import com.homesweethome.entity.Family;
import com.homesweethome.entity.FamilyProfile;
import com.homesweethome.entity.User;
import com.homesweethome.repository.FamilyMemberRepository;
import com.homesweethome.repository.FamilyProfileRepository;
import com.homesweethome.repository.FamilyRepository;

import lombok.RequiredArgsConstructor;

import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.Set;
import java.util.HashSet;
import java.util.Locale;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

@Service
@RequiredArgsConstructor
public class FamilyRosterService {

    private final FamilyProfileRepository familyProfileRepository;
    private final FamilyMemberRepository familyMemberRepository;
    private final FamilyRepository familyRepository;

    @Transactional
    public void createInitialProfiles(
            Family family,
            User creatorUser,
            List<FamilyProfileInput> memberInputs,
            Integer creatorIndex
    ) {
        if (memberInputs == null || memberInputs.isEmpty()) {
            throw new IllegalArgumentException(
                    "At least one family profile is required"
            );
        }

        if (creatorIndex == null
                || creatorIndex < 0
                || creatorIndex >= memberInputs.size()) {
            throw new IllegalArgumentException(
                    "Please select a valid creator profile"
            );
        }

        familyRepository.findByIdForUpdate(family.getId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Family not found"));
        if (!familyProfileRepository.findByFamilyId(family.getId()).isEmpty()) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "This family already has household profiles");
        }

        Set<List<String>> seen = new HashSet<>();
        for (int i = 0; i < memberInputs.size(); i++) {
            FamilyProfileInput input = memberInputs.get(i);

            if (input == null
                    || input.name() == null
                    || input.name().isBlank()
                    || input.role() == null
                    || input.role().isBlank()) {
                throw new IllegalArgumentException(
                        "Every family profile needs a name and role"
                );
            }

            List<String> identity = List.of(input.name().trim().toLowerCase(Locale.ROOT),
                    input.role().trim().toLowerCase(Locale.ROOT),
                    input.gender() == null ? "" : input.gender().trim().toLowerCase(Locale.ROOT));
            if (!seen.add(identity)) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                        "The same household profile was entered more than once");
            }

            FamilyProfile profile = new FamilyProfile();

            profile.setFamily(family);
            profile.setName(input.name().trim());
            profile.setRole(input.role().trim());
            profile.setGender(input.gender());

            profile.setInvitePreferred(
                    Boolean.TRUE.equals(input.invitePreferred())
            );

            if (i == creatorIndex) {
                profile.setLinkedUserEmail(creatorUser.getEmail());
            }

            familyProfileRepository.save(profile);
        }
    }

    @Transactional
    public void linkProfileToUser(
            UUID familyId,
            UUID profileId,
            User user
    ) {
        familyRepository.findByIdForUpdate(familyId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Family not found"));
        if (!familyMemberRepository.existsByFamilyIdAndUserEmail(familyId, user.getEmail())) {
            throw new AccessDeniedException("You are not a member of this family");
        }
        if (profileId == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Profile ID is required"
            );
        }

        FamilyProfile target = familyProfileRepository
                .findById(profileId)
                .orElseThrow(() ->
                        new ResponseStatusException(HttpStatus.NOT_FOUND,
                                "Family profile not found"
                        )
                );

        if (!target.getFamily().getId().equals(familyId)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Profile does not belong to this family"
            );
        }

        String email = user.getEmail();

        if (target.getLinkedUserEmail() != null
                && !target.getLinkedUserEmail().isBlank()
                && !target.getLinkedUserEmail()
                        .equalsIgnoreCase(email)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "This profile is linked to another account"
            );
        }

        List<FamilyProfile> profiles =
                familyProfileRepository.findByFamilyId(familyId);

        for (FamilyProfile profile : profiles) {
            if (!profile.getId().equals(profileId)
                    && profile.getLinkedUserEmail() != null
                    && profile.getLinkedUserEmail()
                            .equalsIgnoreCase(email)) {
                throw new ResponseStatusException(HttpStatus.CONFLICT,
                        "Your account is already linked to another profile"
                );
            }
        }

        target.setLinkedUserEmail(email);
        familyProfileRepository.save(target);
    }

    @Transactional(readOnly = true)
    public List<Map<String, Object>> getProfiles(
            UUID familyId,
            String requesterEmail
    ) {
        if (requesterEmail == null
                || requesterEmail.isBlank()
                || !familyMemberRepository
                        .existsByFamilyIdAndUserEmail(
                                familyId,
                                requesterEmail
                        )) {
            throw new AccessDeniedException(
                    "You are not a member of this family"
            );
        }

        List<FamilyProfile> profiles =
                familyProfileRepository.findByFamilyId(familyId);

        return profileResponses(profiles, requesterEmail);
    }

    // Called only after the controller validates the invitation through FamilyService.
    @Transactional(readOnly = true)
    public List<Map<String, Object>> getInvitationProfiles(UUID familyId, String requesterEmail) {
        List<Map<String, Object>> profiles = profileResponses(
                familyProfileRepository.findByFamilyId(familyId), requesterEmail);
        List<Map<String, Object>> self = profiles.stream()
                .filter(profile -> Boolean.TRUE.equals(profile.get("isSelf"))).toList();
        return self.isEmpty() ? profiles.stream()
                .filter(profile -> !Boolean.TRUE.equals(profile.get("hasAccount"))).toList() : self;
    }

    private List<Map<String, Object>> profileResponses(List<FamilyProfile> profiles, String requesterEmail) {
        List<Map<String, Object>> result = new ArrayList<>();

        for (FamilyProfile profile : profiles) {
            Map<String, Object> item = new LinkedHashMap<>();

            item.put("id", profile.getId().toString());
            item.put("profileId", profile.getId().toString());
            item.put("familyId", profile.getFamily().getId().toString());
            item.put("name", profile.getName());
            item.put("role", profile.getRole());
            item.put("relationship", profile.getRole());
            item.put("gender", profile.getGender());
            item.put("isSelf", profile.getLinkedUserEmail() != null
                    && profile.getLinkedUserEmail().equalsIgnoreCase(requesterEmail));
            item.put(
                    "invitePreferred",
                    profile.isInvitePreferred()
            );

            item.put(
                    "hasAccount",
                    profile.getLinkedUserEmail() != null
                            && !profile.getLinkedUserEmail().isBlank()
            );

            result.add(item);
        }

        return result;
    }
}
