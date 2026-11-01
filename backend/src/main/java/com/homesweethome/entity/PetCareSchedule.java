package com.homesweethome.entity;
import jakarta.persistence.*;
import lombok.Data;
import java.time.*;
import java.util.UUID;

@Entity @Table(name = "pet_care_schedules") @Data
public class PetCareSchedule {
    @Id @GeneratedValue(strategy = GenerationType.UUID) private UUID id;
    @Column(nullable = false) private UUID familyId;
    @Column(nullable = false) private UUID petId;
    @Column(nullable = false, length = 255) private String activityName;
    @Column(length = 2000) private String description;
    @Column(nullable = false, length = 32) private String frequency;
    @Column(length = 32) private String weekdays;
    @Column(nullable = false) private LocalTime scheduledTime;
    @Column(nullable = false) private LocalDate startDate;
    private LocalDate endDate;
    private UUID assignedMemberId;
    private UUID createdByMemberId;
    private boolean active = true;
    private boolean autoTasks;
    private boolean deleted;
}
