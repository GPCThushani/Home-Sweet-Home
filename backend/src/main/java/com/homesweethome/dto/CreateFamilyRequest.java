package com.homesweethome.dto;

import java.util.UUID;

public record CreateFamilyRequest(
    String familyName,
    String timezone,
    UUID creatorId,
    String creatorNickname
) {}