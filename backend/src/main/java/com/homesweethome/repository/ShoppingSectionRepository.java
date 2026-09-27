package com.homesweethome.repository;

import com.homesweethome.entity.ShoppingSection;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface ShoppingSectionRepository extends JpaRepository<ShoppingSection, Long> {

    List<ShoppingSection> findByFamilyIdOrderByCreatedAtAsc(String familyId);

    Optional<ShoppingSection> findByIdAndFamilyId(Long id, String familyId);

    Optional<ShoppingSection> findByFamilyIdAndSectionKey(
            String familyId,
            String sectionKey
    );
}