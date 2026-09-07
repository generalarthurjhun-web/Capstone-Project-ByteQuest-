import 'package:bytequest/screens/simulation/components/mission_simulation_profile.dart';
import 'package:bytequest/screens/simulation/components/simulation_framework.dart';
import 'package:bytequest/screens/simulation/templates/authoritative_mission_contract.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all twenty mission profiles have stable technical scene metadata', () {
    for (var coc = 1; coc <= 4; coc++) {
      for (var mission = 1; mission <= 5; mission++) {
        final profile = MissionSimulationProfile.forMission(
          'COC$coc-M$mission',
        );
        expect(profile.missionCode, 'coc${coc}_m$mission');
        expect(profile.environmentTitle, isNotEmpty);
        expect(profile.scenarioPrompt, isNotEmpty);
        expect(profile.sceneObjects.length, greaterThanOrEqualTo(3));
        for (final object in profile.sceneObjects) {
          expect(object.position.dx, inInclusiveRange(0, 1));
          expect(object.position.dy, inInclusiveRange(0, 1));
        }
      }
    }
  });

  test('stage presentation vocabulary is technical and deterministic', () {
    expect(
      presentationForStage(_stage(AuthoritativeStageType.matching)),
      SimulationPresentationKind.connection,
    );
    expect(
      presentationForStage(_stage(AuthoritativeStageType.configuration)),
      SimulationPresentationKind.configuration,
    );
    expect(
      presentationForStage(_stage(AuthoritativeStageType.sequence)),
      SimulationPresentationKind.procedure,
    );
    expect(
      presentationForStage(
        _stage(
          AuthoritativeStageType.singleChoice,
          id: 'diagnose_fault',
        ),
      ),
      SimulationPresentationKind.troubleshooting,
    );
    expect(
      presentationForStage(
        _stage(
          AuthoritativeStageType.singleChoice,
          id: 'interpret_test_result',
        ),
      ),
      SimulationPresentationKind.testing,
    );
  });

  testWidgets('scene hotspots are accessible, responsive, and neutral',
      (tester) async {
    final inspected = <String>{};
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => SizedBox(
              width: 360,
              child: SimulationScene(
                profile: MissionSimulationProfile.forMission('coc2_m5'),
                inspectedObjectIds: inspected,
                enabled: true,
                onObjectSelected: (id) => setState(() => inspected.add(id)),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('simulation-object-client')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(inspected, contains('client'));
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('matching supports drag and accessible source destination input',
      (tester) async {
    tester.view.physicalSize = const Size(500, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: _PlacementHarness()));
    final sourceA = find.byKey(const ValueKey('assessment-match-source-a'));
    final targetA =
        find.byKey(const ValueKey('assessment-match-destination-port_a'));
    await tester.drag(
        sourceA, tester.getCenter(targetA) - tester.getCenter(sourceA));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('1 of 2 connections recorded'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('assessment-match-source-b')));
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('assessment-match-destination-port_b')),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('2 of 2 connections recorded'), findsOneWidget);
  });

  testWidgets('reduced motion and large text keep controls available',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            disableAnimations: true,
            textScaler: TextScaler.linear(1.8),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              child: MultiSelectInspection(
                stage: _stage(AuthoritativeStageType.selection),
                selectedItems: const {},
                writing: false,
                onChanged: (_, __) {},
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('inspection-option-a')), findsOneWidget);
  });

  testWidgets('tool selection and multi-select inspection update feedback',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: _SelectionHarness(toolMode: true)),
    );
    await tester.tap(find.byKey(const ValueKey('tool-option-a')));
    await tester.pump();
    expect(find.text('1 of 2 resources prepared'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: _SelectionHarness(
          key: ValueKey('inspection-harness'),
          toolMode: false,
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('inspection-option-b')));
    await tester.pump();
    expect(find.text('1 of 2 observations selected'), findsOneWidget);
  });

  testWidgets('sequence records a chronological evidence timeline',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: _SequenceHarness()),
    );
    await tester.tap(find.byKey(const ValueKey('sequence-option-a')));
    await tester.pump();
    expect(find.text('1 of 2 actions recorded'), findsOneWidget);
    expect(find.text('Chronological evidence saved'), findsNothing,
        reason: 'The upgraded timeline uses concise learner-facing labels.');
    expect(find.text('Option A'), findsWidgets);
  });

  testWidgets('configuration applies fields without leaking expected values',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: _ConfigurationHarness()),
    );
    final first = tester.widget<DropdownButtonFormField<String>>(
      find.byKey(const ValueKey('configuration-field-a')),
    );
    first.onChanged?.call('port_a');
    await tester.pump();
    expect(find.text('1 of 2 values applied'), findsOneWidget);
    expect(find.textContaining('correct'), findsNothing);
  });

  testWidgets('troubleshooting requires symptom inspection before decision',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: _TroubleshootingHarness()),
    );
    final decision = find.byKey(const ValueKey('decision-option-a'));
    expect(
      tester
          .widget<InkWell>(
            find.descendant(of: decision, matching: find.byType(InkWell)),
          )
          .onTap,
      isNull,
    );
    await tester.tap(find.text('Inspect symptom state'));
    await tester.pump();
    expect(find.textContaining('Continue with your diagnosis'), findsOneWidget);
    await tester.tap(decision);
    await tester.pump();
    expect(find.byIcon(Icons.check_circle_rounded), findsWidgets);
  });
}

AuthoritativeMissionStage _stage(
  AuthoritativeStageType type, {
  String id = 'stage',
}) {
  const options = [
    AuthoritativeStageOption(id: 'a', label: 'Option A'),
    AuthoritativeStageOption(id: 'b', label: 'Option B'),
  ];
  const fields = [
    AuthoritativeStageField(
      id: 'a',
      label: 'Source A',
      options: [
        AuthoritativeStageOption(id: 'port_a', label: 'Port A'),
        AuthoritativeStageOption(id: 'port_b', label: 'Port B'),
      ],
    ),
    AuthoritativeStageField(
      id: 'b',
      label: 'Source B',
      options: [
        AuthoritativeStageOption(id: 'port_a', label: 'Port A'),
        AuthoritativeStageOption(id: 'port_b', label: 'Port B'),
      ],
    ),
  ];
  return AuthoritativeMissionStage(
    id: id,
    criterionCode: 'criterion',
    type: type,
    title: 'Technical activity',
    instruction: 'Use the simulated environment to record evidence.',
    actionType: id,
    requiredCount: type == AuthoritativeStageType.singleChoice ? 1 : 2,
    options: options,
    fields: type == AuthoritativeStageType.configuration ||
            type == AuthoritativeStageType.matching
        ? fields
        : const [],
  );
}

class _PlacementHarness extends StatefulWidget {
  const _PlacementHarness();

  @override
  State<_PlacementHarness> createState() => _PlacementHarnessState();
}

class _PlacementHarnessState extends State<_PlacementHarness> {
  final values = <String, String>{};
  String? selected;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ComponentPlacement(
            stage: _stage(AuthoritativeStageType.matching),
            selectedMatchField: selected,
            fieldValues: values,
            writing: false,
            onFieldSelected: (field, value) =>
                setState(() => values[field] = value),
            onSourceSelected: (value) => setState(() => selected = value),
            onDestinationSelected: (destination) {
              final source = selected;
              if (source == null) return;
              setState(() {
                values[source] = destination;
                selected = null;
              });
            },
          ),
        ),
      );
}

class _SelectionHarness extends StatefulWidget {
  final bool toolMode;

  const _SelectionHarness({super.key, required this.toolMode});

  @override
  State<_SelectionHarness> createState() => _SelectionHarnessState();
}

class _SelectionHarnessState extends State<_SelectionHarness> {
  final selected = <String>{};

  @override
  Widget build(BuildContext context) => Scaffold(
        body: widget.toolMode
            ? ToolPalette(
                stage: _stage(AuthoritativeStageType.selection),
                selectedItems: selected,
                writing: false,
                onChanged: _change,
              )
            : MultiSelectInspection(
                stage: _stage(AuthoritativeStageType.selection),
                selectedItems: selected,
                writing: false,
                onChanged: _change,
              ),
      );

  void _change(String id, bool value) => setState(() {
        if (value) {
          selected.add(id);
        } else {
          selected.remove(id);
        }
      });
}

class _SequenceHarness extends StatefulWidget {
  const _SequenceHarness();

  @override
  State<_SequenceHarness> createState() => _SequenceHarnessState();
}

class _SequenceHarnessState extends State<_SequenceHarness> {
  final sequence = <String>[];

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SequenceActivity(
          stage: _stage(AuthoritativeStageType.sequence),
          sequence: sequence,
          writing: false,
          onSelected: (id) async => setState(() => sequence.add(id)),
        ),
      );
}

class _ConfigurationHarness extends StatefulWidget {
  const _ConfigurationHarness();

  @override
  State<_ConfigurationHarness> createState() => _ConfigurationHarnessState();
}

class _ConfigurationHarnessState extends State<_ConfigurationHarness> {
  final values = <String, String>{};

  @override
  Widget build(BuildContext context) => Scaffold(
        body: ConfigurationPanel(
          stage: _stage(AuthoritativeStageType.configuration),
          fieldValues: values,
          writing: false,
          onFieldSelected: (field, value) =>
              setState(() => values[field] = value),
        ),
      );
}

class _TroubleshootingHarness extends StatefulWidget {
  const _TroubleshootingHarness();

  @override
  State<_TroubleshootingHarness> createState() =>
      _TroubleshootingHarnessState();
}

class _TroubleshootingHarnessState extends State<_TroubleshootingHarness> {
  bool inspected = false;
  String? selected;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: TroubleshootingFlow(
          stage: _stage(
            AuthoritativeStageType.singleChoice,
            id: 'diagnose_fault',
          ),
          selectedItems: const {},
          selectedOption: selected,
          writing: false,
          inspected: inspected,
          onInspect: () async => setState(() => inspected = true),
          onSelectionChanged: (_, __) {},
          onSingleSelected: (value) => setState(() => selected = value),
        ),
      );
}
