-- Additional scoped class and content lifecycle operations.

begin;

create or replace function public.enroll_learner_by_email(
  p_class_id uuid,
  p_email text
)
returns public.class_memberships
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_learner_id uuid;
begin
  if not public.instructor_owns_class(p_class_id) then
    raise exception 'CLASS_SCOPE_DENIED' using errcode = '42501';
  end if;

  select p.user_id into v_learner_id
  from public.profiles p
  where lower(p.email) = lower(btrim(p_email))
    and p.role = 'learner'::public.user_role
    and p.status = 'active'::public.account_status;

  if not found then
    raise exception 'ACTIVE_LEARNER_NOT_FOUND' using errcode = 'P0002';
  end if;

  return public.enroll_learner(p_class_id, v_learner_id);
end
$$;

create or replace function public.archive_class(
  p_class_id uuid,
  p_reason text
)
returns public.classes
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_class public.classes;
  v_old jsonb;
begin
  if not public.instructor_owns_class(p_class_id) then
    raise exception 'CLASS_SCOPE_DENIED' using errcode = '42501';
  end if;

  if nullif(btrim(p_reason), '') is null then
    raise exception 'ARCHIVE_REASON_REQUIRED' using errcode = '22023';
  end if;

  select c.* into v_class
  from public.classes c
  where c.id = p_class_id
  for update;
  v_old := to_jsonb(v_class);

  update public.classes
  set status = 'archived'::public.class_status,
      archived_at = now(),
      archived_by = (select auth.uid()),
      archive_reason = btrim(p_reason)
  where id = p_class_id
  returning * into v_class;

  perform private.write_audit_event(
    'class.archived',
    'class',
    v_class.id,
    v_old,
    to_jsonb(v_class),
    p_reason
  );

  return v_class;
end
$$;

create or replace function public.close_assignment(
  p_assignment_id uuid,
  p_reason text
)
returns public.assignments
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_assignment public.assignments;
  v_old jsonb;
begin
  if nullif(btrim(p_reason), '') is null then
    raise exception 'CLOSE_REASON_REQUIRED' using errcode = '22023';
  end if;

  select a.* into v_assignment
  from public.assignments a
  where a.id = p_assignment_id
  for update;

  if not found or not public.instructor_owns_class(v_assignment.class_id) then
    raise exception 'CLASS_SCOPE_DENIED' using errcode = '42501';
  end if;

  v_old := to_jsonb(v_assignment);

  update public.assignments
  set status = 'closed'::public.assignment_status,
      closed_at = now(),
      close_reason = btrim(p_reason)
  where id = p_assignment_id
  returning * into v_assignment;

  perform private.write_audit_event(
    'assignment.closed',
    'assignment',
    v_assignment.id,
    v_old,
    to_jsonb(v_assignment),
    p_reason
  );

  return v_assignment;
end
$$;

create or replace function public.publish_module_version(
  p_module_version_id uuid,
  p_reason text
)
returns public.module_versions
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_version public.module_versions;
  v_old jsonb;
begin
  select mv.* into v_version
  from public.module_versions mv
  where mv.id = p_module_version_id
  for update;

  if not found then
    raise exception 'MODULE_VERSION_NOT_FOUND' using errcode = 'P0002';
  end if;

  if not public.is_admin()
     and not (public.is_instructor() and v_version.created_by = (select auth.uid())) then
    raise exception 'CONTENT_SCOPE_DENIED' using errcode = '42501';
  end if;

  if v_version.status <> 'draft'::public.content_version_status then
    raise exception 'DRAFT_MODULE_VERSION_REQUIRED' using errcode = '22023';
  end if;

  if not exists (
    select 1 from public.tesda_sources ts
    where ts.id = v_version.tesda_source_id
      and ts.status = 'active'::public.tesda_source_status
  ) then
    raise exception 'ACTIVE_TESDA_SOURCE_REQUIRED' using errcode = '22023';
  end if;

  if v_version.source_trace = '{}'::jsonb then
    raise exception 'SOURCE_TRACE_REQUIRED' using errcode = '22023';
  end if;

  v_old := to_jsonb(v_version);

  update public.module_versions
  set status = 'published'::public.content_version_status,
      published_by = (select auth.uid()),
      published_at = now()
  where id = p_module_version_id
  returning * into v_version;

  perform private.write_audit_event(
    'module_version.published',
    'module_version',
    v_version.id,
    v_old,
    to_jsonb(v_version),
    p_reason
  );

  return v_version;
end
$$;

create or replace function public.publish_activity_version(
  p_activity_version_id uuid,
  p_reason text
)
returns public.activity_versions
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_version public.activity_versions;
  v_old jsonb;
begin
  select av.* into v_version
  from public.activity_versions av
  where av.id = p_activity_version_id
  for update;

  if not found then
    raise exception 'ACTIVITY_VERSION_NOT_FOUND' using errcode = 'P0002';
  end if;

  if not public.is_admin()
     and not (public.is_instructor() and v_version.created_by = (select auth.uid())) then
    raise exception 'CONTENT_SCOPE_DENIED' using errcode = '42501';
  end if;

  if v_version.status <> 'draft'::public.content_version_status then
    raise exception 'DRAFT_ACTIVITY_VERSION_REQUIRED' using errcode = '22023';
  end if;

  if not exists (
    select 1
    from public.module_versions mv
    join public.tesda_sources ts on ts.id = mv.tesda_source_id
    where mv.id = v_version.module_version_id
      and mv.status = 'published'::public.content_version_status
      and ts.status = 'active'::public.tesda_source_status
  ) then
    raise exception 'ACTIVE_PUBLISHED_MODULE_REQUIRED' using errcode = '22023';
  end if;

  v_old := to_jsonb(v_version);

  update public.activity_versions
  set status = 'published'::public.content_version_status,
      published_by = (select auth.uid()),
      published_at = now()
  where id = p_activity_version_id
  returning * into v_version;

  perform private.write_audit_event(
    'activity_version.published',
    'activity_version',
    v_version.id,
    v_old,
    to_jsonb(v_version),
    p_reason
  );

  return v_version;
end
$$;

revoke all on function public.enroll_learner_by_email(uuid, text) from public, anon;
revoke all on function public.archive_class(uuid, text) from public, anon;
revoke all on function public.close_assignment(uuid, text) from public, anon;
revoke all on function public.publish_module_version(uuid, text) from public, anon;
revoke all on function public.publish_activity_version(uuid, text) from public, anon;

grant execute on function public.enroll_learner_by_email(uuid, text) to authenticated;
grant execute on function public.archive_class(uuid, text) to authenticated;
grant execute on function public.close_assignment(uuid, text) to authenticated;
grant execute on function public.publish_module_version(uuid, text) to authenticated;
grant execute on function public.publish_activity_version(uuid, text) to authenticated;

commit;
