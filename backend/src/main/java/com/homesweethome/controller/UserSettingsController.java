package com.homesweethome.controller;

import com.homesweethome.entity.NotificationHistory;
import com.homesweethome.entity.UserSettings;
import com.homesweethome.repository.NotificationHistoryRepository;
import com.homesweethome.repository.UserSettingsRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/settings")
@RequiredArgsConstructor
public class UserSettingsController {

    private final UserSettingsRepository settingsRepository;
    private final NotificationHistoryRepository notificationRepository;

    @GetMapping("/{userEmail}")
    public ResponseEntity<UserSettings> getSettings(@PathVariable String userEmail) {
        UserSettings settings = settingsRepository.findByUserEmail(userEmail)
                .orElseGet(() -> {
                    UserSettings s = new UserSettings();
                    s.setUserEmail(userEmail);
                    return settingsRepository.save(s);
                });
        return ResponseEntity.ok(settings);
    }

    @PutMapping("/{userEmail}")
    public ResponseEntity<UserSettings> updateSettings(
            @PathVariable String userEmail,
            @RequestBody UserSettings newSettings
    ) {
        UserSettings settings = settingsRepository.findByUserEmail(userEmail)
                .orElse(new UserSettings());
        
        settings.setUserEmail(userEmail);
        settings.setPushEnabled(newSettings.isPushEnabled());
        settings.setInAppEnabled(newSettings.isInAppEnabled());
        settings.setTaskNotifications(newSettings.isTaskNotifications());
        settings.setFamilyNotifications(newSettings.isFamilyNotifications());
        settings.setHealthNotifications(newSettings.isHealthNotifications());
        settings.setPetNotifications(newSettings.isPetNotifications());
        settings.setDocNotifications(newSettings.isDocNotifications());
        settings.setHomeNotifications(newSettings.isHomeNotifications());
        settings.setReminderTiming(newSettings.getReminderTiming());
        settings.setDailySummary(newSettings.isDailySummary());
        settings.setQuietHoursStart(newSettings.getQuietHoursStart());
        settings.setQuietHoursEnd(newSettings.getQuietHoursEnd());
        settings.setSoundEnabled(newSettings.isSoundEnabled());
        settings.setFamilyVisibility(newSettings.getFamilyVisibility());
        settings.setHealthVisibility(newSettings.getHealthVisibility());
        settings.setDocumentVisibility(newSettings.getDocumentVisibility());
        settings.setPetVisibility(newSettings.getPetVisibility());
        settings.setThemeMode(newSettings.getThemeMode());
        settings.setAppLanguage(newSettings.getAppLanguage());
        settings.setCountry(newSettings.getCountry());
        settings.setTimeZone(newSettings.getTimeZone());
        settings.setDateFormat(newSettings.getDateFormat());
        settings.setTimeFormat(newSettings.getTimeFormat());
        settings.setFirstDayOfWeek(newSettings.getFirstDayOfWeek());

        return ResponseEntity.ok(settingsRepository.save(settings));
    }

    @GetMapping("/notifications/{userEmail}")
    public ResponseEntity<List<NotificationHistory>> getNotifications(@PathVariable String userEmail) {
        return ResponseEntity.ok(notificationRepository.findByUserEmailOrderByCreatedAtDesc(userEmail));
    }

    @PutMapping("/notifications/read-all/{userEmail}")
    public ResponseEntity<Void> markAllRead(@PathVariable String userEmail) {
        List<NotificationHistory> list = notificationRepository.findByUserEmailOrderByCreatedAtDesc(userEmail);
        list.forEach(n -> n.setRead(true));
        notificationRepository.saveAll(list);
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/notifications/{userEmail}")
    public ResponseEntity<Void> clearNotifications(@PathVariable String userEmail) {
        notificationRepository.deleteByUserEmail(userEmail);
        return ResponseEntity.noContent().build();
    }
}