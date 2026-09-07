-- Supabase's service_role bypasses RLS, but PostgreSQL table and sequence ACLs
-- are still required before trusted server-side maintenance can read or write.
-- Fresh local bootstraps do not inherit the managed project's implicit grants,
-- so make that server-only contract explicit without broadening client roles.

begin;

grant usage on schema public to service_role;
grant all privileges on all tables in schema public to service_role;
grant all privileges on all sequences in schema public to service_role;

-- Preserve the same server-only access for tables and identity sequences added
-- by later migrations. Function execution remains explicitly granted/revoked by
-- each workflow migration and is intentionally not changed here.
alter default privileges for role postgres in schema public
  grant all privileges on tables to service_role;
alter default privileges for role postgres in schema public
  grant all privileges on sequences to service_role;

commit;
