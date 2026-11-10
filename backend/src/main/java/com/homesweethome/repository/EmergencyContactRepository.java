package com.homesweethome.repository;

import com.homesweethome.entity.EmergencyContact;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

public interface EmergencyContactRepository extends JpaRepository<EmergencyContact, UUID> {
    List<EmergencyContact> findByFamilyId(UUID familyId);
}