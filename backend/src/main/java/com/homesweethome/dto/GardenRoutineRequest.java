package com.homesweethome.dto;

import lombok.Data;
import java.time.*;

@Data
public class GardenRoutineRequest {
    private String title;
    private String frequencyType;
    private Integer intervalDays;
    private DayOfWeek dayOfWeek;
    private Integer dayOfMonth;
    private LocalTime scheduledTime;
    private Boolean isQuickAction;
}