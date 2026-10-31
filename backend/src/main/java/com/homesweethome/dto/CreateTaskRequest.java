package com.homesweethome.dto;

import java.time.ZonedDateTime;
import java.util.UUID;
import jakarta.validation.constraints.*;

public record CreateTaskRequest(
        @NotNull UUID familyId,
        @NotBlank @Size(max = 255) String title,
        String description,
        @NotBlank @Size(max = 50) String originModule,
        UUID creatorMemberId,
        UUID assignedToMemberId,
        ZonedDateTime dueDate
) {}