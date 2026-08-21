import 'package:bytequest/models/mission_model.dart';
import 'package:bytequest/screens/simulation/mission_launcher.dart';
import 'package:bytequest/screens/simulation/mission_simulation_screen.dart';
import 'package:bytequest/screens/simulation/templates/authoritative_mission_assessment_screen.dart';
import 'package:bytequest/screens/simulation/templates/coc1_m2_screen_enhanced.dart';
import 'package:bytequest/screens/simulation/templates/coc1_m3_screen_enhanced.dart';
import 'package:bytequest/screens/simulation/templates/coc2_cable_termination_assessment_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MissionLauncher.screenFor', () {
    test('resolves all twenty catalog IDs through the simulation runtime', () {
      for (var coc = 1; coc <= 4; coc++) {
        for (var number = 1; number <= 5; number++) {
          final id = 'coc${coc}_m$number';
          final screen = MissionLauncher.screenFor(_mission(id));

          expect(screen, isA<MissionSimulationScreen>(), reason: id);
          expect(
            (screen as MissionSimulationScreen).definition.id,
            id,
            reason: id,
          );
        }
      }
    });

    test('fails clearly for an unknown mission ID', () {
      expect(
        () => MissionLauncher.screenFor(_mission('coc9_m9')),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('preserves explicit authoritative and cable assessment payload routes',
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
    });

    test('retains opt-in adapters for protected legacy practice screens', () {
      expect(
        MissionLauncher.screenFor(
          _mission('coc1_m2'),
          learnerPayload: const {
            'simulation_template': 'coc1_m2_enhanced',
          },
        ),
        isA<COC1M2ScreenEnhanced>(),
      );
      expect(
        MissionLauncher.screenFor(
          _mission('coc1_m3'),
          learnerPayload: const {
            'simulation_template': 'coc1_m3_enhanced',
          },
        ),
        isA<COC1M3ScreenEnhanced>(),
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
