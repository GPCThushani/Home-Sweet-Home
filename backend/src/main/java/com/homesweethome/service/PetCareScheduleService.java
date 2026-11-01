package com.homesweethome.service;

import com.homesweethome.dto.PetCareScheduleRequest;
import com.homesweethome.entity.*;
import com.homesweethome.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import java.time.ZonedDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service @RequiredArgsConstructor
public class PetCareScheduleService {
    private final PetCareScheduleRepository schedules;
    private final PetAccessService petAccess;
    private final FamilyAccessService access;
    private final FamilyMemberRepository members;
    private final GlobalTaskRepository tasks;
    private final PetTaskGenerator generator;

    public List<PetCareSchedule> list(UUID petId) {
        petAccess.require(petId);
        return schedules.findByPetIdAndDeletedFalseOrderByStartDateDesc(petId);
    }
    public PetCareSchedule get(UUID petId, UUID id) {
        petAccess.require(petId);
        return schedules.findById(id).filter(s -> s.getPetId().equals(petId) && !s.isDeleted())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Care schedule not found"));
    }
    @Transactional
    public PetCareSchedule save(UUID petId, UUID id, PetCareScheduleRequest input) {
        Pet pet = petAccess.require(petId);
        PetCareSchedule schedule = id == null ? new PetCareSchedule() : get(petId, id);
        if (id == null) {
            schedule.setPetId(petId); schedule.setFamilyId(pet.getFamilyId());
            schedule.setCreatedByMemberId(access.currentMember(pet.getFamilyId()).getId());
        }
        if (input.activityName() == null || input.activityName().isBlank() || input.activityName().length() > 255
                || input.scheduledTime() == null || input.startDate() == null)
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Activity, time and start date are required");
        if (input.frequency() == null || !Set.of("DAILY", "SELECTED_WEEKDAYS", "WEEKLY", "MONTHLY", "ONE_TIME").contains(input.frequency()))
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Choose a valid frequency");
        if (input.endDate() != null && input.endDate().isBefore(input.startDate()))
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "End date precedes start date");
        if (input.description() != null && input.description().length() > 2000)
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Instructions are too long");
        String days = input.weekdays() == null ? "" : input.weekdays().stream().sorted()
                .map(String::valueOf).collect(Collectors.joining(","));
        if ("SELECTED_WEEKDAYS".equals(input.frequency())
                && (input.weekdays() == null || input.weekdays().isEmpty() || input.weekdays().stream().anyMatch(day -> day < 1 || day > 7)))
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Select weekdays from Monday through Sunday");
        if (input.assignedMemberId() != null && members.findById(input.assignedMemberId())
                .filter(m -> m.getFamily().getId().equals(pet.getFamilyId())).isEmpty())
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Assignee is not in this family");
        schedule.setActivityName(input.activityName().trim());
        schedule.setDescription(input.description() == null ? null : input.description().trim());
        schedule.setFrequency(input.frequency()); schedule.setWeekdays(days);
        schedule.setScheduledTime(input.scheduledTime()); schedule.setStartDate(input.startDate());
        schedule.setEndDate(input.endDate()); schedule.setAssignedMemberId(input.assignedMemberId());
        schedule.setActive(input.active()); schedule.setAutoTasks(input.autoTasks());
        schedule = schedules.saveAndFlush(schedule);
        removeFuturePending(schedule.getId());
        if (schedule.isActive() && schedule.isAutoTasks()) generator.generate(schedule.getId());
        return schedule;
    }
    @Transactional
    public void delete(UUID petId, UUID id) {
        PetCareSchedule schedule = get(petId, id);
        schedule.setDeleted(true); schedule.setActive(false);
        schedules.save(schedule);
        removeFuturePending(id);
    }
    private void removeFuturePending(UUID id) {
        ZonedDateTime now = ZonedDateTime.now();
        tasks.findBySourceCareScheduleId(id).stream()
                .filter(t -> !"COMPLETED".equals(t.getStatus()) && t.getDueDate() != null && t.getDueDate().isAfter(now))
                .forEach(tasks::delete);
    }
}
