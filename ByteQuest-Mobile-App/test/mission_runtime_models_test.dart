import 'package:bytequest/screens/simulation/runtime/mission_runtime_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('runtime state round trip preserves resume-critical fields', () {
    final state = MissionRuntimeState.initial('coc2_m3').copyWith(
      currentPhaseId: 'verify_links',
      selectedToolId: 'lan_tester',
      connectedNodePairs: const {'pc1>switch1'},
      acceptedEvidenceIds: const {'action-1'},
    );

    expect(MissionRuntimeState.fromJson(state.toJson()), state);
  });

  test('definition rejects phase counts outside three to six', () {
    expect(
      () => _definition(phases: const []),
      throwsArgumentError,
    );
    expect(
      () => _definition(
        phases: List.generate(7, (index) => _phase(id: 'phase-$index')),
      ),
      throwsArgumentError,
    );
  });

  test('definition rejects duplicate phase IDs', () {
    expect(
      () => _definition(
        phases: [
          _phase(id: 'inspect'),
          _phase(id: 'inspect'),
          _phase(id: 'verify'),
        ],
      ),
      throwsArgumentError,
    );
  });

  test('definition rejects declared and rendered interaction divergence', () {
    final divergent = MissionPhaseDefinition(
      id: 'choose-components',
      title: 'Choose components',
      instruction: 'Select the required components.',
      primaryInteraction: InteractionFamily.decide,
      presentation: const {
        'component': 'multi_select',
        'options': [
          {'id': 'memory', 'label': 'Memory module'},
        ],
      },
    );

    expect(
      () => _definition(
        phases: [
          divergent,
          _phase(id: 'verify', primaryInteraction: InteractionFamily.testRun),
          _phase(id: 'review', primaryInteraction: InteractionFamily.review),
        ],
        interactionFamilies: const {
          InteractionFamily.decide,
          InteractionFamily.testRun,
          InteractionFamily.review,
        },
      ),
      throwsArgumentError,
    );
  });

  test('rendered selection is a real technical decision family', () {
    final definition = _definition(
      phases: [
        MissionPhaseDefinition(
          id: 'select',
          title: 'Select components',
          instruction: 'Choose the components required for service.',
          primaryInteraction: InteractionFamily.select,
          presentation: const {
            'component': 'multi_select',
            'options': [
              {'id': 'memory', 'label': 'Memory module'},
            ],
          },
        ),
        _phase(id: 'verify', primaryInteraction: InteractionFamily.testRun),
        _phase(id: 'review', primaryInteraction: InteractionFamily.review),
      ],
      interactionFamilies: const {
        InteractionFamily.select,
        InteractionFamily.testRun,
      },
    );

    expect(definition.interactionFamilies, {
      InteractionFamily.select,
      InteractionFamily.testRun,
    });
    expect(definition.hasTechnicalDecision, isTrue);
  });

  test('definition rejects interaction family counts outside two to four', () {
    expect(
      () => _definition(
        phases: [
          _phase(id: 'inspect'),
          _phase(id: 'inspect-ports'),
          _phase(id: 'inspect-cable'),
        ],
        interactionFamilies: const {InteractionFamily.inspect},
      ),
      throwsArgumentError,
    );
    expect(
      () => _definition(
        phases: [
          _phase(id: 'inspect'),
          _phase(id: 'select', primaryInteraction: InteractionFamily.select),
          _phase(id: 'tool', primaryInteraction: InteractionFamily.tool),
          _phase(id: 'connect', primaryInteraction: InteractionFamily.connect),
          _phase(id: 'decide', primaryInteraction: InteractionFamily.decide),
          _phase(id: 'verify', primaryInteraction: InteractionFamily.testRun),
        ],
        interactionFamilies: const {
          InteractionFamily.inspect,
          InteractionFamily.select,
          InteractionFamily.tool,
          InteractionFamily.connect,
          InteractionFamily.configure,
        },
      ),
      throwsArgumentError,
    );
  });

  test(
      'definition rejects decision and verification absent from phase interactions',
      () {
    expect(
      () => _definition(
        phases: [
          _phase(id: 'inspect'),
          _phase(id: 'connect', primaryInteraction: InteractionFamily.connect),
          _phase(id: 'verify', primaryInteraction: InteractionFamily.testRun),
        ],
        interactionFamilies: const {
          InteractionFamily.inspect,
          InteractionFamily.connect,
          InteractionFamily.testRun,
        },
      ),
      throwsArgumentError,
    );
    expect(
      () => _definition(
        phases: [
          _phase(id: 'inspect'),
          _phase(id: 'connect', primaryInteraction: InteractionFamily.connect),
          _phase(id: 'decide', primaryInteraction: InteractionFamily.decide),
        ],
        interactionFamilies: const {
          InteractionFamily.inspect,
          InteractionFamily.connect,
          InteractionFamily.decide,
        },
      ),
      throwsArgumentError,
    );
  });

  test('valid definition derives required interactions from typed phases', () {
    final phaseSource = [
      _phase(id: 'inspect'),
      _phase(id: 'decide', primaryInteraction: InteractionFamily.decide),
      _phase(id: 'verify', primaryInteraction: InteractionFamily.testRun),
    ];
    final objectSource = [
      SceneObjectDefinition(
        id: 'switch',
        label: 'Network switch',
        x: 0.25,
        y: 0.4,
        width: 0.2,
        height: 0.15,
        hotspotType: 'device',
      ),
    ];
    final definition = _definition(phases: phaseSource, objects: objectSource);
    phaseSource.add(_phase(id: 'outside'));
    objectSource.clear();

    expect(definition.phases, hasLength(3));
    expect(definition.scene.objects.single.id, 'switch');
    expect(definition.interactionFamilies, {
      InteractionFamily.inspect,
      InteractionFamily.decide,
      InteractionFamily.testRun,
    });
    expect(definition.hasTechnicalDecision, isTrue);
    expect(definition.hasVerification, isTrue);
  });

  test('evidence deep-copies structured action values', () {
    final source = <String, dynamic>{
      'nested': <String, dynamic>{'port': '1'},
      'tools': <String>['crimper'],
      'states': <String>{'queued'},
    };
    final evidence = MissionEvidenceAction(
      clientActionId: 'action-1',
      missionId: 'coc2_m3',
      phaseId: 'inspect',
      actionType: 'inspect_object',
      value: source,
      occurredAt: DateTime.utc(2026),
    );
    (source['nested'] as Map<String, dynamic>)['port'] = '2';
    (source['tools'] as List<String>).add('lan_tester');
    (source['states'] as Set<String>).add('sent');

    expect(evidence.value['nested'], {'port': '1'});
    expect(evidence.value['tools'], ['crimper']);
    expect(evidence.value['states'], ['queued']);
  });

  test('copyWith can explicitly clear optional phase and tool selections', () {
    final state = MissionRuntimeState.initial('coc2_m3').copyWith(
      currentPhaseId: 'inspect',
      selectedToolId: 'crimper',
    );

    final cleared = state.copyWith(
      clearCurrentPhaseId: true,
      clearSelectedToolId: true,
    );

    expect(cleared.currentPhaseId, isNull);
    expect(cleared.selectedToolId, isNull);
  });

  test('test lifecycle status is typed and survives state serialization', () {
    final running = MissionRuntimeState.initial('coc2_m3').withTestStatus(
      'uplink-check',
      MissionTestStatus.running,
    );

    expect(
      running.testStatusFor('uplink-check'),
      MissionTestStatus.running,
    );
    expect(
      running.testStatusFor('not-started'),
      MissionTestStatus.idle,
    );
    final restored = MissionRuntimeState.fromJson(running.toJson());
    expect(
      restored.testStatusFor('uplink-check'),
      MissionTestStatus.running,
    );
  });
}

MissionSimulationDefinition _definition({
  List<MissionPhaseDefinition>? phases,
  List<SceneObjectDefinition>? objects,
  Set<InteractionFamily>? interactionFamilies,
}) {
  final definitionPhases = phases ??
      [
        _phase(id: 'inspect'),
        _phase(id: 'decide', primaryInteraction: InteractionFamily.decide),
        _phase(id: 'verify', primaryInteraction: InteractionFamily.testRun),
      ];
  return MissionSimulationDefinition(
    id: 'coc2_m3',
    cocId: 'coc2',
    title: 'Connect the workstation',
    scenario: 'A workstation needs a verified network connection.',
    environmentLabel: 'Networking lab',
    practiceGuidance: 'Inspect the switch before connecting the cable.',
    scene: SimulationSceneDefinition(
      id: 'network-lab',
      objects: objects ??
          [
            SceneObjectDefinition(
              id: 'switch',
              label: 'Network switch',
              x: 0.25,
              y: 0.4,
              width: 0.2,
              height: 0.15,
              hotspotType: 'device',
              connectionNodeIds: ['switch1'],
            ),
          ],
    ),
    phases: definitionPhases,
    interactionFamilies: interactionFamilies ??
        definitionPhases.map((phase) => phase.primaryInteraction).toSet(),
  );
}

MissionPhaseDefinition _phase({
  required String id,
  InteractionFamily primaryInteraction = InteractionFamily.inspect,
}) {
  return MissionPhaseDefinition(
    id: id,
    title: id,
    instruction: 'Complete $id.',
    primaryInteraction: primaryInteraction,
  );
}
