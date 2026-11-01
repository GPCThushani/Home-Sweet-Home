package com.homesweethome;

import com.homesweethome.controller.HealthController;
import com.homesweethome.dto.FamilyProfileInput;
import com.homesweethome.entity.*;
import com.homesweethome.repository.*;
import com.homesweethome.service.FamilyService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import java.nio.file.Path;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;

class HealthRestartPersistenceTest {
    @TempDir Path temporary;

    ConfigurableApplicationContext start(String ddl) {
        return new SpringApplicationBuilder(BackendApplication.class).run(
            "--server.port=0", "--spring.datasource.url=jdbc:h2:file:" + temporary.resolve("health").toAbsolutePath().toString().replace('\\', '/') + ";MODE=PostgreSQL",
            "--spring.datasource.driver-class-name=org.h2.Driver", "--spring.datasource.username=sa", "--spring.datasource.password=",
            "--spring.jpa.database-platform=org.hibernate.dialect.H2Dialect", "--spring.jpa.hibernate.ddl-auto=" + ddl,
            "--spring.sql.init.mode=never",
            "--security.jwt.secret=" + Base64.getEncoder().encodeToString(new byte[32]),
            "--spring.jpa.show-sql=false", "--logging.level.root=ERROR");
    }
    @Test void savedProfileAndMedicineSurviveCompleteApplicationContextRestart() {
        String familyId, personId;
        Long medicineId;
        UUID taskId;
        try (var app = start("create")) {
            User user = app.getBean(UserRepository.class).save(User.builder().email("restart@example.test").passwordHash("unused").build());
            Family family = app.getBean(FamilyService.class).createFamilyWithProfiles("Restart test", "Asia/Colombo", user, "Parent", null,
                List.of(new FamilyProfileInput("Parent", "Mother", "Female", false), new FamilyProfileInput("Child", "Son", "Male", false)), 0);
            familyId = family.getId().toString();
            personId = app.getBean(FamilyProfileRepository.class).findByFamilyId(family.getId()).stream().filter(p -> p.getLinkedUserEmail() == null).findFirst().orElseThrow().getId().toString();
            SecurityContextHolder.getContext().setAuthentication(new UsernamePasswordAuthenticationToken(user.getEmail(), "unused", List.of()));
            HealthProfile profile = new HealthProfile(); profile.setAllergies("Persistent allergy");
            app.getBean(HealthController.class).updateProfile(familyId, personId, profile);
            Medicine medicine = new Medicine(); medicine.setName("Persistent medicine"); medicine.setRemainingQuantity(7);
            medicineId = app.getBean(HealthController.class).addMedicine(familyId, personId, medicine).getBody().getId();
            FamilyMember creator = app.getBean(FamilyMemberRepository.class).findByFamilyId(family.getId()).get(0);
            taskId = app.getBean(com.homesweethome.service.GlobalTaskService.class).createTask(family, "Persistent task", "Saved details", "CHORES", creator, creator, null).getId();
        } finally { SecurityContextHolder.clearContext(); }
        try (var app = start("validate")) {
            assertEquals("Persistent allergy", app.getBean(HealthProfileRepository.class).findByFamilyIdAndFamilyMemberId(familyId, personId).orElseThrow().getAllergies());
            Medicine medicine = app.getBean(MedicineRepository.class).findById(medicineId).orElseThrow();
            assertEquals(personId, medicine.getFamilyMemberId()); assertEquals(7, medicine.getRemainingQuantity());
            GlobalTask task = app.getBean(GlobalTaskRepository.class).findById(taskId).orElseThrow();
            assertEquals("Persistent task", task.getTitle()); assertEquals("PENDING", task.getStatus());
            assertEquals(UUID.fromString(familyId), task.getFamily().getId());
            assertNotNull(task.getAssignedTo().getId());
        }
    }
}
