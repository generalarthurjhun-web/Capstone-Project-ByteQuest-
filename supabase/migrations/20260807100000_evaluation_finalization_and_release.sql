-- Trusted provisional evaluation ingestion, append-only Instructor review,
-- finalization, and release.

begin;

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

  if nullif(btrim(p_scoring_method), '') is null
     or p_scoring_method = 'PENDING_TESDA_VALIDATION'
     or coalesce(p_passing_rule->>'status', 'PENDING_TESDA_VALIDATION') = 'PENDING_TESDA_VALIDATION' then
    raise exception 'APPROVED_TESDA_SCORING_RULE_REQUIRED' using errcode = '22023';
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
      and coalesce(rc.scoring_rule->>'status', 'PENDING_TESDA_VALIDATION') = 'PENDING_TESDA_VALIDATION'
  ) then
    raise exception 'CRITERION_SCORING_RULE_PENDING' using errcode = '22023';
  end if;

  update public.rubric_versions
  set status = 'approved'::public.rubric_status,
      scoring_method = btrim(p_scoring_method),
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

create or replace function public.record_provisional_evaluation(
  p_attempt_id uuid,
  p_evaluation_run_id uuid,
  p_criterion_results jsonb,
  p_total_value numeric,
  p_max_value numeric,
  p_percentage numeric,
  p_outcome public.evaluation_outcome,
  p_remarks text default null
)
returns public.score_revisions
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_attempt public.attempts;
  v_rubric public.rubric_versions;
  v_revision public.score_revisions;
  v_expected_count integer;
  v_input_count integer;
  v_distinct_count integer;
begin
  if coalesce((select auth.role()), '') <> 'service_role' then
    raise exception 'TRUSTED_EVALUATOR_REQUIRED' using errcode = '42501';
  end if;

  if jsonb_typeof(p_criterion_results) <> 'array'
     or jsonb_array_length(p_criterion_results) = 0 then
    raise exception 'CRITERION_RESULTS_REQUIRED' using errcode = '22023';
  end if;

  if p_outcome = 'pending_tesda_validation'::public.evaluation_outcome then
    raise exception 'TESDA_VALIDATION_REQUIRED_BEFORE_EVALUATION' using errcode = '22023';
  end if;

  if p_total_value is not null and p_total_value < 0 then
    raise exception 'INVALID_TOTAL_VALUE' using errcode = '22023';
  end if;

  if p_max_value is not null and p_max_value <= 0 then
    raise exception 'INVALID_MAX_VALUE' using errcode = '22023';
  end if;

  if p_percentage is not null and (p_percentage < 0 or p_percentage > 100) then
    raise exception 'INVALID_PERCENTAGE' using errcode = '22023';
  end if;

  select sr.* into v_revision
  from public.score_revisions sr
  where sr.attempt_id = p_attempt_id
    and sr.evaluation_run_id = p_evaluation_run_id
    and sr.revision_type = 'automated_provisional'::public.score_revision_type;

  if found then
    return v_revision;
  end if;

  select a.* into v_attempt
  from public.attempts a
  where a.id = p_attempt_id
  for update;

  if not found or v_attempt.status <> 'submitted'::public.attempt_status then
    raise exception 'SUBMITTED_ATTEMPT_REQUIRED' using errcode = '22023';
  end if;

  if v_attempt.rubric_version_id is null or v_attempt.tesda_source_id is null then
    raise exception 'VERSIONED_RUBRIC_AND_SOURCE_REQUIRED' using errcode = '22023';
  end if;

  select rv.* into v_rubric
  from public.rubric_versions rv
  join public.tesda_sources ts on ts.id = rv.tesda_source_id
  where rv.id = v_attempt.rubric_version_id
    and rv.activity_version_id = v_attempt.activity_version_id
    and rv.tesda_source_id = v_attempt.tesda_source_id
    and rv.status = 'approved'::public.rubric_status
    and ts.status = 'active'::public.tesda_source_status;

  if not found then
    raise exception 'APPROVED_ACTIVE_RUBRIC_REQUIRED' using errcode = '22023';
  end if;

  select count(*) into v_expected_count
  from public.rubric_criteria rc
  where rc.rubric_version_id = v_rubric.id;

  select count(*), count(distinct input.criterion_id)
  into v_input_count, v_distinct_count
  from jsonb_to_recordset(p_criterion_results) as input(
    criterion_id uuid,
    observation text,
    observed_evidence jsonb,
    score_value numeric,
    remarks text
  );

  if v_input_count <> v_expected_count or v_distinct_count <> v_expected_count then
    raise exception 'EXACTLY_ONE_RESULT_PER_RUBRIC_CRITERION_REQUIRED' using errcode = '22023';
  end if;

  if exists (
    select 1
    from jsonb_to_recordset(p_criterion_results) as input(
      criterion_id uuid,
      observation text,
      observed_evidence jsonb,
      score_value numeric,
      remarks text
    )
    left join public.rubric_criteria rc
      on rc.id = input.criterion_id
     and rc.rubric_version_id = v_rubric.id
    where rc.id is null
       or input.observation not in (
         'satisfied', 'not_satisfied', 'not_evaluated', 'requires_review'
       )
       or input.score_value < 0
  ) then
    raise exception 'INVALID_CRITERION_RESULT' using errcode = '22023';
  end if;

  insert into public.criterion_results (
    attempt_id,
    rubric_criterion_id,
    evaluation_run_id,
    expected_rule,
    observed_evidence,
    observation,
    score_value,
    remarks
  )
  select
    v_attempt.id,
    rc.id,
    p_evaluation_run_id,
    jsonb_build_object(
      'evidence_rule', rc.evidence_rule,
      'scoring_rule', rc.scoring_rule,
      'source_trace', rc.source_trace
    ),
    coalesce(input.observed_evidence, '{}'::jsonb),
    input.observation::public.criterion_observation,
    input.score_value,
    nullif(btrim(input.remarks), '')
  from jsonb_to_recordset(p_criterion_results) as input(
    criterion_id uuid,
    observation text,
    observed_evidence jsonb,
    score_value numeric,
    remarks text
  )
  join public.rubric_criteria rc
    on rc.id = input.criterion_id
   and rc.rubric_version_id = v_rubric.id;

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
    p_evaluation_run_id,
    p_total_value,
    p_max_value,
    p_percentage,
    p_outcome,
    p_criterion_results,
    nullif(btrim(p_remarks), '')
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
    jsonb_build_object('evaluation_run_id', p_evaluation_run_id)
  );

  return v_revision;
end
$$;

create or replace function public.finalize_attempt(
  p_attempt_id uuid,
  p_total_value numeric,
  p_max_value numeric,
  p_percentage numeric,
  p_outcome public.evaluation_outcome,
  p_criterion_values jsonb,
  p_reason text default null,
  p_remarks text default null
)
returns public.score_revisions
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_attempt public.attempts;
  v_latest public.score_revisions;
  v_adjustment public.score_revisions;
  v_final public.score_revisions;
  v_next integer;
  v_changed boolean;
  v_values jsonb;
begin
  select a.* into v_attempt
  from public.attempts a
  where a.id = p_attempt_id
  for update;

  if not found or not public.instructor_owns_class(v_attempt.class_id) then
    raise exception 'CLASS_SCOPE_DENIED' using errcode = '42501';
  end if;

  if v_attempt.status <> 'evaluated'::public.attempt_status then
    raise exception 'EVALUATED_ATTEMPT_REQUIRED' using errcode = '22023';
  end if;

  if p_outcome = 'pending_tesda_validation'::public.evaluation_outcome then
    raise exception 'FINAL_OUTCOME_REQUIRES_APPROVED_TESDA_RULE' using errcode = '22023';
  end if;

  if p_total_value is not null and p_total_value < 0 then
    raise exception 'INVALID_TOTAL_VALUE' using errcode = '22023';
  end if;

  if p_max_value is not null and p_max_value <= 0 then
    raise exception 'INVALID_MAX_VALUE' using errcode = '22023';
  end if;

  if p_percentage is not null and (p_percentage < 0 or p_percentage > 100) then
    raise exception 'INVALID_PERCENTAGE' using errcode = '22023';
  end if;

  select sr.* into v_latest
  from public.score_revisions sr
  where sr.attempt_id = p_attempt_id
  order by sr.revision_number desc
  limit 1;

  if not found or v_latest.revision_type <> 'automated_provisional'::public.score_revision_type then
    raise exception 'PROVISIONAL_REVISION_REQUIRED' using errcode = '22023';
  end if;

  v_values := coalesce(p_criterion_values, v_latest.criterion_values);
  if jsonb_typeof(v_values) <> 'array' then
    raise exception 'CRITERION_VALUES_MUST_BE_ARRAY' using errcode = '22023';
  end if;

  v_changed :=
    p_total_value is distinct from v_latest.total_value
    or p_max_value is distinct from v_latest.max_value
    or p_percentage is distinct from v_latest.percentage
    or p_outcome is distinct from v_latest.outcome
    or v_values is distinct from v_latest.criterion_values;

  if v_changed and nullif(btrim(p_reason), '') is null then
    raise exception 'ADJUSTMENT_REASON_REQUIRED' using errcode = '22023';
  end if;

  v_next := v_latest.revision_number + 1;

  if v_changed then
    insert into public.score_revisions (
      attempt_id,
      revision_number,
      revision_type,
      supersedes_revision_id,
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
      reason,
      remarks
    )
    values (
      v_attempt.id,
      v_next,
      'instructor_adjustment'::public.score_revision_type,
      v_latest.id,
      (select auth.uid()),
      'instructor'::public.user_role,
      v_latest.tesda_source_id,
      v_latest.rubric_version_id,
      v_latest.evaluation_run_id,
      p_total_value,
      p_max_value,
      p_percentage,
      p_outcome,
      v_values,
      btrim(p_reason),
      nullif(btrim(p_remarks), '')
    )
    returning * into v_adjustment;

    perform private.write_audit_event(
      'score.adjusted',
      'attempt',
      v_attempt.id,
      to_jsonb(v_latest),
      to_jsonb(v_adjustment),
      p_reason
    );

    v_latest := v_adjustment;
    v_next := v_next + 1;
  end if;

  insert into public.score_revisions (
    attempt_id,
    revision_number,
    revision_type,
    supersedes_revision_id,
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
    reason,
    remarks
  )
  values (
    v_attempt.id,
    v_next,
    'instructor_final'::public.score_revision_type,
    v_latest.id,
    (select auth.uid()),
    'instructor'::public.user_role,
    v_latest.tesda_source_id,
    v_latest.rubric_version_id,
    v_latest.evaluation_run_id,
    p_total_value,
    p_max_value,
    p_percentage,
    p_outcome,
    v_values,
    nullif(btrim(p_reason), ''),
    nullif(btrim(p_remarks), '')
  )
  returning * into v_final;

  update public.attempts
  set status = 'finalized'::public.attempt_status,
      finalized_at = now()
  where id = v_attempt.id;

  perform private.write_audit_event(
    'score.finalized',
    'attempt',
    v_attempt.id,
    to_jsonb(v_latest),
    to_jsonb(v_final),
    p_reason
  );

  return v_final;
end
$$;

create or replace function public.release_attempt(
  p_attempt_id uuid,
  p_release_reason text default null
)
returns public.result_releases
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_attempt public.attempts;
  v_revision public.score_revisions;
  v_release public.result_releases;
  v_release_number integer;
  v_mission_id uuid;
  v_coc_id uuid;
  v_projected_score integer;
begin
  select a.* into v_attempt
  from public.attempts a
  where a.id = p_attempt_id
  for update;

  if not found or not public.instructor_owns_class(v_attempt.class_id) then
    raise exception 'CLASS_SCOPE_DENIED' using errcode = '42501';
  end if;

  select rr.* into v_release
  from public.result_releases rr
  where rr.attempt_id = p_attempt_id
    and rr.is_current;

  if v_attempt.status = 'released'::public.attempt_status and found then
    return v_release;
  end if;

  if v_attempt.status <> 'finalized'::public.attempt_status then
    raise exception 'FINALIZED_ATTEMPT_REQUIRED' using errcode = '22023';
  end if;

  select sr.* into v_revision
  from public.score_revisions sr
  where sr.attempt_id = p_attempt_id
    and sr.revision_type = 'instructor_final'::public.score_revision_type
  order by sr.revision_number desc
  limit 1;

  if not found then
    raise exception 'FINAL_REVISION_REQUIRED' using errcode = '22023';
  end if;

  select coalesce(max(rr.release_number), 0) + 1
  into v_release_number
  from public.result_releases rr
  where rr.attempt_id = p_attempt_id;

  insert into public.result_releases (
    attempt_id,
    score_revision_id,
    release_number,
    released_by,
    release_reason
  )
  values (
    p_attempt_id,
    v_revision.id,
    v_release_number,
    (select auth.uid()),
    nullif(btrim(p_release_reason), '')
  )
  returning * into v_release;

  update public.attempts
  set status = 'released'::public.attempt_status,
      released_at = v_release.released_at
  where id = p_attempt_id;

  select m.id, m.coc_id
  into v_mission_id, v_coc_id
  from public.activity_versions av
  join public.missions m on m.id = av.mission_id
  where av.id = v_attempt.activity_version_id;

  v_projected_score := coalesce(round(v_revision.percentage)::integer, 0);

  if v_mission_id is not null and v_coc_id is not null then
    insert into public.learner_progress (
      user_id,
      coc_id,
      mission_id,
      status,
      completion_percentage,
      best_score,
      latest_score,
      attempts_count,
      last_activity_at,
      unlocked_at,
      started_at,
      completed_at
    )
    values (
      v_attempt.learner_id,
      v_coc_id,
      v_mission_id,
      case
        when v_revision.outcome = 'competent'::public.evaluation_outcome
          then 'completed'::public.progress_status
        else 'failed'::public.progress_status
      end,
      100,
      v_projected_score,
      v_projected_score,
      1,
      now(),
      coalesce(v_attempt.started_at, now()),
      v_attempt.started_at,
      case
        when v_revision.outcome = 'competent'::public.evaluation_outcome
          then v_release.released_at
        else null
      end
    )
    on conflict (user_id, mission_id) do update
    set status = excluded.status,
        completion_percentage = 100,
        best_score = greatest(public.learner_progress.best_score, excluded.best_score),
        latest_score = excluded.latest_score,
        attempts_count = (
          select count(*)::integer
          from public.attempts a
          where a.learner_id = v_attempt.learner_id
            and a.activity_version_id = v_attempt.activity_version_id
        ),
        last_activity_at = now(),
        completed_at = case
          when v_revision.outcome = 'competent'::public.evaluation_outcome
            then v_release.released_at
          else public.learner_progress.completed_at
        end,
        updated_at = now();
  end if;

  insert into public.gamification_events (
    learner_id,
    event_type,
    source_type,
    source_id,
    idempotency_key,
    xp_delta,
    points_delta,
    metadata,
    created_by
  )
  values (
    v_attempt.learner_id,
    'assessment_result_released',
    'attempt',
    v_attempt.id,
    'release:' || v_attempt.id::text || ':' || v_revision.id::text,
    0,
    0,
    jsonb_build_object(
      'score_revision_id', v_revision.id,
      'reward_status', 'PENDING_APPROVED_GAMIFICATION_CONFIGURATION'
    ),
    (select auth.uid())
  )
  on conflict (learner_id, idempotency_key) do nothing;

  perform private.write_audit_event(
    'result.released',
    'attempt',
    v_attempt.id,
    null,
    to_jsonb(v_release),
    p_release_reason,
    jsonb_build_object('score_revision_id', v_revision.id)
  );

  return v_release;
end
$$;

revoke all on function public.approve_rubric_version(uuid, text, jsonb, text) from public, anon;
revoke all on function public.record_provisional_evaluation(uuid, uuid, jsonb, numeric, numeric, numeric, public.evaluation_outcome, text) from public, anon, authenticated;
revoke all on function public.finalize_attempt(uuid, numeric, numeric, numeric, public.evaluation_outcome, jsonb, text, text) from public, anon;
revoke all on function public.release_attempt(uuid, text) from public, anon;

grant execute on function public.approve_rubric_version(uuid, text, jsonb, text) to authenticated;
grant execute on function public.record_provisional_evaluation(uuid, uuid, jsonb, numeric, numeric, numeric, public.evaluation_outcome, text) to service_role;
grant execute on function public.finalize_attempt(uuid, numeric, numeric, numeric, public.evaluation_outcome, jsonb, text, text) to authenticated;
grant execute on function public.release_attempt(uuid, text) to authenticated;

commit;
