# ByteQuest Web Analytics and Reporting Implementation

**Implementation date:** 2026-08-11; visual refinement pass 2026-08-12 (Asia/Manila)  
**Scope:** Instructor Analytics, Instructor Reports, Admin System Analytics, and shared Web shell refinement  
**Data policy:** authoritative Supabase/PostgreSQL records only

## 1. Architecture

The implementation uses one read-only aggregation path:

```text
Supabase Auth identity
  -> role/object-scope check inside PostgreSQL
  -> parameterized SECURITY DEFINER analytics RPC
  -> Next.js server component/server route
  -> Zod-validated typed payload
  -> Recharts visualization and accessible HTML table/list
```

No assessment decision moved into React. The analytics functions do not create or modify attempts, scores, revisions, releases, progress, rewards, or audits.

Repository migration: `supabase/migrations/20260811120000_scoped_analytics_and_reporting.sql`  
Live migration: `scoped_analytics_and_reporting`  
Live migration state after application: 33 migrations (29 repository migrations plus four documented historical live-only migrations).

## 2. Data Sources

Instructor analytics aggregates the existing authoritative relationships across:

- `classes` and `class_memberships` for ownership and learner scope;
- `assignments`, `activity_versions`, `activities`, `missions`, `coc_modules`, and `modules` for assigned content identity;
- `attempts` for workflow, history, and retry activity;
- `criterion_results` and `rubric_criteria` for criterion outcomes and provenance;
- `score_revisions` and `result_releases` for final/released result state;
- `learner_progress` for learner x COC progress;
- `profiles` for scoped learner names;
- `learning_resources` and `audit_events` for Admin operational metrics.

Gamification is not presented as competency. Percentage displays are explicitly labeled criterion-satisfaction aggregates, calculated as satisfied evaluated criteria divided by evaluated criteria. They are not labeled as TESDA scores.

## 3. Analytics Queries

`public.get_instructor_analytics(p_class_id, p_coc_id, p_mission_id, p_from, p_to)` returns one normalized JSON payload containing:

- filter catalogs;
- summary counts;
- daily submitted/released/satisfied-criterion trend;
- COC performance;
- mission performance;
- criterion outcome/provenance statistics;
- learner intervention signals;
- workflow-state distribution;
- retry signals;
- learner x COC progress;
- assessment history;
- current released results.

The date range is bounded to 366 days. A supplied class must be owned by the authenticated Instructor. The function uses fixed `search_path = ''` and fully qualified objects.

`public.get_admin_system_analytics(p_from, p_to)` returns platform-level account, class, assessment, release, resource, audit, trend, and COC usage data. It requires an active Admin and does not expose routine Instructor assessment mutation.

## 4. Reporting Queries

Reports call the same Instructor analytics RPC and reuse the same filters. `prepareReport` converts that single normalized payload into a structured report. This prevents dashboard/report count drift caused by separate client-side formulas.

Supported report types:

1. Class Performance
2. Learner Performance
3. COC Competency
4. Mission Assessment
5. Criterion Analysis
6. Assessment History
7. Intervention
8. Released Results

## 5. Instructor Analytics

`/analytics` provides class, COC, mission, period, and custom-date filters; four high-value summary metrics; submitted/released/criterion-evidence trends; assessment workflow distribution; COC comparison; mission drilldown; criterion provenance; affected learner/attempt drilldown; retry signals; learner progress; and links to the real attempt review route.

## 6. Admin Analytics

`/admin/analytics` is independent from Instructor Analytics. It provides active account/class counts, assessment/release volume, learning-resource/storage volume, system activity trends, account states, COC usage, and recent audit activity. It does not include routine score-finalization controls.

## 7. Charts Implemented

- Responsive line charts for Instructor class activity and Admin platform activity.
- Horizontal workflow-state bar chart.
- COC criterion-satisfaction bar chart.
- Admin COC usage bar chart.
- Ranked mission and retry lists where a chart would reduce readability.

The existing Recharts dependency is reused; no competing chart library was installed. Charts use restrained semantic colors, subtle grids, concise axes, tooltips, and data-adaptive empty states.

## 8. Drilldown Flows

```text
All scoped analytics
  -> COC
  -> Mission
  -> Criterion
  -> Affected learners
  -> Authoritative attempt/evidence review
```

COC, mission, criterion, period, and class context use URL search parameters. Context breadcrumbs and clear actions allow returning to broader analysis.

## 9. Filters

Supported filters are owned class, COC, mission, 7/30/90 days, and a custom date range up to 366 days. Changes update metrics, charts, tables, intervention rows, and reports. Invalid UUID/date input is discarded or reset before reaching PostgreSQL.

## 10. Reports

`/reports` contains a report-type selector, shared Instructor scope filters, preview, empty state, and export actions. Dense tables use deliberate horizontal overflow rather than compressing critical columns into unusable mobile widths.

## 11. Exports

- **CSV:** authenticated server route `/api/reports/export`; same RPC/filters as preview, UTF-8 BOM, correct escaping, `private, no-store`, and `nosniff`.
- **PDF:** print-optimized report sheet with browser `Print / Save PDF`. No large PDF dependency was added. Route/build verification passes; visual PDF artifact inspection remains browser acceptance work because no browser surface was connected.

## 12. RLS and Permissions

The Instructor RPC requires an active Instructor, derives identity from `auth.uid()`, scopes all records to Instructor-owned classes, and rejects cross-Instructor, Learner, Admin, and anonymous callers. The Admin RPC requires an active Admin. Report pages/exports independently require an active Instructor at the Next.js boundary. CSV returns 401 for anonymous and 403 for Learner/Admin callers.

## 13. UI Redesign

The shell now uses concise role-specific navigation, compact branding, a responsive desktop/mobile sidebar, persistent search/user top bar, keyboard skip link, consistent page headers/metric strips/section headings, restrained surfaces, and print-safe reports. Instructor and Admin navigation remain distinct.

The 2026-08-12 visual refinement pass keeps the existing ByteQuest blue language while adopting a warmer off-white application canvas, individual white KPI cards with a 4/2/1 responsive grid, compact 12px labels, prominent 24â€“28px values, consistent semantic icon containers, quiet borders, and low ambient depth. Analytics layouts use a deliberate approximately 2:1 primary-chart-to-secondary-chart rhythm, while resource and Admin surfaces reuse the same shared card treatment without changing their data contracts.

## 14. Animation and Motion

Motion is limited to functional hover/focus/selection transitions and chart data entrance. `prefers-reduced-motion: reduce` disables CSS motion and the charts disable Recharts animation through `useReducedMotion`.

## 15. Accessibility

- Semantic headings and tables.
- Accessible chart names/descriptions.
- Expandable Instructor trend table.
- Keyboard-operable COC list equivalent to the chart drilldown.
- Admin trend screen-reader summary and textual COC usage list.
- Non-color status/intervention labels.
- Focus-visible states and reduced-motion support.

## 16. Responsive Behavior

Metrics reorganize from one to two to four columns; chart/operational layouts stack; sidebar becomes a mobile sheet; filters reorganize; tables scroll only where their density genuinely requires it; and main containers use `min-w-0` plus bounded widths.

Static responsive/accessibility inspection, route rendering, type validation, and production build pass. The six key routes (`/login`, `/instructor/dashboard`, `/admin/dashboard`, `/analytics`, `/reports`, `/resources`) returned HTTP 200 from the local Next.js server after the visual pass. Screenshot QA at 390/768/1024/1440 remains unrecorded because no browser surface was connected.

## 17. Tests

Passed:

- `pnpm test:analytics`: 4/4.
- Impeccable layout/type detector: zero findings on shared dashboard, layout, analytics, chart, and global style files.
- `pnpm test:openrouter`: 6/6 contract tests.
- TypeScript, Next.js lint, and production build.
- Authenticated analytics/RBAC boundary.
- Authenticated analytics/report/server routes.
- COC2 lifecycle: 14/14 groups.
- All mission COC1-COC4 lifecycle suites.
- Instructor quiz governance: 11/11 groups.
- Impeccable static detector: zero findings.

The current `openrouter/free` live retry returned malformed provider output and failed closed with no question saved. Manual quiz creation and provider validation remain functional; a previous live provider lifecycle passed.

## 18. Performance Findings

- PostgreSQL aggregates data; the browser does not calculate from an unbounded raw history.
- Detailed history/release rows cap at 500 and dates cap at 366 days.
- Existing Recharts is reused and limited to analytics routes.
- Two support indexes cover current release timestamps and criterion/evaluation timestamps.
- Supabase reports both new indexes as unused INFO findings because the observed test workload is small/short-lived; retain until representative query statistics exist.
- No `DUMMY_*`, `MOCK_*`, `Math.random`, or hard-coded production chart dataset exists under `src`.

## 19. Remaining Limitations

1. Browser screenshot/console/responsive QA is unrecorded because the Browser runtime reported no connected surfaces.
2. Browser-native PDF output was not visually inspected as an artifact; authenticated CSV is verified.
3. `openrouter/free` may return schema-invalid content; the route fails closed and preserves manual creation.
4. Supabase intentionally warns that authenticated users can execute the two SECURITY DEFINER analytics RPCs. Both use fixed search paths, enforce role/object scope internally, and passed negative tests.
5. Leaked-password protection remains an existing plan/configuration recommendation.

## Appendix A. Web UI Inventory Decision

| Area | Decision | Result |
|---|---|---|
| Login/profile | KEEP | Existing Supabase authentication and account lifecycle preserved. |
| Instructor overview | REFINE | Attention-first metrics, class list, recent real attempts, Analytics/Classes actions. |
| Admin overview | REFINE | Governance-first metrics, audit activity, TESDA status, system analytics action. |
| Classes/class detail | KEEP + SHARED SHELL | Existing class, enrollment, assignment, resource, and monitoring workflows preserved. |
| Learners/progress | KEEP + SHARED SHELL | Existing scoped learner progress/drilldown retained. |
| Assignments/modules | KEEP + SHARED SHELL | Existing versioned assignment/content workflows retained. |
| Attempts/review | KEEP + SHARED SHELL | Existing evidence/revision/finalization/release workflow retained. |
| Quizzes/AI workspace | KEEP + SHARED SHELL | Existing Instructor draft/review/publish/OpenRouter workflow retained. |
| Resources | KEEP + SHARED SHELL | Existing private Storage workflow retained. |
| Instructor Analytics | REDESIGN | Full real-data overview and COC/mission/criterion/learner drilldown. |
| Reports | REDESIGN | Eight previewable report types with scoped CSV and print/PDF. |
| Admin System Analytics | NEW WITHIN EXISTING ADMIN | Separate account/activity/resource/audit analytics. |
| Users/TESDA sources/audit/settings | KEEP + SHARED SHELL | Existing governance routes preserved with normalized navigation and layout. |

No working page or route was removed.

