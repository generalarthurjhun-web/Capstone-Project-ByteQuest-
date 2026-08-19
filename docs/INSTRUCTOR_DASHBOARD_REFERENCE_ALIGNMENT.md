# Instructor Dashboard Reference Alignment

Date: 2026-08-12

## Scope

The supplied Instructor dashboard references were used as a visual and information-architecture target. Existing ByteQuest routes and trusted Supabase data remain the source of truth; illustrative values in the references were not copied into production UI.

## Implemented surfaces

| Reference area | ByteQuest route | Current data | Alignment |
| --- | --- | --- | --- |
| Instructor overview | `/instructor/dashboard` | Owned classes, active memberships, attempts, review states, assignments, instructor-final revisions | Overview now has scoped KPI cards, review queue, class workload, recent attempts, and upcoming due dates. |
| Classes | `/classes` | Classes owned by the authenticated Instructor and active class memberships | KPI summary added for total/active classes, active learners, and other class states; roster remains real and actionable. |
| Class details | `/classes/[id]` | Membership history, assignments, published activities/rubrics, bypasses, private resources | KPI summary now links to the existing tabbed class workspace. Existing enrollment, assignment, resource, bypass, and settings workflows are preserved. |
| Learners | `/progress` and `/progress/learners/[userId]` | Scoped attempt/release and learner profile records | Existing monitoring and drilldown remain the source for learner progress and released results. |
| Assignments & Modules | `/modules`, class assignment tab | Versioned activities, rubrics, assignments, retry/prerequisite configuration | Existing versioned assignment workflow is retained; unsupported calendar/schedule claims are not fabricated. |
| Reviews & Results | `/attempts`, `/attempts/[id]` | Attempts, ordered evidence, criterion results, revisions, finalization and release | Attempt list now exposes truthful queue metrics; detail remains the authoritative review workflow. |
| Quizzes | `/quizzes`, `/quizzes/[id]` | Quiz/version/item publication and review state | KPI summary added for published versions, drafts, active items, and archived quizzes. AI remains draft-only. |
| Resources | `/resources`, class resources tab | Private learning resources, class scope, storage metadata | Existing resource KPI/library and signed access workflow preserved. |
| Analytics | `/analytics` | Server-side scoped aggregates and drilldowns | Existing real-data analytics dashboard already provides COC, mission, criterion, intervention, and learner matrix views. |
| Reports | `/reports` | Shared analytics aggregates and scoped export/print report | KPI context added above the report builder; filters and exports continue to use the same analytics scope. |

## Truth and scope rules

- All Instructor queries run behind `requireStaffProfile(["instructor"])` and the existing RLS/ownership boundary.
- No reference-only metrics such as average class score, pass rate, attendance, future schedules, or trend percentages were invented where the active schema does not provide them.
- Quiz counts distinguish published versions, draft versions, active questions, and archived records; they do not imply learner completion or competency.
- Assessment results remain criterion/evidence based. A report or KPI never converts gamification into TESDA grading.

## Responsive and accessibility behavior

- Shared `MetricStrip` uses a 1-column compact layout, 2-column tablet layout, and 4-column wide layout.
- KPI cards use semantic links for actionable destinations, visible focus rings, reduced-motion-safe transitions, and truthful zero-state helpers.
- Dense data remains in responsive list/table containers rather than forcing reference-only columns into narrow viewports.

## Validation

- `pnpm exec tsc --noEmit` â€” pass
- `pnpm lint` â€” pass
- `pnpm test:analytics` â€” PASS, 4/4
- `pnpm build` â€” PASS
- Authenticated server-route/RBAC smoke â€” PASS, including all Admin destinations, protected analytics/reports/quiz routes, resource scope, and account safeguards

