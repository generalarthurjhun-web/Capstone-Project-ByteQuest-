# ByteQuest Final Capstone Acceptance Walkthrough

This walkthrough is the deterministic human acceptance script for the current
ByteQuest release candidate. It uses disposable accounts and the live,
versioned Supabase workflow. It does not require live AI generation.

## Test identities and evidence fields

Use one active disposable Admin, one active Instructor, Learner A, and (for
negative checks) Learner B. Record IDs only; never record passwords, service
role keys, OpenRouter keys, access tokens, or signed URLs.

| Field | Value |
|---|---|
| Run ID | ______________________________ |
| Admin user ID | ______________________________ |
| Instructor user ID | ______________________________ |
| Learner A user ID | ______________________________ |
| Learner B user ID | ______________________________ |
| Class ID | ______________________________ |
| COC / mission | ______________________________ |
| Activity version | ______________________________ |
| Rubric version | ______________________________ |
| Attempt ID | ______________________________ |
| Quiz assignment / attempt | ______________________________ |
| Resource ID | ______________________________ |
| Start time / end time | ______________________________ |

## Acceptance procedure

| # | Step | Expected result | Actual result / evidence | Status |
|---:|---|---|---|---|
| 1 | Launch Mobile | Splash initializes and restores/clears the Supabase session safely. | __________________ | PASS / FAIL |
| 2 | Learner login | Learner authenticates through Supabase; no staff route is shown. | __________________ | PASS / FAIL |
| 3 | Home and Learn | Assigned class, learning path, resources, and pending work use real scoped data. | __________________ | PASS / FAIL |
| 4 | Start authoritative mission | One active attempt is created with the expected activity/rubric version. | __________________ | PASS / FAIL |
| 5 | Record evidence | Multiple meaningful actions are stored in chronological order; count and IDs are recorded. | __________________ | PASS / FAIL |
| 6 | Pause | Leaving the workspace does not submit or evaluate the attempt. | __________________ | PASS / FAIL |
| 7 | Process termination | Force-stop/background-close the app, relaunch, and restore the same active attempt. | __________________ | PASS / FAIL / BLOCKED |
| 8 | Resume | The first incomplete stage and prior evidence are restored without a duplicate attempt. | __________________ | PASS / FAIL |
| 9 | Submission review | Ordered evidence is visible; Return/Edit does not submit; Confirm requires explicit action. | __________________ | PASS / FAIL / BLOCKED |
| 10 | Submit | Processing state appears and duplicate submission remains idempotent. | __________________ | PASS / FAIL |
| 11 | Provisional result | Learner sees a clearly labelled automated/provisional state, not an Instructor-final result. | __________________ | PASS / FAIL |
| 12 | Instructor review | Owning Instructor sees only authorized learner/class evidence, version provenance, and criterion results. | __________________ | PASS / FAIL |
| 13 | Adjustment (optional) | Any adjustment requires a reason and appends a revision; prior history remains visible. | __________________ | PASS / FAIL / N/A |
| 14 | Finalize and release | Only the authorized Instructor can finalize/release; unauthorized roles are denied. | __________________ | PASS / FAIL |
| 15 | Learner final result | Released result and criterion feedback appear in Mobile and remain distinct from provisional state. | __________________ | PASS / FAIL |
| 16 | Analytics/reporting | The same attempt appears in Instructor analytics, drilldown, and scoped report/export values. | __________________ | PASS / FAIL |
| 17 | Quiz publish/assign | Instructor publishes an immutable version and assigns it to the owned class. | __________________ | PASS / FAIL |
| 18 | Quiz learner flow | Authorized learner lists, starts, answers, leaves, resumes, reviews, and submits once. | __________________ | PASS / FAIL / BLOCKED |
| 19 | Quiz security | Draft/unpublished items and answer keys are hidden; cross-learner and anonymous access fail. | __________________ | PASS / FAIL |
| 20 | Resource flow | Instructor uploads private resource; authorized learner previews/opens it through signed access. | __________________ | PASS / FAIL |
| 21 | Resource denial | Archived, unsupported, anonymous, and wrong-class access fail safely without exposing storage paths. | __________________ | PASS / FAIL |
| 22 | Practice/bypass | Practice or bypass unlocks access only; no competency, released result, progress, XP, or reward is created. | __________________ | PASS / FAIL |
| 23 | Admin governance | Admin account/scope/audit safeguards work; Admin is not an ordinary assessment finalizer. | __________________ | PASS / FAIL |
| 24 | Cleanup | Disposable fixtures are removed through the prepared harness; production history is preserved. | __________________ | PASS / FAIL |

## Web visual and accessibility pass

Run the authenticated Web dashboard at 390px, 768px, 1024px, 1440px+, and
1920px where available. Inspect Login, Instructor Overview, Classes, Learners,
Assessment Review, Quizzes, Resources, Analytics, Reports, Admin Overview,
Users, TESDA Sources, Audit Logs, Security, Profile, and Settings.

| Check | Result / evidence | Status |
|---|---|---|
| Sidebar grouping, active state, and mobile drawer | __________________ | PASS / FAIL / BLOCKED |
| Immediate client navigation and route transitions | __________________ | PASS / FAIL / BLOCKED |
| Loading, empty, error, and unauthorized states | __________________ | PASS / FAIL / BLOCKED |
| Console: React/hydration/404/request errors | __________________ | PASS / FAIL / BLOCKED |
| Keyboard focus and semantic labels | __________________ | PASS / FAIL / BLOCKED |
| Charts/tables/filters at all target widths | __________________ | PASS / FAIL / BLOCKED |

## Android visual and accessibility pass

Use a compact phone, normal phone, landscape/full-screen simulation, and large
text. If TalkBack is available, verify the main navigation, mission controls,
accessible alternatives, quiz questions, results, resources, and Settings.

| Check | Result / evidence | Status |
|---|---|---|
| Safe areas, bottom navigation, and keyboard behavior | __________________ | PASS / FAIL / BLOCKED |
| Simulation alignment, zoom, full-screen, and touch targets | __________________ | PASS / FAIL / BLOCKED |
| Large text and reduced-motion behavior | __________________ | PASS / FAIL / BLOCKED |
| TalkBack semantics and non-color feedback | __________________ | PASS / FAIL / BLOCKED |

## Sign-off

| Area | Decision | Evidence reference |
|---|---|---|
| Objective 1 â€” 2D simulation | COMPLETE / PARTIAL / FAIL | __________________ |
| Objective 2 â€” Gamification | COMPLETE / PARTIAL / FAIL | __________________ |
| Objective 3 â€” CSS NC II modules | COMPLETE / PARTIAL / FAIL | __________________ |
| Objective 4 â€” Automated evaluation | COMPLETE / PARTIAL / FAIL | __________________ |
| Objective 5 â€” Performance analytics | COMPLETE / PARTIAL / FAIL | __________________ |
| Deployment recommendation | READY / CONDITIONAL / NOT READY | __________________ |
| Reviewer / date | ______________________________ | __________________ |

## Current environment evidence (2026-08-13)

- `adb devices`: no attached Android emulator or physical device. Android
  process-kill/resume, authenticated submission-review confirmation, TalkBack,
  large-text, and frame-pacing rows remain `BLOCKED` until a target is
  connected.
- Browser connector: unavailable (`No browser is available`). Web screenshot,
  responsive, and console-inspection rows remain `BLOCKED` until a browser
  target is available.
- `supabase db test --linked`: blocked before TAP output because the isolated
  pg_prove role cannot read fixture `public.profiles`. Do not add production
  grants or weaken RLS; use a dedicated test fixture role/path before marking
  this row PASS.
- Android release signing: no `android/key.properties` is configured. Normal
  release packaging fails closed. The explicit
  `BYTEQUEST_ALLOW_DEBUG_SIGNING=true` path is smoke-only and not a defense or
  distribution artifact.

### Continuation note â€” 2026-08-14

- The owner requested that the Android emulator not be launched. The Android
  rows above remain intentionally `BLOCKED`; no runtime evidence was
  fabricated.
- The non-device regression passed: Flutter 39 tests, analyzer exit 0, debug
  APK, TypeScript, ESLint, analytics/OpenRouter tests, and Next.js production
  build.
- The current linked pgTAP attempt is blocked by the stopped Docker Desktop
  engine. The earlier fixture-role `profiles` read limitation remains a second
  test-harness issue after Docker is available.

