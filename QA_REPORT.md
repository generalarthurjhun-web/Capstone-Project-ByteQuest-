# ByteQuest Mobile QA Audit

## Phase 9  ByteQuest To-do Compliance Audit

Audit date: 2026-08-22 (Asia/Manila)
Acceptance source: `bytequest.md` (authoritative)
Branch: `Dro-branch`
Scope: static catalog audit, reusable-system audit, required Flutter gates, and emulator practice-shell/runtime smoke. No product changes were made for this audit.

### Compliance percentage

The Phase 1 checklist has 15 criteria across 20 missions (300 points). A static pass is 1 point, a partially verified/runtime-blocked item is 0.5, and an absent item is 0. The result is **90% structural compliance (270/300)**. This is not release sign-off: authenticated all-20 manual/backend acceptance remains incomplete.

### Compliance matrix

| Requirement | Status | Evidence/location | Recommended action |
|---|---|---|---|
| 20 mission definitions | ✅ Complete | `mission_simulation_definitions.dart`; `mission_catalog_acceptance_test.dart` exact 20-ID assertion | Keep catalog gate in CI |
| Clear scenario for every mission | ✅ Complete | `MissionSimulationDefinition.scenario`; all 20 definitions | Instructor wording review |
| 3–6 meaningful phases | ✅ Complete | Catalog acceptance test lines 327–345 | Preserve phase-count gate |
| 2–4 interaction families | ✅ Complete | `expectedFamilies`; catalog acceptance test | Add runtime completion telemetry |
| Drag/drop not sole mechanic | ✅ Complete | `accessibleControl: select_then_confirm`; catalog test rejects drag-only paths | Manually exercise placement/connect alternatives |
| Technical decision point | ✅ Complete | `hasTechnicalDecision`; catalog test asserts all 20 | Instructor review of decision depth |
| Observation/testing/verification | ✅ Complete | `hasVerification`; test/observe/interpret families | Verify result states live |
| Structured evidence for actions | ⚠️ Partial | `MissionRuntimeController.dispatch`; `PracticeMissionEvidenceService` RLS upsert | Authenticated Supabase write/read/reconcile run |
| Specific technical feedback | ✅ Complete | `MissionContentData.feedbackForMission`; phase feedback IDs | Text scan for remaining generic copy |
| Assessment hides answers | ✅ Complete | authoritative contracts and diagnostic tests | Disposable assessment attempt |
| Practice hints | ⚠️ Partial | `practiceGuidance` and practice copy; no uniform phase hint affordance | Add/verify phase-level hints |
| Pause/resume state | ✅ Complete (static) | controller `persist/restore`; lifecycle observer; tests | Authenticated process-death run |
| Evidence deduplication | ✅ Complete (static) | stable `clientActionId`, upsert conflict key, reconciliation | Offline/reconnect integration run |
| Accessibility alternatives | ✅ Complete (automated) | Semantics, 48dp hotspots, object picker, select-then-confirm | TalkBack pass across all families |
| Android sizes | ✅ Complete (automated) | compact/landscape/2× text tests; responsive scene | Low-end physical device pass |
| Submission review | ✅ Complete (static/widget) | review is last phase; gated `EvidenceReviewPanel` | Live backend rejection/release run |
| Evaluation/realtime/instructor release | ❌ Missing evidence | Supplied session did not provide authorized lifecycle | Provision learner/instructor fixtures |

Audit date: 2026-08-22 (Asia/Manila)
Build: Flutter debug APK, package `com.example.bytequest`, Android 16 emulator `emulator-5554`
Scope: static configuration review, startup/auth/runtime smoke testing, offline/lifecycle checks, and existing automated coverage. No product fixes were made during this audit.

### Mission design standard / learning loop

The runtime is simulation-oriented: every catalog mission has a scenario, reusable `SimulationScene`, stateful phases, evidence dispatch, and final review. The literal full loop is not present in every mission; some intentionally omit a tool, configuration, or troubleshooting stage. That is partial compliance with the broad loop, not a missing mission.

| Mission | Scenario | Inspect | Identify/choose | Technical task | Observe/test | Configure/troubleshoot | Evidence/review | Loop |
|---|---|---|---|---|---|---|---|---|
| COC1 M1 | ✅ | ✅ | ✅ | ⚠️ record/select | ✅ | ⚠️ | ✅ | ⚠️ |
| COC1 M2 | ✅ | ✅ | ✅ | ✅ placement | ✅ | ⚠️ | ✅ | ⚠️ |
| COC1 M3 | ✅ | ⚠️ sequence first | ✅ | ✅ cable/config | ✅ | ✅ | ✅ | ✅ |
| COC1 M4 | ✅ | ✅ | ✅ tool | ✅ connect | ✅ | ⚠️ | ✅ | ⚠️ |
| COC1 M5 | ✅ | ✅ progressive | ✅ | ✅ correction | ✅ | ✅ | ✅ | ✅ |
| COC2 M1 | ✅ | ⚠️ | ✅ tools/materials | ✅ cable/connect | ✅ | ⚠️ | ✅ | ⚠️ |
| COC2 M2 | ✅ | ✅ topology | ✅ | ✅ cable/config | ✅ | ✅ | ✅ | ✅ |
| COC2 M3 | ✅ | ✅ topology | ✅ | ✅ link repair | ✅ | ✅ | ✅ | ✅ |
| COC2 M4 | ✅ | ⚠️ | ✅ | ✅ network config | ✅ | ✅ | ✅ | ✅ |
| COC2 M5 | ✅ | ✅ topology/config | ✅ | ✅ fix | ✅ | ✅ | ✅ | ✅ |
| COC3 M1 | ✅ | ✅ | ✅ requirements/role | ⚠️ readiness | ✅ | ⚠️ | ✅ | ⚠️ |
| COC3 M2 | ✅ | ⚠️ config-first | ✅ role/config | ✅ install/restart | ✅ | ✅ | ✅ | ✅ |
| COC3 M3 | ✅ | ✅ | ✅ permissions | ✅ correction | ✅ | ✅ | ✅ | ✅ |
| COC3 M4 | ✅ | ✅ service | ✅ config | ✅ service state | ✅ | ✅ | ✅ | ✅ |
| COC3 M5 | ✅ | ✅ | ✅ | ✅ recovery | ✅ | ✅ | ✅ | ✅ |
| COC4 M1 | ✅ | ✅ | ✅ symptom/priority | ⚠️ diagnosis record | ✅ | ⚠️ | ✅ | ⚠️ |
| COC4 M2 | ✅ | ✅ | ✅ tool/fault | ✅ repair | ✅ | ✅ | ✅ | ✅ |
| COC4 M3 | ✅ | ✅ | ✅ | ✅ diagnostics | ✅ | ✅ | ✅ | ✅ |
| COC4 M4 | ✅ | ⚠️ | ✅ component/tool | ✅ replacement | ✅ | ✅ | ✅ | ✅ |
| COC4 M5 | ✅ | ✅ | ✅ priority/tool | ✅ maintenance | ✅ | ✅ | ✅ | ✅ |

The catalog maps to reusable interaction systems rather than read-only pages or drag-only quizzes. COC3/COC4 remain visually less realistic because their scene assets are shared track artwork/code-drawn schematics.

### Reusable system audit

| System | Status | Evidence |
|---|---|---|
| `SimulationScene` | ✅ | `InteractiveViewer`, zoom/pan, reset/fit, coordinate mapping, states, connections, responsive tests |
| `HotspotWidget` | ✅ | 48dp semantics, state visuals, image-backed hotspots, object-list alternative |
| Scene persistence | ✅ static | camera/runtime state persisted by controller/store |
| Tap/Inspect | ✅ | `tap_inspect_interaction.dart` |
| Multi Select | ✅ | `multi_select_interaction.dart` |
| Tool Selection | ✅ | `tool_selection_interaction.dart`, `tool_tray.dart` |
| Connection | ✅ | `connection_interaction.dart`, select-then-confirm alternative |
| Configuration | ✅ | `configuration_panel.dart` |
| Sequencing | ✅ | `sequencing_interaction.dart` |
| Matching | ✅ | `matching_interaction.dart` |
| Controlled Placement | ✅ | orientation validation and accessible confirmation |
| Troubleshooting | ✅ | progressive diagnostic facts |
| Testing | ✅ | progress/result state |
| Observation | ✅ | observation input and evidence callback |
| Scenario Decision | ✅ | branching choice interaction |
| Result Interpretation | ✅ | simulated output interpretation |
| Evidence Review | ✅ | final review and submit gating |

### Phase 1 mission-standard check

Static result: scenarios 20/20; phase count 20/20; interaction variety 20/20; non-drag alternative 20/20; technical decision 20/20; observation/testing 20/20; feedback catalog 20/20; assessment answer protection 20/20; pause/resume and deduplication 20/20 code paths; accessibility and size tests 20/20. Evidence writes, live pause/reconnect, and backend release remain runtime-blocked; practice hints are partial because guidance exists but is not a uniform affordance in every phase.

### Mission-by-mission scorecard

Scores are `scenario / interaction / technical / decision / scene / evidence / access / polish / persistence / integrity`; requested targets are `4/4/4/3/4/4/4/4/5/5`.

| Mission | Current state | Interaction types | Evidence/persistence/accessibility | Score /5 | Missing or risk |
|---|---|---|---|---:|---|
| COC1 M1 | Runtime catalog; emulator workspace images verified | inspect, select, observe, test | structured path; controller/store; semantics/picker | 3.6 | live backend lifecycle; schematic scene |
| COC1 M2 | Runtime placement workflow | inspect, place, sequence, test | same reusable path | 3.7 | full manual phase run |
| COC1 M3 | Runtime cable/config workflow | sequence, connect, test, interpret | same reusable path | 3.7 | legacy assignment template divergence |
| COC1 M4 | Runtime peripheral workflow | inspect, tool, connect, test | same reusable path | 3.4 | manual traversal |
| COC1 M5 | Progressive diagnosis | troubleshoot, decide, test | branch evidence; persistence/accessibility | 3.6 | backend retest |
| COC2 M1 | Runtime cabling workflow | tool, sequence, connect, test | same reusable path | 3.5 | manual traversal |
| COC2 M2 | Golden cable workflow | configure, sequence, connect, test | same reusable path | 3.7 | legacy assignment template divergence |
| COC2 M3 | Topology repair | select, connect, decide, test | same reusable path | 3.7 | manual traversal |
| COC2 M4 | Network configuration | configure, test, interpret | same reusable path | 3.5 | fewer interaction families |
| COC2 M5 | Progressive troubleshooting | troubleshoot, decide, test | branch evidence; persistence/accessibility | 3.6 | backend retest |
| COC3 M1 | Server preparation | inspect, decide, sequence, test | same reusable path | 3.4 | generic artwork; live server test |
| COC3 M2 | Install/restart | configure, sequence, decide, test | same reusable path | 3.5 | generic artwork; manual run |
| COC3 M3 | Permissions diagnosis | configure, troubleshoot, decide, test | same reusable path | 3.6 | live permission test |
| COC3 M4 | Service workflow | inspect, configure, test, interpret | same reusable path | 3.5 | simulated service response |
| COC3 M5 | Service recovery | troubleshoot, decide, test | branch evidence; persistence/accessibility | 3.5 | backend recovery |
| COC4 M1 | Maintenance inspection | inspect, observe, decide, test | same reusable path | 3.4 | shallow preliminary diagnosis; artwork |
| COC4 M2 | Hardware diagnosis | troubleshoot, interpret, decide, test | branch evidence; persistence/accessibility | 3.6 | live tools/results |
| COC4 M3 | Software/network diagnosis | inspect, troubleshoot, interpret, test | progressive evidence | 3.6 | live diagnostics |
| COC4 M4 | Repair/reconfiguration | place, configure, sequence, test | select-confirm; persistence | 3.7 | manual traversal |
| COC4 M5 | Final maintenance | troubleshoot, decide, test, observe | branch/observation evidence | 3.7 | backend release/manual final verification |

All missions are below at least one requested category target. Scene quality is generally 3/5 because current visuals are schematic/track artwork; persistence and assessment integrity are not 5/5 until live process-death and instructor-release checks complete.

### Category scores by mission

Columns: `S` scenario realism, `V` interaction variety, `T` technical relevance, `D` decision depth, `2D` scene quality, `E` evidence quality, `A` accessibility, `P` visual polish, `R` persistence, `I` assessment integrity. Each value is /5; targets are `4,4,4,3,4,4,4,4,5,5`.

| Mission | S | V | T | D | 2D | E | A | P | R | I |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| COC1 M1 | 4 | 4 | 4 | 3 | 3 | 3 | 4 | 3 | 4 | 4 |
| COC1 M2 | 4 | 4 | 4 | 3 | 3 | 3 | 4 | 3 | 4 | 4 |
| COC1 M3 | 4 | 4 | 4 | 3 | 3 | 3 | 4 | 3 | 4 | 4 |
| COC1 M4 | 4 | 4 | 4 | 3 | 3 | 3 | 4 | 3 | 4 | 4 |
| COC1 M5 | 4 | 4 | 4 | 3 | 3 | 4 | 4 | 3 | 4 | 4 |
| COC2 M1 | 4 | 4 | 4 | 3 | 3 | 3 | 4 | 3 | 4 | 4 |
| COC2 M2 | 4 | 4 | 4 | 3 | 3 | 3 | 4 | 3 | 4 | 4 |
| COC2 M3 | 4 | 4 | 4 | 3 | 3 | 3 | 4 | 3 | 4 | 4 |
| COC2 M4 | 4 | 3 | 4 | 3 | 3 | 3 | 4 | 3 | 4 | 4 |
| COC2 M5 | 4 | 4 | 4 | 3 | 3 | 4 | 4 | 3 | 4 | 4 |
| COC3 M1 | 4 | 4 | 4 | 3 | 2 | 3 | 4 | 2 | 4 | 4 |
| COC3 M2 | 4 | 4 | 4 | 3 | 2 | 3 | 4 | 2 | 4 | 4 |
| COC3 M3 | 4 | 4 | 4 | 3 | 2 | 3 | 4 | 2 | 4 | 4 |
| COC3 M4 | 4 | 4 | 4 | 3 | 2 | 3 | 4 | 2 | 4 | 4 |
| COC3 M5 | 4 | 4 | 4 | 3 | 2 | 3 | 4 | 2 | 4 | 4 |
| COC4 M1 | 4 | 4 | 4 | 3 | 2 | 3 | 4 | 2 | 4 | 4 |
| COC4 M2 | 4 | 4 | 4 | 3 | 2 | 3 | 4 | 2 | 4 | 4 |
| COC4 M3 | 4 | 4 | 4 | 3 | 2 | 3 | 4 | 2 | 4 | 4 |
| COC4 M4 | 4 | 4 | 4 | 3 | 2 | 3 | 4 | 2 | 4 | 4 |
| COC4 M5 | 4 | 4 | 4 | 3 | 2 | 3 | 4 | 2 | 4 | 4 |

Every mission is below at least one target, primarily 2D scene quality, visual polish, live evidence quality, persistence, or assessment integrity pending runtime proof.

### Final acceptance test

| Check | Result |
|---|---|
| `flutter test` | ✅ 191 passed |
| `flutter analyze --no-fatal-infos` | ✅ 0 errors; 214 informational findings |
| `flutter build apk --debug` | ✅ built `build/app/outputs/flutter-apk/app-debug.apk` |
| Practice shell | ✅ entered `Learn → Practice`; COC1 M1 launched |
| COC1 M1 workspace | ✅ motherboard/CPU/RAM/PSU/anti-static images visibly rendered |
| COC1 M1–M5 full manual traversal | ⚠️ not completed; M1 was opened, remaining full-phase evidence absent |
| COC2–COC4 M1–M5 full manual traversal | ⚠️ not completed |
| Incorrect states/evidence/pause/resume | ⚠️ widget/controller tests pass; authenticated manual run pending |
| Supabase evaluation/realtime/instructor release | ❌ not verified |

### UI/UX, security, and performance findings

- ✅ Consistent navy/blue system, bottom navigation, semantics, 48dp targets, responsive scene/control split, and image-backed COC1/COC2 hotspots.
- ⚠️ COC3/COC4 use generic track artwork/code-drawn schematics rather than mission-specific equipment scenes.
- ⚠️ Startup logs show severe emulator frame drops (`Skipped` frames); this remains BQ-QA-002.
- ✅ Practice evidence is authenticated/RLS-scoped; assessment evidence and release remain backend-authoritative.
- ⚠️ Live RLS, evaluation, realtime propagation, instructor receipt/release, and learner result release were not exercised.
- ⚠️ Missing/malformed Supabase configuration can fail before controlled startup UI (BQ-QA-001).

### Release recommendation

**NO-GO yet.** Automated catalog and Flutter gates pass, but the acceptance specification still requires authenticated all-20 manual traversal, evidence/scoring, pause/reconnect, realtime instructor receipt/release, and learner result propagation. Complete those with disposable learner/instructor fixtures, rerun this matrix, and obtain review approval before release.

## Phase 10 — Release Validation Execution (2026-08-22)

### Defect list (recorded before fixes)

#### BQ-P10-001 — Saved-progress restore fails for a practice mission

- Severity: P1 release blocker
- Location: `ByteQuest-Mobile-App/lib/screens/simulation/mission_simulation_screen.dart:118-137`, `MissionRuntimeController.restore()`
- Steps: enter `Learn → Practice → COC2 M5` from the emulator after prior mission activity; allow the mission to restore.
- Expected: the saved phase/evidence restores, or a precise recoverable error identifies the failed dependency.
- Actual: the mission displayed `Saved progress could not be restored for this mission session.` with `Retry restore` and `Reset saved progress`. Resetting allowed the mission to launch.
- Root cause: not conclusively isolated during this run because `_restore()` catches the underlying exception and replaces it with a generic message. Likely stale local snapshot/server reconciliation or an unavailable practice-evidence read; requires captured exception logging in a test build.
- Recommended fix: preserve the original exception in diagnostics, classify snapshot/schema/server failures separately, and add an integration test for stale pending evidence plus offline restore. Do not silently discard the snapshot until the learner chooses reset.

#### BQ-P10-002 — Full authenticated release lifecycle cannot be executed with the current account/session

- Severity: P1 environment blocker
- Location: learner/instructor Supabase lifecycle; no product line isolated.
- Steps: attempt to complete an authoritative assessment and observe instructor review/release.
- Expected: learner evidence reaches backend, instructor sees pending attempt, instructor releases, learner receives released result.
- Actual: the current learner session exposes practice catalog access but no assigned assessment/instructor fixture; earlier supplied login credentials were rejected for fresh authentication. No authorized instructor session was available.
- Root cause: missing disposable learner/instructor test fixture, not evidence of a product defect.
- Recommended fix: provision a short-lived learner + instructor fixture in the authorized Supabase project and rerun the lifecycle with server logs.

### Manual mission traversal status

| Track | Launch/shell checks | Full interactions/evidence/pause/resume | Result |
|---|---|---|---|
| COC1 M1–M5 | M1–M5 opened from Practice; M1/M2/M3/M5 visually captured | Not completed for every phase; backend evidence not verified | ⚠️ Partial |
| COC2 M1–M5 | M1/M2 opened; later attempts encountered/used saved-state flow; M5 restore defect recorded | Not completed for every phase; backend evidence not verified | ⚠️ Partial |
| COC3 M1–M5 | Not reached in this emulator pass | Not tested | ❌ Missing |
| COC4 M1–M5 | Not reached in this emulator pass | Not tested | ❌ Missing |

Observed positive checks: practice catalog opens, mission scenario/header loads, responsive 2D workspace renders, COC1 component artwork is visible, and mission controls are reachable without a crash. The requested all-20 manual acceptance cannot be marked passed from this run.

### Backend validation map

| Lifecycle step | Tables/API | Status |
|---|---|---|
| Practice evidence append | `practice_mission_actions`; authenticated `.upsert()` with conflict `learner_id,client_action_id` | Code path verified; live write/read not completed |
| Assessment action append | `attempt_actions`; `AuthoritativeAssessmentService.recordAction()` | Code path verified; no disposable assessment run |
| Attempt submission | `submit_attempt`/authoritative service submission RPC path | Not live-verified |
| Evaluation/finalization | `criterion_results`, `score_revisions`, finalization RPCs | Static migration/RLS evidence only |
| Instructor pending review | `attempts` status + dashboard queries | No instructor fixture |
| Instructor release | `release_attempt()`, `result_releases` | Static migration/RLS evidence only |
| Learner released result | `learner_learning_path` projection + learner queries | Static code path only |
| Realtime invalidation | `LearnerRealtimeCoordinator`; filtered `attempts`, `criterion_results`, `score_revisions`, `result_releases` channels | Listener code verified; no live event observed |

### Mobile reliability

- Force-close/reopen and lifecycle persistence are covered by controller/widget tests and the runtime lifecycle observer, but a complete authenticated process-death mission run was not completed.
- Offline action queue/reconnect was not executed in this pass. Prior emulator shell restrictions rejected the airplane-mode broadcast; use emulator UI or a controlled network proxy, then verify pending evidence reconciliation and no duplicate `client_action_id` rows.
- The COC2 M5 restore failure is the only new runtime defect observed in this pass.

### Visual/security review

- COC1 M1–M5 and COC2 launch screens showed responsive workspace framing and no overflow in the observed states. COC3/COC4 were not manually reached.
- Static security review found only `.env`-based anon-key loading in Flutter; no service-role key or hardcoded secret was found in mobile source/assets. RLS-scoped practice writes and backend-authoritative release remain the intended boundaries.
- Existing risks remain: missing Supabase configuration can fail before controlled startup UI (BQ-QA-001), startup frame drops remain visible (BQ-QA-002), and COC3/COC4 visuals are generic schematic/track artwork.

### Phase 10 release recommendation

**NO-GO remains.** Automated Flutter gates pass, but BQ-P10-001 must be isolated/fixed and the all-20 manual plus authenticated learner → instructor → release → learner lifecycle must be executed before a GO decision.

## Phase 10.1 — BQ-P10-001 restore fix (2026-08-22)

### Root-cause investigation

- Reproduced the failure in a focused controller test with a COC2 M5 runtime and an acknowledged timeline containing both COC2 M1 and COC2 M5 actions.
- `AuthoritativeAssessmentService.getActiveAttemptActions()` reads the complete active-attempt `attempt_actions` timeline. `MissionEvidenceGateway` correctly preserves those records, but `MissionRuntimeController.restore()` previously replayed every record through the active mission reducer.
- `MissionRuntimeActionReducer` correctly rejected the COC2 M1 record as a different mission, which escaped to `MissionSimulationScreen`, where the exception was replaced by the generic restore failure screen. This was the exact BQ-P10-001 failure point; no mission data or UI defect was involved.
- Local snapshot loading remains backwards-compatible: invalid/mismatched snapshots still fail closed without deletion, now with mission/version/error stack diagnostics. Existing local progress is never reset automatically.

### Fix applied

- `mission_runtime_controller.dart`: filter acknowledged server actions to the active `missionId` before reducer replay and pending reconciliation. Added structured diagnostics for mission ID, runtime schema version, snapshot timestamp, stored phase, evidence count, pending actions, Supabase sync state, and exception stack traces.
- `mission_simulation_screen.dart`: preserve and print the original restore/reset exception and stack trace instead of silently swallowing it; visible UI behavior is unchanged.
- `progress_resume_service.dart`: preserve local snapshot compatibility behavior while logging the load error and stack trace with mission/version context.
- `mission_runtime_controller_test.dart`: added a regression test proving cross-mission acknowledged actions are ignored and current-mission state restores.

### Validation

| Check | Result |
|---|---|
| Focused regression test before fix | Failed with `FormatException: Acknowledged evidence coc2-m1-action does not match coc2_m5` in `MissionRuntimeActionReducer.reduce()` |
| Focused regression test after fix | Passed |
| `flutter test` | Passed — 192 tests |
| `flutter analyze --no-fatal-infos` | Passed — 0 errors, 214 informational findings |
| `flutter build apk --debug` | Passed — debug APK generated |
| Data safety | No automatic reset, deletion, or mission/UI redesign added |

### Remaining validation

Live emulator reproduction with a newly created COC2 M5 snapshot and authenticated Supabase attempt still requires an authorized disposable account/session. The code-level reproduction matches the observed failure and the regression test now guards it.

## Phase 10.2 — Live restore and release validation (2026-08-22)

### Live emulator execution

- Installed the latest `app-debug.apk` on `emulator-5554` and launched successfully.
- The emulator already had an authenticated learner session; a genuinely fresh account/session was unavailable without an authorized disposable credential. Practice catalog access was available.
- Entered COC2 M5, intentionally reset its existing local snapshot, completed the first diagnostic action, force-stopped the process, relaunched the app, reopened COC2 M5, and observed the saved phase/evidence restored.
- Restore diagnostics showed the local snapshot was loaded with `storedPhase=coc2_m5_p1`, `pendingActions=1`, then the Supabase read failed with `PGRST205: Could not find the table public.practice_mission_actions in the schema cache`; the controller correctly retained local progress (`server_actions_failed_using_local_snapshot`) and displayed no restore-error screen.
- After process death the app reopened at the home dashboard, not directly at the prior mission. Reopening COC2 M5 from Practice was required before the mission snapshot resumed. This is a navigation-resume limitation, not loss of mission state.

### Defects and blockers found

#### BQ-P10.2-001 — Practice evidence table missing in deployed Supabase schema

- Severity: P1 release/environment blocker
- Location: Supabase schema used by `PracticeMissionEvidenceService`; migration `supabase/migrations/20260822124500_practice_mission_evidence.sql` defines the missing table.
- Reproduction: open a practice mission with no local snapshot and allow restore; the client reads `practice_mission_actions`.
- Expected: the table exists, RLS-scoped read succeeds, and evidence synchronizes.
- Actual: Supabase returns `PostgrestException` code `PGRST205` (“Could not find the table public.practice_mission_actions in the schema cache”). A new session cannot complete server reconciliation; local progress is preserved when present.
- Recommended action: apply/verify the migration in the authorized Supabase project, refresh the PostgREST schema cache, then rerun practice evidence append/read and restore. No client code was changed for this environment defect.

#### BQ-P10.2-002 — Process death does not restore the prior mission route

- Severity: P2 UX limitation
- Reproduction: force-stop while in COC2 M5, relaunch the app.
- Expected: prior mission route opens directly, or a clear resume entry point is shown.
- Actual: app opens at the home dashboard; selecting COC2 M5 manually restores the saved phase/evidence.
- Recommended action: evaluate route-intent persistence separately; do not alter the runtime snapshot contract as part of this validation.

### Cross-mission isolation

- Code-level regression test passed: acknowledged actions from another mission are filtered before reducer replay.
- Local snapshot keys include learner, mission, mode, and assessment attempt scope. A complete live multi-mission sequence was not completed because the deployed practice evidence table is missing.

### Mission smoke traversal

| Track | Emulator result in this pass |
|---|---|
| COC1 M1–M5 | Catalog and prior launch captures available; full interaction/persistence traversal not repeated in this pass |
| COC2 M1–M5 | Catalog visible; COC2 M5 launched and restored after force-stop; full five-mission interaction traversal not completed |
| COC3 M1–M5 | Not reached in this pass |
| COC4 M1–M5 | Not reached in this pass |
| Static 20-mission launch/asset coverage | Existing automated suite passed; this does not replace manual acceptance |

Observed no new crash, overflow, or missing-art failure in the COC2 M5 state. Full manual checks for invalid actions, evidence submission, pause/resume, accessibility, and all COC3/COC4 screens remain open.

### Backend lifecycle and security

- Learner evidence submission → instructor pending review → evaluation → instructor release → learner final result could not be executed live: the practice table is missing and no disposable instructor fixture/session was available.
- Static review confirms learner-scoped Supabase access, RLS-bound practice writes, authoritative assessment RPCs, instructor-only release paths, and realtime listeners. No service-role key or hardcoded secret was found in mobile source/assets.

### Phase 10.2 release recommendation

**NO-GO remains.** The BQ-P10-001 client fix is validated by regression test and local-fallback emulator behavior, but BQ-P10.2-001 blocks server synchronization; BQ-P10.2-002 and incomplete all-20/backend manual coverage remain.

## Supabase foundation schema repair (2026-08-23)

- Added `supabase/migrations/20260807000000_initial_schema.sql` as one additive baseline migration. It restores the documented legacy foundation: identity (`profiles`, `account_status`, `user_role`), catalog (`competencies`, `coc_modules`, `missions`), simulation/criteria tables, progress/results, gamification catalogs and awards, notifications/settings, reports/logs, timestamps, Auth profile provisioning, and compatibility helpers.
- The migration was derived from every ordered migration dependency plus `docs/CHECKPOINT_A_COLUMN_INVENTORY.md`; no existing incremental migration was modified and no seed/content rows were invented.
- `supabase db push --linked --include-all --yes`: **PASS**. All 37 migrations, including the new baseline and `20260822124500_practice_mission_evidence.sql`, applied sequentially without dependency errors.
- `supabase migration list --linked`: **PASS**. Local and remote versions match from `20260807000000` through `20260822124500`.
- Linked verification queries confirmed all foundation tables and compatibility routines exist. Later migrations removed the retired `is_instructor_admin` routine as intended.
- `supabase db reset --local --no-seed --yes`: **BLOCKED** before migration execution because Docker/Podman is unavailable (`LegacyLocalDbRunningError: failed to inspect service`). This is an environment limitation, not a migration dependency failure.
- No security policies were removed or bypassed; later authoritative RLS migrations remain unchanged and were applied by the linked push.

### Remaining dependency issues

No remaining dependency issues were reported by the linked sequential push. Local reset still requires Docker Desktop or Podman, then should be rerun independently.

## Priority summary

| Priority | Count | Meaning |
|---|---:|---|
| P1 | 1 | Startup can fail hard when Supabase configuration is missing or malformed |
| P2 | 1 | Noticeable first-use jank during startup/auth rendering |
| P3 | 1 | Mission scene metadata points at assets that are not present/declared |
| Blocked | 1 | Authenticated mission/evidence/scoring test blocked by supplied account credentials |

## Findings

### BQ-QA-001

- Severity: P1 — High
- Location: `ByteQuest-Mobile-App/lib/main.dart:31-40`; `ByteQuest-Mobile-App/lib/core/config/supabase_config.dart:29-45`
- Steps to reproduce:
  1. Remove `.env`, or leave `SUPABASE_URL`/`SUPABASE_ANON_KEY` empty.
  2. Launch the APK.
- Expected behavior: A controlled configuration/error screen explains the missing setting and keeps the process alive (or exits with a user-actionable message).
- Actual behavior: `main()` logs a warning, then calls `SupabaseConfig.initialize()` without a recovery boundary. Initialization rethrows the missing-variable exception before `runApp()`, so Flutter has no error UI to display and startup can terminate.
- Root cause: Environment loading is attempted twice, but the second initialization exception is allowed to escape the root async entrypoint.
- Recommended fix: Validate configuration once before `runApp()`, then render a fail-closed `ConfigurationErrorScreen` with a non-secret diagnostic. Add a startup test for missing URL/key and malformed URL.

### BQ-QA-002

- Severity: P2 — Medium
- Location: startup path in `ByteQuest-Mobile-App/lib/main.dart:28-60`; splash/auth image-heavy screens.
- Steps to reproduce:
  1. Clear app state and launch on `emulator-5554`.
  2. Move from onboarding to login and focus the form.
  3. Observe Flutter/device logs.
- Expected behavior: Startup and the first auth interaction remain responsive with no sustained frame loss.
- Actual behavior: Runtime logs recorded `Skipped 72 frames`, `Skipped 59 frames`, and `Skipped 125 frames` during initial startup/auth rendering. The app remained usable, but transitions and keyboard interactions visibly stalled on the emulator.
- Root cause: Large raster assets and Supabase initialization/orientation work occur during the first interactive frames; image decoding is visible in the Android logs.
- Recommended fix: Defer non-critical initialization until after the first frame, precache/resize onboarding assets, and profile image decode plus auth-screen rebuilds on a low-end emulator. Add a startup frame-time budget to QA.

### BQ-QA-003

- Severity: P3 — Low/medium maintainability risk
- Location: `ByteQuest-Mobile-App/lib/data/mission_simulation_definitions.dart:170-174`; `ByteQuest-Mobile-App/pubspec.yaml:52-58`
- Steps to reproduce:
  1. Inspect generated mission scene definitions.
  2. Resolve each `metadata.replaceableAsset` path.
  3. Check the Flutter asset manifest/source tree.
- Expected behavior: Every replaceable scene asset exists and is declared, or the definition uses an explicit placeholder/fallback contract.
- Actual behavior: Definitions generate paths under `assets/simulation/schematics/<object>.svg`, but no `assets/simulation/schematics` files or asset declaration exists in the project. The current renderer does not consume this metadata, so this did not crash the smoke run; any future renderer that does will produce missing-asset failures.
- Root cause: Scene metadata was added ahead of the production schematic asset bundle.
- Recommended fix: Either add the schematic bundle and `pubspec.yaml` declaration, or remove/guard the metadata and provide a tested code-drawn fallback. Add an asset-manifest consistency test.

## Test limitation (not classified as a confirmed product defect)

`drobertalsidpalces@gmail.com` / supplied password was entered through the real login UI. Supabase returned `Invalid login credentials`; the UI stayed on login and emitted a specific error snackbar. Because no valid disposable learner account was available, the following could not be exercised end-to-end: authenticated dashboard navigation, mission launch from the learner shell, evidence submission, backend scoring, pause/resume of an authenticated attempt, realtime instructor release, and authenticated offline recovery. This is an environment/credential blocker, not evidence that those flows are broken.

## Runtime checks performed

- APK build/install/startup: passed; app reached onboarding without a crash.
- Onboarding → “I already have an account” → login: passed.
- Invalid-auth handling: passed; returned a specific invalid-credentials message and did not crash.
- Offline cold start: passed at the shell level; app still rendered onboarding while airplane mode was enabled. Authenticated offline behavior remains blocked by credentials.
- Force-stop/relaunch smoke: app process relaunched and rendered the onboarding shell.
- Emulator/device: Android 16, `emulator-5554`, 320×640 logical display in the UI dump.
- Automated Flutter suite: `flutter test` passed, 189 tests.
- Static analysis: `flutter analyze --no-fatal-infos` exited 0; 213 informational lints, 0 errors.
- Debug APK build: passed. Build emitted Kotlin/Gradle migration warnings but no build failure.
- No `FATAL EXCEPTION`, Flutter framework exception, `RenderFlex overflow`, or `Unable to load asset` was observed during the captured smoke run.

## Recommended fix order

1. BQ-QA-001 — protect startup with a controlled configuration state.
2. BQ-QA-002 — reduce first-frame/auth jank and add a measurable performance gate.
3. BQ-QA-003 — reconcile schematic metadata with real assets or a guaranteed fallback.
4. Re-run authenticated mission, evidence, scoring, realtime, and pause/resume checks with disposable learner/instructor credentials.

## Failed test operations and alternatives

- 2026-08-22 15:09 +08:00 — Android airplane-mode broadcast was rejected with `SecurityException` because shell UID cannot send `AIRPLANE_MODE` broadcasts on this emulator. Location: test harness command (no product line). Workaround used: `settings put global airplane_mode_on` plus `svc wifi/data`; alternative: toggle airplane mode through the emulator UI or use a network-proxy/offline test harness.
- 2026-08-22 15:10 +08:00 — Supplied login attempt failed with Supabase `Invalid login credentials`. Location: `lib/screens/auth/login_screen.dart:38-66` and `lib/services/auth_service.dart:88-123`. Workaround: obtain a valid disposable learner account or reset the supplied account through the authorized Supabase/instructor workflow; alternatives: run the existing widget/service tests with fakes, or provision a local Supabase test project without weakening production auth.

## Supabase cloud/application audit (2026-08-23)

- Scope: read-only verification of the linked cloud project and Flutter integration. No `db pull`, local reset, or production code change was performed.
- Migration state: `supabase migration list --linked` reports local/remote parity for all 37 migrations through `20260822124500`.
- Flutter integration: `SupabaseConfig` loads only `SUPABASE_URL` and the publishable/anon key from `.env`, enables PKCE and token refresh, and exposes the auth-state stream. Repository search found no committed service-role key or JWT secret.
- Authentication/profile provisioning: `AuthService` uses Supabase email/password Auth; sign-up expects the `auth.users` `on_auth_user_created` trigger to provision `profiles`, then completes learner-editable fields. Sign-in verifies an existing active learner profile before allowing the mobile session. The trigger exists in the linked database.
- Mission data/evidence: `MissionDatabaseService` uses the learner-authorized `get_learner_learning_path` RPC and catalog tables. Practice evidence writes and reads use `practice_mission_actions` with `(learner_id, client_action_id)` idempotency, and the linked table now exists with the expected columns/index and own-learner RLS policies. Authoritative assessment writes use `start_attempt`, `append_attempt_action`, and `submit_attempt`; score/release authority remains in database RPCs.
- Expected API surface: all mobile-referenced RPCs (`get_learner_learning_path`, `get_bypassed_activities`, `start_attempt`, `get_available_learner_quizzes`) exist. Linked inspection also found the evaluation/release, profile, attempt, result, and realtime-supporting tables expected by the application.
- RLS/security: every public base table inspected has RLS enabled. Profiles, practice evidence, attempts, learner progress, mission results, and current result releases have scoped authenticated policies. A privilege audit found `authenticated` still reports UPDATE/DELETE/TRUNCATE table privileges on `practice_mission_actions`, despite its migration granting only SELECT/INSERT; RLS blocks row updates/deletes, but the excess ACL is a least-privilege hardening defect (BQ-QA-004) and should be revoked in a follow-up migration. No client-side service-role exposure was found.
- Backend lifecycle limitation: no live learner→instructor→release→learner transaction was executed in this audit because a valid disposable learner/instructor fixture was not available. Database RPC definitions and policy scope were verified statically/through linked metadata only.

### BQ-QA-004

- Severity: P1 — Security hardening
- Location: linked ACL for `public.practice_mission_actions`; migration `20260822124500_practice_mission_evidence.sql:62-64`
- Steps to reproduce: query `information_schema.table_privileges` or `has_table_privilege('authenticated', 'public.practice_mission_actions', 'TRUNCATE')` in the linked project.
- Expected behavior: authenticated clients have only SELECT and INSERT, matching the append-only evidence contract.
- Actual behavior: linked metadata reports UPDATE, DELETE, TRUNCATE, and other table privileges for `authenticated`; no UPDATE/DELETE policies exist, but the table ACL is broader than intended.
- Root cause: the deployed table ACL retains broader managed/default privileges after the migration’s public/anon revoke and SELECT/INSERT grant.
- Recommended fix: apply a reviewed follow-up migration that explicitly revokes UPDATE, DELETE, TRUNCATE, REFERENCES, and TRIGGER on `public.practice_mission_actions` from `authenticated`, retaining only SELECT/INSERT plus sequence usage, then recheck ACLs. Do not alter the append-only RLS policies.

### BQ-QA-004 remediation (2026-08-23)

- Added `supabase/migrations/20260823100000_restrict_practice_evidence_privileges.sql`.
- The migration revokes all table privileges from `anon` and `authenticated`, then grants authenticated only `SELECT, INSERT`. It similarly removes sequence privileges and restores authenticated `USAGE` only. `service_role` privileges were not changed.
- `supabase db push --linked --include-all --yes`: passed.
- Post-migration ACL verification: `authenticated` has only INSERT and SELECT on `practice_mission_actions`; `anon` has no table privileges; authenticated has only sequence USAGE. Service-role privileges remain available.
- RLS verification: existing `practice_mission_actions_select_own` and `practice_mission_actions_insert_own` policies are unchanged and remain learner/`auth.uid()` scoped.
- Migration parity: local and remote match through `20260823100000`.
- Status: **Resolved**. No Flutter code was modified and no commit was created.

## Live authenticated evidence validation (2026-08-23)

- Credentials: supplied learner account, authenticated through Supabase Auth REST using the mobile `.env` URL and anon key.
- Authentication: **PASS**. Auth returned user `de4c5944-c0e4-4aee-8ef6-0304914e9296` and an access token.
- Profile provisioning: **PASS**. Authenticated read returned an active `learner` profile for the same `user_id`.
- Practice evidence INSERT/read/isolation/update/delete: **BLOCKED/FAIL**. At `2026-08-23 01:12:12 +08:00`, authenticated requests to `/rest/v1/practice_mission_actions` returned HTTP 404 `PGRST205`: `Could not find the table 'public.practice_mission_actions' in the schema cache`. This occurred after the ACL migration was pushed and after `NOTIFY pgrst, 'reload schema'` plus `pg_notify('pgrst','reload schema')` were issued. No evidence row was created, so mutation behavior could not be safely exercised.
- Attempt lifecycle/retry/reconnect: **BLOCKED** because the practice evidence transport cannot reach its deployed PostgREST resource. No client or database code was modified to bypass this failure.

### BQ-QA-005

- Severity: P1 — Release blocker
- Location: deployed PostgREST schema cache for `public.practice_mission_actions`; Flutter transport `ByteQuest-Mobile-App/lib/services/practice_mission_evidence_service.dart:95-118`
- Steps to reproduce: authenticate as the supplied learner, call GET or POST `/rest/v1/practice_mission_actions` with the bearer token.
- Expected behavior: the table is available through PostgREST and learner-scoped SELECT/INSERT RLS is enforced.
- Actual behavior: HTTP 404 `PGRST205` reports the table is absent from the schema cache, although linked PostgreSQL metadata confirms the table and policies exist.
- Root cause: the cloud PostgREST schema cache has not incorporated the newly deployed table/migration.
- Recommended fix: refresh/restart the project’s PostgREST/API schema cache through the Supabase project control plane, then rerun the authenticated INSERT/read/isolation/append-only tests. Do not change Flutter code or weaken RLS.

### BQ-QA-005 investigation result (2026-08-23)

- `information_schema.tables` confirms exactly one `BASE TABLE`: `public.practice_mission_actions`. `pg_class` confirms lowercase relation name, ordinary persistent table, owned by `postgres`; no duplicate table exists in another schema.
- The linked migration history confirms `20260822124500_practice_mission_evidence.sql` committed, followed by ACL remediation. PostgreSQL table/column/index/RLS metadata is present.
- API exposure comparison: `public.profiles` and `public.attempt_actions` are reachable through the same REST base URL (HTTP 200), proving the cloud API exposes the `public` schema. Only `practice_mission_actions` is missing from the OpenAPI/PostgREST cache. Local `supabase/config.toml` also declares `schemas = ["public", "graphql_public"]`; cloud `pgrst.*` settings are not exposed through `pg_settings`.
- Safe fix attempted: added `supabase/migrations/20260823110000_reload_postgrest_schema_cache.sql` containing only `NOTIFY pgrst, 'reload schema'`; applied successfully with `supabase db push --linked --include-all --yes`. A direct `NOTIFY`/`pg_notify` was also issued. After waiting and retesting, REST still returns HTTP 404 `PGRST205` for the relation.
- Conclusion: this is a managed PostgREST instance/cache exposure problem, not a schema name, casing, transaction, ACL, RLS, or Flutter issue. The database-side notification is not being consumed by the deployed API instance.
- Required action: restart/refresh the project’s PostgREST/API service or use the Supabase control plane support path to invalidate its schema cache. Re-run the authenticated evidence lifecycle afterward. No further database object, ACL, or policy changes are appropriate.

### BQ-QA-005 post-restart validation (2026-08-23)

- Restart was reported complete and the supplied learner authenticated successfully.
- Fresh API tests still returned HTTP 404 `PGRST205` for INSERT, own SELECT, cross-user SELECT, DELETE, and the final verification read. The relation remains absent from the live PostgREST schema cache.
- The attempted PATCH returned HTTP 400 `PGRST102` because the curl request body was not accepted; this is not counted as an authorization result. No evidence row was created, so update/delete immutability and cross-user isolation remain unverified.
- BQ-QA-005 status: **OPEN / RELEASE BLOCKER**. Do not mark resolved until the REST relation becomes reachable and all five learner checks pass.

### BQ-QA-005 deeper metadata comparison (2026-08-23)

- REST metadata: the anonymous/authenticated `/rest/v1/` OpenAPI endpoint rejects metadata access (`Invalid API key`; Supabase reserves that endpoint for `service_role`). Direct endpoint comparison still shows `profiles` and `attempt_actions` reachable with HTTP 200, while `practice_mission_actions` returns PGRST205. This proves the public schema is exposed but the new relation is missing from the deployed PostgREST cache.
- PostgreSQL comparison: all three relations are lowercase persistent tables in schema `public`, owned by `postgres`, with the same public schema ACL. `practice_mission_actions` has the intended authenticated `ar` ACL (SELECT/INSERT), while working tables are also reachable. The practice table has its expected comment and RLS policies; no ownership or privilege discrepancy explains PGRST205.
- Migration timing: `supabase_migrations.schema_migrations` records the practice table migration, ACL hardening, and cache-reload migration as committed. No alternate schema, casing mismatch, or uncommitted transaction exists. PostgreSQL has no table-creation timestamp to compare against an API snapshot.
- API configuration: repository `supabase/config.toml` exposes `public` and `graphql_public`; cloud `pgrst.*` settings are not visible through `pg_settings`. Existing public tables confirm the cloud API is exposing `public` in practice.
- Safe-fix assessment: no additional table/ACL/RLS migration is justified. The database-only `NOTIFY pgrst` migration was applied but ineffective, and the reported service restart did not refresh the relation. This is now documented as a managed Supabase/PostgREST platform-cache issue requiring control-plane/support intervention.
-
### BQ-QA-005 live validation rerun (2026-08-23)

- Migration sync: `supabase db push --linked --include-all --yes` returned `upToDate=true`; no pending migrations.
- Data API public-schema exposure: `GET /rest/v1/profiles?select=user_id&limit=1` → HTTP **200**; `GET /rest/v1/attempt_actions?select=id&limit=1` → HTTP **200**.
- Authenticated learner: supplied account authenticated successfully.
- `POST /rest/v1/practice_mission_actions` → HTTP **404**, code `PGRST205`.
- Own `GET /rest/v1/practice_mission_actions?...` → HTTP **404**, code `PGRST205`.
- Cross-user `GET /rest/v1/practice_mission_actions?learner_id=neq.<learner>` → HTTP **404**, code `PGRST205`.
- `PATCH /rest/v1/practice_mission_actions?...` → HTTP **404**, code `PGRST205`.
- `DELETE /rest/v1/practice_mission_actions?...` → HTTP **404**, code `PGRST205`.
- Final read after mutation attempts → HTTP **404**, code `PGRST205`.
- No evidence row was created. BQ-QA-005 remains **OPEN / RELEASE BLOCKER**; RLS isolation and append-only mutation behavior cannot be evaluated until PostgREST exposes the relation.

## Mission routing regression fix (2026-08-23)

- Root cause: commit `55a2a9c` replaced the legacy `MissionType`/mission-ID launcher with an unconditional shared-runtime fallback, bypassing the original identification and practice templates.
- Fix: restored mission-specific practice routes in `mission_launcher.dart` while preserving assessment payload overrides and the shared runtime fallback.
- COC1 M1 now uses `IdentificationMissionScreenEnhanced` with the existing COC1 M1 questions/items, including Motherboard and SSD.
- All 20 mission IDs have explicit intended-operation routing coverage and regression tests.
- Validation: `flutter analyze --no-fatal-infos` passed with 0 errors; `flutter test` passed (193 tests). Emulator manual smoke passed on `emulator-5554`: COC1 M1 displayed the tap-identification grid, hardware images, and “Tap the correct item” prompt.

## Final release audit after routing restoration (2026-08-23)

### Release decision: **NO-GO**

Automated and focused UI contract coverage passed, but the live practice evidence API remains unavailable. The release cannot be accepted while evidence creation/synchronization is blocked.

- Mission routing/content: **PASS by automated catalog contract** for all 20 IDs. Each mission resolves to its intended identification, drag/drop, configuration, procedure, troubleshooting, or protected enhanced template. COC1 M1 was manually opened on `emulator-5554` and matched the reference interaction: identification grid, hardware images, and “Tap the correct item” prompt.
- Manual mission traversal: COC1 M1 launch/visual check passed. Full manual interaction, completion, retry, and asset verification for COC1 M2–M5 and COC2–COC4 M1–M5 was not completed in this run; automated widget/catalog coverage is not a substitute for that live acceptance gate.
- Assets/UI contract: automated image-path, responsive-layout, accessibility, and interaction-family tests passed. Existing debug logs still report startup frame skips and some generic missing-image diagnostics in synthetic test fixtures; no new routing crash or overflow was found.
- Evidence lifecycle: **BLOCKED**. Authenticated REST `GET /rest/v1/practice_mission_actions` still returns HTTP 404 `PGRST205`; INSERT, SELECT, retry, reconnect, and result propagation cannot be validated.
- BQ-QA-005: **OPEN / P1 release blocker**. Public API comparison remains `profiles` HTTP 200, `attempt_actions` HTTP 200, `practice_mission_actions` HTTP 404/PGRST205.
- Automated validation: `flutter analyze --no-fatal-infos` passed with 0 errors and 214 informational findings; `flutter test` passed with 193 tests.
- Required before GO: repair the managed PostgREST schema exposure, then complete authenticated evidence sync/retry/reconnect/result propagation and a full live COC1–COC4 mission traversal.
