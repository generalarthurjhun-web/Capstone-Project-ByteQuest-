# ByteQuest Mobile QA Audit

Audit date: 2026-08-22 (Asia/Manila)
Build: Flutter debug APK, package `com.example.bytequest`, Android 16 emulator `emulator-5554`
Scope: static configuration review, startup/auth/runtime smoke testing, offline/lifecycle checks, and existing automated coverage. No product fixes were made during this audit.

## Priority summary

| Priority | Count | Meaning |
|---|---:|---|
| P1 | 1 | Startup can fail hard when Supabase configuration is missing or malformed |
| P2 | 1 | Noticeable first-use jank during startup/auth rendering |
| P3 | 1 | Mission scene metadata points at assets that are not present/declared |
| Blocked | 1 | Authenticated mission/evidence/scoring test blocked by supplied account credentials |

## Findings

### BQ-QA-001

- Severity: P1 — High
- Location: `ByteQuest-Mobile-App/lib/main.dart:31-40`; `ByteQuest-Mobile-App/lib/core/config/supabase_config.dart:29-45`
- Steps to reproduce:
  1. Remove `.env`, or leave `SUPABASE_URL`/`SUPABASE_ANON_KEY` empty.
  2. Launch the APK.
- Expected behavior: A controlled configuration/error screen explains the missing setting and keeps the process alive (or exits with a user-actionable message).
- Actual behavior: `main()` logs a warning, then calls `SupabaseConfig.initialize()` without a recovery boundary. Initialization rethrows the missing-variable exception before `runApp()`, so Flutter has no error UI to display and startup can terminate.
- Root cause: Environment loading is attempted twice, but the second initialization exception is allowed to escape the root async entrypoint.
- Recommended fix: Validate configuration once before `runApp()`, then render a fail-closed `ConfigurationErrorScreen` with a non-secret diagnostic. Add a startup test for missing URL/key and malformed URL.

### BQ-QA-002

- Severity: P2 — Medium
- Location: startup path in `ByteQuest-Mobile-App/lib/main.dart:28-60`; splash/auth image-heavy screens.
- Steps to reproduce:
  1. Clear app state and launch on `emulator-5554`.
  2. Move from onboarding to login and focus the form.
  3. Observe Flutter/device logs.
- Expected behavior: Startup and the first auth interaction remain responsive with no sustained frame loss.
- Actual behavior: Runtime logs recorded `Skipped 72 frames`, `Skipped 59 frames`, and `Skipped 125 frames` during initial startup/auth rendering. The app remained usable, but transitions and keyboard interactions visibly stalled on the emulator.
- Root cause: Large raster assets and Supabase initialization/orientation work occur during the first interactive frames; image decoding is visible in the Android logs.
- Recommended fix: Defer non-critical initialization until after the first frame, precache/resize onboarding assets, and profile image decode plus auth-screen rebuilds on a low-end emulator. Add a startup frame-time budget to QA.

### BQ-QA-003

- Severity: P3 — Low/medium maintainability risk
- Location: `ByteQuest-Mobile-App/lib/data/mission_simulation_definitions.dart:170-174`; `ByteQuest-Mobile-App/pubspec.yaml:52-58`
- Steps to reproduce:
  1. Inspect generated mission scene definitions.
  2. Resolve each `metadata.replaceableAsset` path.
  3. Check the Flutter asset manifest/source tree.
- Expected behavior: Every replaceable scene asset exists and is declared, or the definition uses an explicit placeholder/fallback contract.
- Actual behavior: Definitions generate paths under `assets/simulation/schematics/<object>.svg`, but no `assets/simulation/schematics` files or asset declaration exists in the project. The current renderer does not consume this metadata, so this did not crash the smoke run; any future renderer that does will produce missing-asset failures.
- Root cause: Scene metadata was added ahead of the production schematic asset bundle.
- Recommended fix: Either add the schematic bundle and `pubspec.yaml` declaration, or remove/guard the metadata and provide a tested code-drawn fallback. Add an asset-manifest consistency test.

## Test limitation (not classified as a confirmed product defect)

`drobertalsidpalces@gmail.com` / supplied password was entered through the real login UI. Supabase returned `Invalid login credentials`; the UI stayed on login and emitted a specific error snackbar. Because no valid disposable learner account was available, the following could not be exercised end-to-end: authenticated dashboard navigation, mission launch from the learner shell, evidence submission, backend scoring, pause/resume of an authenticated attempt, realtime instructor release, and authenticated offline recovery. This is an environment/credential blocker, not evidence that those flows are broken.

## Runtime checks performed

- APK build/install/startup: passed; app reached onboarding without a crash.
- Onboarding → “I already have an account” → login: passed.
- Invalid-auth handling: passed; returned a specific invalid-credentials message and did not crash.
- Offline cold start: passed at the shell level; app still rendered onboarding while airplane mode was enabled. Authenticated offline behavior remains blocked by credentials.
- Force-stop/relaunch smoke: app process relaunched and rendered the onboarding shell.
- Emulator/device: Android 16, `emulator-5554`, 320×640 logical display in the UI dump.
- Automated Flutter suite: `flutter test` passed, 189 tests.
- Static analysis: `flutter analyze --no-fatal-infos` exited 0; 213 informational lints, 0 errors.
- Debug APK build: passed. Build emitted Kotlin/Gradle migration warnings but no build failure.
- No `FATAL EXCEPTION`, Flutter framework exception, `RenderFlex overflow`, or `Unable to load asset` was observed during the captured smoke run.

## Recommended fix order

1. BQ-QA-001 — protect startup with a controlled configuration state.
2. BQ-QA-002 — reduce first-frame/auth jank and add a measurable performance gate.
3. BQ-QA-003 — reconcile schematic metadata with real assets or a guaranteed fallback.
4. Re-run authenticated mission, evidence, scoring, realtime, and pause/resume checks with disposable learner/instructor credentials.

## Failed test operations and alternatives

- 2026-08-22 15:09 +08:00 — Android airplane-mode broadcast was rejected with `SecurityException` because shell UID cannot send `AIRPLANE_MODE` broadcasts on this emulator. Location: test harness command (no product line). Workaround used: `settings put global airplane_mode_on` plus `svc wifi/data`; alternative: toggle airplane mode through the emulator UI or use a network-proxy/offline test harness.
- 2026-08-22 15:10 +08:00 — Supplied login attempt failed with Supabase `Invalid login credentials`. Location: `lib/screens/auth/login_screen.dart:38-66` and `lib/services/auth_service.dart:88-123`. Workaround: obtain a valid disposable learner account or reset the supplied account through the authorized Supabase/instructor workflow; alternatives: run the existing widget/service tests with fakes, or provision a local Supabase test project without weakening production auth.
