-- Learner-owned practice activity evidence. These rows are presentation and
-- resume evidence only; no evaluation, score, outcome, or release authority is
-- stored here.

create table if not exists public.practice_mission_actions (
  id bigint generated always as identity primary key,
  learner_id uuid not null references public.profiles(user_id) on delete cascade,
  client_action_id text not null,
  mission_id text not null,
  phase_id text not null,
  action_type text not null,
  target text,
  value jsonb not null default '{}'::jsonb,
  client_occurred_at timestamptz not null,
  created_at timestamptz not null default now(),
  constraint practice_mission_actions_client_action_id_not_blank
    check (btrim(client_action_id) <> ''),
  constraint practice_mission_actions_mission_id_not_blank
    check (btrim(mission_id) <> ''),
  constraint practice_mission_actions_phase_id_not_blank
    check (btrim(phase_id) <> ''),
  constraint practice_mission_actions_action_type_not_blank
    check (btrim(action_type) <> ''),
  constraint practice_mission_actions_value_object
    check (jsonb_typeof(value) = 'object'),
  constraint practice_mission_actions_learner_action_unique
    unique (learner_id, client_action_id)
);

create index if not exists practice_mission_actions_learner_mission_time_idx
  on public.practice_mission_actions (
    learner_id,
    mission_id,
    client_occurred_at,
    id
  );

alter table public.practice_mission_actions enable row level security;

drop policy if exists practice_mission_actions_select_own
  on public.practice_mission_actions;
create policy practice_mission_actions_select_own
on public.practice_mission_actions
for select
to authenticated
using ((select auth.uid()) = learner_id);

drop policy if exists practice_mission_actions_insert_own
  on public.practice_mission_actions;
create policy practice_mission_actions_insert_own
on public.practice_mission_actions
for insert
to authenticated
with check ((select auth.uid()) = learner_id);

revoke all on table public.practice_mission_actions from public, anon;
grant select, insert on table public.practice_mission_actions to authenticated;
grant usage on sequence public.practice_mission_actions_id_seq to authenticated;

comment on table public.practice_mission_actions is
  'RLS-scoped learner practice interaction evidence. It is not an evaluation, score, competency, release, or reward authority.';
