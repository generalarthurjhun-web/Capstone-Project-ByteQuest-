-- Break cross-table RLS recursion with a non-exposed relationship predicate.
-- The function returns only a boolean and is not in the PostgREST public schema.

begin;

create or replace function private.current_instructor_teaches_learner(
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
    from public.class_memberships cm
    join public.classes c on c.id = cm.class_id
    join public.profiles instructor_profile
      on instructor_profile.user_id = c.instructor_id
    where cm.learner_id = p_learner_id
      and c.instructor_id = auth.uid()
      and cm.status = 'active'::public.membership_status
      and c.status = 'active'::public.class_status
      and instructor_profile.role = 'instructor'::public.user_role
      and instructor_profile.status = 'active'::public.account_status
  );
$$;

revoke all on function private.current_instructor_teaches_learner(uuid)
  from public, anon;
grant usage on schema private to authenticated, service_role;
grant execute on function private.current_instructor_teaches_learner(uuid)
  to authenticated, service_role;

drop policy if exists profiles_select_scoped on public.profiles;
create policy profiles_select_scoped
on public.profiles for select to authenticated
using (
  user_id = (select auth.uid())
  or public.is_admin()
  or (
    public.is_instructor()
    and role = 'learner'::public.user_role
    and private.current_instructor_teaches_learner(user_id)
  )
);

drop policy if exists classes_select_scoped on public.classes;
create policy classes_select_scoped
on public.classes for select to authenticated
using (
  public.is_admin()
  or instructor_id = (select auth.uid())
  or public.learner_is_enrolled(id, (select auth.uid()))
);

drop policy if exists class_memberships_select_scoped
  on public.class_memberships;
create policy class_memberships_select_scoped
on public.class_memberships for select to authenticated
using (
  public.is_admin()
  or learner_id = (select auth.uid())
  or public.instructor_owns_class(class_id)
);

commit;
