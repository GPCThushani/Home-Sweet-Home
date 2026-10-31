package com.homesweethome.dto;

public record FamilyProfileInput(
        String name,
        String role,
        String gender,
        Boolean invitePreferred
) {}