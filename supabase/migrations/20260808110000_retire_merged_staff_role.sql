-- Retire the historical merged staff label without rebuilding the enum or
-- deleting profile history. Rollback: recreate is_instructor_admin(), restore
-- the guard/constraint text, then rename legacy_instructor_admin back.

do $$
begin
  if exists (
    select 1
    from public.profiles
    where role::text = 'instructor_admin'
  ) then
    raise exception 'MERGED_STAFF_ROLE_STILL_IN_USE';
  end if;
end
$$;

alter type public.user_role
  rename value 'instructor_admin' to 'legacy_instructor_admin';

alter table public.profiles
  drop constraint profiles_no_merged_staff_role_check;

alter table public.profiles
  add constraint profiles_no_merged_staff_role_check
  check (role <> 'legacy_instructor_admin'::public.user_role);

create or replace function public.admin_change_user_role(
  p_user_id uuid,
  p_new_role public.user_role,
  p_reason text
)
returns public.profiles
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_profile public.profiles;
  v_old jsonb;
begin
  if not public.is_admin() then
    raise exception 'ADMIN_REQUIRED' using errcode = '42501';
  end if;

  if p_new_role = 'legacy_instructor_admin'::public.user_role then
    raise exception 'MERGED_STAFF_ROLE_FORBIDDEN' using errcode = '22023';
  end if;

  if nullif(btrim(p_reason), '') is null then
    raise exception 'ROLE_CHANGE_REASON_REQUIRED' using errcode = '22023';
  end if;

  if p_user_id = (select auth.uid())
     and p_new_role <> 'admin'::public.user_role then
    raise exception 'ADMIN_CANNOT_SELF_DEMOTE' using errcode = '42501';
  end if;

  select p.*
  into v_profile
  from public.profiles p
  where p.user_id = p_user_id
  for update;

  if not found then
    raise exception 'PROFILE_NOT_FOUND' using errcode = 'P0002';
  end if;

  v_old := to_jsonb(v_profile);

  update public.profiles
  set role = p_new_role
  where user_id = p_user_id
  returning * into v_profile;

  perform private.write_audit_event(
    'account.role_changed',
    'profile',
    v_profile.id,
    v_old,
    to_jsonb(v_profile),
    p_reason,
    jsonb_build_object('target_user_id', p_user_id)
  );

  return v_profile;
end
$$;

drop function public.is_instructor_admin();

comment on type public.user_role is
  'Application roles. legacy_instructor_admin is retained only as a rejected compatibility label and cannot be assigned to profiles.';
