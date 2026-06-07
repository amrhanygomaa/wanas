# ونس (Wanas)

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B.svg?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%3E%3D3.0-0175C2.svg?logo=dart)](https://dart.dev)
[![Riverpod](https://img.shields.io/badge/State-Riverpod_2.5-4c2bd9.svg)](https://riverpod.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> نظام شامل لإدارة دور رعاية المسنين — Arabic-first, RTL mobile application that connects
> elderly residents, their families, and the entire care team in one platform.

---

## Overview

Wanas delivers a tailored experience for **six distinct roles**, each with its own dashboard,
navigation, and feature set:

| Role | Arabic | Primary focus |
|------|--------|---------------|
| Elderly | المسن | Home screen, medications, AI companion, voice calls, memories, activities |
| Family | الأسرة | Resident dashboard, shared media, family communication, reminders |
| Nurse | الممرض | Shift operations, medication administration, care tasks, handoff reports |
| Specialist | الأخصائي | GDS assessments, activity coordination, complaints, KPI reports |
| Volunteer | المتطوع | Profile, scheduling, assignments |
| Admin | الإدارة | Facility settings, resident management, staff accounts, billing, audit log |

### Features

- **AI Companion** — voice-driven check-ins via AWS Bedrock (`/ai/chat`) with persistent memory stored in DB, TTS (`flutter_tts`) and STT (`speech_to_text`)
- **Emergency SOS** — one-tap SOS trigger/cancel/resolve with real-time notification to the care team (`/emergency/sos`)
- **Medication Management** — reminders scheduled via `flutter_local_notifications` + timezone, adherence tracking
- **Family Bridge** — shared memories/albums, real-time updates, family activity participation
- **Real-time Updates** — Socket.IO (`socket_io_client`) on `/realtime` driving 7 live banner types
- **Video Calls** — Zoom integration via `/video-calls`
- **Reports & PDF** — generate and print care reports with `pdf` + `printing`
- **GDS Assessments** — geriatric depression scale questionnaire with backend sync
- **Secure Auth** — AWS Cognito (direct HTTPS, no SDK), biometric unlock (`local_auth`), JWT stored in `flutter_secure_storage`
- **Push Notifications** — Firebase Cloud Messaging + local scheduling
- **Dark Mode & Font Scale** — accessibility-first with persistent user preferences

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x · Dart ≥ 3.0 |
| State | `flutter_riverpod` ^2.5.1 (ChangeNotifier pattern) |
| Backend | [raaya-backend](https://github.com/amrhanygomaa/raaya-backend) — NestJS REST + WebSocket |
| Auth | AWS Cognito (InitiateAuth/RefreshToken) + `flutter_secure_storage` ^10.0 + `local_auth` ^2.3 |
| Realtime | `socket_io_client` ^2.0.3 |
| Push | `firebase_messaging` ^15.1 + `firebase_core` ^3.6 |
| Voice / AI | `flutter_tts` ^4.2 · `speech_to_text` ^7.3 · `audioplayers` ^6.4 · `record` ^6.2 |
| Media | `image_picker` ^1.0 · `photo_manager` ^3.9 · `photo_manager_image_provider` ^2.2 |
| PDF | `pdf` ^3.12 · `printing` ^5.14 |
| Animations | `flutter_animate` ^4.5 · `lottie` ^3.1 · `shimmer` ^3.0 |
| Font | Cairo (9 weights 200–900, Arabic, RTL) |
| HTTP | `http` (pinned 1.x) — unified via `ApiClient` with JWT Bearer |
| Contacts | `flutter_contacts` 1.1.9 |
| Notifications | `flutter_local_notifications` ^17.1 + `timezone` ^0.9 |
| Config | `String.fromEnvironment` / `--dart-define-from-file` (no runtime .env) |

---

## Project Structure

```
lib/
├── main.dart                  # Entry point — role-based routing + theme
├── nav_wrapper.dart           # Bottom-nav shell for the Elderly role
├── config/
│   └── api_config.dart        # Base URL, Cognito pool IDs (compile-time constants)
├── models/
│   └── app_models.dart        # All domain models (20+ classes)
├── providers/
│   ├── app_riverpod.dart            # AppRiverpod class — fields, constructor, core
│   ├── app_riverpod_memories.dart   # Albums & memories domain
│   ├── app_riverpod_facility.dart   # Billing, audit trail, call history
│   ├── app_riverpod_residents_family.dart  # Display prefs, family activities
│   ├── app_riverpod_staff_reports.dart     # Staff performance, medical sessions
│   ├── app_riverpod_nursing_ops.dart       # Nursing ops, care tasks, inventory
│   ├── app_riverpod_family_reminders.dart  # Family medication reminders
│   ├── app_riverpod_assessments.dart       # GDS assessments
│   ├── app_riverpod_memory_wall.dart       # Family memory wall
│   ├── app_riverpod_elderly_media.dart     # Gallery, media, elderly tabs
│   ├── app_riverpod_auth_accounts.dart     # Auth, registration, session management
│   └── app_riverpod_activities_ai_emergency.dart  # Activities, AI insights, SOS
├── services/                  # API clients and feature services
│   ├── api_client.dart        # Unified HTTP client (JWT Bearer)
│   ├── auth_service.dart      # Cognito login / refresh / restore
│   ├── backend_sync_service.dart       # Pulls 30+ endpoints post-login
│   ├── backend_mutation_service.dart   # 40+ create / update / delete calls
│   └── ...                    # 20+ additional feature services
├── widgets/                   # Shared UI components (SOS, AI chat, drawer…)
└── screens/
    ├── admin/        # Facility management, staff, billing, settings
    ├── auth/         # Login screen
    ├── common/       # Shared across roles
    ├── elderly/      # Elderly resident screens
    ├── family/       # Family dashboard and features
    ├── nurse/        # Nurse operations
    ├── onboarding/   # Splash + onboarding flow
    ├── specialist/   # Assessments, activities, KPIs
    └── volunteer/    # Volunteer profile and scheduling
```

> The 6 700-line god-file has been split into 11 domain `part`-file extensions. All fields and
> the constructor stay in `app_riverpod.dart`; method groups live in their domain files. Zero
> consumer import changes — consumers still `import 'providers/app_riverpod.dart'`.

---

## Quick Start

### Prerequisites

- Flutter SDK ≥ 3.0.0 and Dart SDK ≥ 3.0.0
- Android Studio (for emulator/device) — app is portrait-only on Android
- A running [raaya-backend](https://github.com/amrhanygomaa/raaya-backend) instance (or use the hosted API at `https://api.helpers-tech.com`)

### Installation

```bash
git clone https://github.com/amrhanygomaa/Wesal.git
cd Wesal
flutter pub get
flutter run
```

### Configuration

Configuration is injected at **compile time** via `--dart-define` or `--dart-define-from-file`.
No `.env` file is read at runtime. Copy the example and fill in your values:

```bash
cp dart_defines.example.json dart_defines.json   # git-ignored
```

| Key | Description | Default |
|-----|-------------|---------|
| `API_BASE_URL` | Backend base URL | `https://api.helpers-tech.com` |
| `ADMIN_REG_SECRET` | Secret for registering the first admin of a new facility | _(empty)_ |
| `FACILITY_ID` | Default facility ID for single-tenant builds | _(empty)_ |

Run with a dart-define file:

```bash
flutter run --dart-define-from-file=dart_defines.json
```

Or pass individually:

```bash
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:3000 \
  --dart-define=ADMIN_REG_SECRET=your-secret
```

> **Firebase:** `lib/firebase_options.dart` holds standard client-side config generated by
> `flutterfire configure`. Push notifications require `google-services.json` (Android) and/or
> `GoogleService-Info.plist` (iOS) — these are **not** committed.
> See [Firebase Flutter setup](https://firebase.flutter.dev/docs/overview).

### Build for release

```bash
flutter build apk --release --dart-define-from-file=dart_defines.json
flutter build appbundle --release --dart-define-from-file=dart_defines.json
flutter build ios --release --dart-define-from-file=dart_defines.json   # macOS only
```

---

## Testing & Quality

```bash
flutter analyze              # Static analysis (0 issues on clean tree)
flutter test                 # Unit + widget tests
flutter test --coverage      # With coverage report
```

CI runs `flutter analyze` + `flutter test` on every push and pull request
(see [`.github/workflows/flutter-ci.yml`](.github/workflows/flutter-ci.yml)).

---

## API Integration

Wanas talks exclusively to the [raaya-backend](https://github.com/amrhanygomaa/raaya-backend)
NestJS API — 0% mock data. See that repository's Swagger UI at `/api/docs` for the full
endpoint reference.

Highlights of what's integrated:

- Auth: Cognito login/refresh + `/auth/register-admin`
- Residents, medications, activities, complaints, visits, memories, volunteers, social assessments
- AI chat + memory via AWS Bedrock (`/ai/chat`, `ai_resident_memory` DB table)
- Emergency SOS (`/emergency/sos`)
- Family ↔ specialist messaging (`/messages`)
- Push notification tokens (`/notifications/push-tokens`)
- Video calls via Zoom (`/video-calls`)
- Health vitals, alerts, thresholds
- Real-time banners via Socket.IO (`/realtime`)
- Admin facility settings (emergency contacts, billing, facility profile)

---

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for branching strategy, commit conventions,
and the PR checklist. By participating you agree to the [Code of Conduct](CODE_OF_CONDUCT.md).

---

## License

Licensed under the MIT License — see [LICENSE](LICENSE) for details.
