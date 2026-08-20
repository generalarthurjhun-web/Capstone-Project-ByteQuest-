# ByteQuest Simulation Platform Design

## Purpose

Complete the `bytequest.md` priority list in the canonical `ByteQuest-Mobile-App/` Flutter application. The result is a reusable, accessible 2D simulation platform supporting all 20 CSS NC II missions while retaining PostgreSQL as the authority for assessment evidence, evaluation, review, and released results.

## Scope

This design covers:

- The 2D scene engine, hotspots, tool tray, camera controls, responsive positioning, and landscape operation.
- All reusable interaction types requested by `bytequest.md`.
- Five missions for each of COC1 through COC4, including upgrades to the three partial missions.
- Structured evidence, feedback, scene changes, troubleshooting branches, submission review, accessibility, visual polish, animation, pause/resume, showcase selection, mission scorecards, and final QA.
- Automated Flutter verification, emulator QA, and authenticated Supabase lifecycle verification when test accounts are available.
- A timestamped failure report for any operation that cannot be completed.

Production-quality artwork is outside the current scope. Missing mission artwork uses responsive Flutter-rendered schematic scenes as replaceable placeholders.

## Constraints

- The canonical mobile directory is `ByteQuest-Mobile-App/`.
- Preserve the existing working-tree rename from `ByteQuest Mobile App/`; do not recreate or independently edit the deleted path.
- Preserve the existing COC1 M2, COC1 M3, and COC2 M2 authoritative evaluation rules.
- Assessment mode never receives or displays expected targets, answers, scores, pass flags, XP, or rewards.
- PostgreSQL remains authoritative. Local state is a resume cache only.
- Every meaningful action produces structured evidence.
- No mission may use drag-and-drop as its only mechanic.
- All gesture interactions must have accessible tap-based alternatives.
- Visuals use ByteQuest blue/navy, compact typography, restrained borders and shadows, and 150–250 ms transitions. Avoid giant cards, excessive gradients, glassmorphism, glow, and childish styling.

## Recommended Architecture

Use one data-driven mission runtime rather than 20 independent large screens. Mission definitions describe scenes, phases, allowable interactions, content keys, and evidence action types. Shared widgets render those definitions and emit typed runtime actions. Existing special assessment screens are adapted behind the same interfaces instead of having their evaluation contracts rewritten.

This structure separates four responsibilities:

1. Mission definitions describe what a learner can see and do.
2. The runtime state machine controls what is currently available and visible.
3. Widgets render interactions and report learner actions without deciding assessment correctness.
4. The evidence gateway persists ordered actions and reconciles local presentation state with Supabase.

## Core Domain Model

### Mission definition

`MissionSimulationDefinition` contains:

- Mission and COC identifiers.
- Scenario, environment, practice guidance, and presentation metadata.
- A `SimulationSceneDefinition` with schematic objects, normalized coordinates, hotspot types, connection nodes, and initial status.
- An ordered list of three to six `MissionPhaseDefinition` objects.
- A mission-specific feedback catalog keyed by stable feedback IDs.
- Submission-review labels and scorecard metadata.

Each phase declares one primary interaction and may compose supporting interactions. Definitions contain permissible presentation choices, but assessment definitions do not contain expected answers exposed to UI widgets.

### Runtime state

`MissionRuntimeState` contains:

- Current phase and completed phase IDs.
- Inspected, selected, completed, and error hotspot IDs.
- Selected tool and recorded tool applications.
- Connections, placements, configuration values, sequence order, matches, observations, and interpretations.
- Revealed troubleshooting facts and selected branch actions.
- Test execution and result-display state.
- Accepted evidence IDs and pending evidence actions.
- Practice/assessment mode, reduced-motion preference, and last update time.

All state is JSON serializable. Runtime transitions are immutable and testable independently of Flutter widgets.

### Stable evidence action

`MissionEvidenceAction` contains a stable client action ID, mission ID, phase ID, action type, target, structured value, and occurrence time. The stable action ID is generated before the visual transition and stored in resume state. Replayed or reconnected actions reuse that ID.

Supabase evidence remains chronologically ordered through `AuthoritativeAssessmentService`. A duplicate-prevention check reconciles stable IDs against active attempt actions before enqueueing unsynchronized evidence. Submission is disabled until pending evidence has been acknowledged.

## Scene Engine

### SimulationScene

`simulation_scene.dart` provides:

- An `InteractiveViewer` with constrained zoom, pan, reset, and fit-to-screen controls.
- A fixed logical scene coordinate space transformed into the available viewport using `LayoutBuilder` and `FittedBox`-style scaling.
- A `Stack` containing a replaceable background renderer, schematic objects, connection painter, status overlays, and hotspots.
- Landscape-first layout while still rendering safely in portrait and split-width test sizes.
- Camera state serialization where useful; reset remains available at all times.
- A compact accessible object-list alternative.

The engine does not force device orientation globally. Mission screens may request landscape while active and restore supported orientations on exit, preventing orientation leakage elsewhere in the app.

### HotspotWidget

`hotspot_widget.dart` maps normalized scene rectangles to the logical coordinate space. It supports neutral, selected, completed, and error states, uses a minimum 48×48 logical tap target, exposes a `Semantics` label and state, and forwards selection without determining correctness.

### ToolTray

`tool_tray.dart` renders a horizontal, keyboard/tap-accessible list of tools. It highlights the selected tool, validates compatibility against hotspot categories, emits structured use attempts, and requests feedback by feedback ID. Invalid use records evidence when meaningful and displays a technical reason rather than generic correctness language.

### Placeholder schematic renderer

Missing artwork is represented by semantic Flutter shapes and icons: device chassis, boards, ports, cables, racks, clients, servers, tools, indicators, and workspace hazards. Renderers consume scene definitions and remain replaceable by asset-backed renderers without changing mission phases or evidence behavior.

## Reusable Interactions

The runtime provides these composable widgets:

- `TapInspectInteraction`: selects an object and reveals its inspection panel.
- `MultiSelectInteraction`: builds a set of objects and confirms it as one structured action.
- `ToolSelectionInteraction`: composes the tool tray with a target hotspot.
- `ConnectionInteraction`: supports drag and source-select/destination-select connection methods.
- `ConfigurationPanel`: renders typed dropdown, toggle, and text fields with serializable values.
- `SequencingInteraction`: supports reorder and button-based move controls.
- `MatchingInteraction`: supports two-column selection without requiring drag.
- `ControlledPlacementInteraction`: validates destination, compatibility, and orientation with tap-to-place support.
- `TroubleshootingBranchInteraction`: reveals one fact after each diagnostic action and gates later choices.
- `TestRunInteraction`: shows a reduced-motion-aware progress state and records the completed test action.
- `ObservationInteraction`: records a learner interpretation of displayed output.
- `ScenarioDecisionInteraction`: changes available subsequent actions from a technical choice.
- `ResultInterpretationInteraction`: records an interpretation without revealing assessment correctness.
- `EvidenceReviewPanel`: displays completed phases and server-backed evidence count before explicit submission.

Although `bytequest.md` calls the set “12 components,” it names 14 rows. All 14 named interactions are included.

## Mission Coverage

### COC1

- M1: inspect hardware, identify a safe set, record observations, and verify readiness.
- M2: inspect compatibility, place components with orientation checks, sequence assembly, and verify installation while preserving existing rules.
- M3: sequence installation, configure options, detect a bad configuration, run a test, and interpret output while preserving existing rules.
- M4: inspect peripherals, choose tools, connect devices, run a device test, and interpret results.
- M5: inspect symptoms, choose diagnostics, progressively troubleshoot, apply a correction, and verify integration.

### COC2

- M1: identify network materials, select cable and tools, sequence preparation, connect, test, and interpret.
- M2: retain the golden cable assessment rules while adding topology/device context, accessible connections, configuration activity, and connectivity verification.
- M3: select nodes, construct topology, verify links, diagnose one invalid connection, and repair it.
- M4: choose a device, configure network values, test connectivity, interpret output, correct an error, and retest.
- M5: inspect topology, test a connection, inspect configuration, progressively diagnose, apply a fix, and retest.

### COC3

- M1: inspect a server workspace, identify requirements, select a role, check network readiness, sequence preparation, and validate.
- M2: choose roles and configuration before installation, simulate install/restart, and verify service readiness.
- M3: create accounts, assign groups and permissions, inspect access, test access, diagnose a permission error, and correct it.
- M4: inspect, configure, start, and stop services; set values; inspect status; test client access; and interpret the response.
- M5: inspect client, server, service, connectivity, and permissions progressively; correct the fault; retest; and verify recovery.

### COC4

- M1: inspect environment and components, identify symptoms, record observations, prioritize diagnostics, and state a preliminary diagnosis.
- M2: inspect symptoms and components, select a test tool, run a simulated test, interpret the result, identify the fault, repair, and verify.
- M3: reveal software/network information only through selected diagnostic actions and require interpretation after each result.
- M4: select components and tools, perform accessible controlled replacement, reconfigure, sequence repair, verify, and run a post-repair test.
- M5: inspect a maintenance request and system, identify and prioritize issues, choose tools, maintain and repair configuration, test, interpret, verify, and review the final submission report.

## Feedback and Assessment Integrity

Feedback text lives in `mission_content_data.dart` or a focused catalog owned by it, keyed by mission and feedback ID. Widgets never hardcode mission answers. Invalid attempts explain the technical constraint without giving the required target. Practice mode may expose opt-in hints. Assessment mode displays neutral acknowledgments such as “Evidence recorded” and defers correctness to PostgreSQL.

## Scene Changes and Animation

Accepted runtime transitions drive visuals:

- Connections animate a line into place.
- Device state indicators fade in.
- Components snap and then transition to completed state.
- Tests show a subtle progress animation.
- Phase completion shows a compact check transition.

Durations remain between 150 and 250 ms. Reduced-motion mode replaces movement with immediate state changes or short opacity changes. Animation never represents success unless runtime state records the corresponding accepted action.

## Troubleshooting Branches

Troubleshooting phases start with only scenario-safe symptoms. Each diagnostic action records evidence, reveals exactly one new fact, and unlocks contextually valid next actions. A learner may inspect an unhelpful branch without being told the answer. Correction and retest phases remain locked until the configured diagnostic prerequisites are recorded. A single multiple-choice question is never the whole troubleshooting flow.

## Persistence and Reconciliation

`ProgressResumeService` stores a versioned runtime snapshot scoped by learner and mission. Lifecycle hooks save on meaningful transitions and app pause. Restore validates the schema version, loads active server evidence, removes already acknowledged pending actions, and rebuilds the current phase without submitting or evaluating.

Resume invariants:

- Never append evidence solely because state was restored.
- Never advance beyond evidence-supported assessment state.
- Never evaluate or submit during restoration.
- Never discard server evidence because the local cache is missing or stale.
- Configuration, connections, branches, observations, selections, camera state, and current phase restore consistently.

## Submission Flow

The review stage lists completed phases and loads the authoritative evidence timeline/count. The learner may return to the mission when the attempt remains editable. Submission requires an explicit confirmation and remains disabled while evidence is pending or failed. The existing sequence remains unchanged: learner submits, PostgreSQL evaluates, instructor reviews, instructor releases, learner receives the released result through existing realtime/data flows.

## Accessibility and Responsive Design

- Interactive elements have semantic labels, roles, selected state, and enabled state.
- Scene hotspots are at least 48×48 dp or represented in the object list.
- Drag, connect, reorder, and placement operations have complete tap/button alternatives.
- Layouts tolerate system large text by reflowing controls and allowing scrolling rather than clipping.
- The scene receives most available space, with compact collapsible controls.
- Tests cover compact phone, standard phone, large phone/tablet-like width, portrait fallback, and landscape.
- Reduced-motion behavior follows platform accessibility settings.

## Testing Strategy

### Automated tests

- Domain tests for runtime transitions and invalid transition rejection.
- Serialization and migration tests for resume snapshots.
- Evidence tests for stable IDs, ordering, reconciliation, retry, and duplicate prevention.
- Widget tests for scene camera controls, 48 dp targets, hotspot states, tool compatibility, all interaction alternatives, large text, and reduced motion.
- Mission catalog tests asserting 20 unique missions, three to six phases each, two to four interaction families, technical decision points, observation/test/verification coverage, feedback references, review stage, and no drag-only mission.
- Regression tests for existing authoritative mission contracts.
- Launcher tests proving all 20 mission IDs resolve.

### Build gates

Run from `ByteQuest-Mobile-App/`:

1. `flutter analyze --no-fatal-infos`
2. `flutter test`
3. `flutter build apk --debug`

### Emulator QA

For every mission, verify launch, scenario, responsive scene, interaction phases, technical feedback, evidence display, pause/resume, review, submission when test data permits, crashes, overflow, and controls. Exercise landscape and portrait fallback plus at least two emulator display sizes or densities.

### Supabase lifecycle QA

With suitable learner/instructor test accounts, verify evidence persistence, submission, backend evaluation, realtime instructor visibility, instructor release, and released learner results. Tests use existing authorized scripts/RPCs and do not expose service credentials to Flutter.

## Scorecard and Showcase

Produce a 20-row scorecard using every category and threshold in `bytequest.md`. No mission is marked complete unless persistence and assessment integrity score 5/5 and all other thresholds pass.

Showcase candidates emphasize different mechanics:

- COC1: M3 installation/configuration workflow.
- COC2: M3 topology construction.
- COC3: M4 server/network services.
- COC4: M5 final maintenance scenario.

Final selection may change after emulator QA if another mission demonstrates the interaction more reliably.

## Rollout Order

1. Core state/evidence model and scene engine.
2. Tool system and all reusable interactions.
3. COC1 missions and regression coverage.
4. COC2 missions and preservation of the golden assessment.
5. COC3 missions.
6. COC4 missions.
7. Feedback, branching, animation, review, accessibility, and visual consistency passes.
8. Persistence reconciliation across all missions.
9. Automated gates, emulator QA, Supabase lifecycle QA, scorecard, and showcase report.

Each stage must leave a testable application. New mission definitions are enabled only after their completeness tests pass.

## Failure Reporting

Create `docs/BYTEQUEST_IMPLEMENTATION_FAILURES.md` if any operation fails. Each entry records:

- Date and time in Asia/Manila.
- Operation and exact command or interaction.
- Affected file and line, or “not applicable” for environment/tool failures.
- Observed output and root cause when known.
- Primary remediation.
- At least one alternative remediation or verification route.
- Final status: resolved, bypassed with justification, or blocked.

The initial discovery failure on 2026-08-20 is included even though it was resolved by correcting the path.

## Acceptance Criteria

- All 20 mission IDs launch through the canonical mobile application.
- Every mission implements its required technical flow with three to six meaningful phases and two to four interaction families.
- All 14 named reusable interactions exist and are used where specified.
- Scenes are responsive, zoomable, pannable, resettable, state-driven, and accessible.
- Every meaningful assessment action is persisted as ordered structured evidence without duplicate writes on resume.
- PostgreSQL retains sole authority for evaluation and released results.
- Feedback, branching, scene changes, animations, review, accessibility, visual rules, gamification restrictions, and persistence requirements match `bytequest.md`.
- Automated Flutter gates pass.
- Emulator and available Supabase lifecycle checks are documented per mission.
- The 20-mission scorecard passes all stated thresholds, with any unverifiable external operation explicitly reported rather than claimed.
