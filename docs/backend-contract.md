# Backend Contract Audit

Last updated: 2026-05-23

Purpose: this file captures the AWS backend surface that the Flutter app expects before we remove remaining mock data. Any endpoint marked "verify" must be confirmed against the real backend repository or Swagger before code cleanup.

## Rules

- Do not replace a missing AWS feature with fake UI data.
- If an endpoint is missing, the Flutter app should show a loading, empty, or actionable error state.
- Display-only labels, tab names, colors, icons, Arabic month names, and placeholders are not backend mocks.
- Business data such as phone numbers, bank accounts, staff identifiers, assessment questions, report metadata, and facility names must come from AWS.

## Environment

| Item | Current value | Source | Notes |
|---|---|---|---|
| API base URL | `https://api.helpers-tech.com` | `lib/config/api_config.dart` | Should become environment-specific before production. |
| Cognito region | `us-east-1` | `lib/config/api_config.dart` | Used directly from Flutter. |
| Cognito user pool | `us-east-1_WQgMPSADf` | `lib/config/api_config.dart` | Verify staging/prod separation. |
| Cognito client | `ifk56gi2vp5jn4tshvp96vn06` | `lib/config/api_config.dart` | Public app client is okay, but environment config is still needed. |

## Auth And Users

| Method | Path / Target | Flutter source | Status |
|---|---|---|---|
| POST | `/auth/login` | `lib/services/auth_service.dart` | Implemented in Patch 1; backend handles Cognito password auth and returns tokens. |
| POST | Cognito `InitiateAuth` REFRESH_TOKEN_AUTH | `lib/services/auth_service.dart` | Implemented in Flutter. |
| POST | `/auth/register` | `lib/services/auth_service.dart` | Verify backend exists and restricts self-register roles. |
| POST | `/auth/register-admin` | `lib/services/auth_service.dart` | Added in backend Patch 2; requires `ADMIN_SETUP_SECRET`. |
| GET | `/auth/me` | `lib/screens/common/cloud_health_screen.dart` | Used by cloud health screen. |
| GET | `/users/clinical` | `lib/services/messages_service.dart` | Used to find specialist/chat recipients. |
| GET | `/user-preferences/me` | `lib/services/user_preferences_service.dart` | Added in backend Patch 6. |
| PUT | `/user-preferences/me` | `lib/services/user_preferences_service.dart` | Added in backend Patch 6. |
| GET | `/user-progress/me` | `lib/services/user_progress_service.dart` | Added in backend Patch 6. |
| POST | `/user-progress/points` | `lib/services/user_progress_service.dart` | Added in backend Patch 6. |

## Admin And Facility Settings

| Method | Path | Flutter source | Status |
|---|---|---|---|
| GET | `/admin/settings/emergency-contacts` | `lib/providers/app_riverpod.dart` | Added in backend Patch 2; Flutter now uses it. |
| POST | `/admin/users` | `lib/services/backend_mutation_service.dart` | Used for managed users; self-register should not call this. |
| PATCH | `/admin/users/:id` | `lib/services/backend_mutation_service.dart` | Verify route exists. |
| PATCH | `/admin/users/:id/disable` | `lib/services/backend_mutation_service.dart` | Verify route exists. |
| POST | `/admin/users/:id/photo/upload` | `lib/services/profile_image_service.dart` | Added in backend Patch 8; presigned S3 upload. |
| PATCH | `/admin/users/:id/photo/confirm` | `lib/services/profile_image_service.dart` | Added in backend Patch 8; persists `imageUrl`. |
| GET | `/admin/staff-performance` | `lib/services/backend_sync_service.dart` | Used in sync. |
| GET | `/admin/users/:id` | `lib/services/admin_users_service.dart` | Added in backend Patch 4; accepts managed user id or Cognito sub. |
| GET | `/admin/users/:id/reviews` | `lib/services/admin_users_service.dart`, `lib/screens/nurse/nurse_profile_screen.dart` | Added in backend Patch 9; used for nurse profile reviews. |
| GET/PUT | `/admin/settings/billing` | `lib/services/facility_settings_service.dart` | Added in backend Patch 2; Flutter now reads payment instructions. |
| GET/PUT | `/admin/settings/facility-profile` | `lib/services/facility_settings_service.dart` | Added in backend Patch 2; Flutter now reads facility name/address/contacts. |
| GET/POST | `/facilities/search` | `lib/services/facility_inquiry_service.dart` | Added in backend Patch 5; public guest search. |
| POST | `/facility-inquiries` | `lib/services/facility_inquiry_service.dart` | Added in backend Patch 5; public guest inquiry submission. |

## Residents

| Method | Path | Flutter source | Status |
|---|---|---|---|
| GET | `/residents` | `lib/services/backend_sync_service.dart`, `lib/services/residents_service.dart` | Core sync endpoint. |
| GET | `/residents/:id` | `lib/services/residents_service.dart` | Used by direct resident screens. |
| POST | `/residents` | `lib/services/backend_mutation_service.dart`, `lib/services/residents_service.dart` | Admin create resident. |
| PATCH | `/residents/:id` | `lib/services/backend_mutation_service.dart` | Admin update resident. |
| PUT | `/residents/:id/medical-info` | `lib/services/backend_mutation_service.dart` | Verify schema covers all Flutter fields. |
| GET | `/residents/:id/audit-trail` | `lib/providers/app_riverpod.dart`, `lib/screens/specialist/views/files_view.dart` | Added in backend Patch 10; specialist file audit timeline. |
| POST | `/residents/:id/photo/upload` | `lib/services/profile_image_service.dart` | Added in backend Patch 8; presigned S3 upload. |
| PATCH | `/residents/:id/photo/confirm` | `lib/services/profile_image_service.dart` | Added in backend Patch 8; persists `imageUrl`. |

## Family Members And Contacts

| Method | Path | Flutter source | Status |
|---|---|---|---|
| GET | `/family-members?residentId=:id` | `lib/services/backend_sync_service.dart` | Needed for calls/contact UI. |
| POST | `/family-members` | `lib/services/backend_mutation_service.dart` | Used for linking and importing contacts. |
| PATCH/DELETE | `/family-members/:id` | not implemented | Needed for pin, edit, delete if UI exposes those actions. |

## Medications

| Method | Path | Flutter source | Status |
|---|---|---|---|
| GET | `/medications/schedules` | `lib/services/backend_sync_service.dart`, `lib/services/medications_service.dart` | Core medication schedule. |
| POST | `/medications/schedules` | `lib/services/backend_mutation_service.dart` | Create schedule. |
| GET | `/medications/overdue` | `lib/services/backend_sync_service.dart`, `lib/services/medications_service.dart` | Nurse overdue view. |
| POST | `/medications/doses` | `lib/services/medications_service.dart` | Dose log. |
| PATCH | `/medications/doses/:id` | `lib/services/medications_service.dart` | Dose status update. |
| GET | `/medications/adherence` | `lib/services/medication_adherence_service.dart` | Reports. |

## Health

| Method | Path | Flutter source | Status |
|---|---|---|---|
| GET | `/health` | `lib/screens/common/cloud_health_screen.dart` | Public health check. |
| POST | `/health/vitals` | `lib/services/health_service.dart` | Record vitals. |
| GET | `/health/vitals` | `lib/services/backend_sync_service.dart`, `lib/services/health_service.dart` | Vitals history. |
| GET | `/health/alerts` | `lib/services/health_service.dart` | Alerts. |
| PATCH | `/health/alerts/:id` | `lib/services/health_service.dart` | Acknowledge/resolve. |
| GET | `/health/thresholds` | `lib/services/health_service.dart` | Threshold settings. |
| PUT | `/health/thresholds` | `lib/services/health_service.dart` | Threshold update. |

## Nurse Operations

| Method | Path | Flutter source | Status |
|---|---|---|---|
| GET/POST | `/nursing-notes` | `lib/services/backend_sync_service.dart`, `lib/services/backend_mutation_service.dart` | Verify author fields map to user names, not ids only. |
| GET/POST | `/handoffs` | `lib/services/backend_sync_service.dart`, `lib/services/backend_mutation_service.dart` | Shift handoff. |
| GET/POST | `/care-tasks` | `lib/services/backend_sync_service.dart`, `lib/services/backend_mutation_service.dart` | Care tasks. |
| PATCH | `/care-tasks/:id/complete` | `lib/services/backend_mutation_service.dart` | Complete task. |
| PATCH | `/care-tasks/:id/reopen` | `lib/services/backend_mutation_service.dart` | Reopen task. |
| DELETE | `/care-tasks/:id` | `lib/services/backend_mutation_service.dart` | Delete task. |
| GET/POST | `/inventory` | `lib/services/backend_sync_service.dart`, `lib/services/backend_mutation_service.dart` | Inventory. |
| PATCH | `/inventory/:id/stock` | `lib/services/backend_mutation_service.dart` | Stock update. |
| GET/POST | `/doctor-visits` | `lib/services/backend_sync_service.dart`, `lib/services/backend_mutation_service.dart` | Doctor visits. |
| GET/POST | `/medical-sessions` | `lib/services/backend_sync_service.dart`, `lib/services/backend_mutation_service.dart` | Medical sessions. |
| GET/POST | `/prescriptions` | `lib/services/backend_sync_service.dart`, `lib/services/backend_mutation_service.dart` | Prescriptions. |
| GET/POST | `/meal-plans` | `lib/services/backend_sync_service.dart`, `lib/services/backend_mutation_service.dart` | Meal plans. |

## Reports

| Method | Path | Flutter source | Status |
|---|---|---|---|
| GET | `/reports/nursing/preview` | `lib/services/backend_sync_service.dart`, `lib/services/nursing_reports_service.dart` | Used for family/nurse report preview. |
| GET | `/reports/nursing/completeness` | `lib/services/nursing_reports_service.dart` | Completeness checklist. |
| GET | `/reports/nursing/export` | `lib/services/nursing_reports_service.dart` | Flutter falls back to local PDF on failure; verify if this fallback should remain only as explicit offline export. |
| GET | `/reports/nursing/history` | `lib/services/backend_sync_service.dart` | Sent reports. |
| POST | `/reports/nursing/send` | `lib/services/backend_mutation_service.dart` | Send report. |
| GET/PATCH | `/reports/nursing/settings` | `lib/services/nursing_reports_service.dart` | Should include facility name/logo/recipients. |

## Family Bridge, Billing, Memories

| Method | Path | Flutter source | Status |
|---|---|---|---|
| GET | `/family-bridge/visits` | `lib/services/backend_sync_service.dart`, `lib/services/family_bridge_service.dart` | Visits. |
| POST | `/family-bridge/visits` | `lib/services/backend_mutation_service.dart` | Book visit. |
| PATCH | `/family-bridge/visits/:id/status` | `lib/services/family_bridge_service.dart` | Approve/reject. |
| GET | `/family-bridge/media` | `lib/services/backend_sync_service.dart`, `lib/services/family_media_service.dart` | Family media. |
| POST | `/family-bridge/media/upload` | `lib/services/family_media_service.dart` | Presigned upload. |
| PATCH | `/family-bridge/media/:id/confirm` | `lib/services/family_media_service.dart` | Confirm upload. |
| DELETE | `/family-bridge/media/:id` | `lib/services/family_media_service.dart` | Added in backend Patch 4. |
| GET | `/billing` | `lib/services/backend_sync_service.dart` | Family bills. |
| PATCH | `/billing/:id/pay` | `lib/services/backend_mutation_service.dart` | Mark paid. |
| GET/POST | `/memories` | `lib/services/backend_sync_service.dart`, `lib/services/backend_mutation_service.dart` | Memory wall. |
| PATCH | `/memories/:id/appreciate` | `lib/services/backend_mutation_service.dart` | Appreciation. |
| DELETE | `/memories/:id` | `lib/services/backend_mutation_service.dart` | Delete memory. |

## Social Specialist

| Method | Path | Flutter source | Status |
|---|---|---|---|
| GET/POST | `/social/needs` | `lib/services/backend_sync_service.dart`, `lib/services/social_service.dart` | Needs. |
| GET | `/social/assessment-tools` | `lib/services/backend_sync_service.dart`, `lib/services/social_service.dart` | Tools. |
| GET | `/social/assessment-tools/:id/questions` | `lib/services/social_service.dart` | Added in backend Patch 3; Flutter now uses it without local fallback questions. |
| GET | `/social/gds-questions` | `lib/services/social_service.dart` | Required before removing local `gdsQuestions`. |
| GET | `/social/resident-scores` | `lib/services/backend_sync_service.dart`, `lib/services/social_service.dart` | Resident scores. |
| GET/POST | `/social/assessments` | `lib/services/backend_sync_service.dart`, `lib/services/backend_mutation_service.dart` | GET added in backend Patch 3; POST already existed. |
| GET | `/social/kpis` | `lib/services/social_service.dart` | Social KPIs. |
| GET/POST/PATCH | `/complaints` family | `lib/services/complaints_service.dart` | Complaints. |

## Volunteers

| Method | Path | Flutter source | Status |
|---|---|---|---|
| GET/PUT | `/volunteers/profile` | `lib/services/backend_sync_service.dart`, `lib/services/backend_mutation_service.dart` | Profile. |
| GET/POST/PATCH/DELETE | `/volunteers/opportunities` | `lib/services/backend_sync_service.dart`, `lib/services/backend_mutation_service.dart` | Opportunities. |
| GET/POST/PATCH | `/volunteers/bookings` | `lib/services/backend_sync_service.dart`, `lib/services/backend_mutation_service.dart` | Bookings/cancel/attendance. |
| GET | `/volunteers/certificates` | `lib/services/backend_sync_service.dart` | Certificates. |
| GET | `/volunteers/ratings` | `lib/services/backend_sync_service.dart` | Ratings. |
| GET/POST | `/volunteers/reviews` | `lib/services/backend_sync_service.dart`, `lib/services/backend_mutation_service.dart` | Reviews. |
| POST | `/volunteers/documents/upload` | `lib/services/volunteer_documents_service.dart` | Added in backend Patch 8; presigned S3 upload. |
| PATCH | `/volunteers/documents/:id/confirm` | `lib/services/volunteer_documents_service.dart` | Added in backend Patch 8; updates profile CV/recommendation URLs. |
| POST | `/volunteers/profile/public-link` | `lib/services/volunteer_documents_service.dart` | Added in backend Patch 8; generates/returns share URL. |
| GET | `/volunteers/profile/public/:slug` | public web/API consumers | Added in backend Patch 8; public volunteer profile. |

## AI, Media, Messaging, Calls, Push

| Method | Path | Flutter source | Status |
|---|---|---|---|
| POST | `/ai/chat` | `lib/services/ai_service.dart` | AI companion. |
| GET | `/ai/recommendations/:residentId` | `lib/services/ai_service.dart` | AI insights. |
| GET/POST | `/ai/memory/:residentId` | `lib/services/ai_service.dart` | Verify persistence in DB, not process memory. |
| POST/PATCH | `/ai/media/upload`, `/ai/media/:id/confirm` | `lib/services/ai_media_service.dart` | Added in backend Patch 8; presigned media upload. |
| GET/POST | `/messages` family | `lib/services/messages_service.dart` | Text chat implemented; media fields are not sent until backend supports them. |
| POST/PATCH/GET | `/video-calls` family | `lib/services/video_call_service.dart` | Added in backend Patch 7; stores call state and optional join URLs. |
| POST/GET/PATCH | `/emergency` family | `lib/services/emergency_service.dart` | SOS and active emergency flows; request mapping fixed in Patch 1. |
| POST/DELETE | `/notifications/push-tokens` | `lib/services/push_notification_service.dart` | Verify route shape matches backend. |
| GET/POST/PATCH/DELETE | `/notifications` family | `lib/services/notifications_api_service.dart` | Internal notifications. |

## Immediate Backend Questions

1. Where is the current backend repository for `https://api.helpers-tech.com`?
2. Is there an OpenAPI/Swagger URL available for the deployed API?
3. Which endpoints above are already deployed in staging/production?
4. Are `/auth/register`, `/auth/register-admin`, `/family-members`, `/emergency`, `/messages`, `/video-calls`, `/user-preferences`, and `/user-progress` live?
5. Which fields are mandatory for facility settings, billing, emergency contacts, assessment questions, and staff profile details?
