import 'dart:convert';

import 'package:bytequest/core/widgets/instruction_card.dart';
import 'package:bytequest/core/widgets/progress_indicator_card.dart';
import 'package:bytequest/core/widgets/step_progress_card.dart';
import 'package:bytequest/data/mission_content_data.dart';
import 'package:bytequest/data/missions_data.dart';
import 'package:bytequest/models/mission_model.dart';
import 'package:bytequest/screens/simulation/components/practice_mission_chrome.dart';
import 'package:bytequest/screens/simulation/mission_launcher.dart';
import 'package:bytequest/screens/simulation/templates/coc1_m2_screen_enhanced.dart';
import 'package:bytequest/screens/simulation/templates/drag_drop_mission_screen.dart';
import 'package:bytequest/screens/simulation/templates/identification_mission_screen_enhanced.dart';
import 'package:bytequest/screens/simulation/templates/troubleshooting_mission_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'sb_publishable_ui_revision_test_key',
    );
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
      'identification uses status-first layout and learner-paced feedback',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final questions = [
      MissionQuestion(
        id: 'q1',
        question: 'Tap the correct item: Router',
        options: const ['Router', 'Switch', 'Modem', 'Crimping Tool'],
        correctAnswer: 'Router',
        explanation: 'A router forwards traffic between networks.',
      ),
      MissionQuestion(
        id: 'q2',
        question: 'Tap the correct item: Switch',
        options: const ['Router', 'Switch', 'Modem', 'Crimping Tool'],
        correctAnswer: 'Switch',
        explanation: 'A switch connects devices inside a LAN.',
      ),
    ];
    final items = [
      HardwareItem(
          id: 'router', name: 'Router', imagePath: 'missing/router.png'),
      HardwareItem(
          id: 'switch', name: 'Switch', imagePath: 'missing/switch.png'),
      HardwareItem(id: 'modem', name: 'Modem', imagePath: 'missing/modem.png'),
      HardwareItem(
        id: 'crimper',
        name: 'Crimping Tool',
        imagePath: 'missing/crimper.png',
      ),
    ];

    await tester.pumpWidget(MaterialApp(
      home: IdentificationMissionScreenEnhanced(
        mission: _mission('coc2_m1', 1, 'Identify Network Devices and Tools'),
        questions: questions,
        hardwareItems: items,
      ),
    ));
    await tester.pump();

    expect(find.text('COC2 M1'), findsOneWidget);
    expect(find.byType(StepProgressCard), findsNothing);
    expect(find.byType(ProgressIndicatorCard), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(ProgressIndicatorCard)).dy,
      lessThan(tester.getTopLeft(find.byType(InstructionCard)).dy),
    );
    expect(
      find.byKey(const ValueKey('simulation-fullscreen-button')),
      findsNothing,
    );

    await tester.tap(find.text('Router'));
    await tester.pump();
    expect(find.text('A router forwards traffic between networks.'),
        findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    expect(find.text('A router forwards traffic between networks.'),
        findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is InstructionCard &&
            widget.instruction == 'Tap the correct item: Router',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is InstructionCard &&
            widget.instruction == 'Tap the correct item: Switch',
      ),
      findsOneWidget,
    );
  });

  testWidgets('COC2 M2 shows pin slots above a two-column answer grid',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final components = List.generate(
      8,
      (index) => DraggableComponent(
        id: 'option_${index + 1}',
        name: 'Option ${index + 1}',
        targetZone: 'pin_${index + 1}',
      ),
    );
    final zones = List.generate(
      8,
      (index) => DropZone(
        id: 'pin_${index + 1}',
        name: 'Pin ${index + 1}',
        acceptedComponents: ['option_${index + 1}'],
      ),
    );

    await tester.pumpWidget(MaterialApp(
      home: DragDropMissionScreen(
        mission: _mission('coc2_m2', 2, 'Create Network Cables'),
        components: components,
        dropZones: zones,
      ),
    ));
    await tester.pump();

    expect(
      tester.getTopLeft(find.text('Pin 1').first).dy,
      lessThan(tester.getTopLeft(find.text('Option 1')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Option 1')).dy,
      tester.getTopLeft(find.text('Option 2')).dy,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('COC2 M2 keeps workspace controls visible in compact landscape',
      (tester) async {
    tester.view.physicalSize = const Size(640, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      home: DragDropMissionScreen(
        mission: _mission('coc2_m2', 2, 'Create Network Cables'),
        components: List.generate(
          8,
          (index) => DraggableComponent(
            id: 'option_${index + 1}',
            name: 'Option ${index + 1}',
            targetZone: 'pin_${index + 1}',
          ),
        ),
        dropZones: List.generate(
          8,
          (index) => DropZone(
            id: 'pin_${index + 1}',
            name: 'Pin ${index + 1}',
            acceptedComponents: ['option_${index + 1}'],
          ),
        ),
      ),
    ));
    await tester.pump();

    expect(find.text('Pin connections').hitTestable(), findsOneWidget);
    expect(find.text('Check Placements').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('installation feedback does not move the workspace',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1280);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      home: COC1M2ScreenEnhanced(
        mission: _mission('coc1_m2', 2, 'Install Internal Components'),
      ),
    ));
    await tester.pump();

    final workspaceTarget =
        find.byKey(const ValueKey('drop-target-motherboard_area'));
    final before = tester.getRect(workspaceTarget);

    await tester.tap(find.byWidgetPredicate(
      (widget) => widget is Draggable<String> && widget.data == 'motherboard',
    ));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('drop-target-cpu_socket')));
    await tester.pump();

    expect(find.text('Incorrect placement.'), findsOneWidget);
    expect(tester.getRect(workspaceTarget), before);
  });

  testWidgets(
      'troubleshooting restores submitted answer and stable option mapping',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _recoverTestSession();
    addTearDown(() async {
      try {
        await Supabase.instance.client.auth.signOut(
          scope: SignOutScope.local,
        );
      } on AuthException {
        // The local session is removed before the mocked endpoint is called.
      }
    });
    final mission = _mission(
      'coc4_m3',
      3,
      'Diagnose Hardware and Software Faults',
    );
    final scenarios = [
      <String, dynamic>{
        'symptom': 'Computer beeps and shows no display',
        'causes': <String>[
          'RAM not seated properly',
          'Working hardware',
          'No related fault',
          'Correct power and connection',
        ],
        'correctCause': 'RAM not seated properly',
        'explanation': 'Reseat the memory module and retest POST.',
        'points': 25,
      },
    ];

    await tester.pumpWidget(MaterialApp(
      home: TroubleshootingMissionScreen(
        mission: mission,
        scenarios: scenarios,
      ),
    ));
    await tester.pump(const Duration(milliseconds: 100));

    final initialOrder = tester
        .widgetList<Text>(find.byType(Text))
        .map((widget) => widget.data)
        .where((text) => scenarios.single['causes'].contains(text))
        .cast<String>()
        .toList();

    await tester.tap(find.text('RAM not seated properly'));
    await tester.pump();
    await tester.tap(find.text('Submit Diagnosis'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Correct Diagnosis!'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();
    await tester.pumpWidget(MaterialApp(
      home: TroubleshootingMissionScreen(
        mission: mission,
        scenarios: scenarios,
      ),
    ));
    await tester.pump(const Duration(milliseconds: 100));

    final restoredOrder = tester
        .widgetList<Text>(find.byType(Text))
        .map((widget) => widget.data)
        .where((text) => scenarios.single['causes'].contains(text))
        .cast<String>()
        .toList();
    expect(restoredOrder, initialOrder);
    expect(find.text('Correct Diagnosis!'), findsOneWidget);
    expect(find.text('View Results'), findsOneWidget);
  });

  for (final mission in MissionsData.getAllMissions()) {
    testWidgets('${mission.id} shows identity without fullscreen',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1280);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester
          .pumpWidget(MaterialApp(home: MissionLauncher.screenFor(mission)));
      await tester.pump();

      expect(
        find.text(practiceMissionIdentifier(mission)),
        findsOneWidget,
        reason: '${mission.id} must identify itself in the practice header.',
      );
      expect(
        find.byKey(const ValueKey('simulation-fullscreen-button')),
        findsNothing,
        reason: '${mission.id} must not expose the obsolete fullscreen action.',
      );
    });
  }
}

Mission _mission(String id, int number, String title) => Mission(
      id: id,
      cocId: id.substring(0, 4),
      missionCode: id.toUpperCase(),
      missionNumber: number,
      title: title,
      missionType: MissionType.identification,
      orderIndex: number,
    );

Future<void> _recoverTestSession() async {
  final expiresAt = DateTime.now().add(const Duration(hours: 1));
  final jwtPart = base64Url.encode(utf8.encode(jsonEncode({
    'exp': expiresAt.millisecondsSinceEpoch ~/ 1000,
    'sub': '4d2583da-8de4-49d3-9cd1-37a9a74f55bd',
    'role': 'authenticated',
  })));
  final accessToken = 'test.$jwtPart.signature';
  await Supabase.instance.client.auth.recoverSession(jsonEncode({
    'access_token': accessToken,
    'expires_in': 3600,
    'refresh_token': 'test-refresh-token',
    'token_type': 'bearer',
    'user': {
      'id': '4d2583da-8de4-49d3-9cd1-37a9a74f55bd',
      'app_metadata': const {
        'provider': 'email',
        'providers': ['email']
      },
      'user_metadata': const {},
      'aud': 'authenticated',
      'email': 'learner@example.com',
      'phone': '',
      'created_at': DateTime.now().toIso8601String(),
      'role': 'authenticated',
    },
  }));
}
