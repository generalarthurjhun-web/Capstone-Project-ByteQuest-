-- Restore least-privilege access after enabling the practice evidence table
-- in the Data API. This migration changes only table and sequence ACLs;
-- existing RLS policies, table structure, and Data API exposure are retained.

begin;

revoke all on table public.practice_mission_actions
  from anon, authenticated;
grant select, insert on table public.practice_mission_actions
  to authenticated;

revoke all on sequence public.practice_mission_actions_id_seq
  from anon, authenticated;
grant usage on sequence public.practice_mission_actions_id_seq
  to authenticated;

commit;
