import 'mission_phase_completion_policy.dart';
import 'mission_runtime_models.dart';

/// Deterministically rebuilds presentation state from acknowledged evidence.
///
/// This reducer only restores what the learner did. It never evaluates
/// correctness or competency; those decisions remain server-authoritative.
final class MissionRuntimeActionReducer {
  MissionRuntimeActionReducer(this.definition);

  final MissionSimulationDefinition definition;

  MissionRuntimeState reduce(
    MissionRuntimeState state,
    MissionEvidenceAction action,
  ) {
    if (action.missionId != definition.id ||
        action.missionId != state.missionId) {
      throw FormatException(
        'Acknowledged evidence ${action.clientActionId} does not match '
        '${definition.id}.',
      );
    }
    final phase = definition.phases.where((item) => item.id == action.phaseId);
    if (phase.isEmpty) {
      throw FormatException(
        'Acknowledged evidence ${action.clientActionId} references unknown '
        'phase ${action.phaseId}.',
      );
    }
    final phaseDefinition = phase.single;
    if (action.actionType == 'phase_completed') {
      final nextPhaseId = action.target;
      if (nextPhaseId == null ||
          !definition.phases.any((item) => item.id == nextPhaseId)) {
        throw FormatException(
          'Acknowledged phase transition ${action.clientActionId} has an '
          'unknown destination.',
        );
      }
      return state.copyWith(
        currentPhaseId: nextPhaseId,
        completedPhaseIds: {...state.completedPhaseIds, action.phaseId},
      );
    }
    if (action.actionType == 'review_returned') {
      final destination = action.target;
      if (destination == null ||
          !definition.phases.any((item) => item.id == destination)) {
        throw FormatException(
          'Acknowledged review return ${action.clientActionId} has an '
          'unknown destination.',
        );
      }
      return state.copyWith(currentPhaseId: destination);
    }

    final runtimeActionType = _runtimeActionType(phaseDefinition, action);
    final transitioned = transitionForAction(
      state,
      runtimeActionType,
      action.target,
      action.value,
    );
    return MissionPhaseCompletionPolicy.afterAction(
      phase: phaseDefinition,
      state: transitioned,
      emittedActionType: runtimeActionType,
      target: action.target,
      value: action.value,
    );
  }

  String _runtimeActionType(
    MissionPhaseDefinition phase,
    MissionEvidenceAction action,
  ) {
    final recordedType = action.value['runtime_action_type'];
    if (recordedType is String && recordedType.isNotEmpty) return recordedType;
    if (_runtimeActionTypes.contains(action.actionType))
      return action.actionType;
    return switch (phase.resolvedInteraction) {
      InteractionFamily.inspect => 'object_inspected',
      InteractionFamily.select => 'selection_confirmed',
      InteractionFamily.tool => 'tool_attempted',
      InteractionFamily.connect => 'connection_created',
      InteractionFamily.configure => 'configuration_applied',
      InteractionFamily.sequence => 'sequence_reordered',
      InteractionFamily.match => 'match_created',
      InteractionFamily.place => 'placement_attempted',
      InteractionFamily.troubleshoot =>
        action.value.containsKey('reveals_fact_id')
            ? 'diagnostic_action'
            : 'retest_requested',
      InteractionFamily.testRun =>
        action.value['test_status'] == MissionTestStatus.running.name
            ? 'test_started'
            : 'test_completed',
      InteractionFamily.observe => 'observation_recorded',
      InteractionFamily.decide => 'scenario_decision',
      InteractionFamily.interpret => 'result_interpreted',
      InteractionFamily.review => action.actionType,
    };
  }

  static const _runtimeActionTypes = {
    'object_inspected',
    'selection_confirmed',
    'tool_attempted',
    'connection_created',
    'configuration_applied',
    'sequence_reordered',
    'match_created',
    'placement_attempted',
    'diagnostic_action',
    'correction_applied',
    'retest_requested',
    'test_started',
    'test_completed',
    'observation_recorded',
    'scenario_decision',
    'result_interpreted',
  };

  static MissionRuntimeState transitionForAction(
    MissionRuntimeState state,
    String actionType,
    String? target,
    Map<String, dynamic> value,
  ) {
    final testStatusName = value['test_status'];
    if (target != null && testStatusName is String) {
      for (final status in MissionTestStatus.values) {
        if (status.name == testStatusName) {
          state = state.withTestStatus(target, status);
          break;
        }
      }
    }
    switch (actionType) {
      case 'object_inspected':
        if (target == null) return state;
        return state.copyWith(hotspotStates: {
          ...state.hotspotStates,
          target: HotspotVisualState.selected,
        });
      case 'selection_confirmed':
        final selected =
            (value['selected_ids'] as List? ?? const []).whereType<String>();
        return state.copyWith(hotspotStates: {
          ...state.hotspotStates,
          for (final id in selected) id: HotspotVisualState.selected,
        });
      case 'tool_attempted':
        final toolId = value['tool_id'] as String?;
        if (value['compatible'] != true) return state;
        return state.copyWith(
          selectedToolId: toolId,
          toolApplications: target == null || toolId == null
              ? state.toolApplications
              : {...state.toolApplications, target: toolId},
        );
      case 'connection_created':
        final source = value['source_id'] as String?;
        final destination = value['destination_id'] as String?;
        if (source == null || destination == null) return state;
        return state.copyWith(connectedNodePairs: {
          ...state.connectedNodePairs,
          '$source>$destination',
        });
      case 'configuration_applied':
        final values = value['values'];
        return values is Map
            ? state.copyWith(configurationValues: {
                ...state.configurationValues,
                ...Map<String, dynamic>.from(values),
              })
            : state;
      case 'sequence_reordered':
        return state.copyWith(
          sequenceOrder: (value['order'] as List? ?? const [])
              .whereType<String>()
              .toList(growable: false),
        );
      case 'match_created':
        final source = value['source_id'] as String?;
        final destination = value['destination_id'] as String?;
        if (source == null || destination == null) return state;
        return state.copyWith(matches: {...state.matches, source: destination});
      case 'placement_attempted':
        final item = value['item_id'] as String?;
        final destination = value['destination_id'] as String?;
        if (item == null ||
            destination == null ||
            value['compatible'] != true) {
          return state;
        }
        return state.copyWith(placements: {
          ...state.placements,
          item: destination,
        });
      case 'diagnostic_action':
        final factId = value['reveals_fact_id'] as String?;
        return factId == null
            ? state
            : state.copyWith(
                revealedFactIds: {...state.revealedFactIds, factId},
              );
      case 'correction_applied':
      case 'retest_requested':
      case 'scenario_decision':
        if (target == null) return state;
        return state.copyWith(selectedBranchActionIds: {
          ...state.selectedBranchActionIds,
          target,
        });
      case 'observation_recorded':
        final observation = value['observation'];
        return observation is String && target != null
            ? state.copyWith(observations: {
                ...state.observations,
                target: observation,
              })
            : state;
      case 'result_interpreted':
        final interpretation = value['interpretation'];
        return interpretation is String && target != null
            ? state.copyWith(interpretations: {
                ...state.interpretations,
                target: interpretation,
              })
            : state;
      default:
        return state;
    }
  }
}
