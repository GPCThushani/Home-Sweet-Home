package com.homesweethome.dto;

import lombok.*;
import java.time.*;

@Data
@AllArgsConstructor
public class GardenRoutineView {
    private Long id;
    private String title;
    private String frequencyType;
    private Integer intervalDays;
    private DayOfWeek dayOfWeek;
    private Integer dayOfMonth;
    private LocalTime scheduledTime;
    private boolean isQuickAction;
    private LocalDate nextDueDate;
    private LocalDate lastCompletedDate;
    private String completedBy;
    private boolean completedForCurrentOccurrence;
    private String status;
}