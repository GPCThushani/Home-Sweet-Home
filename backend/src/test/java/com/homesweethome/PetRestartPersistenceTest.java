package com.homesweethome;

import com.homesweethome.dto.FamilyProfileInput;
import com.homesweethome.dto.PetCareScheduleRequest;
import com.homesweethome.entity.*;
import com.homesweethome.repository.*;
import com.homesweethome.service.*;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.nio.file.Path;
import java.time.*;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;

class PetRestartPersistenceTest {
    @TempDir Path temporary;

    ConfigurableApplicationContext start(String ddl) {
        return new SpringApplicationBuilder(BackendApplication.class).run(
            "--server.port=0", "--spring.datasource.url=jdbc:h2:file:" + temporary.resolve("pets").toAbsolutePath().toString().replace('\\', '/') + ";MODE=PostgreSQL",
            "--spring.datasource.driver-class-name=org.h2.Driver", "--spring.datasource.username=sa", "--spring.datasource.password=",
            "--spring.jpa.database-platform=org.hibernate.dialect.H2Dialect", "--spring.jpa.hibernate.ddl-auto=" + ddl,
            "--spring.sql.init.mode=never", "--spring.jpa.show-sql=false", "--logging.level.root=ERROR",
            "--security.jwt.secret=" + Base64.getEncoder().encodeToString(new byte[32]));
    }

    @Test void savedPetAndScheduleGeneratePendingTasksAfterRestart() {
        UUID petId, scheduleId;
        try (var app = start("create")) {
            User user = app.getBean(UserRepository.class).save(User.builder()
                .email("pet-restart@example.test").passwordHash("unused").build());
            Family family = app.getBean(FamilyService.class).createFamilyWithProfiles("Pet restart", "Asia/Colombo", user,
                "Owner", null, List.of(new FamilyProfileInput("Owner", "Parent", "Other", false)), 0);
            FamilyMember member = app.getBean(FamilyMemberRepository.class).findByFamilyId(family.getId()).get(0);
            Pet pet = new Pet(); pet.setFamilyId(family.getId()); pet.setName("Luna"); pet.setType("Cat");
            petId = app.getBean(PetRepository.class).save(pet).getId();
            SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(user.getEmail(), "unused", List.of()));
            PetCareScheduleRequest request = new PetCareScheduleRequest("Feed Luna", null, "DAILY", Set.of(),
                LocalTime.of(8, 0), LocalDate.now(ZoneId.of("Asia/Colombo")).plusDays(1), null,
                member.getId(), true, true);
            scheduleId = app.getBean(PetCareScheduleService.class).save(petId, null, request).getId();
            var tasks = app.getBean(GlobalTaskRepository.class);
            assertFalse(tasks.findBySourceCareScheduleId(scheduleId).isEmpty());
            tasks.deleteAll(tasks.findBySourceCareScheduleId(scheduleId));
        } finally { SecurityContextHolder.clearContext(); }
        try (var app = start("validate")) {
            assertEquals("Luna", app.getBean(PetRepository.class).findById(petId).orElseThrow().getName());
            assertTrue(app.getBean(GlobalTaskRepository.class).findBySourceCareScheduleId(scheduleId).isEmpty());
            app.getBean(PetTaskGenerator.class).refreshWindow();
            assertFalse(app.getBean(GlobalTaskRepository.class).findBySourceCareScheduleId(scheduleId).isEmpty());
        }
    }
}
