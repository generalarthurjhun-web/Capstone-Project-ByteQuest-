-- ByteQuest scoped analytics and reporting
-- Read-only, role-checked aggregation functions. No assessment authority is moved
-- out of the existing evidence/evaluation/finalization lifecycle.

create index if not exists result_releases_current_released_at_idx
  on public.result_releases (released_at desc)
  where is_current;

create index if not exists criterion_results_criterion_evaluated_idx
  on public.criterion_results (rubric_criterion_id, evaluated_at desc);

create or replace function public.get_instructor_analytics(
  p_class_id uuid default null,
  p_coc_id uuid default null,
  p_mission_id uuid default null,
  p_from timestamptz default (now() - interval '30 days'),
  p_to timestamptz default now()
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_actor_id uuid := auth.uid();
  v_from timestamptz := coalesce(p_from, now() - interval '30 days');
  v_to timestamptz := coalesce(p_to, now());
  v_result jsonb;
begin
  if v_actor_id is null
     or not public.is_active_user()
     or not public.is_instructor() then
    raise exception 'Active Instructor authentication is required'
      using errcode = '42501';
  end if;

  if v_from > v_to then
    raise exception 'Analytics start date must be before the end date'
      using errcode = '22023';
  end if;

  if v_to - v_from > interval '366 days' then
    raise exception 'Analytics date range cannot exceed 366 days'
      using errcode = '22023';
  end if;

  if p_class_id is not null and not exists (
    select 1
    from public.classes c
    where c.id = p_class_id
      and c.instructor_id = v_actor_id
  ) then
    raise exception 'Class is outside the current Instructor scope'
      using errcode = '42501';
  end if;

  with
  owned_classes as (
    select c.id, c.title, c.class_code, c.status
    from public.classes c
    where c.instructor_id = v_actor_id
      and (p_class_id is null or c.id = p_class_id)
  ),
  scope_assignments as (
    select distinct
      a.id as assignment_id,
      a.class_id,
      a.title as assignment_title,
      av.id as activity_version_id,
      av.title as activity_title,
      m.id as mission_id,
      m.mission_code,
      m.mission_number,
      m.title as mission_title,
      cm.id as coc_id,
      upper(cm.coc_code) as coc_code,
      coalesce(nullif(cm.title, ''), cm.module_name) as coc_title
    from public.assignments a
    join owned_classes oc on oc.id = a.class_id
    join public.activity_versions av on av.id = a.activity_version_id
    join public.missions m on m.id = av.mission_id
    join public.coc_modules cm on cm.id = m.coc_id
    where (p_coc_id is null or cm.id = p_coc_id)
      and (p_mission_id is null or m.id = p_mission_id)
  ),
  base_attempts as (
    select
      at.id,
      at.learner_id,
      at.class_id,
      at.assignment_id,
      at.status::text as status,
      at.started_at,
      at.submitted_at,
      at.evaluated_at,
      at.finalized_at,
      at.released_at,
      at.elapsed_time_seconds,
      coalesce(at.submitted_at, at.started_at, at.created_at) as event_at,
      sa.assignment_title,
      sa.activity_version_id,
      sa.activity_title,
      sa.mission_id,
      sa.mission_code,
      sa.mission_number,
      sa.mission_title,
      sa.coc_id,
      sa.coc_code,
      sa.coc_title,
      oc.title as class_title
    from public.attempts at
    join scope_assignments sa
      on sa.assignment_id = at.assignment_id
     and sa.class_id = at.class_id
    join owned_classes oc on oc.id = at.class_id
    where coalesce(at.submitted_at, at.started_at, at.created_at) >= v_from
      and coalesce(at.submitted_at, at.started_at, at.created_at) <= v_to
  ),
  latest_criteria as (
    select distinct on (cr.attempt_id, cr.rubric_criterion_id)
      cr.attempt_id,
      cr.rubric_criterion_id,
      cr.observation::text as observation,
      cr.evaluated_at
    from public.criterion_results cr
    join base_attempts ba on ba.id = cr.attempt_id
    order by cr.attempt_id, cr.rubric_criterion_id, cr.evaluated_at desc, cr.id desc
  ),
  current_releases as (
    select
      rr.attempt_id,
      rr.released_at,
      rr.release_reason,
      sr.id as revision_id,
      sr.outcome::text as outcome,
      sr.percentage,
      sr.remarks
    from public.result_releases rr
    join public.score_revisions sr on sr.id = rr.score_revision_id
    join base_attempts ba on ba.id = rr.attempt_id
    where rr.is_current
  ),
  active_memberships as (
    select distinct cm.class_id, cm.learner_id
    from public.class_memberships cm
    join owned_classes oc on oc.id = cm.class_id
    where cm.status = 'active'::public.membership_status
  ),
  assigned_cocs as (
    select distinct class_id, coc_id, coc_code, coc_title
    from scope_assignments
  ),
  failure_by_learner as (
    select
      lc.rubric_criterion_id,
      ba.learner_id,
      ba.class_id,
      ba.class_title,
      ba.coc_id,
      ba.coc_code,
      ba.mission_id,
      ba.mission_title,
      count(distinct ba.id)::int as failed_attempts,
      greatest(count(distinct ba.id)::int - 1, 0) as repeat_failures,
      max(ba.event_at) as latest_activity,
      (array_agg(ba.id order by ba.event_at desc))[1] as latest_attempt_id
    from latest_criteria lc
    join base_attempts ba on ba.id = lc.attempt_id
    where lc.observation in ('not_satisfied', 'requires_review')
    group by lc.rubric_criterion_id, ba.learner_id, ba.class_id, ba.class_title,
             ba.coc_id, ba.coc_code, ba.mission_id, ba.mission_title
  ),
  mission_retry as (
    select
      ba.coc_id,
      ba.coc_code,
      ba.mission_id,
      ba.mission_title,
      count(*)::int as attempts,
      count(distinct (ba.learner_id, ba.assignment_id))::int as learner_assignments,
      count(*) filter (where attempt_count > 1)::int as attempts_in_repeat_groups,
      count(distinct ba.learner_id) filter (where attempt_count > 1)::int as learners_retrying
    from (
      select base_attempts.*,
             count(*) over (partition by learner_id, assignment_id) as attempt_count
      from base_attempts
    ) ba
    group by ba.coc_id, ba.coc_code, ba.mission_id, ba.mission_title
  ),
  progress_rows as (
    select
      am.class_id,
      oc.title as class_title,
      am.learner_id,
      p.full_name as learner_name,
      ac.coc_id,
      ac.coc_code,
      ac.coc_title,
      case
        when bool_or(cr.outcome = 'competent') then 'completed'
        when bool_or(cr.outcome = 'not_yet_competent') then 'needs_support'
        when count(ba.id) > 0 then 'in_progress'
        else 'not_started'
      end as progress_state
    from active_memberships am
    join owned_classes oc on oc.id = am.class_id
    join public.profiles p on p.user_id = am.learner_id
    join assigned_cocs ac on ac.class_id = am.class_id
    left join base_attempts ba
      on ba.class_id = am.class_id
     and ba.learner_id = am.learner_id
     and ba.coc_id = ac.coc_id
    left join current_releases cr on cr.attempt_id = ba.id
    group by am.class_id, oc.title, am.learner_id, p.full_name,
             ac.coc_id, ac.coc_code, ac.coc_title
  )
  select jsonb_build_object(
    'period', jsonb_build_object('from', v_from, 'to', v_to),
    'filters', jsonb_build_object(
      'classes', coalesce((
        select jsonb_agg(jsonb_build_object(
          'id', oc.id,
          'title', oc.title,
          'classCode', oc.class_code,
          'status', oc.status::text
        ) order by oc.title)
        from owned_classes oc
      ), '[]'::jsonb),
      'cocs', coalesce((
        select jsonb_agg(jsonb_build_object(
          'id', x.coc_id,
          'code', x.coc_code,
          'title', x.coc_title
        ) order by x.coc_code)
        from (select distinct coc_id, coc_code, coc_title from scope_assignments) x
      ), '[]'::jsonb),
      'missions', coalesce((
        select jsonb_agg(jsonb_build_object(
          'id', x.mission_id,
          'cocId', x.coc_id,
          'code', x.mission_code,
          'number', x.mission_number,
          'title', x.mission_title
        ) order by x.coc_code, x.mission_number)
        from (
          select distinct mission_id, coc_id, coc_code, mission_code, mission_number, mission_title
          from scope_assignments
        ) x
      ), '[]'::jsonb)
    ),
    'summary', jsonb_build_object(
      'activeLearners', (select count(distinct learner_id)::int from active_memberships),
      'totalAttempts', (select count(*)::int from base_attempts),
      'assessmentsSubmitted', (select count(*)::int from base_attempts where submitted_at is not null),
      'releasedResults', (select count(*)::int from current_releases),
      'pendingReview', (select count(*)::int from base_attempts where status in ('evaluated', 'under_review')),
      'learnersNeedingAttention', (select count(distinct learner_id)::int from failure_by_learner)
    ),
    'trend', coalesce((
      select jsonb_agg(jsonb_build_object(
        'date', d.day::date,
        'submitted', coalesce(t.submitted, 0),
        'released', coalesce(t.released, 0),
        'criteriaSatisfied', coalesce(t.criteria_satisfied, 0)
      ) order by d.day)
      from generate_series(date_trunc('day', v_from), date_trunc('day', v_to), interval '1 day') d(day)
      left join (
        select
          date_trunc('day', ba.event_at) as day,
          count(distinct ba.id) filter (where ba.submitted_at is not null)::int as submitted,
          count(distinct cr.attempt_id)::int as released,
          count(lc.rubric_criterion_id) filter (where lc.observation = 'satisfied')::int as criteria_satisfied
        from base_attempts ba
        left join current_releases cr on cr.attempt_id = ba.id
        left join latest_criteria lc on lc.attempt_id = ba.id
        group by date_trunc('day', ba.event_at)
      ) t on t.day = d.day
    ), '[]'::jsonb),
    'cocPerformance', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', x.coc_id,
        'code', x.coc_code,
        'title', x.coc_title,
        'attempts', x.attempts,
        'submitted', x.submitted,
        'released', x.released,
        'criteriaEvaluated', x.criteria_evaluated,
        'criteriaSatisfied', x.criteria_satisfied,
        'criteriaNotSatisfied', x.criteria_not_satisfied,
        'satisfactionRate', case when x.criteria_evaluated = 0 then null
          else round((x.criteria_satisfied::numeric / x.criteria_evaluated::numeric) * 100, 1) end
      ) order by x.coc_code)
      from (
        select
          ac.coc_id,
          ac.coc_code,
          ac.coc_title,
          count(distinct ba.id)::int as attempts,
          count(distinct ba.id) filter (where ba.submitted_at is not null)::int as submitted,
          count(distinct cr.attempt_id)::int as released,
          count(lc.rubric_criterion_id)::int as criteria_evaluated,
          count(lc.rubric_criterion_id) filter (where lc.observation = 'satisfied')::int as criteria_satisfied,
          count(lc.rubric_criterion_id) filter (where lc.observation in ('not_satisfied', 'requires_review'))::int as criteria_not_satisfied
        from (select distinct coc_id, coc_code, coc_title from assigned_cocs) ac
        left join base_attempts ba on ba.coc_id = ac.coc_id
        left join current_releases cr on cr.attempt_id = ba.id
        left join latest_criteria lc on lc.attempt_id = ba.id
        group by ac.coc_id, ac.coc_code, ac.coc_title
      ) x
    ), '[]'::jsonb),
    'missionPerformance', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', x.mission_id,
        'cocId', x.coc_id,
        'cocCode', x.coc_code,
        'code', x.mission_code,
        'number', x.mission_number,
        'title', x.mission_title,
        'attempts', x.attempts,
        'submitted', x.submitted,
        'finalized', x.finalized,
        'released', x.released,
        'criteriaNotSatisfied', x.criteria_not_satisfied,
        'learnersNeedingReview', x.learners_needing_review
      ) order by x.coc_code, x.mission_number)
      from (
        select
          sm.mission_id,
          sm.coc_id,
          sm.coc_code,
          sm.mission_code,
          sm.mission_number,
          sm.mission_title,
          count(distinct ba.id)::int as attempts,
          count(distinct ba.id) filter (where ba.submitted_at is not null)::int as submitted,
          count(distinct ba.id) filter (where ba.status in ('finalized', 'released'))::int as finalized,
          count(distinct cr.attempt_id)::int as released,
          count(lc.rubric_criterion_id) filter (where lc.observation in ('not_satisfied', 'requires_review'))::int as criteria_not_satisfied,
          count(distinct ba.learner_id) filter (where lc.observation in ('not_satisfied', 'requires_review'))::int as learners_needing_review
        from (
          select distinct mission_id, coc_id, coc_code, mission_code, mission_number, mission_title
          from scope_assignments
        ) sm
        left join base_attempts ba on ba.mission_id = sm.mission_id
        left join current_releases cr on cr.attempt_id = ba.id
        left join latest_criteria lc on lc.attempt_id = ba.id
        group by sm.mission_id, sm.coc_id, sm.coc_code, sm.mission_code, sm.mission_number, sm.mission_title
      ) x
    ), '[]'::jsonb),
    'criteria', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', x.criterion_id,
        'code', x.criterion_code,
        'title', x.criterion_title,
        'sourceTrace', x.source_trace,
        'isRequired', x.is_required,
        'cocId', x.coc_id,
        'cocCode', x.coc_code,
        'missionId', x.mission_id,
        'missionTitle', x.mission_title,
        'evaluatedAttempts', x.evaluated_attempts,
        'satisfied', x.satisfied,
        'notSatisfied', x.not_satisfied,
        'affectedLearners', x.affected_learners,
        'repeatFailures', x.repeat_failures,
        'latestFailureAt', x.latest_failure_at
      ) order by x.not_satisfied desc, x.criterion_code)
      from (
        select
          rc.id as criterion_id,
          rc.criterion_code,
          rc.title as criterion_title,
          rc.source_trace,
          rc.is_required,
          ba.coc_id,
          ba.coc_code,
          ba.mission_id,
          ba.mission_title,
          count(distinct lc.attempt_id)::int as evaluated_attempts,
          count(*) filter (where lc.observation = 'satisfied')::int as satisfied,
          count(*) filter (where lc.observation in ('not_satisfied', 'requires_review'))::int as not_satisfied,
          count(distinct ba.learner_id) filter (where lc.observation in ('not_satisfied', 'requires_review'))::int as affected_learners,
          coalesce((select sum(fbl.repeat_failures)::int from failure_by_learner fbl where fbl.rubric_criterion_id = rc.id), 0) as repeat_failures,
          max(lc.evaluated_at) filter (where lc.observation in ('not_satisfied', 'requires_review')) as latest_failure_at
        from latest_criteria lc
        join public.rubric_criteria rc on rc.id = lc.rubric_criterion_id
        join base_attempts ba on ba.id = lc.attempt_id
        group by rc.id, rc.criterion_code, rc.title, rc.source_trace, rc.is_required,
                 ba.coc_id, ba.coc_code, ba.mission_id, ba.mission_title
      ) x
    ), '[]'::jsonb),
    'attention', coalesce((
      select jsonb_agg(jsonb_build_object(
        'learnerId', x.learner_id,
        'learnerName', x.learner_name,
        'classId', x.class_id,
        'classTitle', x.class_title,
        'cocId', x.coc_id,
        'cocCode', x.coc_code,
        'missionId', x.mission_id,
        'missionTitle', x.mission_title,
        'criterionId', x.rubric_criterion_id,
        'criterionCode', x.criterion_code,
        'criterionTitle', x.criterion_title,
        'failedAttempts', x.failed_attempts,
        'repeatFailures', x.repeat_failures,
        'lastActivity', x.latest_activity,
        'latestAttemptId', x.latest_attempt_id,
        'reason', case when x.repeat_failures > 0 then 'Repeated criterion evidence needs support' else 'Criterion evidence needs review' end
      ) order by x.repeat_failures desc, x.failed_attempts desc, x.latest_activity desc)
      from (
        select fbl.*, p.full_name as learner_name,
               rc.criterion_code, rc.title as criterion_title
        from failure_by_learner fbl
        join public.profiles p on p.user_id = fbl.learner_id
        join public.rubric_criteria rc on rc.id = fbl.rubric_criterion_id
      ) x
    ), '[]'::jsonb),
    'workflow', coalesce((
      select jsonb_agg(jsonb_build_object('status', s.status, 'count', coalesce(a.count, 0)) order by s.position)
      from (values
        ('in_progress', 1), ('submitted', 2), ('evaluated', 3),
        ('under_review', 4), ('finalized', 5), ('released', 6)
      ) s(status, position)
      left join (
        select status, count(*)::int as count
        from base_attempts
        group by status
      ) a on a.status = s.status
    ), '[]'::jsonb),
    'retries', coalesce((
      select jsonb_agg(jsonb_build_object(
        'cocId', mr.coc_id,
        'cocCode', mr.coc_code,
        'missionId', mr.mission_id,
        'missionTitle', mr.mission_title,
        'attempts', mr.attempts,
        'learnerAssignments', mr.learner_assignments,
        'averageAttempts', case when mr.learner_assignments = 0 then 0
          else round(mr.attempts::numeric / mr.learner_assignments::numeric, 2) end,
        'learnersRetrying', mr.learners_retrying
      ) order by mr.learners_retrying desc, mr.mission_title)
      from mission_retry mr
    ), '[]'::jsonb),
    'progressMatrix', coalesce((
      select jsonb_agg(jsonb_build_object(
        'learnerId', pr.learner_id,
        'learnerName', pr.learner_name,
        'classId', pr.class_id,
        'classTitle', pr.class_title,
        'cocs', pr.cocs
      ) order by pr.learner_name)
      from (
        select learner_id, learner_name, class_id, class_title,
               jsonb_agg(jsonb_build_object(
                 'id', coc_id,
                 'code', coc_code,
                 'title', coc_title,
                 'state', progress_state
               ) order by coc_code) as cocs
        from progress_rows
        group by learner_id, learner_name, class_id, class_title
      ) pr
    ), '[]'::jsonb),
    'assessmentHistory', coalesce((
      select jsonb_agg(to_jsonb(x) order by x."eventAt" desc)
      from (
        select
          ba.id as "attemptId",
          ba.learner_id as "learnerId",
          p.full_name as "learnerName",
          ba.class_id as "classId",
          ba.class_title as "classTitle",
          ba.coc_id as "cocId",
          ba.coc_code as "cocCode",
          ba.mission_id as "missionId",
          ba.mission_title as "missionTitle",
          ba.assignment_title as "assignmentTitle",
          ba.status,
          ba.event_at as "eventAt",
          ba.submitted_at as "submittedAt",
          ba.released_at as "releasedAt",
          row_number() over (partition by ba.learner_id, ba.assignment_id order by ba.started_at) as "attemptNumber"
        from base_attempts ba
        join public.profiles p on p.user_id = ba.learner_id
        order by ba.event_at desc
        limit 500
      ) x
    ), '[]'::jsonb),
    'releasedResults', coalesce((
      select jsonb_agg(to_jsonb(x) order by x."releasedAt" desc)
      from (
        select
          ba.id as "attemptId",
          ba.learner_id as "learnerId",
          p.full_name as "learnerName",
          p.email as "learnerEmail",
          ba.class_id as "classId",
          ba.class_title as "classTitle",
          ba.coc_id as "cocId",
          ba.coc_code as "cocCode",
          ba.mission_id as "missionId",
          ba.mission_title as "missionTitle",
          ba.assignment_title as "assignmentTitle",
          cr.outcome,
          cr.percentage,
          cr.remarks,
          cr.release_reason as "releaseReason",
          cr.released_at as "releasedAt"
        from current_releases cr
        join base_attempts ba on ba.id = cr.attempt_id
        join public.profiles p on p.user_id = ba.learner_id
        order by cr.released_at desc
        limit 500
      ) x
    ), '[]'::jsonb)
  ) into v_result;

  return v_result;
end;
$$;

create or replace function public.get_admin_system_analytics(
  p_from timestamptz default (now() - interval '30 days'),
  p_to timestamptz default now()
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_from timestamptz := coalesce(p_from, now() - interval '30 days');
  v_to timestamptz := coalesce(p_to, now());
  v_result jsonb;
begin
  if auth.uid() is null
     or not public.is_active_user()
     or not public.is_admin() then
    raise exception 'Active Admin authentication is required'
      using errcode = '42501';
  end if;

  if v_from > v_to or v_to - v_from > interval '366 days' then
    raise exception 'Admin analytics date range must be between 0 and 366 days'
      using errcode = '22023';
  end if;

  select jsonb_build_object(
    'period', jsonb_build_object('from', v_from, 'to', v_to),
    'summary', jsonb_build_object(
      'activeLearners', (select count(*)::int from public.profiles where role = 'learner'::public.user_role and status = 'active'::public.account_status),
      'activeInstructors', (select count(*)::int from public.profiles where role = 'instructor'::public.user_role and status = 'active'::public.account_status),
      'activeClasses', (select count(*)::int from public.classes where status = 'active'::public.class_status),
      'assessmentVolume', (select count(*)::int from public.attempts where created_at between v_from and v_to),
      'releasedResults', (select count(*)::int from public.result_releases where is_current and released_at between v_from and v_to),
      'resourceUploads', (select count(*)::int from public.learning_resources where created_at between v_from and v_to),
      'storageBytes', (select coalesce(sum(size_bytes), 0)::bigint from public.learning_resources where status <> 'deleted'::public.resource_status),
      'auditEvents', (select count(*)::int from public.audit_events where created_at between v_from and v_to)
    ),
    'trend', coalesce((
      select jsonb_agg(jsonb_build_object(
        'date', d.day::date,
        'assessments', coalesce(attempts.event_count, 0),
        'released', coalesce(releases.event_count, 0),
        'resources', coalesce(resources.event_count, 0),
        'auditEvents', coalesce(audits.event_count, 0)
      ) order by d.day)
      from generate_series(date_trunc('day', v_from), date_trunc('day', v_to), interval '1 day') d(day)
      left join (
        select date_trunc('day', created_at) as bucket_day, count(*)::int as event_count
        from public.attempts where created_at between v_from and v_to group by 1
      ) attempts on attempts.bucket_day = d.day
      left join (
        select date_trunc('day', released_at) as bucket_day, count(*)::int as event_count
        from public.result_releases where is_current and released_at between v_from and v_to group by 1
      ) releases on releases.bucket_day = d.day
      left join (
        select date_trunc('day', created_at) as bucket_day, count(*)::int as event_count
        from public.learning_resources where created_at between v_from and v_to group by 1
      ) resources on resources.bucket_day = d.day
      left join (
        select date_trunc('day', created_at) as bucket_day, count(*)::int as event_count
        from public.audit_events where created_at between v_from and v_to group by 1
      ) audits on audits.bucket_day = d.day
    ), '[]'::jsonb),
    'accountStates', coalesce((
      select jsonb_agg(jsonb_build_object('role', role::text, 'status', status::text, 'count', count) order by role::text, status::text)
      from (
        select role, status, count(*)::int count
        from public.profiles
        group by role, status
      ) x
    ), '[]'::jsonb),
    'cocUsage', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', x.coc_id,
        'code', x.coc_code,
        'title', x.coc_title,
        'attempts', x.attempts,
        'learners', x.learners,
        'released', x.released
      ) order by x.coc_code)
      from (
        select cm.id coc_id, upper(cm.coc_code) coc_code,
               coalesce(nullif(cm.title, ''), cm.module_name) coc_title,
               count(distinct at.id)::int attempts,
               count(distinct at.learner_id)::int learners,
               count(distinct rr.attempt_id)::int released
        from public.coc_modules cm
        left join public.missions m on m.coc_id = cm.id
        left join public.activity_versions av on av.mission_id = m.id
        left join public.attempts at on at.activity_version_id = av.id and at.created_at between v_from and v_to
        left join public.result_releases rr on rr.attempt_id = at.id and rr.is_current
        group by cm.id, cm.coc_code, cm.title, cm.module_name
      ) x
    ), '[]'::jsonb),
    'recentAuditEvents', coalesce((
      select jsonb_agg(to_jsonb(x) order by x."createdAt" desc)
      from (
        select id, action, target_type as "targetType", outcome,
               actor_role::text as "actorRole", created_at as "createdAt"
        from public.audit_events
        order by created_at desc
        limit 12
      ) x
    ), '[]'::jsonb)
  ) into v_result;

  return v_result;
end;
$$;

revoke all on function public.get_instructor_analytics(uuid, uuid, uuid, timestamptz, timestamptz) from public;
revoke all on function public.get_instructor_analytics(uuid, uuid, uuid, timestamptz, timestamptz) from anon;
revoke all on function public.get_instructor_analytics(uuid, uuid, uuid, timestamptz, timestamptz) from authenticated;
grant execute on function public.get_instructor_analytics(uuid, uuid, uuid, timestamptz, timestamptz) to authenticated;

revoke all on function public.get_admin_system_analytics(timestamptz, timestamptz) from public;
revoke all on function public.get_admin_system_analytics(timestamptz, timestamptz) from anon;
revoke all on function public.get_admin_system_analytics(timestamptz, timestamptz) from authenticated;
grant execute on function public.get_admin_system_analytics(timestamptz, timestamptz) to authenticated;

comment on function public.get_instructor_analytics(uuid, uuid, uuid, timestamptz, timestamptz)
  is 'Returns role-checked, Instructor-owned analytics/report aggregates. No authoritative assessment data is mutated.';

comment on function public.get_admin_system_analytics(timestamptz, timestamptz)
  is 'Returns role-checked system-operation analytics for an active Admin. It does not grant assessment-finalization authority.';
