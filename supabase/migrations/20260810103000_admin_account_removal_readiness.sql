-- Read-only safeguard for Admin permanent account removal. The Auth identity is
-- removed only by the trusted server route after this function proves that no
-- retention-protected foreign-key dependency would be orphaned or cascaded.

begin;

create or replace function public.admin_account_removal_readiness(
  p_user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_target public.profiles;
  v_fk record;
  v_count bigint;
  v_blockers jsonb := '[]'::jsonb;
begin
  if not public.is_admin() then
    raise exception 'ADMIN_REQUIRED' using errcode = '42501';
  end if;

  if p_user_id = (select auth.uid()) then
    raise exception 'ADMIN_CANNOT_REMOVE_SELF' using errcode = '42501';
  end if;

  select p.* into v_target
  from public.profiles p
  where p.user_id = p_user_id;

  if not found then
    raise exception 'TARGET_PROFILE_NOT_FOUND' using errcode = 'P0002';
  end if;

  if v_target.status <> 'deactivated'::public.account_status then
    raise exception 'ACCOUNT_MUST_BE_DEACTIVATED_FIRST' using errcode = '22023';
  end if;

  for v_fk in
    select
      source_namespace.nspname as schema_name,
      source_table.relname as table_name,
      source_column.attname as column_name,
      constraint_row.conname as constraint_name
    from pg_catalog.pg_constraint constraint_row
    join pg_catalog.pg_class source_table
      on source_table.oid = constraint_row.conrelid
    join pg_catalog.pg_namespace source_namespace
      on source_namespace.oid = source_table.relnamespace
    join lateral unnest(constraint_row.conkey) source_key(attnum) on true
    join pg_catalog.pg_attribute source_column
      on source_column.attrelid = source_table.oid
     and source_column.attnum = source_key.attnum
    where constraint_row.contype = 'f'
      and constraint_row.confrelid = 'auth.users'::regclass
      and constraint_row.confdeltype in ('a', 'r')
      and cardinality(constraint_row.conkey) = 1
    order by source_namespace.nspname, source_table.relname, source_column.attname
  loop
    execute format(
      'select count(*) from %I.%I where %I = $1',
      v_fk.schema_name,
      v_fk.table_name,
      v_fk.column_name
    )
    into v_count
    using p_user_id;

    if v_count > 0 then
      v_blockers := v_blockers || jsonb_build_array(jsonb_build_object(
        'schema', v_fk.schema_name,
        'table', v_fk.table_name,
        'column', v_fk.column_name,
        'constraint', v_fk.constraint_name,
        'rows', v_count
      ));
    end if;
  end loop;

  return jsonb_build_object(
    'safe_to_remove', jsonb_array_length(v_blockers) = 0,
    'target_user_id', p_user_id,
    'target_role', v_target.role,
    'target_status', v_target.status,
    'blockers', v_blockers,
    'retention_policy', case
      when jsonb_array_length(v_blockers) = 0 then 'NO_RESTRICT_DEPENDENCIES'
      else 'PRESERVE_HISTORY_AND_KEEP_DEACTIVATED'
    end
  );
end
$$;

revoke all on function public.admin_account_removal_readiness(uuid) from public, anon;
grant execute on function public.admin_account_removal_readiness(uuid) to authenticated;

comment on function public.admin_account_removal_readiness(uuid) is
  'Admin-only read gate. Returns every restrictive Auth FK dependency; it never deletes an account or academic history.';

commit;
