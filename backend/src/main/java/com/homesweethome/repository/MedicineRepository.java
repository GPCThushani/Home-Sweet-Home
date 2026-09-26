package com.homesweethome.repository;

import com.homesweethome.entity.Medicine;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface MedicineRepository
        extends JpaRepository<Medicine, Long> {

    List<Medicine> findByFamilyIdAndFamilyMemberIdAndActiveTrue(
            String familyId,
            String familyMemberId
    );
}