package com.homesweethome.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.util.UUID;

@Entity
@Table(name = "user_app_settings")
@Data
public class UserSettings {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false, unique = true)
    private String userEmail;

    private UUID familyId;

    private boolean pushEnabled = true;
    private boolean inAppEnabled = true;
    private boolean taskNotifications = true;
    private boolean familyNotifications = true;
    private boolean healthNotifications = true;
    private boolean petNotifications = true;
    private boolean docNotifications = true;
    private boolean homeNotifications = true;
    
    private String reminderTiming = "15 minutes before";
    private boolean dailySummary = false;
    private String quietHoursStart = "22:00";
    private String quietHoursEnd = "07:00";
    private boolean soundEnabled = true;

    private String familyVisibility = "Family Only";
    private String healthVisibility = "Private";
    private String documentVisibility = "Family Only";
    private String petVisibility = "Family Only";

    private String themeMode = "Light";
    private String appLanguage = "English";
    private String country = "Sri Lanka";
    private String timeZone = "Asia/Colombo";
    private String dateFormat = "YYYY-MM-DD";
    private String timeFormat = "12-hour";
    private String firstDayOfWeek = "Monday";
}