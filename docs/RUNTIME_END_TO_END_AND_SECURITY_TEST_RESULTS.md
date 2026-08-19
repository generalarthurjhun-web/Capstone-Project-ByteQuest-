# Runtime End-to-End and Security Test Results

**Date:** 2026-08-10  
**Environment:** Authorized live Supabase project plus local Next.js production server; disposable identities only  
**Verdict:** All-mission authenticated API/database/server-route journey PASS; Instructor quiz CRUD/AI-draft boundaries PASS; live AI provider generation and the recorded human-operated Flutter/browser journey remain UNVERIFIED

## Executed suites

| Suite | Result | Evidence |
|---|---|---|
| `scripts/verify-all-mission-packages-live.mjs` | PASS | 20 missions, 20 published activities, 20 approved rubrics, 98 required criteria; no learner answers/rules; all-required/non-numeric |
| `scripts/authenticated-all-missions-lifecycle-e2e.mjs` â€” COC2 remainder | PASS â€” 4/4 missions, 8 attempts | Correct and incorrect/missing evidence, lifecycle, isolation, exact-once behavior |
| Same suite â€” COC1 | PASS â€” 5/5 missions, 10 attempts | Full mission contract and lifecycle matrix |
| Same suite â€” COC3 | PASS â€” 5/5 missions, 10 attempts | Full mission contract and lifecycle matrix |
| Same suite â€” COC4 | PASS â€” 5/5 missions, 10 attempts | Full mission contract and lifecycle matrix |
| `scripts/authenticated-boundary-smoke.mjs` | PASS â€” 23/23 groups | Five identities, UUID linkage, RLS/RBAC negatives, class isolation, private Storage, deactivation, quiz ownership/role denial, anonymous denial, audits, cleanup |
| `scripts/authenticated-coc2-lifecycle-e2e.mjs` | PASS â€” 14/14 groups | Golden COC2 chain, exact sequence, exact-once evaluation/reward, revisions/finalization/release, analytics, audits |
| `scripts/authenticated-quiz-authoring-e2e.mjs` | PASS â€” 11/11 groups | Manual quiz CRUD, approval/publish gates, structured AI-draft database contract, rejection reason, immutable published items, version retirement, RLS, audit, archive/history |
| `scripts/authenticated-server-route-smoke.mjs` | PASS â€” 7/7 groups | Real Supabase SSR cookies, protected page/role routing, Instructor quiz workspace, missing AI key fail-closed, Storage routes, Admin provisioning/removal, cleanup |
| `foundation_lifecycle_rollback.sql` | PASS and rolled back | Evaluator, class isolation, idempotency, exact sequence, lifecycle, superseded source, bypass, audit, released-only visibility |
| `storage_and_account_hardening_rollback.sql` | PASS and rolled back | Storage and Instructor learner-deactivation invariants |
| `governance_safeguards_rollback.sql` | PASS and rolled back | Admin lifecycle/removal readiness and audit immutability |

### Non-product invocation incidents (resolved)

- One server-route run saw `/attempts` return HTTP 500 after `next build` and the already-running dev server shared a stale `.next` state. The exact Node listener was restarted; no application change was made for this incident.
- The server-route harness defaults to port 3100, while this dashboard is intentionally running on port 3000. One invocation therefore returned `fetch failed`; rerunning with `BYTEQUEST_WEB_BASE_URL=http://127.0.0.1:3000` passed all seven groups.
- One quiz harness invocation omitted its required demo-password environment input and exited before creating data. Rerunning with the existing disposable/demo Instructor credential passed 11/11.
- After provider packages changed, one post-migration server-route run encountered a stale `.next` development cache and returned HTTP 500 for `/quizzes`; restarting the exact local listener resolved it and the rerun passed all 7/7 groups.
- One ad hoc grounded-detail assertion looked for an exact client-component button string in the initial SSR payload and failed even though the response was HTTP 200 and source/activity/provider context was present. The test-only quiz was archived; the stable SSR assertions for TESDA edition, approved activity, and OpenRouter context passed.
- On 2026-08-11, one server-route invocation used the harness default port `3100` while the dashboard was running on `3000`; it failed with `fetch failed`, cleaned all disposable fixtures, and was rerun with the correct explicit base URL. Run `bq-route-e2e-20260811034600-c67ff5fe` then passed 7/7 groups. This was an invocation configuration error, not a product defect.

These incidents are retained here so the record does not hide failed command invocations. None represented a reproduced authorization, data-integrity, or product-runtime defect.

Successful batch run identifiers:

- COC2 M1/M3/M4/M5: `bq-coc2-missions-20260810071935-551241c4`.
- COC1 M1â€“M5: `bq-coc1-missions-20260810072022-7937b6ef`.
- COC3 M1â€“M5: `bq-coc3-missions-20260810072111-285e9273`.
- COC4 M1â€“M5: `bq-coc4-missions-20260810072205-3962a035`.
- Final boundary regression: `bq-e2e-20260810090640-06d1a4de`.
- Final golden COC2 regression: `bq-coc2-uat-20260810072948-61168235`.
- Final quiz lifecycle regression: `quiz-e2e-20260810090505-b6dfbbfb`.
- Final server-route regression: `bq-route-e2e-20260810084952-d29b5651`.

All disposable users were deactivated/Auth-banned and classes/assignments/resources were closed or archived. Immutable attempts and audit evidence were retained intentionally; no real learner record was used.

## Per-mission lifecycle contract

For every newly published mission, the batch harness verified:

1. Version-bound assignment, activity, rubric, and official source.
2. One correct attempt with every criterion satisfied.
3. One deliberately incorrect/incomplete attempt (first criterion wrong, last criterion omitted).
4. Exact chronological comparison for order-sensitive stages.
5. Idempotent attempt start, action retry, submission, and release.
6. Exactly one result row per criterion and one provisional revision.
7. Learner finalization denial and cross-Instructor class/attempt denial.
8. Instructor finalization/release with history preserved.
9. Released learner result, progress, and exactly one gamification event.
10. Real attempt/progress records available to analytics.

## Acceptance journey

| Step | Status | Evidence |
|---|---|---|
| Admin/Instructor/Learner identities | PASS | Real Supabase sessions, matching Auth/profile UUIDs, disposable records |
| Admin/Instructor route boundaries | PASS | Production SSR requests plus server/page guards |
| Class, enrollment, assignment | PASS | Authenticated RPCs for every batch |
| All 20 mission/source/rubric chains | PASS | Published version FKs and live package verifier |
| Learner starts exactly one attempt | PASS | Same start key returns the same attempt; conflicting in-progress start is rejected |
| Ordered evidence recorded | PASS | Sequence numbers retained; action retry exact-once |
| Duplicate submission | PASS | Same key returns the same evaluated state and rows |
| PostgreSQL criterion evaluation | PASS | 98 published rules; correct and wrong/missing cases exercised |
| Learner score/finalize/release writes | PASS â€” denied | Authorization tests reject trusted-boundary violations |
| Instructor review/finalization/release | PASS | Scoped evidence/results, immutable revision, separate idempotent release |
| Learner visibility | PASS | Unreleased protected; current final visible only after release |
| Progress/gamification | PASS | Exactly one event/projection per released attempt |
| Instructor analytics | PASS | Real COC, mission, attempt, final decision, and criterion failure records |
| Admin audit | PASS | Actor, role, action, target, reason/outcome present for critical operations |
| Instructor quiz CRUD/version/review/publish | PASS | Instructor ownership, review states, mandatory rejection reason, approved-items-only publication, immutable published versions, audit |
| AI draft trusted boundary | PASS | Server-only OpenRouter JSON-Schema route, approved activity/TESDA grounding, service-only completion, draft-only insertion, no competency authority, missing-key fail-closed behavior, and real `openrouter/free` generation all pass |

## Security negative matrix

| Caller / attempted operation | Result |
|---|---|
| Learner reads another learnerâ€™s attempt/result | DENIED |
| Learner changes role or authoritative assessment data | DENIED |
| Learner finalizes/releases/grants bypass/creates class | DENIED |
| Instructor accesses another Instructorâ€™s class/assignment/resource/attempt | DENIED |
| Instructor performs Admin governance or self-promotion | DENIED |
| Admin performs routine Instructor finalization | DENIED |
| Anonymous caller invokes protected RPC/page | DENIED |
| Archived resource receives a signed learner URL | DENIED |
| Admin removes active/self/wrong-email/history-blocked account | DENIED and audited where applicable |
| Learner/Admin/other Instructor authors or reads private Instructor quiz answers | DENIED |
| Authenticated user completes/fails an AI generation through service-only RPC | DENIED |

## Live database/security state

- Public tables: 42; RLS enabled: 42; policies: 47.
- Live migrations: 33; repository migration files: 29; the four historical live-only entries remain documented rather than fabricated.
- Supabase security advisor: 0 errors, 50 warnings â€” 48 authenticated-callable `SECURITY DEFINER` RPCs in the reviewed trusted API model (including two read-only analytics aggregators), one `pg_trgm` public-schema placement warning, and leaked-password protection disabled. Trusted RPCs use fixed empty search paths, no anonymous execution, and internal role/object-scope checks.
- The post-audit `quiz_private_function_grant_hardening` migration revoked inherited `EXECUTE` from both private quiz constraint/trigger helpers; direct anonymous/authenticated/service-role checks now all return false, and quiz/boundary regressions remain green.
- Supabase performance advisor: 87 informational findings. These require query/workload review; no blind index churn was performed. The two new analytics indexes are currently reported unused because disposable test workloads are too small/short-lived for representative statistics.

Relevant advisor remediation references: [authenticated SECURITY DEFINER functions](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable), [`pg_trgm` in public](https://supabase.com/docs/guides/database/database-linter?lint=0014_extension_in_public), and [leaked-password protection](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection).

## UI/runtime boundary

The all-mission Mobile workspace is covered by contract/widget tests at compact portrait, landscape, tablet, and 1.8Ã— text scaling; drag and select-item/select-destination produce the same evidence. Flutter compiles and the debug APK builds. The Next server renders protected pages and passes authenticated server routes. The installed Browser skill could not attach because no browser backend/session was available, so a recorded human-operated login and visual mission journey on an actual Flutter target plus browser was not performed. This visual journey is the remaining P0 acceptance-evidence gap, not a database/RBAC/lifecycle failure.

### OpenRouter continuation verification â€” 2026-08-11

- OpenRouter provider contract: 6/6 PASS (default `openrouter/free`, valid structured output, duplicate rejection, sanitized 401 mapping, 429 `Retry-After`, malformed JSON rejection).
- Instructor quiz lifecycle after provider migration: 11/11 PASS (`quiz-e2e-20260811034546-084d5573`).
- Authenticated boundary matrix: 23/23 PASS.
- Authenticated server-route matrix: 7/7 PASS (`bq-route-e2e-20260811034600-c67ff5fe`), including missing-key 503 fail-closed behavior, private Storage, and guarded Admin removal.
- Added `scripts/authenticated-openrouter-quiz-e2e.mjs`. It is a real-provider acceptance harness for COC2 Mission 2 grounding, draft-only generation, Instructor edit/reject/remove/approve, approved-items-only publication, audit provenance, and automatic archival. After the server environment was saved and reloaded, run `openrouter-live-20260811041145-3d5f7bb0` passed all 9 lifecycle groups using `openrouter/free`.
- Browser selection was retried using the installed Browser integration; no browser instance was available, so no visual interaction was fabricated or substituted.
- Authenticated SSR/server-route groups: 7/7 PASS after restarting a stale development server cache.
- Generated `.next/static` scan: zero `OPENROUTER_API_KEY` or `OPENROUTER_MODEL` names and zero exact key-value occurrences in client assets; source reference exists only in `ByteQuest Web Dashboard/src/lib/ai/config.ts`.
- Live provider call: PASS (`openrouter-live-20260811041145-3d5f7bb0`). The key remained server-only and was not printed, logged, documented, returned by an API, or placed in a client bundle.
- The first live run exposed an HTTP 422 grounding defect: the trusted route reloaded approved global rubric content with the Instructor RLS client. The test quiz was archived. The route now verifies Instructor ownership first and uses the existing server-only service client solely for the approved grounding lookup; no RLS policy was weakened. The rerun passed.
- Post-fix authenticated server routes: PASS (`bq-route-e2e-20260811041245-37dbba57`) for all 6 applicable key-enabled groups, including cleanup.

### Web analytics and reporting continuation â€” 2026-08-11

- Applied live read-only migration `scoped_analytics_and_reporting`; repository source is `20260811120000_scoped_analytics_and_reporting.sql`.
- PostgreSQL and PostgREST signatures verified for Instructor/Admin analytics; the API schema cache was explicitly reloaded after migration.
- Authenticated boundary run `bq-e2e-20260811050436-7ac74cb1`: PASS for own-class analytics plus cross-Instructor, Learner, Instructor-to-Admin, and anonymous denials; all disposable records cleaned up.
- Authenticated server-route run `bq-route-e2e-20260811052926-300c2f2d`: PASS against the fresh production build for Instructor Analytics, Reports preview, Admin System Analytics, CSV authorization/content headers, cross-role page denial, private Storage, and Admin removal safeguards.
- `pnpm test:analytics`: 4/4 PASS across all eight report types, dashboard/report count consistency, CSV escaping, and aggregate validation.
- COC2 lifecycle run `bq-coc2-uat-20260811051702-ad3b58df`: 14/14 PASS, including real analytics projection and Admin audit.
- All-mission lifecycle rerun: COC1, COC2, COC3, and COC4 PASS; real attempt/progress analytics sources remained queryable only by the owning Instructor.
- `pnpm test:openrouter`: 6/6 PASS and Instructor quiz governance: 11/11 PASS. The current `openrouter/free` live retry returned malformed provider data, failed closed with no saved question, and safely archived its disposable quiz. A previous live provider lifecycle remains recorded as PASS.
- Impeccable static detector: zero findings. Browser visual QA remains unrecorded because the installed Browser runtime reported no connected in-app or extension browser surface.

### Learner quiz deployment attempt â€” 2026-08-12

- Supabase CLI version: `2.109.1`.
- CLI deployment channel: BLOCKED â€” no `SUPABASE_ACCESS_TOKEN`, no authenticated CLI session, and the repository is not linked to a project.
- Direct PostgreSQL/local channel: BLOCKED â€” no database credential and no running local Supabase Docker engine.
- Dashboard channel: BLOCKED â€” the installed browser integration reported no available browser session.
- Read-only PostgREST capability probe against the configured project returned HTTP `404` / `PGRST202` for `get_available_learner_quizzes`, confirming that migration `20260812120000_learner_quiz_lifecycle.sql` is not live.
- No migration, test fixture, learner record, or production data was changed. The rollback security suite and authenticated quiz E2E were therefore not run, and screens 21â€“23 remain PARTIAL.

### Learner quiz live deployment and acceptance â€” 2026-08-12 (supersedes the blocked attempt above)

- Authorized Supabase CLI session and project link verified for `rslmteqipxqfifwftugk`.
- Applied `20260812120000_learner_quiz_lifecycle.sql` through the authorized linked database channel and reconciled its migration-history entry as applied. Local and remote history now both contain `20260812120000`.
- `supabase/tests/learner_quiz_lifecycle_rollback.sql`: PASS. The transaction rolled back its fixtures and left live application history unchanged.
- Live RLS verification: `quizzes`, `quiz_versions`, `quiz_items`, `quiz_assignments`, `quiz_attempts`, `quiz_answers`, and `quiz_results` all have RLS enabled and an active policy.
- Learner RPC verification: `get_available_learner_quizzes`, `start_learner_quiz`, `save_learner_quiz_answer`, `submit_learner_quiz`, and `get_learner_quiz_result` are `SECURITY DEFINER`, use fixed `search_path=""`, deny anonymous execution, and allow authenticated invocation subject to internal active-profile, enrollment, ownership, publication, and attempt-state checks.
- Supabase security advisor: 0 errors. Its quiz-related items are the generic authenticated-callable `SECURITY DEFINER` warning; object-level checks were exercised by the live negative matrix and no policy/grant was weakened.
- Authenticated run `quiz-learner-e2e-20260812110223-9891ce03`: PASS for all 18 recorded groups, including disposable identities and class scope, draft hiding, publish/assign, authorized list, cross-class isolation, cross-learner denial, answer-key omission, save, same-attempt resume, exact-once submit/result, post-submit immutability, own-result scope, anonymous denial, audit evidence, and exact disposable cleanup.
- The reusable harness now performs its cleanup through a generated mode-0600 temporary SQL file and exact captured UUIDs. This is necessary because production append-only guards correctly prevent ordinary service-role deletion of completed results and published versions; the harness does not weaken those guards.
- Screens 21â€“23 are COMPLETE in `MOBILE_32_SCREEN_COMPLETENESS_AUDIT.md`.

### Authoritative learner-path and mobile continuation â€” 2026-08-12

- Applied and reconciled `20260812130000_learner_learning_path_projection.sql` on the authorized live project.
- The RPC is authenticated-only, `SECURITY DEFINER` with fixed `search_path=""`, and begins with the existing active-Learner guard. It returns no score, answer key, Instructor notes, or learner-selected identity parameter.
- Authenticated run `quiz-learner-e2e-20260812111006-b11487ba`: PASS for all 20 groups. In addition to the quiz matrix, it proved the 20 published mission rows, own-class assignment projection, cross-class practice-only state, anonymous projection denial, and exact disposable cleanup.
- Flutter Learning Path and COC Details now consume assignment/attempt/release/bypass states from that trusted projection; the former client percentage/unlock presentation is not used.
- Progress now exposes real COC â†’ mission lifecycle state and released mission â†’ criterion feedback. Ratios are labeled as released mission counts, never TESDA scores.
- Both authoritative simulation templates now reload their own RLS-scoped ordered evidence on resume and reconstruct the first incomplete stage. Their completion flow opens a pre-submit evidence timeline and explicit confirmation instead of submitting merely because navigation reached the result route.
- `flutter test`: PASS, 36 tests. `flutter analyze --no-fatal-infos`: PASS with 0 errors/warnings and 215 informational legacy notices. Debug APK: PASS.
- The learner quiz rollback security suite passed again after these changes.
- Remaining runtime evidence: an authenticated Android process-kill/relaunch and review/confirm walkthrough is still required before screens 13â€“14 move from PARTIAL to COMPLETE.

### Learner settings and achievements continuation â€” 2026-08-12

- Reused the existing `user_settings` and `user_achievements` truth; no duplicate tables were introduced.
- Applied `20260812132000_learner_settings_update_grant.sql` and `20260812133000_learner_settings_table_update_grant.sql`. The latter supplies the table-level UPDATE privilege required by PostgREST upsert; existing own-row RLS still constrains `USING` and `WITH CHECK` to `auth.uid()`.
- Authenticated run `quiz-learner-e2e-20260812112705-3c180f51`: PASS for 21 groups, including settings persistence, cross-learner settings invisibility, anonymous denial, and cleanup.
- Flutter Settings now loads and saves only implemented notification/sound preferences. Misleading no-op Theme/Language actions were removed.
- Added `/achievements`, which reads only earned `user_achievements` joined to their real definitions and provides truthful loading/error/empty states.

## Current final acceptance rerun â€” 2026-08-13 (authoritative addendum)

This addendum supersedes earlier historical run notes where a capability was
still marked blocked or where a prior test harness reported a different state.
It records the latest verification without changing production data or
weakening any authorization policy.

### Automated product evidence

- Flutter: `flutter test` **PASS (39)**; `flutter analyze --no-fatal-infos`
  **PASS** (exit 0; 215 informational legacy notices); `flutter build apk
  --debug` **PASS**.
- Android release packaging is intentionally fail-closed when
  `android/key.properties` is absent. The normal release command fails with
  the expected missing-signing message. An explicit temporary
  `BYTEQUEST_ALLOW_DEBUG_SIGNING=true` smoke build passes (67.7 MB), but is
  debug-signed and not distributable.
- Web: `pnpm exec tsc --noEmit` **PASS**, `pnpm lint` **PASS**, analytics tests
  **4/4 PASS**, OpenRouter contract tests **6/6 PASS**, and `pnpm build`
  **PASS** (Next.js 15.3.8; 23 static pages).
- Authenticated production-route smoke
  `bq-route-e2e-20260813140311-8d8f4b75`: **PASS** for Admin destinations,
  Instructor/quiz/resource/report routes, scope boundaries, private Storage,
  and account safeguards.
- Live mission/assessment evidence remains green: authenticated boundary
  matrix, COC2 golden lifecycle, all COC1â€“COC4 lifecycle batches, learner
  quiz lifecycle, learning-path projection, settings isolation, achievements,
  and resource authorization. The latest run IDs and exact group counts remain
  in `docs/CAPSTONE_FINAL_OBJECTIVES_AND_DEPLOYMENT_AUDIT.md`.

### Security and database evidence

- `supabase migration list --linked`: **PASS** with the documented historical
  live-only migration drift; the current quiz, learning-path, settings, and
  analytics migrations are present in the live history.
- `supabase db lint --linked`: **PASS** with one non-blocking unused
  `public.get_rating(p_score)` warning.
- The linked rollback SQL suite is still **BLOCKED before TAP output** because
  its isolated `pg_prove` role cannot read fixture rows from `public.profiles`.
  No production grant, RLS policy, or service-role shortcut was added. A
  dedicated test-only fixture path is required before this suite can be marked
  PASS.
- Secret scans found no service-role/OpenRouter key material in browser bundles,
  APK output, source-controlled configuration, logs, or reports. Privileged
  variables remain server-only.

### Manual runtime evidence

- `adb devices` has no attached Android emulator or physical device. Android
  process-kill/relaunch resume, evidence-review confirmation, TalkBack, large
  text, and physical frame-pacing checks are **BLOCKED**, not inferred.
- The installed browser connector reports `No browser is available`. Web
  responsive screenshots and console inspection are **BLOCKED**, not inferred.

The current deployment verdict therefore remains **CONDITIONAL**: automated
functional/security evidence is ready, while the Android/browser human gates,
the isolated rollback fixture, and production release signing remain open.

## Non-device verification rerun â€” 2026-08-14

- No Android emulator was launched, per owner direction.
- Flutter: **39 tests PASS**, analyzer **exit 0** with 215 informational
  notices, debug APK **PASS**.
- Web: TypeScript **PASS**, ESLint **PASS**, analytics **4/4 PASS**,
  OpenRouter contract **6/6 PASS**, Next.js production build **PASS**. A
  temporary built-server smoke check returned HTTP 200 for `/login`; the local
  server was stopped afterward.
- Supabase migration list and lint **PASS**; the latest required migrations
  match live history and the known historical drift remains unchanged.
- The current `supabase db test --linked supabase/tests` attempt is **BLOCKED**
  because the Docker Desktop engine is stopped. Starting the protected service
  was denied by the host. The previously observed test-role fixture read issue
  remains a second harness blocker after Docker availability is restored.
- Browser bundle/APK privileged-key pattern scan: **0 findings**.
- Production fake-data and hard-coded localhost scan: **0 findings**.

No production policy, grant, record, migration history, or assessment result
was modified by this rerun.

