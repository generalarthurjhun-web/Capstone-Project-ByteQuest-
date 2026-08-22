# ByteQuest Android Emulator QA

Date: 2026-08-22 (Asia/Manila)

## Device and artifact

- Device: `sdk gphone64 x86 64` (`emulator-5554`)
- Android: 16 / API 36, `android-x64`
- Display: 320 × 640 physical pixels; 136 dpi override
- Hardware rendering: enabled
- Package: `com.example.bytequest`
- APK: `ByteQuest-Mobile-App/build/app/outputs/flutter-apk/app-debug.apk`
- APK SHA-256: `032D2E7DD07CFC3700F801EBA70F30549D440AE627AADE1E884F2B3A89B0C6C6`

The APK installed successfully and reached onboarding and learner login without a startup crash. No fatal `AndroidRuntime` or Flutter exception appeared in the captured startup log.

## Shell and lifecycle variants

| Check | Result | Evidence |
|---|---|---|
| Portrait startup | Pass | Onboarding rendered at 320 × 640 without visible overflow or dead primary actions. |
| Landscape | Pass at app shell | Login rendered after rotation without a Flutter overflow/crash. |
| Large font | Pass at app shell | System font scale 2.0 rendered; content remained scrollable/contained. Authenticated mission screens remain covered by widget tests, not live device evidence. |
| Reduced motion | Pass at app shell | All Android animation scales set to 0 without crash; runtime reduced-motion behavior is covered by the accessibility matrix. |
| Background/resume | Pass at app shell | Process ID remained `6382` after Home and resume. |
| Force-stop/relaunch | Pass at app shell | New process ID `6644` launched successfully. |
| Settings cleanup | Pass | Font scale, animation scales, and automatic rotation were restored after QA. |

## Twenty-mission matrix

Legend: **Contract pass** means catalog, launcher, interaction, accessibility, persistence, and runtime widget tests passed in the 169-test full suite. **Live unverified** means the installed APK could not enter the authenticated mission because no authorized learner credentials were supplied. It does not mean failure or pass.

| Mission | Launch/scenario/scene/phases/feedback/evidence/review contract | Live emulator interaction | Pause/resume/submit lifecycle | Overall device status |
|---|---|---|---|---|
| COC1 M1 (`coc1_m1`) | Contract pass | Live unverified | Live unverified | Blocked by authentication |
| COC1 M2 (`coc1_m2`) | Contract pass | Live unverified | Live unverified | Blocked by authentication |
| COC1 M3 (`coc1_m3`) | Contract pass | Live unverified | Live unverified | Blocked by authentication |
| COC1 M4 (`coc1_m4`) | Contract pass | Live unverified | Live unverified | Blocked by authentication |
| COC1 M5 (`coc1_m5`) | Contract pass | Live unverified | Live unverified | Blocked by authentication |
| COC2 M1 (`coc2_m1`) | Contract pass | Live unverified | Live unverified | Blocked by authentication |
| COC2 M2 (`coc2_m2`) | Contract pass; protected evaluator route retained | Live unverified | Live unverified | Blocked by authentication |
| COC2 M3 (`coc2_m3`) | Contract pass | Live unverified | Live unverified | Blocked by authentication |
| COC2 M4 (`coc2_m4`) | Contract pass | Live unverified | Live unverified | Blocked by authentication |
| COC2 M5 (`coc2_m5`) | Contract pass | Live unverified | Live unverified | Blocked by authentication |
| COC3 M1 (`coc3_m1`) | Contract pass | Live unverified | Live unverified | Blocked by authentication |
| COC3 M2 (`coc3_m2`) | Contract pass | Live unverified | Live unverified | Blocked by authentication |
| COC3 M3 (`coc3_m3`) | Contract pass | Live unverified | Live unverified | Blocked by authentication |
| COC3 M4 (`coc3_m4`) | Contract pass | Live unverified | Live unverified | Blocked by authentication |
| COC3 M5 (`coc3_m5`) | Contract pass | Live unverified | Live unverified | Blocked by authentication |
| COC4 M1 (`coc4_m1`) | Contract pass | Live unverified | Live unverified | Blocked by authentication |
| COC4 M2 (`coc4_m2`) | Contract pass | Live unverified | Live unverified | Blocked by authentication |
| COC4 M3 (`coc4_m3`) | Contract pass | Live unverified | Live unverified | Blocked by authentication |
| COC4 M4 (`coc4_m4`) | Contract pass | Live unverified | Live unverified | Blocked by authentication |
| COC4 M5 (`coc4_m5`) | Contract pass | Live unverified | Live unverified | Blocked by authentication |

## Automated evidence used for the unverified live rows

- Full Flutter suite: 169/169 passed.
- Task 9 UI gate: 84/84 passed across scene, core/advanced interactions, runtime screen, accessibility matrix, and design system.
- Catalog acceptance proves exactly 20 stable mission definitions, required interaction variety, diagnostic fact progression, correction/retest controls, and review phases.
- Launcher/runtime tests prove all 20 default IDs resolve to the canonical runtime while protected legacy evaluator routes remain explicit.
- Persistence tests prove scoped mode/attempt restoration, unknown-phase fail-closed recovery, evidence de-duplication, and terminal submit latching.

## Required follow-up with credentials

Using a disposable authorized learner assigned all 20 missions, repeat each row and record: live launch, scenario, responsive scene, every phase, technical feedback, evidence count, mid-phase background/restore, review, submit, instructor visibility/evaluation/release, learner result, crash/overflow, and dead controls. Do not store the account password, access token, or service-role key in this document or repository.
