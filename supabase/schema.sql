create table if not exists public.users (
  id bigint generated always as identity primary key,
  name text not null,
  email text not null unique,
  password text not null,
  role text not null check (role in ('admin','staff','teacher')),
  createdAt timestamptz not null default now(),
  updatedAt timestamptz not null default now()
);

create table if not exists public.complaints (
  id bigint generated always as identity primary key,
  title text not null,
  description text not null,
  mediaPath text,
  mediaIsVideo boolean not null default false,
  status text not null check (status in ('unassigned','assigned','needs_verification','closed')),
  teacherId bigint not null references public.users(id) on delete cascade,
  staffId bigint references public.users(id),
  createdAt timestamptz not null default now(),
  updatedAt timestamptz not null default now()
);

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new."updatedAt" := now();
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

create policy users_select_all on public.users for select using (true);
create policy users_insert_all on public.users for insert with check (true);
create policy users_update_all on public.users for update using (true) with check (true);

create policy complaints_select_all on public.complaints for select using (true);
create policy complaints_insert_all on public.complaints for insert with check (true);
create policy complaints_update_all on public.complaints for update using (true) with check (true);

create index if not exists complaints_teacher_idx on public.complaints("teacherId");
create index if not exists complaints_staff_idx on public.complaints("staffId");
create index if not exists complaints_staff_status_idx on public.complaints("staffId", status);

select storage.create_bucket('complaint-media', public => true);

