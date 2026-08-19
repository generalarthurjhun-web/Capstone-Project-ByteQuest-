# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Users

- Learners use the Flutter mobile app to access assigned CSS NC II learning resources, practice missions, simulations, assessments, released results, progress, and motivational gamification.
- Instructors use the Next.js dashboard to manage their own classes, learners, assignments, resources, attempt evidence, criterion review, finalization, release, and intervention analytics.
- Admins use a separate Next.js governance area for accounts, roles, access state, TESDA source versions, audit visibility, and safeguarded system operations.

## Product Purpose

ByteQuest is a supplementary gamified simulation and evidence-review platform for Computer Systems Servicing NC II. It connects learner actions in mobile simulations to authoritative PostgreSQL evaluation, Instructor accountability, released results, and real class analytics. Success means the same authenticated identity and versioned evidence record is trustworthy across Mobile, Web, and Supabase.

## Positioning

ByteQuest combines chronological simulation evidence with criterion-level database evaluation and an append-only Instructor review lifecycle. Gamification remains motivational and cannot determine competency.

## Operating Context

The product is used in classroom, laboratory, independent-practice, assessment-review, capstone-demonstration, and defense settings. The first approved operational reference assessment is COC2 / Set-up Computer Networks â€” Cable Termination and Testing. Official TESDA source material, local project-approved operational decisions, and system gamification rules must remain visibly distinct.

## Capabilities and Constraints

- Supabase Auth and PostgreSQL are the shared identity and data authority.
- Roles are `learner`, `instructor`, and `admin`; Instructor and Admin capabilities are never merged.
- Mobile may record ordered evidence but cannot authoritatively set final score, competency, criterion decisions, rewards, role, or release state.
- PostgreSQL evaluates approved criterion contracts. Instructor finalization and release remain separate audited actions.
- Completed attempts, criterion results, score revisions, result releases, progress, and audit history are preserved.
- Private learning resources are class scoped and use validated Supabase Storage workflows.
- ByteQuest does not issue TESDA certification, replace official TESDA assessment, or imply TESDA endorsement.
- Unsupported TESDA numeric thresholds, weights, time bonuses, retry limits, XP, and leaderboard rules must not be invented.

## Brand Commitments

The confirmed product name is ByteQuest. Its voice is clear, accountable, encouraging, and technically precise. The interface should feel modern, premium, clean, minimal, professional, accessible, and engaging without becoming childish, noisy, or decorative at the expense of the learner task.

## Evidence on Hand

- Approved PRD, objectives, scope, panel recommendations, gap analysis, implementation reports, and acceptance matrices in the repository root and `docs/`.
- Verified official TESDA Training Regulations and SAG artifacts under `docs/reference/tesda_sources/`, with hashes and provenance documented in `docs/TESDA_SOURCE_VALIDATION_STATUS.md`.
- A live versioned COC2 source/module/activity/rubric chain and archived authenticated UAT evidence in Supabase.
- Existing Flutter simulations, Next.js role dashboards, database migrations, RLS policies, RPCs, test suites, and runtime harnesses.
- No testimonials, external endorsement claims, or official TESDA certification authority should be fabricated.

## Product Principles

1. Evidence before appearance: identity, scope, versioning, and assessment authority stay trustworthy through every interface change.
2. Workspace first: simulation and assessment review prioritize the task and evidence over decoration.
3. Clear state and accountability: provisional, final, released, practice, and assessment states are explicit and auditable.
4. Professional restraint: hierarchy, spacing, feedback, and accessibility create engagement without visual noise.
5. One system: Flutter, Next.js, Supabase, TESDA provenance, and analytics communicate a single coherent product.

## Accessibility & Inclusion

Support Android TalkBack semantics, keyboard navigation on Web, meaningful focus states, text scaling, 48dp mobile touch targets, accessible contrast, reduced motion, landscape/full-screen simulation use, zoom, and a select-item/select-destination alternative to drag interactions. Correct/incorrect state must never rely on color alone.

