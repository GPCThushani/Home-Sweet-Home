package com.homesweethome;

import com.homesweethome.config.*;
import com.homesweethome.controller.*;
import com.homesweethome.entity.*;
import com.homesweethome.repository.*;
import com.homesweethome.service.*;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Import;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.junit.jupiter.web.SpringJUnitWebConfig;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;
import org.springframework.web.servlet.config.annotation.EnableWebMvc;

import java.util.*;
import javax.crypto.SecretKey;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

// Real MVC, security chain, JWT signing/parsing, BCrypt, and controllers.
// Repository mocks deliberately prevent any connection to the user's database.
@SpringJUnitWebConfig(AuthenticationIntegrationTest.Config.class)
class AuthenticationIntegrationTest {
    private static final SecretKey KEY = Keys.secretKeyFor(SignatureAlgorithm.HS256);
    private static final UUID FAMILY = UUID.randomUUID();
    private static final UUID OTHER_FAMILY = UUID.randomUUID();
    private static final UUID PERSON = UUID.randomUUID();
    private static final UUID TASK = UUID.randomUUID();
    private static final String EMAIL = "member@example.test";
    private static final String PASSWORD = "Test-password-123!";

    @Autowired WebApplicationContext context;
    @Autowired UserRepository users;
    @Autowired FamilyMemberRepository members;
    @Autowired FamilyProfileRepository profiles;
    @Autowired FamilyRepository families;
    @Autowired FamilyService familyService;
    @Autowired GlobalTaskService tasks;
    @Autowired HealthProfileRepository healthProfiles;
    @Autowired MedicineRepository medicines;
    @Autowired MedicineLogRepository logs;
    @Autowired HealthAppointmentRepository appointments;
    @Autowired HealthRecordRepository records;
    @Autowired HealthDocumentRepository documents;
    @Autowired MenstrualCycleRepository cycles;
    @Autowired MenstrualEntryRepository entries;
    @Autowired PasswordEncoder encoder;
    @Autowired JwtService jwt;
    private MockMvc mvc;
    private User user;
    private Family family;
    private FamilyMember member;
    private GlobalTask task;
    private String bearer;

    @BeforeEach
    void setup() {
        reset(users, members, profiles, families, familyService, tasks, healthProfiles,
                medicines, logs, appointments, records, documents, cycles, entries);
        mvc = MockMvcBuilders.webAppContextSetup(context).apply(springSecurity()).build();
        user = User.builder().id(UUID.randomUUID()).email(EMAIL)
                .passwordHash(encoder.encode(PASSWORD)).build();
        family = Family.builder().id(FAMILY).name("Test family").build();
        member = FamilyMember.builder().id(UUID.randomUUID()).family(family)
                .user(user).role("MEMBER").nickname("Test member").build();
        task = GlobalTask.builder().id(TASK).family(family).title("Test task")
                .createdBy(member).originModule("GENERAL").build();
        when(users.findByEmail(EMAIL)).thenReturn(Optional.of(user));
        when(users.findById(user.getId())).thenReturn(Optional.of(user));
        when(families.findById(FAMILY)).thenReturn(Optional.of(family));
        when(members.existsByFamilyIdAndUserEmail(FAMILY, EMAIL)).thenReturn(true);
        when(members.findByFamilyId(FAMILY)).thenReturn(List.of(member));
        when(profiles.findByFamilyId(FAMILY)).thenReturn(List.of());
        when(profiles.existsByIdAndFamilyId(PERSON, FAMILY)).thenReturn(true);
        FamilyProfile healthPerson = new FamilyProfile(); healthPerson.setId(PERSON); healthPerson.setFamily(family);
        when(profiles.findHealthProfileForUpdate(PERSON)).thenReturn(Optional.of(healthPerson));
        when(tasks.getTaskById(TASK)).thenReturn(task);
        when(tasks.getAllTasksForFamily(FAMILY)).thenReturn(List.of(task));
        bearer = "Bearer " + jwt.generateToken(user);
    }

    @Test
    void loginUsesBcryptAndIgnoresStaleBearerToken() throws Exception {
        String body = "{\"email\":\"" + EMAIL + "\",\"password\":\"" + PASSWORD + "\"}";
        String response = mvc.perform(post("/api/users/login").header("Authorization", "Bearer broken")
                        .contentType("application/json").content(body))
                .andExpect(status().isOk()).andExpect(jsonPath("$.userId").value(user.getId().toString()))
                .andExpect(jsonPath("$.token").isString()).andExpect(jsonPath("$.passwordHash").doesNotExist())
                .andReturn().getResponse().getContentAsString();
        assertFalse(response.contains(user.getPasswordHash()));
        mvc.perform(post("/api/users/login").contentType("application/json")
                        .content("{\"email\":\"" + EMAIL + "\",\"password\":\"wrong\"}"))
                .andExpect(status().isUnauthorized()).andExpect(jsonPath("$.error").isString());
    }

    @Test
    void registrationIsPublicAndReturnsRealSignedSession() throws Exception {
        when(users.save(any(User.class))).thenAnswer(invocation -> {
            User saved = invocation.getArgument(0);
            assertNotEquals(PASSWORD, saved.getPasswordHash());
            assertTrue(encoder.matches(PASSWORD, saved.getPasswordHash()));
            saved.setId(UUID.randomUUID());
            return saved;
        });
        mvc.perform(post("/api/users/register").contentType("application/json")
                        .content("{\"email\":\"new@example.test\",\"password\":\"" + PASSWORD + "\"}"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.token").isString())
                .andExpect(jsonPath("$.email").value("new@example.test"))
                .andExpect(jsonPath("$.password").doesNotExist());
        verify(users).save(any(User.class));
    }

    @Test
    void duplicateAndInvalidRegistrationsDoNotBecomeServerErrors() throws Exception {
        mvc.perform(post("/api/users/register").contentType("application/json")
                        .content("{\"email\":\"" + EMAIL + "\",\"password\":\"" + PASSWORD + "\"}"))
                .andExpect(status().isConflict());
        mvc.perform(post("/api/users/register").contentType("application/json")
                        .content("{\"email\":\"invalid\",\"password\":\"\"}"))
                .andExpect(status().isBadRequest());
        verify(users, never()).save(any());
    }

    @Test
    void invalidExpiredUnsignedAndUnknownUserTokensReturn401() throws Exception {
        String expired = Jwts.builder().setSubject(EMAIL).setExpiration(new Date(1))
                .signWith(KEY).compact();
        String noExpiry = Jwts.builder().setSubject(EMAIL).signWith(KEY).compact();
        String wrongKey = Jwts.builder().setSubject(EMAIL).setExpiration(new Date(System.currentTimeMillis() + 60000))
                .signWith(Keys.secretKeyFor(SignatureAlgorithm.HS256)).compact();
        String unknown = jwt.generateToken(User.builder().email("unknown@example.test").build());
        for (String token : List.of("broken", "", "a.b.c", expired, noExpiry, wrongKey, unknown)) {
            mvc.perform(get("/api/families/" + FAMILY + "/members").header("Authorization", "Bearer " + token))
                    .andExpect(status().isUnauthorized()).andExpect(jsonPath("$.error").isString());
        }
    }

    @Test
    void familyHealthAndTasksRequireAuthenticationAndMembership() throws Exception {
        for (UUID familyId : List.of(FAMILY, OTHER_FAMILY)) {
            for (String route : List.of("/api/families/" + familyId + "/profiles",
                    "/api/families/" + familyId + "/members",
                    "/api/families/" + familyId + "/members/logged",
                    "/api/health/medicines/" + familyId + "/" + PERSON,
                    "/api/health/appointments/" + familyId + "/" + PERSON,
                    "/api/health/records/" + familyId + "/" + PERSON,
                    "/api/health/documents/" + familyId + "/" + PERSON,
                    "/api/health/womens-health/cycles/" + familyId + "/" + PERSON,
                    "/api/tasks/family/" + familyId)) {
                mvc.perform(get(route)).andExpect(status().isUnauthorized());
                mvc.perform(get(route).header("Authorization", bearer))
                        .andExpect(status().is(familyId.equals(FAMILY) ? 200 : 403));
            }
        }
    }

    @Test
    void userLookupOnlyExposesOwnIdAndEmail() throws Exception {
        mvc.perform(get("/api/users/by-email").param("email", EMAIL).header("Authorization", bearer))
                .andExpect(status().isOk()).andExpect(jsonPath("$.id").value(user.getId().toString()))
                .andExpect(jsonPath("$.passwordHash").doesNotExist()).andExpect(jsonPath("$.password").doesNotExist())
                .andExpect(jsonPath("$.authorities").doesNotExist());
        mvc.perform(get("/api/users/by-email").param("email", "other@example.test").header("Authorization", bearer))
                .andExpect(status().isForbidden());
        mvc.perform(get("/api/tasks/family/" + FAMILY).header("Authorization", bearer))
                .andExpect(status().isOk()).andExpect(jsonPath("$[0].createdBy.user.passwordHash").doesNotExist())
                .andExpect(jsonPath("$[0].createdBy.user.password").doesNotExist())
                .andExpect(jsonPath("$[0].createdBy.user.authorities").doesNotExist());
    }

    @Test
    void familyCreationAndJoiningCannotImpersonateAnotherUser() throws Exception {
        User other = User.builder().id(UUID.randomUUID()).email("other@example.test").build();
        when(users.findById(other.getId())).thenReturn(Optional.of(other));
        when(familyService.findByInviteCode("test-invite")).thenReturn(family);
        mvc.perform(post("/api/families").header("Authorization", bearer).contentType("application/json")
                        .content("{\"creatorId\":\"" + other.getId() + "\",\"familyName\":\"Test\"}"))
                .andExpect(status().isForbidden());
        mvc.perform(post("/api/families/join-by-code").header("Authorization", bearer).contentType("application/json")
                        .content("{\"userId\":\"" + other.getId() + "\",\"inviteCode\":\"test-invite\"}"))
                .andExpect(status().isForbidden());
        mvc.perform(post("/api/families/" + OTHER_FAMILY + "/profiles/" + PERSON + "/link-self")
                        .header("Authorization", bearer)).andExpect(status().isForbidden());
        verify(familyService, never()).createFamilyWithProfiles(any(), any(), any(), any(), any(), any(), any());
    }

    @Test
    void healthProfileReadAndWriteCheckMembershipBeforePersistence() throws Exception {
        for (String method : List.of("GET", "PUT")) {
            var request = method.equals("GET") ? get("/api/health/profile/" + OTHER_FAMILY + "/" + PERSON)
                    : put("/api/health/profile/" + OTHER_FAMILY + "/" + PERSON).contentType("application/json").content("{}");
            mvc.perform(request.header("Authorization", bearer)).andExpect(status().isForbidden());
        }
        verifyNoInteractions(healthProfiles);
    }

    @Test
    void invitationPreviewRequiresJwtAndCodeWithoutOpeningTheNormalRoster() throws Exception {
        FamilyProfile available = new FamilyProfile(); available.setId(PERSON); available.setFamily(family);
        available.setName("Sam"); available.setRole("Mother");
        FamilyProfile claimed = new FamilyProfile(); claimed.setId(UUID.randomUUID()); claimed.setFamily(family);
        claimed.setName("Alex"); claimed.setRole("Father"); claimed.setLinkedUserEmail("other@example.test");
        when(profiles.findByFamilyId(FAMILY)).thenReturn(List.of(available, claimed));
        when(familyService.findByInviteCode("test-invite")).thenReturn(family);
        when(members.existsByFamilyIdAndUserEmail(FAMILY, EMAIL)).thenReturn(false);
        mvc.perform(post("/api/families/invitations/preview").contentType("application/json")
                .content("{\"inviteCode\":\"test-invite\"}")).andExpect(status().isUnauthorized());
        mvc.perform(post("/api/families/invitations/preview").header("Authorization", bearer)
                        .contentType("application/json").content("{\"inviteCode\":\"test-invite\"}"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.profiles.length()").value(1))
                .andExpect(jsonPath("$.profiles[0].id").value(PERSON.toString()))
                .andExpect(jsonPath("$.profiles[0].profileId").value(PERSON.toString()))
                .andExpect(jsonPath("$.profiles[0].linkedUserEmail").doesNotExist());
        mvc.perform(get("/api/families/" + FAMILY + "/profiles").header("Authorization", bearer))
                .andExpect(status().isForbidden());
    }

    @Test
    void joiningUsesAuthenticatedAccountAndReturnsSeparateProfileAndMembershipIds() throws Exception {
        FamilyProfile profile = new FamilyProfile(); profile.setId(PERSON); profile.setFamily(family);
        profile.setName("Sam"); profile.setRole("Mother"); profile.setLinkedUserEmail(EMAIL);
        when(profiles.findByFamilyId(FAMILY)).thenReturn(List.of(profile));
        when(familyService.findByInviteCode("test-invite")).thenReturn(family);
        when(familyService.joinFamily(FAMILY, user, null, "MEMBER", PERSON)).thenReturn(member);
        mvc.perform(post("/api/families/join-by-code").header("Authorization", bearer)
                        .contentType("application/json").content("{\"inviteCode\":\"test-invite\",\"profileId\":\"" + PERSON + "\"}"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.profileId").value(PERSON.toString()))
                .andExpect(jsonPath("$.membershipId").value(member.getId().toString()));
        verify(familyService).joinFamily(FAMILY, user, null, "MEMBER", PERSON);
        mvc.perform(get("/api/families/" + FAMILY + "/members").header("Authorization", bearer))
                .andExpect(status().isOk()).andExpect(jsonPath("$[0].id").value(member.getId().toString()))
                .andExpect(jsonPath("$[0].membershipId").value(member.getId().toString()))
                .andExpect(jsonPath("$[0].profileId").value(PERSON.toString()))
                .andExpect(jsonPath("$[0].role").value("Mother"))
                .andExpect(jsonPath("$[0].systemRole").value("MEMBER"));
    }

    @Test
    void healthRecordIdRoutesAuthorizeStoredFamilyBeforeUpdateOrDelete() throws Exception {
        Medicine med = new Medicine(); med.setId(1L); med.setFamilyId(OTHER_FAMILY.toString());
        HealthAppointment app = new HealthAppointment(); app.setId(1L); app.setFamilyId(OTHER_FAMILY.toString());
        HealthRecord rec = new HealthRecord(); rec.setId(1L); rec.setFamilyId(OTHER_FAMILY.toString());
        HealthDocument doc = new HealthDocument(); doc.setId(1L); doc.setFamilyId(OTHER_FAMILY.toString());
        MenstrualCycle cycle = new MenstrualCycle(); cycle.setId(1L); cycle.setFamilyId(OTHER_FAMILY.toString());
        when(medicines.findById(1L)).thenReturn(Optional.of(med));
        when(appointments.findById(1L)).thenReturn(Optional.of(app));
        when(records.findById(1L)).thenReturn(Optional.of(rec));
        when(documents.findById(1L)).thenReturn(Optional.of(doc));
        when(cycles.findById(1L)).thenReturn(Optional.of(cycle));
        for (String kind : List.of("medicines", "appointments", "records", "documents")) {
            mvc.perform(delete("/api/health/" + kind + "/1").header("Authorization", bearer))
                    .andExpect(status().isForbidden());
            if (!kind.equals("documents")) mvc.perform(put("/api/health/" + kind + "/1")
                            .header("Authorization", bearer).contentType("application/json").content("{}"))
                    .andExpect(status().isForbidden());
        }
        mvc.perform(put("/api/health/womens-health/cycles/1/end").param("endDate", "2026-10-30")
                        .header("Authorization", bearer)).andExpect(status().isForbidden());
        verify(medicines, never()).deleteById(any()); verify(medicines, never()).save(any());
        verify(appointments, never()).deleteById(any()); verify(records, never()).deleteById(any());
        verify(documents, never()).deleteById(any()); verify(cycles, never()).save(any());
    }

    @Test
    void healthBodiesCannotSpoofOwnershipOfReferencedResources() throws Exception {
        Medicine med = new Medicine(); med.setId(1L); med.setFamilyId(OTHER_FAMILY.toString());
        MenstrualCycle cycle = new MenstrualCycle(); cycle.setId(1L); cycle.setFamilyId(OTHER_FAMILY.toString());
        when(medicines.findById(1L)).thenReturn(Optional.of(med));
        when(cycles.findById(1L)).thenReturn(Optional.of(cycle));
        mvc.perform(post("/api/health/medicines/logs").header("Authorization", bearer).contentType("application/json")
                        .content("{\"familyId\":\"" + FAMILY + "\",\"familyMemberId\":\"" + PERSON + "\",\"medicineId\":1}"))
                .andExpect(status().isForbidden());
        mvc.perform(post("/api/health/womens-health/entries").header("Authorization", bearer).contentType("application/json")
                        .content("{\"familyId\":\"" + FAMILY + "\",\"familyMemberId\":\"" + PERSON + "\",\"cycleId\":1}"))
                .andExpect(status().isForbidden());
        verifyNoInteractions(logs, entries);
    }

    @Test
    void taskMutationsCannotCrossFamilyBoundaryOrSpoofCreator() throws Exception {
        family.setId(OTHER_FAMILY);
        mvc.perform(delete("/api/tasks/" + TASK).header("Authorization", bearer)).andExpect(status().isForbidden());
        mvc.perform(put("/api/tasks/" + TASK).header("Authorization", bearer)
                .contentType("application/json").content("{\"title\":\"Task\",\"originModule\":\"OTHER\"}")).andExpect(status().isForbidden());
        mvc.perform(put("/api/tasks/" + TASK + "/complete").header("Authorization", bearer))
                .andExpect(status().isForbidden());
        family.setId(FAMILY);
        mvc.perform(post("/api/tasks").header("Authorization", bearer).contentType("application/json")
                        .content("{\"title\":\"Task\",\"originModule\":\"OTHER\",\"familyId\":\"" + FAMILY + "\",\"creatorMemberId\":\"" + UUID.randomUUID() + "\"}"))
                .andExpect(status().isForbidden());
        Family foreign = Family.builder().id(OTHER_FAMILY).build();
        FamilyMember outsider = FamilyMember.builder().id(UUID.randomUUID()).family(foreign).build();
        when(members.findById(outsider.getId())).thenReturn(Optional.of(outsider));
        mvc.perform(put("/api/tasks/" + TASK).header("Authorization", bearer).contentType("application/json")
                        .content("{\"title\":\"Task\",\"originModule\":\"OTHER\",\"assignedToMemberId\":\"" + outsider.getId() + "\"}"))
                .andExpect(status().isForbidden());
        verify(tasks, never()).deleteTask(any());
        verify(tasks, never()).completeTask(any(), any());
    }

    @TestConfiguration
    @EnableWebMvc
    @Import({SecurityConfig.class, ApplicationConfig.class, JwtAuthenticationFilter.class,
            UserController.class, FamilyController.class, HealthController.class, GlobalTaskController.class,
            ApiExceptionHandler.class, UserService.class, FamilyAccessService.class, FamilyRosterService.class, HealthAccessService.class})
    static class Config {
        @Bean JwtService jwtService() { return new JwtService(Base64.getEncoder().encodeToString(KEY.getEncoded())); }
        @Bean UserRepository users() { return mock(UserRepository.class); }
        @Bean FamilyMemberRepository members() { return mock(FamilyMemberRepository.class); }
        @Bean FamilyProfileRepository profiles() { return mock(FamilyProfileRepository.class); }
        @Bean FamilyRepository families() { return mock(FamilyRepository.class); }
        @Bean FamilyService familyService() { return mock(FamilyService.class); }
        @Bean GlobalTaskService tasks() { return mock(GlobalTaskService.class); }
        @Bean HealthProfileRepository healthProfiles() { return mock(HealthProfileRepository.class); }
        @Bean MedicineRepository medicines() { return mock(MedicineRepository.class); }
        @Bean MedicineScheduleRepository schedules() { return mock(MedicineScheduleRepository.class); }
        @Bean MedicineLogRepository logs() { return mock(MedicineLogRepository.class); }
        @Bean HealthAppointmentRepository appointments() { return mock(HealthAppointmentRepository.class); }
        @Bean HealthRecordRepository records() { return mock(HealthRecordRepository.class); }
        @Bean HealthDocumentStorage documentStorage() { return mock(HealthDocumentStorage.class); }
        @Bean HealthDocumentRepository documents() { return mock(HealthDocumentRepository.class); }
        @Bean MenstrualCycleRepository cycles() { return mock(MenstrualCycleRepository.class); }
        @Bean MenstrualEntryRepository entries() { return mock(MenstrualEntryRepository.class); }
    }
}
