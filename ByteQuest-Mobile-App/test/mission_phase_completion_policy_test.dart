import 'package:bytequest/data/mission_simulation_definitions.dart';
import 'package:bytequest/screens/simulation/runtime/mission_phase_completion_policy.dart';
import 'package:bytequest/screens/simulation/runtime/mission_runtime_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MissionPhaseCompletionPolicy', () {
    test('all fourteen interaction families fail closed before terminal state',
        () {
      for (final family in InteractionFamily.values) {
        final phase = _phaseFor(family);
        final state = MissionRuntimeState.initial('policy-test').copyWith(
          currentPhaseId: phase.id,
        );

        expect(
          MissionPhaseCompletionPolicy.canAdvance(phase, state),
          isFalse,
          reason: '${family.name} advanced without terminal interaction state',
        );
      }
    });

    test('all non-review families advance only after their terminal action',
        () {
      for (final family in InteractionFamily.values) {
        final phase = _phaseFor(family);
        final initial = MissionRuntimeState.initial('policy-test').copyWith(
          currentPhaseId: phase.id,
        );
        final terminal = _terminalActionFor(phase, initial);
        final afterAction = MissionPhaseCompletionPolicy.afterAction(
          phase: phase,
          state: terminal.state,
          emittedActionType: terminal.actionType,
          target: terminal.target,
          value: terminal.value,
        );

        expect(
          MissionPhaseCompletionPolicy.canAdvance(phase, afterAction),
          family == InteractionFamily.review ? isFalse : isTrue,
          reason: '${family.name} did not honor its terminal action',
        );
      }
    });

    test('every catalog phase requires its own terminal interaction state', () {
      for (final definition in MissionSimulationDefinitions.all) {
        var state = MissionRuntimeState.initial(definition.id);
        for (final phase in definition.phases) {
          state = state.copyWith(currentPhaseId: phase.id);
          expect(
            MissionPhaseCompletionPolicy.canAdvance(phase, state),
            isFalse,
            reason: '${definition.id}/${phase.id} advanced before interaction',
          );

          final terminal = _terminalActionFor(phase, state);
          state = MissionPhaseCompletionPolicy.afterAction(
            phase: phase,
            state: terminal.state,
            emittedActionType: terminal.actionType,
            target: terminal.target,
            value: terminal.value,
          );
          expect(
            MissionPhaseCompletionPolicy.canAdvance(phase, state),
            phase.primaryInteraction == InteractionFamily.review
                ? isFalse
                : isTrue,
            reason: '${definition.id}/${phase.id} rejected terminal action',
          );
        }
      }
    });

    test('terminal state from one phase never unlocks a later phase', () {
      final definition = MissionSimulationDefinitions.byId('coc1_m1');
      final first = definition.phases.first;
      final later = definition.phases[2];
      final terminal = _terminalActionFor(
        first,
        MissionRuntimeState.initial(definition.id).copyWith(
          currentPhaseId: first.id,
        ),
      );
      final afterFirst = MissionPhaseCompletionPolicy.afterAction(
        phase: first,
        state: terminal.state,
        emittedActionType: terminal.actionType,
        target: terminal.target,
        value: terminal.value,
      ).copyWith(currentPhaseId: later.id);

      expect(
          MissionPhaseCompletionPolicy.canAdvance(first, afterFirst), isTrue);
      expect(
          MissionPhaseCompletionPolicy.canAdvance(later, afterFirst), isFalse);
    });
  });
}

MissionPhaseDefinition _phaseFor(InteractionFamily family) {
  final presentation = switch (family) {
    InteractionFamily.inspect => const {
        'objects': [
          {'id': 'device', 'label': 'Device'},
        ],
      },
    InteractionFamily.select => const {
        'options': [
          {'id': 'device', 'label': 'Device'},
        ],
      },
    InteractionFamily.tool => const {
        'targets': [
          {'id': 'device', 'label': 'Device'},
        ],
        'tools': [
          {'id': 'meter', 'label': 'Meter'},
        ],
      },
    InteractionFamily.connect || InteractionFamily.match => const {
        'sources': [
          {'id': 'source', 'label': 'Source'},
        ],
        'destinations': [
          {'id': 'destination', 'label': 'Destination'},
        ],
      },
    InteractionFamily.configure => const {
        'fields': [
          {'id': 'address', 'label': 'Address'},
        ],
      },
    InteractionFamily.sequence => const {
        'items': [
          {'id': 'step', 'label': 'Step'},
        ],
      },
    InteractionFamily.place => const {
        'items': [
          {'id': 'part', 'label': 'Part'},
        ],
        'destinations': [
          {'id': 'slot', 'label': 'Slot'},
        ],
      },
    InteractionFamily.troubleshoot => const {
        'diagnostic_actions': [
          {
            'id': 'inspect',
            'label': 'Inspect',
            'reveals_fact_id': 'fact',
          },
        ],
        'required_fact_ids': ['fact'],
      },
    InteractionFamily.decide => const {
        'choices': [
          {'id': 'isolate', 'label': 'Isolate'},
        ],
      },
    _ => const <String, dynamic>{},
  };
  return MissionPhaseDefinition(
    id: 'phase-${family.name}',
    title: family.name,
    instruction: 'Complete ${family.name}',
    primaryInteraction: family,
    availableObjectIds: const ['device'],
    presentation: presentation,
  );
}

_TerminalAction _terminalActionFor(
  MissionPhaseDefinition phase,
  MissionRuntimeState state,
) {
  final family = MissionPhaseCompletionPolicy.interactionFor(phase);
  return switch (family) {
    InteractionFamily.inspect => _TerminalAction(
        state: state.copyWith(
          hotspotStates: {
            for (final id in _ids(
              phase.presentation['objects'],
              fallback: phase.availableObjectIds,
            ))
              id: HotspotVisualState.selected,
          },
        ),
        actionType: 'object_inspected',
        target: phase.availableObjectIds.firstOrNull,
      ),
    InteractionFamily.select => _TerminalAction(
        state: state.copyWith(
          hotspotStates: const {'device': HotspotVisualState.selected},
        ),
        actionType: 'selection_confirmed',
        target: phase.id,
        value: const {
          'selected_ids': ['device'],
        },
      ),
    InteractionFamily.tool => _TerminalAction(
        state: state.copyWith(
          selectedToolId: 'meter',
          toolApplications: const {'device': 'meter'},
        ),
        actionType: 'tool_attempted',
        target: 'device',
        value: const {'tool_id': 'meter', 'compatible': true},
      ),
    InteractionFamily.connect => _TerminalAction(
        state: state.copyWith(
          connectedNodePairs: {
            for (final id in _ids(phase.presentation['sources']))
              '$id>destination',
          },
        ),
        actionType: 'connection_created',
        target: 'destination',
        value: const {
          'source_id': 'source',
          'destination_id': 'destination',
        },
      ),
    InteractionFamily.configure => _TerminalAction(
        state: state.copyWith(configurationValues: const {'address': 'value'}),
        actionType: 'configuration_applied',
        target: phase.id,
        value: const {
          'values': {'address': 'value'},
        },
      ),
    InteractionFamily.sequence => _TerminalAction(
        state: state.copyWith(
          sequenceOrder: _ids(
            phase.presentation['items'],
            fallback: phase.availableObjectIds,
          ),
        ),
        actionType: 'sequence_reordered',
        target: phase.id,
        value: {
          'order': _ids(
            phase.presentation['items'],
            fallback: phase.availableObjectIds,
          ),
        },
      ),
    InteractionFamily.match => _TerminalAction(
        state: state.copyWith(matches: {
          for (final id in _ids(phase.presentation['sources']))
            id: 'destination',
        }),
        actionType: 'match_created',
        target: 'destination',
        value: const {
          'source_id': 'source',
          'destination_id': 'destination',
        },
      ),
    InteractionFamily.place => _TerminalAction(
        state: state.copyWith(placements: {
          for (final id in _ids(phase.presentation['items'])) id: 'slot',
        }),
        actionType: 'placement_attempted',
        target: 'slot',
        value: const {
          'item_id': 'part',
          'destination_id': 'slot',
          'compatible': true,
        },
      ),
    InteractionFamily.troubleshoot => _TerminalAction(
        state: state.copyWith(
          revealedFactIds: _stringIds(
            phase.presentation['required_fact_ids'],
            fallback: const ['fact'],
          ).toSet(),
        ),
        actionType: 'diagnostic_action',
        target: 'inspect',
        value: const {'reveals_fact_id': 'fact'},
      ),
    InteractionFamily.testRun => _TerminalAction(
        state: state.withTestStatus(
          phase.presentation['target'] as String? ?? phase.id,
          MissionTestStatus.completed,
        ),
        actionType: 'test_completed',
        target: phase.presentation['target'] as String? ?? phase.id,
        value: const {'test_status': 'completed'},
      ),
    InteractionFamily.observe => _TerminalAction(
        state: state.copyWith(observations: {phase.id: 'Observed value'}),
        actionType: 'observation_recorded',
        target: phase.id,
        value: const {'observation': 'Observed value'},
      ),
    InteractionFamily.decide => _TerminalAction(
        state: state.copyWith(selectedBranchActionIds: const {'isolate'}),
        actionType: 'scenario_decision',
        target: 'isolate',
      ),
    InteractionFamily.interpret => _TerminalAction(
        state: state.copyWith(interpretations: {phase.id: 'Interpretation'}),
        actionType: 'result_interpreted',
        target: phase.id,
        value: const {'interpretation': 'Interpretation'},
      ),
    InteractionFamily.review => _TerminalAction(
        state: state,
        actionType: 'review_confirmed',
        target: phase.id,
      ),
  };
}

List<String> _ids(dynamic raw, {Iterable<String> fallback = const []}) {
  final ids = (raw as List? ?? const [])
      .whereType<Map>()
      .map((item) => item['id'])
      .whereType<String>()
      .toList(growable: false);
  return ids.isEmpty ? fallback.toList(growable: false) : ids;
}

List<String> _stringIds(dynamic raw, {Iterable<String> fallback = const []}) {
  final ids = (raw as List? ?? const []).whereType<String>().toList();
  return ids.isEmpty ? fallback.toList(growable: false) : ids;
}

final class _TerminalAction {
  const _TerminalAction({
    required this.state,
    required this.actionType,
    this.target,
    this.value = const {},
  });

  final MissionRuntimeState state;
  final String actionType;
  final String? target;
  final Map<String, dynamic> value;
}

extension on List<String> {
  String? get firstOrNull => this.isEmpty ? null : first;
}
