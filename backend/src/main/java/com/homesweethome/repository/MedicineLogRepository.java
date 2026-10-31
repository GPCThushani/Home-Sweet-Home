package com.homesweethome.repository;

import com.homesweethome.entity.MedicineLog;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.time.LocalDateTime;

public interface MedicineLogRepository
        extends JpaRepository<MedicineLog, Long> {

    Optional<MedicineLog> findByMedicineIdAndScheduledAt(Long medicineId, LocalDateTime scheduledAt);

    List<MedicineLog> findByFamilyIdAndFamilyMemberIdOrderByScheduledAtDesc(
            String familyId,
            String familyMemberId
    );
}
