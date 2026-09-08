# ByteQuest

ByteQuest is a complete capstone project: a gamified Computer Systems Servicing NC II learner application, an Instructor/Admin dashboard, and one shared Supabase backend with authoritative assessment and access-control workflows.

## Repository map

- `ByteQuest-Mobile-App/` — Flutter/Dart learner application, simulations, missions, quizzes, resources, progress, results, and mobile platform projects.
- `ByteQuest Web Dashboard/` — Next.js/TypeScript Instructor and Admin dashboard, authentication, RBAC, analytics, reports, and realtime UI integration.
- `supabase/` — shared PostgreSQL/Auth/Storage/RLS/Realtime backend, ordered migrations, and rollback-only database lifecycle tests.
- `docs/` — project, audit, architecture, capstone, TESDA provenance, design, and historical documentation.
- `scripts/` — shared maintenance, provisioning, verification, and authenticated lifecycle scripts.

Supabase Auth and PostgreSQL are the shared identity and data authority. Roles are `learner`, `instructor`, and `admin`; assessment evaluation, criterion results, finalization, release, audit events, and gamification-side effects remain database-authoritative.

All 20 catalog mission IDs use the typed 2D `MissionSimulationScreen` for the
normal learner practice path. Server-issued `authoritative_mission_v1`
activities and the protected COC2 cable assessment retain their explicit
authoritative adapters; unknown mission IDs and template names fail closed.

The root `package.json` contains only the Node dependencies needed by repository-level Supabase and lifecycle scripts; the dashboard has its own package manifest and lockfile.

## Development commands

Mobile:

```bash
cd "ByteQuest-Mobile-App"
flutter pub get
flutter run
```

Web:

```bash
cd "ByteQuest Web Dashboard"
pnpm install
pnpm dev
```

Web verification:

```bash
cd "ByteQuest Web Dashboard"
pnpm exec tsc --noEmit
pnpm lint
pnpm build
```

Mobile verification:

```bash
cd "ByteQuest-Mobile-App"
flutter pub get
flutter test
flutter analyze
flutter build apk --debug
```

Shared Supabase commands are run from the repository root. The
`20260807085500_initial_schema.sql` artifact bootstraps an empty local database;
an existing database that already records migration version `20260807085500`
skips that baseline and receives only later forward migrations. Never use
`migration repair` or `db push --include-all` to make the histories agree.

For an isolated local stack:

```bash
supabase db reset --local
supabase test db
```

The rollback tests create fixtures inside transactions and leave the local
database unchanged. Do not point these commands at the live project.

Authenticated web/database lifecycle checks are exposed as scripts in `scripts/` and package commands in `ByteQuest Web Dashboard/package.json`. They require the local dashboard environment and appropriate test credentials.

## Configuration and secrets

Copy `ByteQuest Web Dashboard/.env.example` to `ByteQuest Web Dashboard/.env.local` and provide the shared Supabase URL and browser-safe publishable/anonymous key. The Supabase service-role and OpenRouter keys are server-only and must never be placed in Flutter assets or variables prefixed with `NEXT_PUBLIC_`. Set `BYTEQUEST_E2E_PASSWORD` locally before running authenticated lifecycle scripts. The mobile app keeps its local `.env` for the Supabase URL and anonymous key; it is gitignored.

Never commit service-role keys, database passwords, access tokens, or local environment files.

## Documentation

Current acceptance, architecture, assessment, security, mobile, and deployment records are in `docs/`. Files under `docs/archive/` are retained historical records and are not current implementation guidance. Official TESDA source material and project-approved operational decisions remain distinct from gamification rules; ByteQuest does not issue TESDA certification or imply TESDA endorsement.
