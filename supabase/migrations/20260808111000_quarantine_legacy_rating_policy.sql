-- The legacy rating bands were not traceable to an approved TESDA source.
-- Keep the function signature for schema compatibility, but fail closed so no
-- server process can silently apply the historical 90/80/75/60 thresholds.

create or replace function public.get_rating(p_score integer)
returns public.rating_type
language plpgsql
immutable
set search_path = ''
as $$
begin
  raise exception 'PENDING_TESDA_VALIDATION'
    using errcode = '22023',
          detail = 'Legacy numeric rating bands are quarantined until an approved source and rubric version are activated.';
end
$$;

alter function public.set_updated_at()
  set search_path = '';

alter function public.get_level_from_xp(integer)
  set search_path = '';

revoke all on function public.get_rating(integer)
  from public, anon, authenticated;

comment on function public.get_rating(integer) is
  'Compatibility signature only. Always fails with PENDING_TESDA_VALIDATION; authoritative outcomes come from approved rubric versions.';
