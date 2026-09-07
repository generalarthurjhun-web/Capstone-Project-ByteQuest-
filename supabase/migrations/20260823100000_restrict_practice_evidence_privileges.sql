-- Keep practice evidence append-only for learner clients at the table ACL level.
-- RLS policies remain the row-level owner boundary; this migration only removes
-- privileges that are not required by the mobile evidence transport.

begin;

revoke all on table public.practice_mission_actions from anon, authenticated;
grant select, insert on table public.practice_mission_actions to authenticated;

-- PostgREST inserts identity rows and needs sequence usage for the generated id.
revoke all on sequence public.practice_mission_actions_id_seq from anon, authenticated;
grant usage on sequence public.practice_mission_actions_id_seq to authenticated;

commit;
