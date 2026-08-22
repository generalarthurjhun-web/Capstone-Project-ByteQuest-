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
    testWidgets('does not advance before the active interaction is terminal',
        (tester) async {
      final definition = MissionSimulationDefinitions.byId('coc1_m1');
      final controller = _controller(definition);

      await tester.pumpWidget(_host(definition, controller: controller));
      await tester.pumpAndSettle();

      final nextFinder = find.byKey(const ValueKey('mission-next'));
      final before = tester.widget<FilledButton>(nextFinder);
      expect(before.onPressed, isNull);

      for (final object in const ['motherboard', 'cpu', 'ram', 'psu']) {
        final target = find.byKey(ValueKey('inspect-target-$object'));
        await tester.ensureVisible(target);
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      final after = tester.widget<FilledButton>(nextFinder);
      expect(after.onPressed, isNotNull);
      await tester.ensureVisible(nextFinder);
      await tester.tap(nextFinder);
      await tester.pumpAndSettle();
      expect(controller.state.currentPhaseId, definition.phases[1].id);
    });

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

    testWidgets('does not force landscape and restores orientations on exit',
        (tester) async {
      final definition = MissionSimulationDefinitions.byId('coc1_m1');
      final orientation = _FakeOrientationCoordinator();

      await tester.pumpWidget(_host(
        definition,
        controller: _controller(definition),
        orientationCoordinator: orientation,
      ));
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(orientation.restoreRequests, 1);
    });

    testWidgets('reaches review, can return, and submits only on confirmation',
        (tester) async {
      final definition = MissionSimulationDefinitions.byId('coc1_m1');
      var submissions = 0;
      final controller = _controller(definition);

      await tester.pumpWidget(_host(
        definition,
        controller: controller,
        onSubmit: () async => submissions++,
      ));
      await tester.pumpAndSettle();

      await _advanceToReview(tester, definition, controller);

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
      final controller = _controller(definition);

      await tester.pumpWidget(_host(
        definition,
        controller: controller,
        onSubmit: () async => submissions++,
      ));
      await tester.pumpAndSettle();
      await _advanceToReview(tester, definition, controller);

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

    testWidgets(
        'retry synchronizes the same pending evidence and unblocks submission',
        (tester) async {
      final definition = MissionSimulationDefinitions.byId('coc1_m1');
      final pending = MissionEvidenceAction(
        clientActionId: 'pending-action-1',
        missionId: definition.id,
        phaseId: definition.phases[3].id,
        actionType: 'test_completed',
        target: definition.phases[3].id,
        value: const {'test_status': 'completed'},
        occurredAt: DateTime.utc(2026, 8, 22),
      );
      final appendGate = Completer<void>();
      final transport = _MemoryTransport(
        appendGate: appendGate,
        readError: StateError('offline'),
      );
      final localState = MissionRuntimeState.initial(definition.id).copyWith(
        currentPhaseId: definition.phases.last.id,
        completedPhaseIds: definition.phases
            .take(definition.phases.length - 1)
            .map((phase) => phase.id)
            .toSet(),
        pendingEvidence: [pending],
      );
      final store = _MemoryStore()..saved = localState;
      final controller = _controller(
        definition,
        store: store,
        transport: transport,
        initialState: localState,
      );

      await tester.pumpWidget(_host(definition, controller: controller));
      await tester.pumpAndSettle();

      final retry = find.widgetWithText(
        OutlinedButton,
        'Retry pending evidence',
      );
      expect(retry, findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Confirm evidence'),
            )
            .onPressed,
        isNull,
      );

      transport.readError = null;
      await tester.tap(retry);
      await tester.pump();

      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Retrying evidence…'),
            )
            .onPressed,
        isNull,
      );
      expect(controller.state.pendingEvidence.single.clientActionId,
          'pending-action-1');

      appendGate.complete();
      await tester.pumpAndSettle();

      expect(transport.appendedIds, ['pending-action-1']);
      expect(controller.state.pendingEvidence, isEmpty);
      expect(controller.state.acceptedEvidenceIds, {'pending-action-1'});
      expect(find.text('Pending evidence synchronized.'), findsOneWidget);
      expect(find.text('Retry pending evidence'), findsNothing);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Confirm evidence'),
            )
            .onPressed,
        isNotNull,
      );
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

    testWidgets('configured test evidence type is emitted only on completion',
        (tester) async {
      final definition = MissionSimulationDefinitions.byId('coc2_m5');
      final phase = definition.phases.singleWhere(
        (item) => (item.presentation['mechanics'] as List)
            .contains('retest_network_path'),
      );
      final transport = _MemoryTransport();
      final controller = _controller(
        definition,
        transport: transport,
        initialState: MissionRuntimeState.initial(definition.id).copyWith(
          currentPhaseId: phase.id,
        ),
      );

      await tester.pumpWidget(_host(definition, controller: controller));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Run test'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Run test again'));
      await tester.pumpAndSettle();

      expect(
        transport.appendedActions.map((action) => action.actionType),
        [
          'test_started',
          'retest_requested',
          'test_started',
          'retest_requested',
        ],
      );
      expect(
        transport.appendedActions
            .where((action) => action.actionType == 'retest_requested'),
        hasLength(2),
      );
      expect(
        transport.appendedActions.map(
          (action) => action.value['runtime_action_type'],
        ),
        ['test_started', 'test_completed', 'test_started', 'test_completed'],
      );
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

    testWidgets('renders every catalog phase without technical unavailability',
        (tester) async {
      final failures = <String>[];
      for (final definition in MissionSimulationDefinitions.all) {
        for (final phase in definition.phases) {
          await tester.pumpWidget(MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: MissionPhaseInteraction(
                  phase: phase,
                  state: MissionRuntimeState.initial(definition.id).copyWith(
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
          await tester.pump();

          final renderedWidgets = expectedWidgets.values
              .where((type) => find.byType(type).evaluate().isNotEmpty)
              .toList(growable: false);
          final exception = tester.takeException();
          if (find.byType(TechnicalUnavailableState).evaluate().isNotEmpty ||
              renderedWidgets.length != 1 ||
              exception != null) {
            failures.add(
              '${definition.id}/${phase.id}: '
              'widgets=$renderedWidgets exception=$exception',
            );
          }
        }
      }
      if (failures.isNotEmpty) {
        debugPrint(failures.join('\n'));
      }
      expect(failures, isEmpty);
    });

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
  MissionEvidenceTransport? transport,
  MissionRuntimeState? initialState,
}) {
  return MissionRuntimeController(
    userId: 'learner-1',
    initialState: initialState ??
        MissionRuntimeState.initial(definition.id).copyWith(
          currentPhaseId: definition.phases.first.id,
        ),
    store: store ?? _MemoryStore(),
    evidenceGateway: MissionEvidenceGateway(
      transport: transport ?? _MemoryTransport(),
    ),
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
  MissionRuntimeController controller,
) async {
  for (var phaseIndex = 0;
      phaseIndex < definition.phases.length - 1;
      phaseIndex++) {
    switch (phaseIndex) {
      case 0:
        for (final object in const ['motherboard', 'cpu', 'ram', 'psu']) {
          final target = find.byKey(ValueKey('inspect-target-$object'));
          await tester.ensureVisible(target);
          await tester.tap(target);
          await tester.pumpAndSettle();
        }
      case 1:
        final choice = find.byKey(const ValueKey('multi-select-motherboard'));
        await tester.ensureVisible(choice);
        await tester.tap(choice);
        final confirm = find.byKey(const ValueKey('multi-select-confirm'));
        await tester.ensureVisible(confirm);
        await tester.tap(confirm);
        await tester.pumpAndSettle();
      case 2:
        final input = find.byKey(
          const ValueKey('observation-input-coc1_m1_p3'),
        );
        await tester.ensureVisible(input);
        await tester.enterText(input, 'No visible damage was observed.');
        await tester.pump();
        final record = find.text('Record observation');
        await tester.ensureVisible(record);
        await tester.tap(record);
        await tester.pumpAndSettle();
      case 3:
        final run = find.byKey(const ValueKey('test-run-start'));
        await tester.ensureVisible(run);
        await tester.tap(run);
        await tester.pumpAndSettle();
    }
    final next = find.byKey(const ValueKey('mission-next'));
    expect(
      tester.widget<FilledButton>(next).onPressed,
      isNotNull,
      reason: 'phase $phaseIndex did not reach terminal interaction state: '
          '${controller.state.toJson()}',
    );
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
  _MemoryTransport({this.appendGate, this.readError});

  final Completer<void>? appendGate;
  Object? readError;
  final Set<String> accepted = <String>{};
  final List<String> appendedIds = <String>[];
  final List<MissionEvidenceAction> appendedActions = <MissionEvidenceAction>[];

  @override
  Future<List<AcknowledgedMissionEvidenceAction>>
      readAcknowledgedActions() async {
    if (readError case final error?) throw error;
    return [
      for (final (index, id) in accepted.indexed)
        AcknowledgedMissionEvidenceAction(
          action: MissionEvidenceAction(
            clientActionId: id,
            missionId: 'coc1_m1',
            phaseId: 'coc1_m1_p1',
            actionType: 'object_inspected',
            value: const {},
            occurredAt: DateTime.utc(2026),
          ),
          serverRecordId: 'server-$id',
          serverOrder: index + 1,
          recordedAt: DateTime.utc(2026),
        ),
    ];
  }

  @override
  Future<void> append(MissionEvidenceAction action) async {
    appendedIds.add(action.clientActionId);
    appendedActions.add(action);
    await appendGate?.future;
    accepted.add(action.clientActionId);
  }
}

final class _FakeOrientationCoordinator
    implements MissionOrientationCoordinator {
  int restoreRequests = 0;

  @override
  Future<void> restoreSupportedOrientations() async => restoreRequests++;
}
