import 'package:flutter/material.dart';
import '../../models/mission_model.dart';
import '../../data/mission_content_data.dart';
import 'templates/identification_mission_screen.dart';
import 'templates/identification_mission_screen_enhanced.dart';
import 'templates/drag_drop_mission_screen.dart';
import 'templates/configuration_mission_screen.dart';
import 'templates/step_procedure_mission_screen.dart';
import 'templates/troubleshooting_mission_screen.dart';
import 'templates/coc1_m2_screen_enhanced.dart';
import 'templates/coc1_m3_screen_enhanced.dart';
import 'templates/coc2_cable_termination_assessment_screen.dart';
import 'templates/authoritative_mission_assessment_screen.dart';

/// Mission Launcher
/// Routes to the appropriate simulation template based on mission type
class MissionLauncher {
  static Future<void> launch(
    BuildContext context,
    Mission mission, {
    Map<String, dynamic> learnerPayload = const {},
  }) async {
    Widget? screen;

    if (learnerPayload['simulation_template'] == 'coc2_cable_termination') {
      screen = Coc2CableTerminationAssessmentScreen(mission: mission);
    }
    if (learnerPayload['simulation_template'] == 'authoritative_mission_v1') {
      screen = AuthoritativeMissionAssessmentScreen(
        mission: mission,
        learnerPayload: learnerPayload,
      );
    }

    switch (screen == null ? mission.missionType : null) {
      case MissionType.identification:
        screen = _launchIdentificationMission(mission);
        break;
      case MissionType.dragAndDrop:
        screen = _launchDragDropMission(mission);
        break;
      case MissionType.configurationForm:
        screen = _launchConfigurationMission(mission);
        break;
      case MissionType.stepProcedure:
        screen = _launchStepProcedureMission(mission);
        break;
      case MissionType.troubleshooting:
        screen = _launchTroubleshootingMission(mission);
        break;
      case MissionType.checklist:
      case MissionType.matching:
        // Not yet implemented - fall through to null
        break;
      case null:
        break;
    }

    if (screen != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => screen!),
      );
    }
  }

  static Widget _launchIdentificationMission(Mission mission) {
    List<MissionQuestion> questions;
    List<HardwareItem>? hardwareItems;

    switch (mission.id) {
      case 'coc1_m1':
        questions = MissionContentData.getCOC1M1Questions();
        hardwareItems = MissionContentData.getCOC1M1Items();
        return IdentificationMissionScreenEnhanced(
          mission: mission,
          questions: questions,
          hardwareItems: hardwareItems,
        );
      case 'coc2_m1':
        questions = MissionContentData.getCOC2M1Questions();
        hardwareItems = MissionContentData.getCOC2M1Items();
        return IdentificationMissionScreenEnhanced(
          mission: mission,
          questions: questions,
          hardwareItems: hardwareItems,
        );
      case 'coc3_m1':
        questions = MissionContentData.getCOC3M1Questions();
        break;
      case 'coc4_m1':
        questions = _convertScenariosToCOC4M1Questions();
        break;
      default:
        questions = MissionContentData.getCOC1M1Questions();
        hardwareItems = MissionContentData.getCOC1M1Items();
    }

    return IdentificationMissionScreen(
      mission: mission,
      questions: questions,
      hardwareItems: hardwareItems,
    );
  }

  static Widget _launchDragDropMission(Mission mission) {
    // Special handling for COC1 M2 - Enhanced image-based simulation
    if (mission.id == 'coc1_m2') {
      return COC1M2ScreenEnhanced(mission: mission);
    }

    // Special handling for COC1 M3 - Enhanced cable matching simulation
    if (mission.id == 'coc1_m3') {
      return COC1M3ScreenEnhanced(mission: mission);
    }

    // Other drag-drop missions use generic template
    List<DraggableComponent> components;
    List<DropZone> dropZones;

    switch (mission.id) {
      case 'coc1_m2':
        components = MissionContentData.getCOC1M2Components();
        dropZones = MissionContentData.getCOC1M2DropZones();
        break;
      case 'coc1_m3':
        components = MissionContentData.getCOC1M3Components();
        dropZones = MissionContentData.getCOC1M3DropZones();
        break;
      case 'coc2_m2':
        components = _createCOC2M2Components();
        dropZones = _createCOC2M2DropZones();
        break;
      case 'coc2_m4':
        components = MissionContentData.getCOC2M4Components();
        dropZones = _createCOC2M4DropZones();
        break;
      default:
        components = MissionContentData.getCOC1M2Components();
        dropZones = MissionContentData.getCOC1M2DropZones();
    }

    return DragDropMissionScreen(
      mission: mission,
      components: components,
      dropZones: dropZones,
    );
  }

  static Widget _launchConfigurationMission(Mission mission) {
    Map<String, dynamic> configData;

    switch (mission.id) {
      case 'coc1_m4':
        configData = MissionContentData.getCOC1M4ConfigData();
        break;
      case 'coc2_m5':
        configData = MissionContentData.getCOC2M5ConfigData();
        break;
      case 'coc3_m3':
        configData = _createCOC3M3ConfigData();
        break;
      case 'coc3_m4':
        configData = _createCOC3M4ConfigData();
        break;
      default:
        configData = MissionContentData.getCOC2M5ConfigData();
    }

    return ConfigurationMissionScreen(
      mission: mission,
      configData: configData,
    );
  }

  static Widget _launchStepProcedureMission(Mission mission) {
    List<ProcedureStep> steps;

    switch (mission.id) {
      case 'coc1_m5':
        steps = MissionContentData.getCOC1M5Steps();
        break;
      case 'coc2_m3':
        steps = MissionContentData.getCOC2M3Steps();
        break;
      case 'coc3_m2':
        steps = MissionContentData.getCOC3M2Steps();
        break;
      case 'coc4_m2':
        steps = MissionContentData.getCOC4M2Steps();
        break;
      default:
        steps = MissionContentData.getCOC1M5Steps();
    }

    return StepProcedureMissionScreen(
      mission: mission,
      steps: steps,
    );
  }

  static Widget _launchTroubleshootingMission(Mission mission) {
    List<Map<String, dynamic>> scenarios;

    switch (mission.id) {
      case 'coc3_m5':
        scenarios = _createCOC3M5Scenarios();
        break;
      case 'coc4_m3':
        scenarios = _createCOC4M3Scenarios();
        break;
      case 'coc4_m4':
        scenarios = _createCOC4M4Scenarios();
        break;
      case 'coc4_m5':
        scenarios = _createCOC4M5Scenarios();
        break;
      default:
        scenarios = MissionContentData.getCOC4M1Scenarios();
    }

    return TroubleshootingMissionScreen(
      mission: mission,
      scenarios: scenarios,
    );
  }

  // Helper methods to create additional mission content
  static List<MissionQuestion> _convertScenariosToCOC4M1Questions() {
    final scenarios = MissionContentData.getCOC4M1Scenarios();
    return scenarios.map((scenario) {
      return MissionQuestion(
        id: 'q${scenarios.indexOf(scenario) + 1}',
        question: 'What causes: ${scenario['symptom']}?',
        options: List<String>.from(scenario['causes']),
        correctAnswer: scenario['correctCause'] as String,
        explanation: 'The correct cause is ${scenario['correctCause']}',
        points: scenario['points'] as int,
      );
    }).toList();
  }

  static List<DraggableComponent> _createCOC2M2Components() {
    final sequence = MissionContentData.getCOC2M2WireSequence();
    return sequence.map((color) {
      return DraggableComponent(
        id: color.toLowerCase().replaceAll('-', '_'),
        name: color,
        targetZone: 'pin_${sequence.indexOf(color) + 1}',
        description: 'Wire color $color',
      );
    }).toList();
  }

  static List<DropZone> _createCOC2M2DropZones() {
    final sequence = MissionContentData.getCOC2M2WireSequence();
    return List.generate(8, (index) {
      return DropZone(
        id: 'pin_${index + 1}',
        name: 'Pin ${index + 1}',
        acceptedComponents: [
          sequence[index].toLowerCase().replaceAll('-', '_')
        ],
      );
    });
  }

  static List<DropZone> _createCOC2M4DropZones() {
    return [
      DropZone(
        id: 'switch_port',
        name: 'Switch Port',
        acceptedComponents: ['computer'],
      ),
      DropZone(
        id: 'router_lan',
        name: 'Router LAN Port',
        acceptedComponents: ['switch'],
      ),
      DropZone(
        id: 'modem',
        name: 'Modem Port',
        acceptedComponents: ['router'],
      ),
    ];
  }

  static Map<String, dynamic> _createCOC3M3ConfigData() {
    return {
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
  }

  static Map<String, dynamic> _createCOC3M4ConfigData() {
    return {
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
  }

  static List<Map<String, dynamic>> _createCOC3M5Scenarios() {
    return [
      {
        'symptom': 'Client cannot access shared folder',
        'causes': [
          'Incorrect permissions',
          'Correct network settings',
          'Server running',
          'Cable connected'
        ],
        'correctCause': 'Incorrect permissions',
        'explanation': 'Check user permissions on the shared folder.',
        'points': 25,
      },
      {
        'symptom': 'Cannot connect to server',
        'causes': [
          'Server IP wrong',
          'Client online',
          'Network working',
          'Firewall off'
        ],
        'correctCause': 'Server IP wrong',
        'explanation': 'Verify the server IP address is correct.',
        'points': 25,
      },
      {
        'symptom': 'User cannot login',
        'causes': [
          'Wrong username/password',
          'Account active',
          'Server online',
          'Network good'
        ],
        'correctCause': 'Wrong username/password',
        'explanation': 'Verify credentials are correct.',
        'points': 25,
      },
      {
        'symptom': 'Server not reachable',
        'causes': [
          'Network configuration error',
          'Cable good',
          'Power on',
          'Firewall OK'
        ],
        'correctCause': 'Network configuration error',
        'explanation': 'Check IP settings and network configuration.',
        'points': 25,
      },
    ];
  }

  static List<Map<String, dynamic>> _createCOC4M3Scenarios() {
    return [
      {
        'symptom': 'Computer beeps and shows no display',
        'causes': [
          'RAM not seated properly',
          'Monitor good',
          'Power supply working',
          'Hard drive OK'
        ],
        'correctCause': 'RAM not seated properly',
        'explanation': 'Reseat the RAM modules securely.',
        'points': 25,
      },
      {
        'symptom': 'Computer shuts down randomly',
        'causes': [
          'Overheating CPU',
          'Good ventilation',
          'Working PSU',
          'New thermal paste'
        ],
        'correctCause': 'Overheating CPU',
        'explanation': 'Check CPU cooler and apply thermal paste.',
        'points': 25,
      },
      {
        'symptom': 'Hard drive not detected',
        'causes': [
          'SATA cable loose',
          'Drive mounted',
          'Power connected',
          'BIOS updated'
        ],
        'correctCause': 'SATA cable loose',
        'explanation': 'Reconnect SATA data and power cables.',
        'points': 25,
      },
      {
        'symptom': 'System freezes frequently',
        'causes': ['Faulty RAM', 'Good CPU', 'Working HDD', 'Clean system'],
        'correctCause': 'Faulty RAM',
        'explanation': 'Test RAM modules individually.',
        'points': 25,
      },
    ];
  }

  static List<Map<String, dynamic>> _createCOC4M4Scenarios() {
    return [
      {
        'symptom': 'No internet but LAN works',
        'causes': [
          'Router not connected to modem',
          'LAN cable good',
          'Switch working',
          'Computer on'
        ],
        'correctCause': 'Router not connected to modem',
        'explanation': 'Check the connection between router and modem.',
        'points': 25,
      },
      {
        'symptom': 'Slow network speed',
        'causes': [
          'Network congestion',
          'Cable good',
          'NIC working',
          'Router OK'
        ],
        'correctCause': 'Network congestion',
        'explanation': 'Too many devices or bandwidth-heavy applications.',
        'points': 25,
      },
      {
        'symptom': 'Cannot ping gateway',
        'causes': [
          'Wrong IP configuration',
          'Cable connected',
          'Network card on',
          'Driver installed'
        ],
        'correctCause': 'Wrong IP configuration',
        'explanation': 'Verify IP address, subnet mask, and gateway.',
        'points': 25,
      },
      {
        'symptom': 'Intermittent connection drops',
        'causes': [
          'Faulty network cable',
          'Router working',
          'Switch OK',
          'Computer on'
        ],
        'correctCause': 'Faulty network cable',
        'explanation': 'Replace the network cable.',
        'points': 25,
      },
    ];
  }

  static List<Map<String, dynamic>> _createCOC4M5Scenarios() {
    return [
      {
        'symptom': 'Printer not printing',
        'causes': [
          'Driver not installed',
          'Paper loaded',
          'Ink full',
          'Power on'
        ],
        'correctCause': 'Driver not installed',
        'explanation': 'Install the correct printer driver.',
        'points': 20,
      },
      {
        'symptom': 'USB device not recognized',
        'causes': [
          'USB port damaged',
          'Device working',
          'Cable good',
          'Driver present'
        ],
        'correctCause': 'USB port damaged',
        'explanation': 'Try a different USB port.',
        'points': 20,
      },
      {
        'symptom': 'Audio not working',
        'causes': [
          'Audio driver missing',
          'Speakers on',
          'Volume up',
          'Cable connected'
        ],
        'correctCause': 'Audio driver missing',
        'explanation': 'Install or update audio driver.',
        'points': 20,
      },
      {
        'symptom': 'Monitor shows "No Signal"',
        'causes': [
          'Video cable disconnected',
          'Monitor on',
          'Computer on',
          'GPU installed'
        ],
        'correctCause': 'Video cable disconnected',
        'explanation': 'Reconnect the video cable securely.',
        'points': 20,
      },
      {
        'symptom': 'System slow after Windows update',
        'causes': [
          'Background updates running',
          'Good RAM',
          'Fast SSD',
          'Clean system'
        ],
        'correctCause': 'Background updates running',
        'explanation': 'Wait for updates to complete or restart system.',
        'points': 20,
      },
    ];
  }
}
