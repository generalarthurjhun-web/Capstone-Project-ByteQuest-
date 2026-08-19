# Checkpoint A â€” Architecture and Database Inventory

Date: 2026-08-07  
Scope: read-only architecture, source, repository, and live Supabase inspection  
Decision gate: **additive/reversible foundation work may proceed; destructive cleanup may not proceed**

## Executive decision

Supabase is the only viable authoritative identity and domain platform for ByteQuest. The Flutter application already uses the authorized Supabase project, the live project contains learner records, and the approved PRD requires one shared backend. The web dashboard's Firebase browser SDK, mock session, mock users, and dummy analytics are not an approved second system and must be migrated before Firebase can be removed.

No live table or column is approved for deletion at this checkpoint. Existing records must be preserved as legacy evidence/projections until the replacement attempt and result lifecycle has been deployed, migrated, reconciled, and backed up.

## Sources reviewed

- `Capstone_PRD_Gamified_CSS_NCII.pdf`, 25/25 pages, PRD v1.0 dated 2026-08-07.
- `docs/reference/CAPSTONE_CURRENT_SYSTEM_GAP_ANALYSIS_REPORT.pdf`, 47/47 pages.
- Objectives of the Study, Scope and Limitations, and all 14 panel recommendations contained in the PRD.
- All root project documentation and all Flutter documentation files.
- The stale `.kiro/specs/web-prd-compliance` requirements, design, and tasks; these are Firebase-era implementation notes and are subordinate to the approved PRD.
- All repository authentication, authorization, Firebase, Supabase, database-service, scoring, progress, gamification, simulation, and test code.
- Live Supabase schemas, tables, columns, constraints, indexes, views, functions, triggers, enums, migrations, RLS policies, storage inventory, Auth/profile consistency, row counts, security advisor, and performance advisor.

## Requirement authority findings

- The PRD explicitly does not approve an exact TESDA source edition, COC naming/sequence, pass threshold, task weights, or scoring formula.
- No approved TESDA booklet or Training Regulations PDF exists in the repository.
- The 75% pass value and 40/20/20/15/25 weighting values in the live database and clients are therefore `UNVERIFIED_LEGACY_VALUE`, not approved requirements.
- Status: **TESDA SOURCE REQUIRES HUMAN CONFIRMATION**. Rule activation and official competency finalization must remain blocked until an Admin records an approved official source and rubric.

## Repository architecture before

| Surface | Current authority | Verified condition | Decision |
|---|---|---|---|
| Flutter learner app | Supabase client plus SharedPreferences | Direct table writes decide score, pass, XP, progress, badges, achievements, and leaderboard projections | Preserve UI/content where useful; replace authoritative writes with versioned RPC/server workflow |
| Next.js dashboard | Firebase browser SDK, localStorage flag, and dummy arrays | Login accepts synthetic credentials, route guard is disabled, sign-up creates `instructor_admin`, privileged writes use a browser client | Replace with Supabase SSR/session verification and trusted server mutations |
| Firebase | Partial legacy web persistence | Collections referenced: `users`, `progress`, `logs`, `settings`; no evidence it is an approved authority | Trace/migrate any required records, then remove production dependency; do not delete before trace is complete |
| Supabase | Live identity and learner data | 13 Auth users, 11 profiles, 19 app tables, 28 results, 141 progress rows | Adopt as sole shared authority and normalize incrementally |
| TESDA rules | Hard-coded client/database values | No approved source/version linkage | Quarantine as legacy; introduce inactive/pending versioned source and rubric structures |

## Repository dependency inventory

### Web

- 107 source files; no middleware and no API route/server-action authorization boundary.
- `ByteQuest Web Dashboard/src/hooks/use-auth.tsx` uses a mock `instructor_admin` and a `bytequest_temp_auth` localStorage flag.
- `ByteQuest Web Dashboard/src/components/auth/LoginForm.tsx` accepts any syntactically plausible email and non-empty password.
- `ByteQuest Web Dashboard/src/components/auth/SignUpForm.tsx` creates Firebase Auth accounts and assigns `instructor_admin` from the browser.
- `ByteQuest Web Dashboard/src/services/firebase.service.ts` exposes generic collection CRUD through the browser SDK.
- Dummy or random production data is present in dashboard, analytics, progress, reports, modules, and users.
- Root dependencies include Firebase but no Supabase JavaScript/SSR package.
- The Next.js production build succeeds. A typecheck fails against stale `.next/types` before a build and passes after `next build` regenerates types.

### Flutter

Direct table references were verified for `profiles`, `coc_modules`, `missions`, `simulation_tasks`, `levels`, `mission_results`, `task_results`, `learner_progress`, badges/achievements, leaderboard, notifications, and settings. `competencies`, `assessment_criteria`, `reports`, and `activity_logs` have no effective learner-side table integration.

Key write paths:

- `AuthService` and `ProfileService` allow the client to create/update profile role and status fields.
- `ResultService` inserts a mission result and then task results in separate calls, without a transaction or idempotency key.
- `MissionCompletionService` performs result, progress, profile, badge, achievement, and leaderboard writes sequentially and can leave partial state.
- Enhanced simulation screens persist completion before navigation; `ResultScreen` persists it again.
- `LocalGamificationService` treats SharedPreferences as a competing reward/progress authority.
- `ProgressResumeService` keeps detailed evidence locally and sends only a percentage/status projection to Supabase.

Verified defects:

- Duplicate result persistence is confirmed in both source and live data.
- Chronological procedure validation is not recorded; a final set can incorrectly validate `B â†’ A â†’ C` as `A â†’ B â†’ C`.
- The RJ45 question offers `RJ45 Connector` but checks the unreachable exact value `RJ45`.
- Mobile account active-state and role enforcement are not applied at login/navigation boundaries.
- Notification code references an `is_unread` column that does not exist.
- Flutter models for badges, achievements, and leaderboard entries do not match the live schema.
- Three declared asset directories do not exist.
- `test/db_test.dart` contains live credentials/configuration and mutates the remote project; it is not a safe automated test.

## Live Supabase inventory

### Schemas

| Schema | Objects | Ownership decision |
|---|---:|---|
| `public` | 19 tables, 2 views | ByteQuest application schema; migrate incrementally |
| `auth` | 23 provider tables, 1 sequence | Supabase-managed; inspected for user/profile consistency, do not modify directly except supported triggers/functions |
| `storage` | 8 provider tables | Supabase-managed; zero buckets and zero objects |
| `realtime` | 3 provider tables, 1 sequence | Supabase-managed |
| `supabase_migrations` | 1 table | Supabase-managed migration history |
| `vault` | 1 table, 1 view | Supabase-managed; secret contents were not read |
| `extensions` | 2 views | Provider/extension-managed |
| `graphql`, `graphql_public` | no relations | Provider-managed |

### Row counts and data importance

| Table | Live rows | Purpose | Mobile | Web | DB dependency | PRD support | Decision |
|---|---:|---|---|---|---|---|---|
| `profiles` | 11 | App identity/profile and projections | Read/write | Firebase substitute only | Auth trigger, RLS helpers, leaderboard view | Identity/RBAC | **MODIFY** â€” retain records; restrict writable fields; add lifecycle fields |
| `competencies` | 4 | Legacy competency catalog | No direct integration | Mock pages only | FK from COCs/missions | TESDA mapping | **MODIFY** â€” attach approved source/version before publication |
| `coc_modules` | 4 | Legacy four-COC module catalog | Read | Mock modules | FKs from missions/progress/results | Module/COC navigation | **MODIFY** â€” retain as stable identity; version published content |
| `missions` | 20 | Legacy mission/activity catalog | Heavy read | Mock modules | Many FKs and performance view | Learning activities | **MODIFY** â€” retain identity; publish immutable activity versions |
| `simulation_tasks` | 0 | Versionless task definitions | Read path exists | None | FK from task results | Simulation content | **DEPRECATE** after versioned activities exist; no drop yet |
| `assessment_criteria` | 80 | Unversioned legacy weights | No integration | Placeholder routes | FK to missions | Criterion evaluation | **MIGRATE/QUARANTINE** as unverified legacy; never activate as TESDA rules |
| `levels` | 8 | Gamification level configuration | Read/client fallback | None | `get_level_from_xp` | Motivation | **KEEP/MODIFY** â€” server projection only, separate from competency |
| `mission_results` | 28 | Client-authored legacy totals | Insert/read | Dummy reporting only | Task results, leaderboard, view | Historical attempts | **MIGRATE** to legacy attempt imports; preserve every row and duplicate marker |
| `task_results` | 0 | Client-authored per-task results | Insert/read | None | FKs to result/task | Evidence | **DEPRECATE** after action/criterion evidence exists; no drop yet |
| `learner_progress` | 141 | Client-writable mission projection | Read/write | Dummy reporting only | Unique learner/mission | Progress | **MODIFY** â€” preserve and make server-projected |
| `badges` | 7 | Badge catalog | Read | Report mock only | User badges | Gamification | **KEEP/MODIFY** â€” version/configure independently from competency |
| `user_badges` | 0 | Badge awards | Client insert | None | User/badge/mission/COC FKs | Gamification | **MIGRATE** to append-only gamification events/projection |
| `achievements` | 5 | Achievement catalog | Read | None | User achievements | Gamification | **KEEP/MODIFY** |
| `user_achievements` | 0 | Achievement awards | Client insert | None | User/achievement FKs | Gamification | **MIGRATE** to append-only gamification events/projection |
| `leaderboard_entries` | 3 | Client-calculated ranks/events | Read/write | Placeholder | Mission result FKs | Gamification/analytics | **MIGRATE** to server projection; client writes must stop |
| `notifications` | 0 | Learner notifications | Read/update | Settings label only | Mission/COC FKs | Communication | **KEEP/MODIFY** â€” fix column contract and actor scope |
| `user_settings` | 8 | Learner preferences | Initialization only | Separate Firebase settings | User FK | UX preference | **KEEP** for learner preferences; separate global settings |
| `reports` | 0 | Stored JSON report snapshots | None | Name-only references | Generator user FK | Reporting | **REQUIRES_CONFIRMATION** â€” no drop until real report design is implemented |
| `activity_logs` | 0 | Spoofable generic log rows | None | Firebase `logs`, not this table | User FK | Audit | **DEPRECATE** after trusted `audit_events`; no drop yet |

The complete per-column ledger is in `docs/CHECKPOINT_A_COLUMN_INVENTORY.md`.

### Views

| View | Dependency | Finding | Decision |
|---|---|---|---|
| `view_leaderboard_overall` | `profiles` | Owner-privileged view; `anon` has access; exposes learner identity and client-writable totals | Replace with security-invoker/scoped projection; revoke anonymous access |
| `view_mission_performance_summary` | `missions`, `coc_modules`, `mission_results` | Owner-privileged view aggregates untrusted client results; `anon` has access | Replace with class-scoped analytics over finalized/released results |

No materialized views exist.

### Functions/RPCs

Application functions found:

- `handle_new_user()` â€” Auth trigger; correctly defaults new users to learner, but profile lifecycle is incomplete.
- `is_admin()`, `is_instructor()`, `is_staff()`, `is_instructor_admin()` â€” security-definer role helpers. `is_staff` and `is_instructor_admin` merge all staff roles, violating object-level separation.
- `is_own_user(uuid)` â€” security-definer helper exposed too broadly.
- `after_mission_result_insert()` â€” unattached legacy trigger function with hard-coded ranking/reward formula and broad execute grants.
- `get_rating(integer)` â€” hard-coded 90/80/75/60 bands.
- `get_level_from_xp(integer)` â€” gamification lookup.
- `set_updated_at()` â€” timestamp trigger.
- `rls_auto_enable()` â€” event-trigger function; RLS enabling is useful, but RPC execute grants are broader than necessary.

`pg_trgm` also installs extension functions in `public`; these are not ByteQuest business RPCs.

### Triggers

- `auth.users.on_auth_user_created` invokes `handle_new_user()`.
- `updated_at` triggers exist on profiles and most mutable catalog/projection tables.
- No trigger is attached to `mission_results`; `after_mission_result_insert()` is currently dead code but externally executable.
- Event trigger `ensure_rls` enables RLS on newly created `public` tables.
- Remaining listed triggers are Supabase Storage/provider triggers.

### Migration history

Only four live migration records exist; no matching SQL files are present in the repository:

1. `20260728153636_add_admin_and_instructor_roles`
2. `20260728153711_rbac_role_helper_functions`
3. `20260728153837_create_administrator_and_instructor_accounts`
4. `20260728155035_lock_down_rbac_function_execute_grants`

Legacy documentation states that four earlier SQL files were deleted from the mobile tree. The live schema therefore cannot currently be reproduced from source.

### RLS findings

All 19 public tables have RLS enabled, but current policies are not sufficient:

- A learner can update every column on their own `profiles` row, including role, status, XP, points, badges, level, and completed missions.
- A learner can insert and update their own `mission_results` and `learner_progress`, making score/pass/progress client-authoritative.
- A learner can insert leaderboard, badge, and achievement records for themselves.
- Any authenticated user can insert `activity_logs` with arbitrary actor/action metadata.
- `is_instructor_admin()` permits admin, instructor, and legacy instructor_admin equally across content, all profiles, results, reports, and logs; there is no class ownership boundary.
- Both views use owner privileges and have anonymous grants.
- Several security-definer functions have unnecessary `anon` or `authenticated` execute grants.

Supabase advisor snapshot:

- 2 security errors: both public views are security-definer.
- 15 security warnings: mutable function search paths, extension placement, broad security-definer RPC execution, and leaked-password protection disabled.
- 84 performance notices: 12 unindexed foreign keys, 25 non-initplan RLS calls, 41 currently unused indexes, and 6 duplicate permissive-policy cases.
- Unused-index notices are not deletion evidence and do not authorize dropping an index.

Reference: [Supabase database linter â€” security-definer views](https://supabase.com/docs/guides/database/database-linter?lint=0010_security_definer_view)

## Data quality findings

- 13 Auth users exist; 2 have no profile. There are no orphan profiles and no mirrored-email mismatches.
- Profile roles: 9 learners, 1 instructor, 1 admin; zero live `instructor_admin` rows. The enum and code paths still retain the merged role.
- 28 legacy mission results collapse to only 12 unique `(user, mission, attempt_number)` identities: **16 duplicate identities**.
- 11 consecutive same-learner/same-mission result pairs were created within 30 seconds.
- All 28 mission results have no `task_results` evidence.
- 5 result rows have `score != percentage`.
- 5 profile XP/points projections disagree with sums from mission results.
- All 20 missions use the unverified pass threshold 75.
- The 80 criteria use four legacy weight/max-score pairs: 0.40/40, 0.25/25, 0.20/20, and 0.15/15, twenty rows each. These are not approved TESDA rules.
- `simulation_tasks` is empty, while the mobile simulations mostly use hard-coded Dart definitions.
- There are no storage buckets or objects.

## Proposed target architecture

```text
Supabase Auth
    â†“
profiles (trusted role/account state)
    â”œâ”€â”€ admin governance
    â”œâ”€â”€ instructor-owned classes â†’ memberships â†’ assignments
    â””â”€â”€ learner-scoped assigned content

approved tesda_source
    â†“
module_version â†’ activity_version â†’ rubric_version â†’ rubric_criteria
                                           â†“
assignment â†’ attempt â†’ ordered action evidence
                         â†“
                 trusted criterion evaluation
                         â†“
             provisional score revision
                         â†“
          instructor review/finalization/release
                         â†“
         learner released result + progress projection
                         â†“
        idempotent gamification event/projections

All high-impact transitions â†’ immutable audit_events
```

The web dashboard will use Supabase SSR/cookie sessions and authenticated server routes/actions. Every mutation will re-verify the session and object scope inside the trusted boundary. Flutter will use authenticated reads and narrow RPCs for attempt creation, action append, submission, and released-result reads; it will not write scores, competency, rewards, profile role, or membership.

## Proposed additive migration path

Existing timestamp migration conventions will be retained. Proposed stages:

1. Identity lifecycle fields, strict role helpers, and protected profile mutation.
2. Classes and historical memberships.
3. TESDA source registry with pending/approved/active lifecycle.
4. Stable module/activity identities plus immutable published versions.
5. Versioned rubrics/criteria; legacy criteria marked unverified and inactive.
6. Assignments and class scope.
7. Attempts and ordered append-only action evidence.
8. Criterion results and trusted evaluation framework.
9. Append-only score revisions, finalization, and releases.
10. Audited COC/module bypass that unlocks access only.
11. Idempotent gamification events and server-owned projections.
12. Learning resources/storage metadata if required after file limits are confirmed.
13. Central append-only audit events.
14. Constraints, supporting indexes, and replacement RLS.
15. Legacy data import/reconciliation.
16. Cleanup migration only after backup, cutover, reference proof, and end-to-end validation.

## Keep/modify/removal proposal

### Keep or modify now

- Keep all live rows.
- Keep stable legacy identities for profiles, competencies, COCs, missions, achievements, badges, and preferences.
- Add normalized class, TESDA-version, published-version, attempt, evidence, revision, release, bypass, gamification-event, and audit structures.
- Convert profile/progress/leaderboard totals into trusted projections.
- Replace broad RLS helpers/policies with explicit Admin, Instructor, class-owner, enrolled-learner, and own-record predicates.

### Proposed for later deprecation, not deletion

- `simulation_tasks`, `task_results`, `activity_logs`, `reports`, direct leaderboard entries, and versionless criteria.
- Client-authoritative columns on `mission_results` and learner-writable projection columns.
- Firebase integration and mock persistence.

### Tables proposed for removal now

None.

### Columns proposed for removal now

None.

Every suspected obsolete object is `REQUIRES_CONFIRMATION` until the replacement is deployed, references are removed, production data is migrated/backed up, dependencies are rechecked, and rollback is proven.

## Backup status

Status: **PENDING â€” destructive changes blocked**.

- A protected logical-dump directory was prepared outside the repository, but no dump was written because `.env.local` has API credentials and no PostgreSQL `DATABASE_URL`.
- `pg_dump`/`psql` are not installed independently; Supabase CLI is installed but still requires a database URL or a linked project/password.
- The Browser skill could not inspect managed backups because no in-app or external browser is connected.
- Supabase MCP catalog queries are not a substitute for a recoverable logical/data backup.
- No table/column/data deletion will be attempted until a database connection URL or a confirmed managed restore point is available.

## Baseline validation

| Check | Result |
|---|---|
| Next.js `pnpm build` | Pass; 27 static pages generated |
| Next.js `pnpm exec tsc --noEmit` | Pass after build regenerated stale `.next/types` |
| Flutter `flutter analyze --no-pub` | 0 errors, 10 warnings, 354 info findings |
| Flutter widget test | Blocked: Windows Developer Mode/symlink support required for plugin build |
| Live DB mutation test | Deliberately not run; `db_test.dart` mutates production |

The first Flutter test invocation refreshed five transitive entries in `pubspec.lock` before Windows blocked plugin compilation. No application source was changed by that command.

## Principal risks and gates

| Risk | Severity | Required control |
|---|---|---|
| Learner can alter profile role/status and authoritative-looking scores | P0 | Coordinated RLS/RPC cutover; deny direct writes |
| Anonymous owner-privileged views | P0 | Revoke anonymous grants; replace with security-invoker/scoped queries |
| Web authentication is synthetic | P0 | Supabase SSR Auth; server-side role/object verification |
| Duplicate/unverifiable legacy results | P0 data integrity | Preserve, flag, import as legacy, never treat as final TESDA evidence |
| No approved TESDA source/rubric | P0 academic validity | Keep source/rubric pending; block official finalization |
| No recoverable project backup confirmed | P0 migration safety | No destructive DDL/DML |
| RLS tightening can break current Flutter direct writes | P1 rollout | Deploy narrow RPCs and client changes together with reversible migration |
| Firebase data state is not externally inventoried | P1 migration | Trace collections/config and export any required records before removal |
| Two Auth users lack profiles | P1 identity | Reconcile via safe idempotent migration; do not infer roles |
| Analyzer/asset/Windows test issues | P1 quality | Fix warnings/assets and enable a supported CI/test environment |

## Checkpoint A outcome

The architecture decision and live dependency inventory are complete. It is demonstrably safe to proceed with **additive, reversible** identity/class/TESDA/attempt foundation migrations and coordinated application code. It is **not** demonstrably safe to drop or rewrite any legacy table/column or to remove Firebase until the remaining backup and data-trace gates are satisfied.

