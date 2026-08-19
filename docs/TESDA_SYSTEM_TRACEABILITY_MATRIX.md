# TESDA-to-ByteQuest System Traceability Matrix

**Assessment activation state:** `ALL_20_BYTEQUEST_ASSESSMENT_PACKAGES_ACTIVE`  
**Prepared:** 2026-08-10  
**Scope:** The four core competencies of Computer Systems Servicing NC II and the current 20 ByteQuest mobile missions.

## Source set and version decision

| Source | Verified identity | Use in this matrix | Provenance status |
|---|---|---|---|
| TESDA Training Regulations, *Computer Systems Servicing NC II* | Amended December 2013; Board Resolution No. 2013-13; SHA-256 `42D85DAD87D0566B8B965AC0868E0F92E6CBB4C578028EFF648DB21BE421D147` | Normative competency, element, performance-criterion, evidence-guide, method, resource, and context source | `TESDA_OFFICIAL_APPROVED` |
| TESDA Circular No. 18, series of 2015 | Issued June 3, 2015; SHA-256 `ECD74B9FC5B99AB946B91D9A42FABDE667660DF1E609EBB9D0FE30CD98AAB97A` | Confirms deployment of the amended TR and the four core competencies | `TESDA_OFFICIAL_APPROVED` |
| TESDA Self-Assessment Guide, Computer Systems Servicing NC II | Qualification code `ELCCSS213`; document `ELCCSS213-022021 ver. 1.00`; SHA-256 `536284530C225C60AA79CF7A36909ED5B928584A0E5FA2CC248A65E88CAA2333` | Readiness checklist and critical-aspect cross-check only | `TESDA_OFFICIAL_APPROVED`; not a numeric rubric |
| Project-owner-approved ByteQuest mission packages | COC2 M2 explicitly approved, then remaining 19 directed for implementation on 2026-08-10 | Operationalizes 98 evidence criteria across 20 missions; it does not create a TESDA numeric threshold | `PROJECT_APPROVED_OPERATIONAL_RULE` |

Official files:

- Training Regulations: https://tesda.gov.ph/Downloadables/TRs/TR%20Computer%20Systems%20Servicing%20NC%20II%20.pdf
- Current combined SAG: https://tesda.gov.ph/Downloadables/SAGs/FULL.SAG.pdf
- Circular index and download: https://intranet.tesda.gov.ph/CircularIframe/

No numeric passing percentage, weighting formula, safety percentage, time bonus, XP value, or point value was found in these official sources. None may be represented as a TESDA rule.

## Reading the matrix

- `DRAFT-*` criterion IDs in the historical tables remain traceability-only records from the pre-implementation audit; current published criteria use stable `COC*-M*-*` codes.
- `C1M1` means COC 1 Mission 1; the same convention applies to all missions.
- â€œCurrent evidenceâ€ in the historical tables describes what the old practice client could record before the shared authoritative workspace was implemented.
- Every published operational criterion is bound to an immutable TESDA source, module version, activity version, and rubric version.
- Every `TR-2013` performance-criterion row below has `TESDA_OFFICIAL_APPROVED` provenance. Its final column evaluates ByteQuest evidence/activation sufficiency, not whether the TESDA criterion itself is official.
- COC2 Cable Termination and Testing remains the golden architecture reference; all other assigned mission activities now use the same authoritative lifecycle through the shared contract.

Status meanings: `TESDA_OFFICIAL_APPROVED` (source provenance), `PROJECT_APPROVED_OPERATIONAL_RULE`, `PARTIAL`, `MISSING`, `SYSTEM_GAMIFICATION_RULE`, and `REQUIRES_POLICY_DECISION`.

## Golden reference assessment â€” COC2 Cable Termination and Testing v1

Live chain: active TESDA source â†’ published module version â†’ published activity version â†’ approved rubric version â†’ nine required criteria. The rubric decision method is `all_required`. Technical 1/0 values encode `SATISFIED` / `NOT SATISFIED`; they are not weights or a TESDA percentage.

| Criterion ID | Official source / unit / element / criterion | ByteQuest evidence | Automated evaluation | Provenance / activation |
|---|---|---|---|---|
| `COC2-CABLE-01-PPE-OHS` | TR ELC724332 Element 1, PC 1.4; COC2 SAG PPE/OHS checklist | Final `ppe_prepared` selected-item snapshot | Exact required PPE set | Official obligation: `TESDA_OFFICIAL_APPROVED`; checklist/event contract: `PROJECT_APPROVED_OPERATIONAL_RULE`; ACTIVE |
| `COC2-CABLE-02-TOOLS-MATERIALS` | TR ELC724332 Element 1, PCs 1.2â€“1.3 | Final `tools_materials_checked` snapshot | Exact required cable, connector, stripper, crimper, and tester set | Official obligation: `TESDA_OFFICIAL_APPROVED`; simulation inventory contract: `PROJECT_APPROVED_OPERATIONAL_RULE`; ACTIVE |
| `COC2-CABLE-03-CABLE-PREPARATION` | TR ELC724332 Element 1, PC 1.5; required cable splicing/testing skills | Ordered `cable_preparation_step` targets | Exact chronological `measure_cable â†’ strip_jacket â†’ untwist_and_straighten` | Official outcome: `TESDA_OFFICIAL_APPROVED`; simulated sequence: `PROJECT_APPROVED_OPERATIONAL_RULE`; ACTIVE |
| `COC2-CABLE-04-T568B-ORDER` | TR ELC724332 PC 1.5; official COC2 SAG explicitly names 568A/568B compliance | Eight chronological `conductor_placed` actions with pin position | Exact T568B target sequence; `B â†’ A` cannot satisfy `A â†’ B` | Official standards obligation: `TESDA_OFFICIAL_APPROVED`; selected T568B scenario/order contract: `PROJECT_APPROVED_OPERATIONAL_RULE`; ACTIVE |
| `COC2-CABLE-05-TERMINATION` | TR ELC724332 PC 1.5 | Ordered `termination_step` actions | Exact insertion, jacket-depth verification, crimp sequence | Official termination outcome: `TESDA_OFFICIAL_APPROVED`; simulation sequence: `PROJECT_APPROVED_OPERATIONAL_RULE`; ACTIVE |
| `COC2-CABLE-06-TESTER-USE` | TR ELC724332 PCs 1.3, 1.7 and 4.2; Evidence Guide cable testing | Ordered `tester_step` actions | Exact connect, power, observe sequence | Official testing/safe-operation obligation: `TESDA_OFFICIAL_APPROVED`; event contract: `PROJECT_APPROVED_OPERATIONAL_RULE`; ACTIVE |
| `COC2-CABLE-07-TESTER-RESULT` | TR ELC724332 PCs 1.7, 2.1 and 4.2; Evidence Guide installed cable is inspected/tested | Final `tester_result_submitted.result` | Result must equal the activity scenario's `pass` observation | Official observed/tested outcome: `TESDA_OFFICIAL_APPROVED`; simulator result vocabulary: `PROJECT_APPROVED_OPERATIONAL_RULE`; ACTIVE |
| `COC2-CABLE-08-PHYSICAL-INSPECTION` | TR ELC724332 PCs 1.7 and 4.1 | Final `physical_inspection_completed` snapshot | Exact required damage/order/security inspection set | Official inspection obligation: `TESDA_OFFICIAL_APPROVED`; checklist representation: `PROJECT_APPROVED_OPERATIONAL_RULE`; ACTIVE |
| `COC2-CABLE-09-5S-CLEANUP` | TR ELC724332 PCs 1.8â€“1.9; COC2 SAG 5S/3Rs | Final `cleanup_completed` snapshot | Exact tools-returned, work-area-cleared, scraps-sorted set | Official OHS/5S/WEEE obligation: `TESDA_OFFICIAL_APPROVED`; checklist representation: `PROJECT_APPROVED_OPERATIONAL_RULE`; ACTIVE |

Instructor review, append-only adjustment, finalization, and release are project governance controls. The official TR permits simulation among assessment contexts/methods but ByteQuest remains supplementary and does not issue TESDA certification.

## Current published operational traceability

The live chain is now: official TESDA source â†’ core unit/element/PC basis â†’ COC â†’ module/mission â†’ published `activity_version` â†’ approved `rubric_version` â†’ required `rubric_criteria` â†’ ordered `attempt_actions` â†’ PostgreSQL `criterion_results` â†’ provisional revision â†’ Instructor finalization/release â†’ learner result/analytics. There are 20 published activities, 20 approved rubrics, and 98 required criteria.

| Unit / source basis | ByteQuest mission package | Evidence family | Required criteria | Activation |
|---|---|---|---:|---|
| `ELC724331`, TR printed pp. 37â€“41, applicable SAG | COC1 M1 â€” preparation/resources | Plan sequence, components, tools, OHS/ESD | 4 | TESDA basis approved; project scenario active |
| `ELC724331`, TR pp. 37â€“41 | COC1 M2 â€” component installation | Safety, installation sequence, matching, fastening, inspection | 5 | TESDA basis approved; project scenario active |
| `ELC724331`, TR pp. 37â€“41 | COC1 M3 â€” internal cabling | Safe state, matching, verification sequence, inspection | 4 | TESDA basis approved; project scenario active |
| `ELC724331`, TR pp. 37â€“41 | COC1 M4 â€” firmware/OS | Preflight, scenario configuration, boot media, sequence, final boot | 5 | TESDA basis approved; project scenario active |
| `ELC724331`, TR pp. 37â€“41 | COC1 M5 â€” drivers/apps/testing | Package selection, sequence, configuration, tests, completion | 5 | TESDA basis approved; project scenario active |
| `ELC724332`, TR printed pp. 42â€“45, applicable SAG | COC2 M1 â€” network planning/resources | Route plan, materials, tools, PPE/OHS | 4 | TESDA basis approved; project scenario active |
| `ELC724332`, TR pp. 42â€“45, SAG 568A/568B/PPE/5S | COC2 M2 â€” cable termination/testing | PPE, tools, cable prep, T568B order, crimp, tester, result, inspection, cleanup | 9 | TESDA basis approved; project package active |
| `ELC724332`, TR pp. 42â€“45 | COC2 M3 â€” cable diagnosis | Safe setup, test sequence, fault observation, correction/retest, result | 5 | TESDA basis approved; project scenario active |
| `ELC724332`, TR pp. 42â€“45 | COC2 M4 â€” LAN installation | Preparation, route, topology matching, completion | 4 | TESDA basis approved; project scenario active |
| `ELC724332`, TR pp. 42â€“45 | COC2 M5 â€” LAN configuration | Design, NIC/router settings, communication, report | 5 | TESDA basis approved; project scenario active |
| `ELC724333`, TR printed pp. 46â€“48, applicable SAG | COC3 M1 â€” server plan/resources | Requirements, platform, tools, plan sequence | 4 | TESDA basis approved; project scenario active |
| `ELC724333`, TR pp. 46â€“48 | COC3 M2 â€” NOS preparation | Preflight, install, identity/security, modules, operation | 5 | TESDA basis approved; project scenario active |
| `ELC724333`, TR pp. 46â€“48 | COC3 M3 â€” server networking | Design, NIC, service binding, connectivity | 4 | TESDA basis approved; project scenario active |
| `ELC724333`, TR pp. 46â€“48 | COC3 M4 â€” access/permissions | Policy, creation sequence, permissions, positive/negative tests | 5 | TESDA basis approved; project scenario active |
| `ELC724333`, TR pp. 46â€“48 | COC3 M5 â€” services/predeployment | Checks, diagnosis, remedy/retest, security, report | 5 | TESDA basis approved; project scenario active |
| `ELC724334`, TR printed pp. 49â€“53, applicable SAG | COC4 M1 â€” fault planning/isolation | Service order, resources, diagnostic sequence, observation, diagnosis | 5 | TESDA basis approved; project scenario active |
| `ELC724334`, TR pp. 49â€“53 | COC4 M2 â€” preventive maintenance | PPE/tools, shutdown, maintenance sequence, final test, cleanup | 5 | TESDA basis approved; project scenario active |
| `ELC724334`, TR pp. 49â€“53 | COC4 M3 â€” desktop fault | Safety, tests, diagnosis, correction, retest | 5 | TESDA basis approved; project scenario active |
| `ELC724334`, TR pp. 49â€“53 | COC4 M4 â€” LAN fault | Service order, tools/safety, tests, diagnosis, correction/retest | 5 | TESDA basis approved; project scenario active |
| `ELC724334`, TR pp. 49â€“53 | COC4 M5 â€” repair/report | Safety/resources, repair, collateral inspection, safe result, report | 5 | TESDA basis approved; project scenario active |

Every stable criterion code is indexed in `docs/ALL_MISSIONS_IMPLEMENTATION_REPORT.md`. Its exact official source interpretation and controlled-scenario qualification are stored in `rubric_criteria.source_trace`; its hidden deterministic rule is stored in `rubric_criteria.scoring_rule`. The corresponding learner payload contains neither expected answers nor scoring rules.

## Historical pre-implementation gap map

The detailed PC rows below preserve the original audit evidence and explain why the old practice screens alone were insufficient. Their old `DRAFT-*`, `PARTIAL`, and `MISSING` statuses are historical and are superseded for the published packages by the current operational table above; they remain useful as a warning not to treat the unassigned practice UI as authoritative.

## ELC724331 â€” Install and Configure Computer Systems (COC 1, historical audit)

TR printed pages 38â€“42; evidence guide requires demonstrated hardware assembly, OS/driver installation, application installation, testing, and documentation. The TR permits workplace or simulated assessment and calls for assessor-selected methods; ByteQuest simulation evidence alone must therefore be approved as an institutional implementation.

| Source / Element | Performance criterion summary | ByteQuest module / mission / activity | Draft criterion ID | Current evidence collected | Required evaluation and review | Status |
|---|---|---|---|---|---|---|
| TR-2013 E1 PC1.1 | Plan assembly while following OH&S and system requirements | COC1 / C1M1 parts ID + C1M2 placement | DRAFT-ELC724331-PC1.1 | Identification answers and placement actions; no plan/OH&S record | Approved plan and safety evidence; safety-critical review | PARTIAL |
| TR-2013 E1 PC1.2 | Identify/obtain materials and check against requirements | COC1 / C1M1 identification | DRAFT-ELC724331-PC1.2 | Selected component/tool identifiers | Match to approved scenario requirements, not generic names alone | PARTIAL |
| TR-2013 E1 PC1.3 | Obtain safe, operational tools/test devices | COC1 / C1M1 identification | DRAFT-ELC724331-PC1.3 | Tool-identification answers only | Tool selection plus operation/safety check evidence | PARTIAL |
| TR-2013 E1 PC1.4 | Assemble hardware to procedure and requirements | COC1 / C1M2 drag/drop + C1M3 cable matching | DRAFT-ELC724331-PC1.4 | Ordered placements and cable matches | Approved component/cable set, chronological placement, prohibited-action and completion evidence | PARTIAL |
| TR-2013 E1 PC1.5 | Configure BIOS for hardware requirements | COC1 / C1M4 configuration | DRAFT-ELC724331-PC1.5 | Local BIOS/boot-option selections | Compare with explicit scenario requirements; current â€œHard Driveâ€ answer needs confirmation | REQUIRES_POLICY_DECISION |
| TR-2013 E2 PC2.1 | Create portable bootable device per manufacturer instructions | COC1 / C1M4 configuration | DRAFT-ELC724331-PC2.1 | No boot-media creation evidence | Actual simulated creation steps and artifact/result | MISSING |
| TR-2013 E2 PC2.2 | Prepare customized installer per utilization guide/agreement | COC1 / C1M4 configuration | DRAFT-ELC724331-PC2.2 | No customized-installer evidence | Scenario-specific options, source guide, and accepted agreement evidence | MISSING |
| TR-2013 E2 PC2.3 | Install portable applications per guide/license | COC1 / C1M4 configuration | DRAFT-ELC724331-PC2.3 | No portable-application evidence | Installation actions and license/guide compliance | MISSING |
| TR-2013 E3 PC3.1 | Install OS to procedure and user requirements | COC1 / C1M4 ordered configuration | DRAFT-ELC724331-PC3.1 | Chronological local OS-install selections | Approved scenario, required branches, failures, and end state | PARTIAL |
| TR-2013 E3 PC3.2 | Install/configure peripheral drivers per instructions | COC1 / C1M5 sequence | DRAFT-ELC724331-PC3.2 | Fixed local driver-order actions | Manufacturer/OS-specific expected evidence; local order requires approval | REQUIRES_POLICY_DECISION |
| TR-2013 E3 PC3.3 | Access/install OS and driver updates | COC1 / C1M5 sequence | DRAFT-ELC724331-PC3.3 | Limited update step in local sequence | Approved update/patch scenario and observed result | PARTIAL |
| TR-2013 E3 PC3.4 | Perform ongoing quality checks | COC1 / C1M5 sequence | DRAFT-ELC724331-PC3.4 | Completion and local correctness only | Explicit checks, observations, failures, and remediation evidence | PARTIAL |
| TR-2013 E4 PC4.1 | Install applications using guides, requirements, and license | COC1 / C1M5 sequence | DRAFT-ELC724331-PC4.1 | No application-install transaction evidence | Application, guide, license, choices, and final state | MISSING |
| TR-2013 E4 PC4.2 | Apply installation variations to client requirements | COC1 / C1M5 sequence | DRAFT-ELC724331-PC4.2 | No branching client-requirement evidence | Scenario branch and justified configuration evidence | MISSING |
| TR-2013 E4 PC4.3 | Access/install software updates | COC1 / C1M5 sequence | DRAFT-ELC724331-PC4.3 | Generic update-related step only | Versioned scenario and manufacturer-based success evidence | PARTIAL |
| TR-2013 E5 PC5.1 | Test devices/system/installation against requirements | COC1 / C1M5 testing sequence | DRAFT-ELC724331-PC5.1 | Local ordered steps and completion | Test inputs, expected observations, actual results, and requirement comparison | PARTIAL |
| TR-2013 E5 PC5.2 | Conduct stress test for reliability | COC1 / C1M5 testing sequence | DRAFT-ELC724331-PC5.2 | No stress-test telemetry/result | Approved simulated procedure and observable reliability result | MISSING |
| TR-2013 E5 PC5.3 | Follow 5S and 3Rs | No dedicated current activity | DRAFT-ELC724331-PC5.3 | None | Observable cleanup/environmental actions; human policy confirmation | MISSING |
| TR-2013 E5 PC5.4 | Forward test documentation appropriately | COC1 / C1M5 title/objective only | DRAFT-ELC724331-PC5.4 | No submitted document/report | Report artifact, recipient, timestamp, and instructor review | MISSING |

## ELC724332 â€” Set-up Computer Networks (COC 2, historical audit)

TR printed pages 42â€“46; the evidence guide requires cable installation, network configuration, router/wireless configuration, and inspection/testing. The SAG explicitly references both 568A and 568B; ByteQuest currently exercises only a local 568B scenario.

| Source / Element | Performance criterion summary | ByteQuest module / mission / activity | Draft criterion ID | Current evidence collected | Required evaluation and review | Status |
|---|---|---|---|---|---|---|
| TR-2013 E1 PC1.1 | Plan cable routes from design/site | COC2 / C2M1 identification | DRAFT-ELC724332-PC1.1 | Device/tool choices; no route plan | Route artifact compared to scenario design/site constraints | MISSING |
| TR-2013 E1 PC1.2 | Identify/obtain materials against requirements | COC2 / C2M1 identification | DRAFT-ELC724332-PC1.2 | Material/device/tool identification | Scenario bill of materials and omissions/excess evidence | PARTIAL |
| TR-2013 E1 PC1.3 | Obtain safe, operational tools/test devices | COC2 / C2M1 + C2M3 tester procedure | DRAFT-ELC724332-PC1.3 | Tool choices and tester sequence | Operation/safety check evidence, not identification alone | PARTIAL |
| TR-2013 E1 PC1.4 | Use PPE and follow OHS | No dedicated current activity | DRAFT-ELC724332-PC1.4 | None | Safety-critical PPE/OHS actions; instructor-approved failure policy | MISSING |
| TR-2013 E1 PC1.5 | Perform copper splicing to EIA/TIA standards | COC2 / C2M2 T568B sequence | DRAFT-ELC724332-PC1.5 | Exact chronological conductor-color sequence | Approve scenario as 568B; capture termination/tool/test outcome; do not generalize to all cabling | PARTIAL |
| TR-2013 E1 PC1.6 | Install cable and raceway to requirements | COC2 / C2M4 connect LAN devices | DRAFT-ELC724332-PC1.6 | Logical device connections only | Physical route/raceway/installation evidence | PARTIAL |
| TR-2013 E1 PC1.7 | Check work for damage and compliance | COC2 / C2M3 tester procedure | DRAFT-ELC724332-PC1.7 | Ordered tester actions | Inspection observations and compliance result | PARTIAL |
| TR-2013 E1 PC1.8 | Follow OHS and 5S | No dedicated current activity | DRAFT-ELC724332-PC1.8 | None | Observable safety/housekeeping actions | MISSING |
| TR-2013 E1 PC1.9 | Dispose excess under WEEE/3Rs | No dedicated current activity | DRAFT-ELC724332-PC1.9 | None | Disposal decision and scenario policy evidence | MISSING |
| TR-2013 E2 PC2.1 | Check each terminalâ€™s connectivity to design | COC2 / C2M3 tester + C2M5 IP config | DRAFT-ELC724332-PC2.1 | Tester sequence and configuration values | Per-terminal connectivity observations against approved design | PARTIAL |
| TR-2013 E2 PC2.2 | Diagnose/remedy network faults to SOP | COC2 / C2M3 + C2M5 | DRAFT-ELC724332-PC2.2 | Procedure/config inputs; no complete repair path | Fault isolation, remedy, retest, and SOP evidence | PARTIAL |
| TR-2013 E2 PC2.3 | Configure NIC to network design | COC2 / C2M5 form configuration | DRAFT-ELC724332-PC2.3 | IP/mask/gateway/DNS inputs | Validate IPv4 ranges and compare with scenario design; current fixed addresses are institutional scenario data | REQUIRES_POLICY_DECISION |
| TR-2013 E2 PC2.4 | Check communication between terminals | COC2 / C2M5 configuration | DRAFT-ELC724332-PC2.4 | No terminal-to-terminal result evidence | Ping/share/resource-access action and observation | MISSING |
| TR-2013 E2 PC2.5 | Respond to unplanned conditions per procedure | No current branching activity | DRAFT-ELC724332-PC2.5 | None | Controlled unexpected event, response actions, and review | MISSING |
| TR-2013 E3 PC3.1 | Configure client-device settings | COC2 / C2M5 partial | DRAFT-ELC724332-PC3.1 | NIC values only | Manufacturer/end-user scenario and complete settings evidence | PARTIAL |
| TR-2013 E3 PC3.2 | Configure LAN port to design | No current router configuration activity | DRAFT-ELC724332-PC3.2 | None | Router LAN configuration actions and final state | MISSING |
| TR-2013 E3 PC3.3 | Configure WAN port to design | No current router configuration activity | DRAFT-ELC724332-PC3.3 | None | Router WAN configuration actions and final state | MISSING |
| TR-2013 E3 PC3.4 | Configure wireless settings | No current router configuration activity | DRAFT-ELC724332-PC3.4 | None | Wireless configuration actions and final state | MISSING |
| TR-2013 E3 PC3.5 | Configure security/firewall/advanced settings | No current router configuration activity | DRAFT-ELC724332-PC3.5 | None | Security settings, prohibited insecure choices, and review | MISSING |
| TR-2013 E4 PC4.1 | Inspect configuration against manual | COC2 / C2M3 + C2M5 partial | DRAFT-ELC724332-PC4.1 | Local completion/correctness | Approved manual/version and inspection checklist evidence | PARTIAL |
| TR-2013 E4 PC4.2 | Check network for safe operation | COC2 / C2M3 tester procedure | DRAFT-ELC724332-PC4.2 | Tester action sequence | Safety result, observed defects, and retest | PARTIAL |
| TR-2013 E4 PC4.3 | Prepare company-required report | No current report activity | DRAFT-ELC724332-PC4.3 | None | Submitted report artifact and instructor review | MISSING |

## ELC724333 â€” Set-up Computer Servers (COC 3, historical audit)

TR printed pages 46â€“49; the evidence guide requires user access, configured network services, and testing/documentation/pre-deployment. Installing a server OS is useful preparation but does not by itself satisfy these elements.

| Source / Element | Performance criterion summary | ByteQuest module / mission / activity | Draft criterion ID | Current evidence collected | Required evaluation and review | Status |
|---|---|---|---|---|---|---|
| TR-2013 E1 PC1.1 | Create user folder using NOS features | COC3 / C3M4 users/groups/permissions | DRAFT-ELC724333-PC1.1 | Local user/group/share selections | Actual folder action and verified resulting access state | PARTIAL |
| TR-2013 E1 PC1.2 | Configure access level to policy/requirements | COC3 / C3M4 users/groups/permissions | DRAFT-ELC724333-PC1.2 | Fixed local choices (`admin`, group, share, permission) | Explicit policy/end-user scenario; least-privilege evidence; local answers require approval | REQUIRES_POLICY_DECISION |
| TR-2013 E1 PC1.3 | Perform security check to access policy | COC3 / C3M4 partial | DRAFT-ELC724333-PC1.3 | No security-check result | Positive/negative access tests and observed results | MISSING |
| TR-2013 E2 PC2.1 | Check normal server functions | COC3 / C3M2 OS + C3M3 static IP | DRAFT-ELC724333-PC2.1 | Ordered install/config inputs | Boot and connectivity observations against manufacturer guidance | PARTIAL |
| TR-2013 E2 PC2.2 | Install/update required modules/add-ons | COC3 / C3M2 server OS sequence | DRAFT-ELC724333-PC2.2 | Generic install sequence; no module record | Module identity/version, install actions, and outcome | MISSING |
| TR-2013 E2 PC2.3 | Confirm required network services | COC3 / C3M1 preparation | DRAFT-ELC724333-PC2.3 | Requirement-identification choices | Approved user/system requirements and selected services | PARTIAL |
| TR-2013 E2 PC2.4 | Check operation of network services | COC3 / C3M5 troubleshooting multiple choice | DRAFT-ELC724333-PC2.4 | Diagnosis answer only | Service operation actions/observations and client verification | PARTIAL |
| TR-2013 E2 PC2.5 | Respond to unplanned conditions per procedure | COC3 / C3M5 troubleshooting multiple choice | DRAFT-ELC724333-PC2.5 | Selected diagnosis; no response execution | Chronological response, remediation, and retest | PARTIAL |
| TR-2013 E3 PC3.1 | Perform pre-deployment procedures | COC3 / C3M5 title/objective only | DRAFT-ELC724333-PC3.1 | None | Approved pre-deployment checklist and actions | MISSING |
| TR-2013 E3 PC3.2 | Perform operation and security checks | COC3 / C3M4 + C3M5 partial | DRAFT-ELC724333-PC3.2 | Configuration/diagnosis choices | Operation/security test evidence and results | PARTIAL |
| TR-2013 E3 PC3.3 | Prepare reports to enterprise policy | COC3 / C3M5 title/objective only | DRAFT-ELC724333-PC3.3 | No report artifact | Completed report, policy reference, and instructor review | MISSING |

## ELC724334 â€” Maintain and Repair Computer Systems and Networks (COC 4, historical audit)

TR printed pages 49â€“53; the evidence guide requires planning, maintenance, diagnosis, rectification, inspection, testing, and reporting. Most current COC 4 missions select answers about a fault rather than demonstrate the required work.

| Source / Element | Performance criterion summary | ByteQuest module / mission / activity | Draft criterion ID | Current evidence collected | Required evaluation and review | Status |
|---|---|---|---|---|---|---|
| TR-2013 E1 PC1.1 | Plan maintenance/diagnosis to job requirements | COC4 / C4M1 symptom/cause identification | DRAFT-ELC724334-PC1.1 | Multiple-choice diagnosis | Job order, plan, intended tests, and sequencing evidence | PARTIAL |
| TR-2013 E1 PC1.2 | Obtain/check tools and test devices for safety | COC4 / C4M2 maintenance sequence | DRAFT-ELC724334-PC1.2 | Procedure order only | Tool choice plus operation/safety check | PARTIAL |
| TR-2013 E1 PC1.3 | Obtain/check materials against job | No dedicated current activity | DRAFT-ELC724334-PC1.3 | None | Scenario material selection and requirement comparison | MISSING |
| TR-2013 E1 PC1.4 | Follow OHS to job requirements | COC4 / C4M2 maintenance sequence | DRAFT-ELC724334-PC1.4 | Safety-aware local ordering | Instructor-approved safety-critical steps and prohibited actions | REQUIRES_POLICY_DECISION |
| TR-2013 E1 PC1.5 | Check system/network against service order | COC4 / C4M1 diagnosis | DRAFT-ELC724334-PC1.5 | Symptom/cause choice; no service order | Versioned service order and observed check results | PARTIAL |
| TR-2013 E2 PC2.1 | Use appropriate PPE | COC4 / C4M2 partial | DRAFT-ELC724334-PC2.1 | No explicit PPE selection evidence | Safety-critical PPE action | MISSING |
| TR-2013 E2 PC2.2 | Check normal function per manufacturer | COC4 / C4M3 hardware/software diagnosis + C4M4 network diagnosis | DRAFT-ELC724334-PC2.2 | Multiple-choice diagnosis | Executed tests and observed baseline results | PARTIAL |
| TR-2013 E2 PC2.3 | Perform scheduled maintenance | COC4 / C4M2 ordered sequence | DRAFT-ELC724334-PC2.3 | Chronological maintenance actions | Approved manufacturer-specific procedure and result | PARTIAL |
| TR-2013 E2 PC2.4 | Make needed repair/replacement to procedure | COC4 / C4M5 repair selection | DRAFT-ELC724334-PC2.4 | Selected repair answer only | Actual simulated correction/replacement and outcome | PARTIAL |
| TR-2013 E2 PC2.5 | Respond to unplanned events | No current branching activity | DRAFT-ELC724334-PC2.5 | None | Controlled unexpected event and response evidence | MISSING |
| TR-2013 E3 PC3.1 | Use appropriate PPE during diagnosis | No explicit current activity | DRAFT-ELC724334-PC3.1 | None | Safety-critical PPE action | MISSING |
| TR-2013 E3 PC3.2 | Diagnose faults to requirements/SOP | COC4 / C4M1 + C4M3 + C4M4 | DRAFT-ELC724334-PC3.2 | Multiple-choice symptom/cause/diagnosis answers | Chronological tests, observations, isolation reasoning, and approved scenario ground truth | PARTIAL |
| TR-2013 E3 PC3.3 | Implement contingency measures | No current activity | DRAFT-ELC724334-PC3.3 | None | Contingency decision/actions and result | MISSING |
| TR-2013 E3 PC3.4 | Respond to unplanned events | No current branching activity | DRAFT-ELC724334-PC3.4 | None | Controlled event and response evidence | MISSING |
| TR-2013 E4 PC4.1 | Use appropriate PPE during correction | No explicit current activity | DRAFT-ELC724334-PC4.1 | None | Safety-critical PPE action | MISSING |
| TR-2013 E4 PC4.2 | Correct/replace defect without collateral damage | COC4 / C4M5 repair selection | DRAFT-ELC724334-PC4.2 | Selected repair answer only | Performed correction and post-action inspection evidence | PARTIAL |
| TR-2013 E4 PC4.3 | Make necessary adjustments to procedure | COC4 / C4M5 partial | DRAFT-ELC724334-PC4.3 | No adjustment execution evidence | Adjustment actions and measured result | MISSING |
| TR-2013 E4 PC4.4 | Respond to unplanned events | No current branching activity | DRAFT-ELC724334-PC4.4 | None | Controlled event and response evidence | MISSING |
| TR-2013 E5 PC5.1 | Inspect final work against manual | COC4 / C4M5 partial | DRAFT-ELC724334-PC5.1 | Completion/answer only | Manual/version, inspection actions, observations | PARTIAL |
| TR-2013 E5 PC5.2 | Test for safe operation | COC4 / C4M2 + C4M5 partial | DRAFT-ELC724334-PC5.2 | No measured post-repair test result | Safety test actions and observable result | MISSING |
| TR-2013 E5 PC5.3 | Follow OHS and 5S | COC4 / C4M2 partial | DRAFT-ELC724334-PC5.3 | Limited sequence; no housekeeping record | Observable safety/5S completion | PARTIAL |
| TR-2013 E5 PC5.4 | Leave worksite clean and safe | No current activity | DRAFT-ELC724334-PC5.4 | None | Cleanup actions and final-state evidence | MISSING |
| TR-2013 E5 PC5.5 | Dispose excess under WEEE/3Rs | No current activity | DRAFT-ELC724334-PC5.5 | None | Disposal action and policy evidence | MISSING |
| TR-2013 E5 PC5.6 | Prepare required report | COC4 / C4M5 title/objective only | DRAFT-ELC724334-PC5.6 | No report artifact | Completed service report and instructor review | MISSING |

## Qualification-level requirements and system consequence

| Official requirement | ByteQuest consequence | Status |
|---|---|---|
| NC II requires competence in all prescribed units | ByteQuest must not infer the qualification from a local percentage or from completion of selected missions | TESDA_OFFICIAL_APPROVED / REQUIRES_POLICY_DECISION for ByteQuest aggregation |
| Each COC maps to one core unit in the TR/circular | The four existing COC labels and official unit codes are confirmed | TESDA_OFFICIAL_APPROVED |
| Assessment methods include practical demonstration/observation with oral questioning plus assessor-selected supporting methods | Automated simulation may contribute evidence but cannot silently replace the approved assessment package or assessor decision | TESDA_OFFICIAL_APPROVED / REQUIRES_POLICY_DECISION for simulation substitution |
| Assessment may occur in a simulated environment | The platform is a valid candidate environment only after scenario fidelity and collected evidence satisfy the selected method | TESDA_OFFICIAL_APPROVED / PARTIAL |
| Critical aspects must be demonstrated | A mission title or quiz answer is insufficient; evidence must show the required work | PARTIAL |

## Activation decision

The official source is active and all 20 ByteQuest mission packages are published with approved, versioned, all-required rubrics. Official source facts are `TESDA_OFFICIAL_APPROVED`; controlled scenario values and simulation substitutions are `PROJECT_APPROVED_OPERATIONAL_RULE`. No numeric TESDA cutoff or weight is active. The packages are defensible supplementary assessments, while official certification and physical evidence outside the simulation remain outside ByteQuest authority.

