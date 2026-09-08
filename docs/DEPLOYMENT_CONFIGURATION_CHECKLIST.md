# ByteQuest Deployment Configuration Checklist

This checklist records the configuration required to deploy the current
ByteQuest Web Dashboard and Flutter learner app without exposing credentials.
Values must be supplied through the deployment provider or a local ignored
file; never commit them to the repository.

## Web Dashboard

Required runtime variables (names only):

- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY` (trusted server/test execution only)
- `OPENROUTER_API_KEY` (trusted Instructor AI draft route only)
- `OPENROUTER_MODEL` (recommended initial value: `openrouter/free`)

Optional verification variables:

- `BYTEQUEST_WEB_BASE_URL`
- `BYTEQUEST_DEMO_INSTRUCTOR_EMAIL`
- `BYTEQUEST_DEMO_INSTRUCTOR_PASSWORD`
- `BYTEQUEST_DEMO_LEARNER_PASSWORD`
- `BYTEQUEST_TEST_RUN_ID`

The verification variables are for disposable test accounts and should not be
configured as production secrets unless a controlled test environment needs
them.

## Flutter Android

Required runtime/build variables (names only):

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

The learner APK must never contain `SUPABASE_SERVICE_ROLE_KEY`,
`OPENROUTER_API_KEY`, or any other privileged server credential.

## Release signing

The Android Gradle configuration now fails closed for normal release builds.
The repository includes `ByteQuest-Mobile-App/android/key.properties.example`.

1. Create a private release keystore in the deployment environment.
2. Copy the example to `ByteQuest-Mobile-App/android/key.properties`.
3. Replace the placeholders with the deployment keystore values.
4. Keep `key.properties`, `*.jks`, and `*.keystore` untracked.
5. Build normally:

```powershell
cd "ByteQuest-Mobile-App"
flutter build appbundle --release
```

For a local smoke artifact only, without a release keystore, explicitly opt in
to debug signing for that command and do not distribute the result:

```powershell
$env:BYTEQUEST_ALLOW_DEBUG_SIGNING = "true"
flutter build apk --release
Remove-Item Env:BYTEQUEST_ALLOW_DEBUG_SIGNING
```

## Pre-deployment checks

- Confirm the Web deployment URL and Supabase Auth redirect URLs match.
- Confirm private Storage buckets remain private and signed access is short lived.
- Confirm service-role and OpenRouter keys are server-only.
- Run the Web production build and authenticated route smoke tests.
- Run Flutter tests, analyzer, debug build, and a signed release build.
- Record Android process-kill/resume and browser responsive QA in
  `docs/FINAL_CAPSTONE_ACCEPTANCE_WALKTHROUGH.md`.
- Run `supabase test db` against an isolated local stack and require every
  rollback/RLS/RBAC test to pass before deployment.


