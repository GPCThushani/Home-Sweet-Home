package com.homesweethome.dto;

import java.time.Instant;
import java.util.UUID;

public record FamilyDocumentResponse(
        UUID id, UUID familyId, UUID familyProfileId, String familyProfileName,
        String title, String description, String category, String fileName,
        String fileType, long fileSize, Instant uploadedAt, boolean shared,
        String fileUrl
) {}
