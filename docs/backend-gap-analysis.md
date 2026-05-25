# Backend Gap Analysis Against Flutter

Last updated: 2026-05-23

Backend source checked from `external/raaya-backend` at commit `66cf317` (`2026-05-20T23:22:54+03:00`, `feat(ci): copy migrations to EC2 and run them on every deploy`).

## Summary

The backend repository is much more complete than the old local report suggested. It already contains modules for emergency alerts, messages, family members, push tokens, persistent AI memory, and GDS questions.

The main blockers are now contract mismatches and a smaller set of missing endpoints. Because the backend uses a global `ValidationPipe` with `whitelist: true` and `forbidNonWhitelisted: true`, Flutter requests with extra fields will fail with HTTP 400, not merely ignore unsupported fields.

Patch 1 has now fixed the highest-risk Flutter-side mismatches for login, SOS creation, and text chat sends. Remaining work is mostly missing backend capability or larger UX/data cleanup.

Patch 2 adds backend facility setup/settings support and removes the first hardcoded facility payment/emergency values from Flutter. The backend changes live in `external/raaya-backend` and need deployment before the app can use them in AWS.

Patch 3 adds the missing social assessment read contract and removes the local Flutter assessment question bank fallback.

Patch 4 adds the remaining small P0 backend reads/deletes: family media delete and admin managed-user detail. Flutter staff detail now avoids fake national ID/email values.

Patch 5 replaces the guest facility inquiry mock in the login screen with public backend search/inquiry endpoints.

Patch 6 adds backend persistence for user preferences and user progress, matching the existing Flutter services.

Patch 7 adds backend persistence for video call state, matching the existing Flutter `VideoCallService`.

Patch 8 adds the S3-backed upload contract for resident/staff profile photos, AI media attachments, volunteer documents, and volunteer public profile links. Flutter volunteer upload/share now uses AWS endpoints instead of local simulation.

Patch 9 adds `GET /admin/users/:id/reviews` and replaces the static nurse profile review with AWS-backed staff reviews or an empty state.

Patch 10 adds `GET /residents/:id/audit-trail` and removes the static specialist file timeline fallback while audit data is loading. Specialist PDF preview no longer inserts fake timeline events.

Patch 11 removes the Flutter default role shortcut so startup/auth routing depends on AWS session restore or a fresh login.

Patch 12 fixes the Android production-readiness blocker: `applicationId`/namespace are no longer `com.example.my_app`, release no longer signs with debug keys, and signing is loaded from `android/key.properties` or CI environment variables.

Patch 13 replaces the default Flutter README and web metadata with project-specific setup, AWS backend, Android signing, and verification instructions.

## Status Key

- `LIVE`: endpoint exists in backend source and broadly matches Flutter.
- `MISMATCH`: endpoint exists but request/response contract does not match Flutter.
- `MISSING`: endpoint does not exist in backend source.
- `PARTIAL`: endpoint exists but lacks fields needed to remove mock data.

## Patch 1 Implementation Status

Completed in Flutter:

1. `AuthService.login()` now calls backend `POST /auth/login` instead of direct Cognito password auth.
2. `EmergencyService.triggerSos()` now sends only backend-supported fields: `triggeredBy`, `residentId`, `location`, and `notes`.
3. Emergency response parsing now accepts backend snake_case fields such as `alert_type`, `triggered_by`, and `created_at`.
4. `MessagesService.send()` now sends text-only payloads and no longer sends unsupported `mediaUrl` / `mediaType`.
5. Specialist chat blocks media-only messages with a visible backend-sync error until backend media support exists.

## Patch 2 Implementation Status

Completed in backend source:

1. Added `POST /auth/register-admin`, protected by `ADMIN_SETUP_SECRET`, to bootstrap an Admin Cognito user and initialize facility profile settings.
2. Extended `facility_settings` with JSONB columns: `emergency_contacts`, `billing_settings`, and `facility_profile`.
3. Added readable facility settings endpoints:
   - `GET /admin/settings/emergency-contacts`
   - `GET /admin/settings/billing`
   - `GET /admin/settings/facility-profile`
4. Added Admin-only update endpoints for the same settings paths.

Completed in Flutter:

1. Added `FacilitySettingsService`.
2. Emergency phone numbers are loaded from backend settings instead of hardcoded provider defaults.
3. Family billing/payment text is loaded from backend billing settings instead of a static bank account/wallet.
4. Nurse PDF report header now uses the provider facility name instead of a hardcoded care-home name.

## Patch 3 Implementation Status

Completed in backend source:

1. Added `GET /social/assessments` with optional `residentId` and `limit`.
2. Added `GET /social/assessment-tools/:id/questions`.
3. Added `scale` to `social_assessment_tools` and seeded backend-backed `FAMILY` and `SOCIAL` question sets.
4. Reused the same backend question reader for `GET /social/gds-questions?scale=`.

Completed in Flutter:

1. Removed the local assessment `questionBank` contents.
2. Removed hardcoded GDS question defaults.
3. Tool questions now load from AWS; empty/missing questions render a setup-required state instead of fake questions.

## Patch 4 Implementation Status

Completed in backend source:

1. Added `DELETE /family-bridge/media/:id`.
2. Added `GET /admin/users/:id`, accepting either `managed_users.id` or `cognito_sub`.

Completed in Flutter:

1. Added `AdminUsersService`.
2. Admin staff detail screen now loads staff email/role/status from AWS where available.
3. Removed fake national ID and generated email from the staff detail screen; unsupported fields show a setup-required value.

## Patch 5 Implementation Status

Completed in backend source:

1. Added `GET /facilities/search`.
2. Added `POST /facilities/search`.
3. Added `POST /facility-inquiries`.
4. Added `facility_inquiries` table via migration `033_create_facility_inquiries.sql`.

Completed in Flutter:

1. Added `FacilityInquiryService`.
2. Guest inquiry in `LoginScreen` now searches AWS and stores a real inquiry.
3. Removed the fake `"دار الأمل"` success result.

## Patch 6 Implementation Status

Completed in backend source:

1. Added `GET /user-preferences/me`.
2. Added `PUT /user-preferences/me`.
3. Added `GET /user-progress/me`.
4. Added `POST /user-progress/points`.
5. Added `user_preferences` and `user_progress` tables via migration `034_create_user_state.sql`.

## Patch 7 Implementation Status

Completed in backend source:

1. Added `POST /video-calls`.
2. Added `GET /video-calls/active`.
3. Added `PATCH /video-calls/:id/status`.
4. Added `GET /video-calls/history`.
5. Added `video_calls` table via migration `035_create_video_calls.sql`.

## Patch 8 Implementation Status

Completed in backend source:

1. Added `residents.image_url` and `managed_users.image_url`.
2. Added `POST /residents/:id/photo/upload` and `PATCH /residents/:id/photo/confirm`.
3. Added `POST /admin/users/:id/photo/upload` and `PATCH /admin/users/:id/photo/confirm`.
4. Added `ai_media_uploads` plus `POST /ai/media/upload` and `PATCH /ai/media/:id/confirm`.
5. Added `volunteer_documents`, `volunteer_profiles.recommendation_file_url`, and `volunteer_profiles.public_slug`.
6. Added `POST /volunteers/documents/upload`, `PATCH /volunteers/documents/:id/confirm`, `POST /volunteers/profile/public-link`, and `GET /volunteers/profile/public/:slug`.

Completed in Flutter:

1. Added `VolunteerDocumentsService`.
2. Volunteer document upload now uses backend presigned S3 upload/confirm.
3. Volunteer share now requests a backend public profile URL instead of constructing a local fake link.

## Patch 9 Implementation Status

Completed in backend source:

1. Added `staff_reviews` table via migration `037_create_staff_reviews.sql`.
2. Added `GET /admin/users/:id/reviews`, accepting either `managed_users.id` or Cognito sub through the existing staff lookup.

Completed in Flutter:

1. Added staff review parsing to `AdminUsersService`.
2. Nurse profile review card now loads AWS staff reviews.
3. The static review text and fixed `4.9/5` rating were replaced with backend data or an empty/loading/error state.

## Patch 10 Implementation Status

Completed in backend source:

1. Added `GET /residents/:id/audit-trail`.
2. The endpoint composes resident updates, linked records, and nursing notes into one facility-scoped timeline.

Completed in Flutter:

1. Existing `loadAuditTrail()` now caches empty/error results instead of repeatedly retrying silently.
2. Specialist resident file details show a loading state, then AWS timeline or an empty state; the hardcoded three-item timeline fallback was removed.

## Live Or Mostly Live

| Domain | Backend status | Notes |
|---|---|---|
| Auth self-register | `LIVE` | `POST /auth/register` exists for `Family` and `Volunteer`. |
| Auth login | `LIVE` | `POST /auth/login` exists and supports Cognito secret hash. Flutter uses it as of Patch 1. |
| Forgot password | `LIVE` | `POST /auth/forgot-password` and `POST /auth/confirm-forgot-password` exist. Flutter does not use them yet. |
| Residents | `LIVE` | CRUD plus `GET/PUT /residents/:id/medical-info` exist. |
| Family members | `LIVE` | `GET/POST/PATCH/DELETE /family-members` exists. |
| Medications | `LIVE` | Schedules, doses, overdue, adherence exist. |
| Health | `LIVE` | Vitals, alerts, thresholds exist. |
| Complaints | `LIVE` | Create/list/get/update status exist. |
| Family bridge visits/media upload | `LIVE` | Upload/list/confirm/delete are available after Patch 4. |
| Billing | `LIVE` | Bills/pay exist and facility billing settings were added in Patch 2. |
| Memories | `LIVE` | Create/list/appreciate/delete exist. |
| Emergency | `LIVE` | Endpoint exists; Flutter request mapping was fixed in Patch 1. |
| Messages | `LIVE/PARTIAL` | Text messages work; media fields are still unsupported by backend. |
| Notifications | `LIVE` | Create/list/read/delete/push-token endpoints exist. |
| AI recommendations/chat/memory/media | `LIVE` | Memory is persisted in `ai_resident_memory`; media upload/confirm added in Patch 8. |
| Social GDS questions | `LIVE` | `GET /social/gds-questions` exists. |
| Reports nursing | `LIVE/PARTIAL` | Preview/completeness/export/history/settings/send exist; settings lack facility metadata. |
| Volunteers core | `LIVE` | Profile/opportunities/bookings/certificates/ratings/reviews plus document upload/public profile links exist after Patch 8. |

## Critical Contract Mismatches

| Priority | Flutter expectation | Backend reality | Fix |
|---|---|---|---|
| P0 | `AuthService.registerAdmin()` calls `POST /auth/register-admin`. | Added in backend Patch 2; deployment pending. | Deploy backend and set `ADMIN_SETUP_SECRET`. |
| P0 | Flutter `EmergencyService.triggerSos()` used to send `sourceRole`, `type`, and `message`. | Backend `TriggerSosDto` requires `triggeredBy`, accepts `residentId`, `location`, `notes`; unknown fields are rejected. | Fixed in Flutter Patch 1. |
| P0 | Flutter `MessagesService.send()` used to send `mediaUrl` and `mediaType`. | Backend `SendMessageDto` only accepts `body`, `recipientId`, `residentId`; unknown media fields are rejected. | Text send fixed in Flutter Patch 1; add backend media columns/DTO later if chat media is required. |
| P0 | Flutter uses `/admin/settings/emergency-contacts`. | Added in backend Patch 2; deployment pending. | Deploy backend migration `031_extend_facility_settings.sql`. |
| P0 | Flutter uses `/social/assessment-tools/:id/questions`. | Added in backend Patch 3; deployment pending. | Deploy backend migration `032_extend_social_assessment_tools.sql`. |
| P0 | Flutter sync calls `GET /social/assessments`. | Added in backend Patch 3; deployment pending. | Deploy backend Patch 3. |
| P0 | Flutter can call `/family-bridge/media/:id` DELETE. | Added in backend Patch 4; deployment pending. | Deploy backend Patch 4. |

## Missing Backend Endpoints Needed To Remove Mocks

| Priority | Endpoint / capability | Needed for |
|---|---|---|
| P0 | `POST /auth/register-admin` | Added in backend Patch 2; deploy pending. |
| P0 | `GET/PUT /admin/settings/emergency-contacts` or extend `/admin/settings` | Added in backend Patch 2; deploy pending. |
| P0 | `GET/PUT /admin/settings/billing` | Added in backend Patch 2; deploy pending. |
| P0 | `GET/PUT /admin/settings/facility-profile` | Added in backend Patch 2; deploy pending. |
| P0 | `GET /admin/users/:id` | Added in backend Patch 4; Flutter staff detail uses it. |
| P0 | `GET /social/assessments?residentId=` | Added in backend Patch 3; deploy pending. |
| P0 | `GET /social/assessment-tools/:id/questions` | Added in backend Patch 3; local Flutter question bank removed. |
| P1 | `POST /residents/:id/photo/upload`, `PATCH /residents/:id/photo/confirm` | Added in backend Patch 8; Flutter `ProfileImageService.uploadResidentImage` matches it. |
| P1 | `POST /admin/users/:id/photo/upload`, `PATCH /admin/users/:id/photo/confirm` | Added in backend Patch 8; Flutter `ProfileImageService.uploadStaffImage` matches it. |
| P1 | `GET /residents/:id/audit-trail` | Added in backend Patch 10; specialist files use it. |
| P1 | `POST /ai/media/upload`, `PATCH /ai/media/:id/confirm` | Added in backend Patch 8; Flutter `AiMediaService` matches it. |
| P1 | `POST /volunteers/documents/upload`, `PATCH /volunteers/documents/:id/confirm` | Added in backend Patch 8; Flutter upload UI uses it. |
| P1 | `GET /volunteers/profile/public/:slug`, `POST /volunteers/profile/public-link` | Added in backend Patch 8; Flutter share uses the generated link. |
| P1 | `GET /admin/users/:id/reviews` | Added in backend Patch 9; nurse profile uses it instead of static review text. |
| P1 | `POST /facilities/search`, `GET /facilities/search`, `POST /facility-inquiries` | Added in backend Patch 5; Flutter guest inquiry uses them. |
| P1 | `/video-calls` module | Added in backend Patch 7; Flutter service already matches. |
| P1 | `/user-preferences` module | Added in backend Patch 6; Flutter service already matches. |
| P1 | `/user-progress` module | Added in backend Patch 6; Flutter service already matches. |

## Existing Backend Features Flutter Should Use Better

| Area | Recommendation |
|---|---|
| Login | Prefer backend `POST /auth/login` over direct Cognito in Flutter. Backend already handles `COGNITO_CLIENT_SECRET`; direct Flutter Cognito cannot safely use the client secret. |
| Forgot password | Add Flutter screens/actions using `/auth/forgot-password` and `/auth/confirm-forgot-password`. |
| GDS questions | Flutter should use `/social/gds-questions`; remove hardcoded fallback once deployed data is confirmed. |
| AI memory | Old docs said AI memory was process-local; current backend persists it in `ai_resident_memory`. Update Flutter/report docs accordingly. |
| Managed users | Backend managed users do not allow `Volunteer` role. Use `/auth/register` for volunteers or extend `managed_users` intentionally. |

## Frontend Fixes That Can Start Before Backend Changes

These do not require new backend work:

1. Use `/social/gds-questions` as the only GDS source after confirming seed data.
2. Remove local fallback text where an empty state is safer.
3. Decide whether to add backend media support for messages or keep specialist chat text-only.

## Backend PR Plan

### PR 1: Auth And Facility Setup

- Added in Patch 2:
  - `POST /auth/register-admin`
  - facility profile/settings fields:
  - facility name
  - address
  - logo URL
  - billing/payment instructions
  - emergency contacts
- Remaining: deploy migration and verify Swagger/deployed API.

### PR 2: Social Assessment Contract

- Added in Patch 3:
  - `GET /social/assessments`
  - `GET /social/assessment-tools/:id/questions`
  - `social_assessment_tools.scale`
- Remaining: deploy migration and confirm seeded questions in AWS.

### PR 3: Media And Profile Uploads

- Added in Patch 8:
  - resident/staff photo upload/confirm endpoints
  - AI media upload/confirm endpoints
  - volunteer document upload/confirm endpoints
  - volunteer public profile link endpoints
- Family media delete was added earlier in Patch 4.

### PR 4: Communication And Calls

- Extend messages table/DTO for `media_url` and `media_type`, or remove media from chat.
- Added video-calls module in Patch 7:
  - `POST /video-calls`
  - `GET /video-calls/active`
  - `PATCH /video-calls/:id/status`
  - `GET /video-calls/history`

### PR 5: User State And Staff Details

- Add user preferences module.
- Add user progress module.
- Add staff detail/reviews endpoints.
- Add resident audit trail endpoint.

## Next Flutter Cleanup Order

1. Replace the remaining facility/report values after backend Patch 2 is deployed and seeded.
2. Volunteer upload/share mocks were removed in Patch 8; verify on deployed AWS after migration `036_create_upload_support.sql`.
3. Split sync by domain after endpoints are stable.
