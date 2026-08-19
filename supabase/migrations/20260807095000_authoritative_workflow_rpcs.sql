-- Narrow trusted mutations for classes, enrollment, assignments, attempts,
-- ordered evidence, review/finalization, release, and COC/module bypass.

begin;

create or replace function public.create_class(
  p_title text,
  p_class_code text default null
)
returns public.classes
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_class public.classes;
begin
  if not public.is_instructor() then
    raise exception 'INSTRUCTOR_REQUIRED' using errcode = '42501';
  end if;

  insert into public.classes (title, class_code, instructor_id, created_by)
  values (
    btrim(p_title),
    nullif(btrim(p_class_code), ''),
    (select auth.uid()),
    (select auth.uid())
  )
  returning * into v_class;

  perform private.write_audit_event(
    'class.created',
    'class',
    v_class.id,
    null,
    to_jsonb(v_class)
  );

  return v_class;
end
$$;

create or replace function public.enroll_learner(
  p_class_id uuid,
  p_learner_id uuid
)
returns public.class_memberships
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_membership public.class_memberships;
begin
  if not public.instructor_owns_class(p_class_id) then
    raise exception 'CLASS_SCOPE_DENIED' using errcode = '42501';
  end if;

  if not exists (
    select 1
    from public.profiles p
    where p.user_id = p_learner_id
      and p.role = 'learner'::public.user_role
      and p.status = 'active'::public.account_status
  ) then
    raise exception 'ACTIVE_LEARNER_REQUIRED' using errcode = '22023';
  end if;

  if exists (
    select 1
    from public.class_memberships cm
    where cm.class_id = p_class_id
      and cm.learner_id = p_learner_id
      and cm.status = 'active'::public.membership_status
  ) then
    raise exception 'LEARNER_ALREADY_ENROLLED' using errcode = '23505';
  end if;

  insert into public.class_memberships (
    class_id,
    learner_id,
    status,
    enrolled_by
  )
  values (
    p_class_id,
    p_learner_id,
    'active'::public.membership_status,
    (select auth.uid())
  )
  returning * into v_membership;

  perform private.write_audit_event(
    'class_membership.enrolled',
    'class_membership',
    v_membership.id,
    null,
    to_jsonb(v_membership),
    null,
    jsonb_build_object('class_id', p_class_id, 'learner_id', p_learner_id)
  );

  return v_membership;
end
$$;

create or replace function public.deactivate_class_membership(
  p_membership_id uuid,
  p_reason text
)
returns public.class_memberships
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_membership public.class_memberships;
  v_old jsonb;
begin
  if nullif(btrim(p_reason), '') is null then
    raise exception 'DEACTIVATION_REASON_REQUIRED' using errcode = '22023';
  end if;

  select cm.*
  into v_membership
  from public.class_memberships cm
  where cm.id = p_membership_id
  for update;

  if not found then
    raise exception 'MEMBERSHIP_NOT_FOUND' using errcode = 'P0002';
  end if;

  v_old := to_jsonb(v_membership);

  if not public.instructor_owns_class(v_membership.class_id) then
    raise exception 'CLASS_SCOPE_DENIED' using errcode = '42501';
  end if;

  if v_membership.status <> 'active'::public.membership_status then
    raise exception 'MEMBERSHIP_NOT_ACTIVE' using errcode = '22023';
  end if;

  update public.class_memberships
  set status = 'deactivated'::public.membership_status,
      deactivated_by = (select auth.uid()),
      deactivated_at = now(),
      deactivation_reason = btrim(p_reason)
  where id = p_membership_id
  returning * into v_membership;

  perform private.write_audit_event(
    'class_membership.deactivated',
    'class_membership',
    v_membership.id,
    v_old,
    to_jsonb(v_membership),
    p_reason,
    jsonb_build_object(
      'class_id', v_membership.class_id,
      'learner_id', v_membership.learner_id
    )
  );

  return v_membership;
end
$$;

create or replace function public.assign_activity(
  p_class_id uuid,
  p_activity_version_id uuid,
  p_rubric_version_id uuid,
  p_assignment_type public.assignment_type,
  p_title text,
  p_instructions text default null,
  p_available_at timestamptz default null,
  p_due_at timestamptz default null
)
returns public.assignments
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_assignment public.assignments;
  v_activity public.activity_versions;
  v_module public.module_versions;
  v_source public.tesda_sources;
  v_rubric public.rubric_versions;
begin
  if not public.instructor_owns_class(p_class_id) then
    raise exception 'CLASS_SCOPE_DENIED' using errcode = '42501';
  end if;

  select av.* into v_activity
  from public.activity_versions av
  where av.id = p_activity_version_id;

  if not found or v_activity.status <> 'published'::public.content_version_status then
    raise exception 'PUBLISHED_ACTIVITY_REQUIRED' using errcode = '22023';
  end if;

  select mv.* into v_module
  from public.module_versions mv
  where mv.id = v_activity.module_version_id;

  if not found or v_module.status <> 'published'::public.content_version_status then
    raise exception 'PUBLISHED_MODULE_VERSION_REQUIRED' using errcode = '22023';
  end if;

  select ts.* into v_source
  from public.tesda_sources ts
  where ts.id = v_module.tesda_source_id;

  if not found or v_source.status <> 'active'::public.tesda_source_status then
    raise exception 'ACTIVE_TESDA_SOURCE_REQUIRED' using errcode = '22023';
  end if;

  if p_assignment_type = 'assessment'::public.assignment_type then
    if p_rubric_version_id is null then
      raise exception 'APPROVED_RUBRIC_REQUIRED' using errcode = '22023';
    end if;

    select rv.* into v_rubric
    from public.rubric_versions rv
    where rv.id = p_rubric_version_id;

    if not found
       or v_rubric.status <> 'approved'::public.rubric_status
       or v_rubric.activity_version_id <> p_activity_version_id
       or v_rubric.tesda_source_id <> v_source.id then
      raise exception 'APPROVED_MATCHING_RUBRIC_REQUIRED' using errcode = '22023';
    end if;
  elsif p_rubric_version_id is not null then
    raise exception 'PRACTICE_ASSIGNMENT_MUST_NOT_SET_OFFICIAL_RUBRIC' using errcode = '22023';
  end if;

  insert into public.assignments (
    class_id,
    activity_version_id,
    rubric_version_id,
    assignment_type,
    title,
    instructions,
    assigned_by,
    available_at,
    due_at
  )
  values (
    p_class_id,
    p_activity_version_id,
    p_rubric_version_id,
    p_assignment_type,
    btrim(p_title),
    nullif(btrim(p_instructions), ''),
    (select auth.uid()),
    p_available_at,
    p_due_at
  )
  returning * into v_assignment;

  perform private.write_audit_event(
    'assignment.created',
    'assignment',
    v_assignment.id,
    null,
    to_jsonb(v_assignment),
    null,
    jsonb_build_object('class_id', p_class_id)
  );

  return v_assignment;
end
$$;

create or replace function public.start_attempt(
  p_assignment_id uuid,
  p_client_start_key uuid
)
returns public.attempts
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_assignment public.assignments;
  v_activity public.activity_versions;
  v_module public.module_versions;
  v_source public.tesda_sources;
  v_rubric public.rubric_versions;
  v_attempt public.attempts;
begin
  if not public.is_learner() then
    raise exception 'ACTIVE_LEARNER_REQUIRED' using errcode = '42501';
  end if;

  select a.* into v_assignment
  from public.assignments a
  where a.id = p_assignment_id;

  if not found or v_assignment.status <> 'active'::public.assignment_status then
    raise exception 'ACTIVE_ASSIGNMENT_REQUIRED' using errcode = '22023';
  end if;

  if v_assignment.available_at is not null and now() < v_assignment.available_at then
    raise exception 'ASSIGNMENT_NOT_YET_AVAILABLE' using errcode = '22023';
  end if;

  if v_assignment.due_at is not null and now() > v_assignment.due_at then
    raise exception 'ASSIGNMENT_DUE_DATE_PASSED' using errcode = '22023';
  end if;

  if not public.learner_is_enrolled(v_assignment.class_id, (select auth.uid())) then
    raise exception 'ACTIVE_ENROLLMENT_REQUIRED' using errcode = '42501';
  end if;

  select av.* into v_activity
  from public.activity_versions av
  where av.id = v_assignment.activity_version_id;

  if not found or v_activity.status <> 'published'::public.content_version_status then
    raise exception 'PUBLISHED_ACTIVITY_REQUIRED' using errcode = '22023';
  end if;

  select mv.* into v_module
  from public.module_versions mv
  where mv.id = v_activity.module_version_id;

  select ts.* into v_source
  from public.tesda_sources ts
  where ts.id = v_module.tesda_source_id;

  if v_module.status <> 'published'::public.content_version_status
     or v_source.status <> 'active'::public.tesda_source_status then
    raise exception 'ACTIVE_PUBLISHED_SOURCE_REQUIRED' using errcode = '22023';
  end if;

  if v_assignment.assignment_type = 'assessment'::public.assignment_type then
    select rv.* into v_rubric
    from public.rubric_versions rv
    where rv.id = v_assignment.rubric_version_id;

    if not found
       or v_rubric.status <> 'approved'::public.rubric_status
       or v_rubric.activity_version_id <> v_activity.id
       or v_rubric.tesda_source_id <> v_source.id then
      raise exception 'APPROVED_MATCHING_RUBRIC_REQUIRED' using errcode = '22023';
    end if;
  end if;

  select a.* into v_attempt
  from public.attempts a
  where a.learner_id = (select auth.uid())
    and a.assignment_id = p_assignment_id
    and a.client_start_key = p_client_start_key;

  if found then
    return v_attempt;
  end if;

  insert into public.attempts (
    learner_id,
    class_id,
    assignment_id,
    activity_version_id,
    rubric_version_id,
    tesda_source_id,
    client_start_key
  )
  values (
    (select auth.uid()),
    v_assignment.class_id,
    v_assignment.id,
    v_activity.id,
    v_assignment.rubric_version_id,
    v_source.id,
    p_client_start_key
  )
  returning * into v_attempt;

  return v_attempt;
end
$$;

create or replace function public.append_attempt_action(
  p_attempt_id uuid,
  p_sequence_number integer,
  p_action_type text,
  p_target text,
  p_value jsonb,
  p_client_occurred_at timestamptz
)
returns public.attempt_actions
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_attempt public.attempts;
  v_action public.attempt_actions;
begin
  select a.* into v_attempt
  from public.attempts a
  where a.id = p_attempt_id
  for update;

  if not found or v_attempt.learner_id <> (select auth.uid()) then
    raise exception 'ATTEMPT_SCOPE_DENIED' using errcode = '42501';
  end if;

  if v_attempt.status <> 'in_progress'::public.attempt_status then
    raise exception 'ATTEMPT_NOT_IN_PROGRESS' using errcode = '22023';
  end if;

  if p_sequence_number <= 0 then
    raise exception 'INVALID_SEQUENCE_NUMBER' using errcode = '22023';
  end if;

  if p_client_occurred_at > now() + interval '5 minutes' then
    raise exception 'ACTION_TIME_IN_FUTURE' using errcode = '22023';
  end if;

  select aa.* into v_action
  from public.attempt_actions aa
  where aa.attempt_id = p_attempt_id
    and aa.sequence_number = p_sequence_number;

  if found then
    if v_action.action_type = btrim(p_action_type)
       and v_action.target is not distinct from nullif(btrim(p_target), '')
       and v_action.value = coalesce(p_value, '{}'::jsonb)
       and v_action.client_occurred_at = p_client_occurred_at then
      return v_action;
    end if;

    raise exception 'ACTION_SEQUENCE_CONFLICT' using errcode = '23505';
  end if;

  insert into public.attempt_actions (
    attempt_id,
    sequence_number,
    action_type,
    target,
    value,
    client_occurred_at
  )
  values (
    p_attempt_id,
    p_sequence_number,
    btrim(p_action_type),
    nullif(btrim(p_target), ''),
    coalesce(p_value, '{}'::jsonb),
    p_client_occurred_at
  )
  returning * into v_action;

  return v_action;
end
$$;

create or replace function public.submit_attempt(
  p_attempt_id uuid,
  p_submission_key uuid,
  p_elapsed_time_seconds integer
)
returns public.attempts
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_attempt public.attempts;
begin
  select a.* into v_attempt
  from public.attempts a
  where a.id = p_attempt_id
  for update;

  if not found or v_attempt.learner_id <> (select auth.uid()) then
    raise exception 'ATTEMPT_SCOPE_DENIED' using errcode = '42501';
  end if;

  if v_attempt.status <> 'in_progress'::public.attempt_status then
    if v_attempt.submission_key = p_submission_key then
      return v_attempt;
    end if;
    raise exception 'ATTEMPT_ALREADY_SUBMITTED' using errcode = '22023';
  end if;

  if p_elapsed_time_seconds < 0 then
    raise exception 'INVALID_ELAPSED_TIME' using errcode = '22023';
  end if;

  if not exists (
    select 1 from public.attempt_actions aa where aa.attempt_id = p_attempt_id
  ) then
    raise exception 'ATTEMPT_EVIDENCE_REQUIRED' using errcode = '22023';
  end if;

  update public.attempts
  set status = 'submitted'::public.attempt_status,
      submission_key = p_submission_key,
      submitted_at = now(),
      elapsed_time_seconds = p_elapsed_time_seconds
  where id = p_attempt_id
  returning * into v_attempt;

  return v_attempt;
end
$$;

create or replace function public.grant_coc_bypass(
  p_class_id uuid,
  p_learner_id uuid,
  p_module_version_id uuid,
  p_reason text,
  p_scope jsonb default '{}'::jsonb
)
returns public.coc_bypasses
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_bypass public.coc_bypasses;
begin
  if not public.instructor_owns_class(p_class_id) then
    raise exception 'CLASS_SCOPE_DENIED' using errcode = '42501';
  end if;

  if not public.learner_is_enrolled(p_class_id, p_learner_id) then
    raise exception 'ACTIVE_ENROLLMENT_REQUIRED' using errcode = '22023';
  end if;

  if nullif(btrim(p_reason), '') is null then
    raise exception 'BYPASS_REASON_REQUIRED' using errcode = '22023';
  end if;

  if not exists (
    select 1
    from public.module_versions mv
    join public.tesda_sources ts on ts.id = mv.tesda_source_id
    where mv.id = p_module_version_id
      and mv.status = 'published'::public.content_version_status
      and ts.status = 'active'::public.tesda_source_status
  ) then
    raise exception 'ACTIVE_PUBLISHED_MODULE_REQUIRED' using errcode = '22023';
  end if;

  insert into public.coc_bypasses (
    learner_id,
    class_id,
    module_version_id,
    instructor_id,
    reason,
    scope
  )
  values (
    p_learner_id,
    p_class_id,
    p_module_version_id,
    (select auth.uid()),
    btrim(p_reason),
    coalesce(p_scope, '{}'::jsonb)
  )
  returning * into v_bypass;

  perform private.write_audit_event(
    'coc_bypass.granted',
    'coc_bypass',
    v_bypass.id,
    null,
    to_jsonb(v_bypass),
    p_reason,
    jsonb_build_object(
      'class_id', p_class_id,
      'learner_id', p_learner_id,
      'module_version_id', p_module_version_id,
      'effect', 'UNLOCK_ACCESS_ONLY'
    )
  );

  return v_bypass;
end
$$;

revoke all on function public.create_class(text, text) from public, anon;
revoke all on function public.enroll_learner(uuid, uuid) from public, anon;
revoke all on function public.deactivate_class_membership(uuid, text) from public, anon;
revoke all on function public.assign_activity(uuid, uuid, uuid, public.assignment_type, text, text, timestamptz, timestamptz) from public, anon;
revoke all on function public.start_attempt(uuid, uuid) from public, anon;
revoke all on function public.append_attempt_action(uuid, integer, text, text, jsonb, timestamptz) from public, anon;
revoke all on function public.submit_attempt(uuid, uuid, integer) from public, anon;
revoke all on function public.grant_coc_bypass(uuid, uuid, uuid, text, jsonb) from public, anon;

grant execute on function public.create_class(text, text) to authenticated;
grant execute on function public.enroll_learner(uuid, uuid) to authenticated;
grant execute on function public.deactivate_class_membership(uuid, text) to authenticated;
grant execute on function public.assign_activity(uuid, uuid, uuid, public.assignment_type, text, text, timestamptz, timestamptz) to authenticated;
grant execute on function public.start_attempt(uuid, uuid) to authenticated;
grant execute on function public.append_attempt_action(uuid, integer, text, text, jsonb, timestamptz) to authenticated;
grant execute on function public.submit_attempt(uuid, uuid, integer) to authenticated;
grant execute on function public.grant_coc_bypass(uuid, uuid, uuid, text, jsonb) to authenticated;

commit;
