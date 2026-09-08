-- Destructive-safe verification for Storage metadata scope and Instructor
-- learner-account deactivation. All fixture changes are rolled back.

\echo 1..1
begin;

create temporary table bytequest_storage_test_context (
  instructor_id uuid,
  secondary_instructor_id uuid,
  learner_id uuid,
  other_learner_id uuid,
  class_id uuid,
  secondary_class_id uuid,
  membership_id uuid,
  resource_id uuid not null default gen_random_uuid()
) on commit drop;

insert into bytequest_storage_test_context (
  instructor_id,
  secondary_instructor_id,
  learner_id,
  other_learner_id
)
select
  (select user_id from public.profiles where role = 'instructor' and status = 'active' limit 1),
  (select user_id from public.profiles where role = 'learner' and status = 'active' order by user_id offset 1 limit 1),
  (select user_id from public.profiles where role = 'learner' and status = 'active' order by user_id limit 1),
  (select user_id from public.profiles where role = 'learner' and status = 'active' order by user_id offset 2 limit 1);

do $$
declare
  v_context bytequest_storage_test_context;
begin
  select * into v_context from bytequest_storage_test_context;
  if v_context.instructor_id is null
     or v_context.secondary_instructor_id is null
     or v_context.learner_id is null
     or v_context.other_learner_id is null then
    raise exception 'STORAGE_TEST_FIXTURE_PREREQUISITES_MISSING';
  end if;
end
$$;

update public.profiles
set role = 'instructor'::public.user_role
where user_id = (select secondary_instructor_id from bytequest_storage_test_context);

-- Bucket configuration is governance metadata and is intentionally not exposed
-- through Storage RLS to ordinary authenticated callers. Verify it while the
-- rollback harness is still running as the migration owner.
do $$
begin
  if not exists (
    select 1
    from storage.buckets b
    where b.id = 'learning-resources'
      and b.public = false
  ) then
    raise exception 'RESOURCE_BUCKET_IS_NOT_PRIVATE';
  end if;
end
$$;

with inserted as (
  insert into public.classes (title, class_code, instructor_id, created_by)
  select
    'Rollback secondary resource class',
    'RS-' || left(gen_random_uuid()::text, 8),
    secondary_instructor_id,
    secondary_instructor_id
  from bytequest_storage_test_context
  returning id
)
update bytequest_storage_test_context
set secondary_class_id = inserted.id
from inserted;

grant select, update on bytequest_storage_test_context to authenticated;

select set_config(
  'request.jwt.claim.sub',
  (select instructor_id::text from bytequest_storage_test_context),
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

update bytequest_storage_test_context
set class_id = (
  select id from public.create_class(
    'Rollback learning-resource class',
    'RR-' || left(gen_random_uuid()::text, 8)
  )
);

update bytequest_storage_test_context context
set membership_id = (
  select id from public.enroll_learner(context.class_id, context.learner_id)
);

select public.create_learning_resource(
  context.resource_id,
  context.class_id,
  'Rollback-only PDF resource',
  'Never committed',
  format('classes/%s/resources/%s/resource.pdf', context.class_id, context.resource_id),
  'application/pdf',
  1024
)
from bytequest_storage_test_context context;

do $$
declare
  v_context bytequest_storage_test_context;
begin
  select * into v_context from bytequest_storage_test_context;

  if (select count(*) from public.learning_resources where id = v_context.resource_id) <> 1 then
    raise exception 'RESOURCE_CREATE_FAILED';
  end if;

  begin
    perform public.create_learning_resource(
      gen_random_uuid(),
      v_context.class_id,
      'Rejected executable',
      null,
      format('classes/%s/resources/%s/payload.exe', v_context.class_id, gen_random_uuid()),
      'application/x-msdownload',
      1024
    );
    raise exception 'EXECUTABLE_RESOURCE_WAS_NOT_REJECTED';
  exception
    when invalid_parameter_value then null;
  end;
end
$$;

reset role;
select set_config(
  'request.jwt.claim.sub',
  (select secondary_instructor_id::text from bytequest_storage_test_context),
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

do $$
declare
  v_context bytequest_storage_test_context;
begin
  select * into v_context from bytequest_storage_test_context;
  if (select count(*) from public.learning_resources where id = v_context.resource_id) <> 0 then
    raise exception 'CROSS_INSTRUCTOR_RESOURCE_READ_NOT_BLOCKED';
  end if;
  begin
    perform public.delete_learning_resource(v_context.resource_id, 'Out-of-scope deletion test');
    raise exception 'CROSS_INSTRUCTOR_RESOURCE_DELETE_NOT_BLOCKED';
  exception
    when insufficient_privilege then null;
  end;
end
$$;

reset role;
select set_config(
  'request.jwt.claim.sub',
  (select learner_id::text from bytequest_storage_test_context),
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

do $$
declare
  v_context bytequest_storage_test_context;
begin
  select * into v_context from bytequest_storage_test_context;
  if (select count(*) from public.learning_resources where id = v_context.resource_id) <> 1 then
    raise exception 'ENROLLED_LEARNER_RESOURCE_READ_FAILED';
  end if;
  begin
    perform public.delete_learning_resource(v_context.resource_id, 'Learner deletion test');
    raise exception 'LEARNER_RESOURCE_DELETE_NOT_BLOCKED';
  exception
    when insufficient_privilege then null;
  end;
end
$$;

reset role;
select set_config(
  'request.jwt.claim.sub',
  (select instructor_id::text from bytequest_storage_test_context),
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select public.instructor_deactivate_learner_account(
  learner_id,
  'Rollback-only Instructor account deactivation'
)
from bytequest_storage_test_context;

-- Verify the persisted effects as the rollback harness owner. Once the target
-- account and membership are deactivated, ordinary Instructor RLS correctly no
-- longer exposes those rows through active-scope policies.
reset role;

do $$
declare
  v_context bytequest_storage_test_context;
begin
  select * into v_context from bytequest_storage_test_context;
  if not exists (
    select 1 from public.profiles
    where user_id = v_context.learner_id
      and status = 'deactivated'::public.account_status
      and deactivated_by = v_context.instructor_id
  ) then
    raise exception 'INSTRUCTOR_ACCOUNT_DEACTIVATION_FAILED';
  end if;
  if not exists (
    select 1 from public.class_memberships
    where id = v_context.membership_id
      and status = 'deactivated'::public.membership_status
  ) then
    raise exception 'ACCOUNT_DEACTIVATION_DID_NOT_CLOSE_MEMBERSHIP';
  end if;
  if not exists (
    select 1 from public.audit_events
    where action = 'account.deactivated_by_instructor'
      and metadata->>'target_user_id' = v_context.learner_id::text
  ) then
    raise exception 'ACCOUNT_DEACTIVATION_AUDIT_MISSING';
  end if;
end
$$;

update public.profiles
set status = 'active'::public.account_status,
    deactivated_at = null,
    deactivation_reason = null,
    deactivated_by = null
where user_id = (select learner_id from bytequest_storage_test_context);

update public.class_memberships
set status = 'active'::public.membership_status,
    deactivated_at = null,
    deactivation_reason = null,
    deactivated_by = null
where id = (select membership_id from bytequest_storage_test_context);

insert into public.class_memberships (class_id, learner_id, status, enrolled_by)
select secondary_class_id, learner_id, 'active'::public.membership_status, secondary_instructor_id
from bytequest_storage_test_context;

select set_config(
  'request.jwt.claim.sub',
  (select instructor_id::text from bytequest_storage_test_context),
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

do $$
declare
  v_context bytequest_storage_test_context;
begin
  select * into v_context from bytequest_storage_test_context;
  begin
    perform public.instructor_deactivate_learner_account(
      v_context.learner_id,
      'Must be rejected because another Instructor is active'
    );
    raise exception 'CROSS_INSTRUCTOR_ACCOUNT_DEACTIVATION_NOT_BLOCKED';
  exception
    when insufficient_privilege then null;
  end;

  perform public.delete_learning_resource(
    v_context.resource_id,
    'Rollback-only resource archive verification'
  );
end
$$;

reset role;

do $$
declare
  v_context bytequest_storage_test_context;
begin
  select * into v_context from bytequest_storage_test_context;

  if not exists (
    select 1 from public.learning_resources
    where id = v_context.resource_id
      and status = 'deleted'::public.resource_status
  ) then
    raise exception 'RESOURCE_ARCHIVE_FAILED';
  end if;
  if not exists (
    select 1 from public.audit_events
    where action = 'learning_resource.deleted'
      and target_id = v_context.resource_id
  ) then
    raise exception 'RESOURCE_ARCHIVE_AUDIT_MISSING';
  end if;
end
$$;

rollback;
\echo ok 1 - storage and account hardening rollback
