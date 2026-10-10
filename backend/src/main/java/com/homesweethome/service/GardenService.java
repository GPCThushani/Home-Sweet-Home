package com.homesweethome.service;

import com.homesweethome.dto.*;
import com.homesweethome.entity.*;
import com.homesweethome.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.*;
import java.time.temporal.TemporalAdjusters;
import java.util.*;

@Service
@RequiredArgsConstructor
public class GardenService {
    private final GardenRoutineRepository routines;
    private final GardenRoutineCompletionRepository completions;
    private final GardenSetupRepository setups;
    private final Clock clock = Clock.systemDefaultZone();

    private LocalDate today() { 
        return LocalDate.now(clock); 
    }
    
    private LocalDate weekStart(LocalDate date) { 
        return date.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY)); 
    }

    @Transactional
    public void initializeOnce(String familyId) {
        if (setups.existsById(familyId)) return;
        if (!routines.existsByFamilyId(familyId)) {
            seed(familyId, "Water the garden", "EVERY_N_DAYS", 2, null, null, LocalTime.of(7, 0), false);
            seed(familyId, "Weekly Garden Care", "WEEKLY", null, DayOfWeek.SUNDAY, null, LocalTime.of(8, 0), false);
            seed(familyId, "Fertilize with compost", "MONTHLY", null, null, 1, null, false);
            seed(familyId, "Check soil moisture", "EVERY_N_DAYS", 3, null, null, null, false);
            seed(familyId, "Weed garden beds", "AS_NEEDED", null, null, null, null, true);
            seed(familyId, "Prune dead leaves", "AS_NEEDED", null, null, null, null, true);
            seed(familyId, "Clean pots and racks", "AS_NEEDED", null, null, null, null, true);
            seed(familyId, "Check for pests", "AS_NEEDED", null, null, null, null, true);
        }
        GardenSetup setup = new GardenSetup();
        setup.setFamilyId(familyId);
        setup.setInitialized(true);
        setups.save(setup);
    }

    private void seed(String family, String title, String type, Integer days, DayOfWeek weekday, Integer monthDay, LocalTime time, boolean quick) {
        GardenRoutine r = new GardenRoutine();
        r.setFamilyId(family);
        r.setTitle(title);
        r.setFrequencyType(type);
        r.setIntervalDays(days);
        r.setDayOfWeek(weekday);
        r.setDayOfMonth(monthDay);
        r.setScheduledTime(time);
        r.setQuickAction(quick);
        r.setNextDueDate(quick ? null : initialDue(r, today()));
        routines.save(r);
    }

    private LocalDate initialDue(GardenRoutine r, LocalDate date) {
        return switch(r.getFrequencyType()) {
            case "WEEKLY" -> date.with(TemporalAdjusters.nextOrSame(r.getDayOfWeek() != null ? r.getDayOfWeek() : DayOfWeek.SUNDAY));
            case "MONTHLY" -> {
                int targetDay = r.getDayOfMonth() != null ? r.getDayOfMonth() : 1;
                LocalDate d = date.withDayOfMonth(Math.min(targetDay, date.lengthOfMonth()));
                if (d.isBefore(date)) {
                    LocalDate n = date.plusMonths(1);
                    d = n.withDayOfMonth(Math.min(targetDay, n.lengthOfMonth()));
                }
                yield d;
            }
            default -> date;
        };
    }

    private LocalDate followingDue(GardenRoutine r, LocalDate completedOn) {
        return switch(r.getFrequencyType()) {
            case "EVERY_N_DAYS" -> completedOn.plusDays(r.getIntervalDays() != null ? r.getIntervalDays() : 1);
            case "WEEKLY" -> completedOn.with(TemporalAdjusters.next(r.getDayOfWeek() != null ? r.getDayOfWeek() : DayOfWeek.SUNDAY));
            case "MONTHLY" -> {
                LocalDate next = completedOn.plusDays(1);
                int targetDay = r.getDayOfMonth() != null ? r.getDayOfMonth() : 1;
                LocalDate d = next.withDayOfMonth(Math.min(targetDay, next.lengthOfMonth()));
                if (d.isBefore(next)) {
                    next = next.plusMonths(1);
                    d = next.withDayOfMonth(Math.min(targetDay, next.lengthOfMonth()));
                }
                yield d;
            }
            default -> completedOn.plusDays(1);
        };
    }

    private GardenRoutine require(String family, Long id) {
        return routines.findByIdAndFamilyId(id, family)
                .filter(GardenRoutine::isActive)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Routine not found"));
    }

    private void validate(GardenRoutineRequest req) {
        if (req.getTitle() == null || req.getTitle().isBlank())
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Title required");
        String type = req.getFrequencyType();
        if (type == null || !Set.of("EVERY_N_DAYS", "WEEKLY", "MONTHLY", "AS_NEEDED").contains(type))
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid frequencyType");
    }

    private void apply(GardenRoutine r, GardenRoutineRequest req) {
        validate(req);
        r.setTitle(req.getTitle().trim());
        r.setFrequencyType(req.getFrequencyType());
        r.setIntervalDays(req.getIntervalDays());
        r.setDayOfWeek(req.getDayOfWeek());
        r.setDayOfMonth(req.getDayOfMonth());
        r.setScheduledTime(req.getScheduledTime());
        r.setQuickAction(Boolean.TRUE.equals(req.getIsQuickAction()));
    }

    private GardenRoutineView view(GardenRoutine r) {
        List<GardenRoutineCompletion> history = completions.findByRoutineIdOrderByCompletedAtDesc(r.getId());
        GardenRoutineCompletion latest = history.isEmpty() ? null : history.get(0);
        LocalDate current = today();
        boolean quick = r.isQuickAction();
        LocalDate currentKey = quick ? weekStart(current) : current;
        boolean done = quick && completions.findByRoutineIdAndOccurrenceDate(r.getId(), currentKey).isPresent();
        
        if (!quick && latest != null && r.getNextDueDate() != null && current.isBefore(r.getNextDueDate())) {
            done = true;
        }

        String status = done ? "COMPLETED" : quick ? "AVAILABLE" : (r.getNextDueDate() != null && !r.getNextDueDate().isAfter(current) ? "DUE" : "UPCOMING");
        
        return new GardenRoutineView(
            r.getId(), r.getTitle(), r.getFrequencyType(), r.getIntervalDays(),
            r.getDayOfWeek(), r.getDayOfMonth(), r.getScheduledTime(), quick,
            r.getNextDueDate(), latest == null ? null : latest.getCompletedAt().toLocalDate(),
            latest == null ? null : latest.getCompletedBy(), done, status
        );
    }

    @Transactional
    public List<GardenRoutineView> list(String family, boolean quick) {
        initializeOnce(family);
        return routines.findByFamilyIdAndQuickActionAndActiveTrueOrderByIdAsc(family, quick).stream().map(this::view).toList();
    }

    @Transactional
    public GardenRoutineView add(String family, GardenRoutineRequest req) {
        initializeOnce(family);
        GardenRoutine r = new GardenRoutine();
        r.setFamilyId(family);
        apply(r, req);
        r.setNextDueDate(r.isQuickAction() ? null : initialDue(r, today()));
        return view(routines.save(r));
    }

    @Transactional
    public GardenRoutineView edit(String family, Long id, GardenRoutineRequest req) {
        GardenRoutine r = require(family, id);
        apply(r, req);
        r.setNextDueDate(r.isQuickAction() ? null : initialDue(r, today()));
        return view(routines.save(r));
    }

    @Transactional
    public GardenRoutineView complete(String family, Long id, String user) {
        GardenRoutine r = require(family, id);
        LocalDate date = today();
        LocalDate key = r.isQuickAction() ? weekStart(date) : date;

        if (completions.findByRoutineIdAndOccurrenceDate(id, key).isEmpty()) {
            GardenRoutineCompletion c = new GardenRoutineCompletion();
            c.setFamilyId(family);
            c.setRoutineId(id);
            c.setOccurrenceDate(key);
            c.setCompletedAt(LocalDateTime.now(clock));
            c.setCompletedBy(user);
            completions.save(c);
        }

        if (!r.isQuickAction()) {
            r.setNextDueDate(followingDue(r, date));
        }
        return view(routines.save(r));
    }

    @Transactional
    public GardenRoutineView undo(String family, Long id) {
        GardenRoutine r = require(family, id);
        LocalDate date = today();
        LocalDate key = r.isQuickAction() ? weekStart(date) : date;

        boolean existed = completions.findByRoutineIdAndOccurrenceDate(id, key).map(c -> {
            completions.delete(c);
            return true;
        }).orElse(false);

        if (!r.isQuickAction() && existed) {
            r.setNextDueDate(initialDue(r, date));
        }
        return view(routines.save(r));
    }

    @Transactional
    public void delete(String family, Long id) {
        GardenRoutine r = require(family, id);
        completions.deleteByRoutineId(id);
        routines.delete(r);
    }

    @Transactional(readOnly = true)
    public List<GardenRoutineCompletion> history(String family) {
        return completions.findByFamilyIdOrderByCompletedAtDesc(family);
    }
}