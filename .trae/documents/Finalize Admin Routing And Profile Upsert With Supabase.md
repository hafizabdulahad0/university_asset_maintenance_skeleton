## What You’ve Done
- Applied `complaints_assign_admin_only_update` with `get_user_role(auth.uid()) = 'admin'` — great. Admins can update/assign complaints.

## Remaining Changes (SQL)
- Ensure admin checks use stored role everywhere, not JWT claim:
  - `users_admin_all` and `complaints_admin_all` should use:
    ```sql
    drop policy if exists users_admin_all on public.users;
    create policy users_admin_all
      on public.users
      for all
      using ((select public.get_user_role((select auth.uid()))) = 'admin')
      with check ((select public.get_user_role((select auth.uid()))) = 'admin');

    drop policy if exists complaints_admin_all on public.complaints;
    create policy complaints_admin_all
      on public.complaints
      for all
      using ((select public.get_user_role((select auth.uid()))) = 'admin')
      with check ((select public.get_user_role((select auth.uid()))) = 'admin');
    ```
- Allow each user to insert their own profile row (one-time):
  ```sql
  drop policy if exists users_self_insert on public.users;
  create policy users_self_insert
    on public.users
    for insert
    with check ((select auth.uid()) is not null and auth_user_id = (select auth.uid()));
  ```
- Keep self-select and self-update (prevent role changes by non-admins):
  ```sql
  drop policy if exists users_self_select on public.users;
  create policy users_self_select
    on public.users for select
    using ((select auth.uid()) = auth_user_id);

  drop policy if exists users_self_update on public.users;
  create policy users_self_update
    on public.users for update
    using ((select auth.uid()) = auth_user_id)
    with check ((select public.get_user_role((select auth.uid()))) = 'admin'
                or public.is_proposed_role_same_as_stored(auth_user_id, role));
  ```

## App Adjustments Needed
- On successful signup/login, upsert a `users` profile row with:
  - `id = auth.uid`, `auth_user_id = auth.uid`, `email`, `name`, and the selected `role` from the Register screen.
- Login should then load the profile by UUID and route to Admin/Staff/Teacher accordingly (no defaulting to teacher).
- Admin Dashboard “Assign” must accept Staff UUIDs (Auth user ID).

## Verification Steps
- Create an admin via the app → confirm a `users` row exists (UUID matches Auth user ID) with `role='admin'`:
  ```sql
  select id, auth_user_id, role from public.users where email = '<your admin email>';
  select public.get_user_role((select auth.uid()));
  ```
- Login as admin → land on Admin Dashboard.
- Create a staff account; copy its UUID from Auth → assign a complaint to that staff in the Admin screen.
- Login as staff → see assigned complaints; update status to `needs_verification`.

## Notes
- If email confirmation is enabled in Supabase Auth, confirm emails before login for testing or disable confirmation during development.
- After these changes, the app will route based on the stored `role` and the complaint flow will work end-to-end without messaging.