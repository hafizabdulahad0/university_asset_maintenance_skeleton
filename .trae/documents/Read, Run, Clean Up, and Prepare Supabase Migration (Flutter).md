## Project Overview
- Flutter app targeting Android, iOS, macOS, and Web.
- Local data stored with `sqflite`; schema and CRUD in `lib/helpers/db_helper.dart` (e.g., insert user at lib/helpers/db_helper.dart:84).
- Push notifications via Firebase Cloud Messaging (FCM) and `flutter_local_notifications`; init in `lib/helpers/notification_helper.dart` and `lib/main.dart` (Firebase init at lib/main.dart:41, FCM background handler at lib/main.dart:31).
- State management with `provider`; auth and domain state in `lib/providers/*` (e.g., login at lib/providers/auth_provider.dart:18).
- Media attachments using `image_picker` in `lib/screens/teacher/add_complaint_screen.dart` (picker use at lib/screens/teacher/add_complaint_screen.dart:25).

## What I Will Do First
1. Validate toolchain on Windows:
   - `flutter --version`, `flutter doctor -v`, `flutter devices`.
2. Install dependencies and run checks:
   - `flutter pub get`, `flutter analyze`, `flutter test -r compact`.
3. Run the app on Android (recommended):
   - Ensure an emulator or physical device is available.
   - `flutter run -d emulator` (or `flutter run -d <device_id>`).
   - Verify login/register/OTP, complaint creation, and notifications.
4. Optional Web run:
   - `flutter run -d chrome` may fail because web needs explicit `FirebaseOptions`; I will prioritize Android and report web feasibility.

## Clean-Up Plan (Unnecessary Libraries/Files)
- Dependencies in `pubspec.yaml` are currently used:
  - `provider`, `sqflite`, `path` used by data/state layers.
  - `firebase_core`, `firebase_messaging`, `flutter_local_notifications` used for notifications.
  - `image_picker` used in complaint creation.
- I will:
  - Scan for any dead code or unused imports and remove them.
  - Keep platform directories (`android`, `ios`, `macos`, `web`) unless you confirm target platforms to drop.
  - Keep `android/app/google-services.json` (required for FCM) and flag missing iOS plist.
  - Produce a short report of anything safe to remove/rename.

## Supabase Migration Plan
1. Add Supabase SDK:
   - Add `supabase_flutter` to `pubspec.yaml`.
   - Initialize in a new `lib/core/supabase_client.dart` with your `SUPABASE_URL` and `SUPABASE_ANON_KEY`.
2. Data schema mapping (Postgres):
   - `users` table: `id`, `name`, `email` (unique), `password` (or migrate to Supabase Auth), `role`, `created_at`, `updated_at`.
   - `complaints` table: `id`, `title`, `description`, `media_path`, `media_is_video`, `status`, `teacher_id`, `staff_id`, `created_at`, `updated_at`.
3. Service layer replacement:
   - Create `lib/services/supabase_service.dart` mirroring `DBHelper` methods using PostgREST queries (e.g., `insertUser`, `getUserByEmail`, `insertComplaint`, `getAllComplaints`).
   - Gradually swap `DBHelper` calls in providers with the Supabase service.
4. Auth strategy:
   - Option A (minimal change): keep current local auth and only move data to Supabase.
   - Option B (recommended): adopt Supabase Auth (email/password), update `AuthProvider` to use `supabase.auth.signInWithPassword` and `signUp`; passwords no longer stored in our table.
5. Media storage:
   - Upload picked images/videos to a Supabase Storage bucket, store public paths/URLs in `complaints.media_path`.
6. Realtime/notifications:
   - Keep FCM for device-native notifications initially.
   - Optionally add Supabase Realtime subscriptions to update admin/staff views live.
7. Migration approach:
   - Start with read-only lists from Supabase.
   - Move writes (create/update complaints) next.
   - Migrate auth last (if choosing Option B).

## Verification
- After each step, run on Android and verify flows.
- Add basic widget tests for providers where practical.
- Provide logs and any fixes required (e.g., Android SDK/JDK versions set per android/app/build.gradle.kts:30–37).

## Prerequisites I’ll Check
- Flutter SDK on PATH, Android Studio SDK/emulator, JDK 11 per Gradle config.
- Firebase Android config already present (`android/app/google-services.json`). iOS/web configs are out of scope for initial Android run.

## What I Need From You (later)
- Supabase project URL and anon key.
- Clarify target platforms to keep (Android-only vs. multi-platform).

If you approve, I will run the commands, report results with logs, then proceed with clean-up and begin the Supabase migration foundation.