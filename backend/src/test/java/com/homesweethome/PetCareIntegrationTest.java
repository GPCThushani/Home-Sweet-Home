package com.homesweethome;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
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
import org.springframework.test.web.servlet.MockMvc;
import java.nio.file.Path;
import java.time.*;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(properties = {
    "spring.datasource.url=jdbc:h2:mem:pet-care-integration;MODE=PostgreSQL;DB_CLOSE_DELAY=-1",
    "spring.datasource.driver-class-name=org.h2.Driver", "spring.datasource.username=sa",
    "spring.datasource.password=", "spring.jpa.database-platform=org.hibernate.dialect.H2Dialect",
    "spring.jpa.hibernate.ddl-auto=create", "spring.sql.init.mode=never", "spring.jpa.show-sql=false",
    "pets.schedule.enabled=false", "logging.level.root=WARN"
})
class PetCareIntegrationTest {
    @TempDir static Path storage;
    @Autowired org.springframework.web.context.WebApplicationContext context;
    @Autowired FamilyService familyService;
    @Autowired UserRepository users;
    @Autowired FamilyMemberRepository members;
    @Autowired GlobalTaskRepository tasks;
    @Autowired JwtService jwt;
    @Autowired PetTaskGenerator generator;
    MockMvc mvc;
    ObjectMapper json = new ObjectMapper();
    UUID petId, memberId, otherMemberId;
    String bearer, outsider;

    @DynamicPropertySource static void properties(DynamicPropertyRegistry registry) {
        registry.add("security.jwt.secret", () -> Base64.getEncoder().encodeToString(new byte[32]));
        registry.add("homesweethome.uploads.pet-documents", () -> storage.toString());
    }
    @BeforeEach void setup() throws Exception {
        mvc = org.springframework.test.web.servlet.setup.MockMvcBuilders.webAppContextSetup(context)
            .apply(org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity()).build();
        User owner = users.save(User.builder().email(UUID.randomUUID() + "@example.test").passwordHash("unused").build());
        User other = users.save(User.builder().email(UUID.randomUUID() + "@example.test").passwordHash("unused").build());
        Family family = familyService.createFamilyWithProfiles("Pets", "Asia/Colombo", owner, "Owner", null,
            List.of(new FamilyProfileInput("Owner", "Parent", "Other", false)), 0);
        Family foreign = familyService.createFamilyWithProfiles("Other", "Asia/Colombo", other, "Other", null,
            List.of(new FamilyProfileInput("Other", "Parent", "Other", false)), 0);
        memberId = members.findByFamilyId(family.getId()).get(0).getId();
        otherMemberId = members.findByFamilyId(foreign.getId()).get(0).getId();
        bearer = "Bearer " + jwt.generateToken(owner);
        outsider = "Bearer " + jwt.generateToken(other);
        String result = mvc.perform(post("/api/pets/{familyId}", family.getId()).header("Authorization", bearer)
            .contentType("application/json").content("{\"name\":\"Luna\",\"type\":\"Cat\"}"))
            .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
        petId = UUID.fromString(json.readTree(result).get("id").asText());
    }
    JsonNode createEntry(String kind, String body) throws Exception {
        var response = mvc.perform(post("/api/pets/{petId}/entries/{kind}", petId, kind)
            .header("Authorization", bearer).contentType("application/json").content(body))
            .andReturn();
        if (response.getResponse().getStatus() != 201)
            throw new AssertionError("Pet record returned " + response.getResponse().getStatus()
                + ": " + response.getResponse().getContentAsString()
                + "; cause=" + response.getResolvedException());
        return json.readTree(response.getResponse().getContentAsString());
    }

    @Test void vaccinationHealthMedicationAndWeightCrud() throws Exception {
        JsonNode vaccine = createEntry("VACCINATION", "{\"title\":\"Rabies\",\"recordDate\":\"2025-01-01\",\"nextDueDate\":\"2099-01-01\"}");
        assertEquals("UPCOMING", vaccine.get("computedStatus").asText());
        String vaccineId = vaccine.get("id").asText();
        mvc.perform(get("/api/pets/{petId}/entries/VACCINATION", petId).header("Authorization", bearer))
            .andExpect(status().isOk()).andExpect(jsonPath("$[0].title").value("Rabies"));
        mvc.perform(put("/api/pets/{petId}/entries/VACCINATION/{id}", petId, vaccineId)
            .header("Authorization", bearer).contentType("application/json")
            .content("{\"title\":\"Rabies updated\",\"recordDate\":\"2025-01-01\"}"))
            .andExpect(status().isOk()).andExpect(jsonPath("$.title").value("Rabies updated"));
        createEntry("HEALTH", "{\"title\":\"Allergy\",\"recordDate\":\"2025-01-01\",\"description\":\"Food sensitivity\"}");
        createEntry("MEDICATION", "{\"title\":\"Medicine\",\"dosage\":\"2 mg\",\"frequency\":\"Daily\",\"startDate\":\"2025-01-01\"}");
        createEntry("WEIGHT", "{\"title\":\"Weight check\",\"recordDate\":\"2025-01-01\",\"weightKg\":4.2}");
        mvc.perform(delete("/api/pets/{petId}/entries/VACCINATION/{id}", petId, vaccineId)
            .header("Authorization", bearer)).andExpect(status().isNoContent());
    }

    @Test void recurringScheduleGeneratesIdempotentTasksAndPreservesCompletion() throws Exception {
        LocalDate tomorrow = LocalDate.now(ZoneId.of("Asia/Colombo")).plusDays(1);
        String body = json.writeValueAsString(Map.of("activityName", "Morning feeding", "frequency", "DAILY",
            "scheduledTime", "08:00:00", "startDate", tomorrow.toString(), "assignedMemberId", memberId,
            "active", true, "autoTasks", true));
        String response = mvc.perform(post("/api/pets/{petId}/care-schedules", petId)
            .header("Authorization", bearer).contentType("application/json").content(body))
            .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
        UUID scheduleId = UUID.fromString(json.readTree(response).get("id").asText());
        List<GlobalTask> generated = tasks.findBySourceCareScheduleId(scheduleId);
        assertFalse(generated.isEmpty());
        assertTrue(generated.size() <= 14);
        assertEquals(memberId, generated.get(0).getAssignedTo().getId());
        assertEquals("PETS", generated.get(0).getOriginModule());
        generator.generate(scheduleId);
        assertEquals(generated.size(), tasks.findBySourceCareScheduleId(scheduleId).size());
        String edited = json.writeValueAsString(Map.of("activityName", "Evening feeding", "frequency", "DAILY",
            "scheduledTime", "18:00:00", "startDate", tomorrow.toString(), "assignedMemberId", memberId,
            "active", true, "autoTasks", true));
        mvc.perform(put("/api/pets/{petId}/care-schedules/{id}", petId, scheduleId)
            .header("Authorization", bearer).contentType("application/json").content(edited))
            .andExpect(status().isOk());
        assertTrue(tasks.findBySourceCareScheduleId(scheduleId).stream()
            .allMatch(task -> task.getTitle().contains("Evening feeding")));
        String paused = edited.replace("\"active\":true", "\"active\":false");
        mvc.perform(put("/api/pets/{petId}/care-schedules/{id}", petId, scheduleId)
            .header("Authorization", bearer).contentType("application/json").content(paused))
            .andExpect(status().isOk());
        assertTrue(tasks.findBySourceCareScheduleId(scheduleId).isEmpty());
        mvc.perform(put("/api/pets/{petId}/care-schedules/{id}", petId, scheduleId)
            .header("Authorization", bearer).contentType("application/json").content(edited))
            .andExpect(status().isOk());
        assertFalse(tasks.findBySourceCareScheduleId(scheduleId).isEmpty());
        UUID taskId = tasks.findBySourceCareScheduleId(scheduleId).get(0).getId();
        mvc.perform(put("/api/tasks/{taskId}/complete", taskId).header("Authorization", bearer))
            .andExpect(status().isOk());
        mvc.perform(get("/api/pets/{petId}/daily-care/history", petId).header("Authorization", bearer))
            .andExpect(status().isOk()).andExpect(jsonPath("$[0].id").value(taskId.toString()));
        mvc.perform(delete("/api/pets/{petId}/care-schedules/{id}", petId, scheduleId)
            .header("Authorization", bearer)).andExpect(status().isNoContent());
        assertTrue(tasks.findBySourceCareScheduleId(scheduleId).stream().anyMatch(t -> t.getId().equals(taskId) && "COMPLETED".equals(t.getStatus())));
    }

    @Test void dailyCareVetDocumentsAndAuthorization() throws Exception {
        mvc.perform(put("/api/pets/{petId}/daily-care/instructions", petId).header("Authorization", bearer)
            .contentType("application/json").content("{\"foodType\":\"Dry food\",\"walkingMinutes\":25}"))
            .andExpect(status().isOk()).andExpect(jsonPath("$.foodType").value("Dry food"));
        createEntry("VET", "{\"title\":\"Checkup\",\"appointmentAt\":\"2099-01-01T09:00:00Z\",\"clinic\":\"Vet Clinic\",\"status\":\"UPCOMING\"}");
        byte[] pdf = "%PDF-1.7 pet".getBytes();
        String upload = mvc.perform(multipart("/api/pets/{petId}/documents", petId)
            .file(new MockMultipartFile("file", "record.pdf", "application/pdf", pdf))
            .param("title", "Vet record").param("category", "Medical Reports").header("Authorization", bearer))
            .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
        String documentId = json.readTree(upload).get("id").asText();
        mvc.perform(get("/api/pets/{petId}/documents/{id}/file", petId, documentId).header("Authorization", bearer))
            .andExpect(status().isOk()).andExpect(content().bytes(pdf));
        mvc.perform(get("/api/pets/{petId}/documents/{id}/file", petId, documentId).header("Authorization", outsider))
            .andExpect(status().isForbidden());
        mvc.perform(get("/api/pets/{petId}/documents", petId)).andExpect(status().isUnauthorized());
        mvc.perform(delete("/api/pets/{petId}/documents/{id}", petId, documentId).header("Authorization", bearer))
            .andExpect(status().isNoContent());
    }

    @Test void rejectsInvalidUploadsAndCrossFamilyRecords() throws Exception {
        mvc.perform(post("/api/pets/{petId}/care-schedules", petId)
            .header("Authorization", bearer).contentType("application/json")
            .content("{\"activityName\":\"Feed\",\"scheduledTime\":\"08:00:00\",\"startDate\":\"2099-01-01\"}"))
            .andExpect(status().isBadRequest());
        mvc.perform(multipart("/api/pets/{petId}/documents", petId)
            .file(new MockMultipartFile("file", "fake.pdf", "application/pdf", "plain text".getBytes()))
            .param("title", "Invalid").param("category", "Other").header("Authorization", bearer))
            .andExpect(status().isBadRequest());
        mvc.perform(get("/api/pets/{petId}/entries/HEALTH", petId).header("Authorization", outsider))
            .andExpect(status().isForbidden());
        mvc.perform(post("/api/pets/{petId}/care-schedules", petId)
            .header("Authorization", bearer).contentType("application/json")
            .content(json.writeValueAsString(Map.of("activityName", "Feed", "frequency", "DAILY",
                "scheduledTime", "08:00:00", "startDate", "2099-01-01",
                "assignedMemberId", otherMemberId, "active", true, "autoTasks", true))))
            .andExpect(status().isBadRequest());
    }

    @Test void vetReminderReschedulesAndCancelsWithVisit() throws Exception {
        String original = json.writeValueAsString(Map.of("title", "Checkup", "appointmentAt", "2099-01-01T09:00:00Z",
            "clinic", "Vet Clinic", "status", "UPCOMING", "reminderTask", true, "assignedMemberId", memberId));
        JsonNode visit = createEntry("VET", original);
        UUID visitId = UUID.fromString(visit.get("id").asText());
        List<GlobalTask> linked = tasks.findBySourcePetEntryId(visitId);
        assertEquals(1, linked.size());
        assertEquals(memberId, linked.get(0).getAssignedTo().getId());
        String moved = original.replace("2099-01-01T09:00:00Z", "2099-01-02T10:00:00Z");
        mvc.perform(put("/api/pets/{petId}/entries/VET/{id}", petId, visitId)
            .header("Authorization", bearer).contentType("application/json").content(moved))
            .andExpect(status().isOk());
        assertEquals(linked.get(0).getId(), tasks.findBySourcePetEntryId(visitId).get(0).getId());
        assertEquals(Instant.parse("2099-01-02T10:00:00Z"), tasks.findBySourcePetEntryId(visitId).get(0).getDueDate().toInstant());
        String cancelled = moved.replace("\"status\":\"UPCOMING\"", "\"status\":\"CANCELLED\"")
            .replace("\"reminderTask\":true", "\"reminderTask\":false");
        mvc.perform(put("/api/pets/{petId}/entries/VET/{id}", petId, visitId)
            .header("Authorization", bearer).contentType("application/json").content(cancelled))
            .andExpect(status().isOk());
        assertTrue(tasks.findBySourcePetEntryId(visitId).isEmpty());
    }

    @Test void deletingPetRemovesDependentRecordsAndKeepsCompletedTaskHistory() throws Exception {
        createEntry("HEALTH", "{\"title\":\"Allergy\",\"recordType\":\"ALLERGY\",\"recordDate\":\"2025-01-01\"}");
        LocalDate tomorrow = LocalDate.now(ZoneId.of("Asia/Colombo")).plusDays(1);
        mvc.perform(post("/api/pets/{petId}/care-schedules", petId)
            .header("Authorization", bearer).contentType("application/json")
            .content(json.writeValueAsString(Map.of("activityName", "Feed", "frequency", "DAILY",
                "scheduledTime", "08:00:00", "startDate", tomorrow.toString(),
                "assignedMemberId", memberId, "active", true, "autoTasks", true))))
            .andExpect(status().isCreated());
        UUID taskId = tasks.findBySourcePetId(petId).get(0).getId();
        mvc.perform(put("/api/tasks/{taskId}/complete", taskId).header("Authorization", bearer))
            .andExpect(status().isOk());
        mvc.perform(delete("/api/pets/{petId}", petId).header("Authorization", bearer))
            .andExpect(status().isNoContent());
        mvc.perform(get("/api/pets/item/{petId}", petId).header("Authorization", bearer))
            .andExpect(status().isNotFound());
        assertTrue(tasks.findBySourcePetId(petId).stream()
            .allMatch(task -> "COMPLETED".equals(task.getStatus())));
        assertTrue(tasks.findById(taskId).isPresent());
    }
}
