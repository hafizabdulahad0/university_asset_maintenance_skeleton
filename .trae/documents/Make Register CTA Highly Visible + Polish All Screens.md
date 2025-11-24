## Register CTA Visibility
- Create a reusable `GradientButton` (rounded, bright gradient, ripple, focus ring) to make key actions pop.
- Replace the Login screen "Register" TextButton with `GradientButton` (Login screen: lib/auth/login_screen.dart:120–131) and give it a teal→violet gradient for strong contrast on both themes.
- Optionally, switch the Register screen primary CTA ("Send OTP & Register") to `GradientButton` for consistent visibility (lib/auth/register_screen.dart:128–141).

## Global Theme Refinements
- Update `lib/main.dart` theme to include Material 3 button themes:
  - `FilledButtonThemeData` (primary actions) and `OutlinedButtonThemeData` (secondary), tuned to the seed color.
  - Slightly brighten `colorScheme.primary` and harmonize `secondary` for better gradient blend.
- Keep `PageTransitionsTheme` and input/card shapes already set; only refine colors and button contrast.

## Screen-by-Screen Polishing
- Login/Register:
  - Apply `GradientButton` to key CTAs; keep card scale-in animation for polish.
  - Add small icon accents in headings for identity.
- Forgot/Reset/Change Password:
  - Use `GradientButton` for primary actions.
  - Ensure spacing and typography match the refreshed style.
- Profile:
  - Accent the "Save Changes" button with a tonal or gradient style; keep outlined "Change Password" as secondary.
- Dashboards (Admin/Staff/Teacher):
  - Use accent-colored `ElevatedButton` or `GradientButton` for important actions (Assign/Verify/Take Up/Mark Done).
  - Keep `HoverScale` on cards; add subtle section headers with gradient underline.
- Notifications:
  - Keep hover motion; increase tile selected/hover feedback with slight elevation and accent border.
- Add Complaint:
  - Use `GradientButton` for the submit CTA; make media pick buttons use bright `OutlinedButton` with accent border.

## Implementation Notes
- `GradientButton` will be a pure-UI widget using `Ink` + `Container` with shader gradient, `InkWell` for ripple, rounded corners, and disabled/pressed states.
- No new packages; just Flutter SDK.
- Match contrast ratios for accessibility; ensure text is readable over gradients.

## Verification
- Run `flutter analyze` and the widget smoke test.
- Re-run on Android emulator; visually confirm CTAs are prominent and styles consistent.

## Supabase (next)
- After UI polish, connect Supabase. Provide:
  - `SUPABASE_URL`
  - `SUPABASE_ANON_KEY`
  - Confirm table names/bucket or accept defaults:
    - Tables: `users`, `complaints`
    - Bucket: `complaint-media`
- I’ll integrate `supabase_flutter`, add a client, implement `SupabaseService` mirroring `DBHelper`, then swap providers incrementally.