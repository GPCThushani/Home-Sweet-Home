package com.homesweethome;

import com.fasterxml.jackson.databind.*;
import com.homesweethome.dto.FamilyProfileInput;
import com.homesweethome.entity.*;
import com.homesweethome.repository.*;
import com.homesweethome.service.*;
import org.junit.jupiter.api.*;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.*;
import java.nio.file.*;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

// All writes are isolated to H2 and a temporary document directory, never PostgreSQL.
@SpringBootTest(properties = {
    "spring.datasource.url=jdbc:h2:mem:health-step3;MODE=PostgreSQL;DB_CLOSE_DELAY=-1",
    "spring.datasource.driver-class-name=org.h2.Driver", "spring.datasource.username=sa",
    "spring.datasource.password=", "spring.jpa.database-platform=org.hibernate.dialect.H2Dialect",
    "spring.jpa.hibernate.ddl-auto=create", "spring.jpa.show-sql=false", "logging.level.root=WARN"
})
class HealthIntegrationTest {
    @TempDir static Path storage;
    MockMvc mvc;
    ObjectMapper json = new ObjectMapper();
    @Autowired org.springframework.web.context.WebApplicationContext context;
    @Autowired FamilyService families;
    @Autowired FamilyProfileRepository profiles;
    @Autowired UserRepository users;
    @Autowired JwtService jwt;
    @Autowired HealthProfileRepository healthProfiles;
    @Autowired MedicineLogRepository logs;
    @Autowired MedicineRepository medicines;
    @Autowired HealthDocumentRepository documents;
    String familyId, person, unregistered, bearer, outsider, foreignPerson;

    @DynamicPropertySource static void properties(DynamicPropertyRegistry registry) {
        registry.add("security.jwt.secret", () -> Base64.getEncoder().encodeToString(new byte[32]));
        registry.add("homesweethome.uploads.health", () -> storage.toString());
    }
    @BeforeEach void setup() {
        mvc = org.springframework.test.web.servlet.setup.MockMvcBuilders.webAppContextSetup(context)
            .apply(org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity()).build();
        User creator = users.save(User.builder().email(UUID.randomUUID() + "@example.test").passwordHash("unused").build());
        Family family = families.createFamilyWithProfiles("Health test", "Asia/Colombo", creator, "Parent", null,
            List.of(new FamilyProfileInput("Parent", "Mother", "Female", false), new FamilyProfileInput("Child", "Son", "Male", false)), 0);
        familyId = family.getId().toString();
        var people = profiles.findByFamilyId(family.getId());
        person = people.stream().filter(p -> p.getLinkedUserEmail() != null).findFirst().orElseThrow().getId().toString();
        unregistered = people.stream().filter(p -> p.getLinkedUserEmail() == null).findFirst().orElseThrow().getId().toString();
        bearer = "Bearer " + jwt.generateToken(creator);
        User other = users.save(User.builder().email(UUID.randomUUID() + "@example.test").passwordHash("unused").build());
        outsider = "Bearer " + jwt.generateToken(other);
        Family foreignFamily = families.createFamilyWithProfiles("Other household", "Asia/Colombo", other, "Other", null,
            List.of(new FamilyProfileInput("Other", "Mother", "Female", false)), 0);
        foreignPerson = profiles.findByFamilyId(foreignFamily.getId()).get(0).getId().toString();
    }
    JsonNode write(String method, String path, Object body) throws Exception {
        return json.readTree(mvc.perform((method.equals("POST") ? post(path) : put(path))
            .header("Authorization", bearer).contentType("application/json").content(json.writeValueAsString(body)))
            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString());
    }
    String path(String type, String profile) { return "/api/health/" + type + "/" + familyId + "/" + profile; }
    @Test void profilesPersistIndependentlyWithoutGetCreatingRows() throws Exception {
        long before = healthProfiles.count();
        mvc.perform(get(path("profile", person)).header("Authorization", bearer)).andExpect(status().isOk()).andExpect(jsonPath("$.id").isEmpty());
        assertEquals(before, healthProfiles.count());
        var first = write("PUT", path("profile", person), Map.of("allergies", "Peanuts", "womensHealthEnabled", true));
        var second = write("PUT", path("profile", unregistered), Map.of("allergies", "Penicillin"));
        assertNotEquals(first.get("id"), second.get("id"));
        mvc.perform(get(path("profile", person)).header("Authorization", bearer)).andExpect(jsonPath("$.allergies").value("Peanuts"));
        mvc.perform(get(path("profile", unregistered)).header("Authorization", bearer)).andExpect(jsonPath("$.allergies").value("Penicillin"));
        assertEquals("Penicillin", healthProfiles.findByFamilyIdAndFamilyMemberId(familyId, unregistered).orElseThrow().getAllergies());
        var updated = write("PUT", path("profile", unregistered), Map.of("allergies", "Updated"));
        assertEquals(second.get("id"), updated.get("id"));
    }
    @Test void everyReadRejectsForeignProfilesAndUnauthenticatedUsers() throws Exception {
        for (String type : List.of("profile", "medicines", "medicines/logs", "appointments", "records", "documents", "womens-health/cycles", "womens-health/entries")) {
            String suffix = type.endsWith("entries") ? "?start=2026-10-01&end=2026-10-31" : "";
            mvc.perform(get(path(type, person) + suffix)).andExpect(status().isUnauthorized());
            mvc.perform(get(path(type, person) + suffix).header("Authorization", outsider)).andExpect(status().isForbidden());
            mvc.perform(get(path(type, foreignPerson) + suffix).header("Authorization", bearer)).andExpect(status().isNotFound());
        }
        mvc.perform(get(path("profile", "Mother")).header("Authorization", bearer)).andExpect(status().isBadRequest());
    }
    @Test void profileScopedWritesCannotCreateRecordsForAnotherHouseholdPerson() throws Exception {
        for (String type : List.of("medicines", "appointments", "records", "documents", "womens-health/cycles")) {
            mvc.perform(post(path(type, foreignPerson)).header("Authorization", bearer).contentType("application/json").content("{}"))
                .andExpect(status().isNotFound());
        }
        mvc.perform(put(path("profile", foreignPerson)).header("Authorization", bearer).contentType("application/json").content("{}"))
            .andExpect(status().isNotFound());
        mvc.perform(multipart(path("documents", foreignPerson) + "/upload")
            .file(new MockMultipartFile("file", "report.pdf", "application/pdf", "%PDF-1.4".getBytes()))
            .param("title", "Report").header("Authorization", bearer)).andExpect(status().isNotFound());
    }
    @Test void medicationLogsAreIdempotentStockSafeAndSchedulesPersist() throws Exception {
        var medicine = write("POST", path("medicines", unregistered), Map.of("name", "Prescribed medicine", "remainingQuantity", 3));
        long id = medicine.get("id").asLong();
        var schedule = write("POST", "/api/health/medicines/" + id + "/schedules", Map.of("scheduledTime", "08:30:00"));
        mvc.perform(get("/api/health/medicines/" + id + "/schedules").header("Authorization", bearer)).andExpect(jsonPath("$[0].scheduledTime").value("08:30:00"));
        write("PUT", "/api/health/medicines/schedules/" + schedule.get("id"), Map.of("scheduledTime", "09:00:00"));
        Map<String,Object> log = Map.of("familyId", familyId, "familyMemberId", unregistered, "medicineId", id, "status", "TAKEN", "scheduledAt", "2026-10-30T08:30:00", "recordedByMemberId", unregistered);
        var first = write("POST", "/api/health/medicines/logs", log);
        assertEquals(person, first.get("recordedByMemberId").asText());
        assertEquals(first.get("id"), write("POST", "/api/health/medicines/logs", log).get("id"));
        assertEquals(2, medicines.findById(id).orElseThrow().getRemainingQuantity());
        mvc.perform(get(path("medicines/logs", person)).header("Authorization", bearer)).andExpect(jsonPath("$.length()").value(0));
        mvc.perform(delete("/api/health/medicines/schedules/" + schedule.get("id")).header("Authorization", outsider)).andExpect(status().isForbidden());
        mvc.perform(delete("/api/health/medicines/" + id).header("Authorization", bearer)).andExpect(status().isNoContent());
        assertEquals(1, logs.findByFamilyIdAndFamilyMemberIdOrderByScheduledAtDesc(familyId, unregistered).size());
        mvc.perform(get(path("medicines", unregistered)).header("Authorization", bearer)).andExpect(jsonPath("$.length()").value(0));
    }
    @Test void appointmentsAndRecordsSupportCrudWithIsolation() throws Exception {
        for (String type : List.of("appointments", "records")) {
            Map<String,Object> body = type.equals("records") ? Map.of("title", "Report", "category", "Lab", "recordDate", "2026-10-01", "doctorName", "Doctor") : Map.of("doctorName", "Doctor", "appointmentDateTime", "2026-11-01T14:30:00", "notes", "Keep notes", "status", "UPCOMING");
            var created = write("POST", path(type, unregistered), body);
            String idPath = "/api/health/" + type + "/" + created.get("id");
            mvc.perform(put(idPath).header("Authorization", outsider).contentType("application/json").content(json.writeValueAsString(body))).andExpect(status().isForbidden());
            write("PUT", idPath, body);
            mvc.perform(get(path(type, person)).header("Authorization", bearer)).andExpect(jsonPath("$.length()").value(0));
            mvc.perform(get(path(type, unregistered)).header("Authorization", bearer)).andExpect(jsonPath("$.length()").value(1));
            mvc.perform(delete(idPath).header("Authorization", bearer)).andExpect(status().isNoContent());
        }
    }
    @Test void cyclesAndDailyEntriesUseRealProfileScopedCycleIds() throws Exception {
        var cycle = write("POST", path("womens-health/cycles", person), Map.of("startDate", "2026-10-01"));
        Map<String,Object> body = new HashMap<>(Map.of("familyId", familyId, "familyMemberId", person, "cycleId", cycle.get("id").asLong(), "date", "2026-10-02", "flow", "Medium"));
        var entry = write("POST", "/api/health/womens-health/entries", body);
        body.put("flow", "Light");
        assertEquals(entry.get("id"), write("POST", "/api/health/womens-health/entries", body).get("id"));
        body.put("familyMemberId", unregistered);
        mvc.perform(post("/api/health/womens-health/entries").header("Authorization", bearer).contentType("application/json").content(json.writeValueAsString(body))).andExpect(status().isForbidden());
        mvc.perform(put("/api/health/womens-health/cycles/" + cycle.get("id") + "/end?endDate=2026-09-30").header("Authorization", bearer)).andExpect(status().isBadRequest());
        mvc.perform(put("/api/health/womens-health/cycles/" + cycle.get("id") + "/end?endDate=2026-10-05").header("Authorization", bearer)).andExpect(status().isOk()).andExpect(jsonPath("$.periodLength").value(5));
    }
    @Test void documentsUploadDownloadAndDeleteWithAuthorizationAndRollback() throws Exception {
        byte[] bytes = "%PDF-1.4\nHealth test document".getBytes(java.nio.charset.StandardCharsets.US_ASCII);
        var result = mvc.perform(multipart(path("documents", unregistered) + "/upload").file(new MockMultipartFile("file", "report.pdf", "application/pdf", bytes)).param("title", "Report").header("Authorization", bearer))
            .andExpect(status().isOk()).andReturn();
        long id = json.readTree(result.getResponse().getContentAsString()).get("id").asLong();
        String file = "/api/health/documents/" + id + "/file";
        mvc.perform(get(file)).andExpect(status().isUnauthorized());
        mvc.perform(get(file).header("Authorization", outsider)).andExpect(status().isForbidden());
        mvc.perform(get(file).header("Authorization", bearer)).andExpect(status().isOk()).andExpect(content().bytes(bytes)).andExpect(header().string("Cache-Control", "no-store"));
        Path stored = storage.resolve(familyId).resolve(unregistered).resolve(id + ".blob");
        assertTrue(Files.exists(stored));
        long before = documents.count();
        mvc.perform(multipart(path("documents", person) + "/upload").file(new MockMultipartFile("file", "bad.pdf", "application/pdf", "not pdf".getBytes())).param("title", "Invalid").header("Authorization", bearer)).andExpect(status().isBadRequest());
        assertEquals(before, documents.count());
        mvc.perform(delete("/api/health/documents/" + id).header("Authorization", bearer)).andExpect(status().isNoContent());
        assertFalse(Files.exists(stored));
        assertFalse(documents.existsById(id));
    }
}
