# ByteQuest Dro Integration Verification Matrix

Validated on 2026-09-08 from the production learner routing code on
`integrate-dro`. This matrix records automated coverage, not physical-device or
production-credential QA.

Each `PASS` row includes these gates:

- **R** — the authoritative mission ID resolves through `MissionLauncher` to
  `MissionSimulationScreen`, with no ambiguous fallback.
- **L** — the routed runtime loads its scenario and renders every phase through
  a concrete interaction widget.
- **P** — the technical interaction reaches terminal state only after its
  required action; incorrect/incompatible actions retain technical feedback.
- **E** — structured evidence is queued, persisted before transport,
  acknowledged, and de-duplicated.
- **S** — phase, configuration, connection, order, and evidence state restore
  without premature submission.
- **V** — evidence review and explicit submission are reachable; pending or
  failed evidence blocks submission.
- **A** — the client emits evidence only and does not create an official score,
  pass/fail result, competency, XP, or reward.

| Mission | Production route | R | L | P | E | S | V | A |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| coc1_m1 | MissionSimulationScreen | PASS | PASS | PASS | PASS | PASS | PASS | PASS |
| coc1_m2 | MissionSimulationScreen | PASS | PASS | PASS | PASS | PASS | PASS | PASS |
| coc1_m3 | MissionSimulationScreen | PASS | PASS | PASS | PASS | PASS | PASS | PASS |
| coc1_m4 | MissionSimulationScreen | PASS | PASS | PASS | PASS | PASS | PASS | PASS |
| coc1_m5 | MissionSimulationScreen | PASS | PASS | PASS | PASS | PASS | PASS | PASS |
| coc2_m1 | MissionSimulationScreen | PASS | PASS | PASS | PASS | PASS | PASS | PASS |
| coc2_m2 | MissionSimulationScreen | PASS | PASS | PASS | PASS | PASS | PASS | PASS |
| coc2_m3 | MissionSimulationScreen | PASS | PASS | PASS | PASS | PASS | PASS | PASS |
| coc2_m4 | MissionSimulationScreen | PASS | PASS | PASS | PASS | PASS | PASS | PASS |
| coc2_m5 | MissionSimulationScreen | PASS | PASS | PASS | PASS | PASS | PASS | PASS |
| coc3_m1 | MissionSimulationScreen | PASS | PASS | PASS | PASS | PASS | PASS | PASS |
| coc3_m2 | MissionSimulationScreen | PASS | PASS | PASS | PASS | PASS | PASS | PASS |
| coc3_m3 | MissionSimulationScreen | PASS | PASS | PASS | PASS | PASS | PASS | PASS |
| coc3_m4 | MissionSimulationScreen | PASS | PASS | PASS | PASS | PASS | PASS | PASS |
| coc3_m5 | MissionSimulationScreen | PASS | PASS | PASS | PASS | PASS | PASS | PASS |
| coc4_m1 | MissionSimulationScreen | PASS | PASS | PASS | PASS | PASS | PASS | PASS |
| coc4_m2 | MissionSimulationScreen | PASS | PASS | PASS | PASS | PASS | PASS | PASS |
| coc4_m3 | MissionSimulationScreen | PASS | PASS | PASS | PASS | PASS | PASS | PASS |
| coc4_m4 | MissionSimulationScreen | PASS | PASS | PASS | PASS | PASS | PASS | PASS |
| coc4_m5 | MissionSimulationScreen | PASS | PASS | PASS | PASS | PASS | PASS | PASS |

The explicit server payload routes are intentionally separate: the
`authoritative_mission_v1` template opens
`AuthoritativeMissionAssessmentScreen`, and COC2 M2's
`coc2_cable_termination` template opens
`Coc2CableTerminationAssessmentScreen`. Their evidence is submitted to the
database evaluator and results remain hidden until Instructor release.

Automated evidence: `mission_launcher_test.dart`,
`mission_catalog_acceptance_test.dart`, `mission_simulation_screen_test.dart`,
`mission_phase_completion_policy_test.dart`,
`mission_runtime_controller_test.dart`, `mission_evidence_gateway_test.dart`,
`authoritative_mission_contract_test.dart`, and the accessibility interaction
matrix. The complete post-hardening Flutter suite passed 235 tests at the
pre-commit validation gate.
