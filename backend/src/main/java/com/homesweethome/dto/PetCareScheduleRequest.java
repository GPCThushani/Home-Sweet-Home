package com.homesweethome.dto;
import java.time.*;
import java.util.*;
public record PetCareScheduleRequest(String activityName, String description, String frequency,
        Set<Integer> weekdays, LocalTime scheduledTime, LocalDate startDate, LocalDate endDate,
        UUID assignedMemberId, boolean active, boolean autoTasks) {}
