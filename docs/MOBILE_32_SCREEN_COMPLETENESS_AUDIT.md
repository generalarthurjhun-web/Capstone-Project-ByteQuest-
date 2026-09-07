# ByteQuest Mobile â€” 32-Screen Learner Completeness Audit

Audit date: 2026-08-12  
Scope: `ByteQuest-Mobile-App/lib` and the current Supabase-backed learner workflow.

## Status definitions

- **COMPLETE** â€” reachable in the learner app, backed by the current data/workflow, and has truthful loading/empty/error behavior.
- **PARTIAL** â€” a usable surface exists, but one or more requested capabilities are not yet backed by the authoritative workflow.
- **MISSING** â€” no learner route or supported data contract exists.
- **DUPLICATE/CONSOLIDATED** â€” the capability is intentionally embedded in an existing parent experience rather than creating another top-level destination.

## Audit matrix

| # | Required screen | Current route/file | Status | Real data / authorization | Main gap or evidence | Action |
|---:|---|---|---|---|---|---|
| 1 | Splash | `/` â†’ `screens/splash/splash_screen.dart` | COMPLETE | Supabase session + active-profile check | Branding and initialization state are present. | Retain; active-account guard verified. |
| 2 | Login | `/login` â†’ `screens/auth/login_screen.dart` | COMPLETE | Supabase Auth | Secure learner sign-in and error state exist. | Retain. |
| 3 | Forgot Password | `/forgot-password` â†’ `screens/auth/forgot_password_screen.dart` | COMPLETE | Supabase password reset | Real recovery flow exists. | Retain. |
| 4 | Onboarding | `/onboarding` â†’ `screens/onboarding/onboarding_screen.dart` | COMPLETE | Local explanatory content | No account/data mutation. | Retain; typography uses shared scale. |
| 5 | Home / learner dashboard | `/dashboard` â†’ `screens/dashboard/dashboard_screen.dart` | COMPLETE | Profile, assignments, released results, attempt counts, notifications | Truthful empty/error/loading states exist. | Retain. |
| 6 | My Classes | Learn â†’ Classes tab â†’ `screens/missions/missions_screen.dart` | COMPLETE (consolidated) | Classes are derived only from authorized assignments/resources | No separate top-level tab is necessary. | Added class-detail navigation. |
| 7 | Class Details | `screens/missions/class_details_screen.dart` | COMPLETE | Filtered authorized assignments/resources by `class_id` | New detail surface reuses existing records and launcher. | Implemented and linked from Classes. |
| 8 | Learning Path / COC Overview | `screens/courses/courses_screen.dart` | COMPLETE | Live `get_learner_learning_path()` projection combines published COCs/missions with own active enrollment, assignment policy, attempts, current releases, and active bypasses | No client unlock threshold or invented TESDA score remains. The displayed ratio is explicitly Instructor-released missions / published missions. | Retain and regression-test. |
| 9 | COC Details | `screens/courses/coc_details_screen.dart` | COMPLETE | The same trusted projection supplies per-mission Assigned, In Progress, Awaiting Instructor, Released, scheduled/prerequisite/retry, bypass-practice, and practice-only states | Practice remains launchable without pretending it is authoritative; assigned assessments remain in the assigned-work flow. | Retain and regression-test. |
| 10 | Mission Details / Briefing | `screens/missions/mission_detail_screen.dart` | COMPLETE | Published/local mission scenario content | Clearly labeled practice briefing and Instructor-release notice. | Retain. |
| 11 | 2D Simulation Workspace | `screens/simulation/*_mission_screen.dart` | COMPLETE | Mission templates and authoritative action service where assigned | Workspace, zoom/full-screen, responsive interaction exist. | Retain. |
| 12 | Mission Step / Evidence Interaction | `screens/simulation/templates/*` | COMPLETE | All 20 published authoritative packages use the trusted action contract; selection, matching, ordering, configuration, troubleshooting/observation, testing, drag, and accessible alternatives record ordered evidence | Retained local variants are explicitly practice-only and are not misrepresented as assessment evidence. | Retain shared evidence semantics and regression coverage. |
| 13 | Mission Pause / Resume | `AuthoritativeAssessmentService` + both authoritative assessment templates | PARTIAL | The persisted start key resumes the same server attempt; templates reload ordered `attempt_actions`, reconstruct the first incomplete stage, and preserve elapsed time after process restart | Code and server idempotency are verified, but a human kill/relaunch walkthrough on an authenticated Android target is not yet recorded. | Record the device process-termination acceptance case before marking COMPLETE. |
| 14 | Mission Submission Review | `screens/simulation/result_screen.dart` | PARTIAL | Both authoritative engines now open an explicit evidence timeline/review and confirmation surface before calling `submit_attempt` | The flow no longer auto-submits on navigation; automated widget/regression checks pass, but authenticated device interaction evidence is still outstanding. | Record one generic mission and COC2 M2 review/return/confirm journey. |
| 15 | Assessment Processing | `screens/simulation/result_screen.dart` | COMPLETE | `submit_attempt` RPC and idempotent submission | Clear processing/retry state. | Retain. |
| 16 | Provisional Result | `result_screen.dart` + `AuthoritativeAssessmentService` | COMPLETE | PostgreSQL provisional revision; learner cannot author it | Explicitly says result is not final/released. | Retain. |
| 17 | Released Final Result | `screens/progress/progress_screen.dart` | COMPLETE | `result_releases` and current score revision | Released-only RLS/query behavior is represented. | Retain. |
| 18 | Criterion Feedback | Progress result expansion | COMPLETE | `criterion_results` linked to rubric criteria | Criterion status uses real observations. | Retain; no invented feedback. |
| 19 | Attempt History | `screens/progress/attempt_history_screen.dart` | COMPLETE | Learner-scoped `attempts` query | New timeline distinguishes in-progress, provisional, and released. | Implemented and linked from Progress. |
| 20 | Practice Mode | Learn â†’ Practice tab + bypass assignments | COMPLETE | Local practice and `get_bypassed_activities` access-only records | Practice never creates competency/reward authority. | Retain. |
| 21 | Quizzes list | Learn header â†’ `screens/quizzes/learner_quizzes_screen.dart` | COMPLETE | Live `get_available_learner_quizzes()` scopes active enrollment to assigned published versions | Expanded authenticated run `quiz-learner-e2e-20260812112705-3c180f51` proved an authorized assignment is listed while a learner in another class sees none; drafts remain hidden. | Retain and regression-test. |
| 22 | Quiz Taking | `screens/quizzes/quiz_details_screen.dart` â†’ `quiz_taking_screen.dart` | COMPLETE | Live idempotent start/resume, trusted answer upsert, exact-once PostgreSQL submission, and no learner answer-key field | The live run restored the same attempt and saved answers after leave/resume, rejected post-submit mutation, and produced one result after duplicate submission. All four configured types have widget coverage. | Retain and regression-test. |
| 23 | Quiz Result | `screens/quizzes/quiz_result_screen.dart` | COMPLETE | Live own-attempt result RPC returns stored correctness counts without answer keys or Instructor-only review data | Own-result retrieval passed; cross-learner and anonymous retrieval were denied. The UI remains explicitly supplementary and does not claim TESDA competency. | Retain and regression-test. |
| 24 | Learning Resources | Learn â†’ Files tab | COMPLETE | Private `learning_resources` query filtered by RLS | Authorized resources are listed with truthful empty/error states. | Retain. |
| 25 | Resource Viewer | `screens/resources/resource_viewer_screen.dart` + `LearningResourceService` | COMPLETE | Private signed Supabase Storage URL created only after the learner can read authorized resource metadata | Added a ByteQuest in-app viewer shell with image preview, text/JSON/XML preview, PDF/video authorized-open prompts, unsupported-file handling, loading, retry, and error states. PDF/video still use the device/browser viewer through signed URLs because no embedded PDF/video dependency is approved. | Retain private signed access; add embedded PDF/video playback later only if an approved dependency is selected. |
| 26 | My Progress | `screens/progress/progress_screen.dart` | COMPLETE | Trusted COC/mission lifecycle projection, own attempt states, current Instructor releases, and released criterion results | Expandable COC â†’ mission state and released mission â†’ criterion feedback use real scoped data only; no client score or invented percentage. | Retain and regression-test. |
| 27 | Achievements | `/achievements` â†’ `screens/achievements/achievements_screen.dart` | COMPLETE | Own `user_achievements` joined to the real achievement definition under existing scoped RLS | Dedicated loading/error/refresh and truthful no-earned-achievements state; no configured or unearned badge is fabricated. | Retain; add richer art only from approved stored assets. |
| 28 | Rewards / Gamification | `/dashboard` â†’ Rewards (`leaderboard_screen.dart`) | COMPLETE (consolidated) | Truthful unavailable state until approved server configuration | Never invents XP, rank, or competency. | Retain. |
| 29 | Activity / Recent Progress | Attempt History | COMPLETE (consolidated) | Learner-scoped attempt timeline | Recent activity is represented by real attempts/status dates. | Retain; expand when quiz/resource events exist. |
| 30 | Notifications | `/notifications` â†’ `notifications_screen.dart` | COMPLETE | Real `notifications` rows and read state under RLS | No fake notifications are generated. | Retain. |
| 31 | Profile | `/profile` â†’ `screens/profile/profile_screen.dart` | COMPLETE | ProfileService + authenticated user | Real identity and motivational counters are displayed. | Retain. |
| 32 | Settings | `/settings` â†’ `screens/settings/settings_screen.dart` | COMPLETE | Notification and sound preferences load/upsert the authenticated learner's own `user_settings` row under RLS; security/profile/logout routes are real; reduced motion follows the platform | Removed the former no-op Theme and Language controls. Live harness proves persistence, cross-learner isolation, and anonymous denial. | Retain and regression-test. |

## Final counts

- **Reviewed:** 32 / 32
- **Complete:** 30
- **Partial:** 2
- **Missing:** 0
- **Duplicate/consolidated capabilities:** 3 (My Classes, Rewards, Activity/Recent Progress)

Consolidation is intentional and does not represent duplicate routes: the learner shell keeps four task-first destinations (`Home`, `Learn`, `Progress`, `Rewards`) and opens detail experiences on the navigation stack.

## Typography implementation

`core/theme/app_theme.dart` is now the single typography authority. Plus Jakarta Sans remains the existing approved mobile face, with a Tarsi-inspired compact hierarchy:

- Display: 32 / 28 / 24px, bold
- Headings: 22 / 20 / 18px, semibold-bold
- Titles: 17 / 16 / 14px, semibold
- Body: 16 / 15 / 14px, regular
- Labels/metadata: 14 / 13 / 12 / 11px

The complete Material `TextTheme` now maps to these roles. Shared stat, badge, button, progress, instruction, and navigation widgets consume the roles rather than creating separate font families or arbitrary role sizes. Flutter text scaling remains enabled.

## Verification evidence

- Existing authoritative tests cover contract validation, ordered evidence, idempotency, COC2 assessment behavior, drag accessibility, and design-system constraints.
- Added coverage for the centralized typography role scale.
- `flutter test`: PASS â€” 39 tests, including all four learner quiz item types, answer-key omission, and the new private resource viewer states.
- `flutter analyze --no-fatal-infos`: PASS â€” exit 0 with 215 informational legacy lint/deprecation notices and no fatal analyzer finding.
- `flutter build apk --debug`: PASS â€” `ByteQuest-Mobile-App/build/app/outputs/flutter-apk/app-debug.apk`.
- The new class-details and attempt-history surfaces use existing Supabase/RLS boundaries and do not add client-authoritative scoring.
- Class-detail activities resolve against the existing local mission catalog before starting an attempt; Instructor-bypassed activities reuse the practice launcher and never create an authoritative attempt.

## Remaining P0/P1 work

The learner quiz P0 is complete. The trusted learning-path projection feeds real COC/mission state and released criterion analytics into Progress. Settings now persists only supported values under own-row RLS, and Achievements lists only actually earned rows. The private resource viewer now has an in-app ByteQuest viewer surface with secure signed access and truthful fallbacks. Cross-process authoritative resume and submission review are implemented but remain PARTIAL pending a recorded authenticated device kill/relaunch and review/confirm walkthrough.

## Final acceptance rerun â€” 2026-08-13

- The final automated regression remains green: `flutter test` **39 tests
  passed**, `flutter analyze --no-fatal-infos` **exit 0** with 215
  informational legacy notices, and `flutter build apk --debug` **passed**.
- Screens 1â€“12 and 15â€“32 remain complete from the latest code and live
  backend evidence. Screens 13 (Mission Pause/Resume) and 14 (Mission
  Submission Review) remain **PARTIAL** only because the requested
  authenticated Android process-kill/relaunch and evidence-review walkthrough
  has not been run on a connected target.
- `adb devices` was verified with no attached emulator or physical device; no
  emulator was launched in this acceptance pass. The missing device evidence
  is not treated as a functional failure.

## Functional and Realtime stabilization addendum â€” 2026-08-14

- Added the learner Realtime coordinator with an authenticated JWT, scoped
  table subscriptions, domain-level invalidation, debounced authoritative
  refetch, and deterministic channel cleanup.
- Dashboard, Learn/Classes, Quizzes, Quiz Result, Progress, Attempt History,
  Notifications, and Achievements now refresh when their RLS-visible backend
  state changes. Realtime payloads never become scoring/result authority.
- Live disposable-user tests passed for authorized class/assignment updates,
  quiz assignment and submission, mission submission, released results, and
  private resource metadata. Cross-learner payload delivery was denied.
- Unsupported legacy XP/level/streak/completion counters were removed from
  Profile and Settings. Rewards remains a truthful unavailable state when no
  approved server configuration exists.
- The final non-device regression remains green: Flutter tests **39/39**,
  analyzer exit **0** with **214 information-only** findings, and debug APK
  build **PASS**.

The final count remains **30 COMPLETE / 2 PARTIAL / 0 MISSING**. Screens 13
and 14 are not upgraded without the explicitly required authenticated Android
process-kill and submission-review interaction evidence.


