import 'package:bytequest/models/mission_model.dart';
import 'package:bytequest/screens/simulation/templates/authoritative_mission_assessment_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final mission = Mission(
    id: 'coc1_m2',
    cocId: 'coc1',
    missionCode: 'coc1_m2',
    missionNumber: 2,
    title: 'Install Internal Components',
    missionType: MissionType.dragAndDrop,
    orderIndex: 2,
  );

  final payload = <String, dynamic>{
    'simulation_template': 'authoritative_mission_v1',
    'assessment_package_id': 'coc1-m2-authoritative-v1',
    'local_mission_code': 'COC1-M2',
    'unit_code': 'ELC724331',
    'unit_title': 'Install and Configure Computer Systems',
    'stages': [
      {
        'id': 'placement',
        'criterion_code': 'COC1-M2-03-COMPONENT-PLACEMENT',
        'type': 'matching',
        'title': 'Place the components',
        'instruction': 'Match each component to its destination.',
        'action_type': 'coc1_m2_placement_submitted',
        'required_count': 2,
        'fields': [
          {
            'id': 'cpu',
            'label': 'Processor',
            'options': [
              {'id': 'cpu_socket', 'label': 'Processor socket'},
              {'id': 'dimm_slot', 'label': 'DIMM slot'},
            ],
          },
          {
            'id': 'memory',
            'label': 'Memory module',
            'options': [
              {'id': 'dimm_slot', 'label': 'DIMM slot'},
              {'id': 'cpu_socket', 'label': 'Processor socket'},
            ],
          },
        ],
      },
    ],
  };

  Widget app({double textScale = 1}) => MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: AuthoritativeMissionAssessmentScreen(
          mission: mission,
          learnerPayload: payload,
        ),
      );

  testWidgets('authoritative workspace stays usable at compact and large sizes',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    for (final size in <Size>[
      const Size(320, 568),
      const Size(568, 320),
      const Size(800, 1280),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(app());
      await tester.pump();

      expect(tester.takeException(), isNull,
          reason: 'The authoritative workspace must not overflow at $size.');
      expect(find.text('Place the components'), findsOneWidget);
      expect(find.text('Review before submission'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });

  testWidgets('workspace exposes accessible connection controls',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app());
    await tester.pump();

    final cpu = find.byKey(const ValueKey('assessment-match-source-cpu'));
    final socket = find.byKey(
      const ValueKey('assessment-match-destination-cpu_socket'),
    );
    expect(cpu, findsOneWidget);
    expect(socket, findsOneWidget);
    expect(tester.getSize(cpu).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(socket).height, greaterThanOrEqualTo(64));

    final memory = find.byKey(
      const ValueKey('assessment-match-source-memory'),
    );
    final dimm = find.byKey(
      const ValueKey('assessment-match-destination-dimm_slot'),
    );
    expect(memory, findsOneWidget);
    expect(dimm, findsOneWidget);
    expect(tester.getSize(memory).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(dimm).height, greaterThanOrEqualTo(64));

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('large text remains scrollable without render overflow',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app(textScale: 1.8));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
