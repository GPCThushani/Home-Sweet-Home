package com.homesweethome;

import com.fasterxml.jackson.databind.*;
import com.homesweethome.dto.FamilyProfileInput;
import com.homesweethome.entity.*;
import com.homesweethome.repository.*;
import com.homesweethome.service.*;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.*;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(properties = {
    "spring.datasource.url=jdbc:h2:mem:tasks-step4;MODE=PostgreSQL;DB_CLOSE_DELAY=-1",
    "spring.datasource.driver-class-name=org.h2.Driver", "spring.datasource.username=sa",
    "spring.datasource.password=", "spring.jpa.database-platform=org.hibernate.dialect.H2Dialect",
    "spring.jpa.hibernate.ddl-auto=create", "spring.sql.init.mode=never", "spring.jpa.show-sql=false", "logging.level.root=WARN"
})
class TaskIntegrationTest {
    @Autowired org.springframework.web.context.WebApplicationContext context;
    @Autowired FamilyService families;
    @Autowired FamilyProfileRepository profiles;
    @Autowired FamilyMemberRepository members;
    @Autowired UserRepository users;
    @Autowired GlobalTaskRepository tasks;
    @Autowired JwtService jwt;
    MockMvc mvc;
    ObjectMapper json = new ObjectMapper();
    Family family;
    FamilyMember creator, assignee, foreign;
    UUID householdProfile;
    String bearer, outsider;

    @DynamicPropertySource static void secret(DynamicPropertyRegistry registry) {
        registry.add("security.jwt.secret", () -> Base64.getEncoder().encodeToString(new byte[32]));
    }
    User user() { return users.save(User.builder().email(UUID.randomUUID() + "@example.test").passwordHash("private-test-hash").build()); }
    @BeforeEach void setup() {
        mvc = org.springframework.test.web.servlet.setup.MockMvcBuilders.webAppContextSetup(context)
            .apply(org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity()).build();
        User owner = user(), joining = user(), other = user();
        family = families.createFamilyWithProfiles("Selected household", "Asia/Colombo", owner, "Alex", null,
            List.of(new FamilyProfileInput("Alex", "Father", "Male", false), new FamilyProfileInput("Sam", "Mother", "Female", false)), 0);
        creator = members.findByFamilyId(family.getId()).get(0);
        householdProfile = profiles.findByFamilyId(family.getId()).stream().filter(p -> p.getLinkedUserEmail() == null).findFirst().orElseThrow().getId();
        assignee = families.joinFamily(family.getId(), joining, "Sam", "MEMBER", householdProfile);
        Family another = families.createFamilyWithProfiles("Other household", "Asia/Colombo", other, "Other", null,
            List.of(new FamilyProfileInput("Other", "Father", "Male", false)), 0);
        foreign = members.findByFamilyId(another.getId()).get(0);
        bearer = "Bearer " + jwt.generateToken(owner); outsider = "Bearer " + jwt.generateToken(other);
    }
    Map<String,Object> fields() {
        Map<String,Object> body = new HashMap<>();
        body.put("familyId", family.getId().toString()); body.put("title", "Household task"); body.put("description", "Details");
        body.put("originModule", "CHORES"); body.put("assignedToMemberId", assignee.getId().toString());
        body.put("dueDate", "2026-01-01T14:30:00+05:30");
        return body;
    }
    JsonNode create() throws Exception {
        return json.readTree(mvc.perform(post("/api/tasks").header("Authorization", bearer).contentType("application/json").content(json.writeValueAsString(fields())))
            .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString());
    }
    @Test void taskCrudUsesMembershipIdsAndSafeStableResponseShape() throws Exception {
        JsonNode created = create(); UUID id = UUID.fromString(created.get("id").asText());
        assertFalse(created.get("createdAt").isNull());
        assertEquals(assignee.getId().toString(), created.at("/assignedTo/id").asText());
        assertNotEquals(householdProfile.toString(), created.at("/assignedTo/id").asText());
        assertEquals(creator.getId().toString(), created.at("/createdBy/id").asText());
        assertFalse(created.toString().contains("passwordHash")); assertFalse(created.toString().contains("private-test-hash"));
        assertFalse(created.get("family").has("inviteCode")); assertFalse(created.get("family").has("adminEmail"));
        mvc.perform(get("/api/tasks/family/" + family.getId()).header("Authorization", bearer)).andExpect(status().isOk())
            .andExpect(jsonPath("$[0].id").value(id.toString()));
        Map<String,Object> updated = fields(); updated.put("title", "Updated task"); updated.put("assignedToMemberId", null); updated.put("dueDate", null);
        mvc.perform(put("/api/tasks/" + id).header("Authorization", bearer).contentType("application/json").content(json.writeValueAsString(updated)))
            .andExpect(status().isOk()).andExpect(jsonPath("$.assignedTo").isEmpty()).andExpect(jsonPath("$.dueDate").isEmpty());
        assertEquals("Updated task", tasks.findById(id).orElseThrow().getTitle());
        mvc.perform(delete("/api/tasks/" + id).header("Authorization", bearer)).andExpect(status().isNoContent());
        assertFalse(tasks.existsById(id));
        mvc.perform(delete("/api/tasks/" + id).header("Authorization", bearer)).andExpect(status().isNotFound());
    }
    @Test void completionIsAttributedToAuthenticatedMemberAndRetryPreservesTimestamp() throws Exception {
        UUID id = UUID.fromString(create().get("id").asText());
        String first = mvc.perform(put("/api/tasks/" + id + "/complete").header("Authorization", bearer))
            .andExpect(status().isOk()).andExpect(jsonPath("$.completedBy.id").value(creator.getId().toString()))
            .andExpect(jsonPath("$.status").value("COMPLETED")).andReturn().getResponse().getContentAsString();
        String retry = mvc.perform(put("/api/tasks/" + id + "/complete").header("Authorization", bearer))
            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        assertEquals(json.readTree(first).get("completedAt"), json.readTree(retry).get("completedAt"));
    }
    @Test void foreignAssignmentsAndProfileIdsCannotBeUsedAsMemberships() throws Exception {
        UUID id = UUID.fromString(create().get("id").asText());
        Map<String,Object> body = fields(); body.put("assignedToMemberId", foreign.getId().toString());
        for (String method : List.of("POST", "PUT")) {
            mvc.perform((method.equals("POST") ? post("/api/tasks") : put("/api/tasks/" + id))
                .header("Authorization", bearer).contentType("application/json").content(json.writeValueAsString(body))).andExpect(status().isForbidden());
        }
        body.put("assignedToMemberId", householdProfile.toString());
        mvc.perform(post("/api/tasks").header("Authorization", bearer).contentType("application/json").content(json.writeValueAsString(body))).andExpect(status().isNotFound());
        body = fields(); body.put("creatorMemberId", assignee.getId().toString());
        mvc.perform(post("/api/tasks").header("Authorization", bearer).contentType("application/json").content(json.writeValueAsString(body))).andExpect(status().isForbidden());
    }
    @Test void allTaskRoutesRequireAuthenticationAndFamilyMembership() throws Exception {
        UUID id = UUID.fromString(create().get("id").asText());
        mvc.perform(get("/api/tasks/family/" + family.getId())).andExpect(status().isUnauthorized());
        mvc.perform(post("/api/tasks").contentType("application/json").content(json.writeValueAsString(fields()))).andExpect(status().isUnauthorized());
        mvc.perform(put("/api/tasks/" + id).contentType("application/json").content(json.writeValueAsString(fields()))).andExpect(status().isUnauthorized());
        mvc.perform(put("/api/tasks/" + id + "/complete")).andExpect(status().isUnauthorized());
        mvc.perform(delete("/api/tasks/" + id)).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/tasks/family/" + family.getId()).header("Authorization", outsider)).andExpect(status().isForbidden());
        mvc.perform(post("/api/tasks").header("Authorization", outsider).contentType("application/json").content(json.writeValueAsString(fields()))).andExpect(status().isForbidden());
        mvc.perform(put("/api/tasks/" + id).header("Authorization", outsider).contentType("application/json").content(json.writeValueAsString(fields()))).andExpect(status().isForbidden());
        mvc.perform(put("/api/tasks/" + id + "/complete").header("Authorization", outsider)).andExpect(status().isForbidden());
        mvc.perform(delete("/api/tasks/" + id).header("Authorization", outsider)).andExpect(status().isForbidden());
    }
    @Test void invalidFieldsReturnAuthenticationSafeClientErrors() throws Exception {
        for (Map<String,Object> body : List.of(Map.<String,Object>of(), Map.<String,Object>of("familyId", family.getId(), "title", " ", "originModule", "CHORES"))) {
            mvc.perform(post("/api/tasks").header("Authorization", bearer).contentType("application/json").content(json.writeValueAsString(body))).andExpect(status().isBadRequest());
        }
        mvc.perform(put("/api/tasks/" + UUID.randomUUID() + "/complete").header("Authorization", bearer)).andExpect(status().isNotFound());
    }
    @Test void concurrentCompletionsRetainTheFirstCompleterAndTimestamp() throws Exception {
        UUID id = UUID.fromString(create().get("id").asText());
        String secondBearer = "Bearer " + jwt.generateToken(users.findById(assignee.getUser().getId()).orElseThrow());
        var ready = new java.util.concurrent.CountDownLatch(2);
        var start = new java.util.concurrent.CountDownLatch(1);
        var pool = java.util.concurrent.Executors.newFixedThreadPool(2);
        try {
            List<java.util.concurrent.Future<JsonNode>> results = new ArrayList<>();
            for (String authorization : List.of(bearer, secondBearer)) {
                results.add(pool.submit(() -> {
                    ready.countDown(); assertTrue(start.await(10, java.util.concurrent.TimeUnit.SECONDS));
                    return json.readTree(mvc.perform(put("/api/tasks/" + id + "/complete").header("Authorization", authorization))
                        .andExpect(status().isOk()).andReturn().getResponse().getContentAsString());
                }));
            }
            assertTrue(ready.await(10, java.util.concurrent.TimeUnit.SECONDS)); start.countDown();
            JsonNode first = results.get(0).get(15, java.util.concurrent.TimeUnit.SECONDS);
            JsonNode second = results.get(1).get(15, java.util.concurrent.TimeUnit.SECONDS);
            assertEquals(first.get("completedAt"), second.get("completedAt"));
            assertEquals(first.at("/completedBy/id"), second.at("/completedBy/id"));
        } finally { start.countDown(); pool.shutdownNow(); }
    }
}
