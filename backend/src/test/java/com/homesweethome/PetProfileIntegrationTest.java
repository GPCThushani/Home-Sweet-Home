package com.homesweethome;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.homesweethome.dto.FamilyProfileInput;
import com.homesweethome.entity.Family;
import com.homesweethome.entity.User;
import com.homesweethome.repository.UserRepository;
import com.homesweethome.service.FamilyService;
import com.homesweethome.service.JwtService;
import org.junit.jupiter.api.*;
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
        "spring.datasource.url=jdbc:h2:mem:pets-stage1;MODE=PostgreSQL;DB_CLOSE_DELAY=-1",
        "spring.datasource.driver-class-name=org.h2.Driver", "spring.datasource.username=sa",
        "spring.datasource.password=", "spring.jpa.database-platform=org.hibernate.dialect.H2Dialect",
        "spring.jpa.hibernate.ddl-auto=create", "spring.sql.init.mode=never",
        "spring.jpa.show-sql=false", "logging.level.root=WARN"
})
class PetProfileIntegrationTest {
    @TempDir static Path photos;
    @Autowired org.springframework.web.context.WebApplicationContext context;
    @Autowired FamilyService families;
    @Autowired UserRepository users;
    @Autowired JwtService jwt;
    MockMvc mvc;
    ObjectMapper json = new ObjectMapper();
    String familyId, owner, outsider;

    @DynamicPropertySource static void properties(DynamicPropertyRegistry registry) {
        registry.add("security.jwt.secret", () -> Base64.getEncoder().encodeToString(new byte[32]));
        registry.add("homesweethome.uploads.pets", () -> photos.toString());
    }
    @BeforeEach void setup() {
        mvc = org.springframework.test.web.servlet.setup.MockMvcBuilders.webAppContextSetup(context)
                .apply(org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity()).build();
        User first = users.save(User.builder().email(UUID.randomUUID() + "@example.test").passwordHash("unused").build());
        User second = users.save(User.builder().email(UUID.randomUUID() + "@example.test").passwordHash("unused").build());
        Family family = families.createFamilyWithProfiles("Pet family", "Asia/Colombo", first, "Owner", null,
                List.of(new FamilyProfileInput("Owner", "Parent", "Other", false)), 0);
        families.createFamilyWithProfiles("Foreign family", "Asia/Colombo", second, "Other", null,
                List.of(new FamilyProfileInput("Other", "Parent", "Other", false)), 0);
        familyId = family.getId().toString();
        owner = "Bearer " + jwt.generateToken(first);
        outsider = "Bearer " + jwt.generateToken(second);
    }

    @Test void profileCrudPhotoAndAuthorization() throws Exception {
        String body = """
                {"name":"Luna","type":"Cat","breed":"Mixed","weightKg":4.2,"photoUrl":"assets/images/pets/cat.jpg"}
                """;
        String created = mvc.perform(post("/api/pets/{family}", familyId).header("Authorization", owner)
                .contentType("application/json").content(body)).andExpect(status().isCreated())
                .andExpect(jsonPath("$.name").value("Luna")).andReturn().getResponse().getContentAsString();
        String id = json.readTree(created).get("id").asText();
        mvc.perform(get("/api/pets/{family}", familyId).header("Authorization", owner))
                .andExpect(status().isOk()).andExpect(jsonPath("$[0].id").value(id));
        mvc.perform(get("/api/pets/item/{id}", id).header("Authorization", outsider)).andExpect(status().isForbidden());
        mvc.perform(put("/api/pets/{id}", id).header("Authorization", owner).contentType("application/json")
                .content("{\"name\":\"Luna\",\"type\":\"Cat\",\"weightKg\":4.5}"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.weightKg").value(4.5));
        byte[] png = new byte[]{(byte)137, 80, 78, 71, 13, 10, 26, 10, 1};
        mvc.perform(multipart("/api/pets/{id}/photo", id)
                .file(new MockMultipartFile("file", "luna.png", "image/png", png)).header("Authorization", owner))
                .andExpect(status().isOk());
        mvc.perform(get("/api/pets/{id}/photo", id).header("Authorization", owner))
                .andExpect(status().isOk()).andExpect(content().bytes(png));
        mvc.perform(get("/api/pets/{id}/photo", id).header("Authorization", outsider)).andExpect(status().isForbidden());
        mvc.perform(delete("/api/pets/{id}", id).header("Authorization", owner)).andExpect(status().isNoContent());
    }

    @Test void rejectsInvalidProfileAndPhoto() throws Exception {
        mvc.perform(post("/api/pets/{family}", familyId).header("Authorization", owner)
                .contentType("application/json").content("{\"name\":\"\",\"type\":\"Dog\"}"))
                .andExpect(status().isBadRequest());
        mvc.perform(get("/api/pets/{family}", familyId)).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/pets/{family}", familyId).header("Authorization", outsider)).andExpect(status().isForbidden());
    }
}
