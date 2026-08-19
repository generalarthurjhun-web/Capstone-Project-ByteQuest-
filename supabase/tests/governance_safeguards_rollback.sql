-- Admin account lifecycle, removal-readiness, and audit immutability checks.
-- All target state changes and audit fixtures are rolled back.

begin;

create temporary table bytequest_governance_test_context as
select
  (select user_id from public.profiles where role = 'admin' and status = 'active' limit 1) admin_id,
  (select user_id from public.profiles where role = 'learner' and status = 'active' limit 1) learner_id;

grant select on bytequest_governance_test_context to authenticated;

do $$
begin
  if (select admin_id is null or learner_id is null from bytequest_governance_test_context) then
    raise exception 'GOVERNANCE_TEST_FIXTURE_PREREQUISITES_MISSING';
  end if;
end
$$;

select set_config(
  'request.jwt.claim.sub',
  (select admin_id::text from bytequest_governance_test_context),
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select public.admin_set_account_status(
  learner_id,
  'deactivated'::public.account_status,
  'Rollback-only Admin lifecycle and retention verification'
)
from bytequest_governance_test_context;

do $$
declare
  v_readiness jsonb;
begin
  v_readiness := public.admin_account_removal_readiness(
    (select learner_id from bytequest_governance_test_context)
  );
  if v_readiness->>'target_status' <> 'deactivated'
     or jsonb_typeof(v_readiness->'blockers') <> 'array'
     or v_readiness->>'retention_policy' is null then
    raise exception 'ACCOUNT_REMOVAL_READINESS_INVALID';
  end if;
end
$$;

reset role;

do $$
begin
  if not exists (
    select 1
    from public.profiles p
    where p.user_id = (select learner_id from bytequest_governance_test_context)
      and p.status = 'deactivated'::public.account_status
      and p.deactivated_by = (select admin_id from bytequest_governance_test_context)
  ) then
    raise exception 'ADMIN_ACCOUNT_DEACTIVATION_STATE_MISSING';
  end if;

  if not exists (
    select 1
    from public.audit_events ae
    where ae.actor_id = (select admin_id from bytequest_governance_test_context)
      and ae.action = 'account.deactivated'
      and ae.metadata->>'target_user_id' =
        (select learner_id::text from bytequest_governance_test_context)
  ) then
    raise exception 'ADMIN_ACCOUNT_DEACTIVATION_AUDIT_MISSING';
  end if;

  begin
    update public.audit_events
    set reason = 'Forbidden rewrite'
    where actor_id = (select admin_id from bytequest_governance_test_context)
      and action = 'account.deactivated';
    raise exception 'DIRECT_AUDIT_UPDATE_NOT_BLOCKED';
  exception
    when sqlstate '55000' then null;
  end;

  begin
    delete from public.audit_events
    where actor_id = (select admin_id from bytequest_governance_test_context)
      and action = 'account.deactivated';
    raise exception 'DIRECT_AUDIT_DELETE_NOT_BLOCKED';
  exception
    when sqlstate '55000' then null;
  end;
end
$$;

rollback;
