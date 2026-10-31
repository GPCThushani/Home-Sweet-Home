# Authentication and JWT integration — Step 1

This change secures existing APIs and updates their Flutter callers. It does not change the database schema, household-person identifiers, screen layouts, dashboard behavior, or Health features.

## Required startup configuration

`JWT_SECRET` has now been generated and saved in the current Windows user's environment. It contains 32 random bytes encoded as Base64. It was not printed or written to the repository. Do not regenerate it during normal restarts. Existing terminals and VS Code processes may not inherit a newly saved user variable; load it explicitly using the restart instructions below.

Set `JWT_SECRET` in the environment used to launch Spring Boot. It must be a Base64-encoded cryptographically random key containing at least 32 decoded bytes. The backend deliberately fails startup when the key is missing or too short. Never commit or log the key.

To create a key in a PowerShell session without printing it:

```powershell
$jwtBytes = New-Object byte[] 32
$jwtRandom = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$jwtRandom.GetBytes($jwtBytes)
$jwtRandom.Dispose()
$env:JWT_SECRET = [Convert]::ToBase64String($jwtBytes)
```

Generate once, store it securely outside the repository, and supply the same value to future backend processes. Generating a new key at each startup invalidates existing sessions. Changing the old source-controlled key requires users to log in again; it does not change their accounts or passwords. VS Code must launch the backend with this environment variable too.

## API behavior

- `POST /api/users/register` and `POST /api/users/login` remain public. A stale Authorization header cannot block these recovery endpoints.
- Missing, malformed, expired, incorrectly signed, unknown-user, and expiration-free JWTs receive `401` on protected APIs. Errors do not contain tokens, passwords, or parser details.
- Valid authentication with insufficient family access receives `403`.
- Family creation and invitation acceptance require the submitted user to match the authenticated user. Family member lists and profile linking require membership.
- Both joining endpoints require a valid invitation. `/api/families/{familyId}/join` now requires `inviteCode` in its JSON body; Flutter already uses `/join-by-code`.
- Every Health controller action checks family membership. Record-ID actions authorize the stored family. Medicine logs and menstrual entries also validate the ownership of the referenced medicine/cycle before writing.
- Task reads and mutations require membership. Task creation uses the current member, and assignment cannot cross family boundaries.
- `/api/users/by-email` returns only the current user's `id` and `email`. Nested user objects expose only these fields. Login/registration intentionally return the session JWT to the authenticating client.
- Duplicate registration returns `409`; invalid request fields return `400`; incorrect credentials return `401`.

## Flutter behavior

All HTTP callers use `authenticated_http.dart`. It attaches the stored token to protected requests to the configured API origin, strips stale Authorization headers from login/registration, and handles multipart uploads too. It does not attach the stored token to another origin or follow protected redirects.

Login and registration validate the returned session before storing it. Local validation checks JWT structure, subject, and expiry; the backend verifies signatures. On `401` or local expiry, credentials are cleared and the app returns to the existing login screen. A `403` keeps the session. A failed older request cannot clear a newer login. Existing Health fallback code now propagates authentication/authorization failures instead of treating them as empty health data.

## Files changed in this step

Paths below are relative to the repository root. Some files already contained uncommitted changes before this step; those changes were preserved.

Backend (`backend/src/main/java/com/homesweethome/`):

- `config/SecurityConfig.java`, `config/JwtAuthenticationFilter.java`: protected routes, public recovery routes, safe authentication failures.
- `service/JwtService.java`: externally configured signing key and mandatory token expiry.
- `service/FamilyAccessService.java` (new): shared current-user and family-membership checks.
- `controller/ApiExceptionHandler.java` (new): sanitized authentication, authorization, and validation responses.
- `controller/UserController.java`, `service/UserService.java`: self-only safe lookup, credential validation, duplicate-registration status.
- `controller/FamilyController.java`, `dto/JoinFamilyRequest.java`: actor checks, membership checks, invitation verification.
- `controller/HealthController.java`, `controller/GlobalTaskController.java`: authorization before reads and writes, including ID-only operations and referenced resources.
- `entity/User.java`: response serialization allowlist; no persistence fields changed.
- `dto/AuthenticationResponse.java`, `dto/UserRegistrationRequest.java`: redacted diagnostic strings and credential validation.

Other backend files:

- `backend/src/main/resources/application.properties`: signing-key environment configuration; disable detailed error responses and authentication debug logging.
- `backend/src/test/java/com/homesweethome/AuthenticationIntegrationTest.java` (new): real MVC/security/JWT/BCrypt tests with mocked repositories.

Flutter:

- `mobile/lib/core/services/auth_session.dart` and `authenticated_http.dart` (new): session validation, persistence, Bearer headers, expiry handling.
- `mobile/lib/main.dart`: route expired sessions to the existing login screen.
- `mobile/lib/features/onboarding/screens/login_screen.dart`, `sign_up_screen.dart`: store only validated backend sessions; remove fabricated token fallback.
- `mobile/lib/features/health/screens/health_screen.dart`: use authenticated requests and propagate access failures.
- `mobile/lib/features/together/screens/together_screen.dart`: use the authenticated client for ordinary requests and multipart uploads.
- The Home, Choose Family, and Join Family screens use the authenticated client and check `mounted` before handling late responses, so redirecting an expired session cannot update a disposed screen.
- HTTP import changes only in `mobile/lib/core/services/health_api.dart`; `mobile/lib/features/family/services/family_service.dart`; `mobile/lib/features/documents/screens/documents_screen.dart`; and the existing Garden, Maintenance, More, Shopping, Tasks, and Home Ready screen files.
- `mobile/test/authenticated_http_test.dart` (new): client/session regression tests.

## Verification and manual checks

Verification results: all 82 backend sources compiled from a cleared generated build directory. All 12 backend tests passed (11 authentication integration tests and the existing application-context test), using schema validation. The context test connected to the configured PostgreSQL database without schema updates. Nine Flutter authentication tests and the existing widget smoke test passed. Flutter analysis reports the same pre-existing unused-import warning and four informational findings as Phase 1, with no analyzer errors. Browser/device end-to-end login and persistence across restarts still require manual verification.

The backend authentication integration tests use real Spring MVC, the actual security chain, JWT signing/parsing, and BCrypt, with mocked repositories. They do not verify PostgreSQL persistence. The existing context test should be run with `spring.jpa.hibernate.ddl-auto=validate` so verification cannot change the live schema.

Commands, from the corresponding project directory:

```text
mvn clean compile
mvn test -Dtest=AuthenticationIntegrationTest
mvn test -Dspring.jpa.hibernate.ddl-auto=validate -Dspring.jpa.show-sql=false
flutter analyze --no-pub
flutter test --no-pub test/authenticated_http_test.dart test/widget_test.dart
```

The workspace's Windows Maven wrapper has a pre-existing startup error; a cached Maven installation was used directly. Fresh compilation removes only generated `backend/target` output.

Manual checks after supplying a stable `JWT_SECRET`:

1. Log in with an existing account and register a disposable account only if desired. Check that the browser/device stores a real JWT and public requests send no stale token.
2. Open Family, Health, and Tasks while signed in. Confirm Bearer headers in network inspection; do not copy tokens into logs or reports.
3. Clear or expire the token and open a protected screen. Confirm return to login. Try another family's URL with a valid token and confirm `403` without losing the session.
4. Confirm existing account data remains available after restarting the backend with the same key.

Known issues from Phase 1 remain outside this step: household-profile linking/ID consistency, dashboard family selection, the Health document-upload placeholder, device base URL configuration, and responsive layout work. Women's Health's existing fallback cycle ID is now subject to ownership checks; a missing or foreign cycle cannot be used to write an entry. No attempt was made to repair that feature flow here.

## Restart using the configured key

1. Stop the running backend and Flutter commands with `Ctrl+C` in their terminals. If VS Code launched the backend, stop that debug session. Leave PostgreSQL running.
2. Open a PowerShell terminal and run:

```powershell
Set-Location 'G:\Projects\home_sweet_home\backend'
$env:JWT_SECRET = [Environment]::GetEnvironmentVariable('JWT_SECRET', 'User')
if ([string]::IsNullOrWhiteSpace($env:JWT_SECRET)) { throw 'JWT_SECRET is missing.' }
$maven = (Get-ChildItem "$env:USERPROFILE\.m2\wrapper\dists" -Filter mvn.cmd -Recurse | Select-Object -First 1).FullName
if (-not $maven) { throw 'Cached Maven installation was not found.' }
& $maven "-Dmaven.repo.local=$env:USERPROFILE\.m2\repository" spring-boot:run '-Dspring-boot.run.arguments=--spring.jpa.hibernate.ddl-auto=validate'
```

The explicit Maven path works around the existing wrapper startup issue. `validate` checks the schema without changing it; normal application reads and saves remain available. Wait for the backend to report that it started on port 8080. If it reports a schema validation failure, stop and record the error rather than resetting the database or changing to `create`/`create-drop`.

3. In a second PowerShell terminal, start Flutter Web:

```powershell
Set-Location 'G:\Projects\home_sweet_home\mobile'
flutter run -d chrome --web-port 7357
```

Use Chrome on this computer for this verification because existing API callers use `localhost:8080`. The emulator/physical-device URL work remains deferred. Flutter must never receive `JWT_SECRET`; only the backend uses it.

## Manual login, family, and Health checks

1. Open Chrome DevTools → Network, then log in with an existing account. Expect `POST /api/users/login` to return `200` and the subsequent family-list request to succeed. Once after changing from the old signing key, an old session may return to login; sign in again. A wrong password should fail without crashing. Do not copy response JWTs or Authorization headers into logs, screenshots, or this document.
2. Select an existing family and open Family. Expect `GET /api/families/{familyId}/profiles` to return `200` with the stored household profiles. Check names, relationships, and UUIDs against the existing household; do not delete/recreate profiles to make the check pass. An empty list or wrong person is an integration issue to record for Step 2, not proof that the data was deleted.
3. Open More → Health & Medicine. Its initial `/members` request and the following `/profiles` request should both succeed. Select a person and check the existing Health profile, medicines, appointments, records, documents, and Women's Health views as applicable. Protected requests should carry Bearer headers. Existing Health identity/fallback and document-upload issues remain deferred, so a blank view alone does not prove that the saved data was loaded correctly.
4. Keep the browser open, restart only the backend using the same command, and refresh/reopen the family and Health views. Check that the session and previously saved records remain available. This is the manual persistence/restart check; automated context tests did not save or modify household data.
5. To check missing-token protection without displaying a token, open `http://localhost:8080/api/families/user?email=<your-email>` directly in a separate browser tab. Browser navigation sends no Bearer header, so expect `401`. Use the signed-in app for normal access. Automated tests also cover malformed/expired tokens and `403` for another family's resources.

## Configuration verification results

- All 12 backend tests passed again using the saved user environment variable. The application-context test connected to PostgreSQL with schema validation only.
- All 10 Flutter tests passed again; analysis still reports the original one warning and four informational findings, with no analyzer errors.
- The configured key was absent from 185 scanned workspace text files, including source/configuration and available test logs. The signing configuration contains an environment placeholder only.
- The database URL, username, password, and driver settings match `HEAD`; password and signing-key values were not printed during this review.
- The broader Git working tree already contained unrelated edits before Step 1. They were preserved. This configuration follow-up changed only the Windows user environment and this document, plus generated test/build outputs.
- Full browser/device behavior, profile identity correctness, and saved data across restarts remain manual checks. Step 2 has not started.
