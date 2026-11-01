package com.homesweethome.repository;
import com.homesweethome.entity.PetDocument;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.*;
public interface PetDocumentRepository extends JpaRepository<PetDocument, UUID> {
    List<PetDocument> findByPetIdOrderByUploadedAtDesc(UUID petId);
    Optional<PetDocument> findByIdAndPetId(UUID id, UUID petId);
    long countByPetId(UUID petId);
}
