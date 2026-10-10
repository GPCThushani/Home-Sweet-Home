package com.homesweethome.entity;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*;
import lombok.Data;
import java.time.*;

@Entity
@Table(name = "garden_routines")
@Data
public class GardenRoutine {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "family_id", nullable = false)
    private String familyId;

    @Column(nullable = false)
    private String title;

    @Column(nullable = false)
    private String frequencyType = "AS_NEEDED";

    private Integer intervalDays;

    @Enumerated(EnumType.STRING)
    private DayOfWeek dayOfWeek;

    private Integer dayOfMonth;
    private LocalTime scheduledTime;
    private LocalDate nextDueDate;

    @Column(name = "is_quick_action", nullable = false)
    @JsonProperty("isQuickAction")
    private boolean quickAction;

    @Column(nullable = false)
    private boolean active = true;
}