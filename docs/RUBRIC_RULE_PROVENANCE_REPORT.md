# Rubric and Rule Provenance Report

**Prepared:** 2026-08-10  
**Decision:** Official non-numeric TESDA requirements are approved for provenance; all 20 project-owner-directed ByteQuest mission packages are activated with evidence-based all-required criteria and without a numeric TESDA threshold.

## Provenance classes

- **A â€” Official TESDA requirement:** explicitly supported by the accepted official source. The official source may be non-numeric.
- **B â€” Institutional / instructor-approved operational rule:** a local rule needed to operationalize a scenario, evidence checklist, or review process. It must be signed off and must never be presented as TESDAâ€™s own numeric rule.
- **C â€” System/gamification rule:** motivational or technical behavior that cannot affect competency.
- **D â€” Legacy/unverified rule:** provenance is absent or superseded; official activation is forbidden.

## Active COC2 operational package

| Rule ID | Current value | Source / provenance | Classification | Activation |
|---|---|---|---|---|
| `COC2-ALL-REQUIRED` | Every one of nine required criteria must be `SATISFIED` for the provisional outcome `competent` | Project-owner approval; official criteria traced individually below | `PROJECT_APPROVED_OPERATIONAL_RULE` | ACTIVE |
| `COC2-CABLE-01-PPE-OHS` | Exact prepared PPE set | TR ELC724332 PC 1.4 and official COC2 SAG; simulation set selected by project | Official basis `TESDA_OFFICIAL_APPROVED`; evidence representation `PROJECT_APPROVED_OPERATIONAL_RULE` | ACTIVE |
| `COC2-CABLE-02-TOOLS-MATERIALS` | Exact required material/tool/tester set | TR PCs 1.2â€“1.3 | Official basis approved; operational inventory approved | ACTIVE |
| `COC2-CABLE-03-CABLE-PREPARATION` | Exact chronological preparation sequence | TR PC 1.5 / Evidence Guide skills | Official outcome approved; simulated sequence project-approved | ACTIVE |
| `COC2-CABLE-04-T568B-ORDER` | Exact chronological T568B conductor sequence | TR PC 1.5; official SAG names 568A/568B | Official standards obligation approved; selected scenario/order project-approved | ACTIVE |
| `COC2-CABLE-05-TERMINATION` | Exact insertion/depth/crimp sequence | TR PC 1.5 | Official outcome approved; simulated sequence project-approved | ACTIVE |
| `COC2-CABLE-06-TESTER-USE` | Exact connect/power/observe sequence | TR PCs 1.3, 1.7, 4.2 | Official testing/safety obligation approved; event contract project-approved | ACTIVE |
| `COC2-CABLE-07-TESTER-RESULT` | Final observed tester result is `pass` for the controlled activity | TR PCs 1.7, 2.1, 4.2 / Evidence Guide | Official tested outcome approved; simulator vocabulary project-approved | ACTIVE |
| `COC2-CABLE-08-PHYSICAL-INSPECTION` | Exact required inspection set | TR PCs 1.7, 4.1 | Official inspection approved; checklist project-approved | ACTIVE |
| `COC2-CABLE-09-5S-CLEANUP` | Exact tools/work-area/scrap completion set | TR PCs 1.8â€“1.9; official SAG 5S/3Rs | Official obligation approved; checklist project-approved | ACTIVE |
| `COC2-TECHNICAL-BINARY-ENCODING` | Satisfied=`1`, not satisfied=`0`; count only | Required by current deterministic evaluator storage, not a passing formula | `PROJECT_APPROVED_OPERATIONAL_RULE`; explicitly not TESDA weighting | ACTIVE |

The stored percentage is a technical ratio of satisfied criteria for compatibility/projection. It does not control the `all_required` outcome and must not be presented as an official TESDA percentage.

## Official non-numeric requirements

| Rule ID | Current value / meaning | Used by | Source and section | Approved by | Classification | Activation status |
|---|---|---|---|---|---|---|
| `TESDA-QUAL-ALL-UNITS` | Competence in all prescribed units is required for the NC | Qualification decision design only; no active ByteQuest aggregation rule | TR Section 4.1, printed p.63 | Official TESDA source; project auto-approval policy | A | `TESDA_OFFICIAL_APPROVED` |
| `TESDA-COC-1` | Install and Configure Computer Systems | COC1/module trace | TR pp.38-41, unit `ELC724331`; Section 4.2.1.1; Circular 18-2015 | Official TESDA source; project auto-approval policy | A | `TESDA_OFFICIAL_APPROVED` |
| `TESDA-COC-2` | Set-up Computer Networks | COC2/module trace | TR pp.42-45, unit `ELC724332`; Section 4.2.1.2; Circular 18-2015 | Official TESDA source; project auto-approval policy | A | `TESDA_OFFICIAL_APPROVED` |
| `TESDA-COC-3` | Set-up Computer Servers | COC3/module trace | TR pp.46-48, unit `ELC724333`; Section 4.2.1.3; Circular 18-2015 | Official TESDA source; project auto-approval policy | A | `TESDA_OFFICIAL_APPROVED` |
| `TESDA-COC-4` | Maintain and Repair Computer Systems and Networks | COC4/module trace | TR pp.49-53, unit `ELC724334`; Section 4.2.1.4; Circular 18-2015 | Official TESDA source; project auto-approval policy | A | `TESDA_OFFICIAL_APPROVED` |
| `TESDA-CRITICAL-ASPECTS` | Candidate must demonstrate each unit's critical outcomes | Future rubric scope; not proof that a current mission is sufficient | TR Evidence Guide Â§1 for each core unit; 2021 SAG starred items | Official TESDA source; project auto-approval policy | A | `TESDA_OFFICIAL_APPROVED`; ByteQuest evidence remains partial |
| `TESDA-METHOD-C1` | Assessor may select any two listed methods, including practical demonstration with oral questioning | COC1 assessment-plan constraint | ELC724331 Evidence Guide Â§4, printed p.41 | Official TESDA source; project auto-approval policy | A | `TESDA_OFFICIAL_APPROVED`; method selection requires policy |
| `TESDA-METHOD-C2` | Assessor may select any two listed methods | COC2 assessment-plan constraint | ELC724332 Evidence Guide Â§4, printed p.45 | Official TESDA source; project auto-approval policy | A | `TESDA_OFFICIAL_APPROVED`; method selection requires policy |
| `TESDA-METHOD-C3` | Assessor may select any two listed methods | COC3 assessment-plan constraint | ELC724333 Evidence Guide Â§4, printed p.48 | Official TESDA source; project auto-approval policy | A | `TESDA_OFFICIAL_APPROVED`; method selection requires policy |
| `TESDA-METHOD-C4` | Assessor must select two listed methods | COC4 assessment-plan constraint | ELC724334 Evidence Guide Â§4, printed p.53 | Official TESDA source; project auto-approval policy | A | `TESDA_OFFICIAL_APPROVED`; method selection requires policy |
| `TESDA-SIMULATED-CONTEXT` | Assessment may be conducted in a simulated environment | Platform suitability | Each core unit Evidence Guide Â§6, printed pp.41, 45, 48, 53 | Official TESDA source; project auto-approval policy | A | `TESDA_OFFICIAL_APPROVED`; simulation fidelity remains partial |

Official-source verification found **no** numeric passing percentage, weighted score formula, safety percentage, time bonus, accuracy threshold, attempt limit, retry cooldown, XP amount, or points amount.

## Current authoritative evaluator capabilities

| Rule ID | Current value | Used by | Source / provenance | Approved by | Classification | Activation status |
|---|---|---|---|---|---|---|
| `ENGINE-ACTION-EXISTS` | Evidence operator `action_exists` | PostgreSQL evaluator | Technical evaluator capability; migration `20260808112000_close_lifecycle_review_gaps.sql` | No operational rubric yet | B/technical | Available but no production criterion configured |
| `ENGINE-EXACT-SEQUENCE` | Evidence operator `exact_target_sequence` | PostgreSQL evaluator | Technical evaluator capability; rollback test proves `B â†’ A` fails expected `A â†’ B` | No mission sequence approved | B/technical | Available but no production criterion configured |
| `ENGINE-FINAL-VALUE` | Evidence operator `final_action_value_equals` | PostgreSQL evaluator | Technical evaluator capability | No operational rubric yet | B/technical | Available but no production criterion configured |
| `ENGINE-BINARY-SUM` | Binary criterion values summed | PostgreSQL evaluator | Technical scoring mechanism | No operational rubric yet | B/technical | Available but no production rubric configured |
| `ENGINE-ALL-REQUIRED` | Outcome depends on all required criteria | PostgreSQL evaluator | Technical mechanism consistent with non-numeric competency decisions, but exact required set is unresolved | Adviser/CSS instructor not yet signed | B | `REQUIRES_POLICY_DECISION` |
| `ENGINE-MIN-PERCENT` | Explicit `minimum_percentage` only if stored in an approved rubric | PostgreSQL evaluator | Optional technical mechanism; no official numeric source found | Nobody | B | **Must remain unconfigured** unless institution supplies and labels a local rule |

The live authoritative tables `tesda_sources`, `module_versions`, `activity_versions`, `rubric_versions`, and `rubric_criteria` still contain zero rows. Source provenance approval in this report does not silently create an Admin/audit actor or make any engine capability an official competency decision.

## Legacy and local numeric values

| Rule ID | Current value | Used by | Source / page/section | Approved by | Classification | Activation status |
|---|---|---|---|---|---|---|
| `LEGACY-MISSION-PASS` | `75` | 20 live legacy `missions.passing_score` rows; preserved historical records | No approved source found | Unknown | D | Quarantined; never use for authoritative assessment |
| `LEGACY-ACCURACY-WEIGHT` | `0.40`, max `40` | Each of 20 missions in legacy `assessment_criteria` | No approved source found | Unknown | D | Quarantined |
| `LEGACY-COMPLETION-WEIGHT` | `0.25`, max `25` | Each legacy mission | No approved source found | Unknown | D | Quarantined |
| `LEGACY-SEQUENCE-WEIGHT` | `0.20`, max `20` | Each legacy mission | No approved source found | Unknown | D | Quarantined |
| `LEGACY-TIME-WEIGHT` | `0.15`, max `15` | Each legacy mission | No approved source found | Unknown | D | Quarantined |
| `LEGACY-RATING-BANDS` | Historical `90/80/75/60` bands | Former `get_rating(integer)` behavior | No approved TESDA source | Unknown | D | Function now service-role-only and fails closed; retained only as quarantine history |
| `LEGACY-MISSION-XP` | `100` or `150` | Legacy mission rows | No approved product rule supplied | Unknown | C/D | Not authoritative; mobile catalog uses zero |
| `LEGACY-MISSION-POINTS` | `100` | Legacy mission rows | No approved product rule supplied | Unknown | C/D | Not authoritative; mobile catalog uses zero |
| `MOBILE-PRACTICE-ACCURACY` | `(correct / total) Ã— 100` | Local result presentation in identification, drag/drop, form, sequence, and troubleshooting templates | Client practice feedback, not TESDA | Project implementation | C | Allowed only as clearly labeled practice feedback; never submitted as authoritative score |
| `MOBILE-PASSING-SCORE` | `0` for all 20 local missions | Practice catalog model | Deliberate quarantine change | Project implementation | C/technical safeguard | Active safeguard; not a competency threshold |
| `MOBILE-XP-REWARD` | `0` for all 20 local missions | Practice catalog | Deliberate quarantine change | Project implementation | C/technical safeguard | Active safeguard |
| `RELEASE-XP` | `0` | Transactional release event | Migration explicitly marks configuration pending | Project implementation | C | Active safeguard; exactly-once zero event |
| `RELEASE-POINTS` | `0` | Transactional release event | Migration explicitly marks configuration pending | Project implementation | C | Active safeguard; exactly-once zero event |

## Scenario-specific values requiring institutional provenance

| Rule ID | Current value | Used by | Source | Approved by | Classification | Activation status |
|---|---|---|---|---|---|---|
| `SCENARIO-C1M4-FIRMWARE-OS` | Controlled firmware, boot-media, install, and final-state contract | `coc1_m4` published package | TESDA PC basis plus versioned ByteQuest scenario | Project owner, 2026-08-10 continuation | B | `PROJECT_APPROVED_OPERATIONAL_RULE`; active |
| `SCENARIO-C1M5-DRIVER-TEST` | Controlled driver/application/update/test workflow | `coc1_m5` published package | TESDA PC basis plus versioned ByteQuest scenario | Project owner, 2026-08-10 continuation | B | `PROJECT_APPROVED_OPERATIONAL_RULE`; active |
| `SCENARIO-C2M2-T568B` | One exact T568B termination/testing scenario | `coc2_m2` published package | 568A/568B concept in official TR/SAG; scenario selects T568B | Project owner, explicit approval | B | `PROJECT_APPROVED_OPERATIONAL_RULE`; active |
| `SCENARIO-C2M5-IP` | Controlled small-LAN design with explicit client/router values | `coc2_m5` published package | TESDA configuration/verification basis plus versioned design | Project owner, 2026-08-10 continuation | B | `PROJECT_APPROVED_OPERATIONAL_RULE`; active; values are not universal TESDA rules |
| `SCENARIO-C3M2-SERVER-WORKFLOW` | Controlled network-server installation/preparation sequence | `coc3_m2` published package | TESDA server operation basis plus vendor-neutral scenario | Project owner, 2026-08-10 continuation | B | `PROJECT_APPROVED_OPERATIONAL_RULE`; active |
| `SCENARIO-C3M3-NETWORK` | Controlled server NIC/service/connectivity design | `coc3_m3` published package | TESDA server configuration basis plus versioned design | Project owner, 2026-08-10 continuation | B | `PROJECT_APPROVED_OPERATIONAL_RULE`; active |
| `SCENARIO-C3M4-ACCESS` | Controlled account/share/permission policy with positive and negative tests | `coc3_m4` published package | TESDA access/security basis plus versioned local policy | Project owner, 2026-08-10 continuation | B | `PROJECT_APPROVED_OPERATIONAL_RULE`; active |
| `SCENARIO-C4M2-MAINTENANCE` | Controlled preventive-maintenance safety, sequence, test, and cleanup checklist | `coc4_m2` published package | TESDA maintenance/OHS/5S/3Rs basis plus simulation contract | Project owner, 2026-08-10 continuation | B | `PROJECT_APPROVED_OPERATIONAL_RULE`; active |
| `ALL-MISSION-SCENARIO-CONTRACTS` | Hidden expected selections, configurations, matches, observations, and exact sequences for the 20 versioned scenarios | All approved rubric versions | Official PC basis plus mission-specific simulation operationalization | Project owner, 2026-08-10 implementation directive | B | Active; individual provenance is stored in every criterion `source_trace` |

## Safety, time, and competency decision

- No `safetyScore`, safety percentage, or time bonus is active in production code.
- Safety-critical behavior should be modeled as explicitly required criteria or blocking observations only after the CSS instructor approves the checklist and failure policy.
- Time may be preserved as factual attempt evidence. It must not become a competency weight or bonus without a documented institutional source.
- A learnerâ€™s local practice percentage is not a competency score.
- COC bypass only unlocks practice access and cannot create a pass, criterion result, score revision, progress award, XP, or points.

## Active operationalization controls

All 20 published packages record the immutable source version, official unit/PC interpretation, simulation-specific evidence contract, chronological and safety requirements, deterministic automated observations, all-required decision method, and Instructor accountability. Expected answers stay server-side. Every package is versioned so future content changes create a new activity/rubric version rather than rewriting historical attempts.

The following remain deliberately unconfigured because neither TESDA nor the project directive supplied them: numeric passing percentage, criterion weights, safety percentage, time bonus, arbitrary attempt limit/cooldown, non-zero XP/points, and qualification-level certification aggregation. Those remain `REQUIRES_POLICY_DECISION` or zero-value safeguards and cannot affect competency.

