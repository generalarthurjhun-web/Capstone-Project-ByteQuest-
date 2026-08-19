-- Instructor-owned quiz authoring with audited draft/review/publish lifecycle.
-- AI generations are drafts only and are intentionally separate from competency evaluation.

begin;

do $$
begin
  create type public.quiz_item_type as enum (
    'multiple_choice',
    'true_false',
    'identification',
    'scenario_based'
  );
exception when duplicate_object then null;
end
$$;

do $$
begin
  create type public.quiz_item_origin as enum ('instructor_authored', 'ai_generated_draft');
exception when duplicate_object then null;
end
$$;

do $$
begin
  create type public.quiz_item_review_status as enum ('draft', 'approved', 'rejected');
exception when duplicate_object then null;
end
$$;

do $$
begin
  create type public.ai_generation_status as enum ('requested', 'completed', 'failed');
exception when duplicate_object then null;
end
$$;

create table public.quizzes (
  id uuid primary key default gen_random_uuid(),
  instructor_id uuid not null references auth.users(id) on delete restrict,
  coc_module_id uuid references public.coc_modules(id) on delete restrict,
  title text not null check (length(btrim(title)) between 3 and 200),
  description text,
  topic text not null check (length(btrim(topic)) between 2 and 240),
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz,
  archived_by uuid references auth.users(id) on delete restrict,
  archive_reason text,
  constraint quizzes_archive_details_check check (
    archived_at is null
    or (archived_by is not null and nullif(btrim(archive_reason), '') is not null)
  )
);

create index quizzes_instructor_updated_idx on public.quizzes(instructor_id, updated_at desc);
create index quizzes_coc_module_idx on public.quizzes(coc_module_id) where coc_module_id is not null;

create table public.quiz_versions (
  id uuid primary key default gen_random_uuid(),
  quiz_id uuid not null references public.quizzes(id) on delete restrict,
  version_number integer not null check (version_number > 0),
  instructions text,
  change_summary text,
  status public.content_version_status not null default 'draft',
  created_by uuid not null references auth.users(id) on delete restrict,
  published_by uuid references auth.users(id) on delete restrict,
  published_at timestamptz,
  retired_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (quiz_id, version_number),
  constraint quiz_versions_publish_details_check check (
    status <> 'published'::public.content_version_status
    or (published_by is not null and published_at is not null)
  )
);

create unique index quiz_versions_one_published_idx
  on public.quiz_versions(quiz_id)
  where status = 'published'::public.content_version_status;
create index quiz_versions_quiz_status_idx on public.quiz_versions(quiz_id, status, version_number desc);

create table public.ai_quiz_generations (
  id uuid primary key default gen_random_uuid(),
  instructor_id uuid not null references auth.users(id) on delete restrict,
  quiz_version_id uuid not null references public.quiz_versions(id) on delete restrict,
  provider text not null default 'openai' check (length(btrim(provider)) between 2 and 80),
  model text not null check (length(btrim(model)) between 2 and 120),
  input_context jsonb not null default '{}'::jsonb,
  requested_count integer not null check (requested_count between 1 and 20),
  generated_count integer not null default 0 check (generated_count between 0 and 20),
  status public.ai_generation_status not null default 'requested',
  failure_code text,
  requested_at timestamptz not null default now(),
  completed_at timestamptz,
  constraint ai_quiz_generations_completion_check check (
    (status = 'requested'::public.ai_generation_status and completed_at is null and failure_code is null)
    or (status = 'completed'::public.ai_generation_status and completed_at is not null and failure_code is null)
    or (status = 'failed'::public.ai_generation_status and completed_at is not null and nullif(btrim(failure_code), '') is not null)
  )
);

create index ai_quiz_generations_owner_created_idx
  on public.ai_quiz_generations(instructor_id, requested_at desc);
create index ai_quiz_generations_version_idx
  on public.ai_quiz_generations(quiz_version_id, requested_at desc);

create table public.quiz_items (
  id uuid primary key default gen_random_uuid(),
  quiz_version_id uuid not null references public.quiz_versions(id) on delete restrict,
  item_code text not null check (length(btrim(item_code)) between 3 and 100),
  item_type public.quiz_item_type not null,
  prompt text not null check (length(btrim(prompt)) between 5 and 2000),
  options jsonb not null default '[]'::jsonb check (jsonb_typeof(options) = 'array'),
  correct_answer jsonb not null,
  explanation text,
  origin public.quiz_item_origin not null default 'instructor_authored',
  ai_generation_id uuid references public.ai_quiz_generations(id) on delete restrict,
  review_status public.quiz_item_review_status not null default 'draft',
  review_notes text,
  reviewed_by uuid references auth.users(id) on delete restrict,
  reviewed_at timestamptz,
  order_index integer not null check (order_index > 0),
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  removed_at timestamptz,
  removed_by uuid references auth.users(id) on delete restrict,
  removal_reason text,
  unique (quiz_version_id, item_code),
  unique (quiz_version_id, order_index),
  constraint quiz_items_ai_origin_check check (
    (origin = 'ai_generated_draft'::public.quiz_item_origin and ai_generation_id is not null)
    or (origin = 'instructor_authored'::public.quiz_item_origin and ai_generation_id is null)
  ),
  constraint quiz_items_review_details_check check (
    (review_status = 'draft'::public.quiz_item_review_status and reviewed_by is null and reviewed_at is null)
    or (review_status in ('approved'::public.quiz_item_review_status, 'rejected'::public.quiz_item_review_status)
        and reviewed_by is not null and reviewed_at is not null)
  ),
  constraint quiz_items_removal_details_check check (
    removed_at is null
    or (removed_by is not null and nullif(btrim(removal_reason), '') is not null)
  )
);

create index quiz_items_version_order_idx on public.quiz_items(quiz_version_id, order_index);
create index quiz_items_generation_idx on public.quiz_items(ai_generation_id) where ai_generation_id is not null;

drop trigger if exists trg_quizzes_updated_at on public.quizzes;
create trigger trg_quizzes_updated_at before update on public.quizzes
for each row execute function public.set_updated_at();

drop trigger if exists trg_quiz_versions_updated_at on public.quiz_versions;
create trigger trg_quiz_versions_updated_at before update on public.quiz_versions
for each row execute function public.set_updated_at();

drop trigger if exists trg_quiz_items_updated_at on public.quiz_items;
create trigger trg_quiz_items_updated_at before update on public.quiz_items
for each row execute function public.set_updated_at();

create or replace function private.validate_quiz_item(
  p_item_type public.quiz_item_type,
  p_options jsonb,
  p_correct_answer jsonb
)
returns boolean
language sql
immutable
set search_path = ''
as $$
  select
    jsonb_typeof(coalesce(p_options, 'null'::jsonb)) = 'array'
    and jsonb_typeof(p_correct_answer) = 'string'
    and case
      when p_item_type in ('multiple_choice'::public.quiz_item_type, 'scenario_based'::public.quiz_item_type)
        then jsonb_array_length(p_options) between 2 and 6
             and p_options @> jsonb_build_array(p_correct_answer)
      when p_item_type = 'true_false'::public.quiz_item_type
        then jsonb_array_length(p_options) = 0
             and lower(p_correct_answer #>> '{}') in ('true', 'false')
      when p_item_type = 'identification'::public.quiz_item_type
        then jsonb_array_length(p_options) = 0
             and length(btrim(p_correct_answer #>> '{}')) between 1 and 500
      else false
    end
$$;

alter table public.quiz_items
  add constraint quiz_items_answer_contract_check
  check (private.validate_quiz_item(item_type, options, correct_answer));

create or replace function private.protect_quiz_item_history()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_status public.content_version_status;
begin
  select qv.status into v_status
  from public.quiz_versions qv
  where qv.id = old.quiz_version_id;

  if v_status <> 'draft'::public.content_version_status then
    raise exception 'PUBLISHED_QUIZ_ITEMS_ARE_IMMUTABLE' using errcode = '55000';
  end if;

  return case when tg_op = 'DELETE' then old else new end;
end
$$;

drop trigger if exists quiz_items_protect_history on public.quiz_items;
create trigger quiz_items_protect_history
before update or delete on public.quiz_items
for each row execute function private.protect_quiz_item_history();

alter table public.quizzes enable row level security;
alter table public.quiz_versions enable row level security;
alter table public.quiz_items enable row level security;
alter table public.ai_quiz_generations enable row level security;

create policy quizzes_staff_select on public.quizzes for select to authenticated
using (instructor_id = (select auth.uid()) or public.is_admin());

create policy quiz_versions_staff_select on public.quiz_versions for select to authenticated
using (exists (
  select 1 from public.quizzes q
  where q.id = quiz_versions.quiz_id
    and (q.instructor_id = (select auth.uid()) or public.is_admin())
));

create policy quiz_items_staff_select on public.quiz_items for select to authenticated
using (exists (
  select 1 from public.quiz_versions qv
  join public.quizzes q on q.id = qv.quiz_id
  where qv.id = quiz_items.quiz_version_id
    and (q.instructor_id = (select auth.uid()) or public.is_admin())
));

create policy ai_quiz_generations_staff_select on public.ai_quiz_generations for select to authenticated
using (instructor_id = (select auth.uid()) or public.is_admin());

grant select on public.quizzes, public.quiz_versions, public.quiz_items, public.ai_quiz_generations to authenticated;

create or replace function public.create_instructor_quiz(
  p_title text,
  p_topic text,
  p_description text default null,
  p_coc_module_id uuid default null,
  p_instructions text default null
)
returns public.quizzes
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_quiz public.quizzes;
begin
  if not public.is_instructor() then
    raise exception 'INSTRUCTOR_REQUIRED' using errcode = '42501';
  end if;

  if length(btrim(coalesce(p_title, ''))) not between 3 and 200
     or length(btrim(coalesce(p_topic, ''))) not between 2 and 240 then
    raise exception 'QUIZ_TITLE_AND_TOPIC_REQUIRED' using errcode = '22023';
  end if;

  if p_coc_module_id is not null and not exists (
    select 1 from public.coc_modules cm where cm.id = p_coc_module_id
  ) then
    raise exception 'COC_MODULE_NOT_FOUND' using errcode = 'P0002';
  end if;

  insert into public.quizzes (instructor_id, coc_module_id, title, description, topic, created_by)
  values ((select auth.uid()), p_coc_module_id, btrim(p_title), nullif(btrim(p_description), ''), btrim(p_topic), (select auth.uid()))
  returning * into v_quiz;

  insert into public.quiz_versions (quiz_id, version_number, instructions, change_summary, created_by)
  values (v_quiz.id, 1, nullif(btrim(p_instructions), ''), 'Initial draft', (select auth.uid()));

  perform private.write_audit_event('quiz.created', 'quiz', v_quiz.id, null, to_jsonb(v_quiz));
  return v_quiz;
end
$$;

create or replace function public.update_instructor_quiz(
  p_quiz_id uuid,
  p_title text,
  p_topic text,
  p_description text default null,
  p_coc_module_id uuid default null
)
returns public.quizzes
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_quiz public.quizzes;
  v_old jsonb;
begin
  if not public.is_instructor() then raise exception 'INSTRUCTOR_REQUIRED' using errcode = '42501'; end if;
  select q.* into v_quiz from public.quizzes q where q.id = p_quiz_id for update;
  if not found then raise exception 'QUIZ_NOT_FOUND' using errcode = 'P0002'; end if;
  if v_quiz.instructor_id <> (select auth.uid()) then raise exception 'QUIZ_SCOPE_DENIED' using errcode = '42501'; end if;
  if v_quiz.archived_at is not null then raise exception 'QUIZ_ARCHIVED' using errcode = '22023'; end if;
  if length(btrim(coalesce(p_title, ''))) not between 3 and 200
     or length(btrim(coalesce(p_topic, ''))) not between 2 and 240 then
    raise exception 'QUIZ_TITLE_AND_TOPIC_REQUIRED' using errcode = '22023';
  end if;
  if p_coc_module_id is not null and not exists (select 1 from public.coc_modules cm where cm.id = p_coc_module_id) then
    raise exception 'COC_MODULE_NOT_FOUND' using errcode = 'P0002';
  end if;
  v_old := to_jsonb(v_quiz);
  update public.quizzes set title=btrim(p_title), topic=btrim(p_topic), description=nullif(btrim(p_description), ''), coc_module_id=p_coc_module_id
  where id=p_quiz_id returning * into v_quiz;
  perform private.write_audit_event('quiz.updated', 'quiz', v_quiz.id, v_old, to_jsonb(v_quiz));
  return v_quiz;
end
$$;

create or replace function public.create_quiz_version(
  p_quiz_id uuid,
  p_instructions text default null,
  p_change_summary text default null
)
returns public.quiz_versions
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_quiz public.quizzes;
  v_version public.quiz_versions;
  v_number integer;
begin
  if not public.is_instructor() then raise exception 'INSTRUCTOR_REQUIRED' using errcode = '42501'; end if;
  select q.* into v_quiz from public.quizzes q where q.id=p_quiz_id for update;
  if not found then raise exception 'QUIZ_NOT_FOUND' using errcode = 'P0002'; end if;
  if v_quiz.instructor_id <> (select auth.uid()) then raise exception 'QUIZ_SCOPE_DENIED' using errcode = '42501'; end if;
  if v_quiz.archived_at is not null then raise exception 'QUIZ_ARCHIVED' using errcode = '22023'; end if;
  if exists (select 1 from public.quiz_versions qv where qv.quiz_id=p_quiz_id and qv.status='draft'::public.content_version_status) then
    raise exception 'QUIZ_ALREADY_HAS_DRAFT' using errcode = '23505';
  end if;
  select coalesce(max(qv.version_number),0)+1 into v_number from public.quiz_versions qv where qv.quiz_id=p_quiz_id;
  insert into public.quiz_versions(quiz_id,version_number,instructions,change_summary,created_by)
  values(p_quiz_id,v_number,nullif(btrim(p_instructions),''),nullif(btrim(p_change_summary),''),(select auth.uid())) returning * into v_version;
  perform private.write_audit_event('quiz_version.created','quiz_version',v_version.id,null,to_jsonb(v_version));
  return v_version;
end
$$;

create or replace function public.upsert_quiz_item(
  p_quiz_version_id uuid,
  p_item_type public.quiz_item_type,
  p_prompt text,
  p_options jsonb,
  p_correct_answer jsonb,
  p_explanation text default null,
  p_order_index integer default null,
  p_item_id uuid default null
)
returns public.quiz_items
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_version public.quiz_versions;
  v_quiz public.quizzes;
  v_item public.quiz_items;
  v_old jsonb;
  v_order integer;
begin
  if not public.is_instructor() then raise exception 'INSTRUCTOR_REQUIRED' using errcode='42501'; end if;
  select qv.* into v_version from public.quiz_versions qv where qv.id=p_quiz_version_id for update;
  if not found then raise exception 'QUIZ_VERSION_NOT_FOUND' using errcode='P0002'; end if;
  select q.* into v_quiz from public.quizzes q where q.id=v_version.quiz_id;
  if v_quiz.instructor_id <> (select auth.uid()) then raise exception 'QUIZ_SCOPE_DENIED' using errcode='42501'; end if;
  if v_version.status <> 'draft'::public.content_version_status then raise exception 'DRAFT_QUIZ_VERSION_REQUIRED' using errcode='22023'; end if;
  if length(btrim(coalesce(p_prompt,''))) not between 5 and 2000 or not private.validate_quiz_item(p_item_type,p_options,p_correct_answer) then
    raise exception 'INVALID_QUIZ_ITEM' using errcode='22023';
  end if;

  if p_item_id is null then
    select coalesce(p_order_index, coalesce(max(qi.order_index),0)+1) into v_order from public.quiz_items qi where qi.quiz_version_id=p_quiz_version_id;
    if exists(select 1 from public.quiz_items qi where qi.quiz_version_id=p_quiz_version_id and qi.order_index=v_order) then
      raise exception 'QUIZ_ITEM_ORDER_IN_USE' using errcode='23505';
    end if;
    insert into public.quiz_items(quiz_version_id,item_code,item_type,prompt,options,correct_answer,explanation,order_index,created_by)
    values(p_quiz_version_id,'ITEM-'||lpad(v_order::text,3,'0'),p_item_type,btrim(p_prompt),p_options,p_correct_answer,nullif(btrim(p_explanation),''),v_order,(select auth.uid()))
    returning * into v_item;
    perform private.write_audit_event('quiz_item.created','quiz_item',v_item.id,null,to_jsonb(v_item));
  else
    select qi.* into v_item from public.quiz_items qi where qi.id=p_item_id and qi.quiz_version_id=p_quiz_version_id for update;
    if not found then raise exception 'QUIZ_ITEM_NOT_FOUND' using errcode='P0002'; end if;
    if v_item.removed_at is not null then raise exception 'QUIZ_ITEM_REMOVED' using errcode='22023'; end if;
    v_old:=to_jsonb(v_item);
    v_order:=coalesce(p_order_index,v_item.order_index);
    if v_order<>v_item.order_index and exists(select 1 from public.quiz_items qi where qi.quiz_version_id=p_quiz_version_id and qi.order_index=v_order and qi.id<>v_item.id) then
      raise exception 'QUIZ_ITEM_ORDER_IN_USE' using errcode='23505';
    end if;
    update public.quiz_items set item_type=p_item_type,prompt=btrim(p_prompt),options=p_options,correct_answer=p_correct_answer,
      explanation=nullif(btrim(p_explanation),''),order_index=v_order,review_status='draft'::public.quiz_item_review_status,
      review_notes=null,reviewed_by=null,reviewed_at=null
    where id=p_item_id returning * into v_item;
    perform private.write_audit_event('quiz_item.updated','quiz_item',v_item.id,v_old,to_jsonb(v_item));
  end if;
  return v_item;
end
$$;

create or replace function public.review_quiz_item(
  p_item_id uuid,
  p_decision public.quiz_item_review_status,
  p_notes text default null
)
returns public.quiz_items
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_item public.quiz_items;
  v_old jsonb;
begin
  if not public.is_instructor() then raise exception 'INSTRUCTOR_REQUIRED' using errcode='42501'; end if;
  if p_decision not in ('approved'::public.quiz_item_review_status,'rejected'::public.quiz_item_review_status) then
    raise exception 'REVIEW_DECISION_REQUIRED' using errcode='22023';
  end if;
  if p_decision='rejected'::public.quiz_item_review_status and nullif(btrim(p_notes),'') is null then
    raise exception 'REJECTION_REASON_REQUIRED' using errcode='22023';
  end if;
  select qi.* into v_item from public.quiz_items qi
  join public.quiz_versions qv on qv.id=qi.quiz_version_id
  join public.quizzes q on q.id=qv.quiz_id
  where qi.id=p_item_id and q.instructor_id=(select auth.uid()) and qv.status='draft'::public.content_version_status
  for update of qi;
  if not found then raise exception 'QUIZ_ITEM_SCOPE_OR_STATE_DENIED' using errcode='42501'; end if;
  if v_item.removed_at is not null then raise exception 'QUIZ_ITEM_REMOVED' using errcode='22023'; end if;
  v_old:=to_jsonb(v_item);
  update public.quiz_items set review_status=p_decision,review_notes=nullif(btrim(p_notes),''),reviewed_by=(select auth.uid()),reviewed_at=now()
  where id=p_item_id returning * into v_item;
  perform private.write_audit_event('quiz_item.reviewed','quiz_item',v_item.id,v_old,to_jsonb(v_item),p_notes,jsonb_build_object('decision',p_decision));
  return v_item;
end
$$;

create or replace function public.remove_quiz_item(p_item_id uuid,p_reason text)
returns public.quiz_items
language plpgsql
security definer
set search_path = ''
as $$
declare v_item public.quiz_items; v_old jsonb;
begin
  if not public.is_instructor() then raise exception 'INSTRUCTOR_REQUIRED' using errcode='42501'; end if;
  if nullif(btrim(p_reason),'') is null then raise exception 'REMOVAL_REASON_REQUIRED' using errcode='22023'; end if;
  select qi.* into v_item from public.quiz_items qi join public.quiz_versions qv on qv.id=qi.quiz_version_id
  join public.quizzes q on q.id=qv.quiz_id
  where qi.id=p_item_id and q.instructor_id=(select auth.uid()) and qv.status='draft'::public.content_version_status for update of qi;
  if not found then raise exception 'QUIZ_ITEM_SCOPE_OR_STATE_DENIED' using errcode='42501'; end if;
  v_old:=to_jsonb(v_item);
  update public.quiz_items set removed_at=now(),removed_by=(select auth.uid()),removal_reason=btrim(p_reason),
    review_status='rejected'::public.quiz_item_review_status,review_notes=btrim(p_reason),reviewed_by=(select auth.uid()),reviewed_at=now()
  where id=p_item_id returning * into v_item;
  perform private.write_audit_event('quiz_item.removed','quiz_item',v_item.id,v_old,to_jsonb(v_item),p_reason);
  return v_item;
end
$$;

create or replace function public.publish_quiz_version(p_quiz_version_id uuid,p_reason text)
returns public.quiz_versions
language plpgsql
security definer
set search_path = ''
as $$
declare v_version public.quiz_versions; v_quiz public.quizzes; v_old jsonb;
begin
  if not public.is_instructor() then raise exception 'INSTRUCTOR_REQUIRED' using errcode='42501'; end if;
  if nullif(btrim(p_reason),'') is null then raise exception 'PUBLISH_REASON_REQUIRED' using errcode='22023'; end if;
  select qv.* into v_version from public.quiz_versions qv where qv.id=p_quiz_version_id for update;
  if not found then raise exception 'QUIZ_VERSION_NOT_FOUND' using errcode='P0002'; end if;
  select q.* into v_quiz from public.quizzes q where q.id=v_version.quiz_id for update;
  if v_quiz.instructor_id<>(select auth.uid()) then raise exception 'QUIZ_SCOPE_DENIED' using errcode='42501'; end if;
  if v_quiz.archived_at is not null or v_version.status<>'draft'::public.content_version_status then raise exception 'DRAFT_ACTIVE_QUIZ_REQUIRED' using errcode='22023'; end if;
  if not exists(select 1 from public.quiz_items qi where qi.quiz_version_id=v_version.id and qi.removed_at is null and qi.review_status='approved'::public.quiz_item_review_status) then
    raise exception 'APPROVED_QUIZ_ITEM_REQUIRED' using errcode='22023';
  end if;
  if exists(select 1 from public.quiz_items qi where qi.quiz_version_id=v_version.id and qi.removed_at is null and qi.review_status<>'approved'::public.quiz_item_review_status) then
    raise exception 'ALL_QUIZ_ITEMS_REQUIRE_APPROVAL' using errcode='22023';
  end if;
  v_old:=to_jsonb(v_version);
  update public.quiz_versions set status='retired'::public.content_version_status,retired_at=now()
  where quiz_id=v_quiz.id and status='published'::public.content_version_status;
  update public.quiz_versions set status='published'::public.content_version_status,published_by=(select auth.uid()),published_at=now()
  where id=v_version.id returning * into v_version;
  perform private.write_audit_event('quiz_version.published','quiz_version',v_version.id,v_old,to_jsonb(v_version),p_reason,
    jsonb_build_object('quiz_id',v_quiz.id,'approved_items',(select count(*) from public.quiz_items qi where qi.quiz_version_id=v_version.id and qi.removed_at is null)));
  return v_version;
end
$$;

create or replace function public.archive_instructor_quiz(p_quiz_id uuid,p_reason text)
returns public.quizzes
language plpgsql
security definer
set search_path = ''
as $$
declare v_quiz public.quizzes; v_old jsonb;
begin
  if not public.is_instructor() then raise exception 'INSTRUCTOR_REQUIRED' using errcode='42501'; end if;
  if nullif(btrim(p_reason),'') is null then raise exception 'ARCHIVE_REASON_REQUIRED' using errcode='22023'; end if;
  select q.* into v_quiz from public.quizzes q where q.id=p_quiz_id for update;
  if not found then raise exception 'QUIZ_NOT_FOUND' using errcode='P0002'; end if;
  if v_quiz.instructor_id<>(select auth.uid()) then raise exception 'QUIZ_SCOPE_DENIED' using errcode='42501'; end if;
  if v_quiz.archived_at is not null then return v_quiz; end if;
  v_old:=to_jsonb(v_quiz);
  update public.quizzes set archived_at=now(),archived_by=(select auth.uid()),archive_reason=btrim(p_reason)
  where id=p_quiz_id returning * into v_quiz;
  perform private.write_audit_event('quiz.archived','quiz',v_quiz.id,v_old,to_jsonb(v_quiz),p_reason);
  return v_quiz;
end
$$;

create or replace function public.begin_ai_quiz_generation(
  p_quiz_version_id uuid,
  p_model text,
  p_input_context jsonb,
  p_requested_count integer
)
returns public.ai_quiz_generations
language plpgsql
security definer
set search_path = ''
as $$
declare v_generation public.ai_quiz_generations;
begin
  if not public.is_instructor() then raise exception 'INSTRUCTOR_REQUIRED' using errcode='42501'; end if;
  if p_requested_count not between 1 and 20 or length(btrim(coalesce(p_model,''))) not between 2 and 120 then
    raise exception 'INVALID_AI_GENERATION_REQUEST' using errcode='22023';
  end if;
  if not exists(select 1 from public.quiz_versions qv join public.quizzes q on q.id=qv.quiz_id
    where qv.id=p_quiz_version_id and qv.status='draft'::public.content_version_status
      and q.instructor_id=(select auth.uid()) and q.archived_at is null) then
    raise exception 'QUIZ_VERSION_SCOPE_OR_STATE_DENIED' using errcode='42501';
  end if;
  insert into public.ai_quiz_generations(instructor_id,quiz_version_id,provider,model,input_context,requested_count)
  values((select auth.uid()),p_quiz_version_id,'openai',btrim(p_model),coalesce(p_input_context,'{}'::jsonb),p_requested_count)
  returning * into v_generation;
  perform private.write_audit_event('quiz.ai_draft.requested','ai_quiz_generation',v_generation.id,null,
    jsonb_build_object('quiz_version_id',p_quiz_version_id,'provider','openai','model',v_generation.model,'requested_count',p_requested_count));
  return v_generation;
end
$$;

create or replace function public.complete_ai_quiz_generation(
  p_generation_id uuid,
  p_actor_id uuid,
  p_provider text,
  p_model text,
  p_items jsonb
)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_generation public.ai_quiz_generations;
  v_version public.quiz_versions;
  v_item jsonb;
  v_count integer;
  v_order integer;
  v_type public.quiz_item_type;
begin
  if coalesce(auth.role(),'') <> 'service_role' then raise exception 'SERVICE_ROLE_REQUIRED' using errcode='42501'; end if;
  select g.* into v_generation from public.ai_quiz_generations g where g.id=p_generation_id for update;
  if not found then raise exception 'AI_GENERATION_NOT_FOUND' using errcode='P0002'; end if;
  if v_generation.status<>'requested'::public.ai_generation_status or v_generation.instructor_id<>p_actor_id then
    raise exception 'AI_GENERATION_STATE_DENIED' using errcode='22023';
  end if;
  select qv.* into v_version from public.quiz_versions qv join public.quizzes q on q.id=qv.quiz_id
  where qv.id=v_generation.quiz_version_id and q.instructor_id=p_actor_id for update of qv;
  if not found or v_version.status<>'draft'::public.content_version_status then raise exception 'DRAFT_QUIZ_VERSION_REQUIRED' using errcode='22023'; end if;
  if jsonb_typeof(p_items)<>'array' then raise exception 'AI_ITEMS_ARRAY_REQUIRED' using errcode='22023'; end if;
  v_count:=jsonb_array_length(p_items);
  if v_count<1 or v_count>v_generation.requested_count or v_count>20 then raise exception 'AI_ITEM_COUNT_INVALID' using errcode='22023'; end if;
  select coalesce(max(qi.order_index),0) into v_order from public.quiz_items qi where qi.quiz_version_id=v_version.id;
  for v_item in select value from jsonb_array_elements(p_items)
  loop
    v_type:=(v_item->>'item_type')::public.quiz_item_type;
    if length(btrim(coalesce(v_item->>'prompt',''))) not between 5 and 2000
       or not private.validate_quiz_item(v_type,coalesce(v_item->'options','[]'::jsonb),to_jsonb(v_item->>'correct_answer')) then
      raise exception 'AI_ITEM_CONTRACT_INVALID' using errcode='22023';
    end if;
    v_order:=v_order+1;
    insert into public.quiz_items(quiz_version_id,item_code,item_type,prompt,options,correct_answer,explanation,origin,ai_generation_id,order_index,created_by)
    values(v_version.id,'ITEM-'||lpad(v_order::text,3,'0'),v_type,btrim(v_item->>'prompt'),coalesce(v_item->'options','[]'::jsonb),
      to_jsonb(v_item->>'correct_answer'),nullif(btrim(v_item->>'explanation'),''),'ai_generated_draft'::public.quiz_item_origin,
      v_generation.id,v_order,p_actor_id);
  end loop;
  update public.ai_quiz_generations set provider=btrim(p_provider),model=btrim(p_model),status='completed'::public.ai_generation_status,
    generated_count=v_count,completed_at=now() where id=v_generation.id;
  insert into public.audit_events(actor_id,actor_role,action,target_type,target_id,new_value,metadata,outcome)
  values(p_actor_id,'instructor'::public.user_role,'quiz.ai_draft.completed','ai_quiz_generation',v_generation.id,
    jsonb_build_object('quiz_version_id',v_version.id,'provider',btrim(p_provider),'model',btrim(p_model),'generated_count',v_count),
    jsonb_build_object('draft_only',true,'auto_publish',false,'competency_authority',false),'success');
  return v_count;
end
$$;

create or replace function public.fail_ai_quiz_generation(p_generation_id uuid,p_actor_id uuid,p_failure_code text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare v_generation public.ai_quiz_generations;
begin
  if coalesce(auth.role(),'') <> 'service_role' then raise exception 'SERVICE_ROLE_REQUIRED' using errcode='42501'; end if;
  select g.* into v_generation from public.ai_quiz_generations g where g.id=p_generation_id for update;
  if not found or v_generation.instructor_id<>p_actor_id then raise exception 'AI_GENERATION_NOT_FOUND' using errcode='P0002'; end if;
  if v_generation.status='requested'::public.ai_generation_status then
    update public.ai_quiz_generations set status='failed'::public.ai_generation_status,
      failure_code=left(coalesce(nullif(btrim(p_failure_code),''),'AI_PROVIDER_FAILURE'),120),completed_at=now()
    where id=p_generation_id;
    insert into public.audit_events(actor_id,actor_role,action,target_type,target_id,metadata,outcome)
    values(p_actor_id,'instructor'::public.user_role,'quiz.ai_draft.failed','ai_quiz_generation',p_generation_id,
      jsonb_build_object('failure_code',left(coalesce(nullif(btrim(p_failure_code),''),'AI_PROVIDER_FAILURE'),120)),'failed');
  end if;
end
$$;

revoke all on function public.create_instructor_quiz(text,text,text,uuid,text) from public,anon;
revoke all on function public.update_instructor_quiz(uuid,text,text,text,uuid) from public,anon;
revoke all on function public.create_quiz_version(uuid,text,text) from public,anon;
revoke all on function public.upsert_quiz_item(uuid,public.quiz_item_type,text,jsonb,jsonb,text,integer,uuid) from public,anon;
revoke all on function public.review_quiz_item(uuid,public.quiz_item_review_status,text) from public,anon;
revoke all on function public.remove_quiz_item(uuid,text) from public,anon;
revoke all on function public.publish_quiz_version(uuid,text) from public,anon;
revoke all on function public.archive_instructor_quiz(uuid,text) from public,anon;
revoke all on function public.begin_ai_quiz_generation(uuid,text,jsonb,integer) from public,anon;
revoke all on function public.complete_ai_quiz_generation(uuid,uuid,text,text,jsonb) from public,anon,authenticated;
revoke all on function public.fail_ai_quiz_generation(uuid,uuid,text) from public,anon,authenticated;

grant execute on function public.create_instructor_quiz(text,text,text,uuid,text) to authenticated;
grant execute on function public.update_instructor_quiz(uuid,text,text,text,uuid) to authenticated;
grant execute on function public.create_quiz_version(uuid,text,text) to authenticated;
grant execute on function public.upsert_quiz_item(uuid,public.quiz_item_type,text,jsonb,jsonb,text,integer,uuid) to authenticated;
grant execute on function public.review_quiz_item(uuid,public.quiz_item_review_status,text) to authenticated;
grant execute on function public.remove_quiz_item(uuid,text) to authenticated;
grant execute on function public.publish_quiz_version(uuid,text) to authenticated;
grant execute on function public.archive_instructor_quiz(uuid,text) to authenticated;
grant execute on function public.begin_ai_quiz_generation(uuid,text,jsonb,integer) to authenticated;
grant execute on function public.complete_ai_quiz_generation(uuid,uuid,text,text,jsonb) to service_role;
grant execute on function public.fail_ai_quiz_generation(uuid,uuid,text) to service_role;

commit;
