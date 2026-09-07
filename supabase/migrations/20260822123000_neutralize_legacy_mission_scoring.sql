-- Legacy mission passing_score values were not backed by an approved TESDA
-- source or a published rubric version. Neutralize only this catalog field;
-- historical attempts/results and project-approved gamification remain intact.

begin;

alter table public.missions
  alter column passing_score set default 0;

update public.missions
set passing_score = 0
where passing_score <> 0;

comment on column public.missions.passing_score is
  'Legacy compatibility field fixed at zero. Authoritative outcomes are produced from published rubric versions and Instructor finalization.';

-- RAISE is classified as STABLE by PostgreSQL. Keep the compatibility helper
-- fail-closed without falsely declaring the function immutable, including on
-- databases that already applied the original quarantine migration.
alter function public.get_rating(integer) stable;

commit;
