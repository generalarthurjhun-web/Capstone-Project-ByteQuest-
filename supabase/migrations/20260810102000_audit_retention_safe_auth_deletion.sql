-- Preserve append-only audit history while allowing the audit actor foreign key
-- to perform its declared ON DELETE SET NULL action during Auth user removal.
-- No audit event can be edited or deleted directly by an application caller.

begin;

create or replace function private.protect_audit_event_history()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'UPDATE'
     and pg_trigger_depth() > 1
     and old.actor_id is not null
     and new.actor_id is null
     and (to_jsonb(new) - 'actor_id') = (to_jsonb(old) - 'actor_id') then
    return new;
  end if;

  raise exception 'audit_events is append-only' using errcode = '55000';
end
$$;

drop trigger if exists audit_events_append_only on public.audit_events;
create trigger audit_events_append_only
before update or delete on public.audit_events
for each row execute function private.protect_audit_event_history();

revoke all on function private.protect_audit_event_history() from public, anon, authenticated;

comment on function private.protect_audit_event_history() is
  'Rejects direct audit mutation; permits only nested FK actor_id nullification when an Auth identity is removed.';

commit;
