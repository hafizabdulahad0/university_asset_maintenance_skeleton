## UI Goals
- Apply a cohesive gradient aesthetic across all screens.
- Modernize theme with Material 3, seed color palettes, and consistent components.
- Add tasteful, performant animations: transitions, card entrances, list item motion, button hover/press effects.
- Keep Android performance smooth; enable hover effects for web/desktop using `MouseRegion`.

## Design System Updates (Global)
- `lib/main.dart`:
  - Use `ColorScheme.fromSeed` for light/dark from a core brand seed and supporting seeds (teal/indigo/purple) to drive gradients.
  - Normalize components: `elevatedButtonTheme`, `outlinedButtonTheme`, `inputDecorationTheme`, `cardTheme`.
  - Set `PageTransitionsTheme` for smoother screen transitions.
  - Keep `AnimatedSwitcher` in `AuthWrapper` to animate role-based routing (`lib/main.dart:149–171`).
- Add a reusable `GradientScaffold` (new file):
  - Props: `gradient`, `appBar`, `body`, optional `floatingActionButton`.
  - Handles `extendBodyBehindAppBar`, safe area, and consistent padding.
  - Encapsulates hover effects with a `HoverScale` widget for buttons/cards.

## Screen-by-Screen Updates
- Home (`lib/screens/home_screen.dart`):
  - Wrap with `GradientScaffold` using brand gradient.
  - Keep pulsing icon, increase subtle motion with `AnimatedOpacity` and stagger.
- Auth:
  - Login (`lib/auth/login_screen.dart`): gradient background, scale-in card, hover on action buttons.
  - Register (`lib/auth/register_screen.dart`): same as Login for consistency; animate in form card and CTA.
  - Forgot/Reset/Change Password (`lib/auth/forgot_password_screen.dart`, `lib/auth/reset_password_screen.dart`, `lib/auth/change_password_screen.dart`): unify with `GradientScaffold`, slide/scale entrance.
  - Profile (`lib/auth/profile_screen.dart`): gradient header, animated save button, hover elevation on `Card`.
- Notifications (`lib/screens/notifications_screen.dart` + `lib/widgets/notification_badge.dart`):
  - Animate list items on first build (`TweenAnimationBuilder` with offset/opacity), hover raise on tiles.
- Dashboards:
  - Admin (`lib/screens/admin/admin_dashboard_screen.dart`), Staff (`lib/screens/staff/staff_home_screen.dart`), Teacher (`lib/screens/teacher/teacher_home_screen.dart`):
    - Gradient header bar, animated sections/cards, hover effects.
    - Use `AnimatedSwitcher` for tab/panel changes.
- Add Complaint (`lib/screens/teacher/add_complaint_screen.dart`):
  - Gradient, animated media preview, hover on pick buttons.

## Animations & Interactions (No new dependencies)
- Implicit animations: `AnimatedContainer`, `AnimatedOpacity`, `TweenAnimationBuilder`, `AnimatedScale`.
- Transitions: `AnimatedSwitcher`, theme `PageTransitionsTheme`.
- Hover effects: `MouseRegion` + `Transform.scale` in a small utility `HoverScale`; `InkWell` for ripple.
- Micro-interactions: button press elevation/scale, card shadow changes on hover.

## Implementation Notes
- Keep changes internal to UI composition; no backend changes yet.
- Avoid adding external animation libraries; rely on Flutter SDK only.
- Maintain app routing and provider setup; ensure notification buffer flush remains after providers exist (`lib/main.dart:92–105`).

## Verification
- `flutter analyze` and widget smoke test.
- Run on Android emulator; verify gradients/animations across screens.
- Optional: run on Chrome to validate hover behavior for web (not primary target).

## Supabase Preparation (Next)
- What I need from you:
  - `SUPABASE_URL`
  - `SUPABASE_ANON_KEY`
  - Confirm tables (Postgres) and bucket names, or allow me to create:
    - `users`: `id`, `name`, `email` (unique), `role`, `created_at`, `updated_at` (if using Supabase Auth, passwords are not stored here).
    - `complaints`: `id`, `title`, `description`, `media_path`, `media_is_video` (bool), `status`, `teacher_id`, `staff_id`, `created_at`, `updated_at`.
    - Storage bucket: `complaint-media` (public or signed URLs; we’ll store URL in `media_path`).
- Planned integration steps:
  1. Add `supabase_flutter` and initialize a client file with your URL/key.
  2. Create `SupabaseService` mirroring `DBHelper` (lib/helpers/db_helper.dart:10–78 and methods at 83–181).
  3. Swap providers to use Supabase gradually (list, create, update complaints; users lookups).
  4. Keep FCM for notifications initially; consider Supabase Realtime later for live updates.

If you approve, I will implement the gradient + animation overhaul across all screens, verify on Android, and then request your Supabase credentials to proceed with the database migration.