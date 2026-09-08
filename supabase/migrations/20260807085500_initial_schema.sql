-- ByteQuest fresh-database foundation schema.
--
-- This foundation is stored at the oldest migration version already known to
-- the deployed ByteQuest project. Existing databases therefore do not replay
-- it, while fresh databases receive the identity/catalog objects required by
-- the forward-only authoritative migrations.

begin;

create extension if not exists pgcrypto;

do $$
begin
  create type public.account_status as enum (
    'active', 'inactive', 'suspended', 'pending'
  );
exception when duplicate_object then null;
end
$$;

do $$
begin
  create type public.user_role as enum ('learner', 'instructor', 'admin', 'instructor_admin');
exception when duplicate_object then null;
end
$$;

do $$
begin
  create type public.mission_status as enum ('draft', 'published', 'archived');
exception when duplicate_object then null;
end
$$;

do $$
begin
  create type public.progress_status as enum ('locked', 'not_started', 'in_progress', 'completed', 'failed');
exception when duplicate_object then null;
end
$$;

do $$
begin
  create type public.mission_type as enum (
    'identification', 'drag_and_drop', 'configuration_form',
    'step_procedure', 'troubleshooting', 'checklist', 'matching'
  );
exception when duplicate_object then null;
end
$$;

do $$
begin
  create type public.rating_type as enum (
    'excellent', 'very_good', 'good', 'needs_improvement', 'poor'
  );
exception when duplicate_object then null;
end
$$;

do $$
begin
  create type public.difficulty_level as enum (
    'beginner', 'intermediate', 'advanced'
  );
exception when duplicate_object then null;
end
$$;

do $$
begin
  create type public.competency_status as enum (
    'competent', 'not_yet_competent'
  );
exception when duplicate_object then null;
end
$$;

do $$
begin
  create type public.condition_type as enum (
    'mission_count', 'coc_completion', 'streak', 'score_threshold',
    'time_based', 'perfect_score', 'no_mistake', 'special'
  );
exception when duplicate_object then null;
end
$$;

do $$
begin
  create type public.leaderboard_type as enum (
    'overall', 'coc', 'mission', 'weekly', 'monthly'
  );
exception when duplicate_object then null;
end
$$;

do $$
begin
  create type public.notification_type as enum (
    'mission', 'badge', 'achievement', 'progress', 'system', 'admin_message'
  );
exception when duplicate_object then null;
end
$$;

do $$
begin
  create type public.report_type as enum (
    'individual_learner', 'class_summary', 'coc_performance',
    'mission_result', 'competency_achievement', 'progress_report',
    'pass_fail_summary', 'analytics_dashboard'
  );
exception when duplicate_object then null;
end
$$;

-- Kept for compatibility with the generated database contract and historical
-- task records. The current simulation_tasks.task_type column intentionally
-- uses mission_type, matching the deployed schema.
do $$
begin
  create type public.task_type as enum (
    'select_image', 'drag_drop', 'arrange_sequence', 'form_input',
    'matching', 'checklist', 'decision_tree'
  );
exception when duplicate_object then null;
end
$$;

alter type public.account_status add value if not exists 'deactivated';

create schema if not exists private;

create table if not exists public.profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  full_name text not null default '',
  email text not null default '',
  avatar_url text,
  role public.user_role not null default 'learner',
  status public.account_status not null default 'active',
  learner_id text,
  school text,
  course_section text,
  current_level integer not null default 1 check (current_level > 0),
  total_xp integer not null default 0 check (total_xp >= 0),
  total_points integer not null default 0 check (total_points >= 0),
  total_badges integer not null default 0 check (total_badges >= 0),
  completed_missions integer not null default 0 check (completed_missions >= 0),
  current_streak integer not null default 0 check (current_streak >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  last_login_at timestamptz,
  last_activity_at timestamptz
);

create table if not exists public.competencies (
  id uuid primary key default gen_random_uuid(),
  competency_code text not null unique,
  name text not null,
  description text,
  order_index integer not null default 1 check (order_index > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.coc_modules (
  id uuid primary key default gen_random_uuid(),
  coc_code text not null unique,
  title text not null,
  module_name text not null,
  description text,
  competency_area text,
  competency_id uuid references public.competencies(id) on delete set null,
  total_missions integer not null default 0 check (total_missions >= 0),
  order_index integer not null default 1 check (order_index > 0),
  status public.mission_status not null default 'draft',
  difficulty public.difficulty_level not null default 'beginner',
  xp_reward integer not null default 0 check (xp_reward >= 0),
  icon_url text,
  color_hex text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.missions (
  id uuid primary key default gen_random_uuid(),
  coc_id uuid not null references public.coc_modules(id) on delete cascade,
  competency_id uuid references public.competencies(id) on delete set null,
  mission_code text not null unique,
  mission_number integer not null check (mission_number > 0),
  title text not null,
  description text,
  scenario text,
  objective text,
  skills_assessed text[] not null default '{}',
  challenge_description text,
  mission_type public.mission_type not null default 'identification',
  difficulty public.difficulty_level not null default 'beginner',
  xp_reward integer not null default 0 check (xp_reward >= 0),
  points_reward integer not null default 0 check (points_reward >= 0),
  passing_score integer not null default 0 check (passing_score between 0 and 100),
  time_limit_seconds integer check (time_limit_seconds is null or time_limit_seconds > 0),
  estimated_time_minutes integer not null default 10 check (estimated_time_minutes > 0),
  status public.mission_status not null default 'draft',
  is_locked boolean not null default true,
  order_index integer not null default 1 check (order_index > 0),
  hint_count integer not null default 0 check (hint_count >= 0),
  icon_url text,
  asset_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (coc_id, mission_number)
);

create table if not exists public.simulation_tasks (
  id uuid primary key default gen_random_uuid(),
  mission_id uuid not null references public.missions(id) on delete cascade,
  task_code text,
  task_number integer not null check (task_number > 0),
  task_type public.mission_type not null default 'identification',
  instruction text not null,
  question_text text,
  component_id text,
  target_zone_id text,
  correct_answer text,
  correct_target text,
  accepted_component_ids text[] not null default '{}',
  options jsonb not null default '{}'::jsonb,
  points integer not null default 0 check (points >= 0),
  hint_text text,
  feedback_correct text,
  feedback_incorrect text,
  requires_previous_task boolean not null default false,
  required_order integer,
  order_index integer not null default 1 check (order_index > 0),
  is_required boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (mission_id, task_number)
);

create table if not exists public.assessment_criteria (
  id uuid primary key default gen_random_uuid(),
  mission_id uuid not null references public.missions(id) on delete cascade,
  criteria_name text not null,
  description text,
  max_score numeric(10, 2) not null default 0 check (max_score >= 0),
  weight numeric(6, 4) not null default 0 check (weight >= 0),
  order_index integer not null default 1 check (order_index > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (mission_id, order_index)
);

create table if not exists public.levels (
  id uuid primary key default gen_random_uuid(),
  level_number integer not null unique check (level_number > 0),
  level_name text not null,
  min_xp integer not null default 0 check (min_xp >= 0),
  max_xp integer check (max_xp is null or max_xp >= min_xp),
  badge_icon text,
  created_at timestamptz not null default now()
);

create table if not exists public.badges (
  id uuid primary key default gen_random_uuid(),
  badge_code text not null unique,
  title text not null,
  description text,
  icon_url text,
  condition_type public.condition_type not null,
  condition_value jsonb not null default '{}'::jsonb,
  xp_reward integer not null default 0 check (xp_reward >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.achievements (
  id uuid primary key default gen_random_uuid(),
  achievement_code text not null unique,
  title text not null,
  description text,
  icon_url text,
  condition_type public.condition_type not null,
  condition_value jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.mission_results (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete restrict,
  coc_id uuid references public.coc_modules(id) on delete set null,
  mission_id uuid not null references public.missions(id) on delete restrict,
  mission_title text,
  attempt_number integer not null default 1 check (attempt_number > 0),
  score numeric(12, 2) not null default 0,
  max_score numeric(12, 2) not null default 0,
  percentage numeric(7, 4) not null default 0,
  earned_points integer not null default 0,
  xp_earned integer not null default 0,
  passed boolean not null default false,
  rating public.rating_type,
  competency_status public.competency_status,
  completed_tasks integer not null default 0,
  total_tasks integer not null default 0,
  incorrect_attempts integer not null default 0,
  hints_used integer not null default 0,
  time_spent_seconds integer not null default 0 check (time_spent_seconds >= 0),
  accuracy numeric(7, 4),
  mistakes text[] not null default '{}',
  feedback text,
  remarks text,
  completed_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.task_results (
  id uuid primary key default gen_random_uuid(),
  mission_result_id uuid not null references public.mission_results(id) on delete cascade,
  task_id uuid references public.simulation_tasks(id) on delete set null,
  user_id uuid not null references auth.users(id) on delete restrict,
  mission_id uuid not null references public.missions(id) on delete restrict,
  is_correct boolean,
  is_completed boolean not null default false,
  selected_answer text,
  selected_target text,
  correct_answer text,
  correct_target text,
  score_obtained numeric(10, 2) not null default 0,
  max_score numeric(10, 2) not null default 0,
  attempts integer not null default 0,
  hint_used boolean not null default false,
  feedback text,
  completed_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.learner_progress (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  coc_id uuid not null references public.coc_modules(id) on delete cascade,
  mission_id uuid not null references public.missions(id) on delete cascade,
  status public.progress_status not null default 'locked',
  completion_percentage numeric(7, 4) not null default 0 check (completion_percentage between 0 and 100),
  best_score numeric(12, 2) not null default 0,
  latest_score numeric(12, 2) not null default 0,
  attempts_count integer not null default 0 check (attempts_count >= 0),
  total_time_spent_seconds integer not null default 0 check (total_time_spent_seconds >= 0),
  last_activity_at timestamptz,
  unlocked_at timestamptz,
  started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, mission_id)
);

create table if not exists public.user_badges (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  badge_id uuid not null references public.badges(id) on delete restrict,
  mission_id uuid references public.missions(id) on delete set null,
  coc_id uuid references public.coc_modules(id) on delete set null,
  earned_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table if not exists public.user_achievements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  achievement_id uuid not null references public.achievements(id) on delete restrict,
  mission_id uuid references public.missions(id) on delete set null,
  coc_id uuid references public.coc_modules(id) on delete set null,
  earned_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table if not exists public.leaderboard_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  coc_id uuid references public.coc_modules(id) on delete set null,
  mission_id uuid references public.missions(id) on delete set null,
  mission_result_id uuid references public.mission_results(id) on delete set null,
  score numeric(12, 2) not null default 0,
  xp integer not null default 0,
  time_spent_seconds integer not null default 0,
  incorrect_attempts integer not null default 0,
  ranking_points numeric(12, 2) not null default 0,
  leaderboard_type public.leaderboard_type not null default 'overall',
  completed_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  message text not null,
  type public.notification_type not null default 'system',
  is_read boolean not null default false,
  related_mission_id uuid references public.missions(id) on delete set null,
  related_coc_id uuid references public.coc_modules(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  read_at timestamptz
);

create table if not exists public.user_settings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  notifications_enabled boolean not null default true,
  sound_enabled boolean not null default true,
  vibration_enabled boolean not null default true,
  theme_mode text not null default 'system' check (theme_mode in ('light', 'dark', 'system')),
  language text not null default 'en',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  generated_by uuid references auth.users(id) on delete set null,
  report_type public.report_type not null,
  title text not null,
  filters jsonb not null default '{}'::jsonb,
  data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.activity_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  action text not null,
  entity_type text,
  entity_id uuid,
  description text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create unique index if not exists competencies_code_idx on public.competencies(lower(competency_code));
create unique index if not exists coc_modules_code_idx on public.coc_modules(lower(coc_code));
create index if not exists missions_coc_order_idx on public.missions(coc_id, order_index);
create index if not exists simulation_tasks_mission_order_idx on public.simulation_tasks(mission_id, order_index);
create index if not exists assessment_criteria_mission_order_idx on public.assessment_criteria(mission_id, order_index);
create index if not exists learner_progress_user_status_idx on public.learner_progress(user_id, status);
create index if not exists mission_results_user_completed_idx on public.mission_results(user_id, completed_at desc);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end
$$;

do $$
declare
  v_table text;
begin
  foreach v_table in array array[
    'profiles', 'competencies', 'coc_modules', 'missions', 'simulation_tasks',
    'assessment_criteria', 'badges', 'achievements', 'learner_progress',
    'user_settings'
  ] loop
    execute format('drop trigger if exists trg_%I_updated_at on public.%I', v_table, v_table);
    execute format(
      'create trigger trg_%I_updated_at before update on public.%I for each row execute function public.set_updated_at()',
      v_table, v_table
    );
  end loop;
end
$$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (user_id, email, full_name, role, status)
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    'learner'::public.user_role,
    'active'::public.account_status
  )
  on conflict (user_id) do update
    set email = excluded.email;
  return new;
end
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

create or replace function public.get_level_from_xp(p_xp integer)
returns integer
language sql
stable
as $$
  select coalesce((
    select level_number from public.levels
    where min_xp <= greatest(coalesce(p_xp, 0), 0)
      and (max_xp is null or max_xp >= greatest(coalesce(p_xp, 0), 0))
    order by level_number desc limit 1
  ), 1)
$$;

create or replace function public.get_rating(p_score integer)
returns public.rating_type
language plpgsql
stable
set search_path = ''
as $$
begin
  raise exception 'PENDING_TESDA_VALIDATION'
    using errcode = '22023',
          detail = format(
            'No numeric rating bands are active without an approved source and rubric version; input %s was not evaluated.',
            coalesce(p_score::text, 'NULL')
          );
end
$$;

create or replace function public.is_own_user(p_user_id uuid)
returns boolean
language sql
stable
as $$ select p_user_id = (select auth.uid()) $$;

create or replace function public.is_instructor_admin()
returns boolean
language sql
stable
as $$
  select exists (
    select 1 from public.profiles p
    where p.user_id = (select auth.uid())
      and p.status = 'active'::public.account_status
      and p.role in ('instructor'::public.user_role, 'admin'::public.user_role, 'instructor_admin'::public.user_role)
  )
$$;

create or replace function public.after_mission_result_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  return new;
end
$$;

create or replace function public.rls_auto_enable()
returns event_trigger
language plpgsql
as $$
begin
  return;
end
$$;

alter table public.profiles enable row level security;
alter table public.competencies enable row level security;
alter table public.coc_modules enable row level security;
alter table public.missions enable row level security;
alter table public.simulation_tasks enable row level security;
alter table public.assessment_criteria enable row level security;
alter table public.levels enable row level security;
alter table public.badges enable row level security;
alter table public.achievements enable row level security;
alter table public.mission_results enable row level security;
alter table public.task_results enable row level security;
alter table public.learner_progress enable row level security;
alter table public.user_badges enable row level security;
alter table public.user_achievements enable row level security;
alter table public.leaderboard_entries enable row level security;
alter table public.notifications enable row level security;
alter table public.user_settings enable row level security;
alter table public.reports enable row level security;
alter table public.activity_logs enable row level security;

commit;
