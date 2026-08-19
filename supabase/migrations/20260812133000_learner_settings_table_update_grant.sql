-- PostgREST upsert requires the table-level UPDATE privilege. The existing
-- own-row RLS USING/WITH CHECK policies still prevent cross-user mutation.

begin;
grant update on public.user_settings to authenticated;
commit;
