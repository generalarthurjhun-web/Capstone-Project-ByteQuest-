import 'package:bytequest/models/mission_model.dart';
import 'package:bytequest/screens/simulation/components/practice_mission_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mission identifier normalizes catalog and database mission codes', () {
    expect(practiceMissionIdentifier(_mission), 'COC2 M1');
    expect(
      practiceMissionIdentifier(_mission.copyWith(missionCode: 'COC2-M1')),
      'COC2 M1',
    );
  });

  testWidgets(
      'header shows title and COC mission identifier without fullscreen',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PracticeMissionHeader(
            mission: _mission,
            onBackPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text(_mission.title), findsOneWidget);
    expect(find.text('COC2 M1'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('simulation-fullscreen-button')),
      findsNothing,
    );
  });

  testWidgets('back exits immediately when no progress exists', (tester) async {
    var discarded = false;
    await tester.pumpWidget(_exitHost(
      hasProgress: () => false,
      onDiscard: () async => discarded = true,
    ));

    await tester.tap(find.text('Open mission'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Leave mission'));
    await tester.pumpAndSettle();

    expect(find.text('Mission body'), findsNothing);
    expect(find.text('Exit Mission?'), findsNothing);
    expect(discarded, isFalse);
  });

  testWidgets('cancel keeps the mission and its progress', (tester) async {
    var discarded = false;
    await tester.pumpWidget(_exitHost(
      hasProgress: () => true,
      onDiscard: () async => discarded = true,
    ));

    await tester.tap(find.text('Open mission'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Leave mission'));
    await tester.pumpAndSettle();
    expect(find.text('Exit Mission?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Mission body'), findsOneWidget);
    expect(discarded, isFalse);
  });

  testWidgets('confirmed exit discards progress before leaving',
      (tester) async {
    var discarded = false;
    await tester.pumpWidget(_exitHost(
      hasProgress: () => true,
      onDiscard: () async => discarded = true,
    ));

    await tester.tap(find.text('Open mission'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Leave mission'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Exit'));
    await tester.pumpAndSettle();

    expect(find.text('Mission body'), findsNothing);
    expect(discarded, isTrue);
  });

  testWidgets('system back uses the same progress-aware exit contract',
      (tester) async {
    await tester.pumpWidget(_exitHost(
      hasProgress: () => true,
      onDiscard: () async {},
    ));
    await tester.tap(find.text('Open mission'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Exit Mission?'), findsOneWidget);
    expect(find.text('Mission body'), findsOneWidget);
  });
}

Widget _exitHost({
  required bool Function() hasProgress,
  required Future<void> Function() onDiscard,
}) {
  return MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => PracticeMissionExitGuard(
                  mission: _mission,
                  hasProgress: hasProgress,
                  onDiscard: onDiscard,
                  builder: (context, requestExit) => Scaffold(
                    appBar: AppBar(
                      leading: IconButton(
                        tooltip: 'Leave mission',
                        onPressed: requestExit,
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                    ),
                    body: const Text('Mission body'),
                  ),
                ),
              ),
            ),
            child: const Text('Open mission'),
          ),
        ),
      ),
    ),
  );
}

final _mission = Mission(
  id: 'coc2_m1',
  cocId: 'coc2',
  missionCode: 'COC2_M1',
  missionNumber: 1,
  title: 'Identify Network Devices and Tools',
  missionType: MissionType.identification,
  orderIndex: 1,
);
