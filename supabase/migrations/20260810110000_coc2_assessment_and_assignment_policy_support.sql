-- Support the approved COC2 cable-termination assessment and optional,
-- Instructor-configured assignment access rules. This migration does not seed
-- a TESDA source or invent retry limits, thresholds, or numeric weights.

begin;

alter table public.assignments
  add column if not exists attempts_allowed integer,
  add column if not exists retry_enabled boolean not null default true,
  add column if not exists retry_after_seconds integer,
  add column if not exists prerequisite_assignment_id uuid
    references public.assignments(id) on delete restrict;

alter table public.assignments
  drop constraint if exists assignments_attempts_allowed_check,
  add constraint assignments_attempts_allowed_check
    check (attempts_allowed is null or attempts_allowed > 0),
  drop constraint if exists assignments_retry_after_seconds_check,
  add constraint assignments_retry_after_seconds_check
    check (retry_after_seconds is null or retry_after_seconds >= 0),
  drop constraint if exists assignments_prerequisite_not_self_check,
  add constraint assignments_prerequisite_not_self_check
    check (prerequisite_assignment_id is null or prerequisite_assignment_id <> id);

create index if not exists assignments_prerequisite_idx
  on public.assignments(prerequisite_assignment_id)
  where prerequisite_assignment_id is not null;

create or replace function private.valid_evidence_rule(p_rule jsonb)
returns boolean
language plpgsql
immutable
set search_path = ''
as $$
declare
  v_operator text := p_rule->>'operator';
  v_minimum integer;
begin
  if jsonb_typeof(p_rule) <> 'object' then
    return false;
  end if;

  if v_operator = 'action_exists' then
    if nullif(btrim(p_rule->>'action_type'), '') is null
       or jsonb_typeof(p_rule->'minimum_count') <> 'number'
       or (p_rule ? 'value_contains' and jsonb_typeof(p_rule->'value_contains') <> 'object') then
      return false;
    end if;
    begin
      v_minimum := (p_rule->>'minimum_count')::integer;
    exception when others then
      return false;
    end;
    return v_minimum > 0;
  end if;

  if v_operator = 'exact_target_sequence' then
    return nullif(btrim(p_rule->>'action_type'), '') is not null
      and jsonb_typeof(p_rule->'expected_targets') = 'array'
      and jsonb_array_length(p_rule->'expected_targets') > 0
      and not exists (
        select 1
        from jsonb_array_elements(p_rule->'expected_targets') item
        where jsonb_typeof(item) <> 'string'
      );
  end if;

  if v_operator = 'final_action_value_equals' then
    return nullif(btrim(p_rule->>'action_type'), '') is not null
      and nullif(btrim(p_rule->>'value_key'), '') is not null
      and p_rule ? 'expected';
  end if;

  if v_operator = 'final_action_value_set_equals' then
    return nullif(btrim(p_rule->>'action_type'), '') is not null
      and nullif(btrim(p_rule->>'value_key'), '') is not null
      and jsonb_typeof(p_rule->'expected') = 'array'
      and jsonb_array_length(p_rule->'expected') > 0
      and not exists (
        select 1
        from jsonb_array_elements(p_rule->'expected') item
        where jsonb_typeof(item) <> 'string'
      );
  end if;

  return false;
end
$$;

create or replace function private.evaluate_criterion_evidence(
  p_attempt_id uuid,
  p_rule jsonb
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_operator text := p_rule->>'operator';
  v_count integer;
  v_actions jsonb;
  v_observed jsonb;
  v_expected_set jsonb;
  v_observed_set jsonb;
begin
  if not private.valid_evidence_rule(p_rule) then
    raise exception 'UNSUPPORTED_EVIDENCE_RULE' using errcode = '22023';
  end if;

  if v_operator = 'action_exists' then
    select count(*)::integer,
           coalesce(
             jsonb_agg(
               jsonb_build_object(
                 'sequence_number', aa.sequence_number,
                 'action_type', aa.action_type,
                 'target', aa.target,
                 'value', aa.value,
                 'client_occurred_at', aa.client_occurred_at
               ) order by aa.sequence_number
             ),
             '[]'::jsonb
           )
    into v_count, v_actions
    from public.attempt_actions aa
    where aa.attempt_id = p_attempt_id
      and aa.action_type = p_rule->>'action_type'
      and (not (p_rule ? 'target') or aa.target = p_rule->>'target')
      and (not (p_rule ? 'value_contains') or aa.value @> p_rule->'value_contains');

    return jsonb_build_object(
      'observation', case
        when v_count >= (p_rule->>'minimum_count')::integer then 'satisfied'
        else 'not_satisfied'
      end,
      'observed_evidence', jsonb_build_object(
        'matching_count', v_count,
        'required_count', (p_rule->>'minimum_count')::integer,
        'matching_actions', v_actions
      )
    );
  end if;

  if v_operator = 'exact_target_sequence' then
    select coalesce(jsonb_agg(to_jsonb(aa.target) order by aa.sequence_number), '[]'::jsonb)
    into v_observed
    from public.attempt_actions aa
    where aa.attempt_id = p_attempt_id
      and aa.action_type = p_rule->>'action_type';

    return jsonb_build_object(
      'observation', case
        when v_observed = p_rule->'expected_targets' then 'satisfied'
        else 'not_satisfied'
      end,
      'observed_evidence', jsonb_build_object(
        'observed_targets', v_observed,
        'expected_targets', p_rule->'expected_targets'
      )
    );
  end if;

  select aa.value->(p_rule->>'value_key')
  into v_observed
  from public.attempt_actions aa
  where aa.attempt_id = p_attempt_id
    and aa.action_type = p_rule->>'action_type'
  order by aa.sequence_number desc
  limit 1;

  v_count := case when found then 1 else 0 end;

  if v_operator = 'final_action_value_set_equals' then
    select coalesce(jsonb_agg(to_jsonb(item.value) order by item.value), '[]'::jsonb)
    into v_expected_set
    from (
      select distinct jsonb_array_elements_text(p_rule->'expected') as value
    ) item;

    if v_count = 1 and jsonb_typeof(v_observed) = 'array' then
      select coalesce(jsonb_agg(to_jsonb(item.value) order by item.value), '[]'::jsonb)
      into v_observed_set
      from (
        select distinct jsonb_array_elements_text(v_observed) as value
      ) item;
    else
      v_observed_set := '[]'::jsonb;
    end if;

    return jsonb_build_object(
      'observation', case
        when v_count = 1 and v_observed_set = v_expected_set then 'satisfied'
        else 'not_satisfied'
      end,
      'observed_evidence', jsonb_build_object(
        'observed_values', coalesce(v_observed, 'null'::jsonb),
        'expected_values', p_rule->'expected',
        'normalized_observed_values', v_observed_set,
        'normalized_expected_values', v_expected_set,
        'value_key', p_rule->>'value_key'
      )
    );
  end if;

  return jsonb_build_object(
    'observation', case
      when v_count = 1 and v_observed is not distinct from p_rule->'expected' then 'satisfied'
      else 'not_satisfied'
    end,
    'observed_evidence', jsonb_build_object(
      'observed_value', v_observed,
      'expected_value', p_rule->'expected',
      'value_key', p_rule->>'value_key'
    )
  );
end
$$;

create or replace function public.configure_assignment_access(
  p_assignment_id uuid,
  p_attempts_allowed integer default null,
  p_retry_enabled boolean default true,
  p_retry_after_seconds integer default null,
  p_prerequisite_assignment_id uuid default null,
  p_reason text default null
)
returns public.assignments
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_assignment public.assignments;
  v_prerequisite public.assignments;
  v_old jsonb;
begin
  select a.* into v_assignment
  from public.assignments a
  where a.id = p_assignment_id
  for update;

  if not found then
    raise exception 'ASSIGNMENT_NOT_FOUND' using errcode = 'P0002';
  end if;

  if not public.instructor_owns_class(v_assignment.class_id) then
    raise exception 'CLASS_SCOPE_DENIED' using errcode = '42501';
  end if;

  if nullif(btrim(p_reason), '') is null then
    raise exception 'POLICY_REASON_REQUIRED' using errcode = '22023';
  end if;

  if p_attempts_allowed is not null and p_attempts_allowed <= 0 then
    raise exception 'INVALID_ATTEMPT_LIMIT' using errcode = '22023';
  end if;

  if p_retry_after_seconds is not null and p_retry_after_seconds < 0 then
    raise exception 'INVALID_RETRY_DELAY' using errcode = '22023';
  end if;

  if p_prerequisite_assignment_id is not null then
    select a.* into v_prerequisite
    from public.assignments a
    where a.id = p_prerequisite_assignment_id;

    if not found
       or v_prerequisite.id = v_assignment.id
       or v_prerequisite.class_id <> v_assignment.class_id then
      raise exception 'INVALID_CLASS_PREREQUISITE' using errcode = '22023';
    end if;

    if exists (
      with recursive ancestors(id, prerequisite_assignment_id) as (
        select a.id, a.prerequisite_assignment_id
        from public.assignments a
        where a.id = p_prerequisite_assignment_id
        union all
        select a.id, a.prerequisite_assignment_id
        from public.assignments a
        join ancestors x on x.prerequisite_assignment_id = a.id
      )
      select 1 from ancestors where id = p_assignment_id
    ) then
      raise exception 'PREREQUISITE_CYCLE_DENIED' using errcode = '22023';
    end if;
  end if;

  v_old := to_jsonb(v_assignment);

  update public.assignments
  set attempts_allowed = p_attempts_allowed,
      retry_enabled = coalesce(p_retry_enabled, true),
      retry_after_seconds = p_retry_after_seconds,
      prerequisite_assignment_id = p_prerequisite_assignment_id
  where id = p_assignment_id
  returning * into v_assignment;

  perform private.write_audit_event(
    'assignment.access_policy_configured',
    'assignment',
    v_assignment.id,
    v_old,
    to_jsonb(v_assignment),
    p_reason,
    jsonb_build_object(
      'tesda_numeric_rule', false,
      'policy_classification', 'PROJECT_CONFIGURABLE_OPERATIONAL_RULE'
    )
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
  v_attempt_count integer;
  v_latest_completed_at timestamptz;
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

  select a.* into v_attempt
  from public.attempts a
  where a.learner_id = (select auth.uid())
    and a.assignment_id = p_assignment_id
    and a.client_start_key = p_client_start_key;

  if found then
    return v_attempt;
  end if;

  if exists (
    select 1 from public.attempts a
    where a.learner_id = (select auth.uid())
      and a.assignment_id = p_assignment_id
      and a.status = 'in_progress'::public.attempt_status
  ) then
    raise exception 'ATTEMPT_ALREADY_IN_PROGRESS' using errcode = '22023';
  end if;

  select count(*)::integer,
         max(coalesce(a.submitted_at, a.evaluated_at, a.started_at))
  into v_attempt_count, v_latest_completed_at
  from public.attempts a
  where a.learner_id = (select auth.uid())
    and a.assignment_id = p_assignment_id;

  if not v_assignment.retry_enabled and v_attempt_count > 0 then
    raise exception 'RETRY_NOT_ENABLED' using errcode = '22023';
  end if;

  if v_assignment.attempts_allowed is not null
     and v_attempt_count >= v_assignment.attempts_allowed then
    raise exception 'ATTEMPT_LIMIT_REACHED' using errcode = '22023';
  end if;

  if v_assignment.retry_after_seconds is not null
     and v_latest_completed_at is not null
     and now() < v_latest_completed_at + make_interval(secs => v_assignment.retry_after_seconds) then
    raise exception 'RETRY_WAIT_REQUIRED' using errcode = '22023';
  end if;

  if v_assignment.prerequisite_assignment_id is not null
     and not exists (
       select 1
       from public.attempts pa
       join public.result_releases rr
         on rr.attempt_id = pa.id and rr.is_current
       join public.score_revisions sr
         on sr.id = rr.score_revision_id
       where pa.learner_id = (select auth.uid())
         and pa.assignment_id = v_assignment.prerequisite_assignment_id
         and pa.status = 'released'::public.attempt_status
         and sr.outcome = 'competent'::public.evaluation_outcome
     ) then
    raise exception 'PREREQUISITE_NOT_SATISFIED' using errcode = '22023';
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

  perform private.write_audit_event(
    'attempt.started',
    'attempt',
    v_attempt.id,
    null,
    to_jsonb(v_attempt),
    null,
    jsonb_build_object('assignment_id', p_assignment_id)
  );

  return v_attempt;
end
$$;

revoke all on function public.configure_assignment_access(uuid, integer, boolean, integer, uuid, text)
  from public, anon;
grant execute on function public.configure_assignment_access(uuid, integer, boolean, integer, uuid, text)
  to authenticated;

revoke all on function private.valid_evidence_rule(jsonb) from public, anon, authenticated;
revoke all on function private.evaluate_criterion_evidence(uuid, jsonb) from public, anon, authenticated;

comment on function public.configure_assignment_access(uuid, integer, boolean, integer, uuid, text) is
  'Configures optional Instructor-owned assignment limits and prerequisites. Null limits mean no institutional limit; values are operational configuration, never TESDA numeric rules.';

commit;
