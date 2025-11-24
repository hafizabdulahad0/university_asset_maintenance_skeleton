create extension if not exists pgcrypto;

-- Admin helper function to avoid RLS recursion
create or replace function public.is_admin(p_uid uuid)
returns boolean
language sql
security definer
set search_path = 'public'
stable
as $$
  select exists(
    select 1 from public.users u
    where u.id = p_uid and u.role = 'admin'
  );
$$;

-- Ensure privileged owner and execution permissions
alter function public.is_admin(uuid) owner to postgres;
grant execute on function public.is_admin(uuid) to authenticated, anon;

create table if not exists public.users (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid unique,
  name text not null,
  email text not null unique,
  role text not null check (role in ('admin','staff','teacher')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.complaints (
  id bigint generated always as identity primary key,
  title text not null,
  description text not null,
  media_path text,
  media_is_video boolean not null default false,
  status text not null check (status in ('unassigned','assigned','needs_verification','closed')),
  teacher_id uuid not null references public.users(id) on delete cascade,
  staff_id uuid references public.users(id),
  reported_by uuid references public.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end;$$;

drop trigger if exists users_set_updated on public.users;
create trigger users_set_updated before update on public.users
for each row execute procedure public.set_updated_at();

drop trigger if exists complaints_set_updated on public.complaints;
create trigger complaints_set_updated before update on public.complaints
for each row execute procedure public.set_updated_at();

alter table public.users enable row level security;
alter table public.complaints enable row level security;

drop policy if exists users_select_all on public.users;
drop policy if exists users_insert_all on public.users;
drop policy if exists users_update_all on public.users;
drop policy if exists users_self_select on public.users;
drop policy if exists users_self_insert on public.users;
drop policy if exists users_self_update on public.users;
drop policy if exists users_admin_all on public.users;

create policy users_self_select on public.users
for select using (id = auth.uid() or auth_user_id = auth.uid());

create policy users_self_insert on public.users
for insert with check (id = auth.uid() or auth_user_id = auth.uid());

create policy users_self_update on public.users
for update using (id = auth.uid() or auth_user_id = auth.uid())
with check (id = auth.uid() or auth_user_id = auth.uid());

create policy users_admin_all on public.users
for all using (public.is_admin(auth.uid()))
with check (public.is_admin(auth.uid()));

drop policy if exists complaints_select_all on public.complaints;
drop policy if exists complaints_insert_all on public.complaints;
drop policy if exists complaints_update_all on public.complaints;
drop policy if exists complaints_select_self_or_admin on public.complaints;
drop policy if exists complaints_insert_self on public.complaints;
drop policy if exists complaints_update_admin_only on public.complaints;

create policy complaints_select_self_or_admin on public.complaints
for select using (
  reported_by = auth.uid()
  or teacher_id = auth.uid()
  or staff_id = auth.uid()
  or public.is_admin(auth.uid())
);

create policy complaints_insert_self on public.complaints
for insert with check (reported_by = auth.uid());

create policy complaints_update_admin_only on public.complaints
for update using (public.is_admin(auth.uid()))
with check (public.is_admin(auth.uid()));

drop policy if exists complaints_staff_mark_done on public.complaints;
create policy complaints_staff_mark_done on public.complaints
for update
using (staff_id = auth.uid() and status = 'assigned')
with check (staff_id = auth.uid() and status = 'needs_verification');

create index if not exists complaints_teacher_idx on public.complaints(teacher_id);
create index if not exists complaints_staff_idx on public.complaints(staff_id);
create index if not exists complaints_staff_status_idx on public.complaints(staff_id, status);

select storage.create_bucket('complaint-media', public => true);

