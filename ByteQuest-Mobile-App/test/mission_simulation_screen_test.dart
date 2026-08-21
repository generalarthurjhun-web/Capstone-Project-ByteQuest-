import 'dart:async';

import 'package:bytequest/data/mission_simulation_definitions.dart';
import 'package:bytequest/models/mission_model.dart';
import 'package:bytequest/screens/simulation/components/simulation_scene.dart';
import 'package:bytequest/screens/simulation/interactions/mission_interactions.dart';
import 'package:bytequest/screens/simulation/mission_simulation_screen.dart';
import 'package:bytequest/screens/simulation/runtime/mission_evidence_gateway.dart';
import 'package:bytequest/screens/simulation/runtime/mission_runtime_controller.dart';
import 'package:bytequest/screens/simulation/runtime/mission_runtime_models.dart';
import 'package:bytequest/services/progress_resume_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MissionSimulationScreen', () {
    testWidgets('restores before exposing the interactive workspace',
        (tester) async {
      final definition = MissionSimulationDefinitions.byId('coc1_m1');
      final store = _MemoryStore()..loadGate = Completer<void>();

      await tester.pumpWidget(_host(
        definition,
        controller: _controller(definition, store: store),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(SimulationScene), findsNothing);

      store.loadGate!.complete();
      await tester.pumpAndSettle();

      expect(find.byType(SimulationScene), findsOneWidget);
      expect(store.saveCount, 0);
    });

    testWidgets('unknown restored phase fails closed and can reset safely',
        (tester) async {
      final definition = MissionSimulationDefinitions.byId('coc1_m1');
      final store = _MemoryStore()
        ..saved = MissionRuntimeState.initial(definition.id).copyWith(
          currentPhaseId: 'removed-catalog-phase',
        );

      await tester.pumpWidget(_host(
        definition,
        controller: _controller(definition, store: store),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(TechnicalUnavailableState), findsOneWidget);
      expect(find.byType(TapInspectInteraction), findsNothing);

      await tester.tap(find.text('Reset saved progress'));
      await tester.pumpAndSettle();

      expect(store.clearCount, 1);
      expect(find.byType(TechnicalUnavailableState), findsNothing);
      expect(find.byType(TapInspectInteraction), findsOneWidget);
    });

    testWidgets(
        'keeps the scene visible and controls scrollable at target sizes',
        (tester) async {
      final definition = MissionSimulationDefinitions.byId('coc1_m1');
      for (final size in const [
        Size(360, 800),
        Size(800, 360),
        Size(1280, 800),
      ]) {
        tester.view
          ..physicalSize = size
          ..devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_host(
          definition,
          controller: _controller(definition),
          textScale: 2,
        ));
        await tester.pumpAndSettle();

        expect(find.byType(SimulationScene), findsOneWidget, reason: '$size');
        expect(
          find.byKey(const ValueKey('mission-controls-scroll')),
          findsOneWidget,
          reason: '$size',
        );
        expect(tester.takeException(), isNull, reason: '$size');
      }
    });

    testWidgets('persists once for a pause lifecycle event', (tester) async {
      final definition = MissionSimulationDefinitions.byId('coc1_m1');
      final store = _MemoryStore();

      await tester.pumpWidget(_host(
        definition,
        controller: _controller(definition, store: store),
      ));
      await tester.pumpAndSettle();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();

      expect(store.saveCount, 1);
    });

    testWidgets('requests landscape on entry and restores orientations on exit',
        (tester) async {
      final definition = MissionSimulationDefinitions.byId('coc1_m1');
      final orientation = _FakeOrientationCoordinator();

      await tester.pumpWidget(_host(
        definition,
        controller: _controller(definition),
        orientationCoordinator: orientation,
      ));
      await tester.pumpAndSettle();
      expect(orientation.landscapeRequests, 1);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(orientation.restoreRequests, 1);
    });

    testWidgets('reaches review, can return, and submits only on confirmation',
        (tester) async {
      final definition = MissionSimulationDefinitions.byId('coc1_m1');
      var submissions = 0;

      await tester.pumpWidget(_host(
        definition,
        controller: _controller(definition),
        onSubmit: () async => submissions++,
      ));
      await tester.pumpAndSettle();

      for (var index = 1; index < definition.phases.length; index++) {
        final next = find.byKey(const ValueKey('mission-next'));
        await tester.ensureVisible(next);
        await tester.tap(next);
        await tester.pumpAndSettle();
      }

      expect(find.byType(EvidenceReviewPanel), findsOneWidget);
      expect(submissions, 0);

      final returnButton = find.text('Return to mission');
      await tester.ensureVisible(returnButton);
      await tester.tap(returnButton);
      await tester.pumpAndSettle();
      expect(find.byType(EvidenceReviewPanel), findsNothing);

      final next = find.byKey(const ValueKey('mission-next'));
      await tester.ensureVisible(next);
      await tester.tap(next);
      await tester.pumpAndSettle();
      final confirmButton = find.text('Confirm evidence');
      await tester.ensureVisible(confirmButton);
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      expect(submissions, 1);
    });

    testWidgets('successful submission disables a second confirmation',
        (tester) async {
      final definition = MissionSimulationDefinitions.byId('coc1_m1');
      var submissions = 0;

      await tester.pumpWidget(_host(
        definition,
        controller: _controller(definition),
        onSubmit: () async => submissions++,
      ));
      await tester.pumpAndSettle();
      await _advanceToReview(tester, definition);

      final confirmText = find.text('Confirm evidence');
      await tester.ensureVisible(confirmText);
      await tester.tap(confirmText);
      await tester.pumpAndSettle();

      final confirmButton = tester.widget<FilledButton>(
        find.ancestor(
          of: confirmText,
          matching: find.byType(FilledButton),
        ),
      );
      expect(confirmButton.onPressed, isNull);

      await tester.tap(confirmText, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(submissions, 1);
    });

    testWidgets('incompatible placement never renders as installed',
        (tester) async {
      final definition = _incompatiblePlacementDefinition();
      final controller = _controller(definition);

      await tester.pumpWidget(_host(
        definition,
        controller: controller,
      ));
      await tester.pumpAndSettle();

      final item = find.byKey(const ValueKey('placement-item-memory'));
      await tester.ensureVisible(item);
      await tester.tap(item);
      await tester.pump();
      final destination =
          find.byKey(const ValueKey('placement-destination-cpu-socket'));
      await tester.ensureVisible(destination);
      await tester.tap(destination);
      await tester.pump();
      final place = find.byKey(const ValueKey('placement-place'));
      await tester.ensureVisible(place);
      await tester.tap(place);
      await tester.pumpAndSettle();

      expect(controller.state.placements, isEmpty);
      expect(
        find.byKey(const ValueKey('placement-state-memory')),
        findsNothing,
      );
      expect(controller.state.acceptedEvidenceIds, hasLength(1));
    });
  });

  group('MissionPhaseInteraction', () {
    final expectedWidgets = <InteractionFamily, Type>{
      InteractionFamily.inspect: TapInspectInteraction,
      InteractionFamily.select: MultiSelectInteraction,
      InteractionFamily.tool: ToolSelectionInteraction,
      InteractionFamily.connect: ConnectionInteraction,
      InteractionFamily.configure: ConfigurationPanel,
      InteractionFamily.sequence: SequencingInteraction,
      InteractionFamily.match: MatchingInteraction,
      InteractionFamily.place: ControlledPlacementInteraction,
      InteractionFamily.troubleshoot: TroubleshootingBranchInteraction,
      InteractionFamily.testRun: TestRunInteraction,
      InteractionFamily.observe: ObservationInteraction,
      InteractionFamily.decide: ScenarioDecisionInteraction,
      InteractionFamily.interpret: ResultInterpretationInteraction,
      InteractionFamily.review: EvidenceReviewPanel,
    };

    for (final entry in expectedWidgets.entries) {
      testWidgets('maps ${entry.key.name} to ${entry.value}', (tester) async {
        final phase = _phase(entry.key);
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MissionPhaseInteraction(
                phase: phase,
                state: MissionRuntimeState.initial('test').copyWith(
                  currentPhaseId: phase.id,
                ),
                onAction: (_, __, ___) async {},
                onRuntimeTransition: (_) {},
                onReturnFromReview: () {},
                onConfirmReview: () {},
              ),
            ),
          ),
        ));

        expect(find.byType(entry.value), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('shows technical unavailable for an unknown component override',
        (tester) async {
      final phase = MissionPhaseDefinition(
        id: 'broken',
        title: 'Broken phase',
        instruction: 'Unavailable',
        primaryInteraction: InteractionFamily.connect,
        presentation: const {'component': 'not_registered'},
      );
      await tester.pumpWidget(MaterialApp(
        home: MissionPhaseInteraction(
          phase: phase,
          state: MissionRuntimeState.initial('test'),
          onAction: (_, __, ___) async {},
          onRuntimeTransition: (_) {},
          onReturnFromReview: () {},
          onConfirmReview: () {},
        ),
      ));

      expect(find.byType(TechnicalUnavailableState), findsOneWidget);
      expect(find.textContaining('not available'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

Widget _host(
  MissionSimulationDefinition definition, {
  required MissionRuntimeController controller,
  MissionOrientationCoordinator? orientationCoordinator,
  MissionSubmitCallback? onSubmit,
  double textScale = 1,
}) {
  return MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
      ),
      child: child!,
    ),
    home: MissionSimulationScreen(
      mission: _mission(definition.id),
      definition: definition,
      controller: controller,
      orientationCoordinator:
          orientationCoordinator ?? _FakeOrientationCoordinator(),
      onSubmit: onSubmit,
    ),
  );
}

MissionRuntimeController _controller(
  MissionSimulationDefinition definition, {
  _MemoryStore? store,
}) {
  return MissionRuntimeController(
    userId: 'learner-1',
    initialState: MissionRuntimeState.initial(definition.id).copyWith(
      currentPhaseId: definition.phases.first.id,
    ),
    store: store ?? _MemoryStore(),
    evidenceGateway: MissionEvidenceGateway(transport: _MemoryTransport()),
    submissionPhaseIds: {definition.phases.last.id},
    clientActionIdFactory: _sequentialIds(),
  );
}

MissionSimulationDefinition _incompatiblePlacementDefinition() =>
    MissionSimulationDefinition(
      id: 'coc1_m9',
      cocId: 'coc1',
      title: 'Verify component placement',
      scenario: 'A memory module must be installed in a compatible socket.',
      environmentLabel: 'Hardware lab',
      practiceGuidance: 'Match component category to socket category.',
      scene: SimulationSceneDefinition(
        id: 'hardware-lab',
        objects: [
          SceneObjectDefinition(
            id: 'workbench',
            label: 'Hardware workbench',
            x: .2,
            y: .2,
            width: .4,
            height: .4,
            hotspotType: 'workbench',
          ),
        ],
      ),
      phases: [
        MissionPhaseDefinition(
          id: 'place-component',
          title: 'Place component',
          instruction: 'Install the memory module.',
          primaryInteraction: InteractionFamily.place,
          presentation: const {
            'items': [
              {
                'id': 'memory',
                'label': 'Memory module',
                'category': 'dimm',
              },
            ],
            'destinations': [
              {
                'id': 'cpu-socket',
                'label': 'CPU socket',
                'accepted_categories': ['processor'],
              },
            ],
          },
        ),
        MissionPhaseDefinition(
          id: 'decide',
          title: 'Decide',
          instruction: 'Choose the safe response.',
          primaryInteraction: InteractionFamily.decide,
          presentation: const {
            'choices': [
              {'id': 'stop', 'label': 'Stop and inspect compatibility'},
            ],
          },
        ),
        MissionPhaseDefinition(
          id: 'verify',
          title: 'Verify',
          instruction: 'Run the verification test.',
          primaryInteraction: InteractionFamily.testRun,
        ),
      ],
      interactionFamilies: const {
        InteractionFamily.place,
        InteractionFamily.decide,
        InteractionFamily.testRun,
      },
    );

Future<void> _advanceToReview(
  WidgetTester tester,
  MissionSimulationDefinition definition,
) async {
  for (var index = 1; index < definition.phases.length; index++) {
    final next = find.byKey(const ValueKey('mission-next'));
    await tester.ensureVisible(next);
    await tester.tap(next);
    await tester.pumpAndSettle();
  }
}

ClientActionIdFactory _sequentialIds() {
  var value = 0;
  return () => 'action-${value++}';
}

Mission _mission(String id) => Mission(
      id: id,
      cocId: id.substring(0, 4),
      missionCode: id.toUpperCase(),
      missionNumber: int.parse(id.substring(id.length - 1)),
      title: id,
      missionType: MissionType.identification,
      orderIndex: 1,
    );

MissionPhaseDefinition _phase(InteractionFamily family) {
  final presentation = switch (family) {
    InteractionFamily.inspect => const {
        'objects': [
          {'id': 'device', 'label': 'Device'}
        ],
      },
    InteractionFamily.select => const {
        'options': [
          {'id': 'device', 'label': 'Device'}
        ],
      },
    InteractionFamily.tool => const {
        'targets': [
          {'id': 'device', 'label': 'Device'}
        ],
        'tools': [
          {'id': 'meter', 'label': 'Meter'}
        ],
      },
    InteractionFamily.connect || InteractionFamily.match => const {
        'sources': [
          {'id': 'source', 'label': 'Source'}
        ],
        'destinations': [
          {'id': 'destination', 'label': 'Destination'}
        ],
      },
    InteractionFamily.configure => const {
        'fields': [
          {'id': 'address', 'label': 'Address'}
        ],
      },
    InteractionFamily.sequence => const {
        'steps': [
          {'id': 'step', 'label': 'Step'}
        ],
      },
    InteractionFamily.place => const {
        'items': [
          {'id': 'part', 'label': 'Part'}
        ],
        'destinations': [
          {'id': 'slot', 'label': 'Slot'}
        ],
      },
    InteractionFamily.troubleshoot => const {
        'diagnostic_actions': [
          {
            'id': 'inspect',
            'label': 'Inspect',
            'reveals_fact_id': 'fact',
          }
        ],
        'facts': {'fact': 'The link indicator remains dark.'},
        'required_fact_ids': ['fact'],
      },
    InteractionFamily.decide => const {
        'choices': [
          {'id': 'isolate', 'label': 'Isolate the device'}
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

final class _MemoryStore implements MissionRuntimeStore {
  MissionRuntimeState? saved;
  Completer<void>? loadGate;
  int saveCount = 0;
  int clearCount = 0;

  @override
  Future<bool> clearMissionRuntime({
    required String userId,
    required String missionId,
    required MissionRuntimeMode mode,
    String? assessmentAttemptId,
  }) async {
    clearCount++;
    saved = null;
    return true;
  }

  @override
  Future<MissionRuntimeState?> loadMissionRuntime({
    required String userId,
    required String missionId,
    required MissionRuntimeMode mode,
    String? assessmentAttemptId,
  }) async {
    await loadGate?.future;
    return saved;
  }

  @override
  Future<bool> saveMissionRuntime({
    required String userId,
    required MissionRuntimeState state,
  }) async {
    saveCount++;
    saved = state;
    return true;
  }
}

final class _MemoryTransport implements MissionEvidenceTransport {
  final Set<String> accepted = <String>{};

  @override
  Future<Set<String>> acknowledgedClientActionIds() async => accepted;

  @override
  Future<void> append(MissionEvidenceAction action) async {
    accepted.add(action.clientActionId);
  }
}

final class _FakeOrientationCoordinator
    implements MissionOrientationCoordinator {
  int landscapeRequests = 0;
  int restoreRequests = 0;

  @override
  Future<void> requestLandscape() async => landscapeRequests++;

  @override
  Future<void> restoreSupportedOrientations() async => restoreRequests++;
}
