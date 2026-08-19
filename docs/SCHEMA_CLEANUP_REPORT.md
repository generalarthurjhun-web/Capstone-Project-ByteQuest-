# Schema Cleanup and Destructive-Change Report

Date: 2026-08-10

## Decision

No production table, column, index, view, storage object, or historical record was deleted.

A direct database connection string and local `pg_dump`/`psql` backup path were unavailable. Under the project's deletion rule, this prevents destructive cleanup even where an object appears obsolete. Additive migrations, revocable grants, policy replacement, function replacement, quarantine, and a reversible enum-label rename were used instead.

The backup gate was retried on 2026-08-10 and remains blocked for destructive cleanup only. Eight continuation migrations add private resource delivery, scoped deactivation/removal safeguards, SECURITY DEFINER hardening, COC2 evidence/retry support, the required RLS-scoped version read grant, and an evaluator-precedence repair. None is a legacy cleanup migration and none deletes production history.

## Data preserved and quarantined

- All 28 legacy `mission_results` rows remain intact.
- All 28 were cataloged in `legacy_result_quarantine` with their legacy provenance and quality concerns.
- Sixteen duplicate logical identities were identified.
- No result was promoted to an official attempt because every legacy result lacks criterion/action evidence.
- All 141 legacy learner-progress rows remain intact.

## Removed code, not production data

- Firebase production integration and stale Firebase browser persistence.
- Unsafe mobile result/progress/gamification write services.
- Live-mutating `test/db_test.dart`.
- Proven-unused local sample/level/result model files.

These removals were repository-wide reference checked and replaced by Supabase session/RPC/query paths or were proven unused.

## Database objects modified safely

| Object | Change | Reason | Rollback path |
|---|---|---|---|
| `user_role.instructor_admin` | Renamed to rejected `legacy_instructor_admin` | Remove operational merged role without destructive enum recreation | Migration documents reverse rename after checking for rows |
| Role guard constraint/RPCs | Reject compatibility label | Prevent assignment through trusted paths | Replace constraint/function from migration history |
| `is_instructor_admin()` | Dropped after zero dependent objects were verified | Obsolete merged authorization helper | Recreate from prior schema if rollback is required |
| `get_rating(integer)` | Returns `PENDING_TESDA_VALIDATION` | Quarantine unverified 90/80/75/60 policy bands | Prior body is documented in schema history; activation requires approved policy |
| RLS policies/grants | Replaced/revoked as needed | Establish class/object scope and protect authoritative results | Reapply ordered prior migrations only in a restored environment |

## Legacy table decisions

| Object | Decision | Reason |
|---|---|---|
| `profiles` | MODIFY/KEEP | Authoritative profile; lifecycle fields and protected mutations added |
| `competencies`, `coc_modules`, `missions` | KEEP/MODIFY | Stable legacy catalog identities needed by existing content and version mapping |
| `mission_results`, `learner_progress` | KEEP/QUARANTINE | Production history is untrusted but must not be erased |
| `simulation_tasks`, `task_results` | DEPRECATE, no drop | Empty/legacy paths, but backup and final cutover proof are absent |
| `activity_logs` | DEPRECATE, no drop | Replaced by trusted `audit_events`; destructive gate not met |
| `reports` | REQUIRES_CONFIRMATION | Empty, but report retention/product requirements need confirmation |
| `leaderboard_entries` | MIGRATE later | Existing projection/history retained while event-based gamification becomes authoritative |
| Legacy badges/achievements/settings | KEEP/MODIFY | Useful catalogs/preferences; server ownership must be completed incrementally |

## Tables removed

None.

## Columns removed

None.

## Required prerequisites for a future cleanup migration

1. Obtain a verified database backup/export and restore test.
2. Complete real source/rubric approval and production cutover.
3. Re-run repository-wide references and database dependency queries.
4. Reconcile or export legacy results/progress.
5. Verify no views, functions, triggers, policies, foreign keys, or storage metadata depend on each target.
6. Produce an ordered reversible cleanup migration with explicit recovery SQL.
7. Obtain human confirmation for every `REQUIRES_CONFIRMATION` object.

## Acceptance-phase revalidation

The 2026-08-08 acceptance phase re-ran live row counts, FK graphs, triggers, repository references, and replacement checks. The result remains **no destructive cleanup**:

- Backup/restore verification is still unavailable; see `DATABASE_BACKUP_VERIFICATION.md`.
- `simulation_tasks`, `learner_progress`, and `notifications` still have direct Flutter references.
- Historical `mission_results`, progress, and leaderboard records remain connected through foreign keys.
- `activity_logs` is an empty later drop candidate, but the mandatory backup and manual approval gates are not satisfied.
- Every reassessed table and column is documented in `LEGACY_SCHEMA_REASSESSMENT.md`.

No cleanup migration was created or applied.

