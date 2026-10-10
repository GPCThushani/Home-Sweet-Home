package com.homesweethome.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.time.*;

@Entity
@Table(name = "garden_routine_completions", uniqueConstraints = @UniqueConstraint(
        name = "uq_garden_completion", columnNames = {"routine_id", "occurrence_date"}))
@Data
public class GardenRoutineCompletion {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "family_id", nullable = false)
    private String familyId;

    @Column(name = "routine_id", nullable = false)
    private Long routineId;

    @Column(name = "occurrence_date", nullable = false)
    private LocalDate occurrenceDate;

    @Column(nullable = false)
    private LocalDateTime completedAt;

    private String completedBy;
}