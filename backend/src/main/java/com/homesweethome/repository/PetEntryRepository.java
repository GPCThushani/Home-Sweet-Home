package com.homesweethome.repository;
import com.homesweethome.entity.PetEntry;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.*;
public interface PetEntryRepository extends JpaRepository<PetEntry, UUID> {
    List<PetEntry> findByPetIdAndKindOrderByRecordDateDesc(UUID petId, String kind);
    Optional<PetEntry> findByIdAndPetIdAndKind(UUID id, UUID petId, String kind);
    long countByPetId(UUID petId);
    List<PetEntry> findByPetId(UUID petId);
}
