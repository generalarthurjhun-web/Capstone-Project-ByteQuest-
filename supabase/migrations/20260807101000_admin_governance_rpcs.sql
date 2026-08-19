-- Admin-only account, TESDA-source registration, and global-setting actions.

begin;

create or replace function public.admin_change_user_role(
  p_user_id uuid,
  p_new_role public.user_role,
  p_reason text
)
returns public.profiles
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_profile public.profiles;
  v_old jsonb;
begin
  if not public.is_admin() then
    raise exception 'ADMIN_REQUIRED' using errcode = '42501';
  end if;

  if p_new_role = 'instructor_admin'::public.user_role then
    raise exception 'MERGED_STAFF_ROLE_FORBIDDEN' using errcode = '22023';
  end if;

  if nullif(btrim(p_reason), '') is null then
    raise exception 'ROLE_CHANGE_REASON_REQUIRED' using errcode = '22023';
  end if;

  if p_user_id = (select auth.uid()) and p_new_role <> 'admin'::public.user_role then
    raise exception 'ADMIN_CANNOT_SELF_DEMOTE' using errcode = '42501';
  end if;

  select p.*
  into v_profile
  from public.profiles p
  where p.user_id = p_user_id
  for update;

  if not found then
    raise exception 'PROFILE_NOT_FOUND' using errcode = 'P0002';
  end if;

  v_old := to_jsonb(v_profile);

  update public.profiles
  set role = p_new_role
  where user_id = p_user_id
  returning * into v_profile;

  perform private.write_audit_event(
    'account.role_changed',
    'profile',
    v_profile.id,
    v_old,
    to_jsonb(v_profile),
    p_reason,
    jsonb_build_object('target_user_id', p_user_id)
  );

  return v_profile;
end
$$;

create or replace function public.admin_set_account_status(
  p_user_id uuid,
  p_status public.account_status,
  p_reason text default null
)
returns public.profiles
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_profile public.profiles;
  v_old jsonb;
  v_action text;
begin
  if not public.is_admin() then
    raise exception 'ADMIN_REQUIRED' using errcode = '42501';
  end if;

  if p_status = 'suspended'::public.account_status then
    raise exception 'SUSPENDED_IS_LEGACY_ONLY' using errcode = '22023';
  end if;

  if p_user_id = (select auth.uid()) and p_status <> 'active'::public.account_status then
    raise exception 'ADMIN_CANNOT_SELF_DEACTIVATE' using errcode = '42501';
  end if;

  if p_status in (
      'inactive'::public.account_status,
      'deactivated'::public.account_status
    ) and nullif(btrim(p_reason), '') is null then
    raise exception 'ACCOUNT_STATUS_REASON_REQUIRED' using errcode = '22023';
  end if;

  select p.*
  into v_profile
  from public.profiles p
  where p.user_id = p_user_id
  for update;

  if not found then
    raise exception 'PROFILE_NOT_FOUND' using errcode = 'P0002';
  end if;

  v_old := to_jsonb(v_profile);

  update public.profiles
  set status = p_status,
      deactivated_at = case
        when p_status = 'deactivated'::public.account_status then now()
        else null
      end,
      deactivation_reason = case
        when p_status = 'deactivated'::public.account_status then btrim(p_reason)
        else null
      end,
      deactivated_by = case
        when p_status = 'deactivated'::public.account_status then (select auth.uid())
        else null
      end
  where user_id = p_user_id
  returning * into v_profile;

  v_action := case
    when p_status = 'active'::public.account_status then 'account.restored'
    when p_status = 'deactivated'::public.account_status then 'account.deactivated'
    else 'account.status_changed'
  end;

  perform private.write_audit_event(
    v_action,
    'profile',
    v_profile.id,
    v_old,
    to_jsonb(v_profile),
    p_reason,
    jsonb_build_object('target_user_id', p_user_id)
  );

  return v_profile;
end
$$;

create or replace function public.register_tesda_source(
  p_qualification_code text,
  p_title text,
  p_edition text,
  p_effective_date date,
  p_publication_date date,
  p_source_reference text,
  p_document_storage_path text default null,
  p_validation_notes text default null
)
returns public.tesda_sources
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_source public.tesda_sources;
begin
  if not public.is_admin() then
    raise exception 'ADMIN_REQUIRED' using errcode = '42501';
  end if;

  insert into public.tesda_sources (
    qualification_code,
    title,
    edition,
    effective_date,
    publication_date,
    source_reference,
    document_storage_path,
    status,
    validation_notes,
    created_by
  )
  values (
    btrim(p_qualification_code),
    btrim(p_title),
    nullif(btrim(p_edition), ''),
    p_effective_date,
    p_publication_date,
    btrim(p_source_reference),
    nullif(btrim(p_document_storage_path), ''),
    'pending_tesda_validation'::public.tesda_source_status,
    nullif(btrim(p_validation_notes), ''),
    (select auth.uid())
  )
  returning * into v_source;

  perform private.write_audit_event(
    'tesda_source.registered',
    'tesda_source',
    v_source.id,
    null,
    to_jsonb(v_source),
    p_validation_notes
  );

  return v_source;
end
$$;

create or replace function public.admin_update_system_setting(
  p_setting_key text,
  p_setting_value jsonb,
  p_description text,
  p_reason text
)
returns public.system_settings
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_old jsonb;
  v_setting public.system_settings;
begin
  if not public.is_admin() then
    raise exception 'ADMIN_REQUIRED' using errcode = '42501';
  end if;

  if nullif(btrim(p_reason), '') is null then
    raise exception 'SETTING_CHANGE_REASON_REQUIRED' using errcode = '22023';
  end if;

  select to_jsonb(ss) into v_old
  from public.system_settings ss
  where ss.setting_key = btrim(p_setting_key)
  for update;

  insert into public.system_settings (
    setting_key,
    setting_value,
    description,
    updated_by,
    updated_at
  )
  values (
    btrim(p_setting_key),
    p_setting_value,
    nullif(btrim(p_description), ''),
    (select auth.uid()),
    now()
  )
  on conflict (setting_key) do update
  set setting_value = excluded.setting_value,
      description = excluded.description,
      updated_by = excluded.updated_by,
      updated_at = excluded.updated_at
  returning * into v_setting;

  perform private.write_audit_event(
    'system_setting.updated',
    'system_setting',
    null,
    v_old,
    to_jsonb(v_setting),
    p_reason,
    jsonb_build_object('setting_key', v_setting.setting_key)
  );

  return v_setting;
end
$$;

revoke all on function public.admin_change_user_role(uuid, public.user_role, text) from public, anon;
revoke all on function public.admin_set_account_status(uuid, public.account_status, text) from public, anon;
revoke all on function public.register_tesda_source(text, text, text, date, date, text, text, text) from public, anon;
revoke all on function public.admin_update_system_setting(text, jsonb, text, text) from public, anon;

grant execute on function public.admin_change_user_role(uuid, public.user_role, text) to authenticated;
grant execute on function public.admin_set_account_status(uuid, public.account_status, text) to authenticated;
grant execute on function public.register_tesda_source(text, text, text, date, date, text, text, text) to authenticated;
grant execute on function public.admin_update_system_setting(text, jsonb, text, text) to authenticated;

commit;
