-- Private Supabase Storage workflow for class-scoped instructional resources.
-- Additive only: no legacy object or historical row is removed.

begin;

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'learning-resources',
  'learning-resources',
  false,
  52428800,
  array[
    'application/pdf',
    'image/jpeg',
    'image/png',
    'image/webp',
    'video/mp4',
    'video/webm'
  ]::text[]
)
on conflict (id) do update
set name = excluded.name,
    public = false,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

create or replace function public.create_learning_resource(
  p_resource_id uuid,
  p_class_id uuid,
  p_title text,
  p_description text,
  p_storage_path text,
  p_mime_type text,
  p_size_bytes bigint
)
returns public.learning_resources
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_resource public.learning_resources;
  v_expected_prefix text;
begin
  if not public.is_instructor() then
    raise exception 'INSTRUCTOR_REQUIRED' using errcode = '42501';
  end if;

  if p_resource_id is null or p_class_id is null then
    raise exception 'RESOURCE_AND_CLASS_REQUIRED' using errcode = '22023';
  end if;

  if length(btrim(coalesce(p_title, ''))) not between 2 and 300 then
    raise exception 'INVALID_RESOURCE_TITLE' using errcode = '22023';
  end if;

  if length(coalesce(p_description, '')) > 2000 then
    raise exception 'RESOURCE_DESCRIPTION_TOO_LONG' using errcode = '22023';
  end if;

  if p_mime_type is null or p_mime_type <> all (array[
    'application/pdf',
    'image/jpeg',
    'image/png',
    'image/webp',
    'video/mp4',
    'video/webm'
  ]::text[]) then
    raise exception 'RESOURCE_TYPE_NOT_ALLOWED' using errcode = '22023';
  end if;

  if p_size_bytes is null or p_size_bytes < 1 or p_size_bytes > 52428800 then
    raise exception 'RESOURCE_SIZE_NOT_ALLOWED' using errcode = '22023';
  end if;

  if not exists (
    select 1
    from public.classes c
    where c.id = p_class_id
      and c.instructor_id = (select auth.uid())
      and c.status = 'active'::public.class_status
  ) then
    raise exception 'CLASS_SCOPE_DENIED' using errcode = '42501';
  end if;

  v_expected_prefix := format('classes/%s/resources/%s/', p_class_id, p_resource_id);
  if p_storage_path is null
     or p_storage_path not like v_expected_prefix || '%'
     or position('..' in p_storage_path) > 0
     or position(chr(92) in p_storage_path) > 0 then
    raise exception 'INVALID_RESOURCE_STORAGE_PATH' using errcode = '22023';
  end if;

  insert into public.learning_resources (
    id,
    class_id,
    title,
    description,
    storage_bucket,
    storage_path,
    mime_type,
    size_bytes,
    status,
    uploaded_by
  )
  values (
    p_resource_id,
    p_class_id,
    btrim(p_title),
    nullif(btrim(coalesce(p_description, '')), ''),
    'learning-resources',
    p_storage_path,
    p_mime_type,
    p_size_bytes,
    'active'::public.resource_status,
    (select auth.uid())
  )
  returning * into v_resource;

  perform private.write_audit_event(
    'learning_resource.created',
    'learning_resource',
    v_resource.id,
    null,
    to_jsonb(v_resource),
    null,
    jsonb_build_object(
      'class_id', v_resource.class_id,
      'mime_type', v_resource.mime_type,
      'size_bytes', v_resource.size_bytes
    )
  );

  return v_resource;
end
$$;

create or replace function public.delete_learning_resource(
  p_resource_id uuid,
  p_reason text
)
returns public.learning_resources
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_resource public.learning_resources;
  v_old jsonb;
begin
  if not (public.is_instructor() or public.is_admin()) then
    raise exception 'STAFF_REQUIRED' using errcode = '42501';
  end if;

  if length(btrim(coalesce(p_reason, ''))) < 5 then
    raise exception 'DELETION_REASON_REQUIRED' using errcode = '22023';
  end if;

  select lr.*
  into v_resource
  from public.learning_resources lr
  where lr.id = p_resource_id
  for update;

  if v_resource.id is null then
    raise exception 'RESOURCE_NOT_FOUND' using errcode = 'P0002';
  end if;

  if v_resource.status = 'deleted'::public.resource_status then
    return v_resource;
  end if;

  if public.is_instructor() and not exists (
    select 1
    from public.classes c
    where c.id = v_resource.class_id
      and c.instructor_id = (select auth.uid())
  ) then
    raise exception 'CLASS_SCOPE_DENIED' using errcode = '42501';
  end if;

  v_old := to_jsonb(v_resource);

  update public.learning_resources
  set status = 'deleted'::public.resource_status,
      deleted_by = (select auth.uid()),
      deleted_at = now(),
      deletion_reason = btrim(p_reason)
  where id = v_resource.id
  returning * into v_resource;

  perform private.write_audit_event(
    'learning_resource.deleted',
    'learning_resource',
    v_resource.id,
    v_old,
    to_jsonb(v_resource),
    p_reason,
    jsonb_build_object(
      'class_id', v_resource.class_id,
      'storage_bucket', v_resource.storage_bucket,
      'storage_path', v_resource.storage_path
    )
  );

  return v_resource;
end
$$;

drop policy if exists learning_resource_objects_select_scoped on storage.objects;
create policy learning_resource_objects_select_scoped
on storage.objects for select to authenticated
using (
  bucket_id = 'learning-resources'
  and exists (
    select 1
    from public.learning_resources lr
    where lr.storage_bucket = storage.objects.bucket_id
      and lr.storage_path = storage.objects.name
      and lr.status = 'active'::public.resource_status
      and (
        public.is_admin()
        or exists (
          select 1
          from public.classes c
          where c.id = lr.class_id
            and c.instructor_id = (select auth.uid())
        )
        or exists (
          select 1
          from public.class_memberships cm
          where cm.class_id = lr.class_id
            and cm.learner_id = (select auth.uid())
            and cm.status = 'active'::public.membership_status
        )
      )
  )
);

revoke all on function public.create_learning_resource(uuid, uuid, text, text, text, text, bigint)
  from public, anon;
revoke all on function public.delete_learning_resource(uuid, text)
  from public, anon;

grant execute on function public.create_learning_resource(uuid, uuid, text, text, text, text, bigint)
  to authenticated;
grant execute on function public.delete_learning_resource(uuid, text)
  to authenticated;

commit;
