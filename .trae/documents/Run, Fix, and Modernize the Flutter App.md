## Overview
I inspected the Flutter project structure and code. It’s a cross‑platform Flutter app (Android/iOS/desktop/web folders present) using Provider for state, local SQLite via `sqflite`, and Firebase Messaging + local notifications. Below is a concrete plan to: run and verify, fix errors, update UI, migrate the database, and remove unused modules/files.

## Run & Verify
1. Install toolchain and dependencies:
   - `flutter pub get`
   - Android: ensure Android SDK/emulator; iOS: Xcode + a valid `GoogleService-Info.plist`.
   - Web/desktop: current code uses `dart:io` and mobile‑only plugins; running for web/desktop will fail until we adapt.
2. Run targets:
   - Android: `flutter run -d emulator` (or device). Verify Firebase init and notifications.
   - iOS: add `ios/Runner/GoogleService-Info.plist`, then `flutter run -d ios`.
3. Known issues to fix before/while running:
   - Compile error: `WidgetStateProperty` is invalid; should be `MaterialStateProperty` in DataTable heading color (lib/screens/admin/admin_dashboard_screen.dart:207).
   - Routes pass invalid defaults:
     - `'/verify-otp'` uses `VerifyOtpScreen(mode: '', email: null)` (lib/main.dart:122).
     - `'/reset-password'` uses `ResetPasswordScreen(email: '')` (lib/main.dart:124).
   - Web/desktop build errors:
     - `dart:io` imports used in multiple screens and helpers: add_complaint_screen.dart:1, teacher_home_screen.dart:3, staff_home_screen.dart:3, admin_dashboard_screen.dart:3, helpers/notification_helper.dart:3.
     - DB skip on web leads to `_db` uninitialized if any DB method is called (lib/helpers/db_helper.dart:14–18).
   - iOS Firebase missing config file (no `GoogleService-Info.plist` under `ios/Runner/`).
   - Android 13 notifications permission (`POST_NOTIFICATIONS`) missing in manifest; notifications won’t show without runtime permission.
   - Duplicate notification logic exists in both `helpers/notification_helper.dart` and `services/notification_service.dart`.

## UI Changes
1. Fix DataTable heading color API to `MaterialStateProperty.all(...)` (admin dashboard).
2. Remove dummy named routes for OTP/reset and enforce parameterized navigation via `MaterialPageRoute` only.
3. Unify theming using `ThemeData.from(colorScheme: ...)` with consistent input styles and button themes across light/dark modes.
4. Polish list items and empty states:
   - Ensure thumbnail fallbacks don’t rely on `dart:io` for web; gate with platform checks.
   - Add consistent spacing and typography for Teacher/Staff screens.
5. Add a reusable `AppScaffold` pattern (app bar actions: theme toggle, notifications, profile, logout) to DRY up screens.

## Database Changes
Option A — Migrate to Firebase Cloud Firestore (recommended to align with existing Firebase):
- Add `cloud_firestore` dependency and initialize alongside `firebase_core`.
- Create `lib/services/firestore_service.dart` with collections: `users`, `complaints`.
- Update providers to use Firestore:
  - `AuthProvider`: read/write users by email/id.
  - `ComplaintProvider`: CRUD complaints, queries by teacher/staff/status.
- Data model parity with current SQLite schema (`users`, `complaints`) plus timestamps and indexes.
- Remove `sqflite` usage after migration, or keep a simple offline cache if required.

Option B — Keep SQLite but modernize:
- Use `sqflite_common_ffi` for desktop, implement web support via `sqflite_common_ffi_web`.
- Initialize DB on non‑mobile platforms and avoid `_db` usage on web unless ffi web is wired.
- Add columns like `createdAt`, `updatedAt`, and add indexes on `complaints(status)`, `complaints(teacherId)`, `complaints(staffId)`.

## Cleanup Unused Modules/Files
1. Consolidate notifications:
   - Keep `helpers/notification_helper.dart`; remove duplicate `lib/services/notification_service.dart`.
2. Remove unused dependencies from `pubspec.yaml`:
   - `uuid`, `shared_preferences`, `sqflite_common_ffi_web` (unless we proceed with Option B web support).
3. Remove dummy named routes for OTP/reset from `MaterialApp.routes` to prevent misuse.
4. Optional (based on targets): if not targeting web/desktop, remove the `web/` icon scaffolding and desktop platform folders; otherwise, gate `dart:io` usage and adapt media previews.

## Android/iOS Platform Fixes
- Android: add `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>` in `android/app/src/main/AndroidManifest.xml` and request runtime permission on API 33+.
- iOS: add `GoogleService-Info.plist` and ensure `Firebase.initializeApp()` runs with correct options; request notification permissions (already present in NotificationHelper).

## Verification
- Build and run Android after code fixes; exercise login/register, complaint flow, notifications.
- Add a small widget test for `NotificationProvider` read/unread flows.
- Smoke test Firestore migration: seed sample users/complaints and validate Admin/Staff/Teacher views.

## Deliverables
- Fixed admin DataTable, route cleanup, unified theming.
- Database migration (Option A) or SQLite modernization (Option B) with providers updated.
- Removed duplicate modules and unused dependencies.
- Run results summary and screenshots/logs from the target devices.

Please confirm Option A (Firestore) vs Option B (SQLite), and target platforms (Android only vs also iOS/web/desktop). Once confirmed, I’ll implement the changes, run the app, and report verified results.