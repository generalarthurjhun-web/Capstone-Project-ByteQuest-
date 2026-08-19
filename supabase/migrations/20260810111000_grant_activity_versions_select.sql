-- RLS cannot grant access without the underlying table privilege. The scoped
-- policy already limits each role; this restores the missing SELECT grant used
-- by mobile assignment hydration and Instructor rubric/evidence review.

begin;

grant select on table public.activity_versions to authenticated;

commit;
