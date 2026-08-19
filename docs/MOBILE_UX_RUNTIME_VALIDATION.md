# Mobile UX Runtime Validation

**Date:** 2026-08-10  
**Surface:** Flutter learner app, especially simulation interaction  
**Method:** Android 16 emulator at 411Ã—914 dp; widget tests at 320Ã—568 portrait, 568Ã—320 landscape, and 800Ã—1280 tablet; source inspection; analyzer; debug APK build

## Verdict

The learner entry flow and simulations are runtime-stable at the tested viewports. Explicit full-screen control and a non-drag select-then-place path close the documented interaction gaps. All 19 newly published packages launch a shared workspace-first assessment screen while COC2 M2 retains its golden-reference workspace. Released results show criterion feedback. Authenticated database E2E uses disposable learners, but a human-operated Flutter UI session remains unrecorded.

## Native UX score

| Dimension | Score (0â€“4) | Evidence-based finding |
|---|---:|---|
| Accessibility | 3 | Safe areas, semantics, icon-plus-text states, 48/64 dp matching controls, full-screen semantics, non-drag placement, and 1.8Ã— text widget coverage exist; physical TalkBack/device acceptance remains |
| Performance | 3 | Lazy lists, cached assets, bounded animation, and simple gesture paths are used; no physical-device frame profile exists |
| Appearance/theming | 3 | Consistent Material 3 hierarchy, spacing, typography, and states; dark theme/dynamic color are not baseline requirements |
| Android conformance | 3 | Material controls, system back, SafeArea, reversible System UI mode, and native dialogs are used |
| Adaptivity | 3 | Compact portrait, landscape, and tablet widget layouts pass without overflow |
| **Total** | **15/20 â€” Good** | Suitable for controlled demonstration; physical accessibility/performance validation remains |

## Verified interaction improvements

1. Compact installation layout no longer overflows at 320Ã—568.
2. All six enhanced installation targets expose at least a 48Ã—48 dp effective hit area.
3. Assessment mode hides permanent target names, fills, outlines, icons, and local point values until proximity/feedback.
4. Enhanced simulations display the actual Practice/Assessment state.
5. IPv4 configuration rejects octets outside 0â€“255.
6. Active generic/enhanced simulation routes provide an obvious, 48 dp, semantic full-screen enter/exit control.
7. Full-screen disposal restores edge-to-edge System UI and does not reset route/attempt state.
8. Generic drag/drop and enhanced installation/wiring screens support select-item then select-destination interaction through the same placement/evidence path as drag.
9. Correct/incorrect/selection states use icons/text/borders as well as color.
10. Learner dashboard/progress surfaces consistently disclose ByteQuestâ€™s supplementary, non-certifying role.
11. The dedicated COC2 workspace records PPE, tools/materials, ordered preparation, chronological T568B placement, termination, tester use/result, inspection, and cleanup through one authoritative service.
12. COC2 conductor placement supports drag and select-item/select-next-neutral-pin through the same evidence function; assessment targets remain neutral rather than answer-labeled.
13. Released result cards present Instructor-final outcome and criterion-by-criterion satisfied/not-satisfied feedback instead of an implied TESDA percentage.
14. Assigned `authoritative_mission_v1` activities use one generalized contract parser/workspace rather than 19 hard-coded assessment screens.
15. Learner payloads omit hidden expected answers and evidence rules; those remain in the server rubric.
16. Selection, exact sequence, single choice, configuration, and matching stages emit consistent ordered evidence. Matching drag and select/destination inputs call the same evidence path.

## Automated assertions

`test/drag_drop_accessibility_test.dart` verifies:

- a 96 dp forgiving generic drop area;
- 320Ã—568, 568Ã—320, and 800Ã—1280 simulation layouts without Flutter exceptions;
- six enhanced targets at least 48Ã—48 dp at every tested size;
- equivalent select-then-place behavior without a drag gesture; and
- reversible enter/exit full-screen semantics with a 48 dp control.

`test/authoritative_mission_contract_test.dart` validates parser fail-closed behavior, duplicate rejection, and learner-payload answer isolation. `test/authoritative_mission_assessment_widget_test.dart` validates 320Ã—568 portrait, 568Ã—320 landscape, 800Ã—1280 tablet, 1.8Ã— text, and drag/non-drag evidence equivalence.

The full Flutter suite passes **24 tests**. `flutter analyze --no-fatal-infos` exits 0 with zero errors/warnings and 243 legacy informational lints. `flutter build apk --debug` succeeds.

## Remaining P1 validation

- Validate the implemented non-drag path with TalkBack on physical Android hardware.
- Run physical-device large-text acceptance across mission instructions, compact diagram annotations, result cards, and full-screen controls; automated 1.8Ã— coverage already passes for the shared workspace.
- Record a human-operated authenticated learner journey on a device; disposable automated identities are now available in the test harness but are retired after each run.

## Remaining P2 validation

- Profile drag frame pacing on a low/mid-range physical Android device.
- Verify foldable, split-screen, and physical tablet behavior.
- Consider reduce-motion integration with platform accessibility settings.
- Plan future Gradle/AGP/Kotlin upgrades; current versions build but Flutter reports future-support warnings.

## Acceptance boundary

PRD `MOB-007` and `UI-001` now have widget-runtime evidence. Overall accessibility remains **PARTIAL** until physical TalkBack and large-text testing are completed.

