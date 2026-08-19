-- Enum additions must commit before a later migration can use the new value.
alter type public.account_status add value if not exists 'deactivated';

