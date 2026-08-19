-- Learner-facing supplementary quiz assignment, resumable attempts, trusted
-- evaluation, and result delivery. Quiz outcomes never determine competency.

begin;

do $$
begin
  create type public.quiz_attempt_status as enum (
    'in_progress',
    'submitted',
    'completed'
  );
exception when duplicate_object then null;
end
$$;

create table public.quiz_assignments (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references public.classes(id) on delete restrict,
  quiz_version_id uuid not null references public.quiz_versions(id) on delete restrict,
  status public.assignment_status not null default 'active',
  assigned_by uuid not null references auth.users(id) on delete restrict,
  available_at timestamptz,
  due_at timestamptz,
  attempts_allowed integer check (attempts_allowed is null or attempts_allowed > 0),
  instructions text,
  closed_at timestamptz,
  close_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint quiz_assignments_availability_check check (
    due_at is null or available_at is null or due_at > available_at
  ),
  constraint quiz_assignments_close_details_check check (
    status <> 'closed'::public.assignment_status
    or (closed_at is not null and nullif(btrim(close_reason), '') is not null)
  )
);

create unique index quiz_assignments_one_active_version_idx
  on public.quiz_assignments(class_id, quiz_version_id)
  where status = 'active'::public.assignment_status;
create unique index quiz_assignments_identity_idx
  on public.quiz_assignments(id, class_id, quiz_version_id);
create index quiz_assignments_class_status_idx
  on public.quiz_assignments(class_id, status, available_at, due_at);

create table public.quiz_attempts (
  id uuid primary key default gen_random_uuid(),
  learner_id uuid not null references auth.users(id) on delete restrict,
  class_id uuid not null references public.classes(id) on delete restrict,
  quiz_assignment_id uuid not null references public.quiz_assignments(id) on delete restrict,
  quiz_version_id uuid not null references public.quiz_versions(id) on delete restrict,
  status public.quiz_attempt_status not null default 'in_progress',
  client_start_key uuid not null,
  submission_key uuid,
  started_at timestamptz not null default now(),
  submitted_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (learner_id, quiz_assignment_id, client_start_key),
  constraint quiz_attempts_assignment_identity_fkey foreign key (
    quiz_assignment_id, class_id, quiz_version_id
  ) references public.quiz_assignments(id, class_id, quiz_version_id) on delete restrict,
  constraint quiz_attempts_submission_details_check check (
    status = 'in_progress'::public.quiz_attempt_status
    or (submission_key is not null and submitted_at is not null)
  ),
  constraint quiz_attempts_completion_details_check check (
    status <> 'completed'::public.quiz_attempt_status or completed_at is not null
  )
);

create unique index quiz_attempts_one_active_idx
  on public.quiz_attempts(learner_id, quiz_assignment_id)
  where status = 'in_progress'::public.quiz_attempt_status;
create unique index quiz_attempts_submission_key_idx
  on public.quiz_attempts(learner_id, submission_key)
  where submission_key is not null;
create index quiz_attempts_assignment_started_idx
  on public.quiz_attempts(quiz_assignment_id, started_at desc);
create index quiz_attempts_learner_started_idx
  on public.quiz_attempts(learner_id, started_at desc);
create unique index quiz_attempts_version_identity_idx
  on public.quiz_attempts(id, quiz_version_id);
create unique index quiz_items_version_identity_idx
  on public.quiz_items(id, quiz_version_id);

create table public.quiz_answers (
  id uuid primary key default gen_random_uuid(),
  quiz_attempt_id uuid not null references public.quiz_attempts(id) on delete restrict,
  quiz_item_id uuid not null references public.quiz_items(id) on delete restrict,
  quiz_version_id uuid not null references public.quiz_versions(id) on delete restrict,
  answer jsonb not null check (jsonb_typeof(answer) = 'string'),
  is_correct boolean,
  answered_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (quiz_attempt_id, quiz_item_id),
  constraint quiz_answers_attempt_version_fkey foreign key (
    quiz_attempt_id, quiz_version_id
  ) references public.quiz_attempts(id, quiz_version_id) on delete restrict,
  constraint quiz_answers_item_version_fkey foreign key (
    quiz_item_id, quiz_version_id
  ) references public.quiz_items(id, quiz_version_id) on delete restrict
);

create index quiz_answers_attempt_idx
  on public.quiz_answers(quiz_attempt_id, answered_at);

create table public.quiz_results (
  id uuid primary key default gen_random_uuid(),
  quiz_attempt_id uuid not null unique references public.quiz_attempts(id) on delete restrict,
  correct_count integer not null check (correct_count >= 0),
  question_count integer not null check (question_count > 0),
  item_results jsonb not null check (jsonb_typeof(item_results) = 'array'),
  evaluated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  constraint quiz_results_count_check check (correct_count <= question_count)
);

drop trigger if exists trg_quiz_assignments_updated_at on public.quiz_assignments;
create trigger trg_quiz_assignments_updated_at
before update on public.quiz_assignments
for each row execute function public.set_updated_at();

drop trigger if exists trg_quiz_attempts_updated_at on public.quiz_attempts;
create trigger trg_quiz_attempts_updated_at
before update on public.quiz_attempts
for each row execute function public.set_updated_at();

drop trigger if exists trg_quiz_answers_updated_at on public.quiz_answers;
create trigger trg_quiz_answers_updated_at
before update on public.quiz_answers
for each row execute function public.set_updated_at();

drop trigger if exists quiz_results_append_only on public.quiz_results;
create trigger quiz_results_append_only
before update or delete on public.quiz_results
for each row execute function private.prevent_append_only_mutation();

alter table public.quiz_assignments enable row level security;
alter table public.quiz_attempts enable row level security;
alter table public.quiz_answers enable row level security;
alter table public.quiz_results enable row level security;

create policy quiz_assignments_select_scoped
on public.quiz_assignments for select to authenticated
using (
  public.is_admin()
  or public.instructor_owns_class(class_id)
  or (public.is_learner() and public.learner_is_enrolled(class_id, (select auth.uid())))
);

create policy quiz_attempts_select_scoped
on public.quiz_attempts for select to authenticated
using (
  learner_id = (select auth.uid())
  or public.is_admin()
  or public.instructor_owns_class(class_id)
);

create policy quiz_answers_select_scoped
on public.quiz_answers for select to authenticated
using (exists (
  select 1
  from public.quiz_attempts qa
  where qa.id = quiz_answers.quiz_attempt_id
    and (
      qa.learner_id = (select auth.uid())
      or public.is_admin()
      or public.instructor_owns_class(qa.class_id)
    )
));

create policy quiz_results_select_scoped
on public.quiz_results for select to authenticated
using (exists (
  select 1
  from public.quiz_attempts qa
  where qa.id = quiz_results.quiz_attempt_id
    and (
      qa.learner_id = (select auth.uid())
      or public.is_admin()
      or public.instructor_owns_class(qa.class_id)
    )
));

grant select on public.quiz_assignments, public.quiz_attempts,
  public.quiz_answers, public.quiz_results to authenticated;

create or replace function private.quiz_assignment_is_available(
  p_assignment_id uuid,
  p_learner_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.quiz_assignments a
    join public.quiz_versions qv on qv.id = a.quiz_version_id
    join public.quizzes q on q.id = qv.quiz_id
    join public.classes c on c.id = a.class_id
    join public.class_memberships cm
      on cm.class_id = a.class_id and cm.learner_id = p_learner_id
    where a.id = p_assignment_id
      and a.status = 'active'::public.assignment_status
      and (a.available_at is null or a.available_at <= now())
      and (a.due_at is null or a.due_at >= now())
      and qv.status = 'published'::public.content_version_status
      and q.archived_at is null
      and c.status = 'active'::public.class_status
      and cm.status = 'active'::public.membership_status
  )
$$;

revoke all on function private.quiz_assignment_is_available(uuid, uuid)
from public, anon, authenticated;

create or replace function public.assign_published_quiz(
  p_class_id uuid,
  p_quiz_version_id uuid,
  p_available_at timestamptz default null,
  p_due_at timestamptz default null,
  p_attempts_allowed integer default null,
  p_instructions text default null
)
returns public.quiz_assignments
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_assignment public.quiz_assignments;
begin
  if not public.is_instructor() or not public.instructor_owns_class(p_class_id) then
    raise exception 'INSTRUCTOR_CLASS_SCOPE_REQUIRED' using errcode = '42501';
  end if;
  if p_due_at is not null and p_available_at is not null and p_due_at <= p_available_at then
    raise exception 'INVALID_AVAILABILITY_WINDOW' using errcode = '22023';
  end if;
  if p_attempts_allowed is not null and p_attempts_allowed < 1 then
    raise exception 'INVALID_ATTEMPT_LIMIT' using errcode = '22023';
  end if;
  if not exists (
    select 1 from public.quiz_versions qv
    join public.quizzes q on q.id = qv.quiz_id
    where qv.id = p_quiz_version_id
      and qv.status = 'published'::public.content_version_status
      and q.instructor_id = (select auth.uid())
      and q.archived_at is null
  ) then
    raise exception 'PUBLISHED_QUIZ_SCOPE_REQUIRED' using errcode = '42501';
  end if;

  insert into public.quiz_assignments(
    class_id, quiz_version_id, assigned_by, available_at, due_at,
    attempts_allowed, instructions
  ) values (
    p_class_id, p_quiz_version_id, (select auth.uid()), p_available_at,
    p_due_at, p_attempts_allowed, nullif(btrim(p_instructions), '')
  ) returning * into v_assignment;

  perform private.write_audit_event(
    'quiz.assigned', 'quiz_assignment', v_assignment.id, null,
    to_jsonb(v_assignment), null,
    jsonb_build_object('class_id', p_class_id, 'quiz_version_id', p_quiz_version_id)
  );
  return v_assignment;
end
$$;

create or replace function public.get_available_learner_quizzes()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select case
    when not public.is_learner() then
      (select jsonb_build_object('error', 'LEARNER_REQUIRED'))
    else coalesce((
      select jsonb_agg(payload order by class_title, title)
      from (
        select jsonb_build_object(
          'assignment_id', a.id,
          'quiz_version_id', a.quiz_version_id,
          'quiz_id', q.id,
          'title', q.title,
          'description', q.description,
          'topic', q.topic,
          'instructions', coalesce(a.instructions, qv.instructions),
          'class_id', c.id,
          'class_title', c.title,
          'coc_code', cm.coc_code,
          'coc_title', cm.title,
          'question_count', (
            select count(*) from public.quiz_items qi
            where qi.quiz_version_id = qv.id
              and qi.removed_at is null
              and qi.review_status = 'approved'::public.quiz_item_review_status
          ),
          'available_at', a.available_at,
          'due_at', a.due_at,
          'attempts_allowed', a.attempts_allowed,
          'is_available', private.quiz_assignment_is_available(a.id, (select auth.uid())),
          'attempt_id', latest.id,
          'attempt_status', latest.status,
          'answered_count', coalesce(latest.answered_count, 0),
          'started_at', latest.started_at,
          'completed_at', latest.completed_at
        ) as payload,
        c.title as class_title,
        q.title as title
        from public.quiz_assignments a
        join public.quiz_versions qv on qv.id = a.quiz_version_id
        join public.quizzes q on q.id = qv.quiz_id
        join public.classes c on c.id = a.class_id
        join public.class_memberships membership
          on membership.class_id = a.class_id
         and membership.learner_id = (select auth.uid())
         and membership.status = 'active'::public.membership_status
        left join public.coc_modules cm on cm.id = q.coc_module_id
        left join lateral (
          select qa.id, qa.status, qa.started_at, qa.completed_at,
            (select count(*) from public.quiz_answers ans where ans.quiz_attempt_id = qa.id) as answered_count
          from public.quiz_attempts qa
          where qa.quiz_assignment_id = a.id
            and qa.learner_id = (select auth.uid())
          order by (qa.status = 'in_progress'::public.quiz_attempt_status) desc,
            qa.started_at desc
          limit 1
        ) latest on true
        where a.status = 'active'::public.assignment_status
          and qv.status = 'published'::public.content_version_status
          and q.archived_at is null
          and c.status = 'active'::public.class_status
      ) scoped
    ), '[]'::jsonb)
  end
$$;

create or replace function public.start_learner_quiz(
  p_assignment_id uuid,
  p_client_start_key uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_assignment public.quiz_assignments;
  v_attempt public.quiz_attempts;
  v_attempt_count integer;
  v_payload jsonb;
begin
  if not public.is_learner() then
    raise exception 'LEARNER_REQUIRED' using errcode = '42501';
  end if;
  if not private.quiz_assignment_is_available(p_assignment_id, (select auth.uid())) then
    raise exception 'QUIZ_NOT_AVAILABLE' using errcode = '42501';
  end if;

  select * into v_assignment from public.quiz_assignments
  where id = p_assignment_id for update;

  select * into v_attempt from public.quiz_attempts
  where learner_id = (select auth.uid())
    and quiz_assignment_id = p_assignment_id
    and status = 'in_progress'::public.quiz_attempt_status
  order by started_at desc limit 1;

  if not found then
    select count(*) into v_attempt_count from public.quiz_attempts
    where learner_id = (select auth.uid()) and quiz_assignment_id = p_assignment_id;
    if v_assignment.attempts_allowed is not null
       and v_attempt_count >= v_assignment.attempts_allowed then
      raise exception 'QUIZ_ATTEMPT_LIMIT_REACHED' using errcode = '22023';
    end if;
    insert into public.quiz_attempts(
      learner_id, class_id, quiz_assignment_id, quiz_version_id, client_start_key
    ) values (
      (select auth.uid()), v_assignment.class_id, v_assignment.id,
      v_assignment.quiz_version_id, p_client_start_key
    )
    on conflict (learner_id, quiz_assignment_id, client_start_key)
    do update set client_start_key = excluded.client_start_key
    returning * into v_attempt;
    perform private.write_audit_event(
      'quiz_attempt.started', 'quiz_attempt', v_attempt.id, null,
      jsonb_build_object('assignment_id', v_assignment.id, 'quiz_version_id', v_assignment.quiz_version_id)
    );
  end if;

  select jsonb_build_object(
    'attempt_id', v_attempt.id,
    'status', v_attempt.status,
    'started_at', v_attempt.started_at,
    'quiz', jsonb_build_object(
      'assignment_id', a.id,
      'title', q.title,
      'description', q.description,
      'topic', q.topic,
      'instructions', coalesce(a.instructions, qv.instructions),
      'class_title', c.title,
      'version_number', qv.version_number
    ),
    'questions', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', qi.id,
        'code', qi.item_code,
        'type', qi.item_type,
        'prompt', qi.prompt,
        'options', qi.options,
        'order_index', qi.order_index,
        'saved_answer', ans.answer #>> '{}'
      ) order by qi.order_index)
      from public.quiz_items qi
      left join public.quiz_answers ans
        on ans.quiz_attempt_id = v_attempt.id and ans.quiz_item_id = qi.id
      where qi.quiz_version_id = v_attempt.quiz_version_id
        and qi.review_status = 'approved'::public.quiz_item_review_status
        and qi.removed_at is null
    ), '[]'::jsonb)
  ) into v_payload
  from public.quiz_assignments a
  join public.quiz_versions qv on qv.id = a.quiz_version_id
  join public.quizzes q on q.id = qv.quiz_id
  join public.classes c on c.id = a.class_id
  where a.id = v_attempt.quiz_assignment_id;

  return v_payload;
end
$$;

create or replace function public.save_learner_quiz_answer(
  p_attempt_id uuid,
  p_item_id uuid,
  p_answer text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_attempt public.quiz_attempts;
  v_answer public.quiz_answers;
begin
  if not public.is_learner() then raise exception 'LEARNER_REQUIRED' using errcode = '42501'; end if;
  if length(btrim(coalesce(p_answer, ''))) not between 1 and 2000 then
    raise exception 'QUIZ_ANSWER_REQUIRED' using errcode = '22023';
  end if;
  select * into v_attempt from public.quiz_attempts
  where id = p_attempt_id and learner_id = (select auth.uid()) for update;
  if not found then raise exception 'QUIZ_ATTEMPT_NOT_FOUND' using errcode = 'P0002'; end if;
  if v_attempt.status <> 'in_progress'::public.quiz_attempt_status then
    raise exception 'QUIZ_ATTEMPT_ALREADY_SUBMITTED' using errcode = '55000';
  end if;
  if not exists (
    select 1 from public.quiz_items qi
    where qi.id = p_item_id
      and qi.quiz_version_id = v_attempt.quiz_version_id
      and qi.review_status = 'approved'::public.quiz_item_review_status
      and qi.removed_at is null
  ) then raise exception 'QUIZ_ITEM_NOT_AVAILABLE' using errcode = '42501'; end if;

  insert into public.quiz_answers(
    quiz_attempt_id, quiz_item_id, quiz_version_id, answer
  ) values(
    v_attempt.id, p_item_id, v_attempt.quiz_version_id, to_jsonb(btrim(p_answer))
  )
  on conflict (quiz_attempt_id, quiz_item_id)
  do update set answer = excluded.answer, is_correct = null, answered_at = now()
  returning * into v_answer;
  return jsonb_build_object(
    'attempt_id', v_attempt.id,
    'item_id', p_item_id,
    'saved', true,
    'answered_at', v_answer.answered_at
  );
end
$$;

create or replace function public.submit_learner_quiz(
  p_attempt_id uuid,
  p_submission_key uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_attempt public.quiz_attempts;
  v_question_count integer;
  v_answer_count integer;
  v_correct_count integer;
  v_results jsonb;
  v_result public.quiz_results;
begin
  if not public.is_learner() then raise exception 'LEARNER_REQUIRED' using errcode = '42501'; end if;
  select * into v_attempt from public.quiz_attempts
  where id = p_attempt_id and learner_id = (select auth.uid()) for update;
  if not found then raise exception 'QUIZ_ATTEMPT_NOT_FOUND' using errcode = 'P0002'; end if;

  if v_attempt.status = 'completed'::public.quiz_attempt_status then
    select * into v_result from public.quiz_results where quiz_attempt_id = v_attempt.id;
    return jsonb_build_object(
      'attempt_id', v_attempt.id, 'status', v_attempt.status,
      'correct_count', v_result.correct_count,
      'question_count', v_result.question_count,
      'evaluated_at', v_result.evaluated_at
    );
  end if;
  if v_attempt.status <> 'in_progress'::public.quiz_attempt_status then
    raise exception 'QUIZ_SUBMISSION_IN_PROGRESS' using errcode = '55000';
  end if;

  select count(*) into v_question_count from public.quiz_items qi
  where qi.quiz_version_id = v_attempt.quiz_version_id
    and qi.review_status = 'approved'::public.quiz_item_review_status
    and qi.removed_at is null;
  select count(*) into v_answer_count from public.quiz_answers qa
  where qa.quiz_attempt_id = v_attempt.id;
  if v_question_count < 1 or v_answer_count <> v_question_count then
    raise exception 'ANSWER_EVERY_QUESTION_BEFORE_SUBMISSION' using errcode = '22023';
  end if;

  update public.quiz_attempts set
    status = 'submitted'::public.quiz_attempt_status,
    submission_key = p_submission_key,
    submitted_at = now()
  where id = v_attempt.id;

  update public.quiz_answers ans set is_correct = (
    case
      when qi.item_type in ('identification'::public.quiz_item_type, 'true_false'::public.quiz_item_type)
        then lower(btrim(ans.answer #>> '{}')) = lower(btrim(qi.correct_answer #>> '{}'))
      else ans.answer #>> '{}' = qi.correct_answer #>> '{}'
    end
  )
  from public.quiz_items qi
  where ans.quiz_attempt_id = v_attempt.id and qi.id = ans.quiz_item_id;

  select count(*) filter (where ans.is_correct),
    jsonb_agg(jsonb_build_object(
      'item_id', qi.id,
      'code', qi.item_code,
      'type', qi.item_type,
      'prompt', qi.prompt,
      'learner_answer', ans.answer #>> '{}',
      'is_correct', ans.is_correct,
      'order_index', qi.order_index
    ) order by qi.order_index)
  into v_correct_count, v_results
  from public.quiz_answers ans
  join public.quiz_items qi on qi.id = ans.quiz_item_id
  where ans.quiz_attempt_id = v_attempt.id;

  insert into public.quiz_results(
    quiz_attempt_id, correct_count, question_count, item_results
  ) values (
    v_attempt.id, v_correct_count, v_question_count, coalesce(v_results, '[]'::jsonb)
  ) returning * into v_result;

  update public.quiz_attempts set
    status = 'completed'::public.quiz_attempt_status,
    completed_at = v_result.evaluated_at
  where id = v_attempt.id;

  perform private.write_audit_event(
    'quiz_attempt.completed', 'quiz_attempt', v_attempt.id, null,
    jsonb_build_object(
      'quiz_assignment_id', v_attempt.quiz_assignment_id,
      'correct_count', v_correct_count,
      'question_count', v_question_count
    ), null, jsonb_build_object('competency_authority', false)
  );

  return jsonb_build_object(
    'attempt_id', v_attempt.id,
    'status', 'completed',
    'correct_count', v_correct_count,
    'question_count', v_question_count,
    'evaluated_at', v_result.evaluated_at
  );
end
$$;

create or replace function public.get_learner_quiz_result(p_attempt_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_payload jsonb;
begin
  if not public.is_learner() then raise exception 'LEARNER_REQUIRED' using errcode = '42501'; end if;
  select jsonb_build_object(
    'attempt_id', qa.id,
    'status', qa.status,
    'title', q.title,
    'class_title', c.title,
    'completed_at', qa.completed_at,
    'correct_count', qr.correct_count,
    'question_count', qr.question_count,
    'item_results', qr.item_results,
    'supplementary_only', true
  ) into v_payload
  from public.quiz_attempts qa
  join public.quiz_results qr on qr.quiz_attempt_id = qa.id
  join public.quiz_versions qv on qv.id = qa.quiz_version_id
  join public.quizzes q on q.id = qv.quiz_id
  join public.classes c on c.id = qa.class_id
  where qa.id = p_attempt_id
    and qa.learner_id = (select auth.uid())
    and qa.status = 'completed'::public.quiz_attempt_status;
  if v_payload is null then raise exception 'QUIZ_RESULT_NOT_AVAILABLE' using errcode = 'P0002'; end if;
  return v_payload;
end
$$;

revoke all on function public.assign_published_quiz(uuid,uuid,timestamptz,timestamptz,integer,text) from public, anon;
revoke all on function public.get_available_learner_quizzes() from public, anon;
revoke all on function public.start_learner_quiz(uuid,uuid) from public, anon;
revoke all on function public.save_learner_quiz_answer(uuid,uuid,text) from public, anon;
revoke all on function public.submit_learner_quiz(uuid,uuid) from public, anon;
revoke all on function public.get_learner_quiz_result(uuid) from public, anon;

grant execute on function public.assign_published_quiz(uuid,uuid,timestamptz,timestamptz,integer,text) to authenticated;
grant execute on function public.get_available_learner_quizzes() to authenticated;
grant execute on function public.start_learner_quiz(uuid,uuid) to authenticated;
grant execute on function public.save_learner_quiz_answer(uuid,uuid,text) to authenticated;
grant execute on function public.submit_learner_quiz(uuid,uuid) to authenticated;
grant execute on function public.get_learner_quiz_result(uuid) to authenticated;

commit;
