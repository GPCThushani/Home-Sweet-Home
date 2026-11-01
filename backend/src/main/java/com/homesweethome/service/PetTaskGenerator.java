package com.homesweethome.service;

import com.homesweethome.entity.*;
import com.homesweethome.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import java.time.*;
import java.time.temporal.ChronoUnit;
import java.util.*;

@Service
@RequiredArgsConstructor
public class PetTaskGenerator {
    private final PetCareScheduleRepository schedules;
    private final PetRepository pets;
    private final FamilyRepository families;
    private final FamilyMemberRepository members;
    private final GlobalTaskRepository tasks;
    private final GlobalTaskService taskService;
    private final PlatformTransactionManager transactions;
    @Value("${pets.schedule.enabled:true}") private boolean enabled;

    @Scheduled(initialDelay = 10000, fixedDelay = 6 * 60 * 60 * 1000)
    public void refreshWindow() {
        if (!enabled) return;
        for (PetCareSchedule schedule : schedules.findByAutoTasksTrueAndActiveTrueAndDeletedFalse()) {
            try { generate(schedule.getId()); }
            catch (RuntimeException ex) {
                org.slf4j.LoggerFactory.getLogger(getClass()).warn("Pet schedule generation failed for schedule {}", schedule.getId());
            }
        }
    }

    public void generate(UUID scheduleId) {
        new TransactionTemplate(transactions).executeWithoutResult(unused -> generateLocked(scheduleId));
    }

    private void generateLocked(UUID id) {
        PetCareSchedule schedule = schedules.findForUpdate(id).orElse(null);
        if (schedule == null || schedule.isDeleted() || !schedule.isActive() || !schedule.isAutoTasks()) return;
        Pet pet = pets.findById(schedule.getPetId()).orElse(null);
        Family family = families.findById(schedule.getFamilyId()).orElse(null);
        if (pet == null || family == null || !pet.getFamilyId().equals(family.getId())) return;
        ZoneId zone = ZoneId.of(family.getTimezone());
        ZonedDateTime now = ZonedDateTime.now(zone);
        LocalDate start = now.toLocalDate().isAfter(schedule.getStartDate()) ? now.toLocalDate() : schedule.getStartDate();
        LocalDate limit = now.toLocalDate().plusDays(13);
        if (schedule.getEndDate() != null && schedule.getEndDate().isBefore(limit)) limit = schedule.getEndDate();
        if (start.isAfter(limit)) return;
        List<GlobalTask> existing = tasks.findBySourceCareScheduleId(id);
        FamilyMember creator = members.findById(schedule.getCreatedByMemberId()).orElse(null);
        if (creator == null || !creator.getFamily().getId().equals(family.getId())) return;
        FamilyMember assignee = schedule.getAssignedMemberId() == null ? null : members.findById(schedule.getAssignedMemberId()).orElse(null);
        for (LocalDate day = start; !day.isAfter(limit); day = day.plusDays(1)) {
            if (!occurs(schedule, day)) continue;
            ZonedDateTime due = day.atTime(schedule.getScheduledTime()).atZone(zone).truncatedTo(ChronoUnit.MICROS);
            if (!due.isAfter(now)) continue;
            boolean present = existing.stream().anyMatch(task -> task.getDueDate() != null
                    && task.getDueDate().toInstant().equals(due.toInstant()));
            if (present) continue;
            GlobalTask task = taskService.createTask(family, schedule.getActivityName() + " — " + pet.getName(),
                    schedule.getDescription(), "PETS", creator, assignee, due);
            task.setSourcePetId(pet.getId());
            task.setSourceCareScheduleId(id);
            tasks.save(task);
            existing.add(task);
        }
    }

    private boolean occurs(PetCareSchedule schedule, LocalDate day) {
        return switch (schedule.getFrequency()) {
            case "DAILY" -> true;
            case "SELECTED_WEEKDAYS" -> Arrays.asList(schedule.getWeekdays().split(","))
                    .contains(Integer.toString(day.getDayOfWeek().getValue()));
            case "WEEKLY" -> day.getDayOfWeek().equals(schedule.getStartDate().getDayOfWeek());
            case "MONTHLY" -> day.getDayOfMonth() == schedule.getStartDate().getDayOfMonth();
            case "ONE_TIME" -> day.equals(schedule.getStartDate());
            default -> false;
        };
    }
}
