package com.homesweethome.repository;

import com.homesweethome.entity.MedicineSchedule;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface MedicineScheduleRepository
        extends JpaRepository<MedicineSchedule, Long> {

    List<MedicineSchedule> findByMedicineIdAndActiveTrue(Long medicineId);
}