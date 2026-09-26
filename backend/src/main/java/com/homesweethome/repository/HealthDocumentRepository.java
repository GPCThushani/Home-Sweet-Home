package com.homesweethome.repository;

import com.homesweethome.entity.HealthDocument;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface HealthDocumentRepository
        extends JpaRepository<HealthDocument, Long> {

    List<HealthDocument> findByFamilyIdAndFamilyMemberIdOrderByUploadedDateDesc(
            String familyId,
            String familyMemberId
    );
}