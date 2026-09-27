package com.homesweethome.controller;

import com.homesweethome.entity.ShoppingItem;
import com.homesweethome.entity.ShoppingSection;
import com.homesweethome.repository.ShoppingItemRepository;
import com.homesweethome.repository.ShoppingSectionRepository;
import lombok.RequiredArgsConstructor;

import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;

@RestController
@RequestMapping("/api/shopping")
@RequiredArgsConstructor
public class ShoppingController {

    private final ShoppingItemRepository shoppingItemRepository;
    private final ShoppingSectionRepository shoppingSectionRepository;


    // ============================================================
    // CUSTOM SECTIONS
    // ============================================================

    @GetMapping("/sections/{familyId}")
    public ResponseEntity<List<ShoppingSection>> getCustomSections(
            @PathVariable String familyId
    ) {
        return ResponseEntity.ok(
                shoppingSectionRepository
                        .findByFamilyIdOrderByCreatedAtAsc(familyId)
        );
    }


    @PostMapping("/sections/{familyId}")
    public ResponseEntity<ShoppingSection> createSection(
            @PathVariable String familyId,
            @RequestBody ShoppingSection incoming
    ) {

        if (incoming.getTitle() == null ||
                incoming.getTitle().trim().isEmpty()) {

            return ResponseEntity.badRequest().build();
        }

        ShoppingSection section = new ShoppingSection();

        section.setFamilyId(familyId);

        String cleanTitle = incoming.getTitle().trim();

        section.setTitle(cleanTitle);

        section.setDescription(
                incoming.getDescription() == null ||
                        incoming.getDescription().trim().isEmpty()
                        ? "Custom family shopping items"
                        : incoming.getDescription().trim()
        );

        section.setCustomSection(true);

        String generatedKey =
                "CUSTOM_" +
                UUID.randomUUID()
                        .toString()
                        .replace("-", "")
                        .substring(0, 12)
                        .toUpperCase();

        section.setSectionKey(generatedKey);

        section.setCategories(
                incoming.getCategories() == null
                        ? new ArrayList<>()
                        : new ArrayList<>(incoming.getCategories())
        );

        return ResponseEntity.ok(
                shoppingSectionRepository.save(section)
        );
    }


    @PutMapping("/sections/{familyId}/{sectionId}")
    public ResponseEntity<ShoppingSection> updateSection(
            @PathVariable String familyId,
            @PathVariable Long sectionId,
            @RequestBody ShoppingSection incoming
    ) {

        return shoppingSectionRepository
                .findByIdAndFamilyId(sectionId, familyId)
                .map(section -> {

                    if (incoming.getTitle() != null &&
                            !incoming.getTitle().trim().isEmpty()) {

                        section.setTitle(
                                incoming.getTitle().trim()
                        );
                    }

                    if (incoming.getDescription() != null) {

                        section.setDescription(
                                incoming.getDescription().trim()
                        );
                    }

                    return ResponseEntity.ok(
                            shoppingSectionRepository.save(section)
                    );
                })
                .orElse(ResponseEntity.notFound().build());
    }


    @Transactional
    @DeleteMapping("/sections/{familyId}/{sectionId}")
    public ResponseEntity<Void> deleteSection(
            @PathVariable String familyId,
            @PathVariable Long sectionId
    ) {

        Optional<ShoppingSection> sectionOptional =
                shoppingSectionRepository.findByIdAndFamilyId(
                        sectionId,
                        familyId
                );

        if (sectionOptional.isEmpty()) {
            return ResponseEntity.notFound().build();
        }

        ShoppingSection section = sectionOptional.get();

        /*
         * Delete all active and archived shopping items
         * belonging to this custom section.
         */
        List<ShoppingItem> items =
                shoppingItemRepository.findByFamilyIdAndArchivedFalseOrderByAddedDateDesc(
                        familyId
                );

        items.removeIf(
                item -> !section.getSectionKey().equals(item.getCategory())
        );

        if (!items.isEmpty()) {
            shoppingItemRepository.deleteAll(items);
        }

        shoppingSectionRepository.delete(section);

        return ResponseEntity.noContent().build();
    }


    // ============================================================
    // CUSTOM CATEGORIES
    // ============================================================

    @PostMapping("/sections/{familyId}/{sectionId}/categories")
    public ResponseEntity<ShoppingSection> addCategory(
            @PathVariable String familyId,
            @PathVariable Long sectionId,
            @RequestBody Map<String, String> body
    ) {

        String category =
                body.get("category");

        if (category == null ||
                category.trim().isEmpty()) {

            return ResponseEntity.badRequest().build();
        }

        return shoppingSectionRepository
                .findByIdAndFamilyId(sectionId, familyId)
                .map(section -> {

                    if (section.getCategories() == null) {
                        section.setCategories(
                                new ArrayList<>()
                        );
                    }

                    String cleanCategory =
                            category.trim();

                    boolean exists =
                            section.getCategories()
                                    .stream()
                                    .anyMatch(
                                            c -> c.equalsIgnoreCase(
                                                    cleanCategory
                                            )
                                    );

                    if (!exists) {
                        section.getCategories()
                                .add(cleanCategory);
                    }

                    return ResponseEntity.ok(
                            shoppingSectionRepository.save(section)
                    );
                })
                .orElse(ResponseEntity.notFound().build());
    }


    @DeleteMapping(
            "/sections/{familyId}/{sectionId}/categories"
    )
    public ResponseEntity<ShoppingSection> deleteCategory(
            @PathVariable String familyId,
            @PathVariable Long sectionId,
            @RequestParam String category
    ) {

        return shoppingSectionRepository
                .findByIdAndFamilyId(sectionId, familyId)
                .map(section -> {

                    if (section.getCategories() != null) {

                        section.getCategories()
                                .removeIf(
                                        c -> c.equalsIgnoreCase(
                                                category
                                        )
                                );
                    }

                    return ResponseEntity.ok(
                            shoppingSectionRepository.save(section)
                    );
                })
                .orElse(ResponseEntity.notFound().build());
    }


    // ============================================================
    // SHOPPING ITEMS
    // ============================================================

    @GetMapping("/{familyId}")
    public ResponseEntity<List<ShoppingItem>> getActiveItems(
            @PathVariable String familyId
    ) {

        return ResponseEntity.ok(
                shoppingItemRepository
                        .findByFamilyIdAndArchivedFalseOrderByAddedDateDesc(
                                familyId
                        )
        );
    }


    @GetMapping("/{familyId}/date/{date}")
    public ResponseEntity<List<ShoppingItem>> getItemsByDate(
            @PathVariable String familyId,
            @PathVariable LocalDate date
    ) {

        return ResponseEntity.ok(
                shoppingItemRepository
                        .findByFamilyIdAndArchivedFalseAndShoppingDate(
                                familyId,
                                date
                        )
        );
    }


    @PostMapping("/{familyId}")
    public ResponseEntity<ShoppingItem> addItem(
            @PathVariable String familyId,
            @RequestBody ShoppingItem incoming
    ) {

        if (incoming.getName() == null ||
                incoming.getName().trim().isEmpty()) {

            return ResponseEntity.badRequest().build();
        }

        ShoppingItem item = new ShoppingItem();

        item.setFamilyId(familyId);

        item.setName(
                incoming.getName().trim()
        );

        item.setCategory(
                incoming.getCategory()
        );

        item.setSubCategory(
                incoming.getSubCategory()
        );

        item.setQuantity(
                incoming.getQuantity()
        );

        item.setVarietyNotes(
                incoming.getVarietyNotes()
        );

        item.setCompleted(false);

        item.setArchived(false);

        item.setShoppingDate(
                incoming.getShoppingDate() == null
                        ? LocalDate.now()
                        : incoming.getShoppingDate()
        );

        return ResponseEntity.ok(
                shoppingItemRepository.save(item)
        );
    }


    @PutMapping("/{familyId}/item/{id}")
    public ResponseEntity<ShoppingItem> updateItem(
            @PathVariable String familyId,
            @PathVariable Long id,
            @RequestBody ShoppingItem incoming
    ) {

        return shoppingItemRepository
                .findByIdAndFamilyId(id, familyId)
                .map(item -> {

                    item.setName(
                            incoming.getName()
                    );

                    item.setCategory(
                            incoming.getCategory()
                    );

                    item.setSubCategory(
                            incoming.getSubCategory()
                    );

                    item.setQuantity(
                            incoming.getQuantity()
                    );

                    item.setVarietyNotes(
                            incoming.getVarietyNotes()
                    );

                    item.setCompleted(
                            incoming.isCompleted()
                    );

                    if (incoming.getShoppingDate() != null) {
                        item.setShoppingDate(
                                incoming.getShoppingDate()
                        );
                    }

                    return ResponseEntity.ok(
                            shoppingItemRepository.save(item)
                    );
                })
                .orElse(ResponseEntity.notFound().build());
    }


    @DeleteMapping("/{familyId}/item/{id}")
    public ResponseEntity<Void> deleteItem(
            @PathVariable String familyId,
            @PathVariable Long id
    ) {

        return shoppingItemRepository
                .findByIdAndFamilyId(id, familyId)
                .map(item -> {

                    shoppingItemRepository.delete(item);

                    return ResponseEntity.noContent()
                            .<Void>build();

                })
                .orElse(
                        ResponseEntity.notFound().build()
                );
    }


    // ============================================================
    // ARCHIVE / NEW LIST
    // ============================================================

    @PostMapping("/archive/{familyId}")
    @Transactional
    public ResponseEntity<Map<String, Object>> archiveCompleted(
            @PathVariable String familyId
    ) {

        List<ShoppingItem> items =
                shoppingItemRepository
                        .findByFamilyIdAndArchivedFalseOrderByAddedDateDesc(
                                familyId
                        );

        String batchId =
                UUID.randomUUID().toString();

        LocalDateTime archivedAt =
                LocalDateTime.now();

        int archivedCount = 0;

        for (ShoppingItem item : items) {

            if (item.isCompleted()) {

                item.setArchived(true);

                item.setArchiveBatchId(
                        batchId
                );

                item.setArchivedAt(
                        archivedAt
                );

                archivedCount++;
            }
        }

        shoppingItemRepository.saveAll(items);

        Map<String, Object> response =
                new HashMap<>();

        response.put(
                "message",
                "Completed shopping items archived."
        );

        response.put(
                "archivedCount",
                archivedCount
        );

        response.put(
                "batchId",
                batchId
        );

        return ResponseEntity.ok(response);
    }


    // ============================================================
    // HISTORY
    // ============================================================

    @GetMapping("/history/{familyId}")
    public ResponseEntity<List<ShoppingItem>> getHistory(
            @PathVariable String familyId
    ) {

        return ResponseEntity.ok(
                shoppingItemRepository
                        .findByFamilyIdAndArchivedTrueOrderByArchivedAtDesc(
                                familyId
                        )
        );
    }


    // ============================================================
    // RESTORE LAST LIST
    // ============================================================

    @PostMapping("/restore-last/{familyId}")
    @Transactional
    public ResponseEntity<List<ShoppingItem>> restoreLastList(
            @PathVariable String familyId
    ) {

        Optional<ShoppingItem> latest =
                shoppingItemRepository
                        .findFirstByFamilyIdAndArchivedTrueOrderByArchivedAtDesc(
                                familyId
                        );

        if (latest.isEmpty()) {
            return ResponseEntity.ok(
                    new ArrayList<>()
            );
        }

        String batchId =
                latest.get().getArchiveBatchId();

        if (batchId == null) {
            return ResponseEntity.ok(
                    new ArrayList<>()
            );
        }

        List<ShoppingItem> previousItems =
                shoppingItemRepository
                        .findByFamilyIdAndArchiveBatchId(
                                familyId,
                                batchId
                        );

        List<ShoppingItem> restored =
                new ArrayList<>();

        for (ShoppingItem oldItem : previousItems) {

            ShoppingItem newItem =
                    new ShoppingItem();

            newItem.setFamilyId(
                    familyId
            );

            newItem.setName(
                    oldItem.getName()
            );

            newItem.setCategory(
                    oldItem.getCategory()
            );

            newItem.setSubCategory(
                    oldItem.getSubCategory()
            );

            newItem.setQuantity(
                    oldItem.getQuantity()
            );

            newItem.setVarietyNotes(
                    oldItem.getVarietyNotes()
            );

            newItem.setCompleted(false);

            newItem.setArchived(false);

            newItem.setShoppingDate(
                    LocalDate.now()
            );

            restored.add(newItem);
        }

        return ResponseEntity.ok(
                shoppingItemRepository.saveAll(restored)
        );
    }
}