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
    final component = spec.presentation['component'];
    final renderedFamily = component is String
        ? MissionPhasePresentation.familyForComponent(component) ?? spec.family
        : spec.family;
    final feedbackKind = spec.family == InteractionFamily.review
        ? 'review'
        : spec.family == InteractionFamily.testRun
            ? 'evidence'
            : 'constraint';
    definitions.add(MissionPhaseDefinition(
      id: '${id}_p${index + 1}',
      title: spec.title,
      instruction: spec.instruction,
      primaryInteraction: renderedFamily,
      availableObjectIds: objectIds,
      feedbackIds: ['${id}_$feedbackKind'],
      presentation: _presentationWithImageAssets(
        id,
        spec.presentation,
      )..addAll({
          'mechanics': [spec.mechanic],
        }),
    ));
  }

  return MissionSimulationDefinition(
    id: id,
    cocId: id.substring(0, 4),
    title: title,
    scenario: scenario,
    environmentLabel: environmentLabel,
    practiceGuidance: practiceGuidance,
    scene: _scene(id, _sceneObjects(objects, definitions)),
    phases: definitions,
    interactionFamilies: definitions
        .map((phase) => phase.resolvedInteraction)
        .where((family) => family != InteractionFamily.review),
    feedbackCatalog: feedback,
    reviewMetadata: const {
      'title': 'Evidence review',
      'returnLabel': 'Return to mission',
      'confirmLabel': 'Confirm evidence',
    },
  );
}

Map<String, String> _sceneObjects(
  Map<String, String> objects,
  List<MissionPhaseDefinition> phases,
) {
  final sceneObjects = Map<String, String>.from(objects);
  for (final phase in phases) {
    if (phase.resolvedInteraction != InteractionFamily.connect) continue;
    for (final key in const ['sources', 'destinations']) {
      for (final endpoint
          in (phase.presentation[key] as List? ?? const []).whereType<Map>()) {
        final id = endpoint['id'];
        final label = endpoint['label'];
        if (id is String && label is String) {
          sceneObjects.putIfAbsent(id, () => label);
        }
      }
    }
  }
  return sceneObjects;
}

SimulationSceneDefinition _scene(
    String missionId, Map<String, String> objects) {
  final entries = objects.entries.toList(growable: false);
  final columns = entries.length > 9 ? 4 : 3;
  return SimulationSceneDefinition(
    id: '${missionId}_scene',
    objects: [
      for (var index = 0; index < entries.length; index++)
        SceneObjectDefinition(
          id: entries[index].key,
          label: entries[index].value,
          x: columns == 3
              ? 0.08 + (index % 3) * 0.30
              : 0.04 + (index % 4) * 0.24,
          y: columns == 3
              ? 0.10 + (index ~/ 3) * 0.34
              : 0.08 + (index ~/ 4) * 0.31,
          width: columns == 3 ? 0.24 : 0.20,
          height: 0.22,
          hotspotType: 'inspect_and_select',
          connectionNodeIds: ['${entries[index].key}_port'],
          metadata: {
            'schematicRole': index == 0 ? 'primary' : 'supporting',
            'replaceableAsset':
                'assets/simulation/schematics/${entries[index].key}.svg',
            'imageAsset': _imageAssetForObject(
              missionId,
              entries[index].key,
            ),
          },
        ),
    ],
    backgroundAsset: _backgroundAssetForMission(missionId),
    initialStatus: const {
      'schematic': true,
      'replaceableAssets': true,
      'statusLabel': 'Awaiting inspection',
    },
  );
}

Map<String, dynamic> _presentationWithImageAssets(
  String missionId,
  Map<String, dynamic> presentation,
) {
  final result = Map<String, dynamic>.from(presentation);
  for (final key in const [
    'objects',
    'items',
    'targets',
    'sources',
    'destinations',
  ]) {
    final raw = result[key];
    if (raw is! List) continue;
    result[key] = [
      for (final entry in raw)
        if (entry is Map)
          (() {
            final item = Map<String, dynamic>.from(entry);
            if (item['id'] is String) {
              item['imageAsset'] =
                  _imageAssetForObject(missionId, item['id'] as String);
            }
            return item;
          })()
        else
          entry,
    ];
  }
  return result;
}

String? _backgroundAssetForMission(String missionId) {
  final coc = missionId.substring(0, 4);
  return switch (coc) {
    'coc1' => 'assets/images/COC1.png',
    'coc2' => 'assets/images/COC2.png',
    'coc3' => 'assets/images/COC3.png',
    'coc4' => 'assets/images/COC4.png',
    _ => null,
  };
}

String? _imageAssetForObject(String missionId, String objectId) {
  final coc = missionId.substring(0, 4);
  if (coc == 'coc1') {
    if (objectId == 'system_unit') {
      return 'assets/COC1/Mission 3/System Unit.png';
    }
    final folder = switch (missionId) {
      'coc1_m2' => 'Mission 2',
      'coc1_m3' => 'Mission 3',
      _ => 'Mission 1',
    };
    final filename = switch (missionId) {
      'coc1_m3' => const {
          '24pin_cable': '24 Pin ATX.png',
          'cpu_power': 'CPU Power.png',
          'sata_data': 'Sata Cable.png',
          'sata_power': 'Sata Power.png',
          'front_panel': 'Front Panel.png',
        }[objectId],
      _ => const {
          'motherboard': 'motherboard.png',
          'cpu': 'cpu.png',
          'ram': 'ram.png',
          'psu': 'psu.png',
          'anti_static_strap': 'anti_static_wrist_strap.png',
          'storage': 'ssd.png',
          'cooling_fan': 'cooling_fan.png',
          'monitor': 'monitor.png',
          'keyboard': 'keyboard.png',
          'mouse': 'mouse.png',
        }[objectId],
    };
    return filename == null
        ? 'assets/images/COC1.png'
        : 'assets/COC1/$folder/$filename';
  }
  if (coc == 'coc2') {
    final filename = const {
      'copper_cable': 'Lan Cable.png',
      'rj45_connector': 'RJ45 Connector.png',
      'wire_stripper': 'Wire Stripper.png',
      'crimping_tool': 'Crimping Tool.png',
      'lan_cable_tester': 'LAN Tester.png',
      'router': 'Router.png',
      'switch': 'Switch.png',
      'modem': 'Modem.png',
      'network_adapter': 'NIC.png',
    }[objectId];
    return filename == null
        ? 'assets/images/COC2.png'
        : 'assets/COC2/Mission 1/$filename';
  }
  return _backgroundAssetForMission(missionId);
}

Map<String, dynamic> _progressiveDiagnostics({
  required String symptom,
  required List<(String, String, String, String)> actions,
}) {
  final factIds = actions.map((action) => action.$3).toList(growable: false);
  return {
    'component': 'troubleshooting',
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
      for (final action in actions) action.$3: action.$4,
    },
    'required_fact_ids': factIds,
  };
}
