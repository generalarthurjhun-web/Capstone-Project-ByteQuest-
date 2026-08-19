# Capstone Foundation Implementation Report

Project: **A Gamified Simulation Platform with Automated Skill Evaluation for NC II Computer Systems Servicing**  
Implementation date: 2026-08-07 to 2026-08-08  
Report status: foundational architecture implemented and tested; official TESDA activation remains human-gated

## 1. Executive Summary

ByteQuest now uses Supabase as the shared identity and authoritative domain platform for the Flutter learner application and the Next.js staff dashboard. Firebase production integration, mock authentication, dummy dashboard/report data, client-authoritative assessment writes, and the operational merged Instructor/Admin role were removed.

The database now supports class ownership, historical enrollment, approved-source/content/rubric versions, assignments, idempotent attempts, ordered action evidence, criterion results, append-only score revisions, finalization, release, access-only COC bypass, exactly-once gamification events, resources/settings metadata, and trusted audit events. RLS is enabled on every public table and sensitive transitions execute through scoped RPC/server boundaries.

No official TESDA rule was invented. The reviewed official documents establish the qualification/COC structure but do not supply a project-ready numeric passing or weighting rule. The production database therefore has zero active TESDA sources and zero approved real rubrics, and official assessment publication fails closed pending human confirmation.

No production history was deleted. A verified direct database backup could not be created because no direct database connection string was available to `pg_dump`/`psql`; all destructive cleanup was therefore deferred.

## 2. Architecture Before

| Surface | Previous condition |
|---|---|
| Flutter | Supabase plus SharedPreferences, but client code wrote score, pass, progress, XP, badges, achievements, and leaderboard state |
| Next.js | Firebase browser SDK, synthetic/localStorage authentication, merged `instructor_admin`, and dummy/random operational data |
| Identity | Mobile and web did not share a trusted session/role authority |
| Authorization | Broad staff helpers and UI-only checks; no class ownership/enrollment boundary |
| Assessment | Versionless/hard-coded client evaluation, no ordered evidence, no provisional/final/released lifecycle |
| TESDA | No source/version traceability; unverified 75% and weight/rating values existed |
| Classes | No authoritative class, membership, assignment, or Instructor scope model |
| History | 28 client-authored results, no criterion/task evidence, duplicate logical submissions |

The full baseline is in `docs/CHECKPOINT_A_ARCHITECTURE_DATABASE_INVENTORY.md` and `docs/CHECKPOINT_A_COLUMN_INVENTORY.md`.

## 3. Architecture After

```text
Supabase Auth -> profiles (active account + learner/instructor/admin)
                         |
          +--------------+---------------+
          |                              |
  Admin governance              Instructor-owned classes
                                         |
                         memberships -> assignments
                                         |
TESDA source -> module/activity/rubric versions
                                         |
Flutter learner -> attempt -> ordered action evidence
                                         |
                    database-derived criterion evaluation
                                         |
                     provisional append-only revision
                                         |
                    Instructor review -> finalization
                                         |
                                result release
                                         |
                  learner progress + gamification event

High-impact transitions -> trusted audit_events
```

Next.js uses Supabase cookie sessions, server profile checks, scoped server routes, and RLS-aware queries. Flutter uses assigned-content reads and narrow RPCs; it does not send an authoritative score, outcome, or reward.

## 4. Database Before

The live `public` schema contained 19 tables, 2 views, 13 Auth users, 11 profiles, 28 mission results, and 141 learner-progress rows. All 28 results lacked task/criterion evidence. Sixteen duplicate logical result identities were found. No class, enrollment, assignment, TESDA source, rubric version, attempt, action, revision, release, bypass, or trusted audit model existed. Storage had zero buckets and objects.

Existing migration history had only four live records without matching repository SQL, so the legacy schema was not reproducible from source.

## 5. Database After

The authorized project now has:

- 38 public tables (19 preserved + 19 added);
- 2 preserved legacy views;
- 71 public functions plus 9 private helper functions;
- 29 triggers;
- 43 RLS policies;
- RLS enabled on 38/38 public tables;
- 17 ordered repository migration files for this implementation;
- zero active TESDA sources and zero approved real rubrics;
- all 28 legacy results preserved and represented in quarantine;
- zero merged-role profile rows.

No test fixtures remained after the rollback-only E2E test.

## 6. Tables Added

Nineteen additive tables were created:

1. `audit_events`
2. `classes`
3. `class_memberships`
4. `tesda_sources`
5. `module_versions`
6. `activity_versions`
7. `rubric_versions`
8. `rubric_criteria`
9. `assignments`
10. `attempts`
11. `attempt_actions`
12. `criterion_results`
13. `score_revisions`
14. `result_releases`
15. `coc_bypasses`
16. `gamification_events`
17. `learning_resources`
18. `system_settings`
19. `legacy_result_quarantine`

## 7. Tables Modified

- `profiles`: account deactivation provenance and stricter role/account constraints were added; client authority was reduced through RLS/RPC boundaries.
- `competencies`: optional TESDA source linkage and source trace were added.
- Existing domain tables received replacement/scoped RLS policies or grant changes where required; their production rows were preserved.

## 8. Tables Removed

None. Backup and destructive-change gates were not satisfied.

Objects proposed only for future deprecation/confirmation are documented in `docs/SCHEMA_CLEANUP_REPORT.md`.

## 9. Columns Added

| Table | Columns |
|---|---|
| `profiles` | `deactivated_at`, `deactivation_reason`, `deactivated_by` |
| `competencies` | `tesda_source_id`, `source_trace` |

All new tables include their own constrained identity, provenance, state, source, and timestamp columns as defined by the migrations.

## 10. Columns Modified

- `profiles.role`: the physical enum label `instructor_admin` was safely renamed to `legacy_instructor_admin`; a constraint and trusted functions reject it.
- `profiles.status`: the `deactivated` enum value and corresponding provenance constraint were added.
- Existing score/progress columns were not rewritten into trusted values; legacy rows remain historical/untrusted and the new lifecycle is authoritative.

## 11. Columns Removed

None.

## 12. Data Migration Performed

- All 28 legacy mission results were inventoried in `legacy_result_quarantine` without altering the originals.
- Duplicate identities and evidence gaps were retained as quality metadata.
- No legacy result was promoted into an authoritative attempt because final totals without chronological or criterion evidence cannot prove competency.
- Existing profiles were preserved; there were zero merged-role rows to migrate.
- Test-only source/class/attempt data used for lifecycle validation was rolled back.

## 13. Supabase RLS Policies

The 43 policies implement these boundaries:

- learners: own allowed profile fields, enrolled classes/assignments, own attempt/evidence workflow, and own released results;
- instructors: owned classes, memberships, assigned learners, related attempts/evidence, permitted review/finalization/release, class resources, and class analytics;
- admins: account/access governance, TESDA source governance, system settings, global audit/report visibility where authorized;
- service/trusted evaluation: criterion and provisional-result writes through protected functions/service execution;
- clients: no direct authoritative score, release, audit-actor, or gamification-event mutation.

RLS recursion found during testing was fixed in `20260807104000_fix_rls_policy_recursion.sql`.

## 14. Authentication Changes

- Supabase Auth is the only production identity provider.
- Next.js Firebase SDK/configuration, browser CRUD service, mock login, and localStorage session flag were removed.
- Web sessions use Supabase SSR cookies and server-side profile/account checks.
- New accounts default safely to learner; Admin creates staff/learner accounts through a server-only route and then invokes an audited role-change RPC.
- Flutter validates active account state and learner role before entering learner navigation.
- Secrets remain server-side; service-role credentials are not exposed to browser or Flutter code.

## 15. Instructor/Admin Separation

Operational roles are now `learner`, `instructor`, and `admin`.

Instructor pages and RPCs are class-scoped and cover teaching workflows. Admin pages and RPCs cover accounts, source governance, settings, system analytics, and audit visibility. Route checks supplementâ€”not replaceâ€”RLS and function-level scope checks.

The old enum value remains only as the rejected label `legacy_instructor_admin` to avoid a destructive enum rebuild and retain rollback capability. No application role type or trusted function permits its assignment.

## 16. TESDA Source Status

Status: **TESDA SOURCE REQUIRES HUMAN CONFIRMATION**.

Official TESDA Training Regulations and four COC Self-Assessment Guides were reviewed and hashed. The Training Regulation is marked amended December 2013; the current COC SAGs identify revision `00` dated `03/01/17`. An official download also labels a separate combined package `(Old)`, so the project must not choose or activate an edition silently.

The detailed source record and hashes are in `docs/TESDA_SOURCE_VALIDATION_STATUS.md`. No numeric pass threshold, weighting, safety percentage, COC points, XP, or leaderboard formula was found in the reviewed official documents.

## 17. Assessment Architecture

- Assignment binds a class, immutable activity version, andâ€”when assessmentâ€”an approved rubric version.
- Attempt binds learner, class, assignment, module/activity/rubric versions, timestamps, status, and idempotency keys.
- `attempt_actions` preserves chronological evidence with unique sequence identity.
- The database evaluator accepts only an attempt ID, reads ordered evidence plus the immutable approved rubric contract, and creates criterion-level observations/results plus the automated provisional revision in the submission transaction.
- The mobile app records behavior but cannot declare correctness or competency authoritatively.
- Practice interactions may show local feedback, but official decisions remain pending until trusted evaluation and Instructor release.

The old sequence logic was corrected: matching a final set is insufficient when order matters.

## 18. Score Finalization Lifecycle

1. Trusted evaluation appends a provisional automated revision.
2. Instructor opens the learner attempt and reviews ordered evidence plus criterion results.
3. Any permitted adjustment requires a reason and creates a new revision.
4. Instructor finalization creates/marks the final immutable revision.
5. Release is a separate audited, idempotent operation.
6. Learner queries expose only the current released result.
7. Progress and gamification derive from the release exactly once.

Historical revisions are not overwritten.

## 19. COC Bypass

`coc_bypasses` records learner, class, module version, Instructor, reason, time, scope, and revocation state. The grant function verifies Instructor ownership and active membership. An active learner RPC exposes the module's published activities as practice-only content in Flutter. The enforced effect is `UNLOCK_ACCESS_ONLY`; it never supplies an attempt, score, competency, pass, points, XP, badge, or reward.

## 20. Mobile/Web Integration

- Flutter lists real active assignments visible through learner enrollment RLS.
- Flutter persists learner-and-assignment-scoped start/submission keys before the first RPC, resumes the recorded evidence sequence after retry/restart without shared-device crossover, appends ordered evidence, and submits through idempotent RPCs.
- Instructor web pages query the same attempts, criterion results, and revisions.
- Instructor actions finalize/release the same record.
- Flutter reads the released revision from Supabase.
- Web analytics and CSV export use authoritative released data.

The entire database path was exercised with rollback fixtures. A real non-fixture production path remains intentionally gated by source/rubric approval.

## 21. Mobile UI Improvements

- Learner dashboards and progress surfaces use real/empty/pending states rather than fabricated metrics.
- Official and practice states are clearly separated in learner copy.
- Unverified pass/XP/competency claims were removed.
- Full-screen enhanced simulation presentation was improved.
- Navigation, timer disposal, and responsive state handling were hardened.
- UI hierarchy follows the ByteQuest design system in `docs/design-system/bytequest/MASTER.md`.

## 22. Drag-and-Drop Improvements

- Target hit areas are enlarged and responsive.
- Assessment destinations do not remain permanently answer-revealing.
- Interaction provides enlarged target hitboxes and immediate hover/accept/reject feedback.
- Zoom/pan and responsive scaling are supported.
- Stable target keys improve widget verification and interaction state.
- A 390x844 widget test verifies a forgiving target of at least 96x300 logical pixels.

## 23. Bugs Fixed

- Duplicate mission/result persistence paths removed; authoritative submission is idempotent.
- Impossible RJ45 answer-key mismatch corrected.
- Final-set sequence checking replaced with chronological evaluation.
- Assumed safety/sequence bonus points removed.
- Conflicting/unverified pass thresholds and client XP rewards neutralized.
- Firebase/Supabase split and fake web authentication removed.
- Mock UID/live-mutating database test removed.
- Fake CSV-import/dashboard/report behavior replaced by real paths or redirects.
- Random sidebar skeleton width removed.
- Missing/unsafe local progress and gamification authority removed.
- Assessment evidence queue now fails submission if a background event write fails.
- Active learner, class, enrollment, assignment, availability, and due-state checks now run again for every evidence append and submission.
- A deterministic database evaluator now derives results from approved rules rather than accepting learner totals.
- Superseded source versions no longer strand attempts that already captured them.
- Instructor bypass now exposes usable practice content without creating an official result.
- Mobile attempt/submission keys now survive process loss and retry.
- Splash timer cancellation and simulation navigation issues fixed.
- Production source was checked for mojibake; no encoded mojibake remains in UTF-8 files.

## 24. Tests Added

Flutter:

- exact/out-of-order/optional/incomplete sequence evaluation;
- COC2 answer-key consistency;
- shared RJ45 component/target sequence;
- drag/drop mobile hit-area behavior;
- application launch and splash rendering.

PostgreSQL:

- rollback-only full lifecycle test covering identity scope, class isolation, membership, operational bypass visibility, attempt/action/submission idempotency, deactivated-membership denial, database-derived exact-sequence evaluation, superseded-source completion, score protection, revisions, finalization, release, exactly-once gamification, audit scope, and learner result visibility.

## 25. Test Results

| Verification | Result |
|---|---|
| `flutter test` | PASS â€” 9/9 |
| `flutter analyze --no-fatal-infos` | PASS â€” 0 errors, 0 warnings; 243 info notices |
| `flutter build apk --debug` | PASS |
| `pnpm exec tsc --noEmit` | PASS |
| `pnpm build` | PASS |
| Impeccable detector | PASS â€” no findings |
| `foundation_lifecycle_rollback.sql` | PASS â€” fixtures rolled back |
| RLS live authorization checks | PASS |
| Supabase security advisor | 0 errors; 34 documented warnings |

## 26. Remaining Known Issues

- Human confirmation of the exact approved TESDA source/rubric is required before official assessment publication.
- A direct `pg_dump` backup was unavailable; destructive cleanup remains blocked.
- Supabase leaked-password protection must be enabled in the project Auth settings.
- `pg_trgm` remains installed in `public` until extension dependencies and rollback safety are verified.
- Thirty-two security-advisor warnings identify intentional authenticated security-definer RPC exposure; these require periodic review as functions evolve.
- Flutter has 243 information-level lint/deprecation notices but no analyzer warning/error.
- Flutter reports future support deprecations for Gradle 8.11.1, AGP 8.9.1, and Kotlin 2.1.0.
- Runtime browser/device visual QA was unavailable; builds, static review, and widget constraints passed.
- Existing legacy results/progress remain quarantined/untrusted rather than erased.
- Smooth outside-target proximity/overlap snapping and comprehensive drag-control screen-reader labels remain incomplete; enlarged targets and hover feedback are present.
- Admin governance, source activation, settings, Storage, and web authorization workflows still need automated browser/database functional coverage beyond type/build checks and the core lifecycle SQL test.

## 27. Remaining P1/P2 Work

P1:

- Obtain written source/rubric approval, register hashes, activate a source, and publish a real versioned module/activity/rubric.
- Execute the named 20-step E2E scenario with real Admin, Instructor, and learner accounts.
- Confirm file types, limits, retention, create the approved Storage bucket/policies, and complete Instructor resource upload/delete UI.
- Confirm permanent account-removal policy and implement a safeguarded Admin-only flow if approved.
- Confirm required report/export formats and automated-review policy.
- Add browser E2E automation for route separation, class management, review/finalization, and governance.
- Add database tests for Admin account/role lifecycle, source activation, global settings, membership UI orchestration, and approved Storage policies.

P2:

- Resolve Flutter informational lints and upgrade Gradle/AGP/Kotlin together.
- Add more device sizes/orientations, explicit screen-reader labels for every draggable/target, outside-target overlap tolerance/snap animation, and performance profiling for complex simulations.
- Evaluate optional AI-assisted quiz authoring only after approved human-review and content-governance rules exist.
- Perform backup/restore rehearsal and then reconsider deprecated legacy tables/columns.

## 28. PRD Requirements Improved

The implementation materially improves the P0 PRD baseline for:

- one shared platform and data model;
- independent learner, Instructor, and Admin workspaces;
- trusted authentication and backend authorization;
- LMS-lite class/enrollment/assignment management;
- source/version traceability;
- evidence-based automated assessment architecture;
- Instructor review, justified adjustment, finalization, and release;
- access-only COC bypass;
- real scoped analytics/reporting;
- mobile simulation zoom, responsive drag/drop, and answer-hiding;
- auditability, idempotency, and historical preservation.

Requirements dependent on missing policy decisions remain visibly gated rather than simulated.

## 29. Objective Traceability

| Study objective | Implemented support | Status |
|---|---|---|
| Scenario-based 2D simulation | Existing interactive identification, drag/drop, procedure, configuration, and troubleshooting activities preserved and hardened | Improved |
| Gamification | Competency separated from append-only/idempotent motivational events; unverified reward formulas disabled | Foundation complete; formula pending approval |
| TESDA-aligned competency modules | Official sources reviewed; source/module/activity/rubric version chain implemented | Architecture complete; activation pending human confirmation |
| Automated skill evaluation | Ordered action evidence, database rule evaluator, criterion results, provisional revision, Instructor review/final/release lifecycle | Engine complete; production rules pending approved rubric |
| Performance analytics dashboard | Mobile learner released-result/progress views and real class/system web queries/reports | Integrated foundation complete |

The product remains supplementary and does not claim official TESDA certification authority.

## 30. Panel Recommendation Status

| No. | Recommendation | Status |
|---:|---|---|
| 1 | Grading/modules based on TESDA booklet | Architecture/source research complete; rule activation requires human confirmation |
| 2 | Separate Instructor system; Admin internal | Implemented with independent routes, types, RLS, and RPC scopes |
| 3 | Instructor bypass COC 1-4 | Implemented as audited access-only bypass |
| 4 | Zoom during demonstration | Implemented in simulation viewing |
| 5 | Remove drag/drop boxes | Implemented for assessment mode; targets reveal feedback contextually |
| 6 | Points based on TESDA standards | No value invented; motivational scoring disabled pending an approved source/rule |
| 7 | Instructor checks/edits/finalizes score | Implemented with evidence review and append-only justified revisions |
| 8 | AI-generated Instructor quizzes if suitable | Deferred P2; approval/review policy is not defined |
| 9 | Instructor classes/enrollment; Admin access | Implemented foundation and real web workflows |
| 10 | Instructor files/student monitoring | Monitoring and resource metadata/security foundation implemented; Storage limits/upload UI remain P1 |
| 11 | Instructor deactivates; Admin removes | Class-scoped deactivation and Admin account governance implemented; permanent deletion awaits approved safeguards |
| 12 | Video or text scenario activities | Versioned payload/delivery foundation supports content modes; governed file delivery remains P1 |
| 13 | More interaction than drag/drop | Existing identification, procedure, configuration, and troubleshooting modes preserved |
| 14 | Minimize logos and figures | Mobile hierarchy/full-screen simulation simplified; Impeccable detector returned no findings |

## Final Readiness Decision

The shared identity, role, class, assessment, audit, and integration foundation is implemented, migration-driven, and rollback-tested. It is appropriate for continued capstone development and controlled practice use.

It is **not yet approved for official TESDA-aligned result production**. The next authorized action is to confirm and register the exact approved TESDA/rubric package, then run the real end-to-end scenario. Destructive legacy cleanup must wait for a verified backup and cutover evidence.

