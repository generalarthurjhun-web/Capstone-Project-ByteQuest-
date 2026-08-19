begin;

-- These functions are constraint/trigger implementation details. They are not
-- part of the exposed API and must never inherit PostgreSQL's default PUBLIC
-- function EXECUTE privilege.
revoke all on function private.validate_quiz_item(
  public.quiz_item_type,
  jsonb,
  jsonb
) from public, anon, authenticated;

revoke all on function private.protect_quiz_item_history()
from public, anon, authenticated;

commit;
