# Mock And Fallback Audit

Last updated: 2026-05-23

Goal: remove business mock data from the Flutter app and replace it with AWS-backed data. This document separates real mocks from harmless UI constants.

Patch 2 removed the hardcoded emergency contact defaults from `AppRiverpod`, removed the nurse dashboard emergency-number constants, replaced the family payment instructions with backend billing settings, and changed the nurse PDF header to use the loaded facility name.

Patch 3 removed the local social assessment question bank and the hardcoded GDS defaults from `AppRiverpod`; assessment questions now require backend data.

Patch 4 removed the fake staff national ID/generated email from the admin staff detail screen and wired it to `GET /admin/users/:id`.

Patch 5 removed the fake guest inquiry result from the login screen and wired it to `GET/POST /facilities/search` plus `POST /facility-inquiries`.

Patch 8 removed volunteer upload/share simulation by wiring document uploads to presigned S3 endpoints and profile sharing to `POST /volunteers/profile/public-link`.

Patch 9 removed the static nurse profile family review and rating fallback; the screen now reads `GET /admin/users/:id/reviews` and renders an empty/error state when AWS has no reviews.

Patch 10 removed the hardcoded specialist resident-file timeline fallback; the details sheet now waits for `GET /residents/:id/audit-trail` and shows AWS data or an empty state. The specialist PDF preview no longer inserts fake timeline items.

Patch 11 removed the default `currentRole = 'أخصائي اجتماعي'` startup state. The app now starts unauthenticated unless AWS/Cognito session restore succeeds, and the specialist dashboard no longer forces that role on init.

Patch 12 addressed Android release setup: production package id is `com.raaya.taptaba`, debug signing is no longer used for release, and keystore secrets are gitignored.

Patch 13 replaced the default Flutter README/web metadata with Raaya-specific setup and verification notes.

## Keep As UI Constants

These are not backend mocks and should not block the cleanup:

- Colors, gradients, animations, icons, route labels, Arabic month/day names.
- Tab labels such as `أمس`, `اليوم`, `غداً`, `الأسبوع`.
- Empty-state copy such as "لا توجد حجوزات".
- Text field hints and examples.
- Permission dialogs and local device-only state.

## High Priority Mocks To Remove

| Priority | Source | Current behavior | Required backend-backed replacement |
|---|---|---|---|
| P0 | `lib/providers/app_riverpod.dart` | Previously defaulted `currentRole` to `أخصائي اجتماعي`. | Fixed in Patch 11; starts without a role until AWS session restore/login succeeds. |
| P0 | `lib/providers/app_riverpod.dart` | Previously hardcoded emergency contacts. | Fixed in Patch 2; now loaded from `/admin/settings/emergency-contacts`. |
| P0 | `lib/screens/nurse/nurse_dashboard_screen.dart` | Previously static nurse dashboard emergency numbers. | Fixed in Patch 2; now uses provider emergency contacts only. |
| P0 | `lib/providers/app_riverpod.dart` | Previously local `questionBank` for social assessment tools. | Fixed in Patch 3; now requires `/social/assessment-tools/:id/questions`. |
| P0 | `lib/providers/app_riverpod.dart` | Previously local `gdsQuestions`. | Fixed in Patch 3; now requires `/social/gds-questions`. |
| P0 | `lib/screens/auth/login_screen.dart` | Previously guest inquiry always found "دار الأمل". | Fixed in Patch 5; now searches AWS and stores a real inquiry. |
| P0 | `lib/screens/family/family_dashboard_screen.dart` | Previously static bank account and wallet number. | Fixed in Patch 2; now reads `/admin/settings/billing`. |
| P0 | `lib/screens/admin/admin_staff_detail_screen.dart` | Previously static national ID/generated email for staff. | Fixed in Patch 4; now loads `/admin/users/:id` and shows setup-required values for unsupported fields. |
| P0 | `lib/screens/nurse/nurse_reports_screen.dart` | Previously static facility name in locally generated PDF. | Fixed in Patch 2; now uses loaded provider facility name. |

## Medium Priority Mocks To Remove

| Priority | Source | Current behavior | Required backend-backed replacement |
|---|---|---|---|
| P1 | `lib/screens/nurse/nurse_profile_screen.dart` | Previously displayed a static review mentioning "ممرضة منى". | Fixed in Patch 9; now uses staff reviews from AWS or an empty state. |
| P1 | `lib/screens/volunteer/profile_view.dart` | Previously `_simulateShare` built a local profile link. | Fixed in Patch 8; now uses backend public profile link. |
| P1 | `lib/screens/volunteer/widgets/edit_profile_sheet.dart` | Previously `_simulateUpload` stored selected CV/recommendation file name locally. | Fixed in Patch 8; now uses presigned document upload endpoint. |
| P1 | `lib/providers/app_riverpod.dart:338` | `simulateSessionExpiry` dev utility in production provider. | Move behind debug/dev-only API or test helper. |
| P1 | `lib/providers/app_riverpod.dart:2353` | `simulateNotification` dev utility. | Move behind debug/dev-only API or remove. |
| P1 | `lib/services/notification_service.dart:165` | `simulateIncomingNotification`. | Move behind debug/dev-only API or remove. |
| P1 | `lib/screens/admin/views/admin_home_view.dart:710` | Static fallback chart history. | Empty chart state or backend time-series endpoint. |
| P1 | `lib/screens/specialist/views/files_view.dart` | Previously showed a static three-item activity timeline while audit trail was missing/loading. | Fixed in Patch 10; now uses resident audit trail from AWS. |
| P1 | `lib/providers/app_riverpod.dart:3105` | Family notification comment says simulated target. | Verify target role values and backend notification routing. |

## Mapper Fallbacks To Review

These fallbacks are sometimes acceptable for display, but they can also hide backend schema gaps. Review them per domain before removing.

| Source | Pattern | Recommendation |
|---|---|---|
| `lib/services/backend_sync_service.dart` | `fallback: 'غير محدد'`, `fallback: 'من AWS'`, `fallback: 'دار الرعاية'` | Prefer nullable fields and UI empty states for required business data. |
| `lib/services/backend_sync_service.dart` | Synthetic values like `points: 10`, `badges: 'AWS'`, `contractType: 'شهري'` | Add backend fields or remove from UI if not supported. |
| `lib/services/backend_sync_service.dart` | `DateTime(fallbackYear ?? DateTime.now().year, 1, 1)` | Do not synthesize dates for missing DOB/admission dates. |
| `lib/services/backend_mutation_service.dart` | Defaults like `gender: 'male'`, `lastName: '-'`, `shift incomingNurseId: 'unassigned'` | Require UI input or backend defaults with documented meaning. |
| `lib/providers/app_riverpod.dart` | Local insert after mutation without returned backend object | Prefer using backend response or refresh domain after mutation. |

## Items That May Stay Temporarily If Explicitly Marked Offline

| Source | Current behavior | Condition to keep |
|---|---|---|
| Local PDF generation | Used when AWS report export fails. | Keep only as explicit offline export, not as silent replacement for backend failure. |
| Device gallery/photo picker | Local device integration. | Keep; this is not mock data. |
| TTS/STT state | Local accessibility feature. | Keep; backend not needed. |
| Pending assessment queue | Offline support. | Keep if failures are visible and sync retry is explicit. |

## Required Backend Work Items

1. Facility search and inquiry:
   - `GET /facilities/search?governorate=&city=&features=`
   - `POST /facility-inquiries`
2. Facility settings:
   - `GET/PUT /admin/settings/emergency-contacts`
   - `GET/PUT /admin/settings/billing`
   - `GET/PUT /admin/settings/facility-profile`
3. Social assessment question bank:
   - `GET /social/gds-questions`
   - `GET /social/assessment-tools/:id/questions`
4. Staff details and feedback:
   - `GET /admin/users/:id`
   - `GET /admin/users/:id/reviews`
   - Staff reviews read endpoint added in Patch 9.
5. Volunteer document and public profile:
   - `POST /volunteers/documents/upload`
   - `PATCH /volunteers/documents/:id/confirm`
   - `POST /volunteers/profile/public-link`
   - `GET /volunteers/profile/public/:slug`
   - Added in backend Patch 8; deployment pending.
6. Reports:
   - Ensure `/reports/nursing/settings` returns facility name, logo URL, recipients, and legal footer.
7. Time-series admin dashboard:
   - `GET /kpi/dashboard?days=&includeHistory=true`

## Cleanup Order

1. Remove default role and dev-only simulation APIs from production path.
2. Replace facility settings mocks: emergency contacts, billing, report metadata.
3. Replace social question bank with AWS-only data.
4. Replace staff/profile mocks.
5. Volunteer upload/share mocks were replaced in Patch 8; verify against deployed AWS.
6. Review backend mapper fallbacks and make missing fields visible.
7. Add tests that fail when new business mock strings are introduced.
