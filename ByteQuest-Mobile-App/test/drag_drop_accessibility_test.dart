import 'dart:ui' show SemanticsAction;

import 'package:bytequest/models/mission_model.dart';
import 'package:bytequest/core/widgets/simulation_fullscreen_button.dart';
import 'package:bytequest/screens/simulation/templates/coc1_m2_screen_enhanced.dart';
import 'package:bytequest/screens/simulation/templates/drag_drop_mission_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'sb_publishable_test_key',
    );
  });

  testWidgets('drop zones provide a forgiving mobile hit area', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mission = Mission(
      id: 'practice-drag-test',
      cocId: 'practice-coc',
      missionCode: 'practice_drag_test',
      missionNumber: 1,
      title: 'Practice component placement',
      missionType: MissionType.dragAndDrop,
      orderIndex: 1,
      xpReward: 0,
      pointsReward: 0,
      passingScore: 0,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DragDropMissionScreen(
          mission: mission,
          components: [
            DraggableComponent(
              id: 'component-a',
              name: 'Component A',
              targetZone: 'zone-a',
            ),
          ],
          dropZones: [
            DropZone(
              id: 'zone-a',
              name: 'Installation area',
              acceptedComponents: const ['component-a'],
            ),
          ],
        ),
      ),
    );

    final target = find.byKey(const ValueKey('drop-zone-zone-a'));
    expect(target, findsOneWidget);

    final targetSize = tester.getSize(target);
    expect(targetSize.height, greaterThanOrEqualTo(96));
    expect(targetSize.width, greaterThanOrEqualTo(300));

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('drag task supports an equivalent select-then-place interaction',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mission = Mission(
      id: 'assessment-select-place-test',
      cocId: 'test-coc',
      missionCode: 'assessment_select_place_test',
      missionNumber: 1,
      title: 'Assessment placement',
      missionType: MissionType.dragAndDrop,
      orderIndex: 1,
      xpReward: 0,
      pointsReward: 0,
      passingScore: 0,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DragDropMissionScreen(
          mission: mission,
          components: [
            DraggableComponent(
              id: 'component-a',
              name: 'Component A',
              targetZone: 'zone-a',
            ),
          ],
          dropZones: [
            DropZone(
              id: 'zone-a',
              name: 'Practice installation area',
              acceptedComponents: const ['component-a'],
            ),
          ],
        ),
      ),
    );

    expect(find.text('Practice installation area'), findsOneWidget);
    Finder declaredSemantics(String label) => find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.label == label,
        );
    expect(
        declaredSemantics('Practice installation area, empty'), findsOneWidget);

    await tester.tap(declaredSemantics('Component A'));
    await tester.pump();
    expect(declaredSemantics('Component A, selected'), findsOneWidget);

    await tester.tap(declaredSemantics('Practice installation area, empty'));
    await tester.pump();
    expect(declaredSemantics('Component A, already placed'), findsOneWidget);
    expect(
      declaredSemantics(
        'Practice installation area, contains Component A',
      ),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'compact cable pins expose connection state and TalkBack place/remove actions',
      (tester) async {
    await tester.pumpWidget(_compactCableHarness());
    await tester.pump();

    Finder declaredSemantics(String label) => find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.label == label,
        );

    final emptyPin = declaredSemantics('Pin 1, empty');
    expect(emptyPin, findsOneWidget);
    final pinSize =
        tester.getSize(find.byKey(const ValueKey('drop-zone-pin_1')));
    expect(pinSize.width, greaterThanOrEqualTo(48));
    expect(pinSize.height, greaterThanOrEqualTo(48));

    final wire = declaredSemantics('Orange-white wire');
    await tester.ensureVisible(wire);
    await tester.pump();
    await tester.tap(wire);
    await tester.pump();
    await tester.ensureVisible(emptyPin);
    await tester.pump();
    await tester.tap(emptyPin);
    await tester.pump();

    final connectedPin =
        declaredSemantics('Pin 1, connected to Orange-white wire');
    expect(connectedPin, findsOneWidget);
    expect(
      tester.getSemantics(connectedPin).getSemanticsData().hasAction(
            SemanticsAction.longPress,
          ),
      isTrue,
    );

    await tester.longPress(connectedPin);
    await tester.pump();
    expect(declaredSemantics('Pin 1, empty'), findsOneWidget);
  });

  testWidgets(
      'compact cable validation uses icons and text but hides correctness in assessment mode',
      (tester) async {
    Finder declaredSemantics(String label) => find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.label == label,
        );

    await tester.pumpWidget(_compactCableHarness());
    await tester.pump();
    for (var index = 1; index <= 8; index++) {
      final wire = declaredSemantics(_wireName(index));
      await tester.ensureVisible(wire);
      await tester.pump();
      await tester.tap(wire);
      await tester.pump();
      final pin = declaredSemantics('Pin $index, empty');
      await tester.ensureVisible(pin);
      await tester.pump();
      await tester.tap(pin);
      await tester.pump();
    }
    await tester.tap(find.text('Check Placements'));
    await tester.pump();
    expect(
      declaredSemantics(
          'Pin 1, connected to Orange-white wire, correct connection'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.check_circle), findsWidgets);
    expect(find.text('Correct'), findsWidgets);

    await tester.pumpWidget(_compactCableHarness(assessmentMode: true));
    await tester.pump();
    for (var index = 1; index <= 8; index++) {
      final wire = declaredSemantics(_wireName(index));
      await tester.ensureVisible(wire);
      await tester.pump();
      await tester.tap(wire);
      await tester.pump();
      final pin = declaredSemantics('Pin $index, empty');
      await tester.ensureVisible(pin);
      await tester.pump();
      await tester.tap(pin);
      await tester.pump();
    }
    await tester.tap(find.text('Check Placements'));
    await tester.pump();
    expect(
      find.bySemanticsLabel(RegExp(r'correct|incorrect connection')),
      findsNothing,
    );
    expect(find.text('Correct'), findsNothing);
  });

  testWidgets('full-screen control is explicit, semantic, and reversible',
      (tester) async {
    final platformCalls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        platformCalls.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: SimulationFullscreenButton()),
        ),
      ),
    );

    final control = find.byKey(const ValueKey('simulation-fullscreen-button'));
    expect(control, findsOneWidget);
    expect(tester.getSize(control).width, greaterThanOrEqualTo(48));
    expect(tester.getSize(control).height, greaterThanOrEqualTo(48));
    expect(
      find.bySemanticsLabel('Enter full-screen simulation'),
      findsOneWidget,
    );

    await tester.tap(control);
    await tester.pump();
    expect(
      find.bySemanticsLabel('Exit full-screen simulation'),
      findsOneWidget,
    );

    await tester.tap(control);
    await tester.pump();
    expect(
      find.bySemanticsLabel('Enter full-screen simulation'),
      findsOneWidget,
    );
    expect(
      platformCalls
          .where((call) => call.method == 'SystemChrome.setEnabledSystemUIMode')
          .length,
      2,
    );
  });

  testWidgets(
      'enhanced installation targets remain usable across representative sizes',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    final mission = Mission(
      id: 'coc1_m2',
      cocId: 'coc1',
      missionCode: 'coc1_m2',
      missionNumber: 2,
      title: 'Install Internal Components',
      missionType: MissionType.dragAndDrop,
      orderIndex: 2,
      xpReward: 0,
      pointsReward: 0,
      passingScore: 0,
    );

    for (final size in <Size>[
      const Size(320, 568),
      const Size(568, 320),
      const Size(800, 1280),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MaterialApp(home: COC1M2ScreenEnhanced(mission: mission)),
      );
      await tester.pump();

      expect(tester.takeException(), isNull,
          reason: 'The simulation must not overflow at $size.');
      for (final zoneId in <String>[
        'motherboard_area',
        'cpu_socket',
        'ram_slot',
        'drive_bay',
        'fan_area',
        'psu_bay',
      ]) {
        final target = find.byKey(ValueKey('drop-target-$zoneId'));
        expect(target, findsOneWidget,
            reason: 'Missing target $zoneId at $size.');
        final targetSize = tester.getSize(target);
        expect(targetSize.width, greaterThanOrEqualTo(48),
            reason: '$zoneId is too narrow at $size.');
        expect(targetSize.height, greaterThanOrEqualTo(48),
            reason: '$zoneId is too short at $size.');
      }

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });
}

Widget _compactCableHarness({bool assessmentMode = false}) {
  final components = [
    for (var index = 1; index <= 8; index++)
      DraggableComponent(
        id: 'wire_$index',
        name: _wireName(index),
        targetZone: 'pin_$index',
      ),
  ];
  return MaterialApp(
    home: DragDropMissionScreen(
      key: ValueKey('compact-cable-$assessmentMode'),
      mission: Mission(
        id: 'coc2_m2',
        cocId: 'coc2',
        missionCode: 'COC2-M2',
        missionNumber: 2,
        title: 'Create Network Cables',
        missionType: MissionType.dragAndDrop,
        orderIndex: 2,
      ),
      components: components,
      dropZones: [
        for (var index = 1; index <= 8; index++)
          DropZone(
            id: 'pin_$index',
            name: 'Pin $index',
            acceptedComponents: ['wire_$index'],
          ),
      ],
      assessmentModeOverride: assessmentMode,
    ),
  );
}

String _wireName(int index) => switch (index) {
      1 => 'Orange-white wire',
      2 => 'Orange wire',
      3 => 'Green-white wire',
      4 => 'Blue wire',
      5 => 'Blue-white wire',
      6 => 'Green wire',
      7 => 'Brown-white wire',
      8 => 'Brown wire',
      _ => 'Wire $index',
    };
