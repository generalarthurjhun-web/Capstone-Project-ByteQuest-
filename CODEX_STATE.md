# ByteQuest — Codex Handoff State

> Read this file with `AGENTS.md`, `README.md`, and `bytequest.md` before changing the repository.

## Snapshot

| Field | Value |
|---|---|
| Date | 2026-08-22 |
| Active branch | `Dro-branch` |
| Integrated implementation head | `0ec02ad` (`fix: close final simulation acceptance gaps`) |
| Remote | `origin/Dro-branch` — local branch is ahead; nothing was pushed |
| Primary build target | Android APK (Flutter) |
| Feature worktree | `.worktrees/bytequest-simulation-platform` preserved on `feature/bytequest-simulation-platform` |

## Completed implementation

### Simulation platform

- [x] Responsive reusable 2D scene engine with pan/zoom/reset, landscape support, scene-coordinate scaling, hotspots, connection painter, and object-list alternative.
- [x] Hotspot states: neutral, selected, completed, and error; minimum 48 × 48 dp targets and semantics.
- [x] Tool tray with compatibility checks and structured evidence.
- [x] Fourteen reusable interaction families: inspect, multi-select, tool, connect, configure, sequence, match, controlled placement, troubleshoot, test run, observe, decide, interpret, and evidence review.
- [x] State-driven connection, device, placement, test, and completion transitions with reduced-motion support.
- [x] Explicit review/return/confirm flow with terminal submission latch and pending-evidence retry.

### Twenty-mission catalog

- [x] COC1 M1–M5.
- [x] COC2 M1–M5; protected cable evaluator route retained.
- [x] COC3 M1–M5.
- [x] COC4 M1–M5.
- [x] Exactly 20 stable IDs (`coc1_m1` through `coc4_m5`).
- [x] 116/116 catalog phases render without `TechnicalUnavailableState`.
- [x] Every mission resolves to 2–4 actual rendered interaction families, a real technical decision, and observation/test/verification.
- [x] No mission is drag-drop-only.
- [x] Progressive troubleshooting facts, correction gates, stable retest IDs, and source-linked interpretation are enforced.

### Evidence, persistence, and authority

- [x] Immutable structured evidence actions with stable client IDs and serialized dispatch.
- [x] Assigned assessments retain the authoritative attempt-action gateway.
- [x] Standalone practice evidence uses learner-owned `practice_mission_actions`, active-learner RLS, ownership checks, append-only grants, and idempotent action keys.
- [x] Runtime restore rebuilds state from ordered acknowledged server actions, merges/de-duplicates pending local actions, and preserves local presentation preferences offline.
- [x] Practice and assessment storage are isolated by mode and assessment attempt ID.
- [x] Unknown restored phases fail closed; rejected placements never render success.
- [x] Test start and terminal completion use distinct evidence types; configured evaluator actions occur only on terminal events.
- [x] Supabase/PostgreSQL remains the evaluation authority. Flutter does not calculate score/pass/reward/release, and instructor release remains mandatory.

### Accessibility and quality

- [x] Tap alternatives for drag/connection interactions.
- [x] Semantics and 48 dp minimum targets across enabled interaction states.
- [x] Compact, landscape, 2× text, and reduced-motion widget matrices.
- [x] ByteQuest navy/blue tokens and 150–250 ms state transitions.
- [x] Four showcase candidates: COC1 M3, COC2 M3, COC3 M4, COC4 M5.

## Verification results

Fresh integrated `Dro-branch` evidence:

```text
flutter test                     PASS — 189/189
flutter analyze --no-fatal-infos PASS — 0 errors, 0 warnings, 213 infos
flutter build apk --debug        PASS
catalog phase render gate        PASS — 116/116, 0 unavailable
focused final acceptance gate    PASS — 100/100
static SQL/lifecycle sentinels   PASS — 8/8
whole-branch review              PASS — no Critical/High/Medium findings
```

APK location (ignored): `ByteQuest-Mobile-App/build/app/outputs/flutter-apk/app-debug.apk`; integrated size 195,186,392 bytes; SHA-256 `CE1663F11351B08461719AC4AA9284C251B0DF5346C320618B95A77D9F985410`.

## Durable evidence

- `docs/BYTEQUEST_20_MISSION_SCORECARD.md` — provisional mission-level scores and evidence limits.
- `docs/BYTEQUEST_EMULATOR_QA.md` — Android 16 device metadata and shell/lifecycle QA.
- `docs/BYTEQUEST_SIMULATION_COMPLETION_REPORT.md` — implementation coverage and external blockers.
- `docs/BYTEQUEST_IMPLEMENTATION_FAILURES.md` — timestamped failed operations, causes, fixes, and alternatives.
- `docs/BYTEQUEST_IMPLEMENTATION_FAILURE_INDEX.md` — anchored index of every failure entry.
- `supabase/migrations/20260822124500_practice_mission_evidence.sql` — practice evidence schema/RLS migration.

## External checks still unverified

- Authenticated execution of all 20 missions on the emulator. The APK reached onboarding/login and passed portrait, landscape, 2× text, reduced-motion, background/resume, and force-stop/relaunch checks, but no authorized disposable learner credentials were available.
- `pnpm test:all-missions` and `pnpm test:realtime`. The gitignored dashboard `.env.local` and `BYTEQUEST_E2E_PASSWORD` were unavailable, so both stopped before contacting Supabase.
- Live application of the new migration and rollback lifecycle SQL. Static security/lifecycle assertions pass, but no prepared local/live database connection was authorized.

## QA audit (2026-08-22)

- Added `QA_REPORT.md` after a read-only senior QA pass; no product code was changed during the audit.
- Confirmed startup, onboarding, login navigation, invalid-auth handling, offline cold start, force-stop/relaunch, static analysis, automated tests, and debug APK build.
- Prioritized findings: uncaught missing-Supabase-config startup failure (P1), first-frame/auth jank (P2), and future schematic metadata paths with no bundled assets (P3).
- Authenticated mission/evidence/scoring/realtime checks remain blocked because the supplied learner credentials were rejected by Supabase as invalid; this is recorded as a test-environment limitation in `QA_REPORT.md`.

## Practice regression fixes (2026-08-22)

- Issue found: the shared runtime scene rendered every hotspot as an icon. Existing component PNGs were still present and declared in `pubspec.yaml`, but the catalog's image references were unused metadata; COC3/COC4 had track artwork in `assets/images/` but no scene background binding.
- Fix applied: mission definitions now bind existing COC1/COC2 component assets (and COC3/COC4 track artwork) to every runtime scene object, while the shared hotspot and scene background render those assets with an error fallback. No mission interaction architecture was changed.
- Issue found: `MissionSimulationScreen.initState()` called `requestLandscape()` on every practice entry.
- Fix applied: removed the entry-time landscape request. The app-wide orientation allow-list remains portrait and landscape, so portrait is retained on entry and physical rotation remains natural; exit still restores the supported allow-list.
- Regression coverage: updated the mission orientation widget test and added a catalog-wide visual-asset test covering all 20 missions.
- Validation: `flutter analyze --no-fatal-infos` completed with 0 errors (214 existing informational findings); full `flutter test` passed (191 tests); and `flutter build apk --debug` produced `build/app/outputs/flutter-apk/app-debug.apk`.
- Emulator smoke check: installed the debug APK on `emulator-5554`, launched it, and confirmed the default display remained portrait (`320x640`, rotation `0`). The catalog-wide test covers all 20 mission definitions and their image bindings; interactive manual traversal was not repeated because the app remained at its startup/auth gate in this smoke session.

## Image pipeline follow-up (2026-08-22)

- Root cause confirmed: `MissionContentData.getCOC1M1Items()` had the correct motherboard path (`assets/COC1/Mission 1/motherboard.png`), the file exists, and `pubspec.yaml` registers `assets/COC1/Mission 1/`. However, practice launches `MissionSimulationScreen`; its `TapInspectInteraction` consumed presentation objects that carried labels/IDs only, so the image path stopped between content data and the UI. The previous scene-only metadata binding did not populate those inspection cards.
- A second audit caught one invalid fallback mapping (`assets/COC1/Mission 1/empty_system_unit_case.png`); the file is actually under Mission 2. It was replaced with the existing `assets/COC1/Mission 3/System Unit.png` asset.
- Fix applied: mission presentation objects now receive `imageAsset` metadata, `TapInspectInteraction` renders the asset with `Image.asset`, and visible error builders plus temporary `[ByteQuest image]` path/existence/error logging expose failures instead of silently showing a blank fallback. Scene hotspots and workspace artwork retain the same diagnostics.
- Validation: motherboard, CPU, RAM, PSU, and anti-static strap paths logged as existing through Flutter's asset bundle; the catalog-wide asset-bundle test passed for all COC1–COC4 mission scene assets; targeted scene tests passed (10 tests). Full analyze/test/build should be rerun after this follow-up patch.
- Failed operation: 2026-08-22 15:42 +08:00, first targeted `flutter test` attempt hit a Flutter test-cache `PathExistsException` at `build/test_cache/...cache.dill.track.dill` (transient concurrent cache write). Re-running after the cache settled passed; alternative resolution is to stop competing Flutter/Dart processes and clear only the generated `build/test_cache` directory before rerunning.

Do not weaken authentication, RLS, backend evaluation, or instructor-release controls to bypass these evidence gaps. Close them in an authorized test environment with disposable learner/instructor credentials and protected secrets.

## Targeted image propagation follow-up (2026-08-22)

- Root cause refinement: inspect phases without an explicit `objects` list fell back to bare IDs in `interactionItems`, dropping `description` and `imageAsset` before `TapInspectInteraction`.
- Fix applied: `InteractionItem` now carries typed `id`, `label`, `description`, and `imageAsset` fields; mission-definition normalization supplies explicit inspect objects from the mission catalog; `TapInspectInteraction` passes those fields into the shared `_InspectionImage`, which renders with `Image.asset`.
- Validation: targeted scene/screen tests passed (37 tests); COC1 M1 motherboard, CPU, RAM, PSU, and anti-static strap paths logged as existing; COC1 M2 fallback inspect objects logged bundled paths; catalog asset-bundle coverage passed; full `flutter test` passed (191 tests); `flutter analyze --no-fatal-infos` passed with 0 errors and 214 informational findings; `flutter build apk --debug` passed and produced `build/app/outputs/flutter-apk/app-debug.apk`.

## Inspection image layout follow-up (2026-08-22)

- Issue found: Flutter's renderer reported `Width is zero. 0,0` during emulator startup. The image asset pipeline itself was healthy; `_InspectionImage` had only a fixed height and relied on an upstream width that could be zero during an unconstrained frame.
- Fix applied: `_InspectionImage` now logs MediaQuery size, parent constraints, and final widget dimensions. It resolves a positive bounded width from its parent constraints, falling back to the current MediaQuery width when the parent reports zero/unbounded width, then passes explicit width and height to `Image.asset`.
- Validation: `flutter test test/mission_simulation_screen_test.dart` passed (27 tests); logs showed COC1 M1 images receiving 287.6x120 constraints and assets resolving. `flutter test` previously passed (191 tests). `flutter run -d emulator-5554 --debug` built, installed, and launched successfully; the remaining zero-width logs occurred before viewport metrics during startup, not in `_InspectionImage` layout logs. The account session was at the app gate, so direct COC1 M1 visual traversal remains pending.

## Technical workspace hotspot image fix (2026-08-22)

- Issue found: `HotspotWidget` did receive the correct COC1 M1 metadata and called `Image.asset`, but its default loose `Stack` sized itself from the 24dp state icon. The `Positioned.fill` image therefore rendered inside an icon-sized stack, appearing as an empty/tiny placeholder in the workspace.
- Fix applied: set the shared hotspot `Stack` to `StackFit.expand`, so workspace images fill the mapped hotspot bounds while preserving the existing icon/state overlay and interaction behavior. Added temporary workspace logs for object ID, label, image path, asset-call branch, and asset-bundle existence.
- Validation: live COC1 M1 emulator logs confirmed motherboard, CPU, RAM, PSU, and anti-static strap image branches and existing assets; hot-reloaded emulator screenshot visibly showed all five workspace images. `flutter analyze --no-fatal-infos` passed with 0 errors and 214 informational findings; full `flutter test` passed (191 tests).

## Phase 9 compliance audit (2026-08-22)

- Branch: `Dro-branch`; no commit was created for this audit.
- Completed: read `bytequest.md`/`README.md`; statically audited all 20 COC1–COC4 mission definitions, learning-loop coverage, interaction families, evidence/persistence contracts, accessibility gates, assessment safeguards, and reusable simulation systems.
- Validation: `flutter test` passed (191); `flutter analyze --no-fatal-infos` passed with 0 errors and 214 informational findings; `flutter build apk --debug` passed. Emulator practice shell launched and COC1 M1 was opened; workspace images were visible.
- Audit result: 90% structural to-do compliance (270/300 Phase 1 checklist points). All 20 missions satisfy static phase-count/family/decision/verification/review gates, but the broad literal loop is partial for missions that intentionally omit configuration or troubleshooting.
- Remaining risks: full manual COC1 M1–M5 and COC2–COC4 M1–M5 traversal was not completed; authenticated Supabase evidence writes/reconciliation, backend evaluation, realtime instructor receipt/release, learner result propagation, and process-death/offline reconnect remain unverified. COC3/COC4 scene visuals remain generic schematic/track artwork. Startup jank and missing Supabase-config fail-closed behavior remain documented QA findings.
- Next action: provision disposable learner/instructor fixtures, execute the 20-mission manual/runtime/backend acceptance matrix, capture evidence, then rerun QA_REPORT.md before any release decision.

## Known non-blocking maintenance

- Analyzer informational notices remain, primarily `prefer_const_constructors`, deprecated `.withOpacity`, and existing async-context notices.
- Android build warns that Kotlin 2.2.20 and legacy Kotlin Gradle Plugin application will require future migration; `shared_preferences_android` also applies KGP.
- Android SDK XML tooling versions are mismatched but do not block the current debug build.
- Code-drawn schematic scenes are approved placeholders; replace them with production art later without changing scene/evidence contracts.

## Git handoff

- Reviewed feature commits were transplanted locally onto `Dro-branch`; duplicate rename commit `7878107` was intentionally skipped because `Dro-branch` already contained the canonical `ByteQuest-Mobile-App` rename.
- `main` was not modified.
- Nothing was pushed.
- The feature branch/worktree is preserved for audit and must not be deleted without explicit authorization.

## Project checkpoint (2026-08-22 16:44 +08:00)

- Current branch: `Dro-branch`.
- Current worktree: uncommitted implementation changes are present; pre-existing `bytequest.md` edits and `QA_REPORT.md` remain preserved. No commit or push was made.
- Completed work:
  - Traced the COC1 M1 motherboard image from `MissionContentData` through mission definitions, presentation metadata, and the shared inspection/hotspot renderers.
  - Restored image delivery to practice inspection cards and scene hotspots using existing bundled assets.
  - Removed automatic landscape entry behavior while retaining natural device rotation and exit orientation restoration.
  - Added visible image error states and temporary asset path/existence diagnostics.
  - Added catalog-wide image-path and COC1 M1 motherboard regression coverage.
- Files changed by this work:
  - `ByteQuest-Mobile-App/lib/data/mission_simulation_definitions.dart`
  - `ByteQuest-Mobile-App/lib/screens/simulation/components/hotspot_widget.dart`
  - `ByteQuest-Mobile-App/lib/screens/simulation/components/simulation_scene.dart`
  - `ByteQuest-Mobile-App/lib/screens/simulation/interactions/tap_inspect_interaction.dart`
  - `ByteQuest-Mobile-App/lib/screens/simulation/mission_simulation_screen.dart`
  - `ByteQuest-Mobile-App/test/mission_simulation_screen_test.dart`
  - `ByteQuest-Mobile-App/test/simulation_scene_test.dart`
  - `CODEX_STATE.md`
- Validation results:
  - `flutter analyze --no-fatal-infos`: PASS, 0 errors; 214 existing informational findings.
  - `flutter test`: PASS, 191 tests.
  - `flutter build apk --debug`: PASS; APK generated at `ByteQuest-Mobile-App/build/app/outputs/flutter-apk/app-debug.apk`.
  - Flutter asset-bundle audit: PASS for all catalog COC1–COC4 scene assets; COC1 M1 motherboard, CPU, RAM, PSU, and anti-static strap paths logged as present.
  - `git diff --check`: PASS.
  - Emulator smoke: debug APK installed on `emulator-5554`; portrait launch confirmed. Full practice traversal was unavailable because the current emulator session showed no assigned/unlocked practice activities.
- Remaining tasks:
  - Review the uncommitted diff and approve the image/orientation changes before committing.
  - Repeat direct emulator traversal of COC1 M1–M5 and COC2–COC4 M1–M5 once practice activities are available in the account/session; confirm visual appearance, rotation, and exit behavior.
  - Decide whether temporary `[ByteQuest image]` diagnostics should be removed or retained behind a debug-only flag before release.
  - Resolve previously documented QA/environment blockers (Supabase-authenticated mission run, dashboard E2E/realtime checks, and live migration lifecycle verification) in an authorized environment.
- Exact next steps:
  1. Review `git diff --stat`, `git diff --check`, and the complete diff for scope/regressions.
  2. Install the freshly built APK and unlock/open COC1 M1 in the emulator.
  3. Confirm the motherboard image is visible in the inspection card and scene; inspect logcat for successful asset resolution and absence of error-builder output.
  4. Repeat the same check across all 20 practice missions, including portrait entry, physical rotation, and orientation restoration after exit.
  5. Remove or gate temporary diagnostics if the review approves, rerun analyze/test/build, then request explicit commit approval.
