import 'package:flutter/material.dart';

import '../../data/mission_simulation_definitions.dart';
import '../../data/mission_content_data.dart';
import '../../models/mission_model.dart';
import 'legacy_practice_evidence_scope.dart';
import 'mission_simulation_screen.dart';
import 'templates/authoritative_mission_assessment_screen.dart';
import 'templates/coc1_m2_screen_enhanced.dart';
import 'templates/coc1_m3_screen_enhanced.dart';
import 'templates/coc2_cable_termination_assessment_screen.dart';
import 'templates/configuration_mission_screen.dart';
import 'templates/drag_drop_mission_screen.dart';
import 'templates/identification_mission_screen.dart';
import 'templates/identification_mission_screen_enhanced.dart';
import 'templates/step_procedure_mission_screen.dart';
import 'templates/troubleshooting_mission_screen.dart';

/// Resolves mission routes without requiring navigation, then launches the
/// resolved screen for production callers.
abstract final class MissionLauncher {
  static Widget screenFor(
    Mission mission, {
    Map<String, dynamic> learnerPayload = const {},
  }) {
    switch (learnerPayload['simulation_template']) {
      case 'authoritative_mission_v1':
        return AuthoritativeMissionAssessmentScreen(
          mission: mission,
          learnerPayload: learnerPayload,
        );
      case 'coc2_cable_termination':
        return Coc2CableTerminationAssessmentScreen(mission: mission);
      case 'coc1_m2_enhanced':
        return COC1M2ScreenEnhanced(mission: mission);
      case 'coc1_m3_enhanced':
        return COC1M3ScreenEnhanced(mission: mission);
    }

    // Practice missions retain their original content/template contracts.
    // Published assessment payloads above remain authoritative and continue
    // to use their dedicated assessment screens.
    switch (mission.id) {
      case 'coc1_m1':
        return _practice(
          mission,
          IdentificationMissionScreenEnhanced(
            mission: mission,
            questions: MissionContentData.getCOC1M1Questions(),
            hardwareItems: MissionContentData.getCOC1M1Items(),
          ),
        );
      case 'coc2_m1':
        return _practice(
          mission,
          IdentificationMissionScreenEnhanced(
            mission: mission,
            questions: MissionContentData.getCOC2M1Questions(),
            hardwareItems: MissionContentData.getCOC2M1Items(),
          ),
        );
      case 'coc3_m1':
        return _practice(
          mission,
          IdentificationMissionScreen(
            mission: mission,
            questions: MissionContentData.getCOC3M1Questions(),
          ),
        );
      case 'coc4_m1':
        return _practice(
          mission,
          IdentificationMissionScreen(
            mission: mission,
            questions: _coc4M1Questions(),
          ),
        );
      case 'coc1_m2':
        return _practice(mission, COC1M2ScreenEnhanced(mission: mission));
      case 'coc1_m3':
        return _practice(mission, COC1M3ScreenEnhanced(mission: mission));
      case 'coc2_m2':
        return _practice(
          mission,
          DragDropMissionScreen(
            mission: mission,
            components: _coc2M2Components(),
            dropZones: _coc2M2DropZones(),
          ),
        );
      case 'coc2_m4':
        return _practice(
          mission,
          DragDropMissionScreen(
            mission: mission,
            components: MissionContentData.getCOC2M4Components(),
            dropZones: _coc2M4DropZones(),
          ),
        );
      case 'coc1_m4':
        return _practice(
          mission,
          ConfigurationMissionScreen(
            mission: mission,
            configData: MissionContentData.getCOC1M4ConfigData(),
          ),
        );
      case 'coc2_m5':
        return _practice(
          mission,
          ConfigurationMissionScreen(
            mission: mission,
            configData: MissionContentData.getCOC2M5ConfigData(),
          ),
        );
      case 'coc3_m3':
        return _practice(
          mission,
          ConfigurationMissionScreen(
            mission: mission,
            configData: _coc3M3ConfigData(),
          ),
        );
      case 'coc3_m4':
        return _practice(
          mission,
          ConfigurationMissionScreen(
            mission: mission,
            configData: _coc3M4ConfigData(),
          ),
        );
      case 'coc1_m5':
        return _practice(
          mission,
          StepProcedureMissionScreen(
            mission: mission,
            steps: MissionContentData.getCOC1M5Steps(),
          ),
        );
      case 'coc2_m3':
        return _practice(
          mission,
          StepProcedureMissionScreen(
            mission: mission,
            steps: MissionContentData.getCOC2M3Steps(),
          ),
        );
      case 'coc3_m2':
        return _practice(
          mission,
          StepProcedureMissionScreen(
            mission: mission,
            steps: MissionContentData.getCOC3M2Steps(),
          ),
        );
      case 'coc4_m2':
        return _practice(
          mission,
          StepProcedureMissionScreen(
            mission: mission,
            steps: MissionContentData.getCOC4M2Steps(),
          ),
        );
      case 'coc3_m5':
        return _practice(
          mission,
          TroubleshootingMissionScreen(
            mission: mission,
            scenarios: _coc3M5Scenarios(),
          ),
        );
      case 'coc4_m3':
        return _practice(
          mission,
          TroubleshootingMissionScreen(
            mission: mission,
            scenarios: _coc4M3Scenarios(),
          ),
        );
      case 'coc4_m4':
        return _practice(
          mission,
          TroubleshootingMissionScreen(
            mission: mission,
            scenarios: _coc4M4Scenarios(),
          ),
        );
      case 'coc4_m5':
        return _practice(
          mission,
          TroubleshootingMissionScreen(
            mission: mission,
            scenarios: _coc4M5Scenarios(),
          ),
        );
    }

    final definition = MissionSimulationDefinitions.byId(mission.id);
    return MissionSimulationScreen(
      mission: mission,
      definition: definition,
      learnerPayload: learnerPayload,
    );
  }

  static Future<void> launch(
    BuildContext context,
    Mission mission, {
    Map<String, dynamic> learnerPayload = const {},
  }) {
    final screen = screenFor(mission, learnerPayload: learnerPayload);
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  static Widget _practice(Mission mission, Widget child) =>
      LegacyPracticeEvidenceScope(mission: mission, child: child);

  static List<MissionQuestion> _coc4M1Questions() {
    final scenarios = MissionContentData.getCOC4M1Scenarios();
    return [
      for (var index = 0; index < scenarios.length; index++)
        MissionQuestion(
          id: 'q${index + 1}',
          question: 'What causes: ${scenarios[index]['symptom']}',
          options: List<String>.from(scenarios[index]['causes'] as List),
          correctAnswer: scenarios[index]['correctCause'] as String,
          explanation:
              'The correct cause is ${scenarios[index]['correctCause']}',
          points: scenarios[index]['points'] as int,
        ),
    ];
  }

  static List<DraggableComponent> _coc2M2Components() {
    final sequence = MissionContentData.getCOC2M2WireSequence();
    return [
      for (var index = 0; index < sequence.length; index++)
        DraggableComponent(
          id: sequence[index].toLowerCase().replaceAll('-', '_'),
          name: sequence[index],
          targetZone: 'pin_${index + 1}',
          description: 'Wire color ${sequence[index]}',
        ),
    ];
  }

  static List<DropZone> _coc2M2DropZones() {
    final sequence = MissionContentData.getCOC2M2WireSequence();
    return [
      for (var index = 0; index < sequence.length; index++)
        DropZone(
          id: 'pin_${index + 1}',
          name: 'Pin ${index + 1}',
          acceptedComponents: [
            sequence[index].toLowerCase().replaceAll('-', '_'),
          ],
        ),
    ];
  }

  static List<DropZone> _coc2M4DropZones() => [
        DropZone(
          id: 'switch_port',
          name: 'Switch port',
          acceptedComponents: ['computer'],
        ),
        DropZone(
          id: 'router_lan',
          name: 'Router LAN port',
          acceptedComponents: ['switch'],
        ),
        DropZone(
          id: 'modem',
          name: 'Modem port',
          acceptedComponents: ['router'],
        ),
      ];

  static Map<String, dynamic> _coc3M3ConfigData() => {
        'staticIP': {
          'question': 'Enter Static IP Address',
          'correctAnswer': '192.168.1.10',
          'validation':
              r'^192\.168\.1\.(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])$',
          'points': 25,
        },
        'subnetMask': {
          'question': 'Enter Subnet Mask',
          'correctAnswer': '255.255.255.0',
          'validation': r'^255\.255\.255\.0$',
          'points': 25,
        },
        'gateway': {
          'question': 'Enter Default Gateway',
          'correctAnswer': '192.168.1.1',
          'validation': r'^192\.168\.1\.1$',
          'points': 25,
        },
        'dns': {
          'question': 'Enter Primary DNS',
          'correctAnswer': '8.8.8.8',
          'validation': r'^8\.8\.8\.8$',
          'points': 25,
        },
      };

  static Map<String, dynamic> _coc3M4ConfigData() => {
        'username': {
          'question': 'Create Username',
          'correctAnswer': 'admin',
          'points': 20,
        },
        'userGroup': {
          'question': 'Assign User Group',
          'correctAnswer': 'Administrators',
          'points': 20,
        },
        'folderName': {
          'question': 'Create Shared Folder Name',
          'correctAnswer': 'SharedFiles',
          'points': 20,
        },
        'permission': {
          'question': 'Set Permission Level (read/write)',
          'correctAnswer': 'write',
          'points': 20,
        },
      };

  static List<Map<String, dynamic>> _coc3M5Scenarios() => [
        _scenario(
            'Client cannot access shared folder', 'Incorrect permissions'),
        _scenario('Cannot connect to server', 'Server IP wrong'),
        _scenario('User cannot login', 'Wrong username/password'),
        _scenario('Server not reachable', 'Network configuration error'),
      ];

  static List<Map<String, dynamic>> _coc4M3Scenarios() => [
        _scenario(
            'Computer beeps and shows no display', 'RAM not seated properly'),
        _scenario('Computer shuts down randomly', 'Overheating CPU'),
        _scenario('Hard drive not detected', 'SATA cable loose'),
        _scenario('System freezes frequently', 'Faulty RAM'),
      ];

  static List<Map<String, dynamic>> _coc4M4Scenarios() => [
        _scenario('No internet but LAN works', 'Router not connected to modem'),
        _scenario('Slow network speed', 'Network congestion'),
        _scenario('Cannot ping gateway', 'Wrong IP configuration'),
        _scenario('Intermittent connection drops', 'Faulty network cable'),
      ];

  static List<Map<String, dynamic>> _coc4M5Scenarios() => [
        _scenario('Printer not printing', 'Driver not installed'),
        _scenario('USB device not recognized', 'USB port damaged'),
        _scenario('Audio not working', 'Audio driver missing'),
        _scenario('Monitor shows no signal', 'Video cable disconnected'),
      ];

  static Map<String, dynamic> _scenario(String symptom, String correctCause) =>
      {
        'symptom': symptom,
        'causes': [
          correctCause,
          'Correct power and connection',
          'Working hardware',
          'No related fault',
        ],
        'correctCause': correctCause,
        'points': 25,
      };
}
