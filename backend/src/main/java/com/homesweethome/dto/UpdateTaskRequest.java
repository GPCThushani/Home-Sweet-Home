package com.homesweethome.dto;

import java.time.ZonedDateTime;
import java.util.UUID;
import jakarta.validation.constraints.*;

public record UpdateTaskRequest(
        @NotBlank @Size(max = 255) String title,
        String description,
        @NotBlank @Size(max = 50) String originModule,
        UUID assignedToMemberId,
        ZonedDateTime dueDate
) {}