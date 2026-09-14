package com.homesweethome.dto;

import java.time.ZonedDateTime;
import java.util.UUID;

public record CreateTaskRequest(
    UUID familyId,
    String title,
    String originModule, // e.g., "CHORES", "HEALTH", "FINANCE"
    UUID creatorMemberId, // ID from the family_members table
    UUID assignedToMemberId, // ID from the family_members table
    ZonedDateTime dueDate
) {}