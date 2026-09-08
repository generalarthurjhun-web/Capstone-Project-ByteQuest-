-- Regression proof for the Auth profile-provisioning trigger after direct
-- client EXECUTE access to handle_new_user() is removed. All fixture data is
-- rolled back, including the auth.users row and its triggered profile row.

\echo 1..1
begin;

do $$
declare
  v_user_id uuid := gen_random_uuid();
  v_email text := 'rollback-auth-' || v_user_id::text || '@bytequest.invalid';
  v_profile public.profiles%rowtype;
begin
  if exists (
    select 1
    from pg_proc p
    cross join lateral aclexplode(
      coalesce(p.proacl, acldefault('f', p.proowner))
    ) acl
    where p.oid = 'public.handle_new_user()'::regprocedure
      and acl.grantee = 0
      and acl.privilege_type = 'EXECUTE'
  ) then
    raise exception 'HANDLE_NEW_USER_PUBLIC_EXECUTE_STILL_GRANTED';
  end if;

  if has_function_privilege('anon', 'public.handle_new_user()', 'EXECUTE')
     or has_function_privilege(
       'authenticated',
       'public.handle_new_user()',
       'EXECUTE'
     )
     or has_function_privilege(
       'service_role',
       'public.handle_new_user()',
       'EXECUTE'
     ) then
    raise exception 'HANDLE_NEW_USER_CLIENT_EXECUTE_STILL_GRANTED';
  end if;

  if not has_function_privilege(
    'postgres',
    'public.handle_new_user()',
    'EXECUTE'
  ) then
    raise exception 'HANDLE_NEW_USER_OWNER_EXECUTE_MISSING';
  end if;

  insert into auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at
  ) values (
    '00000000-0000-0000-0000-000000000000'::uuid,
    v_user_id,
    'authenticated',
    'authenticated',
    v_email,
    '',
    jsonb_build_object('provider', 'email', 'providers', jsonb_build_array('email')),
    jsonb_build_object('full_name', 'Rollback Auth Learner'),
    now(),
    now()
  );

  select *
  into v_profile
  from public.profiles
  where user_id = v_user_id;

  if v_profile.user_id is null then
    raise exception 'AUTH_SIGNUP_PROFILE_NOT_PROVISIONED';
  end if;

  if v_profile.email <> v_email
     or v_profile.full_name <> 'Rollback Auth Learner'
     or v_profile.role <> 'learner'::public.user_role
     or v_profile.status <> 'active'::public.account_status then
    raise exception 'AUTH_SIGNUP_PROFILE_CONTENT_MISMATCH';
  end if;
end
$$;

rollback;
\echo ok 1 - auth profile provisioning rollback
