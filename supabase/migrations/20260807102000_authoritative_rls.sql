-- Replace permissive legacy policies with explicit role and object scope.
-- All sensitive writes use audited SECURITY DEFINER RPCs defined earlier.

begin;

do $$
declare
  v_policy record;
begin
  for v_policy in
    select schemaname, tablename, policyname
    from pg_policies
    where schemaname = 'public'
  loop
    execute format(
      'drop policy if exists %I on %I.%I',
      v_policy.policyname,
      v_policy.schemaname,
      v_policy.tablename
    );
  end loop;
end
$$;

revoke all on all tables in schema public from anon;
revoke all on all tables in schema public from authenticated;

grant select on public.profiles to authenticated;
grant update (full_name, avatar_url, learner_id, school, course_section) on public.profiles to authenticated;

grant select on public.competencies,
  public.coc_modules,
  public.missions,
  public.levels,
  public.badges,
  public.achievements to authenticated;

grant select on public.simulation_tasks,
  public.assessment_criteria,
  public.mission_results,
  public.task_results,
  public.learner_progress,
  public.user_badges,
  public.user_achievements,
  public.leaderboard_entries,
  public.notifications,
  public.user_settings,
  public.reports,
  public.activity_logs to authenticated;

grant update (is_read, read_at) on public.notifications to authenticated;
grant insert on public.user_settings to authenticated;
grant update (
  notifications_enabled,
  sound_enabled,
  vibration_enabled,
  theme_mode,
  language
) on public.user_settings to authenticated;

grant select on public.classes,
  public.class_memberships,
  public.tesda_sources,
  public.module_versions,
  public.rubric_versions,
  public.rubric_criteria,
  public.assignments,
  public.attempts,
  public.attempt_actions,
  public.criterion_results,
  public.score_revisions,
  public.result_releases,
  public.coc_bypasses,
  public.gamification_events,
  public.learning_resources,
  public.system_settings,
  public.audit_events to authenticated;

grant select (
  id,
  mission_id,
  module_version_id,
  version_number,
  title,
  instructions,
  delivery_mode,
  learner_payload,
  status,
  published_at,
  created_at,
  updated_at
) on public.activity_versions to authenticated;

grant update (title, class_code) on public.classes to authenticated;

-- Profiles: own row, Admin system scope, Instructor learner scope through a
-- class the Instructor owns. Protected columns are not granted for direct update.
create policy profiles_select_scoped
on public.profiles for select to authenticated
using (
  user_id = (select auth.uid())
  or public.is_admin()
  or (
    public.is_instructor()
    and role = 'learner'::public.user_role
    and exists (
      select 1
      from public.class_memberships cm
      join public.classes c on c.id = cm.class_id
      where cm.learner_id = profiles.user_id
        and c.instructor_id = (select auth.uid())
    )
  )
);

create policy profiles_update_own_safe_columns
on public.profiles for update to authenticated
using (user_id = (select auth.uid()) and public.is_active_user())
with check (user_id = (select auth.uid()));

create policy audit_events_admin_select
on public.audit_events for select to authenticated
using (public.is_admin());

-- LMS-lite class scope.
create policy classes_select_scoped
on public.classes for select to authenticated
using (
  public.is_admin()
  or instructor_id = (select auth.uid())
  or exists (
    select 1
    from public.class_memberships cm
    where cm.class_id = classes.id
      and cm.learner_id = (select auth.uid())
  )
);

create policy classes_update_owned_safe_columns
on public.classes for update to authenticated
using (instructor_id = (select auth.uid()) and public.is_instructor())
with check (instructor_id = (select auth.uid()));

create policy class_memberships_select_scoped
on public.class_memberships for select to authenticated
using (
  public.is_admin()
  or learner_id = (select auth.uid())
  or exists (
    select 1
    from public.classes c
    where c.id = class_memberships.class_id
      and c.instructor_id = (select auth.uid())
  )
);

-- TESDA governance and versioned content.
create policy tesda_sources_select_scoped
on public.tesda_sources for select to authenticated
using (
  public.is_admin()
  or (
    public.is_instructor()
    and status = 'active'::public.tesda_source_status
  )
);

create policy competencies_read_active_users
on public.competencies for select to authenticated
using (public.is_active_user());

create policy coc_modules_read_active_users
on public.coc_modules for select to authenticated
using (
  public.is_active_user()
  and (status = 'published'::public.mission_status or public.is_staff())
);

create policy missions_read_active_users
on public.missions for select to authenticated
using (
  public.is_active_user()
  and (status = 'published'::public.mission_status or public.is_staff())
);

create policy simulation_tasks_staff_only
on public.simulation_tasks for select to authenticated
using (public.is_staff());

create policy assessment_criteria_staff_only
on public.assessment_criteria for select to authenticated
using (public.is_staff());

create policy levels_read_active_users
on public.levels for select to authenticated
using (public.is_active_user());

create policy badges_read_active_users
on public.badges for select to authenticated
using (public.is_active_user());

create policy achievements_read_active_users
on public.achievements for select to authenticated
using (public.is_active_user());

create policy module_versions_select_scoped
on public.module_versions for select to authenticated
using (
  public.is_admin()
  or public.is_instructor()
  or (
    status = 'published'::public.content_version_status
    and (
      exists (
        select 1
        from public.activity_versions av
        join public.assignments a on a.activity_version_id = av.id
        join public.class_memberships cm on cm.class_id = a.class_id
        where av.module_version_id = module_versions.id
          and a.status = 'active'::public.assignment_status
          and cm.learner_id = (select auth.uid())
          and cm.status = 'active'::public.membership_status
      )
      or exists (
        select 1
        from public.coc_bypasses cb
        where cb.module_version_id = module_versions.id
          and cb.learner_id = (select auth.uid())
          and cb.revoked_at is null
      )
    )
  )
);

create policy activity_versions_select_scoped
on public.activity_versions for select to authenticated
using (
  public.is_admin()
  or public.is_instructor()
  or (
    status = 'published'::public.content_version_status
    and exists (
      select 1
      from public.assignments a
      join public.class_memberships cm on cm.class_id = a.class_id
      where a.activity_version_id = activity_versions.id
        and a.status = 'active'::public.assignment_status
        and cm.learner_id = (select auth.uid())
        and cm.status = 'active'::public.membership_status
    )
  )
);

create policy rubric_versions_staff_select
on public.rubric_versions for select to authenticated
using (
  public.is_admin()
  or (
    public.is_instructor()
    and (
      exists (
        select 1
        from public.assignments a
        join public.classes c on c.id = a.class_id
        where a.rubric_version_id = rubric_versions.id
          and c.instructor_id = (select auth.uid())
      )
      or exists (
        select 1
        from public.activity_versions av
        where av.id = rubric_versions.activity_version_id
          and av.created_by = (select auth.uid())
      )
    )
  )
);

create policy rubric_criteria_staff_select
on public.rubric_criteria for select to authenticated
using (
  exists (
    select 1
    from public.rubric_versions rv
    where rv.id = rubric_criteria.rubric_version_id
      and (
        public.is_admin()
        or (
          public.is_instructor()
          and (
            exists (
              select 1
              from public.assignments a
              join public.classes c on c.id = a.class_id
              where a.rubric_version_id = rv.id
                and c.instructor_id = (select auth.uid())
            )
            or exists (
              select 1
              from public.activity_versions av
              where av.id = rv.activity_version_id
                and av.created_by = (select auth.uid())
            )
          )
        )
      )
  )
);

-- Assignments and attempts.
create policy assignments_select_scoped
on public.assignments for select to authenticated
using (
  public.is_admin()
  or exists (
    select 1
    from public.classes c
    where c.id = assignments.class_id
      and c.instructor_id = (select auth.uid())
  )
  or exists (
    select 1
    from public.class_memberships cm
    where cm.class_id = assignments.class_id
      and cm.learner_id = (select auth.uid())
      and cm.status = 'active'::public.membership_status
  )
);

create policy attempts_select_scoped
on public.attempts for select to authenticated
using (
  public.is_admin()
  or learner_id = (select auth.uid())
  or exists (
    select 1
    from public.classes c
    where c.id = attempts.class_id
      and c.instructor_id = (select auth.uid())
  )
);

create policy attempt_actions_select_scoped
on public.attempt_actions for select to authenticated
using (
  exists (
    select 1
    from public.attempts a
    where a.id = attempt_actions.attempt_id
      and (
        public.is_admin()
        or a.learner_id = (select auth.uid())
        or exists (
          select 1 from public.classes c
          where c.id = a.class_id
            and c.instructor_id = (select auth.uid())
        )
      )
  )
);

create policy criterion_results_select_scoped
on public.criterion_results for select to authenticated
using (
  exists (
    select 1
    from public.attempts a
    where a.id = criterion_results.attempt_id
      and (
        public.is_admin()
        or exists (
          select 1 from public.classes c
          where c.id = a.class_id
            and c.instructor_id = (select auth.uid())
        )
        or (
          a.learner_id = (select auth.uid())
          and exists (
            select 1
            from public.result_releases rr
            where rr.attempt_id = a.id and rr.is_current
          )
        )
      )
  )
);

create policy score_revisions_select_scoped
on public.score_revisions for select to authenticated
using (
  exists (
    select 1
    from public.attempts a
    where a.id = score_revisions.attempt_id
      and (
        public.is_admin()
        or exists (
          select 1 from public.classes c
          where c.id = a.class_id
            and c.instructor_id = (select auth.uid())
        )
        or (
          a.learner_id = (select auth.uid())
          and exists (
            select 1
            from public.result_releases rr
            where rr.attempt_id = a.id
              and rr.score_revision_id = score_revisions.id
              and rr.is_current
          )
        )
      )
  )
);

create policy result_releases_select_scoped
on public.result_releases for select to authenticated
using (
  exists (
    select 1
    from public.attempts a
    where a.id = result_releases.attempt_id
      and (
        public.is_admin()
        or exists (
          select 1 from public.classes c
          where c.id = a.class_id
            and c.instructor_id = (select auth.uid())
        )
        or (a.learner_id = (select auth.uid()) and result_releases.is_current)
      )
  )
);

create policy coc_bypasses_select_scoped
on public.coc_bypasses for select to authenticated
using (
  public.is_admin()
  or learner_id = (select auth.uid())
  or exists (
    select 1 from public.classes c
    where c.id = coc_bypasses.class_id
      and c.instructor_id = (select auth.uid())
  )
);

-- Legacy learner history becomes read-only.
create policy mission_results_select_scoped
on public.mission_results for select to authenticated
using (
  user_id = (select auth.uid())
  or public.is_admin()
  or (
    public.is_instructor()
    and exists (
      select 1
      from public.class_memberships cm
      join public.classes c on c.id = cm.class_id
      where cm.learner_id = mission_results.user_id
        and c.instructor_id = (select auth.uid())
    )
  )
);

create policy task_results_select_scoped
on public.task_results for select to authenticated
using (
  user_id = (select auth.uid())
  or public.is_admin()
  or (
    public.is_instructor()
    and exists (
      select 1
      from public.class_memberships cm
      join public.classes c on c.id = cm.class_id
      where cm.learner_id = task_results.user_id
        and c.instructor_id = (select auth.uid())
    )
  )
);

create policy learner_progress_select_scoped
on public.learner_progress for select to authenticated
using (
  user_id = (select auth.uid())
  or public.is_admin()
  or (
    public.is_instructor()
    and exists (
      select 1
      from public.class_memberships cm
      join public.classes c on c.id = cm.class_id
      where cm.learner_id = learner_progress.user_id
        and c.instructor_id = (select auth.uid())
    )
  )
);

create policy user_badges_select_scoped
on public.user_badges for select to authenticated
using (
  user_id = (select auth.uid())
  or public.is_admin()
  or (
    public.is_instructor()
    and exists (
      select 1
      from public.class_memberships cm
      join public.classes c on c.id = cm.class_id
      where cm.learner_id = user_badges.user_id
        and c.instructor_id = (select auth.uid())
    )
  )
);

create policy user_achievements_select_scoped
on public.user_achievements for select to authenticated
using (
  user_id = (select auth.uid())
  or public.is_admin()
  or (
    public.is_instructor()
    and exists (
      select 1
      from public.class_memberships cm
      join public.classes c on c.id = cm.class_id
      where cm.learner_id = user_achievements.user_id
        and c.instructor_id = (select auth.uid())
    )
  )
);

create policy leaderboard_entries_select_scoped
on public.leaderboard_entries for select to authenticated
using (
  user_id = (select auth.uid())
  or public.is_admin()
  or (
    public.is_instructor()
    and exists (
      select 1
      from public.class_memberships cm
      join public.classes c on c.id = cm.class_id
      where cm.learner_id = leaderboard_entries.user_id
        and c.instructor_id = (select auth.uid())
    )
  )
);

create policy notifications_select_own
on public.notifications for select to authenticated
using (user_id = (select auth.uid()));

create policy notifications_update_own
on public.notifications for update to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

create policy user_settings_select_own
on public.user_settings for select to authenticated
using (user_id = (select auth.uid()));

create policy user_settings_insert_own
on public.user_settings for insert to authenticated
with check (user_id = (select auth.uid()));

create policy user_settings_update_own
on public.user_settings for update to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

create policy reports_admin_select
on public.reports for select to authenticated
using (public.is_admin());

create policy activity_logs_admin_select
on public.activity_logs for select to authenticated
using (public.is_admin());

-- Gamification, resources, and settings.
create policy gamification_events_select_scoped
on public.gamification_events for select to authenticated
using (
  learner_id = (select auth.uid())
  or public.is_admin()
  or (
    public.is_instructor()
    and source_type = 'attempt'
    and exists (
      select 1
      from public.attempts a
      join public.classes c on c.id = a.class_id
      where a.id = gamification_events.source_id
        and c.instructor_id = (select auth.uid())
    )
  )
);

create policy learning_resources_select_scoped
on public.learning_resources for select to authenticated
using (
  public.is_admin()
  or exists (
    select 1 from public.classes c
    where c.id = learning_resources.class_id
      and c.instructor_id = (select auth.uid())
  )
  or exists (
    select 1 from public.class_memberships cm
    where cm.class_id = learning_resources.class_id
      and cm.learner_id = (select auth.uid())
      and cm.status = 'active'::public.membership_status
  )
);

create policy system_settings_admin_select
on public.system_settings for select to authenticated
using (public.is_admin());

-- Remove owner-privileged/anonymous view behavior. Views are intentionally not
-- granted to authenticated clients until class-scoped replacements are exposed.
create or replace view public.view_leaderboard_overall
with (security_invoker = true)
as
select
  p.user_id,
  p.full_name,
  p.avatar_url,
  p.current_level,
  p.total_xp,
  p.total_points,
  p.total_badges,
  p.completed_missions,
  rank() over (
    order by p.total_xp desc, p.total_points desc, p.completed_missions desc
  ) as rank
from public.profiles p
where p.role = 'learner'::public.user_role
  and p.status = 'active'::public.account_status;

create or replace view public.view_mission_performance_summary
with (security_invoker = true)
as
select
  m.id as mission_id,
  m.mission_code,
  m.title as mission_title,
  cm.coc_code,
  cm.module_name,
  count(mr.id) as total_attempts,
  count(distinct mr.user_id) as unique_learners,
  coalesce(round(avg(mr.score), 2), 0::numeric) as average_score,
  coalesce(round(avg(mr.time_spent_seconds), 2), 0::numeric) as average_time_seconds,
  count(*) filter (where mr.passed) as passed_count,
  count(*) filter (where not mr.passed) as failed_count
from public.missions m
join public.coc_modules cm on cm.id = m.coc_id
left join public.mission_results mr on mr.mission_id = m.id
group by m.id, m.mission_code, m.title, cm.coc_code, cm.module_name;

revoke all on public.view_leaderboard_overall from anon, authenticated;
revoke all on public.view_mission_performance_summary from anon, authenticated;

-- Legacy/broad helper and policy-value functions remain for reversible cleanup,
-- but are no longer callable through the exposed API.
revoke all on function public.after_mission_result_insert() from public, anon, authenticated;
revoke all on function public.is_own_user(uuid) from public, anon, authenticated;
revoke all on function public.is_instructor_admin() from public, anon, authenticated;
revoke all on function public.rls_auto_enable() from public, anon, authenticated;
revoke all on function public.get_rating(integer) from public, anon, authenticated;
revoke all on function public.set_updated_at() from public, anon, authenticated;

commit;
