# Phase 2 — Step 3: Health & Medicine

Completed on 2026-10-30. Dashboard, Tasks, and unrelated feature work were not started.

## Findings and fixes

The source audit found an inconsistent identity path: More loaded `/families/{id}/members` before opening Health, while Health accepted that membership roster as a fallback and could fall back again to names or relationships as identifiers. Health requests also swallowed non-authentication failures and returned empty maps/lists. These defects obscured failures and could associate requests with the wrong kind of identifier. The old production incident cannot be reproduced with its original records because the development database was already reset; these are verified source defects, not a claim that the historical runtime incident was reproduced.

Health now obtains its entire roster exclusively from `/families/{familyId}/profiles`. Responses must contain valid, unique FamilyProfile UUIDs. Registered and unregistered people use the same API path and identity model. More opens Health directly. Health rejects malformed identifiers before sending requests, verifies response family/profile scopes, and ignores late responses for previously selected people or families. Initial loading, a genuinely empty household, and errors have separate states. Failed API requests propagate errors and retain a retry action rather than returning fabricated empty results.

Every Health route checks authenticated family membership and that the profile belongs to that family. Record-ID mutations authorize the stored record's family and profile. Medicine logs and menstrual entries also check the ownership of the referenced medicine/cycle. Companion profile references are validated. Existing JWT handling supplies Bearer tokens for JSON, multipart, and binary requests; 401 invalidates the session, while 403 preserves it and reports denied access. Login and registration security configuration was not changed.

GET health profile returns an unsaved, scoped default when no profile exists; it no longer inserts on read. Saving uses the existing unique family/profile constraint and a profile row lock, preventing duplicate first saves. Updates preserve fields not exposed by a particular form. Blank birth dates become null. Insurance expiry and emergency contact fields can be edited. Appointment time and status can be selected, and edits preserve notes, follow-up, and companion references. Editing medical records preserves their original date and doctor details.

Medicines retain brand/date fields during updates. Quantities and dates are validated. Dose logging and stock changes are transactional and serialized per household profile. Repeating the same medicine/scheduled-at/status returns the existing log without consuming stock twice; conflicting statuses return 409. The recorder is derived from the authenticated account's linked profile, rather than the selected patient. Skipped/missed logs do not set a taken timestamp. Removing a medicine archives it and disables its schedules, preserving medication history. The screen now displays medication history and supports persisted schedule times through the medicine's Schedules menu. These schedules do not introduce background device notifications.

Women's Health uses real saved cycle IDs, validates cycle ordering and end dates, calculates completed period/cycle lengths, and updates an existing entry for the same profile/date. Opening a logged day retains its recorded symptoms, flow, notes, and mood. No cycle ID or patient is fabricated. Existing gender/relationship hints remain presentation hints; names no longer determine eligibility. Authorization is household membership; the existing sharing preference fields are not a separate per-account consent system.

## Medical documents

The original backend supported metadata only. This step extends the existing local filesystem approach without a new storage service or database columns:

- `POST /api/health/documents/{familyId}/{profileId}/upload`: multipart `file`, `title`, and optional `category`.
- `GET /api/health/documents/{documentId}/file`: authenticated attachment download after stored ownership checks.
- Existing list and delete routes remain available. Deletion removes the managed file only after the metadata transaction commits.
- PDF, PNG, and JPEG content signatures are checked, files must be nonempty and at most 10 MB, and original filenames are sanitized. Multipart limits are 10 MB per file and 11 MB per request.
- Managed files live under `uploads/health/{familyUuid}/{profileUuid}/{documentId}.blob`, relative to the backend working directory. `homesweethome.uploads.health` can override the root. Downloads use `Cache-Control: no-store`, attachment disposition, and `nosniff`.
- Database rollback removes a newly written file. A filesystem removal failure after commit emits a generic warning; it can leave an orphan file requiring operator cleanup. No unrelated uploads are removed.
- Existing metadata-only entries remain readable as metadata; missing physical files return a clear 404. No legacy records or URLs are automatically rewritten.
- Flutter uses the cached `file_picker` package for selection and saving. macOS user-selected file access is declared. Native dialogs and permissions still require device/platform testing.

The database and `uploads/health` directory must both be preserved for document recovery. No existing uploaded files were moved or deleted.

## Files changed in Step 3

| File | Purpose |
| --- | --- |
| `backend/src/main/java/com/homesweethome/controller/HealthController.java` | Profile authorization across all Health routes; transactional saves, validation, medicine/log/schedule integration, appointment/record field preservation, cycles/entries, and document endpoints. |
| `backend/src/main/java/com/homesweethome/service/HealthAccessService.java` | Canonical UUID checks, family/profile ownership, per-profile write locking, authenticated recorder identity. |
| `backend/src/main/java/com/homesweethome/service/HealthDocumentStorage.java` | Bounded local file storage, content validation, rollback cleanup, download, and deletion after commit. |
| `backend/src/main/java/com/homesweethome/repository/FamilyProfileRepository.java` | A Health-specific pessimistic lock query; existing Family behavior preserved. |
| `backend/src/main/java/com/homesweethome/repository/MedicineLogRepository.java` | Find an existing medicine/scheduled-at log for retry handling. |
| `backend/src/main/java/com/homesweethome/repository/MenstrualEntryRepository.java` | Find an existing profile/date entry for updates. |
| `backend/src/main/resources/application.properties` | Multipart size limits only in this step; JWT secret configuration and database credentials unchanged. |
| `backend/src/test/java/com/homesweethome/AuthenticationIntegrationTest.java` | Adapt existing authorization regression fixtures to the Health profile ownership service and storage/schedule dependencies. |
| `backend/src/test/java/com/homesweethome/HealthIntegrationTest.java` | Real MVC/security/JPA tests against isolated H2 and a temporary upload directory. |
| `backend/src/test/java/com/homesweethome/HealthRestartPersistenceTest.java` | Save data, close the full application context, reopen the same temporary file database with schema validation, and verify saved data. |
| `mobile/lib/core/services/health_http.dart` | Shared checked JWT transport, multipart/binary support, UUID request validation, injectable client. |
| `mobile/lib/core/services/health_api.dart` | Shared response shape and profile-scope validation; checked transport for existing API methods. |
| `mobile/lib/features/health/screens/health_screen.dart` | Profiles-only loading, selection race handling, error states, connected Health forms, logs/schedules, cycle tracking, upload/download/delete. Existing styling retained. |
| `mobile/lib/features/more/screens/more_screen.dart` | Remove the membership-roster navigation gate for Health. |
| `mobile/pubspec.yaml`, `mobile/pubspec.lock` | File picker dependency and resolved packages. |
| `mobile/macos/Flutter/GeneratedPluginRegistrant.swift` | Generated file-picker plugin registration; prior registrations retained. |
| `mobile/macos/Runner/DebugProfile.entitlements`, `Release.entitlements` | User-selected read/write file access for medical documents. |
| `mobile/test/health_integration_test.dart` | HTTP failures, malformed IDs/responses, JWT/session behavior, multipart/download compatibility, roster errors, and member-switch race regression tests. |
| `docs/health-medicine-step-3.md` | This report and manual verification checklist. |

Existing changes from Steps 1 and 2 remain in the working tree. They are not new Step 3 changes. No entities, PostgreSQL migrations, Dashboard, or Tasks implementation were changed in this step.

## Verification results

| Check | Result |
| --- | --- |
| Fresh Maven `clean test` | Passed. Recompiled 84 main and 5 test source files using Java release 17. |
| Backend tests | 31 passed; zero failures/errors/skips: authentication 13, existing application context 1, Family persistence 9, Health integration 7, restart persistence 1. |
| Flutter tests | 24 passed, including existing authentication/Family regressions and 7 new Health tests. |
| `flutter analyze` | No errors or warnings. Exit 1 because of four existing informational notices in `add_family_members_screen.dart`: one unnecessary import and three deprecated API usages. No Health diagnostics. Unrelated onboarding code was left unchanged. |
| Family/profile isolation | Verified with registered and unregistered profiles, another real household profile in the test database, mismatched medicine/cycle ownership, and separate response scopes. |
| Authorization | Verified real JWT authentication, anonymous 401, outsider 403, wrong-family profile 404, and malformed profile 400; file download authorization included. |
| Document lifecycle | Upload, byte-for-byte retrieval, ownership checks, rejection of invalid content with database rollback, and metadata/file deletion verified in temporary storage. |
| Restart persistence | Verified against a temporary file-backed H2 database after full application context shutdown/restart. |
| PostgreSQL compatibility | Existing Spring Boot context test passed against `homesweethome` on port 5433 with Hibernate `validate`; no schema updates enabled for verification. |
| PostgreSQL preservation | Read-only snapshot comparison: 27 tables, zero records, identical schema/object metadata and sequence state. No legacy Health identifiers existed to migrate. No reset, migration, or test-record insertion was performed. |
| Secrets/uploads | Windows user JWT_SECRET fingerprint and existing upload count/content hashes match the completed-reset baseline; values were not printed. |

Protected local artifacts: `.local-backups/health-step3-backend-final.log` and `.local-backups/health-step3-verification.jsonl`. Flutter test output is in ignored `mobile/build/health-step3-tests.log`.

## Restart and manual checks

1. Stop the old backend with Ctrl+C. Open PowerShell in `G:\Projects\home_sweet_home\backend`. Load the existing user secret without printing it:

   ```powershell
   $env:JWT_SECRET = [Environment]::GetEnvironmentVariable('JWT_SECRET', 'User')
   ```

   Start with your Maven command, preserving schema validation:

   ```powershell
   mvn spring-boot:run '-Dspring-boot.run.arguments=--spring.jpa.hibernate.ddl-auto=validate'
   ```

   If Maven is not on PATH, use the installed Maven 3.9.16 executable already used for verification rather than the currently broken wrapper. Keep PostgreSQL configured on port 5433.

2. In another terminal, open `G:\Projects\home_sweet_home\mobile`, run `flutter pub get`, then restart with `flutter run -d chrome` (or the desired supported device). A full restart loads the new file-picker plugin. The configured API remains localhost:8080; physical devices require the existing device-appropriate API host configuration.
3. Sign out of any stale pre-reset session. Create a new account and family through the normal UI, with at least one additional unregistered profile. Verify that both appear in Family and Health. Invite/join a second registered account by selecting an existing profile and verify no duplicate person appears.
4. Save different allergies, blood types, insurance/emergency details, medicines, appointments, and records for two profiles. Switch repeatedly, including during slow requests. Edit existing entries and confirm untouched fields/dates remain. Confirm empty profiles show empty states rather than another person's data.
5. Add a medicine, open its Schedules menu, add/remove a time, and use Take Dose. Verify stock decreases once and history appears for the selected patient only. Remove the medicine and confirm its history remains.
6. Enable Women's Health where applicable, start a period, record symptoms on that or a later day, reopen and update that day, and end the period. Confirm dates, history, and profile selection remain correct. Predictions are the existing estimates; no medical validation of predictions is claimed.
7. Upload a PDF or image, download it, and compare the contents. Switch profile and confirm it is absent there. Delete the document and confirm it disappears. Test cancellation, a file over 10 MB, and an unsupported file. Exercise native save/open dialogs on each target platform.
8. Restart both applications and confirm all newly saved data and documents remain. This live PostgreSQL/browser/native-platform persistence check was deliberately not performed automatically, so the empty development database stays untouched.
9. With a separate account in another family, confirm the first family's Health URLs and record/file IDs are denied. Verify a rejected/expired JWT returns to login, and a temporary API failure shows an actionable error and retry.

Live browser-to-PostgreSQL CRUD, platform file dialogs, and physical-device network configuration remain manual checks. Automated persistence and authorization results above apply to the isolated test databases, except the explicitly noted read-only PostgreSQL schema/preservation verification.
