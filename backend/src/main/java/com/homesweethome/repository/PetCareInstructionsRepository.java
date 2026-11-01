package com.homesweethome.repository;
import com.homesweethome.entity.PetCareInstructions;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.UUID;
public interface PetCareInstructionsRepository extends JpaRepository<PetCareInstructions, UUID> {}
