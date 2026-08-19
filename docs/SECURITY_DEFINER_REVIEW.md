# SECURITY DEFINER Review

**Reviewed:** 2026-08-10  
**Live project:** `rslmteqipxqfifwftugk`

## Review result

All 61 `SECURITY DEFINER` functions in `public` and `private` are owned by `postgres`. Sixty use `search_path = ''`; `public.rls_auto_enable()` deliberately uses the fixed `pg_catalog` path. No function is executable by `anon`. Forty-six public authenticated-callable trusted RPCs plus one private RLS helper remain because RLS or a trusted transactional workflow requires them.

`SECURITY DEFINER` is not treated as authorization by itself. Exposed RPCs check the active application role and, for object mutations, class ownership, learner identity, enrollment, attempt ownership, version state, or Admin scope inside the function.

## Private/internal functions

| Function | Purpose | Direct caller/grant | Internal authorization | Decision |
|---|---|---|---|---|
| `private.assert_attempt_write_access` | Rechecks learner, assignment, class, enrollment, and availability on every evidence mutation | Internal only | Learner identity and active scope | KEEP DEFINER |
| `private.current_instructor_teaches_learner` | Non-recursive RLS class/learner scope helper | Policy/internal; private schema has no client usage | `auth.uid()` class ownership | KEEP DEFINER |
| `private.evaluate_criterion_evidence` | Reads ordered evidence for a validated criterion rule | Internal evaluator only | Called after attempt/rubric checks | KEEP DEFINER |
| `private.prevent_append_only_mutation` | Trigger guard for attempts/results/revisions | Trigger only; client grants revoked | Always rejects update/delete | KEEP DEFINER |
| `private.prevent_gamification_event_mutation` | Trigger guard for gamification events | Trigger only; client grants revoked | Always rejects update/delete | KEEP DEFINER |
| `private.protect_audit_event_history` | Rejects audit mutation; permits nested Auth FK actor nullification only | Trigger only; no client grant | Exact column-diff plus nested-trigger check | KEEP DEFINER |
| `private.protect_quiz_item_history` | Prevents mutation/deletion after a quiz version leaves draft | Trigger only; all client grants revoked by `quiz_private_function_grant_hardening` | Reads the bound version state and rejects published-history mutation | KEEP DEFINER |
| `private.write_audit_event` | Central trusted audit writer | Internal only; no client grant | Derives actor/role from Auth context | KEEP DEFINER |

## Public role, RLS, and trigger helpers

| Function | Purpose | Caller | Authorization/object scope | Decision |
|---|---|---|---|---|
| `current_app_role` | Reads active profile role without RLS recursion | Authenticated/RLS | `auth.uid()` + active status | KEEP DEFINER |
| `instructor_owns_class` | Class ownership predicate | Authenticated/RLS/RPC | `class.instructor_id = auth.uid()` | KEEP DEFINER |
| `learner_is_enrolled` | Active membership predicate | Authenticated/RLS/RPC | Requested learner/class membership | KEEP DEFINER |
| `is_active_user` | Active-account predicate | Authenticated/RLS | `auth.uid()` active profile | KEEP DEFINER |
| `is_admin` | Active Admin predicate | Authenticated/RLS/RPC | Active role lookup | KEEP DEFINER |
| `is_instructor` | Active Instructor predicate | Authenticated/RLS/RPC | Active role lookup | KEEP DEFINER |
| `is_learner` | Active Learner predicate | Authenticated/RLS/RPC | Active role lookup | KEEP DEFINER |
| `is_staff` | Active Instructor/Admin predicate | Authenticated/RLS | Active role lookup | KEEP DEFINER |
| `is_own_user` | Legacy identity predicate | Service/legacy dependency only; no app grant | `auth.uid()` equality | KEEP UNTIL BACKUP CLEANUP |
| `handle_new_user` | Auth trigger that creates a default learner profile | Auth trigger/service only | Trigger `new.id`; no client input path | KEEP DEFINER |
| `after_mission_result_insert` | Quarantined legacy projection trigger helper | Trigger/service only; no client grant | Legacy path is quarantined from authoritative assessment | KEEP UNTIL BACKUP CLEANUP |
| `rls_auto_enable` | Enables RLS on newly created public tables | Database event trigger only | Fixed `pg_catalog` path and public-schema allow-list | KEEP DEFINER |

## Authenticated transactional RPCs

| Function | Purpose | Required internal boundary | Decision |
|---|---|---|---|
| `activate_tesda_source` | Activate approved source | Active Admin; approved source; reason | KEEP; human approval gate remains |
| `admin_account_removal_readiness` | Enumerate Auth FK retention blockers | Active Admin; no self-removal; deactivated target | KEEP |
| `admin_change_user_role` | Audited role assignment | Active Admin; self/legacy-role safeguards | KEEP |
| `admin_set_account_status` | Audited deactivate/restore | Active Admin; self-deactivation safeguard | KEEP |
| `admin_update_system_setting` | Audited global setting change | Active Admin; reason and validated input | KEEP |
| `append_attempt_action` | Append chronological evidence | Owning active Learner; active enrollment/assignment | KEEP |
| `approve_rubric_version` | Approve supported rubric contract | Active Admin; active source; validated rules | KEEP; do not call before approval |
| `approve_tesda_source` | Approve candidate source | Active Admin; validation notes | KEEP; do not call before approval |
| `archive_class` | Archive class | Owning Instructor; reason | KEEP |
| `archive_instructor_quiz` | Archive an Instructor-owned quiz while retaining versions/items | Active owning Instructor; reason | KEEP |
| `assign_activity` | Assign published activity | Owning Instructor; active source; approved rubric for assessment | KEEP |
| `begin_ai_quiz_generation` | Record an OpenRouter draft-generation request before provider execution | Active owning Instructor; owned draft version; provider fixed to `openrouter`; count/model/context-size bounded | KEEP |
| `close_assignment` | Close assignment | Owning Instructor; reason | KEEP |
| `create_class` | Create Instructor-owned class | Active Instructor | KEEP |
| `create_instructor_quiz` | Create quiz plus first draft version | Active Instructor; owned optional class | KEEP |
| `create_learning_resource` | Create validated resource metadata | Active owning Instructor; canonical path/type/size | KEEP |
| `create_quiz_version` | Create next draft without rewriting published history | Active owning Instructor; reason for versioning | KEEP |
| `deactivate_class_membership` | Preserve and close enrollment | Owning Instructor; reason | KEEP |
| `delete_learning_resource` | Soft-delete resource metadata | Owning Instructor or Admin; reason | KEEP |
| `enroll_learner` | Enroll a learner UUID | Owning Instructor; active learner | KEEP |
| `enroll_learner_by_email` | Enroll registered learner by email | Owning Instructor; active learner | KEEP |
| `evaluate_submitted_attempt` | Deterministic criterion evaluation | Owning Learner submission or service role; approved captured rubric | KEEP |
| `finalize_attempt` | Append adjustment/final revision | Owning Instructor; evaluated state; reason if changed | KEEP |
| `get_bypassed_activities` | Return practice-only bypass content | Active enrolled Learner; active bypass | KEEP |
| `grant_coc_bypass` | Grant scoped practice access | Owning Instructor; active enrollment/module; reason | KEEP |
| `instructor_deactivate_learner_account` | Conservative learner deactivation | Owning Instructor; exclusive active Instructor scope; reason | KEEP |
| `publish_activity_version` | Publish versioned activity | Active Instructor with allowed content scope | KEEP |
| `publish_quiz_version` | Publish only when every active item is Instructor-approved | Active owning Instructor; nonempty approved version; reason | KEEP |
| `publish_module_version` | Publish versioned module | Active Instructor with allowed content scope | KEEP |
| `register_tesda_source` | Register pending source candidate | Active Admin; remains pending | KEEP |
| `release_attempt` | Release finalized result and projections | Owning Instructor; finalized revision; idempotent | KEEP |
| `remove_quiz_item` | Remove an item from a draft version | Active owning Instructor; draft-only; reason | KEEP |
| `review_quiz_item` | Approve or reject manual/AI draft item | Active owning Instructor; rejection reason mandatory | KEEP |
| `start_attempt` | Create/reuse attempt identity | Active enrolled Learner; active/available assignment | KEEP |
| `submit_attempt` | Submit once and invoke evaluator | Owning active Learner; evidence required; idempotent | KEEP |
| `update_instructor_quiz` | Update quiz metadata/class association | Active owning Instructor; draft/ownership checks | KEEP |
| `upsert_quiz_item` | Create/edit a draft item under the validated answer contract | Active owning Instructor; draft-only; generated items remain draft | KEEP |

## Service-only trusted function

| Function | Purpose | Grant | Decision |
|---|---|---|---|
| `record_provisional_evaluation` | Compatibility path for trusted server evaluation | `service_role` only | KEEP; learner/authenticated grant remains revoked |
| `complete_ai_quiz_generation` | Atomically validate provider payload and insert AI-origin draft items | `service_role` only; server route supplies authenticated requester ID | KEEP; authenticated/anonymous grants revoked |
| `fail_ai_quiz_generation` | Record sanitized provider/contract failure | `service_role` only; server route supplies authenticated requester ID | KEEP; authenticated/anonymous grants revoked |

## Verification

- Direct/anonymous execution: zero `SECURITY DEFINER` functions are executable by `anon` after the quiz private-helper grant hardening migration.
- Search path: 60 empty, one fixed to `pg_catalog`, zero variable/uncontrolled paths.
- Rollback suites: foundation lifecycle PASS; Storage/account hardening PASS.
- Supabase advisor: no error-level finding. The 46 authenticated-definer warnings correspond to the reviewed public allow-list above.

## Remaining configuration findings

1. Supabase leaked-password protection is disabled and cannot be changed through repository SQL/MCP; an authorized Auth operator must enable it if the project plan supports it.
2. `pg_trgm` remains in `public`. Do not relocate it before a verified backup, extension dependency analysis, and isolated restore test.

