# Live Supabase Schema and Migration Drift Report

**Verified:** 2026-08-10  
**Project:** `rslmteqipxqfifwftugk`

## Result

The 28 repository migrations are present in the live migration history in the same order. Eleven additive continuation migrations were applied across this phase. Four earlier live entries still have no matching repository SQL artifact; they are documented here and must not be recreated or replayed casually.

## Migration comparison

| Category | Count | Result |
|---|---:|---|
| Live migration history | 32 | Verified directly |
| Repository SQL migrations | 28 | Verified |
| Repository migration names present live | 28/28 | Match |
| Earlier live migrations missing from repository | 4 | Documented drift; no replay attempted |

Missing historical repository artifacts:

1. `add_admin_and_instructor_roles`
2. `rbac_role_helper_functions`
3. `create_administrator_and_instructor_accounts`
4. `lock_down_rbac_function_execute_grants`

These entries predate the repository foundation series. Their effective schema state is captured by the current generated types, live inventory, final role migrations, and this report. A future developer should recover the original SQL from the original operator/history if available. Creating look-alike migration files with new execution semantics would risk duplicate effects.

## Continuation migrations applied

| Repository file | Live migration name | Purpose |
|---|---|---|
| `20260810100000_learning_resource_storage_workflow.sql` | `learning_resource_storage_workflow` | Private Storage bucket, scoped metadata RPCs, file policy |
| `20260810101000_instructor_learner_account_deactivation.sql` | `instructor_learner_account_deactivation` | Conservative Instructor-scoped learner deactivation |
| `20260810102000_audit_retention_safe_auth_deletion.sql` | `audit_retention_safe_auth_deletion` | Preserve append-only audit history during safe Auth removal |
| `20260810103000_admin_account_removal_readiness.sql` | `admin_account_removal_readiness` | Enumerate retention-blocking Auth foreign keys before deletion |
| `20260810104000_security_definer_grant_hardening.sql` | `security_definer_grant_hardening` | Fixed legacy search paths and removed trigger-helper grants |
| `20260810110000_coc2_assessment_and_assignment_policy_support.sql` | `coc2_assessment_and_assignment_policy_support` | Optional audited retry/prerequisite policy, extended evidence operator, stricter attempt start |
| `20260810111000_grant_activity_versions_select.sql` | `grant_activity_versions_select` | Allows authenticated RLS-scoped version hydration on Mobile/Web |
| `20260810112000_fix_extended_evaluator_json_precedence.sql` | `fix_extended_evaluator_json_precedence` | Repairs JSON extraction precedence while retaining set equality |
| `20260810113000_instructor_quiz_authoring_and_ai_drafts.sql` | `instructor_quiz_authoring_and_ai_drafts` | Versioned Instructor quiz CRUD, review/publish gates, AI draft audit contract, RLS, and trusted RPCs |
| `20260810114000_quiz_private_function_grant_hardening.sql` | `quiz_private_function_grant_hardening` | Revokes inherited client `EXECUTE` from private quiz constraint/trigger helpers |
| `20260810115000_openrouter_quiz_provider.sql` | `openrouter_quiz_provider` | Changes new AI draft provenance/default to OpenRouter and replaces the request RPC with a provider-aware, size-bounded signature while preserving historical generation rows |

Live application timestamps differ from repository filenames because Supabase assigns the applied version. Migration names and order are the stable comparison keys.

## Live schema inventory

| Object type | Count |
|---|---:|
| Public base tables | 42 |
| Public views | 2 |
| Public materialized views | 0 |
| Public functions | 87, including extension functions exposed in `public` |
| Private functions | 12 |
| Public policies | 47 |
| Storage object policies | 1 |
| Public tables with RLS enabled | 42/42 |
| Public indexes | 165 |
| Public named constraints | 308 |
| Public enums | 30 |
| Storage buckets / objects | 1 / 0 after test retirement |

The `learning-resources` bucket is private, has a 50 MiB server-enforced maximum, and permits only PDF, JPEG, PNG, WebP, MP4, and WebM metadata types. Direct authenticated Storage writes are not granted; upload goes through the role-checked server route.

## Data-state facts

- 94 Auth users and 92 application profiles remain; 13 profiles are active. Disposable harness identities are named/retired through the test lifecycle, and immutable assessment/audit history is retained where deletion readiness prevents removal.
- Legacy catalog/history remains 4 competencies, 4 COC modules, 20 missions, 80 legacy criteria, 28 mission results, and 141 progress rows.
- Authoritative assessment state includes one active TESDA source, 20 published activity versions, 20 approved rubrics, and 98 criteria. Current retained lifecycle evidence includes 92 attempts, 1,064 ordered actions, 500 criterion results, 151 revisions, 52 releases, and 52 exact-once gamification events.
- Quiz state contains two archived test-only quizzes, four historical versions, six retained items, and two completed structured-contract generation records. It is non-learner, non-competency, and retained to prove audit/version history.
- 743 append-only `audit_events` remain as intentional governance/UAT evidence.
- The private Storage bucket is configuration, not fabricated learner data; it contains zero objects.
- All three SQL acceptance suites end in `ROLLBACK`. The authenticated COC2 harness retains immutable evidence by design while retiring all active classes/assignments/resources/identities and deleting test Storage objects.

## SECURITY DEFINER state

- 53 public functions are `SECURITY DEFINER`; all reviewed application functions are owned by `postgres`.
- Application RPCs have fixed empty search paths; the event trigger `rls_auto_enable` retains its deliberately fixed `search_path = pg_catalog`.
- No `SECURITY DEFINER` function is executable by `anon`.
- 46 are callable by `authenticated`; each is an intentionally exposed trusted RPC/helper and performs role/object-scope checks internally. AI generation completion/failure remains service-role-only.
- Trigger-only append guards no longer have client `EXECUTE` grants.

The complete review is in `docs/SECURITY_DEFINER_REVIEW.md`.

## Security advisor state

The final advisor reports 48 warnings and no errors:

- 46 authenticated-callable `SECURITY DEFINER` warnings. These are intentional trusted-boundary calls with fixed search paths and internal role/object checks; changes require negative regression tests.
- `pg_trgm` remains installed in `public`; relocation is deferred until a verified backup and dependency plan exist.
- Leaked-password protection remains disabled and requires an authorized Supabase Auth configuration operator.

## Drift decision

Migration history is understandable but not perfectly reconstructable because the four original SQL files are unavailable. No live history entry was edited, renamed, deleted, or replayed. This is the safest reconciliation until the original artifacts can be recovered.

## 2026-08-12 learner continuation

- Repository migrations `20260812120000_learner_quiz_lifecycle.sql` and `20260812130000_learner_learning_path_projection.sql` are both deployed and recorded with matching local/remote timestamps.
- The earlier historical live-only entries remain unchanged and are not recreated or fabricated.
- The learner quiz migration adds the version-linked assignment/attempt/answer/result lifecycle; the learning-path migration adds one authenticated read projection and no duplicate source-of-truth table.
- `20260812132000` and `20260812133000` complete the missing authenticated UPDATE grant for the pre-existing own-row `user_settings` policies. Both are applied with matching history; RLS was not weakened.

