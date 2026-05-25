# Agent Work Plan

Last updated: 2026-05-23

This plan is designed so multiple AI agents can work without stepping on the same files. The first objective is removing mock business data and completing AWS integration. Refactoring `AppRiverpod`, Android production setup, Firebase platform setup, tests, and README come after the mock cleanup foundation.

## Coordination Rules

- One agent owns a file set at a time.
- Backend agents must update Swagger/OpenAPI and migrations with every endpoint change.
- Frontend agents must not invent local fallback data for missing backend endpoints.
- If a backend endpoint is missing, frontend should show an empty/setup/error state until the backend task lands.
- Every task should finish with `flutter analyze` or relevant backend tests.

## Agent A: Backend Contract And Mock Audit

Status: active in this repository. Backend repository cloned to `external/raaya-backend` and patched through backend/Flutter Patch 13.

Owns:
- `docs/backend-contract.md`
- `docs/mock-audit.md`
- `docs/backend-gap-analysis.md`
- Any generated endpoint status table.

Tasks:
1. Verify every Flutter endpoint against deployed Swagger or backend source.
2. Mark endpoints as live, missing, or incompatible.
3. Update mock audit when new mock strings are found.
4. Produce a final "ready for cleanup" checklist.

Output:
- Confirmed backend contract.
- List of backend PRs required before frontend deletion.

## Agent B: AWS Backend Missing Endpoints

Requires:
- Real backend repository.
- Deployment target details.
- Database migration process.

Owns backend files only.

Tasks:
1. Add facility settings endpoints:
   - emergency contacts
   - billing/payment info
   - facility profile/report metadata
2. Add social question bank endpoints:
   - GDS questions
   - tool-specific assessment questions
3. Add staff detail/review endpoints. Staff detail done in Patch 4; staff reviews read endpoint done in Patch 9.
4. Add volunteer document upload/public profile endpoints. Done in Patch 8.
5. Add resident audit trail endpoint. Done in Patch 10.
6. Verify emergency/messages/video-calls/user-preferences/user-progress endpoints. Video calls/user state done in Patches 6-7.
7. Add tests and Swagger docs.

Output:
- Backend PR with migrations, controllers, services, DTOs, guards, tests.
- Swagger URL or OpenAPI file for Agent C/D.

## Agent C: Flutter Facility/Auth/Admin Cleanup

Owns:
- `lib/providers/app_riverpod.dart` only for auth/facility/admin sections.
- `lib/screens/auth/*`
- `lib/screens/admin/*`
- `lib/screens/nurse/nurse_dashboard_screen.dart` emergency contact usage.
- New `lib/services/*` files for facility/admin settings.

Tasks:
1. Remove default role after storage/Cognito restore. Done in Patch 11.
2. Remove hardcoded emergency contacts and wire to AWS.
3. Replace guest facility inquiry fake result with AWS flow.
4. Replace family billing static text with facility billing settings.
5. Replace hardcoded staff detail values with staff endpoint.
6. Add empty/setup states for missing settings.

Tests:
- Auth restore behavior.
- Emergency settings load failure.
- Billing settings empty state.

## Agent D: Flutter Social/Nurse/Volunteer Cleanup

Owns:
- `lib/screens/specialist/*`
- `lib/screens/nurse/nurse_reports_screen.dart`
- `lib/screens/nurse/nurse_profile_screen.dart`
- `lib/screens/volunteer/*`
- `lib/services/social_service.dart`
- `lib/services/nursing_reports_service.dart`
- New upload/public profile services if needed.

Tasks:
1. Remove local `questionBank` and `gdsQuestions` once backend is live.
2. Make assessment screens require backend questions.
3. Replace report facility name with report settings.
4. Replace nurse static review with staff review data or empty state. Done in Patch 9.
5. Replace volunteer `_simulateUpload`. Done in Patch 8.
6. Replace volunteer `_simulateShare`. Done in Patch 8.

Tests:
- Social assessment questions loading.
- GDS empty/error states.
- Report settings mapping.
- Volunteer upload service behavior.

## Agent E: Sync Performance And Tests

Owns:
- `lib/services/backend_sync_service.dart`
- New domain sync services.
- `test/`

Tasks:
1. Split `BackendSyncService.load()` into domain-specific loaders.
2. Make post-login sync minimal.
3. Use parallel loading where domains are independent.
4. Make domain failures isolated.
5. Add mapper unit tests for every domain touched.
6. Add API client and auth service tests with mocked HTTP.

Tests:
- `flutter analyze`
- `flutter test`
- Sync partial failure tests.

## Agent F: Production Readiness After Mock Cleanup

Owns:
- `android/app/build.gradle.kts`
- `android/app/src/main/AndroidManifest.xml`
- `lib/firebase_options.dart`
- `README.md`
- CI files if added.

Tasks:
1. Replace `com.example.my_app` application ID. Done in Patch 12 (`com.raaya.taptaba`).
2. Add release signing configuration using environment/CI secrets. Done in Patch 12 via `android/key.properties` or `ANDROID_*` env vars.
3. Add flavors for dev/staging/prod.
4. Configure Firebase for target platforms or guard unsupported platforms safely.
5. Rewrite README with setup, environment, run, test, build, and deployment steps. Done in Patch 13.
6. Add CI for analyze/test/build.

## Suggested Execution Sequence

1. Agent A verifies this contract against the real backend.
2. Agent B implements remaining backend endpoints.
3. Agent C and Agent D remove remaining mock data in disjoint frontend areas.
4. Agent E adds tests and improves sync performance.
5. Agent F completes production readiness.

## Do Not Start Yet

Do not split `AppRiverpod` until mock cleanup has landed. Splitting first will spread fake data across new providers and make cleanup harder.
