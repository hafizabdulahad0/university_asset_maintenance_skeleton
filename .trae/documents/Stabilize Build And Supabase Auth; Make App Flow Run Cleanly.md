## Issues To Fix
- Android build: AAR metadata required AGP ≥ 8.9.1; Gradle wrapper needed 8.11.1. Remove Firebase Messaging plugin/deps to simplify.
- Auth errors: PKCE storage required → switch to `supabase_flutter`. Add robust error handling to login/signup; ensure UUID-based schema and snake_case fields match service calls.
- Flow alignment: Admin/staff/teacher screens must use UUIDs and Supabase reads/writes; remove OTP/notifications references.

## Implementation Steps
### 1) Build/Config Cleanup
- Confirm `android/settings.gradle.kts` uses: `com.android.application` 8.9.1 and Kotlin 2.1.0.
- Confirm `android/gradle/wrapper/gradle-wrapper.properties` is `gradle-8.11.1-all.zip`.
- In `android/app/build.gradle.kts`, remove `com.google.gms.google-services` plugin and Firebase dependencies; keep desugaring only.
- In `pubspec.yaml`, ensure `supabase_flutter` is added and `.env` is an asset; keep `flutter_dotenv`.

### 2) Supabase Client & Auth
- `lib/core/supabase_client.dart`: initialize with `Supabase.initialize(url, anonKey)` from `.env`.
- `AuthProvider`:
  - Login: `supabase.auth.signInWithPassword`, catch errors; on success, load `users` row by `id` (UUID) or create a local in-memory profile with default role `teacher` for routing.
  - Register: `supabase.auth.signUp`, catch errors; show success snackbar and redirect to login. (Profile upsert by admin later due to RLS.)
  - Change password: use `supabase.auth.updateUser(UserAttributes(password: newPass))`; show error if fails.
- Remove OTP flow entirely in Forgot/Reset screens; Reset uses `supabase.auth.updateUser` for logged-in user, or `resetPasswordForEmail` for email.

### 3) Models & Services
- `User` model: `id: String?`, fields `name`, `email`, `role`, `created_at`, `updated_at` (snake_case mapping).
- `Complaint` model: UUIDs for `teacher_id`, `staff_id`, `reported_by`; snake_case mapping; `media_is_video: bool`.
- `SupabaseService`:
  - `getUserByEmail`, `getUserById(String)`.
  - `insertComplaint` sets `reported_by = auth.uid` and writes snake_case fields.
  - Query helpers accept UUIDs and return mapped complaints.

### 4) Screens
- Login/Register: add try/catch and UI feedback (error SnackBars, button re-enable); ensure navigation after success.
- Admin Dashboard: use `SupabaseService.getAllComplaints` and `updateComplaint`; assignment expects Staff UUID.
- Staff Home: use Supabase service to load unassigned/assigned lists; `updateComplaint` to change status.
- Teacher Home/Add Complaint: create complaints with `teacher_id = auth.uid`.
- Remove Notification/FCM usage from `main.dart`; keep `MultiProvider` without Notification lifecycle hooks.

### 5) Verification
- Emulator: run `flutter pub get` then `flutter run -d emulator`.
- Create new account via Register, then Login.
- Teacher: create complaint, confirm it appears.
- Admin: assign with a Staff UUID (create staff user via Register or Supabase Dashboard), confirm status updates.
- Staff: mark assigned complaint to `needs_verification`, verify lists update.
- Share runtime logs confirming success and the routes.

## Notes
- With RLS policies, profile rows are admin-managed; app routes based on a default or existing role. I’ll default to `teacher` until admin sets roles.
- If you want automated role assignment at signup, I can add a secured RPC later.

## After You Confirm
- I’ll finalize the auth handlers, run on the emulator, and send the logs/screens showing teacher→admin→staff flow working without messaging.