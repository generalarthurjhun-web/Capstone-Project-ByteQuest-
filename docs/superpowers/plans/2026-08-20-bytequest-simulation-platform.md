# ByteQuest Simulation Platform Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver a reusable, accessible 2D Flutter simulation runtime and make all 20 ByteQuest missions satisfy the workflow, evidence, persistence, assessment-integrity, and QA requirements in `bytequest.md`.

**Architecture:** Extend the existing authoritative mission renderer into a typed, data-driven runtime. Split scene and interaction responsibilities into focused files, keep Supabase/PostgreSQL authoritative, and express each mission as a validated definition rather than a separate large screen.

**Tech Stack:** Flutter/Dart, Material, CustomPainter, InteractiveViewer, SharedPreferences, Supabase Flutter, flutter_test.

**Spec:** `docs/superpowers/specs/2026-08-20-bytequest-simulation-platform-design.md`

## Global Constraints

- Work only in the canonical `ByteQuest-Mobile-App/` directory; preserve the user-owned rename from `ByteQuest Mobile App/`.
- Preserve COC1 M2, COC1 M3, and COC2 M2 evaluator contracts and all existing PostgreSQL authority boundaries.
- Assessment UI must not receive expected answers, scores, pass flags, XP, or rewards.
- Every meaningful action emits ordered structured evidence; restore must not duplicate evidence or submit/evaluate.
- Every mission has three to six meaningful phases, two to four interaction families, a technical decision, verification, and explicit submission review.
- Implement all 14 interaction rows named in `bytequest.md`, despite that document calling them “12 components.”
- All drag, placement, connection, and sequencing gestures have tap/button alternatives; targets are at least 48×48 dp or available through an object list.
- Use 150–250 ms state-driven transitions and respect reduced motion.
- Missing artwork uses replaceable Flutter-rendered schematic scenes.
- Use TDD: add a focused failing test, confirm the failure, implement the smallest coherent slice, then rerun focused and regression tests.
- Record every failed operation in `docs/BYTEQUEST_IMPLEMENTATION_FAILURES.md` with Asia/Manila timestamp, command/interaction, file and line or “not applicable,” output, root cause, primary remediation, alternative remediation, and status.

## File Structure

Create these focused runtime files:

- `ByteQuest-Mobile-App/lib/screens/simulation/runtime/mission_runtime_models.dart` — immutable mission definitions, runtime state, actions, serialization.
- `ByteQuest-Mobile-App/lib/screens/simulation/runtime/mission_runtime_controller.dart` — state transitions, lifecycle save/restore, evidence reconciliation.
- `ByteQuest-Mobile-App/lib/screens/simulation/runtime/mission_evidence_gateway.dart` — stable action IDs and authoritative evidence queue adapter.
- `ByteQuest-Mobile-App/lib/screens/simulation/components/simulation_scene.dart` — camera, responsive logical canvas, schematic renderer, overlays.
- `ByteQuest-Mobile-App/lib/screens/simulation/components/hotspot_widget.dart` — accessible mapped hotspot.
- `ByteQuest-Mobile-App/lib/screens/simulation/components/tool_tray.dart` — tools, compatibility, technical feedback.
- `ByteQuest-Mobile-App/lib/screens/simulation/components/scene_connection_painter.dart` — state-driven cable/link drawing.
- `ByteQuest-Mobile-App/lib/screens/simulation/interactions/mission_interactions.dart` — exports the interaction widgets.
- One file per interaction under `interactions/` to keep each widget independently testable.
- `ByteQuest-Mobile-App/lib/data/mission_simulation_definitions.dart` — catalog and lookup for all 20 definitions.
- `ByteQuest-Mobile-App/lib/screens/simulation/mission_simulation_screen.dart` — runtime composition shell.

Modify existing integration files:

- `ByteQuest-Mobile-App/lib/screens/simulation/components/simulation_framework.dart` — retain presentation helpers; delegate extracted scene/interactions and remove duplicate implementations.
- `ByteQuest-Mobile-App/lib/screens/simulation/mission_launcher.dart` — route all mission IDs to the runtime while retaining explicitly protected legacy adapters.
- `ByteQuest-Mobile-App/lib/data/mission_content_data.dart` — stable mission feedback catalogs.
- `ByteQuest-Mobile-App/lib/services/progress_resume_service.dart` — versioned snapshots and cache validation.
- `ByteQuest-Mobile-App/lib/services/authoritative_assessment_service.dart` — stable client action ID reconciliation without changing server authority.
- `ByteQuest-Mobile-App/lib/screens/simulation/result_screen.dart` — reuse the review panel and block incomplete synchronization.

---

### Task 1: Baseline, Failure Ledger, and Mission Contract Inventory

**Files:**
- Create: `docs/BYTEQUEST_IMPLEMENTATION_FAILURES.md`
- Create: `ByteQuest-Mobile-App/test/mission_catalog_acceptance_test.dart`
- Modify: `ByteQuest-Mobile-App/test/simulation_framework_test.dart`

**Interfaces:**
- Consumes: existing `MissionContentData`, `MissionSimulationProfiles`, `AuthoritativeMissionContract`, and `MissionLauncher` behavior.
- Produces: an executable acceptance inventory that later tasks must satisfy.

- [ ] **Step 1: Record known discovery failure**

Create the ledger with this resolved entry and retain its exact facts:

```markdown
# ByteQuest Implementation Failure Log

## 2026-08-20 20:31:08 +08:00 — Simulation framework discovery path

- Operation: Read the active simulation framework during repository discovery.
- Command: `Get-Content -Raw .\ByteQuest-Mobile-App\lib\screens\simulation\simulation_framework.dart`
- Affected location: PowerShell probe line 7; requested repository path did not exist.
- Observed result: `PathNotFound`.
- Root cause: The framework is under `lib/screens/simulation/components/simulation_framework.dart`.
- Primary solution: Read and modify the file at its actual component path.
- Alternatives: Locate it with `rg --files -g simulation_framework.dart`; or import the extracted component files directly after Task 4.
- Status: Resolved.
```

- [ ] **Step 2: Write the failing 20-mission catalog test**

Add a test that imports `mission_simulation_definitions.dart` and asserts:

```dart
test('catalog covers every COC mission with required phase depth', () {
  final definitions = MissionSimulationDefinitions.all;
  expect(definitions, hasLength(20));
  expect(definitions.map((item) => item.id).toSet(), hasLength(20));
  for (final definition in definitions) {
    expect(definition.phases.length, inInclusiveRange(3, 6),
        reason: definition.id);
    expect(definition.interactionFamilies.length, inInclusiveRange(2, 4),
        reason: definition.id);
    expect(definition.hasTechnicalDecision, isTrue, reason: definition.id);
    expect(definition.hasVerification, isTrue, reason: definition.id);
  }
});
```

- [ ] **Step 3: Run the new test and capture the expected failure**

Run: `flutter test test/mission_catalog_acceptance_test.dart`

Expected: FAIL because `mission_simulation_definitions.dart` does not exist. If the failure differs, append it to the failure ledger before continuing.

- [ ] **Step 4: Run the existing baseline gates**

Run:

```powershell
flutter analyze --no-fatal-infos
flutter test
```

Expected: existing baseline passes. Record every pre-existing failure without attributing it to new work.

- [ ] **Step 5: Commit the acceptance inventory**

```powershell
git add -- docs/BYTEQUEST_IMPLEMENTATION_FAILURES.md ByteQuest-Mobile-App/test/mission_catalog_acceptance_test.dart ByteQuest-Mobile-App/test/simulation_framework_test.dart
git commit -m "test: define simulation platform acceptance"
```

---

### Task 2: Runtime Models and Versioned Serialization

**Files:**
- Create: `ByteQuest-Mobile-App/lib/screens/simulation/runtime/mission_runtime_models.dart`
- Create: `ByteQuest-Mobile-App/test/mission_runtime_models_test.dart`

**Interfaces:**
- Produces: `MissionSimulationDefinition`, `SimulationSceneDefinition`, `SceneObjectDefinition`, `MissionPhaseDefinition`, `MissionRuntimeState`, `MissionEvidenceAction`, `InteractionFamily`, `HotspotVisualState`, and JSON codecs.
- Consumes: no UI or Supabase APIs.

- [ ] **Step 1: Write failing serialization and invariant tests**

Cover round-trip preservation and invariant rejection:

```dart
test('runtime state round trip preserves resume-critical fields', () {
  final state = MissionRuntimeState.initial('coc2_m3').copyWith(
    currentPhaseId: 'verify_links',
    selectedToolId: 'lan_tester',
    connectedNodePairs: const {'pc1>switch1'},
    acceptedEvidenceIds: const {'action-1'},
  );
  expect(MissionRuntimeState.fromJson(state.toJson()), state);
});

test('definition rejects phase counts outside three to six', () {
  expect(() => testDefinition(phases: const []), throwsArgumentError);
});
```

- [ ] **Step 2: Confirm the model test fails**

Run: `flutter test test/mission_runtime_models_test.dart`

Expected: FAIL with missing runtime model types.

- [ ] **Step 3: Implement exact model contracts**

Use these stable signatures:

```dart
enum InteractionFamily { inspect, select, tool, connect, configure, sequence, match, place, troubleshoot, testRun, observe, decide, interpret, review }
enum HotspotVisualState { neutral, selected, completed, error }

final class MissionEvidenceAction {
  const MissionEvidenceAction({required this.clientActionId, required this.missionId, required this.phaseId, required this.actionType, this.target, required this.value, required this.occurredAt});
  final String clientActionId;
  final String missionId;
  final String phaseId;
  final String actionType;
  final String? target;
  final Map<String, dynamic> value;
  final DateTime occurredAt;
}

final class MissionRuntimeState {
  static const schemaVersion = 1;
  factory MissionRuntimeState.initial(String missionId);
  factory MissionRuntimeState.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
  MissionRuntimeState copyWith({String? currentPhaseId, String? selectedToolId, Set<String>? connectedNodePairs, Set<String>? acceptedEvidenceIds});
}
```

Implement structural equality so state round-trip assertions are reliable.

- [ ] **Step 4: Run focused tests**

Run: `flutter test test/mission_runtime_models_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit the runtime model**

```powershell
git add -- ByteQuest-Mobile-App/lib/screens/simulation/runtime/mission_runtime_models.dart ByteQuest-Mobile-App/test/mission_runtime_models_test.dart
git commit -m "feat: add typed mission runtime state"
```

---

### Task 3: Evidence Gateway and Idempotent Resume Reconciliation

**Files:**
- Create: `ByteQuest-Mobile-App/lib/screens/simulation/runtime/mission_evidence_gateway.dart`
- Create: `ByteQuest-Mobile-App/lib/screens/simulation/runtime/mission_runtime_controller.dart`
- Create: `ByteQuest-Mobile-App/test/mission_evidence_gateway_test.dart`
- Create: `ByteQuest-Mobile-App/test/mission_runtime_controller_test.dart`
- Modify: `ByteQuest-Mobile-App/lib/services/authoritative_assessment_service.dart`
- Modify: `ByteQuest-Mobile-App/lib/services/progress_resume_service.dart`

**Interfaces:**
- Consumes: Task 2 runtime models, `AuthoritativeAssessmentService.recordAction`, `getActiveAttemptActions`, and SharedPreferences.
- Produces: `MissionEvidenceGateway.record`, `MissionEvidenceGateway.reconcile`, `MissionRuntimeController.dispatch`, `restore`, `flushPending`, and `canSubmit`.

- [ ] **Step 1: Write failing duplicate-prevention tests**

```dart
test('reconcile never appends an acknowledged action twice', () async {
  final transport = FakeEvidenceTransport(existingIds: {'stable-1'});
  final gateway = MissionEvidenceGateway(transport: transport);
  await gateway.reconcile([
    action(clientActionId: 'stable-1'),
    action(clientActionId: 'stable-2'),
  ]);
  expect(transport.appendedIds, ['stable-2']);
});

test('restore does not submit or evaluate', () async {
  final controller = runtimeControllerWithSavedState();
  await controller.restore();
  expect(controller.transport.submitCalls, 0);
});
```

- [ ] **Step 2: Confirm focused tests fail**

Run: `flutter test test/mission_evidence_gateway_test.dart test/mission_runtime_controller_test.dart`

Expected: FAIL because gateway/controller APIs do not exist.

- [ ] **Step 3: Add the transport boundary**

Use:

```dart
abstract interface class MissionEvidenceTransport {
  Future<void> append(MissionEvidenceAction action);
  Future<Set<String>> acknowledgedClientActionIds();
}
```

Map `clientActionId` into the existing evidence `value` as `client_action_id`. Never add local score or correctness fields. Query active actions and extract this value for reconciliation.

- [ ] **Step 4: Version ProgressResumeService snapshots**

Add `saveMissionRuntime`, `loadMissionRuntime`, and `clearMissionRuntime` wrappers. Reject snapshots whose `schemaVersion` is not `MissionRuntimeState.schemaVersion`; return a typed empty restoration rather than throwing.

- [ ] **Step 5: Implement dispatch ordering**

`dispatch` must generate the stable ID, persist the pending action and updated UI state, enqueue evidence, then mark the ID acknowledged after the server write. `canSubmit` is true only when the final review phase is reached and no pending/failed action remains.

- [ ] **Step 6: Run focused and existing assessment tests**

Run:

```powershell
flutter test test/mission_evidence_gateway_test.dart test/mission_runtime_controller_test.dart
flutter test test/authoritative_mission_contract_test.dart test/authoritative_mission_assessment_widget_test.dart test/coc2_cable_assessment_contract_test.dart
```

Expected: PASS.

- [ ] **Step 7: Commit evidence and persistence**

```powershell
git add -- ByteQuest-Mobile-App/lib/screens/simulation/runtime ByteQuest-Mobile-App/lib/services/authoritative_assessment_service.dart ByteQuest-Mobile-App/lib/services/progress_resume_service.dart ByteQuest-Mobile-App/test/mission_evidence_gateway_test.dart ByteQuest-Mobile-App/test/mission_runtime_controller_test.dart
git commit -m "feat: reconcile resumable mission evidence"
```

---

### Task 4: Extract the Responsive Scene Engine

**Files:**
- Create: `ByteQuest-Mobile-App/lib/screens/simulation/components/simulation_scene.dart`
- Create: `ByteQuest-Mobile-App/lib/screens/simulation/components/hotspot_widget.dart`
- Create: `ByteQuest-Mobile-App/lib/screens/simulation/components/scene_connection_painter.dart`
- Create: `ByteQuest-Mobile-App/test/simulation_scene_test.dart`
- Modify: `ByteQuest-Mobile-App/lib/screens/simulation/components/simulation_framework.dart`

**Interfaces:**
- Consumes: `SimulationSceneDefinition`, `SceneObjectDefinition`, runtime hotspot/connection state.
- Produces: `SimulationScene`, `HotspotWidget`, `SceneConnectionPainter`, reset/fit callbacks, accessible object picker.

- [ ] **Step 1: Write failing camera, sizing, and semantics tests**

```dart
testWidgets('hotspot exposes a minimum 48 dp semantic tap target', (tester) async {
  await tester.pumpWidget(testSceneWithTinyLogicalHotspot());
  final size = tester.getSize(find.byKey(const Key('hotspot-port-1')));
  expect(size.width, greaterThanOrEqualTo(48));
  expect(size.height, greaterThanOrEqualTo(48));
  expect(find.bySemanticsLabel('Server LAN port, neutral'), findsOneWidget);
});

testWidgets('reset camera returns InteractiveViewer to identity', (tester) async {
  await tester.pumpWidget(testScene());
  await tester.drag(find.byType(InteractiveViewer), const Offset(120, 40));
  await tester.tap(find.byTooltip('Reset workspace view'));
  await tester.pump();
  expect(sceneTransformation(tester), Matrix4.identity());
});
```

- [ ] **Step 2: Confirm scene tests fail**

Run: `flutter test test/simulation_scene_test.dart`

Expected: FAIL because extracted files and exact controls do not exist.

- [ ] **Step 3: Extract and generalize the existing scene**

Move the current `SimulationScene` implementation out of `simulation_framework.dart`. Render a 1200×720 logical workspace with `LayoutBuilder`, `InteractiveViewer`, a schematic background, connection painter, and normalized hotspot rectangles. Keep `TransformationController` internal and expose reset/fit buttons.

- [ ] **Step 4: Add accessible object-list selection**

Render an “Objects” control that opens a compact bottom sheet/list. Selecting an entry invokes the same callback as the scene hotspot; do not create a separate evidence path.

- [ ] **Step 5: Add state-driven connection animation**

`SceneConnectionPainter` receives immutable connection state. Use a 200 ms animation when reduced motion is false and immediate rendering otherwise.

- [ ] **Step 6: Run scene and regression tests**

Run:

```powershell
flutter test test/simulation_scene_test.dart test/simulation_framework_test.dart
flutter analyze --no-fatal-infos
```

Expected: PASS.

- [ ] **Step 7: Commit the engine extraction**

```powershell
git add -- ByteQuest-Mobile-App/lib/screens/simulation/components ByteQuest-Mobile-App/test/simulation_scene_test.dart ByteQuest-Mobile-App/test/simulation_framework_test.dart
git commit -m "feat: add responsive simulation scene engine"
```

---

### Task 5: Tool System and Core Accessible Interactions

**Files:**
- Create: `ByteQuest-Mobile-App/lib/screens/simulation/components/tool_tray.dart`
- Create: `ByteQuest-Mobile-App/lib/screens/simulation/interactions/tap_inspect_interaction.dart`
- Create: `ByteQuest-Mobile-App/lib/screens/simulation/interactions/multi_select_interaction.dart`
- Create: `ByteQuest-Mobile-App/lib/screens/simulation/interactions/tool_selection_interaction.dart`
- Create: `ByteQuest-Mobile-App/lib/screens/simulation/interactions/connection_interaction.dart`
- Create: `ByteQuest-Mobile-App/lib/screens/simulation/interactions/configuration_panel.dart`
- Create: `ByteQuest-Mobile-App/lib/screens/simulation/interactions/sequencing_interaction.dart`
- Create: `ByteQuest-Mobile-App/lib/screens/simulation/interactions/matching_interaction.dart`
- Create: `ByteQuest-Mobile-App/lib/screens/simulation/interactions/controlled_placement_interaction.dart`
- Create: `ByteQuest-Mobile-App/lib/screens/simulation/interactions/mission_interactions.dart`
- Create: `ByteQuest-Mobile-App/test/core_mission_interactions_test.dart`

**Interfaces:**
- Consumes: runtime definitions/state/controller from Tasks 2–3 and scene callbacks from Task 4.
- Produces: eight reusable interaction widgets plus `ToolTray` with `onAction(MissionEvidenceActionDraft)` callbacks.

- [ ] **Step 1: Write failing compatibility and alternative-input tests**

Test that an incompatible tool emits feedback ID `tool_incompatible`, that connection supports source-select then destination-select, that placement supports select/place buttons, and that sequencing exposes Move up/Move down semantics.

- [ ] **Step 2: Confirm the tests fail**

Run: `flutter test test/core_mission_interactions_test.dart`

Expected: FAIL with missing widget imports.

- [ ] **Step 3: Implement ToolTray**

Use the stable callback:

```dart
typedef MissionActionCallback = Future<void> Function(
  String actionType,
  String? target,
  Map<String, dynamic> value,
);
```

Compatibility is presentation validation from tool/hotspot categories. Both valid and technically meaningful invalid attempts call `onAction`; widgets request copy by feedback ID and never render “Wrong” or “Correct.”

- [ ] **Step 4: Implement inspect, select, connection, and configuration interactions**

Each widget receives only its phase definition and current runtime state. All action values include `input_method` (`tap`, `drag`, `button`, or `keyboard`) so accessibility alternatives produce equivalent evidence.

- [ ] **Step 5: Implement sequence, match, and placement alternatives**

Drag may remain available, but every operation must be completable through explicit controls and semantic announcements.

- [ ] **Step 6: Run focused, accessibility, and regression tests**

Run:

```powershell
flutter test test/core_mission_interactions_test.dart test/drag_drop_accessibility_test.dart test/simulation_framework_test.dart
flutter analyze --no-fatal-infos
```

Expected: PASS with no generic correctness labels in reusable widgets.

- [ ] **Step 7: Commit the first interaction set**

```powershell
git add -- ByteQuest-Mobile-App/lib/screens/simulation/components/tool_tray.dart ByteQuest-Mobile-App/lib/screens/simulation/interactions ByteQuest-Mobile-App/test/core_mission_interactions_test.dart
git commit -m "feat: add accessible mission interactions"
```

---

### Task 6: Branching, Testing, Interpretation, and Review Interactions

**Files:**
- Create: `ByteQuest-Mobile-App/lib/screens/simulation/interactions/troubleshooting_branch_interaction.dart`
- Create: `ByteQuest-Mobile-App/lib/screens/simulation/interactions/test_run_interaction.dart`
- Create: `ByteQuest-Mobile-App/lib/screens/simulation/interactions/observation_interaction.dart`
- Create: `ByteQuest-Mobile-App/lib/screens/simulation/interactions/scenario_decision_interaction.dart`
- Create: `ByteQuest-Mobile-App/lib/screens/simulation/interactions/result_interpretation_interaction.dart`
- Create: `ByteQuest-Mobile-App/lib/screens/simulation/interactions/evidence_review_panel.dart`
- Create: `ByteQuest-Mobile-App/test/advanced_mission_interactions_test.dart`
- Modify: `ByteQuest-Mobile-App/lib/screens/simulation/interactions/mission_interactions.dart`
- Modify: `ByteQuest-Mobile-App/lib/screens/simulation/result_screen.dart`

**Interfaces:**
- Consumes: `MissionActionCallback`, runtime branch/test/review state, active attempt evidence loader.
- Produces: six advanced interactions and a reusable submission review panel.

- [ ] **Step 1: Write failing progressive-disclosure and review tests**

```dart
testWidgets('diagnostic action reveals exactly one new fact', (tester) async {
  await tester.pumpWidget(troubleshootingHarness());
  expect(find.text('Cable continuity: open circuit'), findsNothing);
  await tester.tap(find.text('Run cable test'));
  await tester.pump();
  expect(find.text('Cable continuity: open circuit'), findsOneWidget);
  expect(find.text('Root cause: damaged cable'), findsNothing);
});

testWidgets('review blocks submit while evidence is pending', (tester) async {
  await tester.pumpWidget(reviewHarness(pendingEvidenceCount: 1));
  expect(tester.widget<FilledButton>(find.byKey(const Key('submit-evidence'))).onPressed, isNull);
});
```

- [ ] **Step 2: Confirm focused tests fail**

Run: `flutter test test/advanced_mission_interactions_test.dart`

Expected: FAIL with missing advanced widget types.

- [ ] **Step 3: Implement progressive troubleshooting**

Each diagnostic action unlocks only its configured `revealsFactId`. Root-cause labels are absent from initial UI and no branch embeds an assessment answer into visible feedback.

- [ ] **Step 4: Implement test and interpretation flow**

`TestRunInteraction` records start/completion and shows a 200 ms state change in tests via injectable duration. `ObservationInteraction` and `ResultInterpretationInteraction` emit learner-provided values without client correctness evaluation.

- [ ] **Step 5: Implement scenario decisions and evidence review**

The decision widget restricts later available phase actions through runtime transition rules. `EvidenceReviewPanel` renders completed phases, authoritative count, retry state, Return, and explicit Confirm; it disables Confirm until `canSubmit` is true.

- [ ] **Step 6: Integrate the review panel into ResultScreen**

Retain existing authoritative submission copy and released-result behavior. Replace duplicated evidence-list presentation only when the reusable panel fully covers it.

- [ ] **Step 7: Run focused and result regressions**

Run:

```powershell
flutter test test/advanced_mission_interactions_test.dart test/authoritative_mission_assessment_widget_test.dart
flutter analyze --no-fatal-infos
```

Expected: PASS.

- [ ] **Step 8: Commit advanced interactions**

```powershell
git add -- ByteQuest-Mobile-App/lib/screens/simulation/interactions ByteQuest-Mobile-App/lib/screens/simulation/result_screen.dart ByteQuest-Mobile-App/test/advanced_mission_interactions_test.dart
git commit -m "feat: add diagnostic and evidence review flows"
```

---

### Task 7: Build and Validate the 20-Mission Catalog

**Files:**
- Create: `ByteQuest-Mobile-App/lib/data/mission_simulation_definitions.dart`
- Create: `ByteQuest-Mobile-App/lib/data/mission_definitions/coc1_definitions.dart`
- Create: `ByteQuest-Mobile-App/lib/data/mission_definitions/coc2_definitions.dart`
- Create: `ByteQuest-Mobile-App/lib/data/mission_definitions/coc3_definitions.dart`
- Create: `ByteQuest-Mobile-App/lib/data/mission_definitions/coc4_definitions.dart`
- Modify: `ByteQuest-Mobile-App/lib/data/mission_content_data.dart`
- Modify: `ByteQuest-Mobile-App/test/mission_catalog_acceptance_test.dart`
- Modify: `ByteQuest-Mobile-App/test/content_consistency_test.dart`

**Interfaces:**
- Consumes: Task 2 definition models and all Task 5–6 interaction families.
- Produces: `MissionSimulationDefinitions.all`, `MissionSimulationDefinitions.byId(String)`, and mission feedback lookup.

- [ ] **Step 1: Expand catalog acceptance tests to the exact matrix**

Encode the 20 mission requirements from spec sections COC1–COC4 as expected interaction sets. Also assert every feedback ID resolves, each troubleshooting mission has at least two diagnostic actions, every mission ends in verification/review, and no mission is drag-only.

- [ ] **Step 2: Confirm catalog tests still fail**

Run: `flutter test test/mission_catalog_acceptance_test.dart test/content_consistency_test.dart`

Expected: FAIL because definitions and feedback entries are incomplete.

- [ ] **Step 3: Implement COC1 definitions**

Define M1–M5 with the exact flows in the approved spec. Adapt M2/M3 presentation to protected existing action types; do not alter expected rubric values.

- [ ] **Step 4: Implement COC2 definitions**

Define M1–M5. COC2 M2 uses its existing cable contract identifiers and evaluator rules while adding scene/device context and accessible controls.

- [ ] **Step 5: Implement COC3 definitions**

Define server preparation, installation, accounts/permissions, services, and troubleshooting flows with progressive visibility.

- [ ] **Step 6: Implement COC4 definitions**

Define inspection, hardware diagnosis, progressive software/network diagnosis, corrective action, and final maintenance/report flows.

- [ ] **Step 7: Add all technical feedback entries**

Store concise constraint-based messages under stable mission/feedback keys. Add a test rejecting exact generic strings `Wrong`, `Correct`, `Try again`, and `Incorrect` when they appear alone.

- [ ] **Step 8: Run catalog and content tests**

Run:

```powershell
flutter test test/mission_catalog_acceptance_test.dart test/content_consistency_test.dart
flutter analyze --no-fatal-infos
```

Expected: PASS for 20 unique missions and all completeness rules.

- [ ] **Step 9: Commit the catalog**

```powershell
git add -- ByteQuest-Mobile-App/lib/data ByteQuest-Mobile-App/test/mission_catalog_acceptance_test.dart ByteQuest-Mobile-App/test/content_consistency_test.dart
git commit -m "feat: define all twenty simulation missions"
```

---

### Task 8: Runtime Mission Screen and Launcher Integration

**Files:**
- Create: `ByteQuest-Mobile-App/lib/screens/simulation/mission_simulation_screen.dart`
- Create: `ByteQuest-Mobile-App/test/mission_launcher_test.dart`
- Create: `ByteQuest-Mobile-App/test/mission_simulation_screen_test.dart`
- Modify: `ByteQuest-Mobile-App/lib/screens/simulation/mission_launcher.dart`
- Modify: `ByteQuest-Mobile-App/lib/screens/simulation/templates/authoritative_mission_assessment_screen.dart`
- Modify: `ByteQuest-Mobile-App/lib/screens/simulation/templates/coc1_m2_screen_enhanced.dart`
- Modify: `ByteQuest-Mobile-App/lib/screens/simulation/templates/coc1_m3_screen_enhanced.dart`
- Modify: `ByteQuest-Mobile-App/lib/screens/simulation/templates/coc2_cable_termination_assessment_screen.dart`

**Interfaces:**
- Consumes: catalog, controller, scene, interaction widgets, existing authoritative contracts.
- Produces: `MissionSimulationScreen(mission, definition, learnerPayload)` and launcher resolution for all 20 IDs.

- [ ] **Step 1: Write failing launcher resolution tests**

For each ID `coc1_m1` through `coc4_m5`, assert `MissionLauncher.screenFor(...)` returns a non-null screen. Add a pure `screenFor` function so tests do not require navigation.

- [ ] **Step 2: Write failing responsive shell tests**

Pump the shell at 360×800, 800×360, and 1280×800 with text scale 2.0. Assert no Flutter error, scene remains present, controls scroll, and the review stage is reachable with a fake controller.

- [ ] **Step 3: Confirm integration tests fail**

Run: `flutter test test/mission_launcher_test.dart test/mission_simulation_screen_test.dart`

Expected: FAIL because the runtime screen and pure launcher resolver do not exist.

- [ ] **Step 4: Implement the mission shell**

Compose compact mission header/progress, dominant scene workspace, phase interaction panel, technical feedback region, and review navigation. Observe `WidgetsBindingObserver` and call controller persistence on pause/inactive/detached.

- [ ] **Step 5: Integrate protected missions**

Use adapters for legacy COC1 M2/M3 and COC2 M2 action types until their runtime path passes identical contract tests. Do not delete working screens in the same change; the launcher selects the validated runtime/adaptor path explicitly.

- [ ] **Step 6: Integrate orientation lifecycle**

Request landscape orientations on mission entry and restore portrait/landscape support on disposal. Add a test with an injectable orientation coordinator so widget tests do not depend on platform channels.

- [ ] **Step 7: Run launcher, runtime, and contract regressions**

Run:

```powershell
flutter test test/mission_launcher_test.dart test/mission_simulation_screen_test.dart
flutter test test/authoritative_mission_contract_test.dart test/coc2_cable_assessment_contract_test.dart test/authoritative_mission_assessment_widget_test.dart
flutter analyze --no-fatal-infos
```

Expected: PASS.

- [ ] **Step 8: Commit integration**

```powershell
git add -- ByteQuest-Mobile-App/lib/screens/simulation ByteQuest-Mobile-App/test/mission_launcher_test.dart ByteQuest-Mobile-App/test/mission_simulation_screen_test.dart
git commit -m "feat: launch all missions through simulation runtime"
```

---

### Task 9: Accessibility, Motion, and Visual Quality Pass

**Files:**
- Create: `ByteQuest-Mobile-App/test/mission_accessibility_matrix_test.dart`
- Modify: runtime scene/interactions/screen files created in Tasks 4–8.
- Modify: `ByteQuest-Mobile-App/lib/core/theme/app_theme.dart`
- Modify: `ByteQuest-Mobile-App/test/learner_design_system_test.dart`

**Interfaces:**
- Consumes: completed runtime UI.
- Produces: consistent ByteQuest visual tokens, large-text behavior, reduced-motion behavior, semantic action coverage, and animation-state verification.

- [ ] **Step 1: Write failing accessibility matrix tests**

For every interaction family, assert a semantics action exists without drag. Test text scale 2.0, reduced motion, 48 dp minimum targets, compact width, landscape width, and no `FlutterError` overflow.

- [ ] **Step 2: Confirm the matrix exposes remaining failures**

Run: `flutter test test/mission_accessibility_matrix_test.dart test/learner_design_system_test.dart`

Expected: FAIL only on uncovered semantics/layout/motion cases; record unexpected environment failures.

- [ ] **Step 3: Normalize visual tokens**

Use existing ByteQuest navy/blue theme tokens. Keep workspace dominant, headers compact, borders subtle, shadows restrained, and transitions in the approved 150–250 ms range.

- [ ] **Step 4: Close semantic and large-text gaps**

Add labels, selected/enabled/value state, scroll containers, and object-list alternatives until all interactions are independently completable with taps/buttons.

- [ ] **Step 5: Close reduced-motion and state-animation gaps**

Connection draw, indicator fade, installation snap/fade, test progress, and completion check must be driven by runtime state. Reduced motion switches them to immediate or opacity-only transitions.

- [ ] **Step 6: Run all UI tests and analyze**

Run:

```powershell
flutter test test/mission_accessibility_matrix_test.dart test/simulation_scene_test.dart test/core_mission_interactions_test.dart test/advanced_mission_interactions_test.dart test/mission_simulation_screen_test.dart test/learner_design_system_test.dart
flutter analyze --no-fatal-infos
```

Expected: PASS with no overflow or semantics regressions.

- [ ] **Step 7: Commit the quality pass**

```powershell
git add -- ByteQuest-Mobile-App/lib/core/theme/app_theme.dart ByteQuest-Mobile-App/lib/screens/simulation ByteQuest-Mobile-App/test
git commit -m "feat: polish simulation accessibility and motion"
```

---

### Task 10: Full Automated Verification and Debug APK

**Files:**
- Modify only files required to fix failures directly caused by Tasks 1–9.
- Update: `docs/BYTEQUEST_IMPLEMENTATION_FAILURES.md`

**Interfaces:**
- Consumes: entire Flutter application.
- Produces: passing analyzer, tests, and debug APK, or fully documented unresolved blockers.

- [ ] **Step 1: Run analyzer**

Run: `flutter analyze --no-fatal-infos`

Expected: exit 0. For each failure, capture `Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz'`, diagnostic file/line, cause, primary fix, alternative, and final status before editing.

- [ ] **Step 2: Run the complete test suite**

Run: `flutter test`

Expected: all tests pass. Fix only task-related failures and rerun the narrow failing test before the full suite.

- [ ] **Step 3: Build the APK**

Run: `flutter build apk --debug`

Expected: exit 0 and `build/app/outputs/flutter-apk/app-debug.apk` exists.

- [ ] **Step 4: Verify the failure ledger format**

Check every heading has a timestamp and every entry contains operation, command, affected location, observed result, cause, primary solution, alternative, and status.

- [ ] **Step 5: Commit verification fixes and ledger**

```powershell
git add -- ByteQuest-Mobile-App docs/BYTEQUEST_IMPLEMENTATION_FAILURES.md
git commit -m "test: verify ByteQuest simulation platform"
```

---

### Task 11: Android Emulator Mission Matrix

**Files:**
- Create: `docs/BYTEQUEST_EMULATOR_QA.md`
- Update: `docs/BYTEQUEST_IMPLEMENTATION_FAILURES.md`

**Interfaces:**
- Consumes: debug APK and a running Android emulator visible to `flutter devices`.
- Produces: a 20-mission manual matrix with device metadata and evidence for each `bytequest.md` QA item.

- [ ] **Step 1: Detect the emulator**

Run: `flutter devices`.

Expected: at least one Android emulator. If absent, record an environment failure with alternatives: start it in Android Studio Device Manager; run `flutter emulators`, copy an emulator ID from that output, and pass it to `flutter emulators --launch`; or install the debug APK through Android Studio.

- [ ] **Step 2: Launch the canonical app**

Capture and use the exact Android ID returned by Flutter:

```powershell
$androidDevice = (flutter devices --machine | ConvertFrom-Json | Where-Object { $_.targetPlatform -like 'android*' } | Select-Object -First 1).id
if (-not $androidDevice) { throw 'No running Android emulator was detected.' }
flutter run -d $androidDevice
```

Expected: app reaches authentication/onboarding without startup crash.

- [ ] **Step 3: Execute the 20-mission matrix**

For every `coc1_m1` through `coc4_m5`, record pass/fail for: launch, scenario, responsive 2D scene, all phases, technical feedback, evidence count, pause, resume, review, submit when credentials permit, no crash, no overflow, and no dead control.

- [ ] **Step 4: Exercise responsive and lifecycle variants**

Rotate landscape/portrait, change emulator display size or use a second AVD, enable large font, enable remove animations, background the app during a middle phase, kill/relaunch once, and confirm no duplicated evidence.

- [ ] **Step 5: Fix reproducible app defects through focused tests**

For each defect, first add a widget/unit regression test reproducing it, run the test to see it fail, apply the narrow fix, rerun the test, and repeat the affected emulator mission.

- [ ] **Step 6: Commit emulator QA**

```powershell
git add -- docs/BYTEQUEST_EMULATOR_QA.md docs/BYTEQUEST_IMPLEMENTATION_FAILURES.md ByteQuest-Mobile-App
git commit -m "test: validate missions on Android emulator"
```

---

### Task 12: Supabase Lifecycle QA, Scorecard, and Final Report

**Files:**
- Create: `docs/BYTEQUEST_20_MISSION_SCORECARD.md`
- Create: `docs/BYTEQUEST_SIMULATION_COMPLETION_REPORT.md`
- Update: `docs/BYTEQUEST_IMPLEMENTATION_FAILURES.md`
- Modify: authenticated scripts only if a reproducible script defect blocks an authorized existing workflow.

**Interfaces:**
- Consumes: existing Supabase project configuration, authorized learner/instructor accounts, assessment publication scripts, runtime evidence, emulator QA.
- Produces: documented authoritative lifecycle results, scorecards, showcase selections, and final acceptance evidence.

- [ ] **Step 1: Verify safe configuration without exposing values**

Confirm the mobile `.env` contains non-empty Supabase URL/anonymous key names and that `BYTEQUEST_E2E_PASSWORD` is available for authenticated scripts. Never print secret values.

- [ ] **Step 2: Run existing authenticated lifecycle checks**

Run the two existing authenticated lifecycle commands from `ByteQuest Web Dashboard/`:

```powershell
pnpm test:all-missions
pnpm test:realtime
```

Expected: learner submission becomes visible to instructor, PostgreSQL evaluates, instructor releases, and learner receives the result. If credentials or external connectivity block a check, mark it unverified rather than passed and provide emulator/manual and script alternatives.

- [ ] **Step 3: Score all 20 missions**

Create one row per mission with 1–5 scores for scenario realism, interaction variety, technical relevance, decision depth, scene quality, evidence quality, accessibility, visual polish, persistence, and assessment integrity. Require persistence and integrity 5/5 and every other category at or above the `bytequest.md` thresholds.

- [ ] **Step 4: Confirm showcase missions**

Select one reliable mission per COC demonstrating installation/configuration, topology, server configuration, and troubleshooting/repair. Start with COC1 M3, COC2 M3, COC3 M4, and COC4 M5; change only if emulator evidence supports a stronger selection.

- [ ] **Step 5: Write the completion report**

Report implementation coverage for all 15 priority items, automated command results, APK path, emulator/device metadata, Supabase lifecycle outcomes, scorecard status, showcase missions, preserved evaluator contracts, remaining external blockers, and links to every failure entry.

- [ ] **Step 6: Re-run final gates**

Run:

```powershell
flutter analyze --no-fatal-infos
flutter test
flutter build apk --debug
```

Expected: all exit 0.

- [ ] **Step 7: Commit final evidence**

```powershell
git add -- docs/BYTEQUEST_20_MISSION_SCORECARD.md docs/BYTEQUEST_SIMULATION_COMPLETION_REPORT.md docs/BYTEQUEST_IMPLEMENTATION_FAILURES.md ByteQuest-Mobile-App
git commit -m "docs: complete ByteQuest mission acceptance"
```

## Plan Self-Review Result

- Spec coverage: all scene, interaction, mission, evidence, feedback, branching, animation, submission, accessibility, persistence, gamification-integrity, showcase, scorecard, emulator, and final QA requirements map to Tasks 1–12.
- Scope: tasks form one integrated mobile simulation platform; the protected backend evaluation workflow is consumed, not redesigned.
- Type consistency: mission state, evidence action, transport, controller, callback, definition catalog, and screen interfaces have one stable spelling throughout.
- Failure handling: known and future failures use one required ledger format and are updated at every verification boundary.
