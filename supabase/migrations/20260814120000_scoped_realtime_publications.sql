-- Publish only the ByteQuest records that power authenticated learner,
-- Instructor, and Admin freshness. Row visibility remains enforced by the
-- existing RLS policies; clients use these events only to invalidate and
-- refetch authoritative data.

begin;

do $$
declare
  table_name text;
  realtime_tables constant text[] := array[
    'profiles',
    'classes',
    'class_memberships',
    'assignments',
    'attempts',
    'criterion_results',
    'score_revisions',
    'result_releases',
    'coc_bypasses',
    'quiz_assignments',
    'quiz_attempts',
    'quiz_results',
    'learning_resources',
    'gamification_events',
    'user_achievements',
    'notifications',
    'audit_events',
    'tesda_sources',
    'system_settings'
  ];
begin
  foreach table_name in array realtime_tables loop
    if to_regclass(format('public.%I', table_name)) is null then
      raise exception 'Required realtime table public.% is missing', table_name;
    end if;

    if not exists (
      select 1
      from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = table_name
    ) then
      execute format(
        'alter publication supabase_realtime add table public.%I',
        table_name
      );
    end if;
  end loop;
end
$$;

commit;
