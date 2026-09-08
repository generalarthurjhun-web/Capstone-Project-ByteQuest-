import 'package:bytequest/models/mission_model.dart';
import 'package:bytequest/data/mission_simulation_definitions.dart';
import 'package:bytequest/data/missions_data.dart';
import 'package:bytequest/screens/simulation/mission_launcher.dart';
import 'package:bytequest/screens/simulation/mission_simulation_screen.dart';
import 'package:bytequest/screens/simulation/templates/authoritative_mission_assessment_screen.dart';
import 'package:bytequest/screens/simulation/templates/coc2_cable_termination_assessment_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const authoritativeMissionIds = <String>[
    'coc1_m1',
    'coc1_m2',
    'coc1_m3',
    'coc1_m4',
    'coc1_m5',
    'coc2_m1',
    'coc2_m2',
    'coc2_m3',
    'coc2_m4',
    'coc2_m5',
    'coc3_m1',
    'coc3_m2',
    'coc3_m3',
    'coc3_m4',
    'coc3_m5',
    'coc4_m1',
    'coc4_m2',
    'coc4_m3',
    'coc4_m4',
    'coc4_m5',
  ];

  group('MissionLauncher.screenFor', () {
    test(
      'launches the typed production runtime for every practice mission',
      () {
        final expectedIds = authoritativeMissionIds.toSet();

        expect(MissionLauncher.productionRuntimeMissionIds, expectedIds);
        expect(expectedIds, hasLength(20));

        for (final missionId in authoritativeMissionIds) {
          final screen = MissionLauncher.screenFor(_mission(missionId));
          expect(screen, isA<MissionSimulationScreen>(), reason: missionId);
          final runtime = screen as MissionSimulationScreen;
          expect(runtime.mission.id, missionId, reason: missionId);
          expect(runtime.definition.id, missionId, reason: missionId);
          expect(runtime.learnerPayload, isEmpty, reason: missionId);
        }
      },
    );

    test('runtime titles exactly match the authoritative mission catalog', () {
      final catalog = {
        for (final mission in MissionsData.getAllMissions())
          mission.id: mission.title,
      };
      expect(catalog.keys.toSet(), authoritativeMissionIds.toSet());
      for (final missionId in authoritativeMissionIds) {
        expect(
          MissionSimulationDefinitions.byId(missionId).title,
          catalog[missionId],
          reason: missionId,
        );
      }
    });

    test('fails clearly for an unknown mission ID', () {
      expect(
        () => MissionLauncher.screenFor(_mission('coc9_m9')),
        throwsA(isA<ArgumentError>()),
      );
    });

    test(
      'preserves explicit authoritative and cable assessment payload routes',
      () {
        expect(
          MissionLauncher.screenFor(
            _mission('coc1_m1'),
            learnerPayload: const {
              'simulation_template': 'authoritative_mission_v1',
            },
          ),
          isA<AuthoritativeMissionAssessmentScreen>(),
        );
        expect(
          MissionLauncher.screenFor(
            _mission('coc2_m2'),
            learnerPayload: const {
              'simulation_template': 'coc2_cable_termination',
            },
          ),
          isA<Coc2CableTerminationAssessmentScreen>(),
        );
      },
    );

    test('fails closed for an unknown server-provided simulation template', () {
      expect(
        () => MissionLauncher.screenFor(
          _mission('coc1_m2'),
          learnerPayload: const {
            'simulation_template': 'deprecated_client_scoring_template',
          },
        ),
        throwsArgumentError,
      );
    });
  });
}

Mission _mission(String id) {
  final parts = id.split('_m');
  final missionNumber = int.tryParse(parts.length == 2 ? parts[1] : '') ?? 0;
  return Mission(
    id: id,
    cocId: parts.first,
    missionCode: id.toUpperCase(),
    missionNumber: missionNumber,
    title: id,
    missionType: MissionType.identification,
    orderIndex: missionNumber,
  );
}
