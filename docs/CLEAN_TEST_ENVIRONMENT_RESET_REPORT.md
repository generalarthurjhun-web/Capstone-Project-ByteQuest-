# ByteQuest Clean Test Environment Reset Report

Date: 2026-08-15 (Asia/Manila)  
Scope: Linked ByteQuest Supabase project, Auth, public application data, private learning-resource Storage, Flutter learner app, and Next.js Instructor/Admin dashboard.

## Safety decision

The connected project was verified as the intended ByteQuest development/UAT environment before cleanup. Evidence included the linked project identity, the repository's canonical demo-account provisioning script, 184 controlled `@bytequest-uat.invalid` / `@bytequest-e2e.invalid` fixture profiles, disposable lifecycle classes and attempts, and no Storage objects representing real learner files.

No schema reset, migration repair, historical migration deletion, policy change, RPC/function deletion, trigger deletion, bucket deletion, or authoritative academic-data deletion was performed.

The canonical accounts were resolved from `scripts/provision-dashboard-demo-accounts.mjs`, rather than guessed from the presence of multiple legacy staff fixtures:

| Role | Email | Auth user ID | Profile ID | Final state |
|---|---|---|---|---|
| Admin | `admin@dnsc.edu.ph` | `ed0f391a-cf1c-418f-9003-2a6ba9541ec8` | `8f3ddbee-4547-4837-a17e-a08aba575b05` | Preserved, active |
| Instructor | `instructor@dnsc.edu.ph` | `2b3d9027-3eb8-4bb6-88c2-969c9f957a12` | `34ceaea4-45e3-493a-b714-71b2bf23f023` | Preserved, active |

## Backup and recovery evidence

A native linked `pg_dump` could not run because Docker Desktop was unavailable. No database mutation was allowed to proceed until an alternative snapshot had completed successfully.

The validated pre-cleanup snapshot was generated locally and is not part of the cleaned source tree.

It contains 46 public-table JSON exports, 9,899 rows, Auth metadata for all discoverable users, metadata for two Auth-only users, Storage object inventory/bytes, per-table SHA-256 hashes, and a manifest. Passwords, tokens, private signed URLs, and service credentials were deliberately excluded. Auth passwords are not recoverable from this snapshot and would need to be re-established through Supabase Admin Auth.

The final clean-baseline snapshot was generated locally and is not part of the cleaned source tree.

These generated backup directories were removed during repository cleanup; the report retains the recorded inventory and recovery limitations without carrying personal test data in the source tree.

## Before-cleanup inventory

| Entity | Count before | Dependency / cleanup treatment |
|---|---:|---|
| Auth users | 205 | 203 removed through Admin Auth API; canonical two retained |
| Profiles | 203 | 201 disposable profiles removed through Auth cascading lifecycle; canonical two retained |
| Admin profiles | 23 | One canonical Admin retained; 22 legacy/test Admin profiles removed |
| Instructor profiles | 100 | One canonical Instructor retained; 99 legacy/test Instructor profiles removed |
| Learner profiles | 80 | All removed |
| Classes | 55 | Removed after dependent attempts, assignments, resources, and memberships |
| Enrollments / memberships | 68 | Removed after transactional learner records |
| Assignments | 166 | Removed after attempts and quiz assignment dependencies |
| Mission attempts | 325 | Removed after evidence/results/revisions/releases |
| Mission evidence (`attempt_actions`) | 3,335 | Removed before attempts |
| Criterion results | 1,638 | Removed before attempts |
| Score revisions | 514 | Removed before criterion/attempt parents |
| Result releases | 175 | Removed before score revisions/attempts |
| Legacy mission results | 28 | Test-only compatibility rows removed |
| Legacy result quarantine | 28 | Test-only migration evidence removed after snapshot |
| Quizzes | 16 | All were disposable development/fixture content and were removed |
| Quiz versions | 25 | Removed dependency-first |
| Quiz items | 29 | Removed with history-protection trigger scoped only to the guarded transaction |
| AI quiz generation rows | 13 | Disposable test generations removed |
| Quiz assignments | 0 | Already empty |
| Quiz attempts / answers / results | 0 / 0 / 0 | Already empty |
| Learner progress | 317 | Derived test progress removed |
| Gamification events | 176 | Transactional test events removed; configuration retained |
| Leaderboard entries | 3 | Derived test entries removed |
| User achievements / badges | 0 / 0 | Already empty; definitions retained |
| Notifications | 0 | Already empty |
| Learning-resource records | 16 | Obsolete test metadata removed |
| Storage objects | 0 | Bucket was already physically empty |
| Audit events | 2,490 | Exported and preserved; not blindly deleted |

Reference/configuration records retained include 5 achievement definitions, 7 badge definitions, 8 levels, 4 competencies, 4 module versions, 20 activity versions, 20 rubric versions, 80 assessment criteria, 98 versioned rubric criteria, and the active TESDA source.

## Dependency-aware cleanup procedure

The guarded SQL cleanup in `scripts/clean-test-environment.sql`:

1. Requires exact canonical account UUID, email, role, and active-state matches.
2. Requires either the exact two-account baseline or only controlled UAT/E2E-domain profiles in addition to those accounts.
3. Requires exactly 4 COCs, 20 missions, 20 activity versions, and 98 rubric criteria before and after cleanup.
4. Reassigns only retained academic-version actor foreign keys from disposable fixture actors to the canonical Admin.
5. Records a reset audit event and preserves all existing audit history.
6. Removes quiz results/answers/attempts/assignments/items/generations/versions/quizzes.
7. Removes releases, revisions, criterion results, ordered evidence, and mission attempts.
8. Removes assignments, bypass fixtures, compatibility results, progress, learner gamification, notifications, reports, settings, resources, memberships, and classes.
9. Temporarily disables only append-only/history-protection triggers needed for this owner-authorized cleanup transaction and re-enables them before commit.
10. Verifies the clean transactional counts and authoritative foundation before committing.

Obsolete Auth users were removed by `scripts/delete-obsolete-auth-users.mjs --execute` through the Supabase Admin Auth API. Two malformed legacy Auth records had null GoTrue token-string fields; only those exact records were normalized to GoTrue's empty-string invariant so the authorized Admin API could delete them. Two Auth-only users with no public profile were separately inventoried, backed up, and deleted. No canonical credentials, roles, identities, or password values were changed.

## Final baseline

| Entity | Final count |
|---|---:|
| Auth users | 2 |
| Profiles | 2 |
| Active Admin accounts | 1 |
| Active Instructor accounts | 1 |
| Learner accounts | 0 |
| Classes | 0 |
| Memberships | 0 |
| Assignments | 0 |
| Mission attempts | 0 |
| Mission evidence | 0 |
| Criterion results | 0 |
| Score revisions | 0 |
| Result releases | 0 |
| Quiz definitions / versions / assignments | 0 / 0 / 0 |
| Quiz attempts / answers / results | 0 / 0 / 0 |
| Learner progress | 0 |
| Learner gamification events | 0 |
| Learner notifications | 0 |
| Learning-resource records / Storage objects | 0 / 0 |
| COCs | 4 |
| Authoritative missions | 20 |
| Published/versioned mission activities | 20 |
| Versioned rubric criteria | 98 |
| Rubric versions | 20 |
| TESDA sources | 1 |

The final snapshot contains 2,742 preserved audit events. The increase from the initial 2,490 is expected: the authenticated security/lifecycle regression runs and two owner-authorized cleanup operations were auditable. No learner transaction, class, resource, quiz, result, progress, or reward row remains.

## Orphan, authorization, and Realtime verification

- Auth/profile orphan checks: zero after removal.
- Attempt/assignment, action/attempt, membership/class, and resource/class orphan checks: zero.
- All relevant application tables still have RLS enabled.
- Append-only/protection triggers are enabled after cleanup.
- Realtime publication membership remains configured for profiles, classes, memberships, assignments, attempts, attempt results/revisions/releases, quiz assignments/attempts/results, learning resources, notifications, user settings/achievements, audit events, and TESDA sources.
- The private `learning-resources` bucket remains present and private; it contains zero objects.
- Canonical Admin and Instructor authenticated sessions were established without changing their passwords.
- Correct-role analytics RPCs succeeded; cross-role analytics calls and anonymous calls were denied.
- Both canonical accounts reached Realtime `SUBSCRIBED` state.

## Production fake-data audit

Production code under `src`, `ByteQuest Mobile App/lib`, and `public` was searched for `Math.random`, `MOCK_*`, `DUMMY_*`, known fake learner/test identities, fake XP/results, dummy analytics, placeholder notifications, and sample achievements. No production fake-data signature was found. The remaining uses of `placeholder` are legitimate form input hints or explicit truthful no-placeholder copy, not data fallbacks.

The dashboard data loaders use authoritative queries/RPCs; therefore the clean database produces truthful zero/empty states rather than sample learner values. No source removal was necessary in this pass.

## Regression and smoke evidence

| Verification | Result |
|---|---|
| Flutter unit/widget tests | PASS â€” 48/48 |
| Flutter analyzer | PASS â€” exit 0; 214 legacy informational notices, no errors/warnings |
| Android debug APK | PASS â€” `app-debug.apk` built |
| TypeScript | PASS â€” `pnpm exec tsc --noEmit` |
| ESLint | PASS â€” no warnings/errors |
| Next.js production build | PASS |
| Analytics/reporting tests | PASS â€” 4/4 |
| OpenRouter contract tests | PASS â€” 6/6 |
| Authenticated RBAC/boundary smoke | PASS |
| Learner quiz lifecycle E2E | PASS â€” authorization, hidden answers, resume, exactly-once submit, result scope, cleanup |
| Scoped Realtime E2E | PASS â€” enrollment, assignment, mission submission, release, resource isolation |
| COC1 authoritative lifecycle batch | PASS â€” 5/5 missions |
| COC2 remaining lifecycle batch | PASS â€” 4/4 missions |
| COC3 authoritative lifecycle batch | PASS â€” 5/5 missions |
| COC4 authoritative lifecycle batch | PASS â€” 5/5 missions |
| COC2 Mission 2 golden lifecycle | PASS |
| Authenticated production server-route smoke | PASS â€” Admin sidebar, role boundaries, analytics/reports/quizzes, resources, Admin safeguards |
| Linked database lint | PASS â€” one non-blocking warning for unused `get_rating(p_score)` parameter |
| Final post-regression cleanup and verification | PASS â€” exact two-account/zero-learner baseline restored |

The SQL `pg_prove` rollback harness was not run because its isolated test-role fixture setup still requires a privileged test-only initialization path. Production RLS was not weakened to satisfy that harness. Equivalent live boundary, cross-user, anonymous-denial, idempotency, lifecycle, resource, quiz, and Realtime checks passed against the linked test project.

An Android emulator was intentionally not started during this cleanup pass. Flutter compilation, tests, Auth/backend smoke, and the APK build passed; final human device login and visual empty-state inspection remain part of the fresh manual acceptance sequence.

## Recommended fresh manual test sequence

1. Login as Instructor.
2. Create a new class.
3. Create one new learner account through the authorized workflow.
4. Enroll the learner in the new class.
5. Assign a module and authoritative mission.
6. Create/publish and assign one quiz.
7. Upload and assign one private resource.
8. Login on Mobile as the learner.
9. Verify the class, assignment, quiz, and resource appear.
10. Complete an interactive 2D mission.
11. Review and submit evidence.
12. Verify the Instructor Realtime Review Queue update.
13. Review, finalize, and release from the Instructor dashboard.
14. Verify Mobile receives the released result.
15. Verify learner progress and Instructor analytics update consistently.
16. Complete the assigned quiz and submit exactly once.
17. Verify quiz result/synchronization and Instructor visibility.
18. Verify Admin sees the correct new system activity.

Record the new class, learner, assignment, attempt, quiz attempt, release, and resource IDs in the acceptance evidence. Do not reuse historical fixture identities.

## Required final report

```text
ENVIRONMENT VERIFIED AS TEST/DEVELOPMENT: YES

BACKUP/SNAPSHOT CREATED: YES

AUTH USERS BEFORE: 205
AUTH USERS AFTER: 2

ADMIN ACCOUNTS RETAINED: 1 â€” admin@dnsc.edu.ph
INSTRUCTOR ACCOUNTS RETAINED: 1 â€” instructor@dnsc.edu.ph
LEARNER ACCOUNTS REMOVED: 80

CLASSES REMOVED: 55
ENROLLMENTS REMOVED: 68
MISSION ATTEMPTS REMOVED: 325
MISSION EVIDENCE REMOVED: 3,335
ASSESSMENT RESULTS REMOVED: criterion results 1,638; revisions 514; releases 175; legacy mission/quarantine rows 56
QUIZ ATTEMPTS/RESULTS REMOVED: 0/0 (already empty); 16 disposable quizzes, 25 versions, 29 items, and 13 AI-generation rows removed
PROGRESS RECORDS REMOVED: 317
GAMIFICATION TEST RECORDS REMOVED: 176 events and 3 derived leaderboard entries
NOTIFICATIONS REMOVED: 0 (already empty)
TEST RESOURCES REMOVED: 16 database records
STORAGE OBJECTS REMOVED: 0 (bucket already empty)
ORPHAN RECORDS FOUND/FIXED: 2 Auth-only users removed; 2 malformed legacy Auth records normalized only to permit authorized deletion

AUTHORITATIVE COCs PRESERVED: 4/4
AUTHORITATIVE MISSIONS PRESERVED: 20/20
VERSIONED CRITERIA PRESERVED: 98/98
TESDA/RUBRIC PROVENANCE: PASS
RLS/RBAC PRESERVED: PASS
REALTIME PRESERVED: PASS

HARDCODED/FAKE PRODUCTION DATA FOUND: 0 matching production signatures
HARDCODED/FAKE DATA REMOVED: 0 â€” none required

ADMIN LOGIN: PASS
INSTRUCTOR LOGIN: PASS
MOBILE CLEAN STATE: PASS (automated data/service/widget/build evidence; human device visual check remains)
INSTRUCTOR WEB CLEAN STATE: PASS (zero-data RPC plus authenticated production-route evidence)
ADMIN WEB CLEAN STATE: PASS (zero-data RPC plus authenticated production-route evidence)

FLUTTER TEST: PASS â€” 48/48
FLUTTER ANALYZE: PASS â€” exit 0; 214 informational legacy notices only
APK BUILD: PASS
TYPESCRIPT: PASS
ESLINT: PASS
NEXT.JS BUILD: PASS
SECURITY/RLS TESTS: PASS â€” live authenticated/cross-role/anonymous/lifecycle suites; pg_prove rollback harness BLOCKED
REALTIME TESTS: PASS

KNOWN ISSUES: Non-blocking database lint warning for unused get_rating(p_score); Kotlin 2.1.0 upgrade warning for future Flutter support
BLOCKED TESTS: pg_prove rollback harness test-role fixture initialization; human Android visual/login check not run in this pass

CLEAN BASELINE VERDICT:
READY FOR FRESH END-TO-END TEST
```

