import 'package:bytequest/models/mission_model.dart';
import 'package:bytequest/data/mission_simulation_definitions.dart';
import 'package:bytequest/screens/simulation/mission_launcher.dart';
import 'package:bytequest/screens/simulation/mission_simulation_screen.dart';
import 'package:bytequest/screens/simulation/templates/authoritative_mission_assessment_screen.dart';
import 'package:bytequest/screens/simulation/templates/coc2_cable_termination_assessment_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MissionLauncher.screenFor', () {
    test(
      'launches the typed production runtime for every practice mission',
      () {
        final expectedIds = MissionSimulationDefinitions.all
            .map((definition) => definition.id)
            .toSet();

        expect(MissionLauncher.productionRuntimeMissionIds, expectedIds);
        expect(expectedIds, hasLength(20));

        for (final missionId in expectedIds) {
          final screen = MissionLauncher.screenFor(_mission(missionId));
          expect(screen, isA<MissionSimulationScreen>(), reason: missionId);
          final runtime = screen as MissionSimulationScreen;
          expect(runtime.mission.id, missionId, reason: missionId);
          expect(runtime.definition.id, missionId, reason: missionId);
          expect(runtime.learnerPayload, isEmpty, reason: missionId);
        }
      },
    );

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

    test(
        'retains opt-in adapters for protected legacy practice screens', () {});

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
