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
      'fix_and_retest',
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
      'inspect_access',
      'test_access',
      'diagnose_permission',
      'correct_access',
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

  test('COC4 M3 requires interpretation after every diagnostic result', () {
    final definition = MissionSimulationDefinitions.byId('coc4_m3');
    final diagnosticPhases = definition.phases.where(
      (phase) => phase.presentation['diagnostic_actions'] is List,
    );

    expect(diagnosticPhases, hasLength(2));
    for (final phase in diagnosticPhases) {
      expect(
        phase.presentation['interpretation_required_after_each'],
        isTrue,
        reason: phase.id,
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
