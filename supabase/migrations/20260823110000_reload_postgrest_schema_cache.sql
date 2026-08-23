-- The practice evidence relation is committed in public, but the deployed
-- PostgREST instance has not observed it in its schema cache. This migration
-- changes no tables, policies, grants, or application data; it only requests
-- the supported schema-cache reload.

begin;

notify pgrst, 'reload schema';

commit;
