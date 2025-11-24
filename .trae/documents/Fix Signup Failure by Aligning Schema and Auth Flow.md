## Diagnosis
- Current app code writes `public.users` with fields `id` (Supabase Auth UUID), `auth_user_id`, `created_at`, `updated_at` and expects snake_case.
- Local schema defines camelCase and bigint identity: `createdAt`, `updatedAt`, `id bigint`, and includes a `password` column. See `supabase/schema.sql:1–9`.
- Mismatches cause upsert errors in `lib/services/supabase_service.dart:13–33` and lead to the generic “Signup failed” returned by `lib/providers/auth_provider.dart:46–56`.

## Database Changes (align to app)
1. Users table (UUID + snake_case):
   - Change `id` to `uuid primary key` and add `auth_user_id uuid unique`.
   - Drop `password` column (use Supabase Auth only).
   - Rename `createdAt` → `created_at`, `updatedAt` → `updated_at`.
   - Update trigger to set `updated_at` instead of `"updatedAt"`.
2. Complaints table:
   - Rename fields to snake_case: `mediaPath` → `media_path`, `mediaIsVideo` → `media_is_video`, `teacherId` → `teacher_id`, `staffId` → `staff_id`, `createdAt/updatedAt` → `created_at/updated_at`.
   - Change `teacher_id` and `staff_id` to `uuid` referencing `users(id)`.
   - Add `reported_by uuid` (set via app or trigger) to support RLS.
3. Indexes and policies:
   - Recreate indexes using snake_case columns.
   - Ensure RLS policies use `auth.uid()` and stored role helpers consistently (as previously discussed).

## App Changes
1. Surface precise error messages:
   - In `lib/providers/auth_provider.dart`, catch `SupabaseAuthException` and display `e.message`; catch `PostgrestException` for upsert failures and show its `message`.
2. Upsert profile after signup:
   - Continue using `upsertUserFromAuth` with `onConflict: 'id'` after switching DB to UUID `id`. Code is in `lib/services/supabase_service.dart:13–33`.
3. Ensure mapping consistency:
   - `User.toMap()` and `Complaint.toMap()` already use snake_case (`lib/models/user_model.dart:21–29`, `lib/models/complaint_model.dart:20–32`). No changes needed once DB is aligned.

## Verification
- Confirm Supabase project schema matches the UUID/snake_case design (run migration in SQL editor).
- Disable email confirmation in Auth if testing immediate sign-in.
- Run the app, test signup with a new email, and verify:
  - Auth user created (Supabase Auth → Users list) and session returned.
  - Row inserted/updated in `public.users` with `id = auth.uid()` and correct `role`.
- Create a complaint from teacher, ensure insert succeeds and row visible; as admin, update assignment and verify RLS behavior.

## Notes
- If you prefer to keep bigint/camelCase, we’ll instead refactor app code to match that schema (stop writing `auth_user_id`, avoid setting `id`, write camelCase names). UUID alignment is recommended for mobile apps using Supabase Auth.
- After confirmation, I will apply the migration SQL and adjust any remaining code paths to surface full error messages, then run the emulator to validate end-to-end.