package com.homesweethome.dto;

import java.util.UUID;

public record AuthenticationResponse(
    String token,
    UUID userId,
    String email
) {}