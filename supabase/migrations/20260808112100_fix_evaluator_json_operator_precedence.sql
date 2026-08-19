-- PostgreSQL can bind JSON extraction after comparison operators in these
-- expressions. Parenthesize every extracted rule value explicitly.

begin;

create or replace function private.evaluate_criterion_evidence(
  p_attempt_id uuid,
  p_rule jsonb
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_operator text := p_rule->>'operator';
  v_count integer;
  v_actions jsonb;
  v_observed jsonb;
begin
  if not private.valid_evidence_rule(p_rule) then
    raise exception 'UNSUPPORTED_EVIDENCE_RULE' using errcode = '22023';
  end if;

  if v_operator = 'action_exists' then
    select count(*)::integer,
           coalesce(
             jsonb_agg(
               jsonb_build_object(
                 'sequence_number', aa.sequence_number,
                 'action_type', aa.action_type,
                 'target', aa.target,
                 'value', aa.value,
                 'client_occurred_at', aa.client_occurred_at
               ) order by aa.sequence_number
             ),
             '[]'::jsonb
           )
    into v_count, v_actions
    from public.attempt_actions aa
    where aa.attempt_id = p_attempt_id
      and aa.action_type = (p_rule->>'action_type')
      and (not (p_rule ? 'target') or aa.target = (p_rule->>'target'))
      and (not (p_rule ? 'value_contains') or aa.value @> (p_rule->'value_contains'));

    return jsonb_build_object(
      'observation', case
        when v_count >= (p_rule->>'minimum_count')::integer then 'satisfied'
        else 'not_satisfied'
      end,
      'observed_evidence', jsonb_build_object(
        'matching_count', v_count,
        'required_count', (p_rule->>'minimum_count')::integer,
        'matching_actions', v_actions
      )
    );
  end if;

  if v_operator = 'exact_target_sequence' then
    select coalesce(jsonb_agg(to_jsonb(aa.target) order by aa.sequence_number), '[]'::jsonb)
    into v_observed
    from public.attempt_actions aa
    where aa.attempt_id = p_attempt_id
      and aa.action_type = (p_rule->>'action_type');

    return jsonb_build_object(
      'observation', case
        when v_observed = (p_rule->'expected_targets') then 'satisfied'
        else 'not_satisfied'
      end,
      'observed_evidence', jsonb_build_object(
        'observed_targets', v_observed,
        'expected_targets', p_rule->'expected_targets'
      )
    );
  end if;

  select aa.value->(p_rule->>'value_key')
  into v_observed
  from public.attempt_actions aa
  where aa.attempt_id = p_attempt_id
    and aa.action_type = (p_rule->>'action_type')
  order by aa.sequence_number desc
  limit 1;

  v_count := case when found then 1 else 0 end;

  return jsonb_build_object(
    'observation', case
      when v_count = 1 and v_observed is not distinct from (p_rule->'expected') then 'satisfied'
      else 'not_satisfied'
    end,
    'observed_evidence', jsonb_build_object(
      'observed_value', v_observed,
      'expected_value', p_rule->'expected',
      'value_key', p_rule->>'value_key'
    )
  );
end
$$;

revoke all on function private.evaluate_criterion_evidence(uuid, jsonb)
from public, anon, authenticated;

commit;
