# ByteQuest Product Design Direction

<!-- impeccable:design-schema 1 -->

## Experience Goal

ByteQuest should feel like one accountable educational technology product across Flutter and Next.js: calm enough for assessment, engaging enough for practice, and precise enough for Instructor and Admin decisions. The visual system supports evidence and task completion; it never competes with them.

## Shared Visual Language

- Use clean sans-serif typography with a compact, explicit hierarchy. Existing Inter on Web and Plus Jakarta Sans on Mobile are retained because both are highly legible and already integrated.
- Use knowledge blue for navigation and primary action, violet only for a deliberate secondary accent, green for confirmed success, amber for review/warning, and red for destructive or blocked states.
- Use an 8-point spacing rhythm with 4-point micro-spacing, 12â€“16px card radii, one-pixel borders, and low or zero elevation for routine surfaces.
- Prefer section boundaries, typography, and whitespace over decorative gradients or heavy shadows.
- Use one consistent icon family per client. Icons supplement labels; they do not replace essential text.

## Product-Specific Hierarchy

### Learner Mobile

1. Current assignment and state
2. Workspace or learning content
3. Instruction and progress
4. Feedback and recovery action
5. Motivational gamification

Assessment mode removes answer-revealing targets. Practice hints and assessment evidence remain visually distinct.

#### Established Learner Mobile World

The Flutter learner client extends the shared ByteQuest language into a compact, calm gamified learning console. This is an extension of the established product world, not a separate brand: knowledge blue and navy carry navigation, primary actions, and high-value summaries; a cool blue-gray canvas supports crisp white task surfaces; and Plus Jakarta Sans provides the compact learner hierarchy. External learning-app references may inform hierarchy, spacing, progress composition, and interaction rhythm, but never supply copied branding, artwork, copy, or proprietary assets.

- Treat the Flutter `AppTheme` as the source of truth for mobile tokens. Its core learner palette is primary knowledge blue (`#1F5EFF`), deep blue (`#173EA5`), navy (`#0B1F46`), cool canvas (`#F4F7FC` / `#F7F9FD`), crisp white surface (`#FFFFFF`), ink text (`#12213A`), supporting text (`#53627A`), and quiet border (`#E3E8F1`). These mobile values extend rather than replace Web tokens.
- Keep the four persistent learner destinations task-first and in this order: `Home`, `Learn`, `Progress`, and `Rewards`. Preserve destination state when switching between them.
- Home prioritizes the real `Up next` task and current assignment state. Learn organizes authorized work into Tasks, Classes, Practice, and Files. Progress distinguishes pending Instructor review from released results. Rewards remains visibly motivational and separate from competency.
- Simulation is workspace-first. Compress surrounding chrome before compressing instructions, evidence, feedback, or the active task. Full-screen and landscape behavior must preserve the attempt and workspace state.
- Use compact 12â€“20px radii for routine learner surfaces and controls, with the larger end reserved for high-value summary surfaces. Prefer one-pixel borders or low ambient depth; do not stack a strong border and strong shadow on the same surface.
- Keep one clear next action on each high-value surface. Support it with stable loading skeletons, truthful empty/error states, and a nearby recovery action where recovery is possible.
- Newly introduced transitions should feel immediate (typically 180â€“420ms), become zero-duration or otherwise reduce when platform animation reduction is requested, and never delay data or authoritative state changes.

**The Authority Boundary Rule.** Practice feedback may teach; assessment presentation must not reveal answers. Automated/provisional, Instructor-final, released, and rewards states remain explicit and visually separate.

**The Truthful Progress Rule.** Show progress only when backed by real learner, assignment, mission, or released-result data. Never infer percentages from the mere presence of counts, XP, badges, streaks, or completed items.

**The Workspace-First Rule.** In simulations, task space and evidence interaction outrank branding, decorative summaries, and navigation chrome.

### Instructor Web

1. Class and learner scope
2. Pending operational work
3. Attempt identity and version provenance
4. Ordered action evidence
5. Criterion decisions
6. Instructor finalization and release
7. Immutable history and intervention signals

### Admin Web

1. Account/system state
2. Governance action
3. Scope and consequence
4. Required confirmation/reason
5. Audit evidence

Admin and Instructor navigation remain operationally and visually distinct even though both share tokens and components.

## Accessibility Contract

- Minimum 48dp mobile touch targets and visible Web keyboard focus.
- Layouts must remain usable at 320Ã—568 mobile and 390px Web widths.
- Support mobile text scaling, TalkBack semantics, landscape/full-screen simulation, zoom, and the select-item/select-destination alternative.
- Correct, incorrect, provisional, final, and released states use icon + text + color.
- Motion is subtle and removed or reduced when the platform requests reduced motion.
- Loading, empty, error, blocked, and recovery states use plain language and preserve user work.

## Assessment Presentation Rules

- Show `AUTOMATED / PROVISIONAL`, `INSTRUCTOR FINAL`, and `RELEASED` as separate authority states.
- Present the approved COC2 package criterion-first. Technical 1/0 encodings may be shown only as a satisfied-criteria count, never as an official TESDA weighting or threshold.
- Keep official TESDA provenance and project-approved operational rules explicitly labeled.
- Keep gamification separate from competency results.

## Responsive Behavior

- Replace dense desktop rows with stacked labeled groups on narrow screens.
- Allow horizontal table scrolling only when column relationships would otherwise become ambiguous; prefer responsive lists for primary workflows.
- Keep primary actions near the related state and avoid fixed controls that cover content.
- The simulation workspace expands without recreating attempts or losing state.

## Restraint Rules

- No glassmorphism, decorative dashboards, oversized logos, meaningless KPI cards, or gratuitous charts.
- No monospace type used as a generic â€œtechnicalâ€ costume. Reserve it for event sequence numbers, IDs, and structured evidence.
- No hover movement that shifts layout.
- No animated reveal that hides critical content before JavaScript runs.

