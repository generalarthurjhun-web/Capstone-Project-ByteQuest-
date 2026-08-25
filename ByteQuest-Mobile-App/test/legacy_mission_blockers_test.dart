import 'package:bytequest/core/widgets/step_progress_card.dart';
import 'package:bytequest/data/mission_content_data.dart';
import 'package:bytequest/models/mission_model.dart';
import 'package:bytequest/screens/simulation/templates/coc1_m2_screen_enhanced.dart';
import 'package:bytequest/screens/simulation/templates/coc1_m3_screen_enhanced.dart';
import 'package:bytequest/screens/simulation/templates/configuration_mission_screen.dart';
import 'package:bytequest/screens/simulation/templates/step_procedure_mission_screen.dart';
import 'package:bytequest/services/progress_resume_service.dart';
import 'package:flutter/material.dart';
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

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('all four step missions restore chronological completion order',
      () async {
    for (final missionId in const [
      'coc1_m5',
      'coc2_m3',
      'coc3_m2',
      'coc4_m2',
    ]) {
      const progress = StepProcedureProgress(
        timeSpent: 42,
        correctSteps: 0,
        mistakes: [],
        completedSteps: ['step1', 'step2', 'step3'],
        completionOrder: ['step1', 'step2', 'step3'],
      );

      expect(
        await ProgressResumeService.saveState(
          userId: 'learner-restore-test',
          missionId: missionId,
          cocId: missionId.substring(0, 4),
          currentStep: 3,
          totalSteps: 4,
          stateData: progress.toStateData(),
        ),
        isTrue,
      );

      final stored = await ProgressResumeService.loadState(
        userId: 'learner-restore-test',
        missionId: missionId,
      );
      final reopened = StepProcedureProgress.fromStateData(
        Map<String, dynamic>.from(stored!['stateData'] as Map),
      );

      expect(reopened.completedSteps, ['step1', 'step2', 'step3']);
      expect(reopened.completionOrder, ['step1', 'step2', 'step3']);
    }
  });

  test('legacy step snapshots recover order from insertion-ordered steps', () {
    final reopened = StepProcedureProgress.fromStateData({
      'timeSpent': 8,
      'correctSteps': 0,
      'mistakes': <String>[],
      'completedSteps': ['step2', 'step1'],
    });

    expect(reopened.completionOrder, ['step2', 'step1']);
  });

  test('intentional exit clears progress while interruption keeps it',
      () async {
    const userId = 'learner-exit-boundary';
    const missionId = 'coc2_m5';

    Future<void> saveInterruptionSnapshot() => ProgressResumeService.saveState(
          userId: userId,
          missionId: missionId,
          cocId: 'coc2',
          currentStep: 2,
          totalSteps: 5,
          stateData: const {'configured': true},
        );

    await saveInterruptionSnapshot();
    expect(
      await ProgressResumeService.loadState(
        userId: userId,
        missionId: missionId,
      ),
      isNotNull,
      reason: 'An interruption must retain the local snapshot.',
    );

    expect(
      await ProgressResumeService.clearState(
        userId: userId,
        missionId: missionId,
      ),
      isTrue,
    );
    expect(
      await ProgressResumeService.loadState(
        userId: userId,
        missionId: missionId,
      ),
      isNull,
      reason: 'An intentional exit must discard the local snapshot.',
    );
  });

  test('COC1 M4 authoritative content can evaluate all three fields', () {
    final config = MissionContentData.getCOC1M4ConfigData();

    expect(config['detectedHardware']['correctAnswer'],
        'CPU, RAM, Storage, Network Card');
    expect(
      config['osInstallation']['correctAnswer'],
      'Select language and keyboard, Accept license agreement, '
      'Choose installation type, Select partition/drive, '
      'Begin installation, Set up user account, Complete setup',
    );

    final result = evaluateConfigurationFields(config, const {
      'bootPriority': 'Hard Drive',
      'detectedHardware': 'CPU, RAM, Storage, Network Card',
      'osInstallation':
          'Select language and keyboard, Accept license agreement, '
              'Choose installation type, Select partition/drive, '
              'Begin installation, Set up user account, Complete setup',
    });

    expect(result.correctFields, 3);
    expect(result.fieldValidation.values, everyElement(isTrue));
    expect(result.mistakes, isEmpty);
  });

  testWidgets('COC1 M4 shows a learner-facing OS installation label',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ConfigurationMissionScreen(
          mission: _mission('coc1_m4', 4),
          configData: MissionContentData.getCOC1M4ConfigData(),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.text(
        'Configure BIOS settings correctly and follow the proper sequence '
        'for operating system installation.',
      ),
      findsOneWidget,
    );
    expect(find.text('osInstallation'), findsNothing);
  });

  testWidgets('COC1 M2 terminal progress never displays step 7 of 6',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1280);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: COC1M2ScreenEnhanced(mission: _mission('coc1_m2', 2))),
    );
    await tester.pump();

    for (final placement in const [
      ('motherboard', 'motherboard_area'),
      ('cpu', 'cpu_socket'),
      ('ram', 'ram_slot'),
      ('ssd', 'drive_bay'),
      ('cooling_fan', 'fan_area'),
      ('psu', 'psu_bay'),
    ]) {
      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is Draggable<String> && widget.data == placement.$1,
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(ValueKey('drop-target-${placement.$2}')));
      await tester.pump();
    }

    final progress = tester.widget<StepProgressCard>(
      find.byType(StepProgressCard),
    );
    expect(progress.currentStep, 6);
    expect(find.text('Step 7 of 6'), findsNothing);
    expect(find.text('Step 6 of 6'), findsOneWidget);
  });

  testWidgets('COC1 M3 keeps workspace controls visible at 640x320',
      (tester) async {
    tester.view.physicalSize = const Size(640, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: COC1M3ScreenEnhanced(mission: _mission('coc1_m3', 3))),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Finish Mission'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName.endsWith('System Unit.png'),
      ),
      findsOneWidget,
    );
    expect(find.text('Drag a cable to the correct connection'), findsOneWidget);
  });
}

Mission _mission(String id, int number) => Mission(
      id: id,
      cocId: 'coc1',
      missionCode: id,
      missionNumber: number,
      title: id == 'coc1_m2'
          ? 'Install Internal Components'
          : 'Connect Power and Data Cables',
      missionType: MissionType.dragAndDrop,
      orderIndex: number,
      xpReward: 0,
      pointsReward: 0,
      passingScore: 0,
    );
