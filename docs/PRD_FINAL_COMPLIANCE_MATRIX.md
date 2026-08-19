# Final PRD Compliance Matrix

Re-audit date: 2026-08-10  
Source: `Capstone_PRD_Gamified_CSS_NCII.pdf`, version 1.0, 07 August 2026  
Statuses: `COMPLETE`, `PARTIAL`, `MISSING`, `INCORRECT`, `UNVERIFIED`, `OUT OF SCOPE`

This matrix was rebuilt from the current repository, live Supabase inventory, all-mission authenticated lifecycle tests, original COC2 UAT, production Next SSR/route tests, rollback suites, 24 Flutter tests/build, and current TESDA source review. A route or table alone is not accepted as runtime proof.

## Learner mobile requirements

| ID | Status | Current evidence / gap |
|---|---|---|
| MOB-001 | PARTIAL | Flutter uses Supabase Auth and profile role/status checks; the real login UI rendered. A deactivated disposable learner login was not executed end-to-end. |
| MOB-002 | PARTIAL | Profile, class membership, assignments, Instructor and availability are modeled and queried by mobile; authenticated device rendering is unverified. |
| MOB-003 | COMPLETE | All four official core units map to five versioned published mission activities; lock/availability/progress states and module/mission order are preserved. |
| MOB-004 | PARTIAL | Text scenario briefs exist. Private Storage delivery for PDF/image/video is implemented, but authenticated video scenario runtime is unverified. |
| MOB-005 | COMPLETE | The 20 missions include identification/hotspot, drag-and-drop, configuration, chronological procedures, and troubleshooting/multiple-choice interactions; the mission audit identifies each. |
| MOB-006 | COMPLETE | Generic and enhanced assessment screens suppress permanent target names/outlines; COC1 M2 no longer leaks its exact destination in assessment instructions. |
| MOB-007 | COMPLETE | Bounded pinch zoom plus an explicit 48 dp semantic immersive enter/exit control are implemented across active simulation templates and pass reversible widget tests. |
| MOB-008 | COMPLETE | All 20 packages record mission-relevant ordered action evidence and persist one result for each of 98 required criteria; order-sensitive rules use the actual sequence. |
| MOB-009 | COMPLETE | PostgreSQL deterministically evaluates all 20 approved packages with an all-required outcome; unsupported TESDA percentages and client-computed outcomes are not used. |
| MOB-010 | PARTIAL | Database withholds results until release and mobile distinguishes legacy/practice versus trusted states; authenticated released-result UI was not executed. |
| MOB-011 | COMPLETE | All four batch suites create real released attempts and verify progress plus exactly one gamification event per release; repeated release does not duplicate it. |
| MOB-012 | COMPLETE | Availability timestamps plus nullable attempt limit, retry toggle/delay, and optional prerequisite are enforced by the audited Instructor RPC; null means no institutional limit and all attempts remain preserved. |
| MOB-013 | COMPLETE | Persistent retry identities plus idempotent start/submit/release were tested; no duplicate attempt, criterion, revision, audit, reward, or progress write occurs. |
| MOB-014 | COMPLETE | The shared mission workspace passes widget tests at 320Ã—568, 568Ã—320, and 800Ã—1280, including 1.8Ã— text, matching alternatives, and overflow checks; the debug APK builds. |
| MOB-015 | COMPLETE | No learner AI generation path exists. AI is confined to an Instructor-only, server-side quiz-draft assistant and cannot assess competency or publish content. |

## Instructor requirements

| ID | Status | Current evidence / gap |
|---|---|---|
| INS-001 | COMPLETE | Dedicated Instructor route/navigation and server guard exist; Instructor escalation/Admin operations are rejected by trusted-boundary tests. |
| INS-002 | PARTIAL | Create/view/archive plus class metadata and assignment are implemented; edit/schedule lifecycle was not fully exercised through authenticated browser UI. |
| INS-003 | COMPLETE | Enrollment and reasoned membership deactivation preserve history and are shared with mobile/RLS. |
| INS-004 | COMPLETE | A real authenticated Instructor deactivated an exclusively scoped assigned learner through the trusted RPC with mandatory reason/audit and preserved history; cross-Instructor scope was denied. |
| INS-005 | PARTIAL | One official source and 20 versioned activities/rubrics are active through audited publication RPCs; the full Instructor-authored content CRUD surface is not yet browser-proven. |
| INS-006 | COMPLETE | A real authenticated Instructor uploaded and archived a PDF through the production Next route; authorized signed learner read, class isolation, MIME/size validation, private metadata, audit, and cleanup passed. |
| INS-007 | COMPLETE | All 20 source/module/activity/rubric chains are active with 98 stable criteria; official and project-operational provenance are explicitly separated. |
| INS-008 | COMPLETE | Versioned quiz CRUD, manual authoring, server-only OpenRouter JSON-Schema drafting, approved ByteQuest/TESDA context loading, explicit `AI-generated draft` state, Instructor edit/reject/approve, approved-items-only publication, and audit provenance are implemented and security-tested. Real lifecycle `openrouter-live-20260811041145-3d5f7bb0` passed all 9 groups using `openrouter/free`; AI remains supplementary and has no competency authority. |
| INS-009 | COMPLETE | Class assignment includes audited nullable attempt limits, retry toggle/delay, optional prerequisite with cycle/class checks, and availability; no arbitrary limit is preconfigured. |
| INS-010 | COMPLETE | Scoped, reasoned COC bypass is implemented/tested as practice-only access with audit and no competency/reward. |
| INS-011 | COMPLETE | Each mission batch queries real class/learner/attempt/final records; analytics aggregates real failures by COC â†’ mission â†’ criterion with affected learner and attempt counts. |
| INS-012 | COMPLETE | Attempt detail queries chronological evidence, criterion expected/observed data, and revisions under class scope. |
| INS-013 | COMPLETE | Finalization/adjustment requires reason where changed and appends an immutable final revision. |
| INS-014 | COMPLETE | Release is a separate idempotent Instructor RPC; learners see only released results. |
| INS-015 | COMPLETE | Eight scoped report types cover class, learner, COC, mission, criterion, history, intervention, and released results. Preview and CSV share the same PostgreSQL aggregate; print/PDF uses the scoped preview. Authenticated route and count-consistency tests pass. |
| INS-016 | COMPLETE | Review-pending, not-yet-competent, and repeated criterion-failure drilldowns are calculated from scoped authoritative records and link to the underlying attempt. |
| INS-017 | COMPLETE | Class ownership and enrolled-learner scope are enforced; cross-Instructor class mutation/bypass tests pass. |

## Admin requirements

| ID | Status | Current evidence / gap |
|---|---|---|
| ADM-001 | COMPLETE | Dedicated Admin workspace/guards exist; unauthenticated routes redirect and protected APIs return 403. |
| ADM-002 | COMPLETE | A real authenticated Admin server session provisioned an active disposable Instructor through `/api/admin/users`; Auth/profile UUID, Instructor role, account state, and audited role-change boundary were verified. |
| ADM-003 | COMPLETE | Real disposable Auth removal passed: active/self/wrong-email targets were denied; prior deactivation, exact email, reason, FK readiness, preauthorization audit, deletion, and completion audit were enforced. |
| ADM-004 | PARTIAL | Admin can govern roles and class ownership, but a complete Instructor-scope management workflow is not demonstrated. |
| ADM-005 | PARTIAL | Account state/role repair surfaces exist and audit by design; locked-account/system-availability support was not executed. |
| ADM-006 | PARTIAL | Audited global settings exist; file limits/content-type/report/feature-flag consumers are incomplete. |
| ADM-007 | COMPLETE | One approved official source and 20 versioned activity/rubric packages were published through audited Admin RPCs. Every disposable technical release principal was deactivated/Auth-banned. |
| ADM-008 | PARTIAL | Dedicated Admin system analytics now shows real accounts, classes, assessment/release volume, COC usage, resource/storage usage, trends, and audit activity. External health/availability monitoring remains limited. |
| ADM-009 | COMPLETE | Central audit table/RLS and Admin logs page cover high-impact lifecycle actions; core audit assertions pass. |
| ADM-010 | MISSING | No verified database backup or isolated restore exists; cleanup remains blocked. |
| ADM-011 | MISSING | A complete audited global prohibited/corrupt-content removal workflow was not found. |
| ADM-012 | PARTIAL | Admin system analytics uses a role-checked PostgreSQL aggregate and real account/assessment/resource/audit records; authenticated route checks pass. A separate exportable Admin report builder and visual-browser recording remain incomplete. |
| ADM-013 | COMPLETE | Admin routine finalization is explicitly denied; assessment history is append-only. |
| ADM-014 | PARTIAL | AI provider/model configuration is server-only through deployment environment variables and never exposed to clients. A dedicated Admin configuration/health surface is not implemented. |

## Evaluation requirements

| ID | Status | Current evidence / gap |
|---|---|---|
| EVAL-001 | COMPLETE | All 20 live activities/rubrics and 98 criteria are version-bound by validated FKs; every mission is exercised with correct and incorrect/missing authenticated attempts. |
| EVAL-002 | COMPLETE | Deterministic PostgreSQL operators are repeatably tested. |
| EVAL-003 | COMPLETE | Correct, incorrect, incomplete and exact chronological sequence evidence is represented/tested. |
| EVAL-004 | COMPLETE | Evaluation persists one explainable result per rubric criterion, not only a total. |
| EVAL-005 | COMPLETE | Adjustment/finalization records actor, reason, remarks, affected criterion values, timestamps and prior/new values. |
| EVAL-006 | COMPLETE | Final history is append-only; ordinary users cannot overwrite revisions. |
| EVAL-007 | COMPLETE | Bypass unlocks practice access only and creates no attempt, pass, score, progress or reward. |
| EVAL-008 | COMPLETE | Attempt captures immutable source/module/rubric identities; superseding a source does not break completion. |
| EVAL-009 | COMPLETE | Learner score/finalization/release/bypass/class/role writes are rejected. |
| EVAL-010 | COMPLETE | Legacy practice result, learner dashboard/progress, and all staff dashboard/report surfaces consistently state that ByteQuest is supplementary, non-certifying, and does not replace accredited TESDA assessment. |

## UI requirements

| ID | Status | Current evidence / gap |
|---|---|---|
| UI-001 | COMPLETE | Pinch zoom and an explicit reversible immersive full-screen control are implemented and widget-tested without changing attempt identity/state. |
| UI-002 | COMPLETE | Assessment target outlines/labels are hidden until proximity; practice remains guided and clearly labeled. |
| UI-003 | COMPLETE | Five interaction families are present across the mission set. |
| UI-004 | PARTIAL | Text scenarios work and private video-capable Storage delivery is implemented; authenticated upload/stream runtime is unverified. |
| UI-005 | COMPLETE | Runtime entry screens and simulations prioritize learning controls; no severe decorative/logo obstruction was reproduced. |
| UI-006 | COMPLETE | Practice/assessment, locked/bypassed/completed, evaluated/finalized/released states are explicitly labeled; the incorrect hard-coded Practice badge was fixed. |
| UI-007 | PARTIAL | Keyboard focus, 48 dp targets, semantics, and select-then-place alternatives exist; physical TalkBack and large-text testing remain incomplete. |
| UI-008 | PARTIAL | Reasoned finalization/release forms and state gates reduce accidents; a distinct confirmation/recoverable draft for every high-impact action is not uniformly verified. |

## Shared-service requirements

| ID | Status | Current evidence / gap |
|---|---|---|
| SHR-001 | COMPLETE | Mobile and web use Supabase Auth/project identities; RLS/RPC/server guards enforce role and account state. |
| SHR-002 | PARTIAL | Secure services cover classes/content/attempts/evaluation/results/progress/reports plus authenticated private resource delivery. The full Flutter-to-Web assessment UI journey remains unverified. |
| SHR-003 | COMPLETE | UUID identities, timestamps, FKs and idempotency keys remove ambiguous duplicate entities. |
| SHR-004 | COMPLETE | Attempt, score, audit and membership history are preserved with archive/deactivation/append-only patterns. |
| SHR-005 | COMPLETE | Private bucket, authenticated Instructor upload/archive, enrolled-Learner signed read, wrong-class/anonymous denial, MIME/50 MiB enforcement, audit, and cleanup passed through production server routes. |
| SHR-006 | COMPLETE | Start, actions, submission, provisional evaluation, release and gamification exact-once behavior passes. |
| SHR-007 | COMPLETE | Source/module/activity/rubric versions are immutable and captured by historical attempts. |
| SHR-008 | MISSING | Export exists for reports, but full backup/readability/restore is not verified. |
| SHR-009 | COMPLETE | High-impact lifecycle operations produce trusted actor/action/target audit records. |
| SHR-010 | COMPLETE | Foundation work was incremental; legacy history remains quarantined and no mass rewrite/destructive cleanup occurred. |

## Non-functional requirements

| ID | Status | Current evidence / gap |
|---|---|---|
| NFR-001 | COMPLETE | Backend RBAC/RLS and negative tests cover learner, Instructor, Admin and anonymous boundaries; no known P0 bypass was found. |
| NFR-002 | COMPLETE | Submission/evaluation/finalization/release use transactional RPCs and exact-once constraints. |
| NFR-003 | COMPLETE | Audit records capture trusted actor/time/action/target plus reason/outcome/metadata where relevant. |
| NFR-004 | UNVERIFIED | No deployed campus-network latency/load measurement was performed. |
| NFR-005 | PARTIAL | Retry-safe identities and explicit errors exist; interrupted authenticated mobile submission was not exercised. |
| NFR-006 | PARTIAL | Representative mobile layouts and unauthenticated entry flow are usable; authenticated learner/instructor task usability is unverified. |
| NFR-007 | PARTIAL | Zoom, full-screen, safe areas, contrast/state tokens, target sizing, semantics, and non-drag alternatives exist; physical TalkBack and large-text acceptance remain. |
| NFR-008 | PARTIAL | Next production and Android debug builds pass; deployment-browser matrix and real iOS/physical Android testing were not performed. |
| NFR-009 | PARTIAL | Live-generated TypeScript types, 29 ordered repository migrations (33 live, four documented historical entries), rollback/UAT/analytics harnesses, product/design contracts, and reports exist; informational Flutter lints and future Android toolchain upgrade warnings remain. |
| NFR-010 | COMPLETE | RLS and class/learner scope prevent unauthorized learner-record access in tested paths. |
| NFR-011 | MISSING | Full backup and isolated restore are not verified. |
| NFR-012 | PARTIAL | Audit/debug logs exist; centralized error monitoring/availability observability is limited. |
| NFR-013 | COMPLETE | Published source/content/rubric IDs remain bound to attempts and revisions. |
| NFR-014 | PARTIAL | Database, Flutter, authenticated boundary (23 groups), quiz authoring lifecycle (11 groups), all four mission-batch lifecycles, original COC2 lifecycle, protected Next SSR pages, and production server routes pass; recorded visual browser and authenticated Flutter-device acceptance remain absent. |

## Summary

| Status | Count |
|---|---:|
| COMPLETE | 58 |
| PARTIAL | 25 |
| MISSING | 4 |
| UNVERIFIED | 1 |
| OUT OF SCOPE | 0 |
| INCORRECT | 0 |

The counts cover 88 requirement IDs. The remaining functional acceptance gaps are a recorded human-operated authenticated Flutter + visual browser walkthrough across representative missions and one real server-side AI quiz-draft provider call followed by Instructor approval/publish. Backup/restore, Instructor-scope governance breadth, physical TalkBack/device performance, and observability remain P1/P2; all 20 assessment packages are active and lifecycle-tested.

