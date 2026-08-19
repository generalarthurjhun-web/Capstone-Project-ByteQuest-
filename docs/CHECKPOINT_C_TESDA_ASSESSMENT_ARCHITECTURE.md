# Checkpoint C â€” TESDA and Assessment Architecture

Date: 2026-08-08  
Architecture status: implemented  
Policy activation status: **TESDA SOURCE REQUIRES HUMAN CONFIRMATION**

## TESDA source decision

Official TESDA Training Regulations and Self-Assessment Guides were reviewed and hashed. They support the four-unit/COC structure, but the reviewed documents do not provide a project-ready numeric passing percentage, weighting formula, safety percentage, COC score, or gamification rule.

No source or rubric is active in production. Existing values such as 75%, legacy criterion weights, and rating bands are classified as `UNVERIFIED_LEGACY_VALUE`. The legacy `get_rating(integer)` function now fails closed with `PENDING_TESDA_VALIDATION`.

See `docs/TESDA_SOURCE_VALIDATION_STATUS.md` for exact official references, versions, and hashes.

## Versioned source and content model

The additive schema establishes immutable traceability:

```text
tesda_sources
  -> module_versions
      -> activity_versions
          -> rubric_versions
              -> rubric_criteria
```

Completed attempts retain their module, activity, rubric, and source version references. Admin activation records approval actor and time; source history is not overwritten.

## Authoritative lifecycle

```text
assignment -> attempt -> ordered attempt_actions
           -> trusted criterion_results
           -> provisional score_revision
           -> instructor review/justified revision
           -> finalized revision -> result_release
           -> learner visibility and idempotent gamification event
```

The database owns attempt identity, ordered evidence, submission state, rule evaluation, revision numbering, finalization, release, and idempotency. Learner clients never submit a final score, pass flag, competency decision, XP, badge, or leaderboard value.

The production database evaluator accepts only an attempt ID. It reads ordered `attempt_actions` and the immutable Admin-approved rubric contract, derives criterion observations and binary values inside PostgreSQL, applies the approved `all_required` or explicitly configured `minimum_percentage` decision method, and appends the provisional revision in the same submission transaction. Supported evidence operators are `action_exists`, `exact_target_sequence`, and `final_action_value_equals`. Approval rejects unsupported or pending rules; no policy value is supplied by application code.

## Evidence and review

- Evidence uses an attempt ID plus chronological sequence number.
- Replaying the same client start, evidence sequence, submission, release, or reward event is idempotent.
- Criterion results preserve expected rules, observed evidence, result, values, and remarks.
- Score revisions are append-only and retain actor, role, reason, prior/current values, affected criteria, and source/rubric version.
- Instructor adjustment requires a reason; finalization and release are separate audited transitions.
- COC bypass unlocks access only and does not confer a score, competency, XP, points, or reward.
- Historical attempts captured against a source may finish evaluation after that source becomes `superseded`; new attempts still require the active source.

## Activation gate

Before official assessment publication, an authorized human must confirm the accepted TESDA/source package and any separate official assessor/rating instrument. Until then, local simulations are practice and the database contains zero active TESDA sources and zero approved real rubrics.

