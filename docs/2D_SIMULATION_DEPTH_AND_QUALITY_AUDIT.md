# ByteQuest 2D Simulation Depth and Quality Audit

**Audit date:** 2026-08-15  
**Scope:** 20 authoritative learner missions across COC1â€“COC4  
**Authority boundary:** Flutter records ordered evidence; published PostgreSQL rules evaluate it. Instructor review, finalization, release, RLS/RBAC, Realtime, and exact-once effects are unchanged.

## Executive finding

The backend assessment architecture was already strong, but presentation depth was uneven. COC2 Mission 2 was the richest dedicated simulation; the other 19 missions shared a secure generalized renderer whose selections, radio choices, dropdowns, and matching controls could feel like an LMS form even when the evidence contract represented a real CSS procedure.

This pass adds a reusable, responsive 2D presentation framework and a 20-mission scene/identity registry. It does **not** add client-side answer keys or scoring. The same published stage IDs, criterion codes, action types, evidence rules, activity/rubric versions, PostgreSQL evaluator, and Instructor workflow remain authoritative.

## 20-mission depth audit and upgrade matrix

`Simulation Depth` is the pre-upgrade classification. `Recommended Upgrade` records the implemented presentation change and the resulting classification.

| COC | Mission | Current Scene | Current Interaction Types | Evidence Produced | Simulation Depth | Visual Depth | Decision Depth | Technical Realism | Accessibility | Current Problems | Recommended Upgrade |
|---|---|---|---|---|---|---|---|---|---|---|---|
| COC1 | M1 Identify Computer Parts and Tools | Generic stage card | sequence, multi-select | ordered plan + exact preparation sets | WEAK | Low | Medium | Medium | Tap controls | Planning evidence looked like a checklist | Workbench scene, neutral inspection hotspots, resource palette, action timeline â†’ **ACCEPTABLE** |
| COC1 | M2 Install Internal Components | Enhanced component workspace | select, sequence, matching, inspection | ESD/tool/component/placement/inspection evidence | ACCEPTABLE | Medium | High | High | Drag plus select/destination | Rich evidence but inconsistent with shared missions | Open-chassis scene, controlled placement paths, assembly identity â†’ **RICH** |
| COC1 | M3 Connect Power and Data Cables | Enhanced cable workspace | selection, matching, sequence | isolation, cable-port match, routing, startup evidence | ACCEPTABLE | Medium | High | High | Drag plus select/destination | Connection state lacked shared visual language | Chassis connection bay, visible learner-created paths, neutral ports â†’ **RICH** |
| COC1 | M4 Configure BIOS/UEFI and Install OS | Configuration form | selection, configuration, sequence, decision | detected hardware, config values, install chronology, observation | TOO FORM-LIKE | Low | High | Medium | Standard controls | Dropdowns dominated the experience | Firmware console, boot-media inspection, terminal-style config panel, deployment timeline â†’ **RICH** |
| COC1 | M5 Install Drivers and Test System | Generic stage card | selection, sequence, configuration, test observation | package set, chronology, configuration, test/inspection evidence | WEAK | Low | Medium | Medium | Tap controls | Verification felt like form completion | Post-install verification station, test execution phase, inspection record â†’ **ACCEPTABLE** |
| COC2 | M1 Identify Network Devices and Tools | Generic stage card | sequence, selection | route, materials, tools, PPE evidence | WEAK | Low | Medium | Medium | Tap controls | Network plan was not visible | Topology plan scene, endpoint inspection, tool/resource palette â†’ **ACCEPTABLE** |
| COC2 | M2 Cable Termination and Testing | Dedicated cable bench | tool use, ordered wire placement, crimp, inspect, test | nine ordered cable construction/testing criteria | RICH | High | High | High | Accessible alternatives exist | Golden reference; preserve behavior | Retained dedicated golden implementation â†’ **RICH** |
| COC2 | M3 Diagnose Cable Connectivity | Generic diagnostic stages | selection, sequence, decision | setup, tester order/result, diagnosis, remedy/retest | ACCEPTABLE | Medium | High | High | Tap controls | Test result interpretation lacked a simulated bench | Cable tester scene, explicit run-test/inspect-symptom phases, diagnostic flow â†’ **RICH** |
| COC2 | M4 Install LAN Devices/Cable Route | Matching-heavy stage UI | selection, sequence, matching | route, materials, topology/port, inspection evidence | TOO DRAG-DROP-DEPENDENT | Medium | High | High | Select/destination fallback | Placement was the dominant visual mechanic | Responsive LAN topology, accessible source-target connection, path summary â†’ **RICH** |
| COC2 | M5 Configure/Verify Small LAN | Configuration form | selection, configuration, sequence | design, NIC/LAN/WAN/security values, test evidence | TOO FORM-LIKE | Low | High | High | Standard controls | Real network relationships were visually absent | Network bench, device inspection, terminal-style config, communication-test phase â†’ **RICH** |
| COC3 | M1 Prepare Server Setup Requirements | Generic stage card | selection, sequence | requirement/service/tool/plan evidence | WEAK | Low | Medium | Medium | Tap controls | Server environment was abstract | Server rack planning scene, service/client hotspots, tool palette â†’ **ACCEPTABLE** |
| COC3 | M2 Install and Configure Server OS | Generic procedure UI | selection, sequence, configuration, observation | preflight, install order, identity/security/module/service evidence | WEAK | Low | High | High | Tap controls | Installation did not feel like deployment | Server deployment scene, resource inspection, configuration panel, ordered procedure â†’ **ACCEPTABLE** |
| COC3 | M3 Configure Server Network Settings | Configuration form | selection, configuration, sequence | design, NIC, binding, communication evidence | TOO FORM-LIKE | Low | High | High | Standard controls | Form fields obscured server/client topology | Server rack/client scene, service binding console, verification timeline â†’ **RICH** |
| COC3 | M4 Create Users, Groups and Permissions | Configuration form | selection, sequence, configuration, decisions | account/group/ACL/access-test evidence | TOO FORM-LIKE | Low | High | High | Standard controls | Access relationships were not visible | Access console with user/group/share objects, policy decisions, positive/negative tests â†’ **ACCEPTABLE** |
| COC3 | M5 Test Client Access and Document Setup | Troubleshooting choices | sequence, decision, selection | service/client checks, diagnosis, remedy/retest/report | WEAK | Medium | High | High | Tap controls | Cause selection preceded weak observation | Server-service scene, inspect symptom, run test, remediation timeline â†’ **RICH** |
| COC4 | M1 Identify System and Network Problems | Identification/question UI | selection, sequence, decision | service order, resources, baseline, plan, diagnosis | TOO FORM-LIKE | Low | High | Medium | Tap controls | Mostly knowledge prompts | Fault-isolation bay, scene inspection, diagnostic planning workflow â†’ **ACCEPTABLE** |
| COC4 | M2 Perform Preventive Maintenance | Procedure screen | selection, sequence, inspection | PPE/tools, shutdown, maintenance, test, 5S evidence | ACCEPTABLE | Medium | High | High | Tap sequence | Good chronology but limited environment feedback | Maintenance bay, chassis inspection, resource palette, verification phase â†’ **ACCEPTABLE** |
| COC4 | M3 Diagnose Hardware and Software Faults | Troubleshooting choices | selection, sequence, decision | safety, baseline, isolation, diagnosis, correction/retest | WEAK | Medium | High | High | Tap controls | Symptom/test actions were implied | Open-chassis diagnostic scene, explicit symptom inspection and test interpretation â†’ **RICH** |
| COC4 | M4 Troubleshoot Network Issues | Troubleshooting choices | selection, sequence, decision | topology review, tests, observed result, diagnosis, correction/retest | WEAK | Medium | High | High | Tap controls | Topology and test state were not spatial | LAN diagnostic topology, node inspection, test and correction flow â†’ **RICH** |
| COC4 | M5 Apply Repair Action and Create Report | Repair-choice UI | selection, sequence, inspection | PPE, repair, collateral check, test, cleanup/report | WEAK | Medium | High | High | Tap controls | Repair and verification lacked a workspace | Storage repair bay, controlled repair procedure, inspection/test/report phases â†’ **RICH** |

### Classification totals

| State | Rich | Acceptable | Weak / form-like / drag-dependent |
|---|---:|---:|---:|
| Before | 1 | 4 | 15 |
| After | 12 | 8 | 0 |

The `RICH` label is reserved for missions combining a technical environment, multiple evidence-producing phases, decision or procedure depth, and an explicit verification/diagnostic interaction. Planning and preparation missions are deliberately `ACCEPTABLE`: they are meaningful but should not be inflated into artificial minigames.

## Reusable 2D framework

### Mission metadata

`mission_simulation_profile.dart` defines the presentation-only identity for all 20 missions:

- dominant workflow identity;
- scene kind;
- technical environment title;
- scenario inspection prompt; and
- neutral scene objects using normalized coordinates.

The registry never contains expected choices, criterion rules, or score thresholds.

### Reusable components

`simulation_framework.dart` provides:

- `MissionProgress`
- `SimulationScene`
- `InteractiveHotspot`
- `MultiSelectInspection`
- `ToolPalette`
- `SequenceActivity`
- `EvidenceTimeline`
- `ScenarioDecision`
- `ConfigurationPanel`
- `ComponentPlacement`
- `ConnectionPath`
- `TroubleshootingFlow`
- `TestingPanel`
- `ObservationPanel`
- `SimulationFeedback`
- `SimulationHint`

The generalized authoritative screen selects a presentation deterministically from the published stage type/action semantics. It does not receive the evaluatorâ€™s expected evidence.

## Interaction identities now available

- tap/select neutral scene objects;
- multi-select inspection;
- contextual resource/tool selection;
- tap-to-choose-next procedure sequencing;
- drag connection/placement;
- accessible source â†’ destination connection;
- visible learner-created connection summaries;
- simulated configuration panels;
- symptom inspection before diagnosis;
- simulated test execution before result interpretation;
- observation recording;
- scenario decisions;
- evidence timeline; and
- submission review through the existing result workflow.

## Evidence and persistence architecture

Primary criterion evidence is unchanged and still uses each published stageâ€™s stable `action_type`. The framework also records non-scoring interaction evidence:

- `simulation_scene_inspected`
- `simulation_operational_action`
- `simulation_selection_draft`
- `simulation_decision_draft`
- `simulation_field_draft`

Each event includes the existing attempt, mission, package, and criterion context. Draft events restore partially completed selection, decision, configuration, and connection state after navigation/process restart. Scene inspection and operational test state also restore. The PostgreSQL criterion evaluator filters for published criterion action types, so supplemental presentation events cannot satisfy a criterion or alter competence.

Sequence restoration was hardened to count only the stageâ€™s authoritative `action_type`; supplemental scene events cannot accidentally advance or complete a chronological criterion.

## Assessment integrity

- No expected evidence or answer key was added to Flutter.
- Scene hotspots use neutral styling; inspection only marks what the learner touched.
- Matching destinations do not reveal correct mappings.
- A wrong action does not auto-display the correct answer.
- Testing/troubleshooting stages require the learner to perform an operational step before recording an interpretation.
- Practice and authoritative modes remain separated by the existing router/lifecycle.
- Final competency remains PostgreSQL provisional evaluation â†’ Instructor review/finalization/release.

## Accessibility

- Scene objects expose semantic labels and selected/inspected state.
- Interactive controls retain practical 48dp or larger targets.
- Connection activities support drag and source â†’ destination selection.
- Progress and evidence feedback use live-region semantics.
- Controls use text/icon/stateâ€”not color alone.
- All new transitions honor `MediaQuery.disableAnimationsOf(context)`.
- Compact and 1.8Ã— large-text widget coverage is retained.

## Responsive and performance design

- Scene objects use normalized positions inside `LayoutBuilder`, not device-specific pixels.
- Scene composition uses lightweight Flutter primitives and `CustomPainter`.
- The scene painter is isolated in `RepaintBoundary` and repaints only when scene kind changes.
- `InteractiveViewer` supplies pinch zoom, pan, and fit/reset without a game-engine dependency.
- Animations are limited to 160â€“200ms state feedback and can be disabled.
- The framework introduces no new package, decoded raster asset, physics system, global subscription, or scoring service.

## Verification

Focused automated coverage includes:

- all 20 mission profiles and normalized scene coordinates;
- deterministic interaction-presentation resolution;
- scene hotspot interaction;
- drag connection and accessible source/destination connection;
- compact, landscape, tablet, and 1.8Ã— text layouts;
- matching touch-target sizes;
- learner-contract parsing and answer-leak rejection; and
- generalized authoritative workspace rendering.

Final command results are recorded after the full regression run below.

### Final automated results

| Verification | Result | Evidence |
|---|---|---|
| Flutter focused simulation/contract/widget suite | PASS | Scene registry, presentation resolver, hotspot, tool/multi-select, sequence, configuration, troubleshooting, drag and accessible connection, compact/landscape/tablet/large-text checks |
| Flutter full suite | PASS | 48/48 tests passed after the final interaction-test expansion |
| Flutter analyzer | PASS | `flutter analyze --no-fatal-infos` exited 0; no analyzer errors or warnings; 214 legacy informational notices remain |
| Android debug APK | PASS | `ByteQuest-Mobile-App/build/app/outputs/flutter-apk/app-debug.apk` produced successfully |
| Live mission package/version audit | PASS | 20 published authoritative activities, 20 approved rubrics, 98 criteria; learner payloads contain no evaluator answers |
| COC1 authenticated lifecycle | PASS | 5/5 missions; 10 correct/incorrect attempts; learner finalization denied; analytics/progress updated |
| COC2 remaining-mission lifecycle | PASS | M1/M3/M4/M5; 8 correct/incorrect attempts; learner finalization denied; analytics/progress updated |
| COC2 M2 golden lifecycle | PASS | Ordered evaluation, idempotency, adjustment reason, finalization, release, resource isolation, exact-once gamification, analytics and audit |
| COC3 authenticated lifecycle | PASS | 5/5 missions; 10 correct/incorrect attempts; learner finalization denied; analytics/progress updated |
| COC4 authenticated lifecycle | PASS | 5/5 missions; 10 correct/incorrect attempts; learner finalization denied; analytics/progress updated |
| Scoped Supabase Realtime E2E | PASS | Enrollment, assignment, mission submission/evaluation, released result, and resource events reached only authorized users |

The live suites also verified cross-Instructor class isolation and retired all disposable identities/classes while preserving immutable attempt history.

The first Realtime rerun exposed a channel-authentication readiness race in the E2E harness: `setAuth` was not awaited, so the first enrollment event could be emitted before the socket used the learner token. The harness now awaits authentication before subscribing. The complete rerun passed and cleaned all fixtures; production RLS policies were not weakened.

## Runtime QA and limitations

Android emulator/device visual QA was not launched in this pass, following the project ownerâ€™s standing instruction to continue development without running the emulator. Pixel-level touch accuracy, TalkBack traversal, frame pacing on low-end hardware, and process-kill restoration therefore remain **BLOCKED HUMAN QA**, not falsely marked passed.

The Flutter project retains legacy practice-screen widgets and older generalized private renderer classes for rollback safety; the active authoritative path uses the new framework. Removing those inactive rollback components is a non-blocking cleanup task after human acceptance.

## Final status

```text
MISSIONS AUDITED: 20/20

RICH BEFORE: 1
ACCEPTABLE BEFORE: 4
WEAK BEFORE: 15

RICH AFTER: 12
ACCEPTABLE AFTER: 8
WEAK AFTER: 0

20 MISSION FUNCTIONAL AUDIT: 20/20 PASS
20 MISSION DEPTH STANDARD: 20/20 PASS (automated/static; human visual QA blocked)

FLUTTER TEST: PASS â€” 48/48
FLUTTER ANALYZE: PASS â€” exit 0; 0 errors, 0 warnings, 214 information notices
APK BUILD: PASS
```


