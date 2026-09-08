# ByteQuest — AI Agent Rules and Architecture Reference

> This file is the permanent standing instruction set for every AI agent (Codex, Kiro, or similar)
> working in this repository. Read it in full before touching any code.

---

## 1. Project Purpose

ByteQuest is a Flutter-based interactive 2D mobile application targeting Android, built as a
Computer Systems Servicing NC II capstone project. It simulates real TVET competency tasks across
four COC tracks (COC1–COC4), with five missions each — 20 missions total.

The defining interaction loop is:

> Inspect → Interact → Diagnose → Configure → Connect → Test → Interpret → Troubleshoot → Verify → Submit

ByteQuest is **not** a quiz app. It must feel like operating real equipment and solving real
technical problems in a 2D workspace.

Key stakeholders: learners (students), instructors, admin. Assessment is authoritative and
Supabase-backed. Results are only released by instructors — never auto-released.

GitHub repo: `mikeangelocasono/ByteQuest-Capstone-Project`

---

## 2. Architecture Rules

### 2.1 Repository layout

```
ByteQuest-Mobile-App/     Flutter/Dart learner app (primary build target)
ByteQuest Web Dashboard/  Next.js/TypeScript instructor + admin dashboard
supabase/                 PostgreSQL migrations, RLS, Auth, Realtime config
docs/                     Architecture and audit documents
scripts/                  Shared maintenance and verification scripts
bytequest.md              Full build context — read this before implementing anything
README.md                 Repo overview and dev commands
AGENTS.md                 (this file) AI agent rules
CODEX_STATE.md            Live handoff state — update after every work session
```

### 2.2 Critical file — do not overwrite without reading first

`ByteQuest-Mobile-App/lib/screens/simulation/components/simulation_framework.dart` — the simulation engine
that all mission screens compose. Read it before touching any simulation screen.

### 2.3 Mobile app internal structure

```
lib/core/          Config, constants, routes, theme, shared core widgets
lib/data/          Static content and scenario data files
lib/models/        Dart model classes (do not alter without checking Supabase schema)
lib/screens/       All screen files, including simulation/templates/
lib/services/      Supabase-backed service layer
lib/widgets/       Reusable UI components
```

### 2.4 Backend authority

- **Supabase/PostgreSQL is the authoritative evaluation source.** Flutter records evidence; the
  backend evaluates it.
- Never implement local-only evaluation logic that bypasses Supabase.
- Realtime sync must propagate: learner submit → instructor view; instructor release → learner
  result.
- Assessment results are released only by an authenticated instructor. No auto-release.

### 2.5 Simulation architecture principles

- Every mission screen must compose on top of `simulation_framework.dart`.
- The 2D workspace (`simulation_scene.dart`, `hotspot_widget.dart`) is a reusable engine —
  never duplicate scene logic inside a single mission file.
- Interaction components (`TapInspectInteraction`, `ConnectionInteraction`, etc.) are standalone
  reusable widgets, not one-off per-mission code.
- Scene state is driven by real `MissionState` data, not decorative animation only.
- Drag-drop is **never** the sole mechanic for any mission. Every mission must use at least
  two distinct interaction types.

---

## 3. Coding Rules

### 3.1 Before writing any code

1. Read `bytequest.md` in full — it contains the build priority order, interaction type
   specifications, quality standards, and acceptance criteria.
2. Read the relevant existing files (services, models, templates) before creating anything new.
3. Check `CODEX_STATE.md` for completed and unfinished tasks — do not redo completed work.

### 3.2 Flutter / Dart standards

- Dart null safety is mandatory throughout.
- No hardcoded strings in widget files. Feedback strings go in
  `lib/data/mission_content_data.dart`.
- Follow existing naming conventions: `snake_case` files, `PascalCase` classes.
- Match the style of existing files in the same directory before introducing new patterns.
- Minimum accessible tap target: 48×48 dp on all interactive elements.
- All interactive elements must have `Semantics` labels.
- Support system large text setting and reduced motion preference.

### 3.3 Mission quality gates

Every mission must satisfy **all** of the following before it is considered done:

- Clear scenario or technical problem stated
- 3–6 meaningful interaction phases
- 2–4 different interaction types (drag-drop is never the only one)
- At least one technical decision point
- At least one observation, testing, or verification phase
- Every meaningful action produces structured evidence saved to Supabase
- Incorrect actions give concise technical feedback — never "Wrong"
- Assessment mode does not expose correct targets
- Mission state survives pause and resume without evidence duplication
- Works on different Android screen sizes
- Polished submission-review stage before final submit

### 3.4 Feedback rules

- Never display generic "Wrong" or "Correct".
- Show the specific technical reason, e.g.:
  `"CAT5e cannot support speeds above 100 Mbps on this segment."`
- On success: brief confirmation, then continue — do not interrupt flow.
- All feedback strings are defined in `mission_content_data.dart`, not inline.

### 3.5 Troubleshooting missions

- Do not reveal all diagnostic information at mission start.
- Each diagnostic action reveals exactly one new piece of information.
- Technical tool/component choices control what becomes visible.
- Every decision point must produce Supabase evidence.
- Never use a single multiple-choice question as the troubleshooting mechanic.

### 3.6 Persistence

Use `lib/services/progress_resume_service.dart` (already exists) as the persistence layer.
On app restart or return from background, every mission must restore:
- Current mission phase
- All accepted evidence
- Configuration state (dropdowns, toggles, text inputs)
- Connection state (which nodes are connected)

### 3.7 Visual design

- Primary palette: ByteQuest blue/navy.
- 2D workspace takes the majority of screen real estate.
- Typography: compact, professional.
- Transitions: 150–250 ms, smooth.
- Do NOT use: giant cards, excessive gradients, glassmorphism, glow effects, childish game styling.

---

## 4. Git Rules

- The active development branch is **Dro-branch**. Never push directly to `main`.
- `main` is the stable/protected branch. Merge only after explicit approval.
- Commit messages use the imperative mood: `Add COC1 M1 hardware inspection mission`.
- Stage specific files — never `git add .` blindly.
- Never commit:
  - `.env` files
  - Service-role keys or database passwords
  - Build artifacts (`build/`, `.dart_tool/`, `.flutter-plugins-dependencies`)
  - `*.apk`, `*.aab`, `*.ipa`
- Verify `git status` and `git diff --stat` before every commit.
- The `.gitignore` at repo root and `ByteQuest-Mobile-App/.gitignore` already cover common
  Flutter artifacts and `.env` files — do not weaken those rules.
- After each significant work session, update `CODEX_STATE.md` and commit it.

---

## 5. Supabase Security Rules

- **Never place the service-role key in Flutter code, assets, `.env`, or any client-side file.**
- The mobile app uses only the publishable anon key (`SUPABASE_ANON_KEY` in `.env`).
- The anon key is gitignored — it must not appear in any committed file.
- Row Level Security (RLS) is enabled on all tables. Do not disable it.
- SECURITY DEFINER functions exist for specific elevated operations — do not add new ones
  without explicit review.
- Roles are `learner`, `instructor`, and `admin`. Enforce role-based access in every new
  policy or function.
- The `service_role` key is server-only (web dashboard server actions, migration scripts).
  It must never be prefixed with `NEXT_PUBLIC_` or included in Flutter assets.
- Supabase migrations live in `supabase/migrations/`. Run them in order, never skip.
- Test migrations with the rollback-only lifecycle test before applying to production:
  `supabase/tests/foundation_lifecycle_rollback.sql`

---

## 6. Validation Commands

Run these before every commit and after every significant change:

```bash
# Mobile app
cd ByteQuest-Mobile-App
flutter pub get
flutter analyze --no-fatal-infos
flutter test
flutter build apk --debug

# Web dashboard
cd "ByteQuest Web Dashboard"
pnpm exec tsc --noEmit
pnpm lint
pnpm build
```

All commands must pass with zero errors. Warnings from `--no-fatal-infos` are acceptable
but should be tracked and resolved over time.

---

## 7. Mandatory Pre-Work Checklist

Before modifying or creating any file, an AI agent must:

1. Read `bytequest.md` — full build context and quality standards
2. Read `CODEX_STATE.md` — current implementation status and known issues
3. Read the existing file(s) being modified — never patch code you haven't seen
4. Check `screens/simulation/templates/` for existing patterns before creating a new mission
5. Check `lib/services/` before writing any Supabase interaction — the service layer likely
   already exists
6. Verify the model in `lib/models/` matches what you are saving to Supabase

---

## 8. Do Not Redo Completed Work

`CODEX_STATE.md` lists completed tasks. Do not re-implement anything already listed there.

If a feature is listed as partially complete, read the existing implementation first, then
extend it — do not replace it.

If you are unsure whether something is done, check the source file before implementing.

---

## 9. Mission Status Summary

| COC | M1 | M2 | M3 | M4 | M5 |
|-----|----|----|----|----|-----|
| COC1 | Runtime | Runtime | Runtime | Runtime | Runtime |
| COC2 | Runtime | Runtime + cable assessment | Runtime | Runtime | Runtime |
| COC3 | Runtime | Runtime | Runtime | Runtime | Runtime |
| COC4 | Runtime | Runtime | Runtime | Runtime | Runtime |

`Runtime` means the production practice route resolves through the typed 2D
simulation engine. It does not replace the required automated, device,
accessibility, backend, and instructor-release validation gates.

Existing templates in `screens/simulation/templates/`:
`coc1_m2_screen.dart`, `coc1_m2_screen_enhanced.dart`, `coc1_m3_screen_enhanced.dart`,
`coc2_cable_termination_assessment_screen.dart`, `coc2_cable_assessment_contract.dart`,
plus generic templates: `drag_drop_mission_screen.dart`, `identification_mission_screen.dart`,
`step_procedure_mission_screen.dart`, `troubleshooting_mission_screen.dart`,
`configuration_mission_screen.dart`.

---

## 10. Capstone Defense Standard

The panel must immediately see ByteQuest is a 2D simulation platform, not a quiz app.

Select one showcase mission per COC demonstrating the richest interaction type for defense:
- COC1: installation/configuration showcase
- COC2: networking/topology showcase
- COC3: server configuration showcase
- COC4: troubleshooting/repair showcase

Final target: **20/20 missions functional, 0 drag-drop-only missions.**
