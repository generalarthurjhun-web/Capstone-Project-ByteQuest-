-- Close independent-review gaps without deleting or rewriting production data.
-- Adds a deterministic database evaluator whose values come only from an
-- Admin-approved rubric contract, rechecks learner access on every evidence
-- mutation, exposes bypassed practice content, and permits historical source
-- versions to finish their captured attempt lifecycle.

begin;

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

  return false;
end
$$;

create or replace function private.valid_binary_scoring_rule(
  p_rule jsonb,
  p_max_value numeric
)
returns boolean
language plpgsql
immutable
set search_path = ''
as $$
declare
  v_satisfied numeric;
  v_not_satisfied numeric;
begin
  if jsonb_typeof(p_rule) <> 'object'
     or p_rule->>'status' <> 'APPROVED'
     or p_rule->>'method' <> 'binary'
     or jsonb_typeof(p_rule->'satisfied_value') <> 'number'
     or jsonb_typeof(p_rule->'not_satisfied_value') <> 'number'
     or p_max_value is null
     or p_max_value <= 0 then
    return false;
  end if;

  begin
    v_satisfied := (p_rule->>'satisfied_value')::numeric;
    v_not_satisfied := (p_rule->>'not_satisfied_value')::numeric;
  exception when others then
    return false;
  end;

  return v_satisfied between 0 and p_max_value
    and v_not_satisfied between 0 and p_max_value;
end
$$;

create or replace function private.valid_passing_rule(p_rule jsonb)
returns boolean
language plpgsql
immutable
set search_path = ''
as $$
declare
  v_threshold numeric;
begin
  if jsonb_typeof(p_rule) <> 'object'
     or p_rule->>'status' <> 'APPROVED' then
    return false;
  end if;

  if p_rule->>'method' = 'all_required' then
    return true;
  end if;

  if p_rule->>'method' = 'minimum_percentage'
     and jsonb_typeof(p_rule->'threshold') = 'number' then
    begin
      v_threshold := (p_rule->>'threshold')::numeric;
    exception when others then
      return false;
    end;
    return v_threshold between 0 and 100;
  end if;

  return false;
end
$$;

create or replace function public.approve_rubric_version(
  p_rubric_version_id uuid,
  p_scoring_method text,
  p_passing_rule jsonb,
  p_reason text
)
returns public.rubric_versions
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_rubric public.rubric_versions;
  v_old jsonb;
begin
  if not public.is_admin() then
    raise exception 'ADMIN_REQUIRED' using errcode = '42501';
  end if;

  if nullif(btrim(p_reason), '') is null then
    raise exception 'APPROVAL_REASON_REQUIRED' using errcode = '22023';
  end if;

  if p_scoring_method <> 'binary_sum'
     or not private.valid_passing_rule(p_passing_rule) then
    raise exception 'SUPPORTED_APPROVED_SCORING_CONTRACT_REQUIRED' using errcode = '22023';
  end if;

  select rv.*
  into v_rubric
  from public.rubric_versions rv
  where rv.id = p_rubric_version_id
  for update;

  if not found then
    raise exception 'RUBRIC_NOT_FOUND' using errcode = 'P0002';
  end if;

  v_old := to_jsonb(v_rubric);

  if v_rubric.status not in (
    'pending_tesda_validation'::public.rubric_status,
    'draft'::public.rubric_status
  ) then
    raise exception 'RUBRIC_NOT_APPROVABLE' using errcode = '22023';
  end if;

  if not exists (
    select 1
    from public.tesda_sources ts
    where ts.id = v_rubric.tesda_source_id
      and ts.status = 'active'::public.tesda_source_status
  ) then
    raise exception 'ACTIVE_TESDA_SOURCE_REQUIRED' using errcode = '22023';
  end if;

  if not exists (
    select 1
    from public.activity_versions av
    where av.id = v_rubric.activity_version_id
      and av.status = 'published'::public.content_version_status
  ) then
    raise exception 'PUBLISHED_ACTIVITY_REQUIRED' using errcode = '22023';
  end if;

  if not exists (
    select 1
    from public.rubric_criteria rc
    where rc.rubric_version_id = v_rubric.id
  ) then
    raise exception 'RUBRIC_CRITERIA_REQUIRED' using errcode = '22023';
  end if;

  if exists (
    select 1
    from public.rubric_criteria rc
    where rc.rubric_version_id = v_rubric.id
      and (
        not private.valid_evidence_rule(rc.evidence_rule)
        or not private.valid_binary_scoring_rule(rc.scoring_rule, rc.max_value)
      )
  ) then
    raise exception 'SUPPORTED_CRITERION_RULES_REQUIRED' using errcode = '22023';
  end if;

  update public.rubric_versions
  set status = 'approved'::public.rubric_status,
      scoring_method = p_scoring_method,
      passing_rule = p_passing_rule,
      approved_by = (select auth.uid()),
      approved_at = now()
  where id = p_rubric_version_id
  returning * into v_rubric;

  perform private.write_audit_event(
    'rubric_version.approved',
    'rubric_version',
    v_rubric.id,
    v_old,
    to_jsonb(v_rubric),
    p_reason
  );

  return v_rubric;
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

create or replace function public.evaluate_submitted_attempt(p_attempt_id uuid)
returns public.score_revisions
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_attempt public.attempts;
  v_rubric public.rubric_versions;
  v_revision public.score_revisions;
  v_criterion public.rubric_criteria;
  v_evaluation jsonb;
  v_observation public.criterion_observation;
  v_score numeric;
  v_total numeric := 0;
  v_max numeric := 0;
  v_percentage numeric;
  v_outcome public.evaluation_outcome;
  v_values jsonb := '[]'::jsonb;
  v_run_id uuid := gen_random_uuid();
begin
  select a.* into v_attempt
  from public.attempts a
  where a.id = p_attempt_id
  for update;

  if not found then
    raise exception 'ATTEMPT_NOT_FOUND' using errcode = 'P0002';
  end if;

  if coalesce((select auth.role()), '') <> 'service_role'
     and (not public.is_learner() or v_attempt.learner_id <> (select auth.uid())) then
    raise exception 'ATTEMPT_SCOPE_DENIED' using errcode = '42501';
  end if;

  select sr.* into v_revision
  from public.score_revisions sr
  where sr.attempt_id = p_attempt_id
    and sr.revision_type = 'automated_provisional'::public.score_revision_type
  order by sr.revision_number
  limit 1;

  if found then
    return v_revision;
  end if;

  if v_attempt.status <> 'submitted'::public.attempt_status
     or v_attempt.rubric_version_id is null
     or v_attempt.tesda_source_id is null then
    raise exception 'SUBMITTED_VERSIONED_ASSESSMENT_REQUIRED' using errcode = '22023';
  end if;

  select rv.* into v_rubric
  from public.rubric_versions rv
  join public.tesda_sources ts on ts.id = rv.tesda_source_id
  where rv.id = v_attempt.rubric_version_id
    and rv.activity_version_id = v_attempt.activity_version_id
    and rv.tesda_source_id = v_attempt.tesda_source_id
    and rv.status = 'approved'::public.rubric_status
    and ts.status in (
      'active'::public.tesda_source_status,
      'superseded'::public.tesda_source_status
    );

  if not found
     or v_rubric.scoring_method <> 'binary_sum'
     or not private.valid_passing_rule(v_rubric.passing_rule) then
    raise exception 'SUPPORTED_APPROVED_RUBRIC_REQUIRED' using errcode = '22023';
  end if;

  for v_criterion in
    select rc.*
    from public.rubric_criteria rc
    where rc.rubric_version_id = v_rubric.id
    order by rc.order_index
  loop
    if not private.valid_binary_scoring_rule(v_criterion.scoring_rule, v_criterion.max_value) then
      raise exception 'SUPPORTED_CRITERION_RULE_REQUIRED' using errcode = '22023';
    end if;

    v_evaluation := private.evaluate_criterion_evidence(v_attempt.id, v_criterion.evidence_rule);
    v_observation := (v_evaluation->>'observation')::public.criterion_observation;
    v_score := case
      when v_observation = 'satisfied'::public.criterion_observation
        then (v_criterion.scoring_rule->>'satisfied_value')::numeric
      else (v_criterion.scoring_rule->>'not_satisfied_value')::numeric
    end;

    insert into public.criterion_results (
      attempt_id,
      rubric_criterion_id,
      evaluation_run_id,
      expected_rule,
      observed_evidence,
      observation,
      score_value
    )
    values (
      v_attempt.id,
      v_criterion.id,
      v_run_id,
      jsonb_build_object(
        'evidence_rule', v_criterion.evidence_rule,
        'scoring_rule', v_criterion.scoring_rule,
        'source_trace', v_criterion.source_trace
      ),
      v_evaluation->'observed_evidence',
      v_observation,
      v_score
    );

    v_total := v_total + v_score;
    v_max := v_max + v_criterion.max_value;
    v_values := v_values || jsonb_build_array(jsonb_build_object(
      'criterion_id', v_criterion.id,
      'observation', v_observation,
      'observed_evidence', v_evaluation->'observed_evidence',
      'score_value', v_score
    ));
  end loop;

  if v_max <= 0 then
    raise exception 'POSITIVE_RUBRIC_MAXIMUM_REQUIRED' using errcode = '22023';
  end if;

  v_percentage := round((v_total / v_max) * 100, 4);

  if v_rubric.passing_rule->>'method' = 'all_required' then
    select case when exists (
      select 1
      from public.criterion_results cr
      join public.rubric_criteria rc on rc.id = cr.rubric_criterion_id
      where cr.attempt_id = v_attempt.id
        and cr.evaluation_run_id = v_run_id
        and rc.is_required
        and cr.observation <> 'satisfied'::public.criterion_observation
    ) then 'not_yet_competent'::public.evaluation_outcome
    else 'competent'::public.evaluation_outcome end
    into v_outcome;
  else
    v_outcome := case
      when v_percentage >= (v_rubric.passing_rule->>'threshold')::numeric
        then 'competent'::public.evaluation_outcome
      else 'not_yet_competent'::public.evaluation_outcome
    end;
  end if;

  insert into public.score_revisions (
    attempt_id,
    revision_number,
    revision_type,
    actor_id,
    actor_role,
    tesda_source_id,
    rubric_version_id,
    evaluation_run_id,
    total_value,
    max_value,
    percentage,
    outcome,
    criterion_values,
    remarks
  )
  values (
    v_attempt.id,
    1,
    'automated_provisional'::public.score_revision_type,
    null,
    null,
    v_attempt.tesda_source_id,
    v_rubric.id,
    v_run_id,
    v_total,
    v_max,
    v_percentage,
    v_outcome,
    v_values,
    'Deterministic database evaluation from ordered attempt evidence and the approved rubric contract.'
  )
  returning * into v_revision;

  update public.attempts
  set status = 'evaluated'::public.attempt_status,
      evaluated_at = now()
  where id = v_attempt.id;

  perform private.write_audit_event(
    'attempt.provisional_evaluation_recorded',
    'attempt',
    v_attempt.id,
    null,
    to_jsonb(v_revision),
    null,
    jsonb_build_object('evaluation_run_id', v_run_id, 'engine', 'database_rule_v1')
  );

  return v_revision;
end
$$;

create or replace function private.assert_attempt_write_access(p_attempt public.attempts)
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.is_learner() or p_attempt.learner_id <> (select auth.uid()) then
    raise exception 'ACTIVE_LEARNER_ATTEMPT_REQUIRED' using errcode = '42501';
  end if;

  if not exists (
    select 1
    from public.assignments a
    join public.classes c on c.id = a.class_id
    join public.class_memberships cm
      on cm.class_id = a.class_id
     and cm.learner_id = p_attempt.learner_id
    where a.id = p_attempt.assignment_id
      and a.class_id = p_attempt.class_id
      and a.status = 'active'::public.assignment_status
      and c.status = 'active'::public.class_status
      and cm.status = 'active'::public.membership_status
      and (a.available_at is null or now() >= a.available_at)
      and (a.due_at is null or now() <= a.due_at)
  ) then
    raise exception 'ACTIVE_ASSIGNMENT_AND_ENROLLMENT_REQUIRED' using errcode = '42501';
  end if;
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

  if not found then
    raise exception 'ATTEMPT_NOT_FOUND' using errcode = 'P0002';
  end if;

  perform private.assert_attempt_write_access(v_attempt);

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
  v_assignment public.assignments;
begin
  select a.* into v_attempt
  from public.attempts a
  where a.id = p_attempt_id
  for update;

  if not found then
    raise exception 'ATTEMPT_NOT_FOUND' using errcode = 'P0002';
  end if;

  perform private.assert_attempt_write_access(v_attempt);

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

  select a.* into v_assignment
  from public.assignments a
  where a.id = v_attempt.assignment_id;

  if v_assignment.assignment_type = 'assessment'::public.assignment_type then
    perform public.evaluate_submitted_attempt(v_attempt.id);
    select a.* into v_attempt from public.attempts a where a.id = p_attempt_id;
  end if;

  return v_attempt;
end
$$;

create or replace function public.get_bypassed_activities()
returns table (
  bypass_id uuid,
  class_id uuid,
  class_title text,
  module_version_id uuid,
  activity_version_id uuid,
  activity_title text,
  instructions text,
  learner_payload jsonb,
  mission_id uuid,
  mission_code text,
  granted_at timestamptz
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    cb.id,
    cb.class_id,
    c.title,
    cb.module_version_id,
    av.id,
    av.title,
    av.instructions,
    av.learner_payload,
    m.id,
    m.mission_code,
    cb.granted_at
  from public.coc_bypasses cb
  join public.classes c
    on c.id = cb.class_id
   and c.status = 'active'::public.class_status
  join public.class_memberships cm
    on cm.class_id = cb.class_id
   and cm.learner_id = (select auth.uid())
   and cm.status = 'active'::public.membership_status
  join public.module_versions mv
    on mv.id = cb.module_version_id
   and mv.status = 'published'::public.content_version_status
  join public.tesda_sources ts
    on ts.id = mv.tesda_source_id
   and ts.status in (
     'active'::public.tesda_source_status,
     'superseded'::public.tesda_source_status
   )
  join public.activity_versions av
    on av.module_version_id = mv.id
   and av.status = 'published'::public.content_version_status
  join public.missions m on m.id = av.mission_id
  where public.is_learner()
    and cb.learner_id = (select auth.uid())
    and cb.revoked_at is null
  order by cb.granted_at desc, av.title;
$$;

revoke all on function private.valid_evidence_rule(jsonb) from public, anon, authenticated;
revoke all on function private.valid_binary_scoring_rule(jsonb, numeric) from public, anon, authenticated;
revoke all on function private.valid_passing_rule(jsonb) from public, anon, authenticated;
revoke all on function private.evaluate_criterion_evidence(uuid, jsonb) from public, anon, authenticated;
revoke all on function private.assert_attempt_write_access(public.attempts) from public, anon, authenticated;

revoke all on function public.evaluate_submitted_attempt(uuid) from public, anon;
grant execute on function public.evaluate_submitted_attempt(uuid) to authenticated, service_role;

revoke all on function public.get_bypassed_activities() from public, anon;
grant execute on function public.get_bypassed_activities() to authenticated;

revoke all on function public.append_attempt_action(uuid, integer, text, text, jsonb, timestamptz) from public, anon;
grant execute on function public.append_attempt_action(uuid, integer, text, text, jsonb, timestamptz) to authenticated;

revoke all on function public.submit_attempt(uuid, uuid, integer) from public, anon;
grant execute on function public.submit_attempt(uuid, uuid, integer) to authenticated;

comment on function public.evaluate_submitted_attempt(uuid) is
  'Derives criterion observations, values, percentage, and provisional outcome inside PostgreSQL from ordered attempt_actions and an Admin-approved rubric rule contract. No client score input is accepted.';

comment on function public.get_bypassed_activities() is
  'Returns published practice content operationally unlocked by an active Instructor COC bypass. It creates no attempt, score, competency, or reward.';

commit;
