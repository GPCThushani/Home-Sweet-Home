# Family Profile Integration — Step 2

This step integrates household profiles and registered memberships. No Health source files, task models, dashboard behavior, database entities, existing PostgreSQL records, or schema were changed in this step.

## Joining and linking

1. An authenticated user enters an invitation code and chooses **Find Family**.
2. `POST /api/families/invitations/preview` validates the code before returning the family ID/name and available household profiles. It never returns linked account emails. The normal profiles endpoint still requires family membership.
3. The user selects their existing household profile and chooses **Join Family Space**. No profile is created by joining. The account is taken from the verified JWT, not client-supplied identity or permission fields.
4. `POST /api/families/join-by-code` validates the invitation again and atomically creates/reuses the membership and links the selected profile. Repeating the same operation returns the existing membership and profile UUID. A failed claim rolls back a newly created membership.
5. Existing members who lack a profile link can open Family and use the person-add action beside their unregistered profile, then confirm **Link my account**. Already linked profiles cannot be taken over or reassigned through this action.

An invitation preview returns unlinked profiles, or only the requester's own profile when already linked. It does not expose another account's linked profile as a claimable choice. A valid invitation grants this limited preview before membership; it does not open ordinary family APIs to nonmembers.

## Identifier contract

| API / identifier | Meaning |
| --- | --- |
| `/families/{familyId}/profiles`: `id` and `profileId` | The same stable `FamilyProfile` UUID identifying a household person |
| Profile `relationship` / compatible `role` field | Household relationship, such as Father, Mother, or Daughter |
| Profile `hasAccount` | Whether that household profile has an account link |
| Profile `isSelf` | Whether that profile is linked to the requesting account |
| `/families/{familyId}/members`: `id` and `membershipId` | Registered `FamilyMember` membership UUID, retained for existing Task APIs |
| Membership response `profileId` | Linked household person's UUID, or null for an older unlinked membership |
| Membership `systemRole` | Permission role, such as `PARENT` or `MEMBER` |

Household-person callers must use the profiles API; they must not use a membership ID, name, or relationship as a person ID. The new Flutter Family model validates UUIDs and rejects mismatched/duplicate profile identifiers. Tasks retain their existing membership foreign keys. Updating Health's remaining person-ID adapters is deliberately deferred to the Health step.

## Data preservation and duplicate prevention

- No migration or production schema change is required. Existing family, profile, and membership IDs remain unchanged.
- A pessimistic lock on the existing family row serializes joins and profile claims, including concurrent requests. Both linking endpoints and initial roster creation follow this locking rule.
- The existing membership uniqueness constraint remains in place. Existing membership IDs, nicknames, and permission roles are preserved when an older member links a profile. New joining memberships receive `MEMBER` from the server.
- Joining changes account linkage, not household size. It does not add a second household profile or inflate the family's household count.
- Initial family creation still saves every submitted person and links only the selected creator profile. Identical repeated profile inputs are rejected transactionally. Initializing an already populated roster is also rejected.
- All persisted household profiles are returned to authorized members, including unregistered people. Ordinary reads/linking enforce membership; profile claims also validate the selected profile's family.
- Existing ambiguous/duplicate legacy rows are not deleted, merged, or silently reassigned. Accounts without links require an explicit selection. A household with no stored profiles cannot be reconstructed safely from nicknames; it receives an actionable no-available-profile message instead of invented people. Such a legacy roster needs an explicit data-repair decision if encountered.

## Files modified in Step 2

Backend:

- `backend/src/main/java/com/homesweethome/controller/FamilyController.java`: invitation preview, authenticated account resolution, selection on both join endpoints, explicit identifier fields, and controlled family error messages.
- `backend/src/main/java/com/homesweethome/service/FamilyService.java`: idempotent membership reuse and atomic profile linkage; require explicit profile selection for an unlinked account.
- `backend/src/main/java/com/homesweethome/service/FamilyRosterService.java`: serialized/authorized claims, duplicate-initialization checks, and complete profile responses.
- `backend/src/main/java/com/homesweethome/repository/FamilyRepository.java`: family-row lock query; no entity/schema changes.
- `backend/src/main/java/com/homesweethome/dto/JoinFamilyRequest.java`: selected `profileId` for the existing direct join endpoint.
- `backend/pom.xml`: test-scoped H2 dependency only, excluded from production dependencies.
- `backend/src/test/java/com/homesweethome/AuthenticationIntegrationTest.java`: preview authorization and join/membership response compatibility tests.
- `backend/src/test/java/com/homesweethome/FamilyRosterPersistenceTest.java` (new): isolated persistence, rollback, idempotence, and concurrent-claim tests.

Flutter:

- `mobile/lib/features/family/models/family_profile.dart` (new): typed household profile and invitation models with UUID validation.
- `mobile/lib/features/family/services/family_service.dart`: authenticated roster, preview, join, and self-link API methods using the existing API configuration.
- `mobile/lib/features/family/screens/family_screen.dart`: render the full typed roster, identify the current account, and offer explicit linking for older unlinked memberships.
- `mobile/lib/features/onboarding/screens/join_family_bottom_sheet.dart`: invitation lookup and selection of an existing profile; preserve the existing visual style, add scrolling for the extra required field, and dispose controllers/client safely.
- `mobile/test/family_integration_test.dart` (new): model/API tests and Family/join widget tests.
- This document.

The broader working tree already contained edits from before Step 2. Those files were not reset or attributed to this step.

## Verification

- Backend compilation: all 82 production source files compiled successfully.
- Backend tests: **23 passed**: 13 MVC/authentication/API tests, 9 isolated persistence tests, and the existing PostgreSQL application-context test.
- Concurrent claims tested: two accounts claiming one profile, and one account claiming two profiles. Exactly one claim succeeded and one returned conflict; no duplicate membership/profile remained.
- Isolated persistence tests use a named in-memory H2 database and create only its temporary tables. The PostgreSQL application-context test used `spring.jpa.hibernate.ddl-auto=validate`. It did not migrate the production schema or write household data.
- Flutter tests: **17 passed**, including seven new model/service/widget tests and the previous authentication/widget tests.
- Flutter analysis: no analyzer errors and no new findings; the existing unused Health import warning and four onboarding informational findings remain.
- `git diff --check`: passed.

H2 tests exercise real transactions and row-lock contention, but are not a live PostgreSQL concurrency test. Browser/device end-to-end checks and application restart persistence remain manual verification. No live household was used as test data.

## Manual checks after restarting both applications

Use the saved `JWT_SECRET` and the restart commands in `authentication-step-1.md`; do not generate a new key.

1. Sign in as an existing family member. Open Family and record the existing profile UUIDs and household count from the profiles API. Confirm both registered and unregistered people are listed.
2. With an appropriate second registered account, enter that family's invitation code, choose **Find Family**, select that account's existing household profile, then choose **Join Family Space**. Verify the profile UUID and household count did not change and the profile now says **Account linked (you)**.
3. Repeat joining with that same account and code. The existing membership must be reused. Check the membership response's `membershipId` separately from its `profileId`.
4. If an older member is unlinked, sign in as that member, open Family, choose the person-add action beside the correct unlinked profile, and confirm. Check that the existing membership and profile IDs were preserved.
5. Keep the browser open, restart only the backend with the same signing key, and refresh Family. Verify the same UUIDs/account links remain. Do not delete/recreate profiles if an older roster is incomplete.

Stop here. Health loading, record CRUD, document upload, and Health ID repair have not been started.
