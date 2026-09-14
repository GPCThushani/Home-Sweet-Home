package com.homesweethome.dto;

import java.util.UUID;

public record JoinFamilyRequest(
    UUID userId,
    String nickname,
    String role // e.g., "PARENT", "CHILD"
) {}