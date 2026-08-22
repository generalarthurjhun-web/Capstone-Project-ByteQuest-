w# ByteQuest — Build Context for Codex / Kiro

## Project Overview

**ByteQuest** is a Flutter-based interactive 2D mobile app (Android) serving as a capstone project.
It simulates CSS NC II tasks across 4 competency tracks (COC1-COC4), with 5 missions each = **20 missions total**.

**Core interaction loop (non-negotiable):**
> Inspect > Interact > Diagnose > Configure > Connect > Test > Interpret > Troubleshoot > Verify > Submit

It must NOT feel like: Read > Drag > Answer > Next.

**GitHub Repo:** `mikeangelocasono/ByteQuest-Capstone-Project`
**Backend:** Supabase (PostgreSQL) — authoritative for evidence and evaluation
**Frontend:** Flutter (Dart) — records interactions, drives UI, syncs to Supabase

---

## Current Project Structure (What Already Exists)

```
lib/
  core/
    config/       supabase_config.dart
    constants/    app_constants.dart
    evaluation/   sequence_evaluator.dart
    routes/       app_routes.dart
    theme/        app_theme.dart
    widgets/      (app_button, feedback_card, floating_bottom_nav, instruction_card,
                   learner_ui, mission_header, progress_indicator_card,
                   simulation_fullscreen_button, soft_card, step_progress_card,
                   supplementary_platform_notice)
  data/
    mission_content_data.dart
    mission_scenarios_data.dart
    missions_data.dart
  models/
    achievement_model.dart, assigned_activity_model.dart, attempt_history_model.dart,
    badge_model.dart, coc_model.dart, leaderboard_entry_model.dart,
    learner_learning_path_model.dart, learner_progress_model.dart,
    learner_quiz_model.dart, learning_resource_model.dart, mission_model.dart,
    mission_scenario_model.dart, profile_model.dart, task_result_model.dart
  screens/
    achievements/   achievements_screen.dart
    auth/           auth_wrapper, forgot_password, login, signup screens
    courses/        coc_details_screen, courses_screen
    dashboard/      dashboard_screen, main_navigation_screen
    leaderboard/    leaderboard_screen
    missions/       class_details_screen, mission_detail_screen, missions_screen
    notifications/  notifications_screen
    onboarding/     get_started_screen, onboarding_screen
    profile/        profile_screen
    profile_setup/  profile_setup_screen
    progress/       attempt_history_screen, progress_screen
    quizzes/        learner_quizzes, quiz_details, quiz_result, quiz_taking screens
    resources/      resource_viewer_screen
    settings/       change_password, edit_profile, help_center, settings, terms_privacy screens
    simulation/
      components/   mission_simulation_profile.dart
      templates/    (see Mission Templates below)
      mission_launcher.dart
      result_screen.dart
      simulation_screen.dart
      simulation_framework.dart   <- CRITICAL FILE
    splash/         splash_screen.dart
  services/
    auth_service.dart
    authoritative_assessment_service.dart
    learner_quiz_service.dart
    learner_realtime_coordinator.dart
    learning_resource_service.dart
    mission_database_service.dart
    mission_service.dart
    profile_service.dart
    progress_resume_service.dart
    user_settings_service.dart
  widgets/
    app_top_bar, bytequest_bottom_nav, mission_card, notification_tile,
    quick_start_button, settings_tile, stat_card, status_badge
  main.dart
```

### Existing Mission Templates (in `screens/simulation/templates/`)

| File | Type |
|---|---|
| `authoritative_mission_assessment_screen.dart` | Assessment wrapper |
| `authoritative_mission_contract.dart` | Mission contract/rules |
| `coc1_m2_screen.dart` + `coc1_m2_screen_enhanced.dart` | COC1 Mission 2 (exists) |
| `coc1_m3_screen_enhanced.dart` | COC1 Mission 3 (exists) |
| `coc2_cable_assessment_contract.dart` | COC2 cable assessment |
| `coc2_cable_termination_assessment_screen.dart` | COC2 cable mission (exists) |
| `configuration_mission_screen.dart` | Generic config template |
| `drag_drop_mission_screen.dart` | Drag-drop template (WARNING: must not be sole mechanic) |
| `identification_mission_screen.dart` + `_enhanced.dart` | Identification template |
| `step_procedure_mission_screen.dart` | Step-sequencing template |
| `troubleshooting_mission_screen.dart` | Troubleshooting template |

---

## What Is Missing (Priority Build List)

### CRITICAL: 2D Scene Engine (Does Not Exist Yet)

These core components need to be built first. Everything else composes on top of them.

**File:** `lib/screens/simulation/components/simulation_scene.dart`

Requirements:
- `InteractiveViewer` wrapper for zoom, pan, fit-to-screen, reset camera
- Landscape orientation support
- `Stack`-based layout: scene background image + hotspot layer on top
- Hotspot states: neutral, selected, completed, error
- Scene-state persistence (survives app pause/resume)
- Responsive object positioning for different Android screen sizes

**File:** `lib/screens/simulation/components/hotspot_widget.dart`

Requirements:
- Tappable region mapped to a scene coordinate
- Visual state: neutral / selected / completed / error
- Accessible tap target size (min 48x48dp)
- Optional object list alternative for small targets (accessibility)

**File:** `lib/screens/simulation/components/tool_tray.dart`

Requirements:
- Horizontal scrollable tray of selectable tools
- Active tool highlight
- Compatibility validation (tool only applies to compatible hotspot types)
- Invalid usage shows concise technical feedback, not "Wrong"
- Saves selected tool + action as structured evidence to Supabase

---

### Reusable Interaction Components Needed

Build these as composable Flutter widgets, NOT as one-off per-mission code.

| Component | Description |
|---|---|
| `TapInspectInteraction` | Tap hotspot, show inspection detail panel |
| `MultiSelectInteraction` | Select multiple hotspots, validate selection set |
| `ToolSelectionInteraction` | Pick tool from tray, apply to hotspot |
| `ConnectionInteraction` | Source-to-destination drag/tap to connect two nodes |
| `ConfigurationPanel` | Form-like panel: dropdowns, toggles, input fields for simulated config |
| `SequencingInteraction` | Order a list of steps correctly |
| `MatchingInteraction` | Match items from two columns |
| `ControlledPlacementInteraction` | Place component into correct slot with orientation validation |
| `TroubleshootingBranchInteraction` | Decision tree: action reveals new symptom, not all info upfront |
| `TestRunInteraction` | Simulate a running test with progress indicator + result output |
| `ObservationInteraction` | Learner reads simulated output and records interpretation |
| `ScenarioDecisionInteraction` | Branching choice that affects available next steps |
| `ResultInterpretationInteraction` | Given simulated output, learner selects correct interpretation |
| `EvidenceReviewPanel` | Shows completed steps + evidence count before submission |

---

### Missing Mission Screens (15-17 of 20)

Use existing templates as base. Extend, do NOT build from scratch.

#### COC1 — Install and Configure Computer Systems

| Mission | Status | Interaction Types Required |
|---|---|---|
| M1 — Hardware Inspection | MISSING | TapInspect, MultiSelect, ObservationRecord, Verification |
| M2 — Controlled Assembly | Partial (has basic screen) | ControlledPlacement, CompatibilityValidation, SequenceValidation, OrientationCheck |
| M3 — Installation/Config Workflow | Partial (enhanced exists) | Sequencing, ConfigurationPanel, IncorrectConfigDetection, ResultInterpretation |
| M4 — Peripheral/Device Config | MISSING | TapInspect, ToolSelection, ConnectionInteraction, TestRun, ResultInterpretation |
| M5 — Integration/Troubleshooting | MISSING | SymptomInspect, DiagnosticToolSelection, TroubleshootingBranch, CorrectiveAction, FinalVerification |

#### COC2 — Set Up Computer Networks

| Mission | Status | Interaction Types Required |
|---|---|---|
| M1 — Cabling/Network Prep | MISSING | DeviceIdentification, CableSelection, ToolSelection, Sequencing, ConnectionInteraction, TestRun, ResultInterpretation |
| M2 — Golden/Reference Mission | Partial (cable screen exists) | Preserve existing evaluation rules. Topology, DeviceSelection, ConnectionInteraction, ConfigActivity, ConnectivityTest |
| M3 — Network Topology Construction | MISSING | NodeSelection, ConnectionInteraction, TopologyBuild, LinkStatusVerification, InvalidConnectionFix |
| M4 — Network Configuration | MISSING | DeviceSelection, ConfigurationPanel, ConnectivityTest, ResultInterpretation, ErrorCorrection |
| M5 — Network Troubleshooting | MISSING | TopologyInspect, TestConnection, ConfigInspect, TroubleshootingBranch (NOT single multiple-choice), ApplyFix, Retest |

#### COC3 — Set Up Computer Servers

| Mission | Status | Interaction Types Required |
|---|---|---|
| M1 — Server Preparation | MISSING | SceneInspect, RequirementsIdentification, RoleSelection, NetworkReadinessCheck, Sequencing, Validation |
| M2 — Server Installation | MISSING | ConfigFlow, RoleSelection, ChoicesAffectState, ConfigBeforeInstall, SimulatedRestart, Verification |
| M3 — Users/Groups/Permissions | MISSING | AccountCreation, RoleAssignment, PermissionAssignment, AccessInspect, AccessTest, PermissionErrorDiagnosis |
| M4 — Server/Network Services | MISSING | ServiceInspect, ServiceConfig, StartStopService, ConfigValues, StatusInspect, ClientAccessTest, ServerResponseInterpretation |
| M5 — Server Troubleshooting | MISSING | ClientInspect, ServerInspect, ServiceStateInspect, ConnectivityTest, PermissionConfigInspect, CorrectiveAction, Retest, VerifyRecovery |

#### COC4 — Maintain and Repair Computer Systems and Networks

| Mission | Status | Interaction Types Required |
|---|---|---|
| M1 — Inspection | MISSING | EnvironmentInspect, SymptomIdentification, ComponentInspect, ObservationRecord, DiagnosticPriority, PreliminaryDiagnosis |
| M2 — Hardware Diagnosis | MISSING | SymptomInspect, TestToolSelection, ComponentInspect, SimulatedTest, ResultInterpretation, FaultIdentification, RepairAction, Verification |
| M3 — Software/Network Diagnosis | MISSING | TroubleshootingBranch (reveal info progressively), RequireInterpretation (each result), DoNotRevealRootCauseEarly |
| M4 — Repair/Corrective Action | MISSING | ComponentSelection, ToolSelection, ControlledReplacement, Reconfiguration, RepairSequence, Verification, PostRepairTest |
| M5 — Final Maintenance Scenario | MISSING | MaintenanceRequest, SystemInspect, IssueIdentification, FaultPrioritization, ToolSelection, PerformMaintenance, RepairConfig, SystemTest, ResultInterpretation, FinalVerification, SubmissionReport |

---

## Quality Standard (Apply to Every Mission)

Every mission must pass ALL of the following before it is considered done:

- Has a clear scenario or technical problem
- Has 3-6 meaningful interaction phases (not just one)
- Uses 2-4 different interaction types (drag-drop is NEVER the only mechanic)
- Includes at least one technical decision point
- Includes observation, testing, or verification where appropriate
- Every meaningful action produces structured evidence saved to Supabase
- Incorrect actions give concise technical feedback without revealing the answer
- Assessment mode does NOT expose correct targets
- Practice mode may provide hints
- Mission state survives pause and resume (no duplication on reconnect)
- Works on different Android screen sizes
- Has a polished submission-review stage before final submit

---

## Feedback System Rules (Phase 7)

- Never show generic "Wrong" or "Correct"
- Show brief, specific technical reason: e.g. "CAT5e cannot support speeds above 100Mbps on this segment"
- On success: brief confirmation, then continue — do not interrupt flow
- Feedback strings should be defined in `mission_content_data.dart` per mission, not hardcoded in widgets

---

## Scene State Changes (Phase 8)

When a learner action is confirmed correct, the 2D scene must visually update:

- Cable connected: animate line drawing into place
- Device configured correctly: status indicator changes (fade in)
- Component installed: snap/fade into installed state
- Test running: show subtle progress animation
- Test complete: show result indicator on device

Scene state must be driven by real `MissionState` data, not decorative only.

---

## Troubleshooting Branching Rules (Phase 9)

- Do NOT reveal all diagnostic information at mission start
- Each learner diagnostic action reveals one new piece of information
- Technical decisions (which tool to use, which component to inspect) control what becomes visible
- Branching must produce evidence at each decision point
- Never use a single multiple-choice question as the troubleshooting mechanic

---

## Submission + Evidence Flow (Phases 11-13)

### Submission Review Screen
- Show all completed mission steps
- Show evidence count (e.g. "7 evidence items recorded")
- Allow return to mission if permitted
- Require explicit confirm tap before authoritative submission
- Compact, readable layout

### Evidence + Backend Rules
- Flutter records interactions as structured evidence objects
- Supabase/PostgreSQL is the authoritative evaluation source
- Automated evaluation runs on the backend only
- Sequence: Learner submits > Instructor reviews > Instructor releases > Learner sees result
- Realtime sync: learner submit updates instructor view; instructor release updates learner result screen
- Never allow local-only mission state that bypasses Supabase

---

## Accessibility Requirements (Phase 14)

- All drag interactions must have a tap-to-select + tap-to-place alternative
- All connection gestures must have a source-select + destination-select alternative
- Small scene objects must have accessible tap targets (48x48dp minimum) OR an object list picker
- Add Flutter Semantics labels to all interactive elements
- Support system large text setting
- Support reduced motion preference

---

## Visual Design Rules (Phase 15)

- Primary color: ByteQuest blue/navy
- Typography: compact, professional (no oversized headers)
- 2D workspace gets the majority of screen real estate
- Subtle borders, restrained drop shadows only
- Transitions: 150-250ms, smooth
- DO NOT use: giant cards, excessive gradients, glassmorphism, glow effects, childish game styling

---

## Animation Spec (Phase 16)

| Trigger | Animation |
|---|---|
| Cable connected | Line draws into position |
| Device state changes | Status indicator fades in |
| Component installed | Snaps then fades to completed state |
| Test running | Subtle indeterminate progress bar |
| Mission step completes | Compact checkmark transition |

---

## Pause / Resume Requirements (Phase 17)

On app restart or return from background, every mission must restore:
- Current mission phase
- All accepted evidence
- Configuration state (dropdowns, toggles, text inputs)
- Connection state (which nodes are connected)
- Do NOT duplicate evidence on resume
- Do NOT trigger premature evaluation

Use `progress_resume_service.dart` (already exists) as the persistence layer.

---

## Gamification Rules (Phase 10)

Allowed:
- Mission progress indicators
- Checkpoint completion feedback
- Achievement badges (model already exists)

NOT allowed (will compromise assessment integrity):
- Fake TESDA XP
- Fake passing percentages
- Fake leaderboards tied to mission scores
- Random streaks unrelated to real performance

---

## Mission Scorecard (Acceptance Standard)

Score every mission after implementation. Minimum passing score per category:

| Category | Target |
|---|---|
| Scenario realism | 4/5 |
| Interaction variety | 4/5 |
| Technical relevance | 4/5 |
| Decision depth | 3/5 |
| 2D scene quality | 4/5 |
| Evidence quality | 4/5 |
| Accessibility | 4/5 |
| Visual polish | 4/5 |
| Persistence | 5/5 |
| Assessment integrity | 5/5 |

**Final target: 20/20 functional, 20/20 at acceptable or rich quality, 0 drag-drop-only missions.**

---

## Capstone Defense Showcase Missions (Phase 19)

Select one mission per COC that best demonstrates a different interaction type:

- COC1: installation/configuration showcase
- COC2: networking/topology showcase
- COC3: server configuration showcase
- COC4: troubleshooting/repair showcase

The panel must immediately see that ByteQuest is a 2D simulation platform, not a quiz app.

---

## Final QA Checklist (Phase 20)

Run before submission:
```bash
flutter analyze --no-fatal-infos
flutter test
flutter build apk --debug
```

For every mission (COC1-COC4, M1-M5), manually verify:

- [ ] Mission launches
- [ ] Scenario displays correctly
- [ ] 2D scene is responsive
- [ ] All interactions work
- [ ] Incorrect states show correct feedback
- [ ] Evidence saves to Supabase
- [ ] Pause works
- [ ] Resume restores state correctly
- [ ] Submission review screen works
- [ ] Submit completes
- [ ] Evaluation runs on backend
- [ ] Realtime sync works
- [ ] Instructor sees learner submission
- [ ] Instructor can release result
- [ ] Learner sees final result
- [ ] No crashes
- [ ] No layout overflow
- [ ] No dead/unresponsive buttons

---

## Build Priority Order

1. `simulation_scene.dart` + `hotspot_widget.dart` (2D scene engine)
2. `tool_tray.dart` (tool system)
3. Reusable interaction components (12 components listed above)
4. COC1 M1, M4, M5 (missing missions)
5. COC2 M1, M3, M4, M5 (missing missions)
6. COC3 M1-M5 (all missing)
7. COC4 M1-M5 (all missing)
8. Technical feedback strings in `mission_content_data.dart`
9. Scene state change animations
10. Troubleshooting branching logic
11. Submission review screen polish
12. Accessibility pass (Semantics, tap targets, alternatives)
13. Visual polish + animation pass
14. Pause/resume verification across all 20 missions
15. Full QA pass + scorecard
