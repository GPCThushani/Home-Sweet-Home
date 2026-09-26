package com.homesweethome.repository;

import com.homesweethome.entity.HealthAppointment;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface HealthAppointmentRepository
        extends JpaRepository<HealthAppointment, Long> {

    List<HealthAppointment> findByFamilyIdAndFamilyMemberIdOrderByAppointmentDateTimeAsc(
            String familyId,
            String familyMemberId
    );
}