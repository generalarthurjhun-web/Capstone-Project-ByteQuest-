-- Narrow legacy SECURITY DEFINER trigger helpers without changing their data
-- behavior. Public RPCs intentionally retain authenticated EXECUTE only where
-- their bodies perform role/object-scope checks.

begin;

alter function public.after_mission_result_insert() set search_path = '';
alter function public.handle_new_user() set search_path = '';
alter function public.is_own_user(uuid) set search_path = '';

revoke all on function private.prevent_append_only_mutation()
  from public, anon, authenticated, service_role;
revoke all on function private.prevent_gamification_event_mutation()
  from public, anon, authenticated, service_role;

comment on function public.after_mission_result_insert() is
  'Legacy quarantined mission-result trigger helper; fixed search_path and no client EXECUTE grant.';
comment on function public.handle_new_user() is
  'Auth profile provisioning trigger helper; fixed search_path and no client EXECUTE grant.';
comment on function public.is_own_user(uuid) is
  'Legacy helper retained for dependency-safe cleanup; fixed search_path and no client EXECUTE grant.';

commit;
