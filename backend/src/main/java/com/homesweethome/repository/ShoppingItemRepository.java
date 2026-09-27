package com.homesweethome.repository;

import com.homesweethome.entity.ShoppingItem;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface ShoppingItemRepository extends JpaRepository<ShoppingItem, Long> {

    List<ShoppingItem> findByFamilyIdAndArchivedFalseOrderByAddedDateDesc(
            String familyId
    );

    List<ShoppingItem> findByFamilyIdAndArchivedTrueOrderByArchivedAtDesc(
            String familyId
    );

    List<ShoppingItem> findByFamilyIdAndArchivedFalseAndShoppingDate(
            String familyId,
            LocalDate shoppingDate
    );

    List<ShoppingItem> findByFamilyIdAndArchiveBatchId(
            String familyId,
            String archiveBatchId
    );

    Optional<ShoppingItem> findByIdAndFamilyId(
            Long id,
            String familyId
    );

    Optional<ShoppingItem> findFirstByFamilyIdAndArchivedTrueOrderByArchivedAtDesc(
            String familyId
    );
}