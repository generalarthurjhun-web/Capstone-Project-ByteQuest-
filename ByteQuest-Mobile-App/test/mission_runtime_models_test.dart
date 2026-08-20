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

  test('definition rejects interaction family counts outside two to four', () {
    expect(
      () => _definition(interactionFamilies: const {InteractionFamily.inspect}),
      throwsArgumentError,
    );
    expect(
      () => _definition(
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

  test('definition rejects missing technical decision or verification', () {
    expect(
      () => _definition(hasTechnicalDecision: false),
      throwsArgumentError,
    );
    expect(
      () => _definition(hasVerification: false),
      throwsArgumentError,
    );
  });

  test('valid definition keeps immutable scene and phase metadata', () {
    final definition = _definition();

    expect(definition.phases, hasLength(3));
    expect(definition.scene.objects.single.id, 'switch');
    expect(definition.interactionFamilies, {
      InteractionFamily.inspect,
      InteractionFamily.connect,
    });
  });
}

MissionSimulationDefinition _definition({
  List<MissionPhaseDefinition>? phases,
  Set<InteractionFamily>? interactionFamilies,
  bool hasTechnicalDecision = true,
  bool hasVerification = true,
}) {
  return MissionSimulationDefinition(
    id: 'coc2_m3',
    cocId: 'coc2',
    title: 'Connect the workstation',
    scenario: 'A workstation needs a verified network connection.',
    environmentLabel: 'Networking lab',
    practiceGuidance: 'Inspect the switch before connecting the cable.',
    scene: SimulationSceneDefinition(
      id: 'network-lab',
      objects: [
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
    phases: phases ??
        [
          _phase(id: 'inspect'),
          _phase(id: 'connect'),
          _phase(id: 'verify'),
        ],
    interactionFamilies: interactionFamilies ??
        const {InteractionFamily.inspect, InteractionFamily.connect},
    hasTechnicalDecision: hasTechnicalDecision,
    hasVerification: hasVerification,
  );
}

MissionPhaseDefinition _phase({required String id}) {
  return MissionPhaseDefinition(
    id: id,
    title: id,
    instruction: 'Complete $id.',
    primaryInteraction: InteractionFamily.inspect,
  );
}
