import 'mission_runtime_models.dart';

/// Presentation-state gate only. It proves that the learner completed the
/// phase's required interaction; it never decides correctness or competency.
abstract final class MissionPhaseCompletionPolicy {
  static InteractionFamily interactionFor(MissionPhaseDefinition phase) {
    return phase.resolvedInteraction;
  }

  static bool canAdvance(
    MissionPhaseDefinition phase,
    MissionRuntimeState state,
  ) =>
      interactionFor(phase) != InteractionFamily.review &&
      state.interactionCompletedPhaseIds.contains(phase.id);

  static MissionRuntimeState afterAction({
    required MissionPhaseDefinition phase,
    required MissionRuntimeState state,
    required String emittedActionType,
    required String? target,
    required Map<String, dynamic> value,
  }) {
    if (!_isTerminal(
      phase: phase,
      state: state,
      emittedActionType: emittedActionType,
      target: target,
      value: value,
    )) {
      return state;
    }
    return state.copyWith(
      interactionCompletedPhaseIds: {
        ...state.interactionCompletedPhaseIds,
        phase.id,
      },
    );
  }

  static bool _isTerminal({
    required MissionPhaseDefinition phase,
    required MissionRuntimeState state,
    required String emittedActionType,
    required String? target,
    required Map<String, dynamic> value,
  }) {
    return switch (interactionFor(phase)) {
      InteractionFamily.inspect => emittedActionType == 'object_inspected' &&
          _requiredIds(
            phase.presentation['objects'],
            fallback: phase.availableObjectIds,
          ).every((id) =>
              state.hotspotStates[id] != null &&
              state.hotspotStates[id] != HotspotVisualState.neutral),
      InteractionFamily.select => emittedActionType == 'selection_confirmed' &&
          _stringList(value['selected_ids']).isNotEmpty,
      InteractionFamily.tool => emittedActionType == 'tool_attempted' &&
          value['compatible'] == true &&
          target != null &&
          state.toolApplications.containsKey(target),
      InteractionFamily.connect => emittedActionType == 'connection_created' &&
          _requiredIds(phase.presentation['sources']).every(
            (source) => state.connectedNodePairs.any(
              (pair) => pair.startsWith('$source>'),
            ),
          ),
      InteractionFamily.configure =>
        emittedActionType == 'configuration_applied' &&
            _configurationComplete(phase, state),
      InteractionFamily.sequence => emittedActionType == 'sequence_reordered' &&
          _containsAll(
            state.sequenceOrder,
            _requiredIds(
              phase.presentation['items'],
              fallback: phase.availableObjectIds,
            ),
          ),
      InteractionFamily.match => emittedActionType == 'match_created' &&
          _requiredIds(phase.presentation['sources'])
              .every(state.matches.containsKey),
      InteractionFamily.place => emittedActionType == 'placement_attempted' &&
          value['compatible'] == true &&
          _requiredIds(phase.presentation['items'])
              .every(state.placements.containsKey),
      InteractionFamily.troubleshoot =>
        (emittedActionType == 'diagnostic_action' ||
                emittedActionType == 'retest_requested') &&
            _troubleshootingComplete(phase, state),
      InteractionFamily.testRun =>
        phase.presentation['requires_interpretation'] == true
            ? emittedActionType == 'result_interpreted' &&
                state.testStatusFor(
                      phase.presentation['target'] as String? ?? phase.id,
                    ) ==
                    MissionTestStatus.completed &&
                _hasNonEmptyValue(state.interpretations[phase.id])
            : emittedActionType == 'test_completed' &&
                target != null &&
                state.testStatusFor(target) == MissionTestStatus.completed,
      InteractionFamily.observe =>
        emittedActionType == 'observation_recorded' &&
            _hasNonEmptyValue(state.observations[phase.id]),
      InteractionFamily.decide => emittedActionType == 'scenario_decision' &&
          target != null &&
          state.selectedBranchActionIds.contains(target),
      InteractionFamily.interpret =>
        emittedActionType == 'result_interpreted' &&
            _hasNonEmptyValue(state.interpretations[phase.id]),
      InteractionFamily.review => false,
    };
  }

  static bool _configurationComplete(
    MissionPhaseDefinition phase,
    MissionRuntimeState state,
  ) {
    final fields = _requiredIds(phase.presentation['fields']);
    if (fields.isEmpty) return state.configurationValues.isNotEmpty;
    return fields.every(
      (field) => _hasNonEmptyValue(state.configurationValues[field]),
    );
  }

  static bool _troubleshootingComplete(
    MissionPhaseDefinition phase,
    MissionRuntimeState state,
  ) {
    final requiredFacts = _stringList(phase.presentation['required_fact_ids']);
    if (requiredFacts.isEmpty) return state.revealedFactIds.isNotEmpty;
    return state.revealedFactIds.containsAll(requiredFacts);
  }

  static bool _hasNonEmptyValue(Object? value) =>
      value != null && value.toString().trim().isNotEmpty;

  static bool _containsAll(Iterable<String> actual, Iterable<String> required) {
    final requiredSet = required.toSet();
    return requiredSet.isNotEmpty && actual.toSet().containsAll(requiredSet);
  }

  static List<String> _requiredIds(
    Object? value, {
    Iterable<String> fallback = const [],
  }) {
    final ids = (value as List? ?? const [])
        .whereType<Map>()
        .map((item) => item['id'])
        .whereType<String>()
        .toList(growable: false);
    return ids.isEmpty ? fallback.toList(growable: false) : ids;
  }

  static List<String> _stringList(Object? value) =>
      (value as List? ?? const []).whereType<String>().toList(growable: false);
}
