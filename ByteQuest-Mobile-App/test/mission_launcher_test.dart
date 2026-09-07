import 'package:bytequest/models/mission_model.dart';
import 'package:bytequest/screens/simulation/legacy_practice_evidence_scope.dart';
import 'package:bytequest/screens/simulation/mission_launcher.dart';
import 'package:bytequest/screens/simulation/templates/authoritative_mission_assessment_screen.dart';
import 'package:bytequest/screens/simulation/templates/coc1_m2_screen_enhanced.dart';
import 'package:bytequest/screens/simulation/templates/coc1_m3_screen_enhanced.dart';
import 'package:bytequest/screens/simulation/templates/coc2_cable_termination_assessment_screen.dart';
import 'package:bytequest/screens/simulation/templates/configuration_mission_screen.dart';
import 'package:bytequest/screens/simulation/templates/drag_drop_mission_screen.dart';
import 'package:bytequest/screens/simulation/templates/identification_mission_screen.dart';
import 'package:bytequest/screens/simulation/templates/identification_mission_screen_enhanced.dart';
import 'package:bytequest/screens/simulation/templates/step_procedure_mission_screen.dart';
import 'package:bytequest/screens/simulation/templates/troubleshooting_mission_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MissionLauncher.screenFor', () {
    test('restores the intended practice template for every mission', () {
      final expected = <String, Type>{
        'coc1_m1': IdentificationMissionScreenEnhanced,
        'coc1_m2': COC1M2ScreenEnhanced,
        'coc1_m3': COC1M3ScreenEnhanced,
        'coc1_m4': ConfigurationMissionScreen,
        'coc1_m5': StepProcedureMissionScreen,
        'coc2_m1': IdentificationMissionScreenEnhanced,
        'coc2_m2': DragDropMissionScreen,
        'coc2_m3': StepProcedureMissionScreen,
        'coc2_m4': DragDropMissionScreen,
        'coc2_m5': ConfigurationMissionScreen,
        'coc3_m1': IdentificationMissionScreen,
        'coc3_m2': StepProcedureMissionScreen,
        'coc3_m3': ConfigurationMissionScreen,
        'coc3_m4': ConfigurationMissionScreen,
        'coc3_m5': TroubleshootingMissionScreen,
        'coc4_m1': IdentificationMissionScreen,
        'coc4_m2': StepProcedureMissionScreen,
        'coc4_m3': TroubleshootingMissionScreen,
        'coc4_m4': TroubleshootingMissionScreen,
        'coc4_m5': TroubleshootingMissionScreen,
      };

      for (final entry in expected.entries) {
        final screen = MissionLauncher.screenFor(_mission(entry.key));
        expect(screen, isA<LegacyPracticeEvidenceScope>(), reason: entry.key);
        final scope = screen as LegacyPracticeEvidenceScope;
        expect(scope.mission.id, entry.key, reason: entry.key);
        expect(scope.child.runtimeType, entry.value, reason: entry.key);
      }
    });

    test('COC1 M1 keeps the image identification contract', () {
      final scope = MissionLauncher.screenFor(_mission('coc1_m1'))
          as LegacyPracticeEvidenceScope;
      final screen = scope.child as IdentificationMissionScreenEnhanced;

      expect(screen.questions, isNotEmpty);
      expect(screen.hardwareItems, isNotEmpty);
      expect(screen.hardwareItems!.map((item) => item.name),
          containsAll(<String>['Motherboard', 'SSD']));
      expect(screen.questions.map((question) => question.correctAnswer),
          containsAll(<String>['Motherboard', 'SSD']));
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
