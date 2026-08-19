-- Supporting indexes and non-destructive quarantine metadata for legacy
-- client-authored mission results.

begin;

create index if not exists coc_modules_competency_id_idx
  on public.coc_modules(competency_id);
create index if not exists missions_competency_id_idx
  on public.missions(competency_id);
create index if not exists leaderboard_entries_mission_result_id_idx
  on public.leaderboard_entries(mission_result_id);
create index if not exists notifications_related_mission_id_idx
  on public.notifications(related_mission_id);
create index if not exists notifications_related_coc_id_idx
  on public.notifications(related_coc_id);
create index if not exists task_results_task_id_idx
  on public.task_results(task_id);
create index if not exists user_badges_badge_id_idx
  on public.user_badges(badge_id);
create index if not exists user_badges_mission_id_idx
  on public.user_badges(mission_id);
create index if not exists user_badges_coc_id_idx
  on public.user_badges(coc_id);
create index if not exists user_achievements_achievement_id_idx
  on public.user_achievements(achievement_id);
create index if not exists user_achievements_mission_id_idx
  on public.user_achievements(mission_id);
create index if not exists user_achievements_coc_id_idx
  on public.user_achievements(coc_id);

create table if not exists public.legacy_result_quarantine (
  legacy_mission_result_id uuid primary key
    references public.mission_results(id) on delete restrict,
  duplicate_group_key text not null,
  integrity_flags text[] not null default '{}',
  migration_status text not null default 'pending_review'
    check (migration_status in (
      'pending_review',
      'approved_for_import',
      'imported_as_legacy',
      'excluded_with_reason'
    )),
  review_reason text,
  reviewed_by uuid references auth.users(id) on delete restrict,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  constraint legacy_result_quarantine_review_check check (
    migration_status = 'pending_review'
    or (
      reviewed_by is not null
      and reviewed_at is not null
      and nullif(btrim(review_reason), '') is not null
    )
  )
);

insert into public.legacy_result_quarantine (
  legacy_mission_result_id,
  duplicate_group_key,
  integrity_flags
)
select
  mr.id,
  md5(mr.user_id::text || ':' || mr.mission_id::text || ':' || mr.attempt_number::text),
  array_remove(array[
    case
      when count(*) over (
        partition by mr.user_id, mr.mission_id, mr.attempt_number
      ) > 1 then 'DUPLICATE_ATTEMPT_IDENTITY'
    end,
    case
      when not exists (
        select 1
        from public.task_results tr
        where tr.mission_result_id = mr.id
      ) then 'MISSING_TASK_EVIDENCE'
    end,
    case when mr.score <> mr.percentage then 'SCORE_PERCENTAGE_MISMATCH' end,
    'UNVERIFIED_CLIENT_AUTHORED_RESULT',
    'PENDING_TESDA_VALIDATION'
  ]::text[], null)
from public.mission_results mr
on conflict (legacy_mission_result_id) do nothing;

alter table public.legacy_result_quarantine enable row level security;
revoke all on public.legacy_result_quarantine from anon, authenticated;
grant select on public.legacy_result_quarantine to authenticated;

create policy legacy_result_quarantine_admin_select
on public.legacy_result_quarantine for select to authenticated
using (public.is_admin());

commit;
