-- Auth signup invokes this function through the auth.users trigger. No client
-- role needs permission to invoke the SECURITY DEFINER function directly.
revoke execute on function public.handle_new_user()
  from public, anon, authenticated, service_role;
