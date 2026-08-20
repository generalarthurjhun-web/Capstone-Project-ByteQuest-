import 'dart:async';

import 'package:flutter/material.dart';

import '../components/tool_tray.dart';
import '../runtime/mission_runtime_controller.dart';
import '../runtime/mission_runtime_models.dart';

typedef ScenarioRuntimeTransitionCallback = void Function(
  MissionRuntimeTransition transition,
);

class ScenarioDecisionInteraction extends StatelessWidget {
  const ScenarioDecisionInteraction({
    super.key,
    required this.phase,
    required this.state,
    required this.onAction,
    required this.onRuntimeTransition,
    this.enabled = true,
  });

  final MissionPhaseDefinition phase;
  final MissionRuntimeState state;
  final MissionActionCallback onAction;
  final ScenarioRuntimeTransitionCallback onRuntimeTransition;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final choices = (phase.presentation['choices'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item));
    return Semantics(
      container: true,
      label: 'Technical scenario decision',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(phase.instruction),
          const SizedBox(height: 10),
          for (final choice in choices) ...[
            OutlinedButton(
              onPressed: enabled ? () => _select(choice) : null,
              child: Text(choice['label'] as String? ?? 'Choose action'),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  void _select(Map<String, dynamic> choice) {
    final id = choice['id'] as String?;
    if (id == null) return;
    final availableActionIds = (choice['available_action_ids'] as List? ?? const [])
        .whereType<String>()
        .toList(growable: false);
    onRuntimeTransition(
      (runtime) => runtime.copyWith(
        selectedBranchActionIds: {...runtime.selectedBranchActionIds, id},
        configurationValues: {
          ...runtime.configurationValues,
          'available_action_ids': availableActionIds,
        },
      ),
    );
    unawaited(onAction('scenario_decision', id, {
      'available_action_ids': availableActionIds,
      'input_method': 'tap',
    }));
  }
}
