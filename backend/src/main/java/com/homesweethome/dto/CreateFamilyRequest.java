package com.homesweethome.dto;

import java.util.List;
import java.util.UUID;

public record CreateFamilyRequest(
        UUID creatorId,
        String familyName,
        String timezone,
        String creatorNickname,
        String avatarPath,
        List<FamilyProfileInput> members,
        Integer creatorProfileIndex
) {}