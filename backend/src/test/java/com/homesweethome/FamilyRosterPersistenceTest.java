package com.homesweethome;

import com.homesweethome.dto.FamilyProfileInput;
import com.homesweethome.entity.*;
import com.homesweethome.repository.*;
import com.homesweethome.service.*;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.web.server.ResponseStatusException;

import java.security.SecureRandom;
import java.util.*;
import java.util.concurrent.*;

import static org.junit.jupiter.api.Assertions.*;

// Only this named, in-memory H2 database is created. No PostgreSQL tables/data
// are created, migrated, updated, or deleted by these persistence tests.
@SpringBootTest(properties = {
        "spring.datasource.url=jdbc:h2:mem:family-step2;MODE=PostgreSQL;DB_CLOSE_DELAY=-1;LOCK_TIMEOUT=10000",
        "spring.datasource.driver-class-name=org.h2.Driver", "spring.datasource.username=sa",
        "spring.datasource.password=", "spring.jpa.database-platform=org.hibernate.dialect.H2Dialect",
    "spring.jpa.hibernate.ddl-auto=create", "spring.sql.init.mode=never", "spring.jpa.show-sql=false", "logging.level.root=WARN"
})
class FamilyRosterPersistenceTest {
    @Autowired FamilyService families;
    @Autowired FamilyRosterService roster;
    @Autowired FamilyRepository familyRepository;
    @Autowired FamilyProfileRepository profiles;
    @Autowired FamilyMemberRepository members;
    @Autowired UserRepository users;

    @DynamicPropertySource
    static void secret(DynamicPropertyRegistry registry) {
        byte[] bytes = new byte[32]; new SecureRandom().nextBytes(bytes);
        registry.add("security.jwt.secret", () -> Base64.getEncoder().encodeToString(bytes));
    }

    private User user() {
        return users.save(User.builder().email(UUID.randomUUID() + "@example.test")
                .passwordHash("unused-test-hash").build());
    }

    private record Household(Family family, User creator, List<FamilyProfile> profiles) {}

    private Household household() {
        User creator = user();
        Family family = families.createFamilyWithProfiles("Test household", "Asia/Colombo", creator,
                "Creator", null, List.of(new FamilyProfileInput("Alex", "Father", "Male", false),
                        new FamilyProfileInput("Sam", "Mother", "Female", true),
                        new FamilyProfileInput("Robin", "Son", "Male", false)), 0);
        return new Household(family, creator, profiles.findByFamilyId(family.getId()));
    }

    private FamilyProfile unlinked(Household household, String name) {
        return household.profiles().stream().filter(profile -> profile.getName().equals(name)).findFirst().orElseThrow();
    }

    @Test
    void creationPersistsAllPeopleWithStableUuidsAndOnlyCreatorLinked() {
        Household h = household();
        List<Map<String, Object>> response = roster.getProfiles(h.family().getId(), h.creator().getEmail());
        assertEquals(3, response.size());
        assertEquals(3, response.stream().map(item -> item.get("id")).distinct().count());
        assertEquals(1, response.stream().filter(item -> Boolean.TRUE.equals(item.get("hasAccount"))).count());
        assertEquals(1, response.stream().filter(item -> Boolean.TRUE.equals(item.get("isSelf"))).count());
        for (Map<String, Object> item : response) {
            assertEquals(item.get("id"), item.get("profileId"));
            assertNotNull(UUID.fromString((String) item.get("id")));
            assertFalse(item.containsKey("linkedUserEmail"));
            assertEquals(item.get("role"), item.get("relationship"));
        }
        assertEquals(3, familyRepository.findById(h.family().getId()).orElseThrow().getMemberCount());
    }

    @Test
    void joiningLinksExistingProfileAndRetryReusesSameMembershipAndPerson() {
        Household h = household(); User joining = user();
        UUID profileId = unlinked(h, "Sam").getId();
        FamilyMember first = families.joinFamily(h.family().getId(), joining, "Sam", "PARENT", profileId);
        FamilyMember retry = families.joinFamily(h.family().getId(), joining, "Other nickname", "PARENT", profileId);
        FamilyMember withoutSelection = families.joinFamily(h.family().getId(), joining, null, "MEMBER", null);
        assertEquals(first.getId(), retry.getId()); assertEquals(first.getId(), withoutSelection.getId());
        assertEquals("MEMBER", first.getRole());
        assertEquals(joining.getEmail(), profiles.findById(profileId).orElseThrow().getLinkedUserEmail());
        assertEquals(3, profiles.findByFamilyId(h.family().getId()).size());
        assertEquals(2, members.findByFamilyId(h.family().getId()).size());
        assertEquals(3, familyRepository.findById(h.family().getId()).orElseThrow().getMemberCount());
        List<Map<String, Object>> all = roster.getProfiles(h.family().getId(), joining.getEmail());
        assertEquals(2, all.stream().filter(item -> Boolean.TRUE.equals(item.get("hasAccount"))).count());
    }

    @Test
    void existingUnlinkedMembershipIsPreservedWhenProfileIsSelected() {
        Household h = household(); User joining = user();
        FamilyMember original = members.save(FamilyMember.builder().family(h.family()).user(joining)
                .nickname("Existing nickname").role("MEMBER").build());
        FamilyMember linked = families.joinFamily(h.family().getId(), joining, "New", "MEMBER", unlinked(h, "Sam").getId());
        assertEquals(original.getId(), linked.getId());
        assertEquals("Existing nickname", linked.getNickname());
        assertEquals(2, members.findByFamilyId(h.family().getId()).size());
    }

    @Test
    void missingOrForeignProfileCannotLeaveAnUnlinkedMembershipBehind() {
        Household h = household(); Household other = household(); User joining = user();
        assertEquals(400, assertThrows(ResponseStatusException.class,
                () -> families.joinFamily(h.family().getId(), joining, null, "MEMBER", null)).getStatusCode().value());
        assertEquals(400, assertThrows(ResponseStatusException.class,
                () -> families.joinFamily(h.family().getId(), joining, null, "MEMBER", unlinked(other, "Sam").getId()))
                .getStatusCode().value());
        assertEquals(404, assertThrows(ResponseStatusException.class,
                () -> families.joinFamily(h.family().getId(), joining, null, "MEMBER", UUID.randomUUID()))
                .getStatusCode().value());
        assertTrue(members.findByUserIdAndFamilyId(joining.getId(), h.family().getId()).isEmpty());
        assertEquals(3, profiles.findByFamilyId(h.family().getId()).size());
    }

    @Test
    void profileLinkingRequiresMembershipAndCannotChangeAnExistingLink() {
        Household h = household(); User outsider = user();
        assertThrows(AccessDeniedException.class,
                () -> roster.linkProfileToUser(h.family().getId(), unlinked(h, "Sam").getId(), outsider));
        assertEquals(409, assertThrows(ResponseStatusException.class,
                () -> families.joinFamily(h.family().getId(), outsider, null, "MEMBER", unlinked(h, "Alex").getId()))
                .getStatusCode().value());
        assertEquals(h.creator().getEmail(), profiles.findById(unlinked(h, "Alex").getId()).orElseThrow().getLinkedUserEmail());
        assertTrue(members.findByUserIdAndFamilyId(outsider.getId(), h.family().getId()).isEmpty());
    }

    @Test
    void rosterReadsRequireMembershipAndInvitationChoicesDoNotExposeOtherAccounts() {
        Household h = household(); User outsider = user();
        assertThrows(AccessDeniedException.class, () -> roster.getProfiles(h.family().getId(), outsider.getEmail()));
        List<Map<String, Object>> available = roster.getInvitationProfiles(h.family().getId(), outsider.getEmail());
        assertEquals(2, available.size());
        assertTrue(available.stream().noneMatch(item -> Boolean.TRUE.equals(item.get("hasAccount"))));
        List<Map<String, Object>> own = roster.getInvitationProfiles(h.family().getId(), h.creator().getEmail());
        assertEquals(1, own.size()); assertEquals(true, own.get(0).get("isSelf"));
    }

    @Test
    void duplicateInitialInputsRollBackTheWholeNewFamily() {
        User creator = user();
        long familyCount = familyRepository.count(), profileCount = profiles.count(), memberCount = members.count();
        assertThrows(ResponseStatusException.class, () -> families.createFamilyWithProfiles("Duplicate test",
                null, creator, null, null, List.of(new FamilyProfileInput("Sam", "Son", "Male", false),
                        new FamilyProfileInput(" sam ", "son", "male", false)), 0));
        assertEquals(familyCount, familyRepository.count());
        assertEquals(profileCount, profiles.count()); assertEquals(memberCount, members.count());
        assertTrue(users.findById(creator.getId()).isPresent());
    }

    private List<Integer> race(Household h, User first, UUID firstProfile, User second, UUID secondProfile) throws Exception {
        ExecutorService pool = Executors.newFixedThreadPool(2);
        CountDownLatch start = new CountDownLatch(1);
        try {
            List<Future<Integer>> results = new ArrayList<>();
            for (var claim : List.of(Map.entry(first, firstProfile), Map.entry(second, secondProfile))) {
                results.add(pool.submit(() -> {
                    start.await();
                    try {
                        families.joinFamily(h.family().getId(), claim.getKey(), null, "MEMBER", claim.getValue());
                        return 200;
                    } catch (ResponseStatusException conflict) { return conflict.getStatusCode().value(); }
                }));
            }
            start.countDown();
            return List.of(results.get(0).get(20, TimeUnit.SECONDS), results.get(1).get(20, TimeUnit.SECONDS));
        } finally { pool.shutdownNow(); }
    }

    @Test
    void twoAccountsCannotClaimTheSameProfileConcurrently() throws Exception {
        Household h = household(); User first = user(), second = user(); UUID profileId = unlinked(h, "Sam").getId();
        List<Integer> results = race(h, first, profileId, second, profileId);
        assertEquals(1, Collections.frequency(results, 200)); assertEquals(1, Collections.frequency(results, 409));
        assertEquals(2, members.findByFamilyId(h.family().getId()).size());
        assertEquals(3, profiles.findByFamilyId(h.family().getId()).size());
        assertNotNull(profiles.findById(profileId).orElseThrow().getLinkedUserEmail());
    }

    @Test
    void oneAccountCannotClaimTwoProfilesConcurrently() throws Exception {
        Household h = household(); User joining = user();
        List<Integer> results = race(h, joining, unlinked(h, "Sam").getId(), joining, unlinked(h, "Robin").getId());
        assertEquals(1, Collections.frequency(results, 200)); assertEquals(1, Collections.frequency(results, 409));
        assertEquals(2, members.findByFamilyId(h.family().getId()).size());
        assertEquals(1, profiles.findByFamilyId(h.family().getId()).stream()
                .filter(profile -> joining.getEmail().equals(profile.getLinkedUserEmail())).count());
    }
}
