package com.homesweethome.entity;

import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "shopping_items")
@Data
public class ShoppingItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "family_id", nullable = false)
    private String familyId;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private String category;

    @Column(nullable = false)
    private String subCategory;

    private String quantity;

    @Column(length = 500)
    private String varietyNotes;

    @Column(nullable = false)
    private boolean completed = false;

    @Column(nullable = false)
    private boolean archived = false;

    private LocalDate addedDate;

    /**
     * Date on which the item belongs to the shopping list.
     */
    private LocalDate shoppingDate;

    /**
     * Items archived together receive the same batch id.
     * This allows us to restore a previous shopping list.
     */
    private String archiveBatchId;

    private LocalDateTime archivedAt;

    @PrePersist
    public void prePersist() {

        if (addedDate == null) {
            addedDate = LocalDate.now();
        }

        if (shoppingDate == null) {
            shoppingDate = LocalDate.now();
        }
    }
}