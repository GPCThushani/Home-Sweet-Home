package com.homesweethome.dto;

import java.time.ZonedDateTime;
import java.util.UUID;

public record UpdateTaskRequest(
        String title,
        String description,
        String originModule,
        UUID assignedToMemberId,
        ZonedDateTime dueDate
) {}