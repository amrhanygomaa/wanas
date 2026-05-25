# Raaya / Taptaba Flutter App

Flutter application for elderly-care operations, family communication, volunteer workflows, and facility administration. The app is wired to the AWS-backed Raaya API at `https://api.helpers-tech.com` by default.

## What Is Included

- Cognito-backed login/register/admin bootstrap.
- Facility, residents, medications, nursing, family bridge, volunteer, social specialist, and admin screens.
- AWS API clients for sync, mutations, media uploads, settings, video calls, user state, and AI companion flows.
- Firebase Messaging for Android push notifications.
- Android package id `com.raaya.taptaba` with release signing loaded from local/CI secrets.

## Repository Layout

- `lib/` Flutter app code.
- `lib/services/` AWS/Firebase/API service clients.
- `lib/providers/app_riverpod.dart` current app state and sync orchestration.
- `docs/` backend contract, mock audit, and agent work plan.
- `external/raaya-backend/` local clone of the backend repo, ignored by git.
- `android/key.properties.example` release signing template.

## Requirements

- Flutter stable with Dart 3.
- Android Studio / Android SDK for Android builds.
- A reachable Raaya backend.
- Firebase config files for target platforms.

## Setup

```bash
flutter pub get
flutter analyze
flutter test
```

The API base URL and Cognito values are currently in `lib/config/api_config.dart`.

For first-admin registration, pass the backend bootstrap secret at build/run time:

```bash
flutter run --dart-define=ADMIN_REG_SECRET=your-admin-setup-secret
```

## Android

Debug build:

```bash
flutter build apk --debug
```

Release signing uses either `android/key.properties` or CI environment variables:

```properties
storeFile=C:/path/to/raaya-release.jks
storePassword=...
keyAlias=raaya-release
keyPassword=...
```

Equivalent CI variables:

- `ANDROID_KEYSTORE_PATH`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

Never commit real keystores or `android/key.properties`.

## Backend

Backend work for the missing AWS contracts is tracked in:

- `docs/backend-contract.md`
- `docs/backend-gap-analysis.md`
- `docs/mock-audit.md`
- `docs/agent-work-plan.md`

When backend migrations are deployed, run the app against the same API environment and verify login, sync, media upload, volunteer share links, staff reviews, and resident audit trails.

## Verification Used In This Workspace

```bash
flutter analyze
flutter test
flutter build apk --debug
```

For the backend clone:

```bash
cd external/raaya-backend
npm run build
npm test -- --runTestsByPath src/residents/residents.controller.spec.ts src/admin-management/admin-management.controller.spec.ts
```
