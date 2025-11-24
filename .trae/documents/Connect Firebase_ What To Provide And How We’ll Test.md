## What I Need From You
- Android config file: `google-services.json` placed at `android/app/google-services.json`.
- (Optional) iOS config: `GoogleService-Info.plist` at `ios/Runner/GoogleService-Info.plist` if you want iOS.
- Firebase project details: Project ID and default region (for reference).
- Enable products in Firebase Console:
  - Cloud Firestore (Production or Test mode)
  - Firebase Storage
  - Firebase Cloud Messaging (already in use)
  - (Optional) Firebase Auth → enable Email/Password if you want secure auth
- Firestore rules (initial testing):
  - For quick testing, permissive rules are fine; for production we’ll lock to `request.auth != null`.
- Storage rules (initial testing):
  - Allow read to all and write to authenticated users during testing; tighten later.

## Collections and Fields (I’ll create or use existing)
- `users` documents (id as string):
  - `id` (int stored as string doc id), `name`, `email`, `password` (or remove when using `firebase_auth`), `role`, `createdAt`, `updatedAt`
- `complaints` documents (id as string):
  - `id`, `title`, `description`, `mediaPath` (URL), `mediaIsVideo` (bool), `status` (`unassigned` | `assigned` | `needs_verification` | `closed`), `teacherId`, `staffId`, `createdAt`, `updatedAt`
- Indexes:
  - For `complaints` queries with two filters, add a compound index on `staffId` + `status` (Firestore will show a link to create it the first time; I can configure it once you confirm).

## What I Will Do
- Wire `FirestoreService` (already prepared) into providers for users and complaints.
- Keep FCM working; no change needed to push setup.
- Optionally migrate to `firebase_auth`:
  - If you approve, I’ll switch `AuthProvider` to use secure email/password auth and stop saving `password` in Firestore.
- Ensure Storage uploads for complaint media and store download URLs in `mediaPath`.

## Verification Plan
- Windows prerequisite: enable Developer Mode for plugin symlink support (`start ms-settings:developers`).
- Run `flutter pub get`, `flutter analyze`, and launch on Android emulator.
- Create test data:
  - Register a user, create a complaint, assign/update status, verify list queries work.
- Validate Firestore writes/reads and Storage uploads; share logs and visible UI behavior.

## Send Me
- The `google-services.json` file
- (Optional) `GoogleService-Info.plist`
- Confirmation to enable Firebase Auth (yes/no)
- Confirm if you want Android-only or also iOS/web

Once you share those, I’ll run the app, seed sample data, and we’ll test the database end-to-end.