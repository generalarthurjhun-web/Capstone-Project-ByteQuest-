# ByteQuest 20-Mission Scorecard

Date: 2026-08-22 (Asia/Manila)

Scores are based on the reviewed mission definitions, interaction/runtime implementation, the 169-test full suite, the 84-test UI gate, and persistence/assessment-boundary regressions. Code-drawn schematic scenes are accepted placeholders. Authenticated device and Supabase lifecycle checks remain externally unverified and are not represented as live passes.

Targets: scenario realism 4, interaction variety 4, technical relevance 4, decision depth 3, scene quality 4, evidence quality 4, accessibility 4, visual polish 4, persistence 5, assessment integrity 5.

| Mission | Scenario | Variety | Technical | Decision | Scene | Evidence | Access | Visual | Persist | Integrity | Status |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| COC1 M1 Hardware Inspection | 4 | 4 | 5 | 4 | 4 | 5 | 5 | 4 | 5 | 5 | Automated acceptance |
| COC1 M2 Controlled Assembly | 5 | 5 | 5 | 4 | 4 | 5 | 5 | 4 | 5 | 5 | Automated acceptance |
| COC1 M3 Installation/Configuration | 5 | 4 | 5 | 4 | 4 | 5 | 5 | 4 | 5 | 5 | Showcase candidate |
| COC1 M4 Peripheral Configuration | 4 | 5 | 5 | 4 | 4 | 5 | 5 | 4 | 5 | 5 | Automated acceptance |
| COC1 M5 Integration Troubleshooting | 5 | 5 | 5 | 5 | 4 | 5 | 5 | 4 | 5 | 5 | Automated acceptance |
| COC2 M1 Cabling Preparation | 4 | 5 | 5 | 4 | 4 | 5 | 5 | 4 | 5 | 5 | Automated acceptance |
| COC2 M2 Reference Cable Mission | 5 | 5 | 5 | 4 | 4 | 5 | 5 | 4 | 5 | 5 | Protected evaluator retained |
| COC2 M3 Topology Construction | 5 | 5 | 5 | 5 | 5 | 5 | 5 | 4 | 5 | 5 | Showcase candidate |
| COC2 M4 Network Configuration | 5 | 4 | 5 | 5 | 4 | 5 | 5 | 4 | 5 | 5 | Automated acceptance |
| COC2 M5 Network Troubleshooting | 5 | 5 | 5 | 5 | 4 | 5 | 5 | 4 | 5 | 5 | Automated acceptance |
| COC3 M1 Server Preparation | 4 | 4 | 5 | 4 | 4 | 5 | 5 | 4 | 5 | 5 | Automated acceptance |
| COC3 M2 Server Installation | 5 | 4 | 5 | 5 | 4 | 5 | 5 | 4 | 5 | 5 | Automated acceptance |
| COC3 M3 Users/Groups/Permissions | 5 | 5 | 5 | 5 | 4 | 5 | 5 | 4 | 5 | 5 | Automated acceptance |
| COC3 M4 Server/Network Services | 5 | 5 | 5 | 5 | 4 | 5 | 5 | 4 | 5 | 5 | Showcase candidate |
| COC3 M5 Server Troubleshooting | 5 | 5 | 5 | 5 | 4 | 5 | 5 | 4 | 5 | 5 | Automated acceptance |
| COC4 M1 Maintenance Inspection | 4 | 4 | 5 | 4 | 4 | 5 | 5 | 4 | 5 | 5 | Automated acceptance |
| COC4 M2 Hardware Diagnosis | 5 | 5 | 5 | 5 | 4 | 5 | 5 | 4 | 5 | 5 | Automated acceptance |
| COC4 M3 Software/Network Diagnosis | 5 | 5 | 5 | 5 | 4 | 5 | 5 | 4 | 5 | 5 | Automated acceptance |
| COC4 M4 Repair/Corrective Action | 5 | 5 | 5 | 5 | 4 | 5 | 5 | 4 | 5 | 5 | Automated acceptance |
| COC4 M5 Final Maintenance Scenario | 5 | 5 | 5 | 5 | 5 | 5 | 5 | 4 | 5 | 5 | Showcase candidate |

## Outcome

- 20/20 definitions meet every numeric acceptance threshold in reviewed automated evidence.
- 20/20 use multiple interaction families; 0 are drag-drop-only.
- 20/20 include a technical decision and observation/test/verification evidence.
- Persistence and integrity score 5/5 because state is mode/attempt scoped, evidence is de-duplicated, invalid restore fails closed, submission is terminal, rejected placement never renders success, and backend evaluation/release authority remains protected.
- Final external acceptance is pending the authenticated emulator and Supabase lifecycle rows documented in `BYTEQUEST_EMULATOR_QA.md` and `BYTEQUEST_SIMULATION_COMPLETION_REPORT.md`.
