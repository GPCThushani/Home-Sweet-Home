package com.homesweethome.dto;

import java.util.UUID;

public record JoinFamilyRequest(
    UUID userId,
    String nickname,
    String role, // System role is assigned by the server.
    String inviteCode,
    UUID profileId
) {}
