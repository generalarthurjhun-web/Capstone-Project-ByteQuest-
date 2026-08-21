import 'package:bytequest/data/mission_content_data.dart';
import 'package:bytequest/data/mission_simulation_definitions.dart';
import 'package:bytequest/screens/simulation/runtime/mission_runtime_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const expectedIds = <String>{
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
  const expectedFamilies = <String, Set<InteractionFamily>>{
    'coc1_m1': {
      InteractionFamily.inspect,
      InteractionFamily.decide,
      InteractionFamily.testRun,
      InteractionFamily.review
    },
    'coc1_m2': {
      InteractionFamily.place,
      InteractionFamily.decide,
      InteractionFamily.testRun,
      InteractionFamily.review
    },
    'coc1_m3': {
      InteractionFamily.configure,
      InteractionFamily.decide,
      InteractionFamily.testRun,
      InteractionFamily.review
    },
    'coc1_m4': {
      InteractionFamily.connect,
      InteractionFamily.decide,
      InteractionFamily.testRun,
      InteractionFamily.review
    },
    'coc1_m5': {
      InteractionFamily.troubleshoot,
      InteractionFamily.decide,
      InteractionFamily.testRun,
      InteractionFamily.review
    },
    'coc2_m1': {
      InteractionFamily.connect,
      InteractionFamily.decide,
      InteractionFamily.testRun,
      InteractionFamily.review
    },
    'coc2_m2': {
      InteractionFamily.connect,
      InteractionFamily.decide,
      InteractionFamily.testRun,
      InteractionFamily.review
    },
    'coc2_m3': {
      InteractionFamily.connect,
      InteractionFamily.decide,
      InteractionFamily.testRun,
      InteractionFamily.review
    },
    'coc2_m4': {
      InteractionFamily.configure,
      InteractionFamily.decide,
      InteractionFamily.testRun,
      InteractionFamily.review
    },
    'coc2_m5': {
      InteractionFamily.troubleshoot,
      InteractionFamily.decide,
      InteractionFamily.testRun,
      InteractionFamily.review
    },
    'coc3_m1': {
      InteractionFamily.inspect,
      InteractionFamily.decide,
      InteractionFamily.testRun,
      InteractionFamily.review
    },
    'coc3_m2': {
      InteractionFamily.configure,
      InteractionFamily.decide,
      InteractionFamily.testRun,
      InteractionFamily.review
    },
    'coc3_m3': {
      InteractionFamily.troubleshoot,
      InteractionFamily.decide,
      InteractionFamily.testRun,
      InteractionFamily.review
    },
    'coc3_m4': {
      InteractionFamily.configure,
      InteractionFamily.decide,
      InteractionFamily.testRun,
      InteractionFamily.review
    },
    'coc3_m5': {
      InteractionFamily.troubleshoot,
      InteractionFamily.decide,
      InteractionFamily.testRun,
      InteractionFamily.review
    },
    'coc4_m1': {
      InteractionFamily.inspect,
      InteractionFamily.decide,
      InteractionFamily.testRun,
      InteractionFamily.review
    },
    'coc4_m2': {
      InteractionFamily.troubleshoot,
      InteractionFamily.decide,
      InteractionFamily.testRun,
      InteractionFamily.review
    },
    'coc4_m3': {
      InteractionFamily.troubleshoot,
      InteractionFamily.decide,
      InteractionFamily.testRun,
      InteractionFamily.review
    },
    'coc4_m4': {
      InteractionFamily.place,
      InteractionFamily.decide,
      InteractionFamily.testRun,
      InteractionFamily.review
    },
    'coc4_m5': {
      InteractionFamily.troubleshoot,
      InteractionFamily.decide,
      InteractionFamily.testRun,
      InteractionFamily.review
    },
  };
  const expectedFlows = <String, List<String>>{
    'coc1_m1': [
      'inspect_hardware',
      'select_safe_set',
      'record_observation',
      'verify_readiness',
      'review_evidence'
    ],
    'coc1_m2': [
      'inspect_compatibility',
      'place_with_orientation',
      'sequence_assembly',
      'verify_installation',
      'review_evidence'
    ],
    'coc1_m3': [
      'sequence_installation',
      'configure_and_detect_issue',
      'run_test',
      'interpret_output',
      'review_evidence'
    ],
    'coc1_m4': [
      'inspect_peripherals',
      'choose_tool',
      'connect_devices',
      'run_device_test',
      'interpret_results',
      'review_evidence'
    ],
    'coc1_m5': [
      'inspect_symptom',
      'choose_diagnostic_tool',
      'troubleshoot_progressively',
      'apply_correction',
      'verify_integration',
      'review_evidence'
    ],
    'coc2_m1': [
      'identify_materials',
      'select_tools',
      'sequence_preparation',
      'connect_cable',
      'test_and_interpret',
      'review_evidence'
    ],
    'coc2_m2': [
      'inspect_topology',
      'prepare_golden_cable',
      'connect_accessibly',
      'configure_devices',
      'verify_connectivity',
      'review_evidence'
    ],
    'coc2_m3': [
      'select_nodes',
      'connect_topology',
      'test_links',
      'fix_invalid_link',
      'verify_topology',
      'review_evidence'
    ],
    'coc2_m4': [
      'select_device',
      'configure_network',
      'test_connectivity',
      'interpret_result',
      'correct_and_retest',
      'review_evidence'
    ],
    'coc2_m5': [
      'inspect_topology_and_config',
      'test_connection',
      'troubleshoot_progressively',
      'apply_network_fix',
      'retest_network_path',
      'review_evidence'
    ],
    'coc3_m1': [
      'inspect_workspace',
      'identify_requirements',
      'decide_server_role',
      'check_readiness',
      'sequence_preparation',
      'review_evidence'
    ],
    'coc3_m2': [
      'decide_roles_and_config',
      'simulate_install',
      'simulate_restart',
      'verify_services',
      'review_evidence'
    ],
    'coc3_m3': [
      'configure_accounts_groups_permissions',
      'inspect_and_test_access',
      'diagnose_permission',
      'correct_access',
      'retest_client_access',
      'review_evidence'
    ],
    'coc3_m4': [
      'inspect_service',
      'configure_service',
      'start_stop_status',
      'test_client_access',
      'interpret_response',
      'review_evidence'
    ],
    'coc3_m5': [
      'inspect_client_and_server',
      'inspect_service_and_config',
      'troubleshoot_connectivity_permissions',
      'correct_fault',
      'retest_recovery',
      'review_evidence'
    ],
    'coc4_m1': [
      'inspect_environment_components',
      'record_symptom_observation',
      'prioritize_diagnostics',
      'state_preliminary_diagnosis',
      'verify_diagnosis',
      'review_evidence'
    ],
    'coc4_m2': [
      'inspect_symptom_component',
      'select_tool_and_test',
      'interpret_result',
      'identify_fault',
      'repair_and_verify',
      'review_evidence'
    ],
    'coc4_m3': [
      'inspect_symptoms',
      'run_software_diagnostic',
      'interpret_software_result',
      'run_network_diagnostic',
      'interpret_network_result',
      'review_evidence'
    ],
    'coc4_m4': [
      'select_component_tool',
      'replace_accessibly',
      'reconfigure_component',
      'sequence_repair',
      'run_post_repair_test',
      'review_evidence'
    ],
    'coc4_m5': [
      'inspect_request_system',
      'prioritize_issue_and_tool',
      'maintain_repair_config',
      'test_and_interpret',
      'final_verify',
      'review_evidence'
    ],
  };

  test('catalog exposes the exact immutable twenty-mission matrix', () {
    final definitions = MissionSimulationDefinitions.all;

    expect(definitions, hasLength(20));
    expect(definitions.map((item) => item.id).toSet(), expectedIds);
    expect(() => definitions.add(definitions.first), throwsUnsupportedError);
    for (final id in expectedIds) {
      expect(MissionSimulationDefinitions.byId(id).id, id);
    }
    expect(
      () => MissionSimulationDefinitions.byId('coc5_m1'),
      throwsA(isA<ArgumentError>().having(
        (error) => error.message.toString(),
        'message',
        contains('Unknown mission simulation definition'),
      )),
    );
  });

  test('definitions retain the approved ordered workflows and family groups',
      () {
    for (final definition in MissionSimulationDefinitions.all) {
      expect(definition.phases.length, inInclusiveRange(3, 6),
          reason: definition.id);
      expect(definition.interactionFamilies, expectedFamilies[definition.id],
          reason: definition.id);
      expect(definition.hasTechnicalDecision, isTrue, reason: definition.id);
      expect(definition.hasVerification, isTrue, reason: definition.id);
      expect(
          definition.phases.last.primaryInteraction, InteractionFamily.review,
          reason: definition.id);
      expect(
        definition.phases
            .expand((phase) =>
                (phase.presentation['mechanics'] as List? ?? const [])
                    .whereType<String>())
            .toList(),
        expectedFlows[definition.id],
        reason: definition.id,
      );
      expect(definition.reviewMetadata['title'], isNotEmpty,
          reason: definition.id);
      expect(definition.reviewMetadata['returnLabel'], isNotEmpty,
          reason: definition.id);
      expect(definition.reviewMetadata['confirmLabel'], isNotEmpty,
          reason: definition.id);
    }
  });

  test('every mission provides schematic hotspots and resolvable feedback', () {
    for (final definition in MissionSimulationDefinitions.all) {
      expect(definition.scene.objects, isNotEmpty, reason: definition.id);
      expect(definition.scene.initialStatus['schematic'], isTrue,
          reason: definition.id);
      for (final object in definition.scene.objects) {
        expect(object.hotspotType, isNotEmpty,
            reason: '${definition.id}/${object.id}');
        expect(object.metadata['schematicRole'], isNotEmpty,
            reason: '${definition.id}/${object.id}');
        expect(object.metadata['replaceableAsset'], isNotEmpty,
            reason: '${definition.id}/${object.id}');
      }
      final ownedCatalog = MissionContentData.feedbackForMission(definition.id);
      expect(definition.feedbackCatalog, ownedCatalog, reason: definition.id);
      for (final phase in definition.phases) {
        expect(phase.feedbackIds, isNotEmpty,
            reason: '${definition.id}/${phase.id}');
        for (final feedbackId in phase.feedbackIds) {
          expect(ownedCatalog[feedbackId], isNotNull,
              reason: '${definition.id}/$feedbackId');
        }
      }
    }
  });

  test('troubleshooting is progressive and connections never require dragging',
      () {
    for (final definition in MissionSimulationDefinitions.all) {
      if (definition.interactionFamilies
          .contains(InteractionFamily.troubleshoot)) {
        final diagnostics = definition.phases
            .expand((phase) =>
                (phase.presentation['diagnostic_actions'] as List? ?? const [])
                    .whereType<Map>())
            .toList();
        expect(diagnostics.length, greaterThanOrEqualTo(2),
            reason: definition.id);
        expect(
            diagnostics.every((action) => action['reveals_fact_id'] is String),
            isTrue,
            reason: definition.id);
      }
      if (definition.interactionFamilies.contains(InteractionFamily.connect) ||
          definition.interactionFamilies.contains(InteractionFamily.place)) {
        expect(
          definition.phases.any((phase) =>
              phase.presentation['accessibleControl'] == 'select_then_confirm'),
          isTrue,
          reason: '${definition.id} must not be drag-only',
        );
      }
    }
  });

  test('diagnostic phases cannot expose ordered correction or retest controls',
      () {
    const expectedControls = <String, Map<String, String>>{
      'coc1_m5': {
        'correctionMechanic': 'apply_correction',
        'correctionId': 'apply_integration_correction',
        'retestMechanic': 'verify_integration',
        'retestId': 'retest_integration',
      },
      'coc2_m5': {
        'correctionMechanic': 'apply_network_fix',
        'correctionId': 'apply_network_fix',
        'retestMechanic': 'retest_network_path',
        'retestId': 'retest_network_path',
      },
      'coc3_m3': {
        'correctionMechanic': 'correct_access',
        'correctionId': 'apply_permission_change',
        'retestMechanic': 'retest_client_access',
        'retestId': 'retest_client_access',
      },
      'coc3_m5': {
        'correctionMechanic': 'correct_fault',
        'correctionId': 'apply_service_recovery',
        'retestMechanic': 'retest_recovery',
        'retestId': 'retest_service_access',
      },
      'coc4_m2': {
        'correctionMechanic': 'identify_fault',
        'correctionId': 'apply_component_repair',
        'retestMechanic': 'repair_and_verify',
        'retestId': 'retest_component',
      },
      'coc4_m5': {
        'correctionMechanic': 'maintain_repair_config',
        'correctionId': 'approve_maintenance_action',
        'retestMechanic': 'test_and_interpret',
        'retestId': 'run_maintenance_check',
      },
    };

    for (final entry in expectedControls.entries) {
      final definition = MissionSimulationDefinitions.byId(entry.key);
      final diagnosticIndexes = <int>[];
      for (var index = 0; index < definition.phases.length; index++) {
        final presentation = definition.phases[index].presentation;
        if (presentation['diagnostic_actions'] is! List) continue;
        diagnosticIndexes.add(index);
        expect(presentation, isNot(contains('correction')),
            reason: definition.phases[index].id);
        expect(presentation, isNot(contains('retest')),
            reason: definition.phases[index].id);
      }

      final correctionPhase = _phaseByMechanic(
        definition,
        entry.value['correctionMechanic']!,
      );
      final retestPhase = _phaseByMechanic(
        definition,
        entry.value['retestMechanic']!,
      );
      final correctionChoices =
          (correctionPhase.presentation['choices'] as List? ?? const [])
              .whereType<Map>();
      expect(
        correctionPhase.primaryInteraction,
        InteractionFamily.decide,
        reason: correctionPhase.id,
      );
      expect(
        correctionChoices.single['id'],
        entry.value['correctionId'],
        reason: correctionPhase.id,
      );
      expect(
        correctionChoices.single['label'],
        isNotEmpty,
        reason: correctionPhase.id,
      );
      expect(
        retestPhase.primaryInteraction,
        InteractionFamily.testRun,
        reason: retestPhase.id,
      );
      expect(
        retestPhase.presentation['actionType'],
        'retest_requested',
        reason: retestPhase.id,
      );
      expect(
        retestPhase.presentation['target'],
        entry.value['retestId'],
        reason: retestPhase.id,
      );
      expect(
        definition.phases.indexOf(correctionPhase),
        greaterThan(diagnosticIndexes.last),
        reason: entry.key,
      );
      expect(
        definition.phases.indexOf(retestPhase),
        greaterThan(diagnosticIndexes.last),
        reason: entry.key,
      );
      expect(correctionPhase.presentation, isNot(contains('correction')),
          reason: correctionPhase.id);
      expect(correctionPhase.presentation, isNot(contains('retest')),
          reason: correctionPhase.id);
      expect(retestPhase.presentation, isNot(contains('correction')),
          reason: retestPhase.id);
      expect(retestPhase.presentation, isNot(contains('retest')),
          reason: retestPhase.id);
    }
  });

  test('diagnostic actions reveal concrete technical observations', () {
    final domainState = RegExp(
      r'\b(?:up|down|running|stopped|allowed|granted|unavailable|timeout|timeouts|unreachable|warning|caution|error|errors|reply|replies|reset|resets|listening|overdue|gateway|group|read|modify|change|access|token)\b|\b\d+(?:\.\d+)?\s*(?:operating\s+)?(?:ms|mbps|gbps|v|rpm|°c|days?|seconds?|sectors?)\b',
      caseSensitive: false,
    );
    final placeholder = RegExp(
      r'\b(?:recorded result from|reports result|records result|lists result)\b',
      caseSensitive: false,
    );

    for (final definition in MissionSimulationDefinitions.all) {
      for (final phase in definition.phases) {
        final presentation = phase.presentation;
        final actions =
            (presentation['diagnostic_actions'] as List? ?? const [])
                .whereType<Map>();
        final facts = (presentation['facts'] as Map? ?? const {});
        for (final action in actions) {
          final factId = action['reveals_fact_id'];
          final fact = facts[factId]?.toString() ?? '';
          expect(placeholder.hasMatch(fact), isFalse, reason: phase.id);
          expect(domainState.hasMatch(fact), isTrue, reason: phase.id);
        }
      }
    }
  });

  test('COC4 M3 interleaves each diagnostic with its interpretation phase', () {
    final definition = MissionSimulationDefinitions.byId('coc4_m3');
    final phases = definition.phases;
    final diagnosticIndexes = <int>[
      for (var index = 0; index < phases.length; index++)
        if (phases[index].presentation['diagnostic_actions'] is List) index,
    ];

    expect(diagnosticIndexes, [1, 3]);
    for (final index in diagnosticIndexes) {
      final diagnostic = phases[index];
      final interpretation = phases[index + 1];
      final actions = (diagnostic.presentation['diagnostic_actions'] as List)
          .whereType<Map>();
      expect(actions, hasLength(1), reason: diagnostic.id);
      final factId = actions.single['reveals_fact_id'];
      expect(
        interpretation.presentation['source_fact_ids'],
        [factId],
        reason: interpretation.id,
      );
      expect(
        diagnostic.presentation,
        isNot(contains('interpretation_required_after_each')),
        reason: diagnostic.id,
      );
    }
  });

  test('learner definitions contain no evaluator answers or reward fields', () {
    const prohibited = <String>{
      'answer',
      'answerkey',
      'correctanswer',
      'acceptedcategories',
      'expected',
      'expectedanswer',
      'score',
      'passingscore',
      'pass',
      'xp',
      'xpreward',
      'reward',
    };
    for (final definition in MissionSimulationDefinitions.all) {
      final normalizedKeys = _keys(definition.toJson())
          .map((key) => key.toLowerCase().replaceAll('_', ''))
          .toSet();
      expect(
        normalizedKeys.intersection(prohibited),
        isEmpty,
        reason: definition.id,
      );
    }
  });
}

Set<String> _keys(dynamic value) {
  if (value is Map) {
    return {
      ...value.keys.map((key) => key.toString()),
      ...value.values.expand(_keys),
    };
  }
  if (value is Iterable) return value.expand(_keys).toSet();
  return const {};
}

MissionPhaseDefinition _phaseByMechanic(
  MissionSimulationDefinition definition,
  String mechanic,
) =>
    definition.phases.singleWhere(
      (phase) => (phase.presentation['mechanics'] as List? ?? const [])
          .contains(mechanic),
    );
