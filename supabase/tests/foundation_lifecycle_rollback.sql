-- Destructive-safe integration test. Every fixture and state transition is
-- rolled back. Any failed assertion aborts the script.

begin;

create temporary table bytequest_test_context (
  admin_id uuid,
  instructor_id uuid,
  learner_id uuid,
  other_learner_id uuid,
  secondary_instructor_id uuid,
  module_id uuid,
  mission_id uuid,
  source_id uuid,
  module_version_id uuid,
  activity_version_id uuid,
  rubric_version_id uuid,
  criterion_id uuid,
  class_id uuid,
  secondary_class_id uuid,
  membership_id uuid,
  other_membership_id uuid,
  assignment_id uuid,
  attempt_id uuid,
  other_learner_attempt_id uuid,
  wrong_sequence_attempt_id uuid,
  action_id uuid,
  practice_action_id bigint,
  provisional_revision_id uuid,
  final_revision_id uuid,
  release_id uuid,
  bypass_id uuid,
  start_key uuid not null default gen_random_uuid(),
  other_learner_start_key uuid not null default gen_random_uuid(),
  wrong_sequence_start_key uuid not null default gen_random_uuid(),
  submission_key uuid not null default gen_random_uuid(),
  wrong_sequence_submission_key uuid not null default gen_random_uuid(),
  evaluation_run_id uuid not null default gen_random_uuid(),
  action_at timestamptz not null default clock_timestamp()
) on commit drop;

insert into bytequest_test_context (
  admin_id,
  instructor_id,
  learner_id,
  other_learner_id,
  secondary_instructor_id,
  module_id,
  mission_id
)
select
  (select user_id from public.profiles where role = 'admin' and status = 'active' limit 1),
  (select user_id from public.profiles where role = 'instructor' and status = 'active' limit 1),
  (select user_id from public.profiles where role = 'learner' and status = 'active' order by user_id limit 1),
  (select user_id from public.profiles where role = 'learner' and status = 'active' order by user_id offset 2 limit 1),
  (select user_id from public.profiles where role = 'learner' and status = 'active' order by user_id offset 1 limit 1),
  (select id from public.coc_modules order by created_at, id limit 1),
  (select id from public.missions order by created_at, id limit 1);

do $$
declare
  v_context bytequest_test_context;
begin
  select * into v_context from bytequest_test_context;
  if v_context.admin_id is null
     or v_context.instructor_id is null
     or v_context.learner_id is null
     or v_context.other_learner_id is null
     or v_context.secondary_instructor_id is null
     or v_context.module_id is null
     or v_context.mission_id is null then
    raise exception 'TEST_FIXTURE_PREREQUISITES_MISSING';
  end if;
end
$$;

with inserted as (
  insert into public.tesda_sources (
    qualification_code,
    title,
    edition,
    source_reference,
    status,
    validation_notes,
    created_by,
    approved_by,
    approved_at,
    activated_by,
    activated_at
  )
  select
    'ROLLBACK-' || left(gen_random_uuid()::text, 8),
    'Rollback-only lifecycle verification source',
    'TEST_ONLY',
    'Rollback fixture; never a production TESDA source',
    'active'::public.tesda_source_status,
    'TEST_ONLY_ROLLBACK_FIXTURE',
    admin_id,
    admin_id,
    now(),
    admin_id,
    now()
  from bytequest_test_context
  returning id
)
update bytequest_test_context
set source_id = inserted.id
from inserted;

with inserted as (
  insert into public.module_versions (
    module_id,
    tesda_source_id,
    version_number,
    title,
    source_trace,
    status,
    created_by,
    published_by,
    published_at
  )
  select
    module_id,
    source_id,
    coalesce((select max(version_number) from public.module_versions mv where mv.module_id = context.module_id), 0) + 1,
    'Rollback-only module version',
    jsonb_build_object('status', 'TEST_ONLY'),
    'published'::public.content_version_status,
    admin_id,
    admin_id,
    now()
  from bytequest_test_context context
  returning id
)
update bytequest_test_context
set module_version_id = inserted.id
from inserted;

with inserted as (
  insert into public.activity_versions (
    mission_id,
    module_version_id,
    version_number,
    title,
    delivery_mode,
    learner_payload,
    evaluator_config,
    status,
    created_by,
    published_by,
    published_at
  )
  select
    mission_id,
    module_version_id,
    coalesce((select max(version_number) from public.activity_versions av where av.mission_id = context.mission_id), 0) + 1,
    'Rollback-only assessment activity',
    'assessment'::public.activity_delivery_mode,
    jsonb_build_object('status', 'TEST_ONLY'),
    jsonb_build_object('status', 'TEST_ONLY'),
    'published'::public.content_version_status,
    admin_id,
    admin_id,
    now()
  from bytequest_test_context context
  returning id
)
update bytequest_test_context
set activity_version_id = inserted.id
from inserted;

with inserted as (
  insert into public.rubric_versions (
    activity_version_id,
    tesda_source_id,
    version_number,
    title,
    status,
    scoring_method,
    passing_rule,
    created_by,
    approved_by,
    approved_at
  )
  select
    activity_version_id,
    source_id,
    1,
    'Rollback-only rubric',
    'approved'::public.rubric_status,
    'binary_sum',
    jsonb_build_object('status', 'APPROVED', 'method', 'all_required'),
    admin_id,
    admin_id,
    now()
  from bytequest_test_context
  returning id
)
update bytequest_test_context
set rubric_version_id = inserted.id
from inserted;

with inserted as (
  insert into public.rubric_criteria (
    rubric_version_id,
    criterion_code,
    title,
    source_trace,
    evidence_rule,
    scoring_rule,
    max_value,
    order_index
  )
  select
    rubric_version_id,
    'TEST-CRITERION',
    'Rollback-only criterion',
    'TEST_ONLY_ROLLBACK',
    jsonb_build_object(
      'operator', 'action_exists',
      'action_type', 'test_action',
      'target', 'test_target',
      'minimum_count', 1
    ),
    jsonb_build_object(
      'status', 'APPROVED',
      'method', 'binary',
      'satisfied_value', 1,
      'not_satisfied_value', 0
    ),
    1,
    1
  from bytequest_test_context
  returning id
)
update bytequest_test_context
set criterion_id = inserted.id
from inserted;

insert into public.rubric_criteria (
  rubric_version_id,
  criterion_code,
  title,
  source_trace,
  evidence_rule,
  scoring_rule,
  max_value,
  order_index
)
select
  rubric_version_id,
  'TEST-SEQUENCE',
  'Rollback-only chronological criterion',
  'TEST_ONLY_ROLLBACK',
  jsonb_build_object(
    'operator', 'exact_target_sequence',
    'action_type', 'procedure_step',
    'expected_targets', jsonb_build_array('A', 'B')
  ),
  jsonb_build_object(
    'status', 'APPROVED',
    'method', 'binary',
    'satisfied_value', 1,
    'not_satisfied_value', 0
  ),
  1,
  2
from bytequest_test_context;

update public.profiles
set role = 'instructor'::public.user_role
where user_id = (select secondary_instructor_id from bytequest_test_context);

with inserted as (
  insert into public.classes (title, class_code, instructor_id, created_by)
  select
    'Rollback isolation class',
    'RB-' || left(gen_random_uuid()::text, 8),
    secondary_instructor_id,
    secondary_instructor_id
  from bytequest_test_context
  returning id
)
update bytequest_test_context
set secondary_class_id = inserted.id
from inserted;

grant select, update on bytequest_test_context to authenticated;
grant select on bytequest_test_context to anon;

select set_config(
  'request.jwt.claim.sub',
  (select instructor_id::text from bytequest_test_context),
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

update bytequest_test_context
set class_id = (
  select id
  from public.create_class(
    'Rollback lifecycle class',
    'RB-' || left(gen_random_uuid()::text, 8)
  )
);

update bytequest_test_context context
set membership_id = (
  select id
  from public.enroll_learner(context.class_id, context.learner_id)
);

update bytequest_test_context context
set other_membership_id = (
  select id
  from public.enroll_learner(context.class_id, context.other_learner_id)
);

update bytequest_test_context context
set assignment_id = (
  select id
  from public.assign_activity(
    context.class_id,
    context.activity_version_id,
    context.rubric_version_id,
    'assessment'::public.assignment_type,
    'Rollback lifecycle assessment',
    'Test-only instructions',
    null,
    null
  )
);

update bytequest_test_context context
set bypass_id = (
  select id
  from public.grant_coc_bypass(
    context.class_id,
    context.learner_id,
    context.module_version_id,
    'Rollback-only access verification',
    jsonb_build_object('effect', 'UNLOCK_ACCESS_ONLY')
  )
);

do $$
declare
  v_context bytequest_test_context;
begin
  select * into v_context from bytequest_test_context;

  if (select count(*) from public.classes where id = v_context.class_id) <> 1 then
    raise exception 'INSTRUCTOR_CANNOT_READ_OWN_CLASS';
  end if;

  if (select count(*) from public.classes where id = v_context.secondary_class_id) <> 0 then
    raise exception 'INSTRUCTOR_CLASS_ISOLATION_FAILED';
  end if;

  if exists (
    select 1
    from public.coc_bypasses
    where id = v_context.bypass_id
      and scope->>'effect' <> 'UNLOCK_ACCESS_ONLY'
  ) then
    raise exception 'BYPASS_EFFECT_IS_NOT_ACCESS_ONLY';
  end if;
end
$$;

reset role;
select set_config(
  'request.jwt.claim.sub',
  (select other_learner_id::text from bytequest_test_context),
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

update bytequest_test_context context
set other_learner_attempt_id = (
  select id
  from public.start_attempt(context.assignment_id, context.other_learner_start_key)
);

reset role;
select set_config(
  'request.jwt.claim.sub',
  (select learner_id::text from bytequest_test_context),
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

with inserted as (
  insert into public.practice_mission_actions (
    learner_id,
    client_action_id,
    mission_id,
    phase_id,
    action_type,
    target,
    value,
    client_occurred_at
  )
  select
    learner_id,
    'rollback-practice-action',
    mission_id::text,
    'rollback-practice-phase',
    'object_inspected',
    'rollback-target',
    jsonb_build_object('input_method', 'tap'),
    action_at
  from bytequest_test_context
  on conflict (learner_id, client_action_id) do nothing
  returning id
)
update bytequest_test_context
set practice_action_id = inserted.id
from inserted;

insert into public.practice_mission_actions (
  learner_id,
  client_action_id,
  mission_id,
  phase_id,
  action_type,
  target,
  value,
  client_occurred_at
)
select
  learner_id,
  'rollback-practice-action',
  mission_id::text,
  'rollback-practice-phase',
  'object_inspected',
  'rollback-target',
  jsonb_build_object('input_method', 'tap'),
  action_at
from bytequest_test_context
on conflict (learner_id, client_action_id) do nothing;

do $$
declare
  v_context bytequest_test_context;
begin
  select * into v_context from bytequest_test_context;

  if (
    select count(*)
    from public.practice_mission_actions
    where learner_id = v_context.learner_id
      and client_action_id = 'rollback-practice-action'
  ) <> 1 then
    raise exception 'PRACTICE_EVIDENCE_IDEMPOTENCY_FAILED';
  end if;

  begin
    update public.practice_mission_actions
    set target = 'forbidden-mutation'
    where id = v_context.practice_action_id;
    raise exception 'PRACTICE_EVIDENCE_MUTATION_WAS_NOT_BLOCKED';
  exception
    when insufficient_privilege then null;
  end;
end
$$;

update bytequest_test_context context
set attempt_id = (
  select id
  from public.start_attempt(context.assignment_id, context.start_key)
);

do $$
declare
  v_context bytequest_test_context;
  v_second_attempt_id uuid;
begin
  select * into v_context from bytequest_test_context;
  select id into v_second_attempt_id
  from public.start_attempt(v_context.assignment_id, v_context.start_key);

  if v_second_attempt_id <> v_context.attempt_id then
    raise exception 'ATTEMPT_START_IDEMPOTENCY_FAILED';
  end if;

  begin
    perform public.start_attempt(
      v_context.assignment_id,
      v_context.wrong_sequence_start_key
    );
    raise exception 'SECOND_IN_PROGRESS_ATTEMPT_WAS_NOT_BLOCKED';
  exception
    when sqlstate '22023' then
      if sqlerrm <> 'ATTEMPT_ALREADY_IN_PROGRESS' then
        raise;
      end if;
  end;
end
$$;

update bytequest_test_context context
set action_id = (
  select id
  from public.append_attempt_action(
    context.attempt_id,
    1,
    'test_action',
    'test_target',
    jsonb_build_object('value', 'chronological evidence'),
    context.action_at
  )
);

do $$
declare
  v_context bytequest_test_context;
  v_second_action_id uuid;
begin
  select * into v_context from bytequest_test_context;
  select id into v_second_action_id
  from public.append_attempt_action(
    v_context.attempt_id,
    1,
    'test_action',
    'test_target',
    jsonb_build_object('value', 'chronological evidence'),
    v_context.action_at
  );

  if v_second_action_id <> v_context.action_id then
    raise exception 'ACTION_IDEMPOTENCY_FAILED';
  end if;
end
$$;

reset role;

update public.class_memberships
set status = 'deactivated'::public.membership_status,
    deactivated_at = now(),
    deactivation_reason = 'Rollback access-recheck verification',
    deactivated_by = (select instructor_id from bytequest_test_context)
where id = (select membership_id from bytequest_test_context);

select set_config(
  'request.jwt.claim.sub',
  (select learner_id::text from bytequest_test_context),
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

do $$
declare
  v_context bytequest_test_context;
begin
  select * into v_context from bytequest_test_context;
  begin
    perform public.append_attempt_action(
      v_context.attempt_id,
      2,
      'test_action',
      'test_target',
      jsonb_build_object('value', 'must be rejected while deactivated'),
      clock_timestamp()
    );
    raise exception 'DEACTIVATED_MEMBERSHIP_ACTION_WAS_NOT_BLOCKED';
  exception
    when insufficient_privilege then null;
  end;
end
$$;

reset role;

update public.class_memberships
set status = 'active'::public.membership_status,
    deactivated_at = null,
    deactivation_reason = null,
    deactivated_by = null
where id = (select membership_id from bytequest_test_context);

select set_config(
  'request.jwt.claim.sub',
  (select learner_id::text from bytequest_test_context),
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select public.append_attempt_action(
  attempt_id,
  2,
  'procedure_step',
  'A',
  jsonb_build_object('position', 1),
  clock_timestamp()
)
from bytequest_test_context;

select public.append_attempt_action(
  attempt_id,
  3,
  'procedure_step',
  'B',
  jsonb_build_object('position', 2),
  clock_timestamp()
)
from bytequest_test_context;

select public.submit_attempt(attempt_id, submission_key, 15)
from bytequest_test_context;

select public.submit_attempt(attempt_id, submission_key, 15)
from bytequest_test_context;

update bytequest_test_context context
set wrong_sequence_attempt_id = (
  select id
  from public.start_attempt(context.assignment_id, context.wrong_sequence_start_key)
);

reset role;

update public.tesda_sources
set status = 'superseded'::public.tesda_source_status
where id = (select source_id from bytequest_test_context);

select set_config(
  'request.jwt.claim.sub',
  (select learner_id::text from bytequest_test_context),
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

do $$
begin
  if (select count(*) from public.get_bypassed_activities()) = 0 then
    raise exception 'COC_BYPASS_DID_NOT_UNLOCK_PUBLISHED_ACTIVITY';
  end if;
end
$$;

select public.append_attempt_action(
  wrong_sequence_attempt_id,
  1,
  'test_action',
  'test_target',
  jsonb_build_object('value', 'control criterion remains satisfied'),
  clock_timestamp()
)
from bytequest_test_context;

select public.append_attempt_action(
  wrong_sequence_attempt_id,
  2,
  'procedure_step',
  'B',
  jsonb_build_object('position', 1),
  clock_timestamp()
)
from bytequest_test_context;

select public.append_attempt_action(
  wrong_sequence_attempt_id,
  3,
  'procedure_step',
  'A',
  jsonb_build_object('position', 2),
  clock_timestamp()
)
from bytequest_test_context;

select public.submit_attempt(
  wrong_sequence_attempt_id,
  wrong_sequence_submission_key,
  15
)
from bytequest_test_context;

do $$
declare
  v_context bytequest_test_context;
begin
  select * into v_context from bytequest_test_context;

  if (select count(*) from public.attempts where id = v_context.attempt_id and status = 'evaluated') <> 1 then
    raise exception 'SUBMISSION_IDEMPOTENCY_FAILED';
  end if;

  if (select count(*) from public.attempts where id = v_context.other_learner_attempt_id) <> 0 then
    raise exception 'LEARNER_CROSS_ATTEMPT_READ_WAS_NOT_BLOCKED';
  end if;

  begin
    perform public.append_attempt_action(
      v_context.other_learner_attempt_id,
      1,
      'forbidden_cross_learner_action',
      'other_attempt',
      '{}'::jsonb,
      clock_timestamp()
    );
    raise exception 'LEARNER_CROSS_ATTEMPT_WRITE_WAS_NOT_BLOCKED';
  exception
    when insufficient_privilege then null;
  end;

  begin
    perform public.finalize_attempt(
      v_context.attempt_id,
      2,
      2,
      100,
      'competent'::public.evaluation_outcome,
      null,
      null,
      'forbidden learner finalization'
    );
    raise exception 'LEARNER_FINALIZATION_WAS_NOT_BLOCKED';
  exception
    when insufficient_privilege then null;
  end;

  begin
    perform public.release_attempt(v_context.attempt_id, 'forbidden learner release');
    raise exception 'LEARNER_RELEASE_WAS_NOT_BLOCKED';
  exception
    when insufficient_privilege then null;
  end;

  begin
    perform public.grant_coc_bypass(
      v_context.class_id,
      v_context.learner_id,
      v_context.module_version_id,
      'forbidden learner bypass',
      '{}'::jsonb
    );
    raise exception 'LEARNER_BYPASS_WAS_NOT_BLOCKED';
  exception
    when insufficient_privilege then null;
  end;

  begin
    perform public.create_class('Forbidden learner class', null);
    raise exception 'LEARNER_CLASS_CREATION_WAS_NOT_BLOCKED';
  exception
    when insufficient_privilege then null;
  end;

  begin
    perform public.admin_change_user_role(
      v_context.learner_id,
      'admin'::public.user_role,
      'forbidden learner role escalation'
    );
    raise exception 'LEARNER_ROLE_ESCALATION_WAS_NOT_BLOCKED';
  exception
    when insufficient_privilege then null;
  end;

  begin
    insert into public.score_revisions (
      attempt_id,
      revision_number,
      revision_type,
      tesda_source_id,
      rubric_version_id,
      outcome
    ) values (
      v_context.attempt_id,
      99,
      'instructor_final',
      v_context.source_id,
      v_context.rubric_version_id,
      'competent'
    );
    raise exception 'LEARNER_SCORE_WRITE_WAS_NOT_BLOCKED';
  exception
    when insufficient_privilege then null;
  end;
end
$$;

reset role;

do $$
declare
  v_context bytequest_test_context;
begin
  select * into v_context from bytequest_test_context;

  if (
    select count(*)
    from public.criterion_results cr
    where cr.attempt_id = v_context.attempt_id
  ) <> 2 then
    raise exception 'CRITERION_RESULT_IDEMPOTENCY_FAILED';
  end if;

  if exists (
    select 1
    from public.criterion_results cr
    join public.rubric_criteria rc on rc.id = cr.rubric_criterion_id
    where cr.attempt_id = v_context.attempt_id
      and rc.criterion_code in ('TEST-CRITERION', 'TEST-SEQUENCE')
      and (cr.observation <> 'satisfied'::public.criterion_observation or cr.score_value <> 1)
  ) then
    raise exception 'DATABASE_CRITERION_EVALUATION_FAILED';
  end if;

  if (
    select count(*)
    from public.score_revisions sr
    where sr.attempt_id = v_context.attempt_id
      and sr.revision_type = 'automated_provisional'::public.score_revision_type
      and sr.total_value = 2
      and sr.max_value = 2
      and sr.percentage = 100
      and sr.outcome = 'competent'::public.evaluation_outcome
  ) <> 1 then
    raise exception 'DATABASE_PROVISIONAL_REVISION_FAILED';
  end if;

  if (
    select count(*)
    from public.audit_events ae
    where ae.target_id = v_context.attempt_id
      and ae.action = 'attempt.provisional_evaluation_recorded'
  ) <> 1 then
    raise exception 'PROVISIONAL_EVALUATION_AUDIT_IDEMPOTENCY_FAILED';
  end if;

  if (
    select count(*)
    from public.criterion_results cr
    join public.rubric_criteria rc on rc.id = cr.rubric_criterion_id
    where cr.attempt_id = v_context.wrong_sequence_attempt_id
      and rc.criterion_code = 'TEST-SEQUENCE'
      and cr.observation = 'not_satisfied'::public.criterion_observation
      and cr.score_value = 0
  ) <> 1 then
    raise exception 'WRONG_CHRONOLOGICAL_SEQUENCE_WAS_ACCEPTED';
  end if;

  if (
    select count(*)
    from public.score_revisions sr
    where sr.attempt_id = v_context.wrong_sequence_attempt_id
      and sr.revision_type = 'automated_provisional'::public.score_revision_type
      and sr.total_value = 1
      and sr.max_value = 2
      and sr.percentage = 50
      and sr.outcome = 'not_yet_competent'::public.evaluation_outcome
  ) <> 1 then
    raise exception 'WRONG_SEQUENCE_PROVISIONAL_OUTCOME_FAILED';
  end if;
end
$$;

select set_config(
  'request.jwt.claim.sub',
  (select admin_id::text from bytequest_test_context),
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

do $$
declare
  v_context bytequest_test_context;
begin
  select * into v_context from bytequest_test_context;

  begin
    perform public.finalize_attempt(
      v_context.attempt_id,
      2,
      2,
      100,
      'competent'::public.evaluation_outcome,
      null,
      null,
      'forbidden admin routine finalization'
    );
    raise exception 'ADMIN_ROUTINE_FINALIZATION_WAS_NOT_BLOCKED';
  exception
    when insufficient_privilege then null;
  end;
end
$$;

reset role;

update bytequest_test_context context
set provisional_revision_id = (
  select id
  from public.score_revisions sr
  where sr.attempt_id = context.attempt_id
    and sr.revision_type = 'automated_provisional'::public.score_revision_type
);

select set_config(
  'request.jwt.claim.sub',
  (select instructor_id::text from bytequest_test_context),
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

do $$
declare
  v_context bytequest_test_context;
begin
  select * into v_context from bytequest_test_context;

  begin
    perform public.enroll_learner(v_context.secondary_class_id, v_context.learner_id);
    raise exception 'CROSS_INSTRUCTOR_ENROLLMENT_WAS_NOT_BLOCKED';
  exception
    when insufficient_privilege then null;
  end;

  begin
    perform public.grant_coc_bypass(
      v_context.secondary_class_id,
      v_context.learner_id,
      v_context.module_version_id,
      'forbidden cross-instructor bypass',
      '{}'::jsonb
    );
    raise exception 'CROSS_INSTRUCTOR_BYPASS_WAS_NOT_BLOCKED';
  exception
    when insufficient_privilege then null;
  end;

  begin
    perform public.admin_change_user_role(
      v_context.learner_id,
      'admin'::public.user_role,
      'forbidden instructor role escalation'
    );
    raise exception 'INSTRUCTOR_ROLE_ESCALATION_WAS_NOT_BLOCKED';
  exception
    when insufficient_privilege then null;
  end;
end
$$;

update bytequest_test_context context
set final_revision_id = (
  select id
  from public.finalize_attempt(
    context.attempt_id,
    2,
    2,
    100,
    'competent'::public.evaluation_outcome,
    null,
    null,
    'Rollback-only final confirmation'
  )
);

update bytequest_test_context context
set release_id = (
  select id
  from public.release_attempt(
    context.attempt_id,
    'Rollback-only release verification'
  )
);

select public.release_attempt(attempt_id, 'Idempotent repeated release')
from bytequest_test_context;

do $$
declare
  v_context bytequest_test_context;
begin
  select * into v_context from bytequest_test_context;

  if (select count(*) from public.score_revisions where attempt_id = v_context.attempt_id) <> 2 then
    raise exception 'REVISION_HISTORY_COUNT_FAILED';
  end if;

  if (select count(*) from public.result_releases where attempt_id = v_context.attempt_id and is_current) <> 1 then
    raise exception 'RELEASE_IDEMPOTENCY_FAILED';
  end if;

  if (select count(*) from public.gamification_events where source_id = v_context.attempt_id) <> 1 then
    raise exception 'GAMIFICATION_EXACTLY_ONCE_FAILED';
  end if;

end
$$;

reset role;

do $$
declare
  v_context bytequest_test_context;
begin
  select * into v_context from bytequest_test_context;

  if (select count(*) from public.audit_events where target_id = v_context.attempt_id and action in ('score.finalized', 'result.released')) <> 2 then
    raise exception 'FINALIZATION_RELEASE_AUDIT_FAILED';
  end if;

  begin
    update public.score_revisions
    set remarks = 'forbidden mutation'
    where id = v_context.final_revision_id;
    raise exception 'APPEND_ONLY_REVISION_MUTATION_WAS_NOT_BLOCKED';
  exception
    when object_not_in_prerequisite_state then null;
  end;
end
$$;

select set_config(
  'request.jwt.claim.sub',
  (select learner_id::text from bytequest_test_context),
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

do $$
declare
  v_context bytequest_test_context;
begin
  select * into v_context from bytequest_test_context;

  if (select count(*) from public.result_releases where attempt_id = v_context.attempt_id) <> 1 then
    raise exception 'LEARNER_CANNOT_READ_RELEASED_RESULT';
  end if;

  if (select count(*) from public.audit_events where target_id = v_context.attempt_id) <> 0 then
    raise exception 'LEARNER_AUDIT_VISIBILITY_FAILED';
  end if;
end
$$;

reset role;

select set_config('request.jwt.claim.sub', '', true);
select set_config('request.jwt.claim.role', 'anon', true);
set local role anon;

do $$
begin
  begin
    perform count(*) from public.classes;
    raise exception 'UNAUTHENTICATED_CLASS_READ_WAS_NOT_BLOCKED';
  exception
    when insufficient_privilege then null;
  end;

  begin
    perform count(*) from public.attempts;
    raise exception 'UNAUTHENTICATED_ATTEMPT_READ_WAS_NOT_BLOCKED';
  exception
    when insufficient_privilege then null;
  end;

  begin
    perform count(*) from public.score_revisions;
    raise exception 'UNAUTHENTICATED_SCORE_READ_WAS_NOT_BLOCKED';
  exception
    when insufficient_privilege then null;
  end;

  begin
    perform count(*) from public.audit_events;
    raise exception 'UNAUTHENTICATED_AUDIT_READ_WAS_NOT_BLOCKED';
  exception
    when insufficient_privilege then null;
  end;

  begin
    perform count(*) from public.practice_mission_actions;
    raise exception 'UNAUTHENTICATED_PRACTICE_EVIDENCE_READ_WAS_NOT_BLOCKED';
  exception
    when insufficient_privilege then null;
  end;

  begin
    perform public.create_class('Forbidden anonymous class', null);
    raise exception 'UNAUTHENTICATED_RPC_WAS_NOT_BLOCKED';
  exception
    when insufficient_privilege then null;
  end;
end
$$;

reset role;
rollback;

select jsonb_build_object(
  'status', 'PASS',
  'scope', 'rollback_only',
  'verified', jsonb_build_array(
    'class_isolation',
    'enrollment',
    'assignment',
    'coc_bypass_access_only',
    'attempt_start_idempotency',
    'ordered_action_idempotency',
    'practice_evidence_idempotency',
    'practice_evidence_append_only',
    'deactivated_membership_write_blocked',
    'submission_idempotency',
    'learner_score_write_blocked',
    'learner_cross_attempt_access_blocked',
    'learner_privileged_rpc_write_blocked',
    'database_derived_provisional_evaluation',
    'database_exact_sequence_evaluation',
    'wrong_chronological_sequence_rejected',
    'criterion_result_idempotency',
    'provisional_revision_idempotency',
    'provisional_audit_idempotency',
    'superseded_source_attempt_completion',
    'coc_bypass_operational_access',
    'cross_instructor_mutation_blocked',
    'instructor_role_escalation_blocked',
    'admin_routine_finalization_blocked',
    'instructor_finalization',
    'release_idempotency',
    'append_only_revisions',
    'gamification_exactly_once',
    'audit_visibility',
    'unauthenticated_practice_evidence_blocked',
    'unauthenticated_protected_access_blocked',
    'learner_released_result_visibility'
  )
) as lifecycle_test_result;
