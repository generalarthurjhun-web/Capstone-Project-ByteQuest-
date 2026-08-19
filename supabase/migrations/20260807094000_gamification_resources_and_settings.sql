-- Motivational events, class resources, and audited global settings.

begin;

do $$
begin
  create type public.resource_status as enum ('active', 'deleted');
exception
  when duplicate_object then null;
end
$$;

create table if not exists public.gamification_events (
  id uuid primary key default gen_random_uuid(),
  learner_id uuid not null references auth.users(id) on delete restrict,
  event_type text not null check (length(btrim(event_type)) between 2 and 100),
  source_type text not null check (length(btrim(source_type)) between 2 and 80),
  source_id uuid,
  idempotency_key text not null check (length(btrim(idempotency_key)) between 8 and 300),
  xp_delta integer not null default 0,
  points_delta integer not null default 0,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  unique (learner_id, idempotency_key)
);

create index if not exists gamification_events_learner_created_idx
  on public.gamification_events(learner_id, created_at desc);
create index if not exists gamification_events_source_idx
  on public.gamification_events(source_type, source_id);

create table if not exists public.learning_resources (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references public.classes(id) on delete restrict,
  title text not null check (length(btrim(title)) between 2 and 300),
  description text,
  storage_bucket text not null,
  storage_path text not null,
  mime_type text,
  size_bytes bigint check (size_bytes is null or size_bytes >= 0),
  status public.resource_status not null default 'active',
  uploaded_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  deleted_by uuid references auth.users(id) on delete restrict,
  deleted_at timestamptz,
  deletion_reason text,
  unique (storage_bucket, storage_path),
  constraint learning_resources_deletion_details_check check (
    status <> 'deleted'::public.resource_status
    or (
      deleted_by is not null
      and deleted_at is not null
      and nullif(btrim(deletion_reason), '') is not null
    )
  )
);

create index if not exists learning_resources_class_status_idx
  on public.learning_resources(class_id, status, created_at desc);

create table if not exists public.system_settings (
  setting_key text primary key check (length(btrim(setting_key)) between 2 and 120),
  setting_value jsonb not null,
  description text,
  updated_by uuid not null references auth.users(id) on delete restrict,
  updated_at timestamptz not null default now()
);

create or replace function private.prevent_gamification_event_mutation()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  raise exception 'gamification_events is append-only' using errcode = '55000';
end
$$;

drop trigger if exists gamification_events_append_only on public.gamification_events;
create trigger gamification_events_append_only
before update or delete on public.gamification_events
for each row execute function private.prevent_gamification_event_mutation();

alter table public.gamification_events enable row level security;
alter table public.learning_resources enable row level security;
alter table public.system_settings enable row level security;

commit;
