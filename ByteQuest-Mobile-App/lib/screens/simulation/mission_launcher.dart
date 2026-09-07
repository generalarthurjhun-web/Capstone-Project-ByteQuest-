import 'package:flutter/material.dart';

import '../../data/mission_simulation_definitions.dart';
import '../../models/mission_model.dart';
import 'mission_simulation_screen.dart';
import 'templates/authoritative_mission_assessment_screen.dart';
import 'templates/coc2_cable_termination_assessment_screen.dart';

/// Resolves mission routes without requiring navigation, then launches the
/// resolved screen for production callers.
abstract final class MissionLauncher {
  /// Practice missions intentionally shipped through the typed simulation
  /// runtime. Explicit assessment payload adapters below remain separate so
  /// server-authoritative evaluation contracts are never inferred locally.
  static const Set<String> productionRuntimeMissionIds = {
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
  };

  static Widget screenFor(
    Mission mission, {
    Map<String, dynamic> learnerPayload = const {},
  }) {
    final template = learnerPayload['simulation_template'];
    switch (template) {
      case 'authoritative_mission_v1':
        return AuthoritativeMissionAssessmentScreen(
          mission: mission,
          learnerPayload: learnerPayload,
        );
      case 'coc2_cable_termination':
        return Coc2CableTerminationAssessmentScreen(mission: mission);
      case null:
        break;
      default:
        throw ArgumentError.value(
          template,
          'learnerPayload.simulation_template',
          'Unknown simulation template',
        );
    }

    if (!productionRuntimeMissionIds.contains(mission.id)) {
      throw ArgumentError.value(
        mission.id,
        'mission.id',
        'Unknown production mission route',
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
    return Navigator.of(
      context,
    ).push<void>(MaterialPageRoute<void>(builder: (_) => screen));
  }
}
