-- Authoritative assignment, attempt, chronological action evidence, criterion
-- results, append-only score revisions, releases, and access bypasses.

begin;

do $$
begin
  create type public.assignment_status as enum ('active', 'closed');
exception
  when duplicate_object then null;
end
$$;

do $$
begin
  create type public.assignment_type as enum ('practice', 'assessment');
exception
  when duplicate_object then null;
end
$$;

do $$
begin
  create type public.attempt_status as enum (
    'in_progress',
    'submitted',
    'evaluated',
    'under_review',
    'finalized',
    'released'
  );
exception
  when duplicate_object then null;
end
$$;

do $$
begin
  create type public.criterion_observation as enum (
    'satisfied',
    'not_satisfied',
    'not_evaluated',
    'requires_review'
  );
exception
  when duplicate_object then null;
end
$$;

do $$
begin
  create type public.evaluation_outcome as enum (
    'pending_tesda_validation',
    'competent',
    'not_yet_competent'
  );
exception
  when duplicate_object then null;
end
$$;

do $$
begin
  create type public.score_revision_type as enum (
    'automated_provisional',
    'instructor_adjustment',
    'instructor_final'
  );
exception
  when duplicate_object then null;
end
$$;

create table if not exists public.assignments (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references public.classes(id) on delete restrict,
  activity_version_id uuid not null references public.activity_versions(id) on delete restrict,
  rubric_version_id uuid references public.rubric_versions(id) on delete restrict,
  assignment_type public.assignment_type not null default 'practice',
  title text not null check (length(btrim(title)) between 2 and 300),
  instructions text,
  status public.assignment_status not null default 'active',
  assigned_by uuid not null references auth.users(id) on delete restrict,
  available_at timestamptz,
  due_at timestamptz,
  closed_at timestamptz,
  close_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint assignments_assessment_rubric_check check (
    assignment_type <> 'assessment'::public.assignment_type
    or rubric_version_id is not null
  ),
  constraint assignments_availability_check check (
    due_at is null or available_at is null or due_at > available_at
  ),
  constraint assignments_close_details_check check (
    status <> 'closed'::public.assignment_status
    or (closed_at is not null and nullif(btrim(close_reason), '') is not null)
  )
);

create index if not exists assignments_class_status_idx
  on public.assignments(class_id, status);
create index if not exists assignments_activity_idx
  on public.assignments(activity_version_id);
create unique index if not exists assignments_one_active_activity_idx
  on public.assignments(class_id, activity_version_id, assignment_type)
  where status = 'active'::public.assignment_status;

create table if not exists public.attempts (
  id uuid primary key default gen_random_uuid(),
  learner_id uuid not null references auth.users(id) on delete restrict,
  class_id uuid not null references public.classes(id) on delete restrict,
  assignment_id uuid not null references public.assignments(id) on delete restrict,
  activity_version_id uuid not null references public.activity_versions(id) on delete restrict,
  rubric_version_id uuid references public.rubric_versions(id) on delete restrict,
  tesda_source_id uuid references public.tesda_sources(id) on delete restrict,
  status public.attempt_status not null default 'in_progress',
  client_start_key uuid not null,
  submission_key uuid,
  started_at timestamptz not null default now(),
  submitted_at timestamptz,
  evaluated_at timestamptz,
  finalized_at timestamptz,
  released_at timestamptz,
  elapsed_time_seconds integer check (elapsed_time_seconds is null or elapsed_time_seconds >= 0),
  legacy_mission_result_id uuid unique references public.mission_results(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (learner_id, assignment_id, client_start_key),
  constraint attempts_submission_details_check check (
    status = 'in_progress'::public.attempt_status
    or (submission_key is not null and submitted_at is not null)
  )
);

create unique index if not exists attempts_submission_idempotency_idx
  on public.attempts(learner_id, submission_key)
  where submission_key is not null;
create index if not exists attempts_class_status_idx
  on public.attempts(class_id, status, submitted_at desc);
create index if not exists attempts_learner_status_idx
  on public.attempts(learner_id, status, started_at desc);
create index if not exists attempts_assignment_idx
  on public.attempts(assignment_id, started_at desc);

create table if not exists public.attempt_actions (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null references public.attempts(id) on delete restrict,
  sequence_number integer not null check (sequence_number > 0),
  action_type text not null check (length(btrim(action_type)) between 1 and 80),
  target text,
  value jsonb not null default '{}'::jsonb,
  client_occurred_at timestamptz not null,
  recorded_at timestamptz not null default now(),
  unique (attempt_id, sequence_number)
);

create index if not exists attempt_actions_attempt_recorded_idx
  on public.attempt_actions(attempt_id, sequence_number, recorded_at);

create table if not exists public.criterion_results (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null references public.attempts(id) on delete restrict,
  rubric_criterion_id uuid not null references public.rubric_criteria(id) on delete restrict,
  evaluation_run_id uuid not null,
  expected_rule jsonb not null,
  observed_evidence jsonb not null,
  observation public.criterion_observation not null,
  score_value numeric(12, 4),
  remarks text,
  evaluated_at timestamptz not null default now(),
  unique (attempt_id, rubric_criterion_id, evaluation_run_id),
  constraint criterion_results_score_nonnegative_check check (
    score_value is null or score_value >= 0
  )
);

create index if not exists criterion_results_attempt_run_idx
  on public.criterion_results(attempt_id, evaluation_run_id, evaluated_at desc);

create table if not exists public.score_revisions (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null references public.attempts(id) on delete restrict,
  revision_number integer not null check (revision_number > 0),
  revision_type public.score_revision_type not null,
  supersedes_revision_id uuid references public.score_revisions(id) on delete restrict,
  actor_id uuid references auth.users(id) on delete restrict,
  actor_role public.user_role,
  tesda_source_id uuid not null references public.tesda_sources(id) on delete restrict,
  rubric_version_id uuid not null references public.rubric_versions(id) on delete restrict,
  evaluation_run_id uuid,
  total_value numeric(12, 4),
  max_value numeric(12, 4),
  percentage numeric(7, 4),
  outcome public.evaluation_outcome not null,
  criterion_values jsonb not null default '[]'::jsonb,
  reason text,
  remarks text,
  created_at timestamptz not null default now(),
  unique (attempt_id, revision_number),
  constraint score_revisions_values_check check (
    (total_value is null or total_value >= 0)
    and (max_value is null or max_value > 0)
    and (percentage is null or (percentage >= 0 and percentage <= 100))
  ),
  constraint score_revisions_adjustment_reason_check check (
    revision_type <> 'instructor_adjustment'::public.score_revision_type
    or nullif(btrim(reason), '') is not null
  )
);

create index if not exists score_revisions_attempt_created_idx
  on public.score_revisions(attempt_id, revision_number desc);

create table if not exists public.result_releases (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null references public.attempts(id) on delete restrict,
  score_revision_id uuid not null references public.score_revisions(id) on delete restrict,
  release_number integer not null check (release_number > 0),
  released_by uuid not null references auth.users(id) on delete restrict,
  released_at timestamptz not null default now(),
  release_reason text,
  is_current boolean not null default true,
  revoked_by uuid references auth.users(id) on delete restrict,
  revoked_at timestamptz,
  revocation_reason text,
  created_at timestamptz not null default now(),
  unique (attempt_id, release_number),
  constraint result_releases_revocation_details_check check (
    is_current
    or (
      revoked_by is not null
      and revoked_at is not null
      and nullif(btrim(revocation_reason), '') is not null
    )
  )
);

create unique index if not exists result_releases_one_current_idx
  on public.result_releases(attempt_id)
  where is_current;

create table if not exists public.coc_bypasses (
  id uuid primary key default gen_random_uuid(),
  learner_id uuid not null references auth.users(id) on delete restrict,
  class_id uuid not null references public.classes(id) on delete restrict,
  module_version_id uuid not null references public.module_versions(id) on delete restrict,
  instructor_id uuid not null references auth.users(id) on delete restrict,
  reason text not null check (length(btrim(reason)) between 5 and 1000),
  scope jsonb not null default '{}'::jsonb,
  granted_at timestamptz not null default now(),
  revoked_by uuid references auth.users(id) on delete restrict,
  revoked_at timestamptz,
  revocation_reason text,
  created_at timestamptz not null default now(),
  constraint coc_bypasses_revocation_details_check check (
    revoked_at is null
    or (revoked_by is not null and nullif(btrim(revocation_reason), '') is not null)
  )
);

create unique index if not exists coc_bypasses_one_active_idx
  on public.coc_bypasses(learner_id, class_id, module_version_id)
  where revoked_at is null;
create index if not exists coc_bypasses_class_idx
  on public.coc_bypasses(class_id, granted_at desc);

drop trigger if exists trg_assignments_updated_at on public.assignments;
create trigger trg_assignments_updated_at
before update on public.assignments
for each row execute function public.set_updated_at();

drop trigger if exists trg_attempts_updated_at on public.attempts;
create trigger trg_attempts_updated_at
before update on public.attempts
for each row execute function public.set_updated_at();

create or replace function private.prevent_append_only_mutation()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  raise exception '% is append-only', tg_table_name using errcode = '55000';
end
$$;

drop trigger if exists attempt_actions_append_only on public.attempt_actions;
create trigger attempt_actions_append_only
before update or delete on public.attempt_actions
for each row execute function private.prevent_append_only_mutation();

drop trigger if exists criterion_results_append_only on public.criterion_results;
create trigger criterion_results_append_only
before update or delete on public.criterion_results
for each row execute function private.prevent_append_only_mutation();

drop trigger if exists score_revisions_append_only on public.score_revisions;
create trigger score_revisions_append_only
before update or delete on public.score_revisions
for each row execute function private.prevent_append_only_mutation();

drop trigger if exists audit_events_append_only on public.audit_events;
create trigger audit_events_append_only
before update or delete on public.audit_events
for each row execute function private.prevent_append_only_mutation();

alter table public.assignments enable row level security;
alter table public.attempts enable row level security;
alter table public.attempt_actions enable row level security;
alter table public.criterion_results enable row level security;
alter table public.score_revisions enable row level security;
alter table public.result_releases enable row level security;
alter table public.coc_bypasses enable row level security;

commit;
