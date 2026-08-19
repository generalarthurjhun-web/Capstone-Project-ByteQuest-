-- Versioned TESDA source, module, activity, and rubric foundation.
-- No TESDA source or scoring rule is seeded by this migration.

begin;

do $$
begin
  create type public.tesda_source_status as enum (
    'pending_tesda_validation',
    'approved',
    'active',
    'superseded',
    'archived'
  );
exception
  when duplicate_object then null;
end
$$;

do $$
begin
  create type public.content_version_status as enum ('draft', 'published', 'retired');
exception
  when duplicate_object then null;
end
$$;

do $$
begin
  create type public.activity_delivery_mode as enum ('practice', 'assessment', 'both');
exception
  when duplicate_object then null;
end
$$;

do $$
begin
  create type public.rubric_status as enum (
    'pending_tesda_validation',
    'draft',
    'approved',
    'retired'
  );
exception
  when duplicate_object then null;
end
$$;

create table if not exists public.tesda_sources (
  id uuid primary key default gen_random_uuid(),
  qualification_code text not null check (length(btrim(qualification_code)) between 2 and 80),
  title text not null check (length(btrim(title)) between 5 and 300),
  edition text,
  effective_date date,
  publication_date date,
  source_reference text not null check (length(btrim(source_reference)) between 5 and 1000),
  document_storage_path text,
  status public.tesda_source_status not null default 'pending_tesda_validation',
  validation_notes text,
  created_by uuid not null references auth.users(id) on delete restrict,
  approved_by uuid references auth.users(id) on delete restrict,
  approved_at timestamptz,
  activated_by uuid references auth.users(id) on delete restrict,
  activated_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint tesda_sources_approval_details_check check (
    status not in ('approved'::public.tesda_source_status, 'active'::public.tesda_source_status)
    or (approved_by is not null and approved_at is not null)
  ),
  constraint tesda_sources_activation_details_check check (
    status <> 'active'::public.tesda_source_status
    or (activated_by is not null and activated_at is not null)
  )
);

create unique index if not exists tesda_sources_identity_idx
  on public.tesda_sources(
    lower(qualification_code),
    lower(title),
    lower(coalesce(edition, '')),
    coalesce(effective_date, date '0001-01-01')
  );
create unique index if not exists tesda_sources_one_active_qualification_idx
  on public.tesda_sources(lower(qualification_code))
  where status = 'active'::public.tesda_source_status;

alter table public.competencies
  add column if not exists tesda_source_id uuid references public.tesda_sources(id) on delete restrict,
  add column if not exists source_trace text;
create index if not exists competencies_tesda_source_idx
  on public.competencies(tesda_source_id);

create table if not exists public.module_versions (
  id uuid primary key default gen_random_uuid(),
  module_id uuid not null references public.coc_modules(id) on delete restrict,
  tesda_source_id uuid not null references public.tesda_sources(id) on delete restrict,
  version_number integer not null check (version_number > 0),
  title text not null check (length(btrim(title)) between 2 and 300),
  description text,
  source_trace jsonb not null default '{}'::jsonb,
  content_metadata jsonb not null default '{}'::jsonb,
  status public.content_version_status not null default 'draft',
  created_by uuid not null references auth.users(id) on delete restrict,
  published_by uuid references auth.users(id) on delete restrict,
  published_at timestamptz,
  retired_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (module_id, version_number),
  constraint module_versions_publish_details_check check (
    status <> 'published'::public.content_version_status
    or (published_by is not null and published_at is not null)
  )
);

create index if not exists module_versions_source_status_idx
  on public.module_versions(tesda_source_id, status);

create table if not exists public.activity_versions (
  id uuid primary key default gen_random_uuid(),
  mission_id uuid not null references public.missions(id) on delete restrict,
  module_version_id uuid not null references public.module_versions(id) on delete restrict,
  version_number integer not null check (version_number > 0),
  title text not null check (length(btrim(title)) between 2 and 300),
  instructions text,
  delivery_mode public.activity_delivery_mode not null default 'practice',
  learner_payload jsonb not null default '{}'::jsonb,
  evaluator_config jsonb not null default '{}'::jsonb,
  status public.content_version_status not null default 'draft',
  created_by uuid not null references auth.users(id) on delete restrict,
  published_by uuid references auth.users(id) on delete restrict,
  published_at timestamptz,
  retired_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (mission_id, version_number),
  constraint activity_versions_publish_details_check check (
    status <> 'published'::public.content_version_status
    or (published_by is not null and published_at is not null)
  )
);

create index if not exists activity_versions_module_status_idx
  on public.activity_versions(module_version_id, status);

create table if not exists public.rubric_versions (
  id uuid primary key default gen_random_uuid(),
  activity_version_id uuid not null references public.activity_versions(id) on delete restrict,
  tesda_source_id uuid not null references public.tesda_sources(id) on delete restrict,
  version_number integer not null check (version_number > 0),
  title text not null check (length(btrim(title)) between 2 and 300),
  status public.rubric_status not null default 'pending_tesda_validation',
  scoring_method text not null default 'PENDING_TESDA_VALIDATION',
  passing_rule jsonb not null default jsonb_build_object('status', 'PENDING_TESDA_VALIDATION'),
  created_by uuid not null references auth.users(id) on delete restrict,
  approved_by uuid references auth.users(id) on delete restrict,
  approved_at timestamptz,
  retired_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (activity_version_id, version_number),
  constraint rubric_versions_approval_details_check check (
    status <> 'approved'::public.rubric_status
    or (
      approved_by is not null
      and approved_at is not null
      and scoring_method <> 'PENDING_TESDA_VALIDATION'
      and passing_rule->>'status' is distinct from 'PENDING_TESDA_VALIDATION'
    )
  )
);

create index if not exists rubric_versions_source_status_idx
  on public.rubric_versions(tesda_source_id, status);

create table if not exists public.rubric_criteria (
  id uuid primary key default gen_random_uuid(),
  rubric_version_id uuid not null references public.rubric_versions(id) on delete restrict,
  criterion_code text not null check (length(btrim(criterion_code)) between 1 and 80),
  title text not null check (length(btrim(title)) between 2 and 300),
  description text,
  source_trace text not null check (length(btrim(source_trace)) between 2 and 1000),
  evidence_rule jsonb not null default '{}'::jsonb,
  scoring_rule jsonb not null default jsonb_build_object('status', 'PENDING_TESDA_VALIDATION'),
  max_value numeric(10, 4),
  order_index integer not null check (order_index > 0),
  is_required boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (rubric_version_id, criterion_code),
  unique (rubric_version_id, order_index),
  constraint rubric_criteria_max_value_check check (max_value is null or max_value >= 0)
);

drop trigger if exists trg_tesda_sources_updated_at on public.tesda_sources;
create trigger trg_tesda_sources_updated_at
before update on public.tesda_sources
for each row execute function public.set_updated_at();

drop trigger if exists trg_module_versions_updated_at on public.module_versions;
create trigger trg_module_versions_updated_at
before update on public.module_versions
for each row execute function public.set_updated_at();

drop trigger if exists trg_activity_versions_updated_at on public.activity_versions;
create trigger trg_activity_versions_updated_at
before update on public.activity_versions
for each row execute function public.set_updated_at();

drop trigger if exists trg_rubric_versions_updated_at on public.rubric_versions;
create trigger trg_rubric_versions_updated_at
before update on public.rubric_versions
for each row execute function public.set_updated_at();

drop trigger if exists trg_rubric_criteria_updated_at on public.rubric_criteria;
create trigger trg_rubric_criteria_updated_at
before update on public.rubric_criteria
for each row execute function public.set_updated_at();

alter table public.tesda_sources enable row level security;
alter table public.module_versions enable row level security;
alter table public.activity_versions enable row level security;
alter table public.rubric_versions enable row level security;
alter table public.rubric_criteria enable row level security;

create or replace function public.approve_tesda_source(
  p_source_id uuid,
  p_validation_notes text
)
returns public.tesda_sources
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_source public.tesda_sources;
  v_old jsonb;
begin
  if not public.is_admin() then
    raise exception 'ADMIN_REQUIRED' using errcode = '42501';
  end if;

  if nullif(btrim(p_validation_notes), '') is null then
    raise exception 'VALIDATION_NOTES_REQUIRED' using errcode = '22023';
  end if;

  select ts.*
  into v_source
  from public.tesda_sources ts
  where ts.id = p_source_id
  for update;

  if not found then
    raise exception 'TESDA_SOURCE_NOT_FOUND' using errcode = 'P0002';
  end if;

  v_old := to_jsonb(v_source);

  if v_source.status <> 'pending_tesda_validation'::public.tesda_source_status then
    raise exception 'TESDA_SOURCE_NOT_PENDING' using errcode = '22023';
  end if;

  update public.tesda_sources
  set status = 'approved'::public.tesda_source_status,
      validation_notes = p_validation_notes,
      approved_by = (select auth.uid()),
      approved_at = now()
  where id = p_source_id
  returning * into v_source;

  perform private.write_audit_event(
    'tesda_source.approved',
    'tesda_source',
    p_source_id,
    v_old,
    to_jsonb(v_source),
    p_validation_notes
  );

  return v_source;
end
$$;

create or replace function public.activate_tesda_source(
  p_source_id uuid,
  p_reason text
)
returns public.tesda_sources
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_source public.tesda_sources;
  v_old jsonb;
begin
  if not public.is_admin() then
    raise exception 'ADMIN_REQUIRED' using errcode = '42501';
  end if;

  if nullif(btrim(p_reason), '') is null then
    raise exception 'ACTIVATION_REASON_REQUIRED' using errcode = '22023';
  end if;

  select ts.*
  into v_source
  from public.tesda_sources ts
  where ts.id = p_source_id
  for update;

  if not found then
    raise exception 'TESDA_SOURCE_NOT_FOUND' using errcode = 'P0002';
  end if;

  v_old := to_jsonb(v_source);

  if v_source.status <> 'approved'::public.tesda_source_status then
    raise exception 'TESDA_SOURCE_MUST_BE_APPROVED' using errcode = '22023';
  end if;

  update public.tesda_sources
  set status = 'superseded'::public.tesda_source_status,
      updated_at = now()
  where lower(qualification_code) = lower(v_source.qualification_code)
    and status = 'active'::public.tesda_source_status
    and id <> p_source_id;

  update public.tesda_sources
  set status = 'active'::public.tesda_source_status,
      activated_by = (select auth.uid()),
      activated_at = now()
  where id = p_source_id
  returning * into v_source;

  perform private.write_audit_event(
    'tesda_source.activated',
    'tesda_source',
    p_source_id,
    v_old,
    to_jsonb(v_source),
    p_reason
  );

  return v_source;
end
$$;

revoke all on function public.approve_tesda_source(uuid, text) from public, anon;
revoke all on function public.activate_tesda_source(uuid, text) from public, anon;
grant execute on function public.approve_tesda_source(uuid, text) to authenticated;
grant execute on function public.activate_tesda_source(uuid, text) to authenticated;

commit;
