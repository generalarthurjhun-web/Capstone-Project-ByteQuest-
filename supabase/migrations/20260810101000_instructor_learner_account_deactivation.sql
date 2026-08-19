-- Least-privilege Instructor deactivation for assigned learner accounts.
-- The operation is denied when another Instructor has an active membership.

begin;

create or replace function public.instructor_deactivate_learner_account(
  p_learner_id uuid,
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
  v_membership_ids uuid[];
begin
  if not public.is_instructor() then
    raise exception 'INSTRUCTOR_REQUIRED' using errcode = '42501';
  end if;

  if p_learner_id is null or p_learner_id = (select auth.uid()) then
    raise exception 'INVALID_LEARNER_TARGET' using errcode = '22023';
  end if;

  if length(btrim(coalesce(p_reason, ''))) < 5 then
    raise exception 'DEACTIVATION_REASON_REQUIRED' using errcode = '22023';
  end if;

  select p.*
  into v_profile
  from public.profiles p
  where p.user_id = p_learner_id
    and p.role = 'learner'::public.user_role
  for update;

  if v_profile.id is null then
    raise exception 'LEARNER_NOT_FOUND' using errcode = 'P0002';
  end if;

  if v_profile.status <> 'active'::public.account_status then
    raise exception 'LEARNER_ACCOUNT_NOT_ACTIVE' using errcode = '55000';
  end if;

  select array_agg(cm.id order by cm.enrolled_at)
  into v_membership_ids
  from public.class_memberships cm
  join public.classes c on c.id = cm.class_id
  where cm.learner_id = p_learner_id
    and cm.status = 'active'::public.membership_status
    and c.instructor_id = (select auth.uid());

  if coalesce(cardinality(v_membership_ids), 0) = 0 then
    raise exception 'ASSIGNED_LEARNER_SCOPE_REQUIRED' using errcode = '42501';
  end if;

  if exists (
    select 1
    from public.class_memberships cm
    join public.classes c on c.id = cm.class_id
    where cm.learner_id = p_learner_id
      and cm.status = 'active'::public.membership_status
      and c.instructor_id <> (select auth.uid())
  ) then
    raise exception 'LEARNER_HAS_OTHER_INSTRUCTOR_SCOPE' using errcode = '42501';
  end if;

  v_old := to_jsonb(v_profile);

  update public.class_memberships cm
  set status = 'deactivated'::public.membership_status,
      deactivated_by = (select auth.uid()),
      deactivated_at = now(),
      deactivation_reason = btrim(p_reason)
  where cm.id = any(v_membership_ids);

  update public.profiles
  set status = 'deactivated'::public.account_status,
      deactivated_at = now(),
      deactivation_reason = btrim(p_reason),
      deactivated_by = (select auth.uid())
  where user_id = p_learner_id
  returning * into v_profile;

  perform private.write_audit_event(
    'account.deactivated_by_instructor',
    'profile',
    v_profile.id,
    v_old,
    to_jsonb(v_profile),
    p_reason,
    jsonb_build_object(
      'target_user_id', p_learner_id,
      'membership_ids', to_jsonb(v_membership_ids),
      'scope_rule', 'ALL_ACTIVE_MEMBERSHIPS_OWNED_BY_ACTOR'
    )
  );

  return v_profile;
end
$$;

revoke all on function public.instructor_deactivate_learner_account(uuid, text)
  from public, anon;
grant execute on function public.instructor_deactivate_learner_account(uuid, text)
  to authenticated;

commit;
