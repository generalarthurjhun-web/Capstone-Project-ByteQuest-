import '../screens/simulation/runtime/mission_runtime_models.dart';
import 'mission_content_data.dart';

part 'mission_definitions/coc1_definitions.dart';
part 'mission_definitions/coc2_definitions.dart';
part 'mission_definitions/coc3_definitions.dart';
part 'mission_definitions/coc4_definitions.dart';

/// Authoritative learner-visible presentation catalog for all simulations.
///
/// Definitions describe scenes and evidence-producing workflows only. They do
/// not contain evaluator answers, scores, pass thresholds, XP, or rewards.
abstract final class MissionSimulationDefinitions {
  static final List<MissionSimulationDefinition> all = List.unmodifiable([
    ..._coc1Definitions,
    ..._coc2Definitions,
    ..._coc3Definitions,
    ..._coc4Definitions,
  ]);

  static final Map<String, MissionSimulationDefinition> _byId =
      Map.unmodifiable(
          {for (final definition in all) definition.id: definition});

  static MissionSimulationDefinition byId(String id) {
    final definition = _byId[id];
    if (definition == null) {
      throw ArgumentError.value(
        id,
        'id',
        'Unknown mission simulation definition',
      );
    }
    return definition;
  }
}

final class _PhaseSpec {
  const _PhaseSpec({
    required this.title,
    required this.instruction,
    required this.family,
    required this.mechanic,
    this.presentation = const {},
  });

  final String title;
  final String instruction;
  final InteractionFamily family;
  final String mechanic;
  final Map<String, dynamic> presentation;
}

_PhaseSpec _phase(
  String title,
  String instruction,
  InteractionFamily family,
  String mechanic, {
  Map<String, dynamic> presentation = const {},
}) =>
    _PhaseSpec(
      title: title,
      instruction: instruction,
      family: family,
      mechanic: mechanic,
      presentation: presentation,
    );

MissionSimulationDefinition _mission({
  required String id,
  required String title,
  required String scenario,
  required String environmentLabel,
  required String practiceGuidance,
  required Map<String, String> objects,
  required List<_PhaseSpec> phases,
}) {
  final objectIds = objects.keys.toList(growable: false);
  final feedback = MissionContentData.feedbackForMission(id);
  final definitions = <MissionPhaseDefinition>[];

  for (var index = 0; index < phases.length; index++) {
    final spec = phases[index];
    final feedbackKind = spec.family == InteractionFamily.review
        ? 'review'
        : spec.family == InteractionFamily.testRun
            ? 'evidence'
            : 'constraint';
    definitions.add(MissionPhaseDefinition(
      id: '${id}_p${index + 1}',
      title: spec.title,
      instruction: spec.instruction,
      primaryInteraction: spec.family,
      availableObjectIds: objectIds,
      feedbackIds: ['${id}_$feedbackKind'],
      presentation: {
        ...spec.presentation,
        'mechanics': [spec.mechanic],
      },
    ));
  }

  return MissionSimulationDefinition(
    id: id,
    cocId: id.substring(0, 4),
    title: title,
    scenario: scenario,
    environmentLabel: environmentLabel,
    practiceGuidance: practiceGuidance,
    scene: _scene(id, objects),
    phases: definitions,
    interactionFamilies: definitions.map((phase) => phase.primaryInteraction),
    feedbackCatalog: feedback,
    reviewMetadata: const {
      'title': 'Evidence review',
      'returnLabel': 'Return to mission',
      'confirmLabel': 'Confirm evidence',
    },
  );
}

SimulationSceneDefinition _scene(
    String missionId, Map<String, String> objects) {
  final entries = objects.entries.toList(growable: false);
  return SimulationSceneDefinition(
    id: '${missionId}_scene',
    objects: [
      for (var index = 0; index < entries.length; index++)
        SceneObjectDefinition(
          id: entries[index].key,
          label: entries[index].value,
          x: 0.08 + (index % 3) * 0.30,
          y: 0.10 + (index ~/ 3) * 0.34,
          width: 0.24,
          height: 0.22,
          hotspotType: 'inspect_and_select',
          connectionNodeIds: ['${entries[index].key}_port'],
          metadata: {
            'schematicRole': index == 0 ? 'primary' : 'supporting',
            'replaceableAsset':
                'assets/simulation/schematics/${entries[index].key}.svg',
          },
        ),
    ],
    initialStatus: const {
      'schematic': true,
      'replaceableAssets': true,
      'statusLabel': 'Awaiting inspection',
    },
  );
}

Map<String, dynamic> _progressiveDiagnostics({
  required String symptom,
  required List<(String, String, String)> actions,
  required String correctionId,
  required String correctionLabel,
  required String retestId,
}) {
  final factIds = actions.map((action) => action.$3).toList(growable: false);
  return {
    'symptom': symptom,
    'diagnostic_actions': [
      for (final action in actions)
        {
          'id': action.$1,
          'label': action.$2,
          'reveals_fact_id': action.$3,
        },
    ],
    'facts': {
      for (final action in actions)
        action.$3: 'Recorded result from ${action.$2.toLowerCase()}.',
    },
    'required_fact_ids': factIds,
    'correction': {'id': correctionId, 'label': correctionLabel},
    'retest': {'id': retestId, 'label': 'Run the documented retest'},
  };
}
