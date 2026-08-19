# Remaining Missions Implementation Plan

**Prepared:** 2026-08-10  
**Baseline:** COC2 Mission 2 â€” Cable Termination and Testing v1 is the golden authoritative implementation.  
**Scope:** The other 19 ByteQuest missions.  
**Decision model:** explicit required evidence with `SATISFIED` / `NOT SATISFIED`; all required criteria must be satisfied. No TESDA percentage, criterion weight, safety percentage, time bonus, or retry count is introduced.

## Shared implementation approach

Assigned assessment versions use the existing authoritative lifecycle and a generalized, data-driven Flutter assessment surface. The published `learner_payload` contains learner-visible scenario stages and choices but never marks an answer as correct. PostgreSQL retains the expected evidence rules. Local catalog routes keep the existing screens as clearly labeled practice.

Supported evidence interactions:

- exact checklist/set submission;
- chronological procedure selection;
- scenario observation/decision;
- configuration field submission;
- component/connection matching; and
- inspection/report completion evidence.

Each activity is version-bound to the active official source, its COC module version, a published activity version, an approved rubric version, and stable criteria. Instructor review, revision, finalization, release, learner result, analytics, idempotency, and RBAC remain shared and are not reimplemented per mission.

## Status vocabulary

- `READY_FOR_IMPLEMENTATION` â€” current architecture can express the planned evidence.
- `NEEDS_EVIDENCE_EXTENSION` â€” current practice interaction is too narrow; the assigned version adds stages.
- `NEEDS_UI_REWORK` â€” assessment mode requires a different or generalized interaction surface.
- `NEEDS_WEB_SUPPORT` â€” shared Web review is usable, but mission/COC presentation must remain generic.
- `NEEDS_DATA_VERSION` â€” no published activity/rubric exists yet.
- `NEEDS_TESDA_MAPPING` â€” source mapping requires additional primary-source work.
- `BLOCKED` â€” official evidence is genuinely insufficient. No mission is classified blocked in this plan because the accepted TR/SAG already defines the relevant outcome; the implementation must still state the limits of simulation evidence.

## Batch 1 â€” Remaining COC2 missions (`ELC724332`)

| Mission | Current Mobile screen / interaction | Existing objective and evidence | TESDA element / PC mapping | Missing evidence to add | Planned required criteria | Sequence / safety / tools | Current Web + analytics | Data / UI / priority |
|---|---|---|---|---|---|---|---|---|
| `coc2_m1` Identify Network Devices and Tools | `IdentificationMissionScreenEnhanced`; image selection | Identifies devices/tools through `answer_submitted` | Element 1, PCs 1.1â€“1.4; underpinning knowledge | Cable-route plan, bill of materials, operational-tool check, PPE/OHS | route plan; materials; tools/test devices; PPE/OHS; requirements confirmation | Route order matters; PPE and safe tools required | Generic attempt review/analytics already support versioned evidence; activity identity absent | `NEEDS_EVIDENCE_EXTENSION`, `NEEDS_UI_REWORK`, `NEEDS_DATA_VERSION`; P0; medium |
| `coc2_m3` Test Cable Connectivity | `StepProcedureMissionScreen`; ordered selection | Connect/power/observe/verify actions | Element 1 PCs 1.3, 1.7; Element 2 PCs 2.1â€“2.2; Element 4 PCs 4.1â€“4.2 | Actual tester observation, fault classification, remedy, retest, inspection/safe completion | safe setup; exact tester sequence; observed wire map; diagnosis; corrective action/retest; inspection | Tester sequence and correction/retest order matter; safe operation required | Shared review works; needs mission-specific criterion labels and intervention grouping | `NEEDS_EVIDENCE_EXTENSION`, `NEEDS_DATA_VERSION`; P0; medium |
| `coc2_m4` Connect Devices in LAN | `DragDropMissionScreen`; drag or select/destination | Logical computerâ†’switchâ†’routerâ†’modem topology | Element 1 PCs 1.1, 1.4, 1.6â€“1.9; Element 4 PCs 4.1â€“4.2 | Design route, cable/raceway choice, PPE, physical-port connections, damage inspection, 5S | PPE/OHS; route plan; materials; topology/port match; installation sequence; inspection; cleanup | Installation chronology matters; PPE/tools/materials required | Generic evidence timeline works; mission-aware grouping required | `NEEDS_EVIDENCE_EXTENSION`, `NEEDS_UI_REWORK`, `NEEDS_DATA_VERSION`; P0; high |
| `coc2_m5` Configure IP Settings and Test Connection | `ConfigurationMissionScreen`; form | Fixed IPv4 values via `configuration_submitted` | Element 2 PCs 2.1â€“2.5; Element 3 PCs 3.1â€“3.5; Element 4 PCs 4.1â€“4.3 | Versioned network design, client/router values, communication observation, safe inspection, report | design interpretation; NIC config; LAN/WAN config; wireless/security config; ping/communication result; fault response; inspection/report | Configuration order is contextual; security settings and observed connectivity required | Shared review/analytics work; scenario metadata must be visible | `NEEDS_EVIDENCE_EXTENSION`, `NEEDS_UI_REWORK`, `NEEDS_DATA_VERSION`; P0; high |

## Batch 2 â€” COC1 missions (`ELC724331`)

| Mission | Current Mobile screen / interaction | Existing objective and evidence | TESDA element / PC mapping | Missing evidence to add | Planned required criteria | Sequence / safety / tools | Current Web + analytics | Data / UI / priority |
|---|---|---|---|---|---|---|---|---|
| `coc1_m1` Identify Computer Parts and Tools | `IdentificationMissionScreenEnhanced`; image selection | Component/tool recognition | Element 1 PCs 1.1â€“1.3 | Scenario plan, requirements comparison, PPE/OHS, safe/operational tool check | assembly plan; required components; tools/test devices; PPE/ESD preparation | Planning order contextual; PPE/ESD and tool checks required | Shared review works; current quiz evidence alone is insufficient | `NEEDS_EVIDENCE_EXTENSION`, `NEEDS_UI_REWORK`, `NEEDS_DATA_VERSION`; P0; medium |
| `coc1_m2` Install Internal Components | `COC1M2ScreenEnhanced`; drag or select/destination | Chronological placement attempts | Element 1 PCs 1.1â€“1.4 | Requirements, PPE/ESD, tools, complete component set, prohibited actions, post-install inspection | PPE/ESD; tools/materials; assembly plan; component installation; required chronology; connector/fastener inspection | Motherboard/base preparation precedes dependent components; safety critical | Shared timeline supports placements; needs source/rubric identity | `NEEDS_EVIDENCE_EXTENSION`, `NEEDS_DATA_VERSION`; P0; high |
| `coc1_m3` Connect Power and Data Cables | `COC1M3ScreenEnhanced`; cable matching | `cable_connection_attempted` cable/port evidence | Element 1 PC1.4; Evidence Guide hardware hookup | Power isolation, cable set, orientation, routing, inspection, safe power-on observation | power isolation; cable/tool check; exact cable-port matches; routing/security inspection; safe startup observation | Safety order matters; matching itself is set-based | Generic review works; matching evidence needs criterion normalization | `NEEDS_EVIDENCE_EXTENSION`, `NEEDS_DATA_VERSION`; P0; medium |
| `coc1_m4` Configure BIOS/UEFI and Install OS | `ConfigurationMissionScreen`; form | BIOS/boot/OS local values | Element 1 PC1.5; Element 2 PCs 2.1â€“2.3; Element 3 PC3.1 | Explicit hardware/user scenario, boot-media creation, installer/license choices, OS sequence and final observations | hardware detection; BIOS configuration; bootable media; installer/license preparation; OS installation sequence; final boot observation | Boot/install chronology matters; values are project scenario rules | Shared review works; raw fields require readable rendering | `NEEDS_EVIDENCE_EXTENSION`, `NEEDS_UI_REWORK`, `NEEDS_DATA_VERSION`; P0; high |
| `coc1_m5` Install Drivers and Test System | `StepProcedureMissionScreen`; ordered selection | Locally authored driver/test sequence | Element 3 PCs 3.2â€“3.4; Element 4 PCs 4.1â€“4.3; Element 5 PCs 5.1â€“5.4 | Versioned driver/application requirements, updates, quality/stress observations, 5S/3Rs, test report | required packages; driver/update sequence; application/license action; device tests; stress result; cleanup; report forwarding | Approved scenario sequence matters; test observations required | Shared review/analytics work; report evidence needs readable summary | `NEEDS_EVIDENCE_EXTENSION`, `NEEDS_UI_REWORK`, `NEEDS_DATA_VERSION`; P0; high |

## Batch 3 â€” COC3 missions (`ELC724333`)

| Mission | Current Mobile screen / interaction | Existing objective and evidence | TESDA element / PC mapping | Missing evidence to add | Planned required criteria | Sequence / safety / tools | Current Web + analytics | Data / UI / priority |
|---|---|---|---|---|---|---|---|---|
| `coc3_m1` Prepare Server Setup Requirements | `IdentificationMissionScreen`; selection | Identifies hardware, installer, network, UPS, backup, documentation | Element 2 PCs 2.1â€“2.3; underpinning knowledge | User/system requirements, server roles/services rationale, tool/test plan | requirements interpretation; hardware/power/network materials; required services; tools/tests; implementation plan | Planning sequence contextual; safe power/network resources required | Shared review works; criterion grouping absent | `NEEDS_EVIDENCE_EXTENSION`, `NEEDS_UI_REWORK`, `NEEDS_DATA_VERSION`; P0; medium |
| `coc3_m2` Install and Configure Server OS | `StepProcedureMissionScreen`; ordered selection | Eight-step local OS installation | Element 2 PCs 2.1â€“2.3 as preparation/support | Approved OS scenario, normal-function observation, required modules/add-ons and service confirmation | preflight; install sequence; identity/time/security setup; modules/add-ons; required services; boot/function observation | Installation chronology matters; license/security actions required | Shared review works; source/rubric absent | `NEEDS_EVIDENCE_EXTENSION`, `NEEDS_DATA_VERSION`; P0; high |
| `coc3_m3` Configure Server Network Settings | `ConfigurationMissionScreen`; form | Fixed server IP/mask/gateway/DNS | Element 2 PCs 2.1, 2.3â€“2.4 | Versioned design, service bindings, client connectivity and observed results | network design; server NIC config; service binding; server/client communication test; normal operation result | Config then test order matters | Shared review/analytics work; scenario metadata must display | `NEEDS_EVIDENCE_EXTENSION`, `NEEDS_UI_REWORK`, `NEEDS_DATA_VERSION`; P0; high |
| `coc3_m4` Create Users, Groups and Permissions | `ConfigurationMissionScreen`; form | Fixed user/group/share/permission values | Element 1 PCs 1.1â€“1.3; Element 3 PC3.2 | Explicit access policy, user folder action, least privilege, positive and negative access tests | folder/user creation; group membership; least-privilege ACL; authorized access test; denied access test; security review | Create before permission/test order matters | Shared review works; access-test observations need drilldown | `NEEDS_EVIDENCE_EXTENSION`, `NEEDS_UI_REWORK`, `NEEDS_DATA_VERSION`; P0; high |
| `coc3_m5` Test Client Access and Document Setup | `TroubleshootingMissionScreen`; cause selection | Four diagnosis answers | Element 2 PCs 2.4â€“2.5; Element 3 PCs 3.1â€“3.3 | Executed service/client checks, response/remediation/retest, pre-deployment checklist, report | service checks; client access; controlled fault diagnosis; response/retest; pre-deployment checks; operation/security checks; report | Diagnoseâ†’remedyâ†’retest chronology matters | Generic timeline/history works; mission report and failure grouping needed | `NEEDS_EVIDENCE_EXTENSION`, `NEEDS_UI_REWORK`, `NEEDS_DATA_VERSION`; P0; high |

## Batch 4 â€” COC4 missions (`ELC724334`)

| Mission | Current Mobile screen / interaction | Existing objective and evidence | TESDA element / PC mapping | Missing evidence to add | Planned required criteria | Sequence / safety / tools | Current Web + analytics | Data / UI / priority |
|---|---|---|---|---|---|---|---|---|
| `coc4_m1` Identify System and Network Problems | `IdentificationMissionScreen`; scenario cause selection | Knowledge-level symptom/cause answers | Element 1 PCs 1.1â€“1.5; Element 3 PC3.2 | Service order, plan, tool/material choices, observed checks, diagnostic sequence | service-order interpretation; PPE/tools/materials; diagnostic plan; baseline checks; evidence-based diagnosis | Test order matters; safe tools/PPE required | Shared review works; quiz-only evidence is insufficient | `NEEDS_EVIDENCE_EXTENSION`, `NEEDS_UI_REWORK`, `NEEDS_DATA_VERSION`; P0; high |
| `coc4_m2` Perform Preventive Maintenance | `StepProcedureMissionScreen`; ordered selection | Shutdown, unplug, ESD, clean, inspect, reseat, test | Element 1 PCs 1.2â€“1.4; Element 2 PCs 2.1â€“2.3; Element 5 PCs 5.1â€“5.5 | Explicit PPE/tools/materials, manufacturer/job scenario, observations, disposal/5S, measured final result | PPE/tools/materials; safe shutdown; maintenance sequence; component observations; final inspection/test; 5S/WEEE | Safety-critical exact chronology required | Shared review works; strongest next candidate | `NEEDS_EVIDENCE_EXTENSION`, `NEEDS_DATA_VERSION`; P0; high |
| `coc4_m3` Diagnose Hardware and Software Faults | `TroubleshootingMissionScreen`; cause selection | Four diagnosis answers | Element 2 PC2.2; Element 3 PCs 3.1â€“3.4 | PPE, test selection/actions, observations, isolation, contingency, remediation and retest | PPE/OHS; baseline test; chronological isolation; diagnosis; contingency response; correction; retest | Diagnostic chronology and safety required | Shared review/analytics work; repeated-failure criteria useful | `NEEDS_EVIDENCE_EXTENSION`, `NEEDS_UI_REWORK`, `NEEDS_DATA_VERSION`; P0; high |
| `coc4_m4` Troubleshoot Network Issues | `TroubleshootingMissionScreen`; cause selection | Four network diagnosis answers | Element 2 PC2.2; Element 3 PCs 3.1â€“3.4 | Topology/config observations, commands/tests, isolation, contingency, remedy and retest | PPE/OHS; service-order/topology review; test sequence; observed results; diagnosis; correction; retest | Test/isolation order matters | Shared review/analytics work; mission-aware intervention needed | `NEEDS_EVIDENCE_EXTENSION`, `NEEDS_UI_REWORK`, `NEEDS_DATA_VERSION`; P0; high |
| `coc4_m5` Apply Repair Action and Create Report | `TroubleshootingMissionScreen`; repair-choice selection | Selects a repair response | Element 2 PC2.4; Element 4 PCs 4.1â€“4.4; Element 5 PCs 5.1â€“5.6 | Performed correction, collateral-damage check, adjustments, safe test, cleanup/WEEE, report artifact | PPE; repair sequence; corrective result; collateral inspection; safe-operation test; cleanup/disposal; service report | Repairâ†’inspectâ†’testâ†’cleanup/report chronology required | Shared review works; report evidence must be readable | `NEEDS_EVIDENCE_EXTENSION`, `NEEDS_UI_REWORK`, `NEEDS_DATA_VERSION`; P0; high |

## Batch acceptance gates

For each batch:

1. Create immutable module/activity/rubric/criterion versions through the audited publication boundary.
2. Validate every learner payload against the shared assessment contract.
3. Exercise correct, incorrect, missing, and wrong-order evidence against PostgreSQL.
4. Verify one criterion result per criterion and one provisional revision per submission.
5. Verify Instructor scope, review, reasoned adjustment, finalization, and release.
6. Verify released-only learner results, progress/gamification exact-once, analytics, and audit.
7. Run Flutter contract/widget tests, TypeScript/build tests, SQL rollback tests, and authenticated lifecycle tests before the next batch.

## Known limits that remain disclosed

- ByteQuest captures simulation evidence; it does not certify real physical dexterity, workmanship, or official TESDA competence by itself.
- Scenario-specific expected values and sequences are `PROJECT_APPROVED_OPERATIONAL_RULE`, not universal TESDA rules.
- Automated provisional results remain subject to Instructor evidence review, finalization, and release.
- Existing legacy percentages and XP/point rows remain quarantined and cannot influence these authoritative decisions.

