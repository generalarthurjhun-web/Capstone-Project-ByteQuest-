# ByteQuest — Codex Handoff State

> Update this file at the end of every work session before committing.
> A new AI agent should read this file AND `bytequest.md` AND `AGENTS.md` before doing anything.

---

## Snapshot

| Field | Value |
|---|---|
| Date | 2026-08-21 (Friday) |
| Active branch | `Dro-branch` |
| Latest commit | `f82d9ec` |
| Remote | `origin/Dro-branch` (up to date) |
| Working tree | Clean — nothing uncommitted |
| Primary build target | Android APK (Flutter) |

---

## Completed Tasks

These are done. Do not re-implement them.

### Repository scaffolding
- [x] Initial ByteQuest capstone project created
- [x] Repository structure established: `ByteQuest-Mobile-App/`, `ByteQuest Web Dashboard/`, `supabase/`, `docs/`, `scripts/`
- [x] `README.md` written at repo root
- [x] `.gitignore` configured — covers `.env*`, `build/`, `.dart_tool/`, artifacts
- [x] Mobile app folder renamed from `ByteQuest Mobile App` to `ByteQuest-Mobile-App`
- [x] `bytequest.md` added at repo root (full build context document)
- [x] `AGENTS.md` added at repo root (AI agent standing instructions)
- [x] `CODEX_STATE.md` added at repo root (this file)

### Mobile app — core infrastructure
- [x] Flutter project initialised (`pubspec.yaml`, dependencies, null safety)
- [x] Supabase integration: `lib/core/config/supabase_config.dart`
- [x] App constants: `lib/core/constants/app_constants.dart`
- [x] Route system: `lib/core/routes/app_routes.dart`
- [x] Theme: `lib/core/theme/app_theme.dart`
- [x] Sequence evaluator: `lib/core/evaluation/sequence_evaluator.dart`

### Mobile app — models (all present)
- [x] `achievement_model.dart`, `assigned_activity_model.dart`, `attempt_history_model.dart`
- [x] `badge_model.dart`, `coc_model.dart`, `leaderboard_entry_model.dart`
- [x] `learner_learning_path_model.dart`, `learner_progress_model.dart`, `learner_quiz_model.dart`
- [x] `learning_resource_model.dart`, `mission_model.dart`, `mission_scenario_model.dart`
- [x] `profile_model.dart`, `task_result_model.dart`

### Mobile app — services (all present)
- [x] `auth_service.dart`
- [x] `authoritative_assessment_service.dart`
- [x] `learner_quiz_service.dart`
- [x] `learner_realtime_coordinator.dart`
- [x] `learning_resource_service.dart`
- [x] `mission_database_service.dart`
- [x] `mission_service.dart`
- [x] `profile_service.dart`
- [x] `progress_resume_service.dart`
- [x] `user_settings_service.dart`

### Mobile app — screens (navigation + non-simulation)
- [x] Auth screens: `auth_wrapper`, `login`, `signup`, `forgot_password`
- [x] Onboarding: `onboarding_screen`, `get_started_screen`
- [x] Dashboard: `dashboard_screen`, `main_navigation_screen`
- [x] Courses: `courses_screen`, `coc_details_screen`
- [x] Missions list: `missions_screen`, `mission_detail_screen`, `class_details_screen`
- [x] Quizzes: `learner_quizzes_screen`, `quiz_details_screen`, `quiz_taking_screen`, `quiz_result_screen`
- [x] Progress: `progress_screen`, `attempt_history_screen`
- [x] Resources: `resource_viewer_screen`
- [x] Leaderboard: `leaderboard_screen`
- [x] Achievements: `achievements_screen`
- [x] Notifications: `notifications_screen`
- [x] Profile: `profile_screen`, `profile_setup_screen`
- [x] Settings: `settings_screen`, `edit_profile_screen`, `change_password_screen`, `help_center_screen`, `terms_privacy_screen`
- [x] Splash: `splash_screen`

### Mobile app — simulation infrastructure
- [x] `simulation_framework.dart` (CRITICAL — the simulation engine)
- [x] `simulation_screen.dart`
- [x] `mission_launcher.dart`
- [x] `result_screen.dart`
- [x] `mission_simulation_profile.dart`
- [x] `authoritative_mission_assessment_screen.dart`
- [x] `authoritative_mission_contract.dart`

### Mobile app — existing mission templates
- [x] `coc1_m2_screen.dart` (COC1 M2 basic)
- [x] `coc1_m2_screen_enhanced.dart` (COC1 M2 enhanced)
- [x] `coc1_m3_screen_enhanced.dart` (COC1 M3 enhanced)
- [x] `coc2_cable_termination_assessment_screen.dart` (COC2 M2 cable — golden/reference mission)
- [x] `coc2_cable_assessment_contract.dart`
- [x] `drag_drop_mission_screen.dart` (generic template — WARNING: never sole mechanic)
- [x] `identification_mission_screen.dart` + `_enhanced.dart`
- [x] `step_procedure_mission_screen.dart`
- [x] `troubleshooting_mission_screen.dart`
- [x] `configuration_mission_screen.dart`

### Mobile app — core widgets
- [x] All widgets in `lib/core/widgets/` and `lib/widgets/`

### Mobile app — data files
- [x] `mission_content_data.dart`
- [x] `mission_scenarios_data.dart`
- [x] `missions_data.dart`

### Mobile app — assets
- [x] COC1 Mission 1 assets (hardware components: CPU, RAM, GPU, HDD, SSD, PSU, motherboard, etc.)
- [x] COC1 Mission 2 assets (assembly components)
- [x] COC1 Mission 3 assets (cable connectors: 24-pin ATX, CPU power, SATA, front panel)
- [x] COC2 Mission 1 assets (networking tools and components)
- [x] App images (ByteQuest Logo, COC images, onboarding screens, avatars)

### Mobile app — tests (files present)
- [x] `authoritative_mission_assessment_widget_test.dart`
- [x] `authoritative_mission_contract_test.dart`
- [x] `coc2_cable_assessment_contract_test.dart`
- [x] `content_consistency_test.dart`
- [x] `drag_drop_accessibility_test.dart`
- [x] `learner_design_system_test.dart`
- [x] `learner_learning_path_model_test.dart`
- [x] `learner_quiz_flow_test.dart`
- [x] `profile_setup_screen_test.dart`
- [x] `resource_viewer_test.dart`
- [x] `sequence_evaluator_test.dart`
- [x] `simulation_framework_test.dart`
- [x] `widget_test.dart`

### Supabase backend (migrations present)
- [x] Foundation identity and audit migration
- [x] Classes and memberships migration
- [x] Evaluation finalization and release migration
- [x] RLS policy recursion fix
- [x] Lifecycle review gaps migration
- [x] Security DEFINER grant hardening
- [x] Instructor quiz authoring and AI drafts migration

### Web dashboard
- [x] Next.js project scaffolded
- [x] Authentication, RBAC, and middleware configured
- [x] Logs page with audit event viewer

---

## Unfinished Tasks

These are the remaining implementation items, in priority order per `bytequest.md`.

### PRIORITY 1 — 2D Scene Engine (does not exist yet)
- [ ] `lib/screens/simulation/components/simulation_scene.dart`
  - `InteractiveViewer` with zoom/pan/fit-to-screen/reset
  - Landscape orientation support
  - Stack layout: background image + hotspot layer
  - Hotspot states: neutral, selected, completed, error
  - Scene-state persistence (survives pause/resume)
  - Responsive positioning for different Android screen sizes
- [ ] `lib/screens/simulation/components/hotspot_widget.dart`
  - Tappable region mapped to scene coordinates
  - Visual states: neutral / selected / completed / error
  - Min 48×48 dp accessible tap target
  - Object list alternative for small targets
- [ ] `lib/screens/simulation/components/tool_tray.dart`
  - Horizontal scrollable tray of selectable tools
  - Active tool highlight
  - Compatibility validation
  - Invalid usage shows technical feedback
  - Saves tool + action as structured evidence to Supabase

### PRIORITY 2 — Reusable Interaction Components
- [ ] `TapInspectInteraction`
- [ ] `MultiSelectInteraction`
- [ ] `ToolSelectionInteraction`
- [ ] `ConnectionInteraction`
- [ ] `ConfigurationPanel`
- [ ] `SequencingInteraction`
- [ ] `MatchingInteraction`
- [ ] `ControlledPlacementInteraction`
- [ ] `TroubleshootingBranchInteraction`
- [ ] `TestRunInteraction`
- [ ] `ObservationInteraction`
- [ ] `ScenarioDecisionInteraction`
- [ ] `ResultInterpretationInteraction`
- [ ] `EvidenceReviewPanel`

### PRIORITY 3 — Missing Mission Screens

#### COC1
- [ ] M1 — Hardware Inspection (TapInspect, MultiSelect, ObservationRecord, Verification)
- [ ] M4 — Peripheral/Device Config (TapInspect, ToolSelection, ConnectionInteraction, TestRun, ResultInterpretation)
- [ ] M5 — Integration/Troubleshooting (SymptomInspect, DiagnosticToolSelection, TroubleshootingBranch, CorrectiveAction, FinalVerification)
- [ ] M2 — Extend existing partial (ControlledPlacement, CompatibilityValidation, SequenceValidation, OrientationCheck)
- [ ] M3 — Extend existing enhanced (ConfigurationPanel, IncorrectConfigDetection, ResultInterpretation)

#### COC2
- [ ] M1 — Cabling/Network Prep (DeviceIdentification, CableSelection, ToolSelection, Sequencing, ConnectionInteraction, TestRun)
- [ ] M3 — Network Topology Construction (NodeSelection, ConnectionInteraction, TopologyBuild, LinkStatusVerification)
- [ ] M4 — Network Configuration (DeviceSelection, ConfigurationPanel, ConnectivityTest, ResultInterpretation, ErrorCorrection)
- [ ] M5 — Network Troubleshooting (TroubleshootingBranch, NOT single multiple-choice)
- [ ] M2 — Preserve existing cable evaluation rules, extend if needed

#### COC3 (all five missing)
- [ ] M1 — Server Preparation
- [ ] M2 — Server Installation
- [ ] M3 — Users/Groups/Permissions
- [ ] M4 — Server/Network Services
- [ ] M5 — Server Troubleshooting

#### COC4 (all five missing)
- [ ] M1 — Inspection
- [ ] M2 — Hardware Diagnosis
- [ ] M3 — Software/Network Diagnosis
- [ ] M4 — Repair/Corrective Action
- [ ] M5 — Final Maintenance Scenario

### PRIORITY 4 — Supporting Systems
- [ ] Technical feedback strings populated in `mission_content_data.dart` for all 20 missions
- [ ] Scene state change animations (cable connect, device configure, component install, test run)
- [ ] Troubleshooting branching logic fully implemented across all troubleshooting missions
- [ ] Submission review screen polish (evidence count, return to mission, explicit confirm)
- [ ] Accessibility pass: Semantics labels, tap targets, drag alternatives for all missions
- [ ] Visual polish + animation pass (150–250 ms transitions)
- [ ] Pause/resume verification across all 20 missions
- [ ] Full QA scorecard pass (all 20 missions at acceptable or rich quality)
- [ ] COC2 server/networking assets (scenes for M3, M4, M5)
- [ ] COC3 server assets (scenes for M1–M5)
- [ ] COC4 repair/maintenance assets (scenes for M1–M5)

### PRIORITY 5 — Final Capstone Prep
- [ ] Select and polish 4 showcase missions (one per COC) for defense panel
- [ ] Full manual QA checklist (20 missions × 18 checkpoints per `bytequest.md`)
- [ ] Confirm instructor release flow works end-to-end
- [ ] Confirm realtime sync works (learner submit → instructor; instructor release → learner)

---

## Current Implementation Status

**Overall:** Foundation complete. Simulation engine not yet started.

- Navigation, auth, onboarding, dashboard, quizzes, progress, resources, leaderboard, achievements,
  profile, settings: **Done**
- Supabase backend migrations and RLS: **Done**
- Simulation framework (the engine): **Done**
- 2D scene components (`simulation_scene`, `hotspot_widget`, `tool_tray`): **Not started**
- Reusable interaction components (14 components): **Not started**
- Mission screens: **3 of 20 partial** (COC1 M2, COC1 M3, COC2 M2); **0 of 20 complete**

The single highest-value next action is building `simulation_scene.dart` + `hotspot_widget.dart`.
Everything else composes on top of those two files.

---

## Known Issues

- `build/` directory exists locally — this is expected and gitignored. Do not commit it.
- `.env` contains the Supabase anon key — this is expected and gitignored. Do not commit it.
- COC1 M2 and M3 screens are partial implementations. Read them before extending.
- COC2 M2 (cable mission) is the "golden reference" mission — preserve its evaluation rules
  exactly when extending.
- No COC3 or COC4 scene assets exist yet — these need to be created or sourced before those
  missions can be built.
- `drag_drop_mission_screen.dart` exists as a generic template but drag-drop must NEVER be
  the sole mechanic in any mission.

---

## QA Results

Last run: 2026-08-21

```
flutter pub get               : PASS  (33 packages have newer versions — not blocking)
flutter analyze --no-fatal-infos : PASS  (0 errors, 1 warning, 213 infos)
flutter test                  : PASS  (50/50 tests passed)
flutter build apk --debug     : PASS  (build/app/outputs/flutter-apk/app-debug.apk)
```

### Analyze detail

- **0 errors**
- **1 warning**: `unawaited_return_in_try_block` in `lib/services/progress_resume_service.dart:57`
  — a Future is returned inside a try block without await. Resolve before production release.
- **213 infos**: Primarily `prefer_const_constructors` and `deprecated_member_use` (`.withOpacity`
  → `.withValues()`). Non-blocking for now; should be cleaned up incrementally.
- **2 notable infos** (slightly higher priority):
  - `use_build_context_synchronously` in `profile_screen.dart:255` and `settings_screen.dart:384`
    — BuildContext used across async gap without proper mounted guard.
  - `deprecated_member_use` for `onWillAccept`/`onAccept` in `coc1_m2_screen.dart` — deprecated
    drag target callbacks. Replace with `onWillAcceptWithDetails`/`onAcceptWithDetails`.
  - `deprecated_member_use` for `activeColor` in `settings_screen.dart` — replace with
    `activeThumbColor`.

### Build warnings (non-blocking)

- Android KGP (Kotlin Gradle Plugin) version compatibility warning: `shared_preferences_android`
  still applies KGP directly. Will become an error in a future Flutter version. Track for
  upgrade when `shared_preferences_android` releases a Built-in Kotlin compatible version.
- KGP mismatch between AGP and KGP versions detected — does not block current debug build.

---

## Next Recommended Actions for a New Codex Account

1. Clone the repo and check out `Dro-branch`:
   ```bash
   git clone https://github.com/mikeangelocasono/ByteQuest-Capstone-Project.git
   cd ByteQuest-Capstone-Project
   git checkout Dro-branch
   ```

2. Read (in order):
   - `AGENTS.md` — standing rules
   - `CODEX_STATE.md` — this file
   - `bytequest.md` — full build context

3. Set up the mobile app:
   ```bash
   cd ByteQuest-Mobile-App
   cp .env.example .env
   # Fill in SUPABASE_URL and SUPABASE_ANON_KEY in .env
   flutter pub get
   flutter analyze --no-fatal-infos
   flutter test
   ```

4. Start with **PRIORITY 1**: build `simulation_scene.dart` then `hotspot_widget.dart`.
   Do not start on any mission screen until those two files exist.

5. After each work session: update this file (`CODEX_STATE.md`) and commit it.
