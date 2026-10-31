package com.homesweethome;

import com.homesweethome.dto.FamilyProfileInput;
import com.homesweethome.entity.Family;
import com.homesweethome.entity.User;
import com.homesweethome.repository.FamilyProfileRepository;
import com.homesweethome.repository.UserRepository;
import com.homesweethome.service.FamilyService;
import com.homesweethome.service.JwtService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import java.nio.file.Path;
import java.util.Base64;
import java.util.List;
import java.util.UUID;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(properties = {
        "spring.datasource.url=jdbc:h2:mem:family-documents;MODE=PostgreSQL;DB_CLOSE_DELAY=-1",
        "spring.datasource.driver-class-name=org.h2.Driver", "spring.datasource.username=sa",
        "spring.datasource.password=", "spring.jpa.database-platform=org.hibernate.dialect.H2Dialect",
        "spring.jpa.hibernate.ddl-auto=create", "spring.sql.init.mode=never", "spring.jpa.show-sql=false",
        "logging.level.root=WARN"
})
class FamilyDocumentIntegrationTest {
    @TempDir static Path storage;
    @Autowired org.springframework.web.context.WebApplicationContext context;
    @Autowired FamilyService families;
    @Autowired FamilyProfileRepository profiles;
    @Autowired UserRepository users;
    @Autowired JwtService jwt;
    MockMvc mvc;
    String familyId, profileId, bearer, outsider, otherFamilyId;

    @DynamicPropertySource static void properties(DynamicPropertyRegistry registry) {
        registry.add("security.jwt.secret", () -> Base64.getEncoder().encodeToString(new byte[32]));
        registry.add("homesweethome.uploads.documents", () -> storage.toString());
    }

    @BeforeEach void setup() {
        mvc = org.springframework.test.web.servlet.setup.MockMvcBuilders.webAppContextSetup(context)
                .apply(org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity()).build();
        User owner = users.save(User.builder().email(UUID.randomUUID() + "@example.test").passwordHash("unused").build());
        User other = users.save(User.builder().email(UUID.randomUUID() + "@example.test").passwordHash("unused").build());
        Family family = families.createFamilyWithProfiles("Documents", "Asia/Colombo", owner, "Owner", null,
                List.of(new FamilyProfileInput("Owner", "Parent", "Other", false), new FamilyProfileInput("Child", "Child", "Other", false)), 0);
        Family foreign = families.createFamilyWithProfiles("Other", "Asia/Colombo", other, "Other", null,
                List.of(new FamilyProfileInput("Other", "Parent", "Other", false)), 0);
        familyId = family.getId().toString();
        profileId = profiles.findByFamilyId(family.getId()).get(1).getId().toString();
        otherFamilyId = foreign.getId().toString();
        bearer = "Bearer " + jwt.generateToken(owner);
        outsider = "Bearer " + jwt.generateToken(other);
    }

    @Test void uploadListDownloadAndDeleteFamilyDocument() throws Exception {
        MockMultipartFile file = new MockMultipartFile("file", "policy.pdf", "application/pdf", "%PDF-1.7 test".getBytes());
        String body = mvc.perform(multipart("/api/documents/{family}/upload", familyId).file(file)
                        .param("title", "Insurance policy").param("category", "Insurance").param("familyProfileId", profileId)
                        .header("Authorization", bearer))
                .andExpect(status().isCreated()).andExpect(jsonPath("$.familyProfileId").value(profileId))
                .andExpect(jsonPath("$.familyProfileName").value("Child")).andReturn().getResponse().getContentAsString();
        String id = new com.fasterxml.jackson.databind.ObjectMapper().readTree(body).get("id").asText();
        mvc.perform(get("/api/documents/{family}", familyId).header("Authorization", bearer))
                .andExpect(status().isOk()).andExpect(jsonPath("$[0].id").value(id));
        mvc.perform(get("/api/documents/{id}/file", id).header("Authorization", bearer))
                .andExpect(status().isOk()).andExpect(header().string("Content-Type", "application/pdf"));
        mvc.perform(delete("/api/documents/{id}", id).header("Authorization", bearer)).andExpect(status().isNoContent());
    }

    @Test void rejectsInvalidFilesAndCrossFamilyProfile() throws Exception {
        MockMultipartFile invalid = new MockMultipartFile("file", "bad.exe", "application/octet-stream", new byte[]{1, 2});
        mvc.perform(multipart("/api/documents/{family}/upload", familyId).file(invalid).param("title", "Bad").param("category", "Other").header("Authorization", bearer))
                .andExpect(status().isBadRequest());
        String foreignProfile = profiles.findByFamilyId(UUID.fromString(otherFamilyId)).get(0).getId().toString();
        MockMultipartFile pdf = new MockMultipartFile("file", "file.pdf", "application/pdf", "%PDF-x".getBytes());
        mvc.perform(multipart("/api/documents/{family}/upload", familyId).file(pdf).param("title", "Wrong").param("category", "Other").param("familyProfileId", foreignProfile).header("Authorization", bearer))
                .andExpect(status().isNotFound());
    }

    @Test void requiresMembership() throws Exception {
        mvc.perform(get("/api/documents/{family}", familyId)).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/documents/{family}", familyId).header("Authorization", outsider)).andExpect(status().isForbidden());
    }
}
