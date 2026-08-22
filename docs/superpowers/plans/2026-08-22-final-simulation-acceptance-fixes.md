# Final Simulation Acceptance Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close every remaining simulation acceptance finding across catalog rendering, canonical interaction contracts, server-backed restore, test evidence semantics, scene connections, and proof documentation.

**Architecture:** Make the resolved presentation family a domain-level contract used by definition validation, completion policy, and widget rendering. Rebuild runtime state by deterministically reducing RLS-scoped acknowledged server actions before de-duplicated pending local actions, while keeping PostgreSQL authoritative for evaluation. Normalize scene connection lookup at the scene boundary and preserve existing JSON payload compatibility.

**Tech Stack:** Flutter/Dart, `flutter_test`, Supabase Flutter/PostgREST, PostgreSQL/RLS, Markdown acceptance records.

**Spec:** `docs/superpowers/specs/2026-08-20-bytequest-simulation-platform-design.md`

## Global Constraints

- All 20 missions have three to six meaningful phases and two to four actual non-review interaction families, a rendered technical decision, verification, and explicit review.
- Widgets do not contain mission feedback or evaluator answers; PostgreSQL remains the only evaluation authority.
- Restore never submits or evaluates and never trusts evidence from another learner, mission, mode, or attempt.
- Existing version-1 runtime JSON remains readable and writable without a schema-breaking shape change.
- Live database changes are not applied; authenticated Supabase/emulator proof remains unverified unless credentials and infrastructure are actually available.

---

### Task 1: Canonical catalog presentation contracts

**Files:**
- Modify: `ByteQuest-Mobile-App/lib/screens/simulation/runtime/mission_runtime_models.dart`
- Modify: `ByteQuest-Mobile-App/lib/screens/simulation/runtime/mission_phase_completion_policy.dart`
- Modify: `ByteQuest-Mobile-App/lib/screens/simulation/mission_simulation_screen.dart`
- Modify: `ByteQuest-Mobile-App/lib/data/mission_simulation_definitions.dart`
- Modify: `ByteQuest-Mobile-App/lib/data/mission_definitions/coc1_definitions.dart`
- Modify: `ByteQuest-Mobile-App/lib/data/mission_definitions/coc2_definitions.dart`
- Modify: `ByteQuest-Mobile-App/lib/data/mission_definitions/coc3_definitions.dart`
- Modify: `ByteQuest-Mobile-App/lib/data/mission_definitions/coc4_definitions.dart`
- Test: `ByteQuest-Mobile-App/test/mission_catalog_acceptance_test.dart`
- Test: `ByteQuest-Mobile-App/test/mission_simulation_screen_test.dart`

**Interfaces:**
- Consumes: `MissionPhaseDefinition.presentation`, the fourteen reusable interaction widgets, and existing mission feedback catalogs.
- Produces: one public resolved-family contract used by models, completion policy, and renderer; complete presentation data for every catalog phase.

- [ ] Add an exhaustive widget test that renders all 116 catalog phases and fails if `TechnicalUnavailableState` appears or a widget throws.
- [ ] Run the focused catalog/screen tests and capture the failing mission/phase contracts.
- [ ] Add domain-level component-to-family resolution and validate that declared primary families match the rendered family.
- [ ] Derive mission interaction breadth and technical-decision presence from rendered mechanics, excluding submission review from the 2–4 mechanic count.
- [ ] Populate every missing tool/target, choice, field, sequence, placement, connection, diagnostic, observation, interpretation, test, and review input in data definitions.
- [ ] Run catalog, completion-policy, and screen tests to GREEN.

### Task 2: Server timeline restore and deterministic reduction

**Files:**
- Modify: `ByteQuest-Mobile-App/lib/screens/simulation/runtime/mission_runtime_models.dart`
- Modify: `ByteQuest-Mobile-App/lib/screens/simulation/runtime/mission_evidence_gateway.dart`
- Modify: `ByteQuest-Mobile-App/lib/screens/simulation/runtime/mission_runtime_controller.dart`
- Create: `ByteQuest-Mobile-App/lib/screens/simulation/runtime/mission_runtime_action_reducer.dart`
- Modify: `ByteQuest-Mobile-App/lib/screens/simulation/mission_simulation_screen.dart`
- Modify: `ByteQuest-Mobile-App/lib/services/authoritative_assessment_service.dart`
- Modify: `ByteQuest-Mobile-App/lib/services/practice_mission_evidence_service.dart`
- Test: `ByteQuest-Mobile-App/test/mission_runtime_controller_test.dart`
- Test: `ByteQuest-Mobile-App/test/mission_evidence_gateway_test.dart`
- Test: `ByteQuest-Mobile-App/test/authoritative_assessment_service_recovery_test.dart`
- Test: `ByteQuest-Mobile-App/test/practice_mission_evidence_service_test.dart`

**Interfaces:**
- Consumes: RLS-scoped `attempt_actions` and learner-owned `practice_mission_actions`, stable client action IDs, server record identities, and deterministic order columns.
- Produces: ordered acknowledged timeline records and a reducer that reconstructs `MissionRuntimeState` before layering unique pending actions.

- [ ] Add RED tests for no-cache server rebuild, stale snapshot replacement, pending/server de-duplication, equal-time ordering, offline preservation, and cross-session rejection.
- [ ] Return full acknowledged rows from both transports with record identity/order while retaining learner/attempt RLS scope.
- [ ] Persist mission and phase identity inside new assessment action values without adding score/outcome/release authority.
- [ ] Deterministically reduce acknowledged actions from a clean session baseline, overlay local-only camera/motion preferences, then reduce and flush unique pending actions.
- [ ] Preserve version-1 runtime JSON compatibility and run runtime/service recovery tests to GREEN.

### Task 3: Test evidence and connection rendering regressions

**Files:**
- Modify: `ByteQuest-Mobile-App/lib/screens/simulation/interactions/test_run_interaction.dart`
- Modify: `ByteQuest-Mobile-App/lib/screens/simulation/mission_simulation_screen.dart`
- Modify: `ByteQuest-Mobile-App/lib/screens/simulation/components/simulation_scene.dart`
- Test: `ByteQuest-Mobile-App/test/advanced_mission_interactions_test.dart`
- Test: `ByteQuest-Mobile-App/test/mission_simulation_screen_test.dart`
- Test: `ByteQuest-Mobile-App/test/simulation_scene_test.dart`

**Interfaces:**
- Consumes: configured terminal evidence action types and runtime `source>destination` connection pairs.
- Produces: distinct `test_started` and configured terminal events, stable retest counts, and visible actual-catalog connection paths.

- [ ] Add RED tests proving only test completion maps to the configured evidence action and two retests create two starts plus two terminal events.
- [ ] Make test start non-terminal and protect terminal action adaptation from rewriting unrelated events.
- [ ] Add an actual-catalog scene regression for an accepted connection pair.
- [ ] Normalize lookup so both object IDs and declared node IDs resolve to the same scene endpoints.
- [ ] Run the focused interaction/screen/scene tests to GREEN.

### Task 4: Evidence records, gates, and commit

**Files:**
- Modify: `docs/BYTEQUEST_IMPLEMENTATION_FAILURES.md`
- Modify: `docs/BYTEQUEST_IMPLEMENTATION_FAILURE_INDEX.md`
- Modify: `docs/BYTEQUEST_SIMULATION_COMPLETION_REPORT.md`
- Modify: `docs/BYTEQUEST_20_MISSION_SCORECARD.md`
- Modify: `CODEX_STATE.md` when present in this branch, otherwise report canonical-root handoff status without fabricating a worktree copy.

**Interfaces:**
- Consumes: fresh test/analyzer/build/SQL outputs.
- Produces: timestamped failure ledger entries, evidence-calibrated reports, and one exact commit.

- [x] Record every failed operation with Asia/Manila timestamp, location, output, root cause, primary remediation, alternative, and final status; update the index.
- [x] Run focused Flutter tests, full `flutter test`, full `flutter analyze --no-fatal-infos`, and `flutter build apk --debug`.
- [x] Run static SQL policy checks without applying any live database change; keep live rollback execution explicitly unverified.
- [x] Keep authenticated Supabase/emulator and branch integration explicitly unverified/pending.
- [x] Review `git status` and `git diff --stat`, stage exact files, and commit exactly `fix: close final simulation acceptance gaps`.
