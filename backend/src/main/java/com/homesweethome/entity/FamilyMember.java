package com.homesweethome.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.time.ZonedDateTime;
import java.util.UUID;

@Entity
@Table(name = "family_members", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"user_id", "family_id"})
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FamilyMember {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    // This creates the relationship mapping back to the User
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    // This creates the relationship mapping back to the Family
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "family_id", nullable = false)
    private Family family;

    @Column(nullable = false, length = 50)
    private String role; // e.g., 'PARENT', 'GRANDPARENT', 'CHILD'

    @Column(length = 100)
    private String nickname; // e.g., 'Amma', 'Thaththa'

    @CreationTimestamp
    @Column(updatable = false)
    private ZonedDateTime joinedAt;
}