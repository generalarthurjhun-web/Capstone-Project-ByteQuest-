# Admin Web Dashboard Destination Audit

Date: 2026-08-12

The Admin navigation is guarded by `requireStaffProfile(["admin"])` on the server for all Admin-specific destinations. The authenticated route smoke suite creates disposable Admin/Instructor/Learner sessions and verifies that Admin pages render while cross-role requests are redirected or denied.

| Destination | Route | Status | Real data / workflow | Authorization evidence |
|---|---|---|---|---|
| Overview | `/admin/dashboard` | COMPLETE | Live profiles, classes, TESDA sources, resources, and audit events | Admin server guard; route smoke PASS |
| Users | `/users` | COMPLETE | Live `profiles`; links to account lifecycle workflows | Admin guard and Admin API/RPC boundaries |
| Instructors | `/instructors` | COMPLETE | Live Instructor profiles joined to owned classes and active memberships | Admin guard; account links remain Admin-governed |
| Learners | `/learners` | COMPLETE | Live Learner profiles and historical/active class memberships | Admin guard; history-preserving account workflows |
| Access & Scope | `/admin/access-scope` | COMPLETE | Live class ownership, active memberships, and class-scoped resources | Admin guard; scope is derived from trusted class ownership |
| TESDA Sources | `/tesda-sources` | COMPLETE | Live `tesda_sources` registry, approval, activation, and provenance | Admin guard; existing source governance RPCs |
| Resource Governance | `/admin/resources` | COMPLETE | Live private resource metadata, lifecycle state, class, owner, MIME, and storage totals | Admin guard; private Storage remains governed by existing policies |
| System Analytics | `/admin/analytics` | COMPLETE | Live `get_admin_system_analytics` aggregates and audit activity | Admin guard; RPC is Admin-scoped |
| System Reports | `/admin/reports` | COMPLETE | Live period-scoped system activity, COC usage, accounts, resource, and audit summary | Admin guard; no Instructor assessment finalization controls |
| Audit Logs | `/logs` | COMPLETE | Live append-only `audit_events` with actor role/outcome | Admin guard; audit rows are read-only |
| Security | `/admin/security` | COMPLETE | Live account posture and non-success audit outcomes, with links to audit controls | Admin guard; RLS/RPC enforcement remains trusted backend behavior |
| Profile | `/profile` | COMPLETE | Authenticated profile and password management | Shared authenticated profile flow; Admin role preserved |
| Settings | `/settings` | COMPLETE | Live `system_settings` with Admin-only governance RPC | Admin guard; changes are audited and validation-protected |

## Verification

- `pnpm exec tsc --noEmit` â€” PASS
- `pnpm lint` â€” PASS
- `pnpm build` â€” PASS
- `pnpm test:analytics` â€” 4/4 PASS
- `node --env-file=.env.local scripts/authenticated-server-route-smoke.mjs` â€” PASS, including all Admin destinations, cross-role denial, resource scope/storage checks, Admin account safeguards, and cleanup
- Responsive behavior is inherited from the shared DashboardLayout, responsive sidebar drawer, table overflow treatment, MetricStrip grid, and shared loading/error/empty patterns.

## Scope note

There is no separate unrestricted ACL table in the current schema. Access & Scope truthfully reports the existing authorization model: Instructor-owned active classes define instructional scope; class memberships and class-attached resources remain historical and class-scoped. No new permission shortcut or destructive migration was introduced.

