## Likely Causes
- Email confirmation enabled → sign up appears to succeed but login fails until email is confirmed.
- Profile row not inserted due to RLS → app defaults role to `teacher` or fails routing.
- Environment mismatch (.env keys, Supabase initialization) or missing error handling in UI leading to silent failures.

## Diagnostics (No Code Changes)
1. Supabase project:
   - Auth → Email confirmations: confirm emails for test accounts or disable during development.
   - SQL policies: confirm the following exist and use stored role:
     - `users_admin_all`, `complaints_admin_all` using `get_user_role(auth.uid()) = 'admin'`.
     - `users_self_insert` allows `auth_user_id = auth.uid()`.
     - `users_self_select` and `users_self_update` prevent non‑admin role changes.
   - Tables: check a sign‑up created an Auth user and a `users` row (id/auth_user_id == auth.uid())
     ```sql
     select id, auth_user_id, email, role from public.users where email = '<your email>';
     ```
2. .env:
   - `SUPABASE_URL` and `SUPABASE_ANON_KEY` are correct; app bundles `.env` as asset.
3. Emulator stability:
   - Cold boot the AVD, reduce RAM/heap, disable snapshots to prevent OOM/thread errors.

## App Fixes I Will Implement
1. Robust auth handling:
   - Wrap `signUp`/`signInWithPassword` in try/catch and surface `SupabaseAuthException.message` to the UI.
   - On `signUp` success, immediately upsert profile row with `{ id=auth.uid, auth_user_id=auth.uid, email, name, role }` (enabled by `users_self_insert`).
   - On `login`, fetch `users` by UUID; if missing, upsert profile with selected role from UI (once) and then route.
2. Routing:
   - Use stored role from `public.users` for Admin/Staff/Teacher dashboard selection; remove default to `teacher` when profile exists.
3. Complaints flow validation:
   - Teacher: create complaint (`reported_by = auth.uid`, `teacher_id = auth.uid`).
   - Admin: assign via Staff UUID; policy `complaints_assign_admin_only_update` permits.
   - Staff: update status to `needs_verification`.
4. UX:
   - Buttons show loading and re‑enable on error, with clear messages (invalid credentials, email confirmation required, network error).

## Verification Plan
- Register admin and staff; confirm `users` rows exist and roles are stored.
- Login as admin → land on Admin dashboard; create and assign complaint to staff UUID; login as staff → see assigned and update status.
- Share emulator logs and confirm Supabase rows for users/complaints.

If you approve, I will implement the auth fixes, run on the emulator, and iterate until signup/login and complaint flow work cleanly.