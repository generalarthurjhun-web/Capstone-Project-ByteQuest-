-- One-time, guarded cleanup for the linked ByteQuest UAT project.
-- This script removes transactional/demo content only. It does not alter
-- schema objects, policies, grants, functions, publications, or reference
-- definitions. The exact canonical Auth UUID guard prevents accidental use
-- against another Supabase project.

begin;

do $$
declare
  v_admin constant uuid := 'ed0f391a-cf1c-418f-9003-2a6ba9541ec8';
  v_instructor constant uuid := '2b3d9027-3eb8-4bb6-88c2-969c9f957a12';
  v_profile_count bigint;
  v_fixture_count bigint;
begin
  if not exists (
    select 1 from public.profiles
    where user_id = v_admin and lower(email) = 'admin@dnsc.edu.ph'
      and role = 'admin'::public.user_role and status = 'active'::public.account_status
  ) or not exists (
    select 1 from public.profiles
    where user_id = v_instructor and lower(email) = 'instructor@dnsc.edu.ph'
      and role = 'instructor'::public.user_role and status = 'active'::public.account_status
  ) then
    raise exception 'CLEANUP_ABORTED_CANONICAL_ACCOUNTS_DO_NOT_MATCH';
  end if;

  select count(*) into v_profile_count from public.profiles;
  select count(*) into v_fixture_count
  from public.profiles
  where email like '%@bytequest-uat.invalid'
     or email like '%@bytequest-e2e.invalid';

  -- The initial reset had a large UAT signature. A final regression pass may
  -- create only a handful of recognized disposable fixtures, so a repeat reset
  -- is allowed only when the database is already at the exact two-account
  -- baseline or every additional profile has the controlled test-domain marker.
  if v_profile_count < 2
     or (v_profile_count > 2 and v_fixture_count <> v_profile_count - 2) then
    raise exception 'CLEANUP_ABORTED_TEST_ENVIRONMENT_SIGNATURE_MISSING';
  end if;

  if (select count(*) from public.coc_modules) <> 4
     or (select count(*) from public.missions) <> 20
     or (select count(*) from public.activity_versions) <> 20
     or (select count(*) from public.rubric_criteria) <> 98 then
    raise exception 'CLEANUP_ABORTED_AUTHORITATIVE_FOUNDATION_MISMATCH';
  end if;
end
$$;

-- Retained academic/versioned rows were originally provisioned by disposable
-- UAT governance accounts. Reassign only their actor foreign keys so the
-- immutable academic foundation remains valid after those Auth users are
-- removed. The pre-cleanup snapshot preserves the original actor metadata.
update public.tesda_sources
set created_by = 'ed0f391a-cf1c-418f-9003-2a6ba9541ec8',
    approved_by = case when approved_by is null then null else 'ed0f391a-cf1c-418f-9003-2a6ba9541ec8'::uuid end,
    activated_by = case when activated_by is null then null else 'ed0f391a-cf1c-418f-9003-2a6ba9541ec8'::uuid end
where created_by <> 'ed0f391a-cf1c-418f-9003-2a6ba9541ec8'
   or approved_by is distinct from 'ed0f391a-cf1c-418f-9003-2a6ba9541ec8'
   or activated_by is distinct from 'ed0f391a-cf1c-418f-9003-2a6ba9541ec8';

update public.module_versions
set created_by = 'ed0f391a-cf1c-418f-9003-2a6ba9541ec8',
    published_by = case when published_by is null then null else 'ed0f391a-cf1c-418f-9003-2a6ba9541ec8'::uuid end
where created_by <> 'ed0f391a-cf1c-418f-9003-2a6ba9541ec8'
   or published_by is distinct from 'ed0f391a-cf1c-418f-9003-2a6ba9541ec8';

update public.activity_versions
set created_by = 'ed0f391a-cf1c-418f-9003-2a6ba9541ec8',
    published_by = case when published_by is null then null else 'ed0f391a-cf1c-418f-9003-2a6ba9541ec8'::uuid end
where created_by <> 'ed0f391a-cf1c-418f-9003-2a6ba9541ec8'
   or published_by is distinct from 'ed0f391a-cf1c-418f-9003-2a6ba9541ec8';

update public.rubric_versions
set created_by = 'ed0f391a-cf1c-418f-9003-2a6ba9541ec8',
    approved_by = case when approved_by is null then null else 'ed0f391a-cf1c-418f-9003-2a6ba9541ec8'::uuid end
where created_by <> 'ed0f391a-cf1c-418f-9003-2a6ba9541ec8'
   or approved_by is distinct from 'ed0f391a-cf1c-418f-9003-2a6ba9541ec8';

insert into public.audit_events (
  actor_id, actor_role, action, target_type, reason, metadata, outcome
) values (
  'ed0f391a-cf1c-418f-9003-2a6ba9541ec8',
  'admin'::public.user_role,
  'test_environment.reset_started',
  'system',
  'Project-owner-authorized clean test-environment reset after a verified backup.',
  jsonb_build_object(
    'environment', 'ByteQuest UAT',
    'profiles_before', (select count(*) from public.profiles),
    'classes_before', (select count(*) from public.classes),
    'attempts_before', (select count(*) from public.attempts),
    'audit_history_preserved', true
  ),
  'success'
);

-- Append-only guarantees protect normal product operations. They are disabled
-- only inside this guarded transaction and restored before commit.
alter table public.attempt_actions disable trigger attempt_actions_append_only;
alter table public.criterion_results disable trigger criterion_results_append_only;
alter table public.score_revisions disable trigger score_revisions_append_only;
alter table public.gamification_events disable trigger gamification_events_append_only;
alter table public.quiz_results disable trigger quiz_results_append_only;
alter table public.quiz_items disable trigger quiz_items_protect_history;

delete from public.quiz_results;
delete from public.quiz_answers;
delete from public.quiz_attempts;
delete from public.quiz_assignments;
delete from public.quiz_items;
delete from public.ai_quiz_generations;
delete from public.quiz_versions;
delete from public.quizzes;

delete from public.result_releases;
update public.score_revisions set supersedes_revision_id = null
where supersedes_revision_id is not null;
delete from public.score_revisions;
delete from public.criterion_results;
delete from public.attempt_actions;
delete from public.attempts;

update public.assignments set prerequisite_assignment_id = null
where prerequisite_assignment_id is not null;
delete from public.assignments;
delete from public.coc_bypasses;

delete from public.task_results;
delete from public.legacy_result_quarantine;
delete from public.mission_results;
delete from public.learner_progress;
delete from public.user_achievements;
delete from public.user_badges;
delete from public.leaderboard_entries;
delete from public.gamification_events;
delete from public.notifications;
delete from public.activity_logs;
delete from public.reports;
delete from public.user_settings
where user_id not in (
  'ed0f391a-cf1c-418f-9003-2a6ba9541ec8',
  '2b3d9027-3eb8-4bb6-88c2-969c9f957a12'
);

delete from public.learning_resources;
delete from public.class_memberships;
delete from public.classes;

alter table public.attempt_actions enable trigger attempt_actions_append_only;
alter table public.criterion_results enable trigger criterion_results_append_only;
alter table public.score_revisions enable trigger score_revisions_append_only;
alter table public.gamification_events enable trigger gamification_events_append_only;
alter table public.quiz_results enable trigger quiz_results_append_only;
alter table public.quiz_items enable trigger quiz_items_protect_history;

do $$
begin
  if exists (select 1 from public.classes)
     or exists (select 1 from public.class_memberships)
     or exists (select 1 from public.assignments)
     or exists (select 1 from public.attempts)
     or exists (select 1 from public.attempt_actions)
     or exists (select 1 from public.criterion_results)
     or exists (select 1 from public.score_revisions)
     or exists (select 1 from public.result_releases)
     or exists (select 1 from public.learner_progress)
     or exists (select 1 from public.gamification_events)
     or exists (select 1 from public.quiz_attempts)
     or exists (select 1 from public.learning_resources) then
    raise exception 'CLEANUP_POSTCONDITION_FAILED_TRANSACTIONAL_ROWS_REMAIN';
  end if;

  if (select count(*) from public.coc_modules) <> 4
     or (select count(*) from public.missions) <> 20
     or (select count(*) from public.activity_versions) <> 20
     or (select count(*) from public.rubric_criteria) <> 98 then
    raise exception 'CLEANUP_POSTCONDITION_FAILED_FOUNDATION_CHANGED';
  end if;
end
$$;

commit;
