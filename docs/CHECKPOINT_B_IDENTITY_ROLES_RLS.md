# Checkpoint B â€” Identity, Roles, and RLS

Date: 2026-08-08  
Status: implemented and verified

## Outcome

Supabase Auth is now the shared identity authority for the Flutter learner app and the Next.js dashboard. The application roles are `learner`, `instructor`, and `admin`; no live profile uses the retired merged staff role.

The historical enum label was renamed to `legacy_instructor_admin` instead of being dropped because PostgreSQL enum removal is destructive. A database constraint and all trusted role-changing functions reject that compatibility label. It is retained only as a reversible migration boundary.

## Trusted boundaries

- Next.js authentication uses Supabase sessions and server-side profile checks.
- Instructor and Admin routes are separate and reject the wrong staff role.
- Sensitive mutations use scoped SQL RPCs or server routes that verify both actor role and target object.
- Flutter can start an assigned attempt, append ordered evidence, and submit it through RPCs; it cannot write authoritative scores, competency outcomes, releases, or rewards.
- Learners can see only their own released results.
- Instructors are scoped to classes they own and learners enrolled in those classes.
- Admin governance does not replace the Instructor review/finalization workflow.

## Account lifecycle

`profiles` now records deactivation timestamp, reason, and actor. Admin governance RPCs support role changes and account state operations with trusted audit attribution. Instructor learner-deactivation is class-scoped and preserves membership history.

## RLS verification

- 38/38 public tables have RLS enabled.
- 43 policies cover identity, class ownership, membership, content, attempts, results, governance, resources, and audit visibility.
- Live authorization tests verified class isolation, learner score-write denial, instructor workflow scope, released-result visibility, and audit isolation.
- Security advisor result: 0 errors and 34 warnings. Thirty-two warnings identify intentional authenticated `SECURITY DEFINER` RPCs whose implementations independently verify actor role and object scope. Remaining project-setting/dependency items are documented in Checkpoint F.

## Migration

Primary migration files:

- `20260807085500_add_deactivated_account_status.sql`
- `20260807090000_foundation_identity_and_audit.sql`
- `20260807101000_admin_governance_rpcs.sql`
- `20260807102000_authoritative_rls.sql`
- `20260807104000_fix_rls_policy_recursion.sql`
- `20260808110000_retire_merged_staff_role.sql`

## Remaining gate

The generated TypeScript database type exposes `legacy_instructor_admin` because it reflects the physical enum. Application types, role guards, constraints, and RPCs do not accept it as an operational role.

