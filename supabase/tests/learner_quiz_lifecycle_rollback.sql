-- Trusted learner quiz lifecycle, scope, answer-key privacy, and idempotency.
-- Requires 20260812120000_learner_quiz_lifecycle.sql. All fixtures roll back.

\echo 1..1
begin;

create temporary table bytequest_quiz_test_context as
select
  (select user_id from public.profiles where role = 'instructor' and status = 'active' limit 1) instructor_id,
  (select user_id from public.profiles where role = 'learner' and status = 'active' order by user_id limit 1) learner_a,
  (select user_id from public.profiles where role = 'learner' and status = 'active' order by user_id offset 1 limit 1) learner_b,
  gen_random_uuid() class_id,
  gen_random_uuid() quiz_id,
  gen_random_uuid() version_id,
  gen_random_uuid() item_a,
  gen_random_uuid() item_b,
  gen_random_uuid() assignment_id,
  gen_random_uuid() start_key,
  gen_random_uuid() submission_key;

do $$
begin
  if (select instructor_id is null or learner_a is null or learner_b is null
      from bytequest_quiz_test_context) then
    raise exception 'QUIZ_TEST_FIXTURE_PREREQUISITES_MISSING';
  end if;
end
$$;

insert into public.classes(id, title, class_code, instructor_id, created_by)
select class_id, 'Rollback Quiz Class', 'ROLLBACK-QUIZ-' || left(class_id::text, 8),
  instructor_id, instructor_id
from bytequest_quiz_test_context;

insert into public.class_memberships(class_id, learner_id, enrolled_by)
select class_id, learner_a, instructor_id from bytequest_quiz_test_context;

insert into public.quizzes(id, instructor_id, title, topic, created_by)
select quiz_id, instructor_id, 'Rollback networking quiz', 'Network checks', instructor_id
from bytequest_quiz_test_context;

insert into public.quiz_versions(
  id, quiz_id, version_number, instructions, status, created_by,
  published_by, published_at
)
select version_id, quiz_id, 1, 'Answer every supplementary question.',
  'published'::public.content_version_status, instructor_id, instructor_id, now()
from bytequest_quiz_test_context;

insert into public.quiz_items(
  id, quiz_version_id, item_code, item_type, prompt, options,
  correct_answer, review_status, reviewed_by, reviewed_at,
  order_index, created_by
)
select item_a, version_id, 'ROLLBACK-Q1', 'multiple_choice'::public.quiz_item_type,
  'Which device routes traffic between networks?', '["Router","Keyboard"]'::jsonb,
  '"Router"'::jsonb, 'approved'::public.quiz_item_review_status,
  instructor_id, now(), 1, instructor_id
from bytequest_quiz_test_context
union all
select item_b, version_id, 'ROLLBACK-Q2', 'true_false'::public.quiz_item_type,
  'A switch connects devices in a local network.', '[]'::jsonb,
  '"true"'::jsonb, 'approved'::public.quiz_item_review_status,
  instructor_id, now(), 2, instructor_id
from bytequest_quiz_test_context;

insert into public.quiz_assignments(
  id, class_id, quiz_version_id, assigned_by
)
select assignment_id, class_id, version_id, instructor_id
from bytequest_quiz_test_context;

grant select on bytequest_quiz_test_context to authenticated;

-- Learner B is not enrolled and must receive neither list data nor start access.
select set_config('request.jwt.claim.sub', (select learner_b::text from bytequest_quiz_test_context), true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

do $$
declare
  v_list jsonb;
begin
  v_list := public.get_available_learner_quizzes();
  if jsonb_array_length(v_list) <> 0 then
    raise exception 'CROSS_CLASS_QUIZ_LIST_NOT_BLOCKED';
  end if;
  begin
    perform public.start_learner_quiz(
      (select assignment_id from bytequest_quiz_test_context),
      gen_random_uuid()
    );
    raise exception 'CROSS_CLASS_QUIZ_START_NOT_BLOCKED';
  exception when sqlstate '42501' then null;
  end;
end
$$;

reset role;
select set_config('request.jwt.claim.sub', (select learner_a::text from bytequest_quiz_test_context), true);
set local role authenticated;

do $$
declare
  v_list jsonb;
  v_start jsonb;
  v_attempt_id uuid;
  v_result jsonb;
begin
  v_list := public.get_available_learner_quizzes();
  if jsonb_array_length(v_list) <> 1 then
    raise exception 'AUTHORIZED_QUIZ_LIST_INVALID';
  end if;
  v_start := public.start_learner_quiz(
    (select assignment_id from bytequest_quiz_test_context),
    (select start_key from bytequest_quiz_test_context)
  );
  if v_start::text like '%correct_answer%' then
    raise exception 'ANSWER_KEY_EXPOSED_DURING_START';
  end if;
  v_attempt_id := (v_start->>'attempt_id')::uuid;

  perform public.save_learner_quiz_answer(
    v_attempt_id, (select item_a from bytequest_quiz_test_context), 'Router'
  );
  perform public.save_learner_quiz_answer(
    v_attempt_id, (select item_b from bytequest_quiz_test_context), 'True'
  );
  perform public.submit_learner_quiz(
    v_attempt_id, (select submission_key from bytequest_quiz_test_context)
  );
  -- Network retries remain exact-once even with another client request key.
  perform public.submit_learner_quiz(v_attempt_id, gen_random_uuid());

  if (select count(*) from public.quiz_results where quiz_attempt_id = v_attempt_id) <> 1 then
    raise exception 'QUIZ_RESULT_NOT_EXACT_ONCE';
  end if;
  if (select count(*) from public.quiz_attempts
      where learner_id = (select learner_a from bytequest_quiz_test_context)
        and quiz_assignment_id = (select assignment_id from bytequest_quiz_test_context)) <> 1 then
    raise exception 'QUIZ_ATTEMPT_NOT_EXACT_ONCE';
  end if;

  v_result := public.get_learner_quiz_result(v_attempt_id);
  if (v_result->>'correct_count')::integer <> 2
     or v_result::text like '%correct_answer%'
     or v_result::text like '%Keyboard%' then
    raise exception 'QUIZ_RESULT_PRIVACY_OR_EVALUATION_INVALID';
  end if;

  begin
    perform public.save_learner_quiz_answer(
      v_attempt_id, (select item_a from bytequest_quiz_test_context), 'Keyboard'
    );
    raise exception 'POST_SUBMISSION_MUTATION_NOT_BLOCKED';
  exception when sqlstate '55000' then null;
  end;
end
$$;

reset role;
select set_config('request.jwt.claim.sub', '', true);
select set_config('request.jwt.claim.role', 'anon', true);
set local role anon;

do $$
begin
  begin
    perform public.get_available_learner_quizzes();
    raise exception 'ANON_QUIZ_RPC_NOT_BLOCKED';
  exception when insufficient_privilege then null;
  end;
end
$$;

reset role;
rollback;
\echo ok 1 - learner quiz lifecycle rollback
