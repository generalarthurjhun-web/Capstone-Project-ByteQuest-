-- Trusted learner-facing COC/mission state projection.
-- This exposes lifecycle state, never a TESDA percentage, unlock threshold,
-- score, answer key, or Instructor-only review data.

begin;

create or replace function public.get_learner_learning_path()
returns table (
  coc_id uuid,
  coc_code text,
  coc_title text,
  coc_description text,
  coc_order integer,
  mission_id uuid,
  mission_code text,
  mission_number integer,
  mission_title text,
  mission_description text,
  mission_difficulty text,
  estimated_time_minutes integer,
  assessment_assignment_id uuid,
  assessment_access_state text,
  latest_attempt_id uuid,
  latest_attempt_status text,
  released boolean,
  released_outcome text,
  bypassed_practice boolean
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_learner_id uuid := (select auth.uid());
begin
  if not public.is_learner() then
    raise exception 'ACTIVE_LEARNER_REQUIRED' using errcode = '42501';
  end if;

  return query
  select
    cm.id,
    cm.coc_code,
    cm.title,
    cm.description,
    cm.order_index,
    m.id,
    m.mission_code,
    m.mission_number,
    m.title,
    m.description,
    coalesce(m.difficulty::text, 'beginner'),
    coalesce(m.estimated_time_minutes, 10),
    assigned.id,
    case
      when released_result.attempt_id is not null then 'released'
      when latest_attempt.status = 'in_progress'::public.attempt_status then 'in_progress'
      when latest_attempt.id is not null then 'awaiting_release'
      when assigned.id is null then 'practice_only'
      when assigned.available_at is not null and now() < assigned.available_at then 'not_yet_available'
      when assigned.due_at is not null and now() > assigned.due_at then 'closed'
      when assigned.prerequisite_assignment_id is not null
       and not exists (
         select 1
         from public.attempts prerequisite_attempt
         join public.result_releases prerequisite_release
           on prerequisite_release.attempt_id = prerequisite_attempt.id
          and prerequisite_release.is_current
         join public.score_revisions prerequisite_revision
           on prerequisite_revision.id = prerequisite_release.score_revision_id
         where prerequisite_attempt.learner_id = v_learner_id
           and prerequisite_attempt.assignment_id = assigned.prerequisite_assignment_id
           and prerequisite_attempt.status = 'released'::public.attempt_status
           and prerequisite_revision.outcome = 'competent'::public.evaluation_outcome
       ) then 'prerequisite_required'
      when not assigned.retry_enabled and assignment_attempts.attempt_count > 0 then 'attempts_exhausted'
      when assigned.attempts_allowed is not null
       and assignment_attempts.attempt_count >= assigned.attempts_allowed then 'attempts_exhausted'
      when assigned.retry_after_seconds is not null
       and assignment_attempts.latest_completed_at is not null
       and now() < assignment_attempts.latest_completed_at
                   + make_interval(secs => assigned.retry_after_seconds) then 'retry_wait'
      else 'available'
    end,
    latest_attempt.id,
    latest_attempt.status::text,
    released_result.attempt_id is not null,
    released_result.outcome::text,
    coalesce(bypass.present, false)
  from public.coc_modules cm
  join public.missions m
    on m.coc_id = cm.id
   and m.status = 'published'::public.mission_status
  left join lateral (
    select assignment.*
    from public.assignments assignment
    join public.activity_versions activity
      on activity.id = assignment.activity_version_id
     and activity.mission_id = m.id
     and activity.status = 'published'::public.content_version_status
    join public.class_memberships membership
      on membership.class_id = assignment.class_id
     and membership.learner_id = v_learner_id
     and membership.status = 'active'::public.membership_status
    where assignment.status = 'active'::public.assignment_status
    order by
      (assignment.assignment_type = 'assessment'::public.assignment_type) desc,
      assignment.created_at desc,
      assignment.id
    limit 1
  ) assigned on true
  left join lateral (
    select
      count(*)::integer as attempt_count,
      max(coalesce(a.submitted_at, a.evaluated_at, a.started_at)) as latest_completed_at
    from public.attempts a
    where a.learner_id = v_learner_id
      and a.assignment_id = assigned.id
  ) assignment_attempts on true
  left join lateral (
    select a.id, a.status, a.started_at
    from public.attempts a
    join public.activity_versions activity on activity.id = a.activity_version_id
    where a.learner_id = v_learner_id
      and activity.mission_id = m.id
    order by a.started_at desc, a.id desc
    limit 1
  ) latest_attempt on true
  left join lateral (
    select a.id as attempt_id, revision.outcome
    from public.attempts a
    join public.activity_versions activity on activity.id = a.activity_version_id
    join public.result_releases release
      on release.attempt_id = a.id
     and release.is_current
    join public.score_revisions revision on revision.id = release.score_revision_id
    where a.learner_id = v_learner_id
      and activity.mission_id = m.id
    order by release.released_at desc, release.id desc
    limit 1
  ) released_result on true
  left join lateral (
    select true as present
    from public.coc_bypasses cb
    join public.module_versions module_version on module_version.id = cb.module_version_id
    join public.class_memberships membership
      on membership.class_id = cb.class_id
     and membership.learner_id = v_learner_id
     and membership.status = 'active'::public.membership_status
    where cb.learner_id = v_learner_id
      and cb.revoked_at is null
      and module_version.module_id = cm.id
    limit 1
  ) bypass on true
  where cm.status = 'published'::public.mission_status
  order by cm.order_index, m.order_index, m.id;
end
$$;

revoke all on function public.get_learner_learning_path() from public, anon;
grant execute on function public.get_learner_learning_path() to authenticated;

comment on function public.get_learner_learning_path() is
  'Returns the active learner own COC/mission assignment, attempt, release, and practice-bypass projection without scoring or answer authority.';

commit;
