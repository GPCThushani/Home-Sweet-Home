# Phase 2 — Step 4: Dashboard, Tasks, and remaining integration

Completed 2026-10-30. Authentication, Family Profile, and Health improvements remain intact. No database reset, record insertion/deletion, migration, entity change, or new unrelated feature was performed against PostgreSQL.

## Dashboard and selected-family state

- `MainNavigationShell` passes the selected family UUID into Dashboard. Dashboard matches that exact ID in the authenticated user's families response; it never chooses `families[0]` or silently substitutes another household.
- Dashboard loads `/api/families/user?email=...` with encoded query parameters and `/api/families/{selectedFamilyId}/profiles`. The member count reflects all household profiles, including unregistered people, rather than a fallback value or a count of registered memberships.
- Missing invitation codes display **Invite code unavailable** and disable copying. No demo invitation code is substituted. Missing families, malformed responses, and HTTP failures produce an error with Retry.
- Loading another family clears previous details. Request generations prevent late responses from overwriting the newly selected family's data.
- Family selection saves `current_family_id`, and all routes continue passing the selected ID explicitly. Errors while choosing a family remain errors rather than becoming a false empty-family success state.
- Feature bottom navigation returns to the requested Home, Family, Calendar, Tasks, or More tab with the same family UUID. Embedded Tasks uses the shell's bottom navigation instead of displaying a second bar. Existing Dashboard shortcuts now open the existing Tasks, Family, Shopping, or More destinations.
- Existing colors, imagery, cards, labels, and tab layout are retained. Long family names truncate in the existing header.

## Tasks

The assignment contract remains **FamilyMember membership UUIDs**. Tasks does not substitute FamilyProfile UUIDs, names, or relationships for membership IDs. Unregistered household profiles have no account membership and therefore are not task assignees under the existing schema; no artificial memberships were created.

- A shared `TaskApi` loads `/families/{familyId}/members` and `/tasks/family/{familyId}` and performs create, edit, complete, and delete requests. It validates UUIDs, membership response identity, duplicate memberships, and task response family scope.
- Checked HTTP transport preserves the existing JWT client, supplies Bearer tokens, rejects unsuccessful statuses with useful errors, and retains the established 401/403 session behavior. Loading failure cannot appear as an empty successful task list. Errors can be retried; failed mutations show an error.
- Both create entry points use the same existing form implementation through a compatibility export. Repeated save clicks are guarded. Assignees display their actual household profile name or nickname, with **Unassigned** when appropriate; the old hardcoded email/Father/Daughter overrides are removed.
- Editing supports unassignment and clearing the optional due date. Overdue and historical dates can open the date picker without assertion failures. Editing unrelated fields preserves the original due-date instant, including seconds and milliseconds. Custom existing module values remain selectable instead of breaking the category dropdown.
- Task creation derives the creator from the JWT. Assignment must reference a membership in the same family. Reads and all ID-based mutations authorize the task's stored family; malformed input is 400, missing records/members are 404, and forbidden access is 403.
- Required title/category and their existing database field limits are validated before saving. No schema change was needed.
- Task responses preserve the frontend's nested `family.id` and member `id`/`user.email` shape using an explicit response DTO. Responses exclude password hashes, unrelated family metadata/invitation codes, and Hibernate proxy implementation fields.
- Write operations lock the task row and refresh an entity previously loaded for authorization. Concurrent completion cannot overwrite the first completer or timestamp, and edits cannot restore stale completion state. Repeating completion retains its original attribution. Completion timestamps use PostgreSQL-compatible microsecond precision.
- Task creation flushes before producing its response so generated creation timestamps are available immediately. Task persistence is verified through a full application-context restart in a temporary file database.

## API configuration and platform compatibility

All Flutter API callers now derive their addresses from `ApiConfig.baseUrl`:

| Target | Default / configuration |
| --- | --- |
| Flutter Web | `http://localhost:8080/api` for local development |
| Android emulator | `http://10.0.2.2:8080/api` for the standard Android emulator host alias |
| Windows, macOS, Linux, iOS simulator | `http://localhost:8080/api` by default; override when needed |
| Physical device or deployed web app | Supply the reachable API with `--dart-define=API_BASE_URL=...` |

`API_BASE_URL` accepts HTTP(S) addresses ending in `/api`, removes trailing slashes, and rejects malformed URLs, embedded credentials, query parameters, and fragments. Use HTTPS for deployed HTTPS web apps and release mobile builds. A phone's `localhost` refers to the phone, so physical devices require a reachable server hostname/LAN address. The shared authentication client uses the same configuration, keeping token origin checks consistent with every caller.

Android's main manifest now declares Internet permission for every build variant. Debug and profile manifests permit development HTTP; the main/release manifest does not globally enable cleartext traffic. Native emulator/device networking, local firewall access, and platform TLS trust still require manual checks.

Together image loading now obtains same-API protected image bytes through the authenticated client. External photo URLs use an image request without Authorization headers, preventing the previous JWT forwarding to arbitrary external image hosts. No Together feature or storage redesign was introduced.

The welcome screen retains its background, logo, and buttons and allows scrolling when the available height cannot fit the content. Widget tests cover short, landscape, and phone-sized viewports at increased text scaling.

## Files changed in Step 4

Paths below are relative to the project root. Existing working-tree changes from earlier steps are preserved and are not all new Step 4 edits.

| File | Change |
| --- | --- |
| `backend/src/main/java/com/homesweethome/controller/GlobalTaskController.java` | Validated requests, family authorization, safe DTO responses, transaction boundary, and sanitized task errors. |
| `backend/src/main/java/com/homesweethome/dto/CreateTaskRequest.java` | Required family/title/category and field limits. |
| `backend/src/main/java/com/homesweethome/dto/UpdateTaskRequest.java` | Required title/category and field limits. |
| `backend/src/main/java/com/homesweethome/dto/TaskResponse.java` | New explicit response contract using membership IDs. |
| `backend/src/main/java/com/homesweethome/repository/GlobalTaskRepository.java` | Pessimistic task row-lock query. |
| `backend/src/main/java/com/homesweethome/service/GlobalTaskService.java` | Validation, same-family members, stable completion attribution/time, refresh after locking, correct 404s, generated timestamp availability. |
| `backend/src/test/java/com/homesweethome/AuthenticationIntegrationTest.java` | Valid field fixtures so existing forbidden-request tests still exercise authorization after input validation was added. |
| `backend/src/test/java/com/homesweethome/TaskIntegrationTest.java` | New real MVC/JWT/JPA CRUD, assignment, response safety, authorization, invalid input, and concurrent-completion tests. |
| `backend/src/test/java/com/homesweethome/HealthRestartPersistenceTest.java` | Existing isolated restart test also verifies Tasks, preserving its Health assertions. |
| `mobile/lib/core/services/api_config.dart` | Central platform defaults and compile-time API override. |
| `mobile/lib/core/services/api_client.dart` | New checked transport built on the existing JWT client. |
| `mobile/lib/features/home/screens/home_screen.dart` | Selected-family Dashboard, profile count, real invitation data, retry/loading, stale-response guards, working shortcuts, Web-safe local-avatar fallback. |
| `mobile/lib/shared/widgets/main_navigation_shell.dart` | Selected-family propagation, requested-tab routing, and embedded Tasks navigation. |
| `mobile/lib/features/tasks/services/task_api.dart` | New shared scoped Tasks API adapter. |
| `mobile/lib/features/tasks/screens/global_tasks_screen.dart` | Loading/retry, real member labels, guarded CRUD forms, overdue and precise dates, unassignment/date clearing, correct navigation. |
| `mobile/lib/features/tasks/screens/create_task_bottom_sheet.dart` | Compatibility export for the shared create form; removes duplicate behavior. |
| `mobile/lib/features/onboarding/screens/choose_family_screen.dart` | Checked/validated family loading, encoded email, retry, saved selection, Web-safe local-avatar fallback, central API URL. |
| `mobile/lib/features/onboarding/screens/login_screen.dart` | Central API URLs and encoded email query; authentication behavior preserved. |
| `mobile/lib/features/onboarding/screens/sign_up_screen.dart` | Central registration API URL only. |
| `mobile/lib/features/onboarding/screens/home_ready_screen.dart` | Central account lookup/family creation API URLs only. |
| `mobile/lib/features/onboarding/screens/welcome_screen.dart` | Scrollable constrained layout preventing RenderFlex overflow. |
| `mobile/lib/features/health/screens/health_screen.dart` | Compatibility with dynamic API configuration and selected-family tab navigation only; Health behavior preserved. |
| `mobile/lib/features/garden/screens/plants_garden_screen.dart` | Central Garden/Shopping URLs and correct selected-family tab navigation. |
| `mobile/lib/features/maintenance/screens/home_maintenance_screen.dart` | Central URL and selected-family tab navigation. |
| `mobile/lib/features/shopping/screens/shopping_screens.dart` | Central URL and selected-family tab navigation. |
| `mobile/lib/features/together/screens/together_screen.dart` | Central URL/origin, selected-family tab navigation, protected image bytes, no JWT on external images. |
| `mobile/lib/features/documents/screens/documents_screen.dart` | Central API URL only. |
| `mobile/android/app/src/main/AndroidManifest.xml` | Internet permission in the main manifest. |
| `mobile/android/app/src/debug/AndroidManifest.xml` | Local HTTP for development. |
| `mobile/android/app/src/profile/AndroidManifest.xml` | Local HTTP for profile testing. |
| `mobile/test/authenticated_http_test.dart` | Test request addresses use the central configuration. |
| `mobile/test/health_integration_test.dart` | Health regression addresses use the central configuration. |
| `mobile/test/dashboard_tasks_integration_test.dart` | New configuration, Dashboard selection/error/race, Tasks API/navigation/editing, and welcome overflow tests. |
| `docs/dashboard-tasks-step-4.md` | This report and manual verification instructions. |

No application dependencies, PostgreSQL entities/schema, signing secret, or existing uploaded files were changed in this step.

## Verification results

| Verification | Result |
| --- | --- |
| Fresh backend `clean test` | Passed. 85 main and 6 test source files compiled with Java release 17. |
| Backend tests | **37 passed**, zero failures/errors/skips: authentication 13, PostgreSQL application context 1, Family persistence 9, Health integration 7, restart persistence 1, Tasks integration 6. |
| Flutter tests | **38 passed**, including all prior authentication/Family/Health regressions and 14 new Step 4 checks. |
| Custom API host regression | **16 passed** with `API_BASE_URL=https://api.example.test/api`, verifying JWT/public auth, redirects, sessions, scoped Health requests, multipart, downloads, and member switching with an overridden origin. Mock transport only; this is not a real remote server. |
| Flutter Web compilation | `flutter build web --debug --no-pub` passed; output in `mobile/build/web`. The optional Wasm dry-run advisory was not a build failure. |
| Flutter static analysis | No errors or warnings. Exit 1 for four pre-existing informational notices in `add_family_members_screen.dart`: an unnecessary import and three deprecated API usages. No new diagnostics. |
| Android manifest inspection | Main Internet permission present; debug/profile development HTTP enabled; main/release cleartext not globally enabled. Android APK/runtime testing was not performed. |
| Authorization/API contract | Actual JWT/MVC tests verify anonymous 401, outsider 403, missing task/member 404, invalid fields 400, foreign assignments rejected, FamilyProfile IDs rejected as assignee memberships, and nested response compatibility. |
| Task persistence/concurrency | CRUD and membership foreign keys tested through JPA; task rows survive complete application-context shutdown/restart in temporary file-backed H2; simultaneous completions retain the same completer and timestamp. |
| Live PostgreSQL | Application context passed with `spring.jpa.hibernate.ddl-auto=validate`. Read-only before/after snapshots match: 27 tables, zero application rows, identical schema/object metadata and sequence values/state. No live CRUD fixtures inserted. Only `localhost:5433/homesweethome` queried. |
| Preservation | JWT_SECRET fingerprint and uploaded-file inventory/content hashes unchanged. No secret value was printed. |

Protected local artifacts are `.local-backups/step4-backend-final.log`, `step4-before-final-check.jsonl`, `step4-after-final-check.jsonl`, and `step4-preservation-baseline.json`. Flutter outputs are under ignored `mobile/build/step4-tests.log`, `step4-custom-api-tests.log`, and `step4-web-build.log`.

## Restart/configuration and manual verification

1. Stop the old backend with Ctrl+C. In a PowerShell terminal in `G:\Projects\home_sweet_home\backend`, load the existing secret without displaying it and start with schema validation:

   ```powershell
   $env:JWT_SECRET = [Environment]::GetEnvironmentVariable('JWT_SECRET', 'User')
   $maven = 'C:\Users\DELL\.m2\wrapper\dists\apache-maven-3.9.16\0daed3be3ebd1c706f0e69e8b07c6b73f5cc4ea3dfce72a8d0ec2e849ca2ddb0\bin\mvn.cmd'
   & $maven spring-boot:run '-Dspring-boot.run.arguments=--spring.jpa.hibernate.ddl-auto=validate'
   ```

   PostgreSQL remains configured on localhost:5433. No reset commands are needed. The installed Maven executable is used because this environment's existing wrapper command is broken.

2. In `G:\Projects\home_sweet_home\mobile`, restart Flutter with the desired API address. If Flutter is not on PATH, its executable here is `C:\flutter_windows_3.35.7-stable\flutter\bin\flutter.bat`.

   ```text
   Web locally:       flutter run -d chrome
   Android emulator: flutter run -d <emulator-id>
   Physical device:  flutter run -d <device-id> --dart-define=API_BASE_URL=http://<computer-LAN-IP>:8080/api
   Deployed HTTPS:   flutter build web --dart-define=API_BASE_URL=https://<your-api-host>/api
   ```

   Replace angle-bracket placeholders. The device must reach the backend over the network; test LAN/firewall access. Use a full restart/rebuild after changing a dart-define. Release mobile builds should use a reachable HTTPS endpoint rather than development cleartext exceptions.

3. Use normal signup/family creation to populate the empty development database, or sign in if accounts have since been created. With two families, deliberately select the second one. Confirm Dashboard name, real invite code, avatar where available, and total household-profile count belong to that family. Navigate through Family, Tasks, Health, Shopping, Garden, Maintenance, and Together and confirm Home/Tasks/More return to the selected family's correct tab.
4. Create a task unassigned, then assign it to a registered household member, edit its text/category/date/time, remove the assignment, clear the date, complete it, and delete it. Confirm My Tasks, Completed, and member labels are correct. Test editing an overdue task. Restart both applications and confirm saved tasks and completion attribution remain.
5. With an account belonging to another family, verify the first family's task list and mutation URLs are denied. Attempt a cross-family assignee through API inspection and confirm rejection. Do not copy JWTs into reports/logs. Confirm expired sessions route to login and a temporary server failure shows Retry rather than an empty success state.
6. On Web and target devices, test narrow/landscape welcome layouts and increased text size. Verify authenticated Together images load and external image requests contain no Bearer header. Recheck existing Family linking and profile-specific Health data/documents after navigation changes.

Live browser-to-PostgreSQL CRUD and physical/emulator networking were not exercised automatically, so no user/test accounts or records were inserted. They remain manual verification items. The existing Calendar placeholder remains; Settings opens the existing More menu rather than adding a new settings module. Existing custom-avatar local paths are not shared upload storage and may not display across devices; no avatar-storage redesign was included. Four unrelated onboarding analyzer infos remain as listed above.

Stopped after Step 4. No unrelated feature development was started.
