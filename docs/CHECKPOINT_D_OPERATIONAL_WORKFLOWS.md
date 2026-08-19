# Checkpoint D â€” Instructor and Admin Operational Workflows

Date: 2026-08-08  
Status: implemented against real Supabase data

## Instructor workflow

The Instructor dashboard now provides real, class-scoped operations:

- create and view owned classes;
- enroll or deactivate learners while preserving membership history;
- assign published activity/rubric versions;
- view related attempts and chronological evidence;
- review automated criterion results;
- add justified score revisions;
- finalize and release results;
- grant an audited access-only COC bypass;
- view class progress and released-result analytics.

All mutations call scoped database functions. UI route checks are supplemental; RLS/RPC authorization remains authoritative.

## Admin workflow

The Admin dashboard now provides real system-governance operations:

- create Instructor or learner accounts through a server-only Admin route;
- change roles within the supported role set;
- deactivate and restore accounts with reasons;
- inspect system-wide account, audit, and aggregate data;
- register, approve, and activate versioned TESDA sources;
- manage trusted global settings.

Admin does not silently perform the Instructor's ordinary finalization/release workflow.

## Web data state

- Firebase packages, configuration, browser CRUD, mock authentication, and localStorage session flags were removed from production code.
- Dummy/random learners, results, analytics, reports, and CSV-import behavior were removed or replaced by real scoped queries/explicit redirects.
- Obsolete placeholder CRUD routes redirect to the implemented modules, analytics, or users workflows instead of presenting fabricated state.
- Report export is generated from released authoritative revisions, not client-authored legacy scores.

## Proven workflow

`supabase/tests/foundation_lifecycle_rollback.sql` exercised the full database lifecycle inside a transaction and rolled back every fixture. It verified class isolation, enrollment, assignment, operational access-only bypass, idempotent start/evidence/submission, deactivated-membership write denial, database-derived provisional evaluation, superseded-source completion, protected scoring, Instructor finalization, release, append-only revisions, exactly-once gamification, and audit visibility.

## Production readiness gate

The mechanics are operational, but a real production assessment cannot be published until the approved TESDA source/rubric is confirmed. This is a deliberate fail-closed control rather than a missing mock value.

