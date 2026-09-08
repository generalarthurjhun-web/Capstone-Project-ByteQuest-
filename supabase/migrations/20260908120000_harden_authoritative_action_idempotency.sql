-- Recover safely from an append response lost after commit. Client action IDs
-- are transport idempotency keys, not scoring inputs. This is a forward-only
-- upgrade and does not replay the fresh-database foundation migration.

begin;

do $$
begin
  if exists (
    select 1
    from public.attempt_actions aa
    where nullif(btrim(aa.value ->> 'client_action_id'), '') is not null
    group by aa.attempt_id, aa.value ->> 'client_action_id'
    having count(*) > 1
  ) then
    raise exception 'DUPLICATE_CLIENT_ACTION_IDS_REQUIRE_REVIEW'
      using errcode = '23505';
  end if;
end
$$;

create unique index if not exists attempt_actions_client_action_id_idx
  on public.attempt_actions (
    attempt_id,
    (value ->> 'client_action_id')
  )
  where nullif(btrim(value ->> 'client_action_id'), '') is not null;

create or replace function public.append_attempt_action(
  p_attempt_id uuid,
  p_sequence_number integer,
  p_action_type text,
  p_target text,
  p_value jsonb,
  p_client_occurred_at timestamptz
)
returns public.attempt_actions
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_attempt public.attempts;
  v_action public.attempt_actions;
  v_client_action_id text;
begin
  select a.* into v_attempt
  from public.attempts a
  where a.id = p_attempt_id
  for update;

  if not found then
    raise exception 'ATTEMPT_NOT_FOUND' using errcode = 'P0002';
  end if;

  perform private.assert_attempt_write_access(v_attempt);

  if v_attempt.status <> 'in_progress'::public.attempt_status then
    raise exception 'ATTEMPT_NOT_IN_PROGRESS' using errcode = '22023';
  end if;

  if p_sequence_number <= 0 then
    raise exception 'INVALID_SEQUENCE_NUMBER' using errcode = '22023';
  end if;

  if p_client_occurred_at > now() + interval '5 minutes' then
    raise exception 'ACTION_TIME_IN_FUTURE' using errcode = '22023';
  end if;

  v_client_action_id := nullif(
    btrim(coalesce(p_value, '{}'::jsonb) ->> 'client_action_id'),
    ''
  );

  if v_client_action_id is not null then
    select aa.* into v_action
    from public.attempt_actions aa
    where aa.attempt_id = p_attempt_id
      and aa.value ->> 'client_action_id' = v_client_action_id;

    if found then
      if v_action.action_type = btrim(p_action_type)
         and v_action.target is not distinct from nullif(btrim(p_target), '')
         and v_action.value = coalesce(p_value, '{}'::jsonb)
         and v_action.client_occurred_at = p_client_occurred_at then
        return v_action;
      end if;
      raise exception 'ACTION_ID_CONFLICT' using errcode = '23505';
    end if;
  end if;

  select aa.* into v_action
  from public.attempt_actions aa
  where aa.attempt_id = p_attempt_id
    and aa.sequence_number = p_sequence_number;

  if found then
    if v_action.action_type = btrim(p_action_type)
       and v_action.target is not distinct from nullif(btrim(p_target), '')
       and v_action.value = coalesce(p_value, '{}'::jsonb)
       and v_action.client_occurred_at = p_client_occurred_at then
      return v_action;
    end if;
    raise exception 'ACTION_SEQUENCE_CONFLICT' using errcode = '23505';
  end if;

  insert into public.attempt_actions (
    attempt_id,
    sequence_number,
    action_type,
    target,
    value,
    client_occurred_at
  )
  values (
    p_attempt_id,
    p_sequence_number,
    btrim(p_action_type),
    nullif(btrim(p_target), ''),
    coalesce(p_value, '{}'::jsonb),
    p_client_occurred_at
  )
  returning * into v_action;

  return v_action;
end
$$;

revoke all on function public.append_attempt_action(
  uuid, integer, text, text, jsonb, timestamptz
) from public, anon;
grant execute on function public.append_attempt_action(
  uuid, integer, text, text, jsonb, timestamptz
) to authenticated;

comment on function public.append_attempt_action(
  uuid, integer, text, text, jsonb, timestamptz
) is
  'Appends learner-owned evidence exactly once by attempt sequence and optional client_action_id. It accepts no score, outcome, reward, or competency decision.';

commit;
