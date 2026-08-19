-- Keep quiz reads identically scoped while making each event visibility check
-- self-contained for Supabase Realtime's authenticated RLS transaction.

drop policy if exists quiz_assignments_select_scoped on public.quiz_assignments;
create policy quiz_assignments_select_scoped
on public.quiz_assignments for select to authenticated
using (
  public.is_admin()
  or exists (
    select 1 from public.classes c
    where c.id = quiz_assignments.class_id
      and c.instructor_id = (select auth.uid())
  )
  or exists (
    select 1 from public.class_memberships cm
    where cm.class_id = quiz_assignments.class_id
      and cm.learner_id = (select auth.uid())
      and cm.status = 'active'::public.membership_status
  )
);

drop policy if exists quiz_attempts_select_scoped on public.quiz_attempts;
create policy quiz_attempts_select_scoped
on public.quiz_attempts for select to authenticated
using (
  learner_id = (select auth.uid())
  or public.is_admin()
  or exists (
    select 1 from public.classes c
    where c.id = quiz_attempts.class_id
      and c.instructor_id = (select auth.uid())
  )
);

drop policy if exists quiz_results_select_scoped on public.quiz_results;
create policy quiz_results_select_scoped
on public.quiz_results for select to authenticated
using (
  exists (
    select 1
    from public.quiz_attempts qa
    where qa.id = quiz_results.quiz_attempt_id
      and (
        qa.learner_id = (select auth.uid())
        or public.is_admin()
        or exists (
          select 1 from public.classes c
          where c.id = qa.class_id
            and c.instructor_id = (select auth.uid())
        )
      )
  )
);
