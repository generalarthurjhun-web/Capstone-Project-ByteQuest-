-- ByteQuest foundation: trusted identity helpers and append-only audit records.
-- Expand-only migration. No legacy rows or columns are removed.

begin;

alter table public.profiles
  add column if not exists deactivated_at timestamptz,
  add column if not exists deactivation_reason text,
  add column if not exists deactivated_by uuid references auth.users(id) on delete set null;

alter table public.profiles
  drop constraint if exists profiles_deactivation_details_check;

alter table public.profiles
  add constraint profiles_deactivation_details_check check (
    (status <> 'deactivated'::public.account_status)
    or (
      deactivated_at is not null
      and nullif(btrim(deactivation_reason), '') is not null
    )
  );

-- The enum value is retained for reversible legacy compatibility, but no new
-- profile may use the merged staff role.
alter table public.profiles
  drop constraint if exists profiles_no_merged_staff_role_check;

alter table public.profiles
  add constraint profiles_no_merged_staff_role_check
  check (role <> 'instructor_admin'::public.user_role);

create table if not exists public.audit_events (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references auth.users(id) on delete set null,
  actor_role public.user_role,
  action text not null check (length(btrim(action)) between 3 and 120),
  target_type text not null check (length(btrim(target_type)) between 2 and 80),
  target_id uuid,
  old_value jsonb,
  new_value jsonb,
  reason text,
  metadata jsonb not null default '{}'::jsonb,
  outcome text not null default 'success'
    check (outcome in ('success', 'denied', 'failed')),
  created_at timestamptz not null default now()
);

create index if not exists audit_events_actor_created_idx
  on public.audit_events(actor_id, created_at desc);
create index if not exists audit_events_target_created_idx
  on public.audit_events(target_type, target_id, created_at desc);
create index if not exists audit_events_action_created_idx
  on public.audit_events(action, created_at desc);

alter table public.audit_events enable row level security;

create schema if not exists private;
revoke all on schema private from public;
revoke all on schema private from anon;
revoke all on schema private from authenticated;

create or replace function public.current_app_role()
returns public.user_role
language sql
stable
security definer
set search_path = ''
as $$
  select p.role
  from public.profiles p
  where p.user_id = (select auth.uid())
    and p.status = 'active'::public.account_status
  limit 1
$$;

create or replace function public.is_active_user()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles p
    where p.user_id = (select auth.uid())
      and p.status = 'active'::public.account_status
  )
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.current_app_role() = 'admin'::public.user_role
$$;

create or replace function public.is_instructor()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.current_app_role() = 'instructor'::public.user_role
$$;

create or replace function public.is_learner()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.current_app_role() = 'learner'::public.user_role
$$;

-- A convenience predicate only. It is not used to grant Instructor and Admin
-- the same business capabilities.
create or replace function public.is_staff()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.current_app_role() in (
    'instructor'::public.user_role,
    'admin'::public.user_role
  )
$$;

create or replace function private.write_audit_event(
  p_action text,
  p_target_type text,
  p_target_id uuid default null,
  p_old_value jsonb default null,
  p_new_value jsonb default null,
  p_reason text default null,
  p_metadata jsonb default '{}'::jsonb,
  p_outcome text default 'success'
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid;
begin
  insert into public.audit_events (
    actor_id,
    actor_role,
    action,
    target_type,
    target_id,
    old_value,
    new_value,
    reason,
    metadata,
    outcome
  )
  values (
    (select auth.uid()),
    public.current_app_role(),
    p_action,
    p_target_type,
    p_target_id,
    p_old_value,
    p_new_value,
    nullif(btrim(p_reason), ''),
    coalesce(p_metadata, '{}'::jsonb),
    p_outcome
  )
  returning id into v_id;

  return v_id;
end
$$;

revoke all on function public.current_app_role() from public, anon;
revoke all on function public.is_active_user() from public, anon;
revoke all on function public.is_admin() from public, anon;
revoke all on function public.is_instructor() from public, anon;
revoke all on function public.is_learner() from public, anon;
revoke all on function public.is_staff() from public, anon;

grant execute on function public.current_app_role() to authenticated, service_role;
grant execute on function public.is_active_user() to authenticated, service_role;
grant execute on function public.is_admin() to authenticated, service_role;
grant execute on function public.is_instructor() to authenticated, service_role;
grant execute on function public.is_learner() to authenticated, service_role;
grant execute on function public.is_staff() to authenticated, service_role;

revoke all on function private.write_audit_event(text, text, uuid, jsonb, jsonb, text, jsonb, text)
  from public, anon, authenticated;

commit;
