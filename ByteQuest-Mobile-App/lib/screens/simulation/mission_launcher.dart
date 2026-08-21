import 'package:flutter/material.dart';

import '../../data/mission_simulation_definitions.dart';
import '../../models/mission_model.dart';
import 'mission_simulation_screen.dart';
import 'templates/authoritative_mission_assessment_screen.dart';
import 'templates/coc1_m2_screen_enhanced.dart';
import 'templates/coc1_m3_screen_enhanced.dart';
import 'templates/coc2_cable_termination_assessment_screen.dart';

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
}
