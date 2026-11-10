package com.homesweethome.repository;

import com.homesweethome.entity.NotificationHistory;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

public interface NotificationHistoryRepository extends JpaRepository<NotificationHistory, UUID> {
    List<NotificationHistory> findByUserEmailOrderByCreatedAtDesc(String userEmail);
    void deleteByUserEmail(String userEmail);
}