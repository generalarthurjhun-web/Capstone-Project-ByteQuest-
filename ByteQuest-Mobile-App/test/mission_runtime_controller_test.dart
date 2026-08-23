import 'dart:convert';

import 'package:bytequest/data/mission_simulation_definitions.dart';
import 'package:bytequest/screens/simulation/runtime/mission_runtime_action_reducer.dart';
import 'package:bytequest/screens/simulation/runtime/mission_evidence_gateway.dart';
import 'package:bytequest/screens/simulation/runtime/mission_runtime_controller.dart';
import 'package:bytequest/screens/simulation/runtime/mission_runtime_models.dart';
import 'package:bytequest/services/progress_resume_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('restore reconciles without appending acknowledged evidence', () async {
    final action = _action('stable-1');
    final saved = MissionRuntimeState.initial('coc2_m3').copyWith(
      currentPhaseId: 'review',
      pendingEvidence: [action],
    );
    final events = <String>[];
    final store = _FakeRuntimeStore(saved: saved, events: events);
    final transport = _FakeEvidenceTransport(
      acknowledgedIds: {'stable-1'},
      events: events,
    );
    final controller = _controller(store: store, transport: transport);

    await controller.restore();

    expect(transport.appendedIds, isEmpty);
    expect(transport.acknowledgedReads, 1);
    expect(events.where((event) => event == 'append'), isEmpty);
    expect(controller.state.acceptedEvidenceIds, {'stable-1'});
    expect(controller.state.pendingEvidence, isEmpty);
    expect(controller.canSubmit, isTrue);
  });

  test('restore rebuilds runtime from ordered server actions without a cache',
      () async {
    final definition = MissionSimulationDefinitions.byId('coc2_m3');
    final selectPhase = definition.phases[0];
    final connectPhase = definition.phases[1];
    final transport = _FakeEvidenceTransport(
      acknowledgedActions: [
        _acknowledged(
          _actionFor(
            id: 'server-connect',
            missionId: definition.id,
            phaseId: connectPhase.id,
            actionType: 'connection_created',
            target: 'switch',
            value: const {
              'source_id': 'router',
              'destination_id': 'switch',
            },
          ),
          order: 3,
        ),
        _acknowledged(
          _actionFor(
            id: 'server-phase',
            missionId: definition.id,
            phaseId: selectPhase.id,
            actionType: 'phase_completed',
            target: connectPhase.id,
          ),
          order: 2,
        ),
        _acknowledged(
          _actionFor(
            id: 'server-select',
            missionId: definition.id,
            phaseId: selectPhase.id,
            actionType: 'selection_confirmed',
            target: selectPhase.id,
            value: const {
              'selected_ids': ['router', 'switch'],
            },
          ),
          order: 1,
        ),
      ],
    );
    final controller = _controller(
      store: _FakeRuntimeStore(),
      transport: transport,
      initialState: MissionRuntimeState.initial(definition.id).copyWith(
        currentPhaseId: selectPhase.id,
      ),
      restoreReducer: MissionRuntimeActionReducer(definition),
    );

    await controller.restore();

    expect(controller.state.currentPhaseId, connectPhase.id);
    expect(controller.state.completedPhaseIds, {selectPhase.id});
    expect(
        controller.state.hotspotStates.keys, containsAll(['router', 'switch']));
    expect(controller.state.connectedNodePairs, {'router>switch'});
    expect(controller.state.acceptedEvidenceIds,
        {'server-select', 'server-phase', 'server-connect'});
    expect(transport.appendedIds, isEmpty);
  });

  test('restore ignores acknowledged actions from other missions', () async {
    final definition = MissionSimulationDefinitions.byId('coc2_m5');
    final unrelated = _actionFor(
      id: 'coc2-m1-action',
      missionId: 'coc2_m1',
      phaseId: 'briefing',
      actionType: 'phase_completed',
      target: 'inspect',
    );
    final current = _actionFor(
      id: 'coc2-m5-action',
      missionId: definition.id,
      phaseId: definition.phases.first.id,
      actionType: 'phase_completed',
      target: definition.phases[1].id,
    );
    final controller = _controller(
      store: _FakeRuntimeStore(),
      transport: _FakeEvidenceTransport(
        acknowledgedActions: [
          _acknowledged(unrelated, order: 1),
          _acknowledged(current, order: 2),
        ],
      ),
      initialState: MissionRuntimeState.initial(definition.id).copyWith(
        currentPhaseId: definition.phases.first.id,
      ),
      restoreReducer: MissionRuntimeActionReducer(definition),
    );

    await controller.restore();

    expect(controller.state.currentPhaseId, definition.phases[1].id);
    expect(controller.state.acceptedEvidenceIds, {current.clientActionId});
  });

  test('restore replaces stale state then de-duplicates pending server action',
      () async {
    final definition = MissionSimulationDefinitions.byId('coc2_m3');
    final selectPhase = definition.phases[0];
    final connectPhase = definition.phases[1];
    final serverSelection = _actionFor(
      id: 'server-select',
      missionId: definition.id,
      phaseId: selectPhase.id,
      actionType: 'selection_confirmed',
      target: selectPhase.id,
      value: const {
        'selected_ids': ['router'],
      },
    );
    final pendingConnection = _actionFor(
      id: 'pending-connect',
      missionId: definition.id,
      phaseId: connectPhase.id,
      actionType: 'connection_created',
      target: 'switch',
      value: const {
        'source_id': 'router',
        'destination_id': 'switch',
      },
    );
    final store = _FakeRuntimeStore(
      saved: MissionRuntimeState.initial(definition.id).copyWith(
        currentPhaseId: definition.phases.last.id,
        hotspotStates: const {'stale-object': HotspotVisualState.completed},
        acceptedEvidenceIds: const {'stale-accepted'},
        pendingEvidence: [serverSelection, pendingConnection],
      ),
    );
    final transport = _FakeEvidenceTransport(
      acknowledgedActions: [_acknowledged(serverSelection, order: 1)],
    );
    final controller = _controller(
      store: store,
      transport: transport,
      initialState: MissionRuntimeState.initial(definition.id).copyWith(
        currentPhaseId: selectPhase.id,
      ),
      restoreReducer: MissionRuntimeActionReducer(definition),
    );

    await controller.restore();

    expect(controller.state.hotspotStates, isNot(contains('stale-object')));
    expect(controller.state.acceptedEvidenceIds,
        {'server-select', 'pending-connect'});
    expect(controller.state.connectedNodePairs, {'router>switch'});
    expect(controller.state.pendingEvidence, isEmpty);
    expect(transport.appendedIds, ['pending-connect']);
  });

  test('offline restore preserves an existing local snapshot without replay',
      () async {
    final saved = MissionRuntimeState.initial('coc2_m3').copyWith(
      currentPhaseId: 'local-phase',
      pendingEvidence: [_action('local-pending')],
    );
    final transport = _FakeEvidenceTransport(readError: StateError('offline'));
    final controller = _controller(
      store: _FakeRuntimeStore(saved: saved),
      transport: transport,
    );

    await controller.restore();

    expect(controller.state, saved);
    expect(transport.appendedIds, isEmpty);
  });

  test('dispatch persists pending before transport and accepted afterward',
      () async {
    final events = <String>[];
    final store = _FakeRuntimeStore(events: events);
    final transport = _FakeEvidenceTransport(events: events);
    final controller = _controller(store: store, transport: transport);

    final action = await controller.dispatch(
      phaseId: 'verify',
      actionType: 'test_run',
      value: const {'result': 'link_detected'},
      transition: (state) => state.copyWith(currentPhaseId: 'review'),
    );

    expect(action.clientActionId, 'stable-generated-id');
    expect(events, ['save:pending', 'append', 'save:accepted']);
    expect(controller.state.currentPhaseId, 'review');
    expect(controller.state.pendingEvidence, isEmpty);
    expect(controller.state.acceptedEvidenceIds, {'stable-generated-id'});
    expect(controller.canSubmit, isTrue);
  });

  test('failed append stays retryable and blocks submission', () async {
    final store = _FakeRuntimeStore();
    final transport = _FakeEvidenceTransport(failIds: {'stable-generated-id'});
    final controller = _controller(store: store, transport: transport);

    await expectLater(
      controller.dispatch(
        phaseId: 'verify',
        actionType: 'test_run',
        transition: (state) => state.copyWith(currentPhaseId: 'review'),
      ),
      throwsA(isA<StateError>()),
    );

    expect(
      controller.failedPendingEvidence.map((action) => action.clientActionId),
      ['stable-generated-id'],
    );
    expect(controller.canSubmit, isFalse);

    transport.failIds.clear();
    await controller.flushPending();

    expect(transport.appendedIds, ['stable-generated-id']);
    expect(controller.failedPendingEvidence, isEmpty);
    expect(controller.state.pendingEvidence, isEmpty);
    expect(controller.canSubmit, isTrue);
  });

  test('incompatible mission snapshot returns no state without throwing',
      () async {
    SharedPreferences.setMockInitialValues({
      'bq_mission_runtime_learner-1_coc2_m3_practice': jsonEncode({
        'schemaVersion': MissionRuntimeState.schemaVersion + 1,
        'missionId': 'coc2_m3',
      }),
    });

    final restored = await ProgressResumeService.loadMissionRuntime(
      userId: 'learner-1',
      missionId: 'coc2_m3',
      mode: MissionRuntimeMode.practice,
    );

    expect(restored, isNull);
  });

  test('snapshot for a different mission returns no state', () async {
    SharedPreferences.setMockInitialValues({
      'bq_mission_runtime_learner-1_coc2_m3_practice': jsonEncode(
        MissionRuntimeState.initial('coc1_m1').toJson(),
      ),
    });

    final restored = await ProgressResumeService.loadMissionRuntime(
      userId: 'learner-1',
      missionId: 'coc2_m3',
      mode: MissionRuntimeMode.practice,
    );

    expect(restored, isNull);
  });

  test('restore rejects pending evidence for a different mission', () async {
    final mismatched = MissionEvidenceAction(
      clientActionId: 'wrong-mission-action',
      missionId: 'coc1_m1',
      phaseId: 'verify',
      actionType: 'test_run',
      value: const {},
      occurredAt: DateTime.utc(2026),
    );
    final saved = MissionRuntimeState.initial('coc2_m3').copyWith(
      pendingEvidence: [mismatched],
    );
    final store = _FakeRuntimeStore(saved: saved);
    final transport = _FakeEvidenceTransport();
    final controller = _controller(store: store, transport: transport);

    await expectLater(controller.restore(), throwsFormatException);

    expect(transport.acknowledgedReads, 0);
    expect(transport.appendedIds, isEmpty);
  });

  test('restore rejects practice evidence in an assessment session', () async {
    final practiceSnapshot = MissionRuntimeState.initial('coc2_m3').copyWith(
      acceptedEvidenceIds: const {'practice-action'},
    );
    final store = _FakeRuntimeStore(saved: practiceSnapshot);
    final transport = _FakeEvidenceTransport();
    final controller = _controller(
      store: store,
      transport: transport,
      initialState: MissionRuntimeState.initial(
        'coc2_m3',
        mode: MissionRuntimeMode.assessment,
        assessmentAttemptId: 'attempt-current',
      ),
    );

    await expectLater(controller.restore(), throwsFormatException);

    expect(controller.state.acceptedEvidenceIds, isEmpty);
    expect(transport.acknowledgedReads, 0);
  });

  test('restore rejects evidence from a prior assessment attempt', () async {
    final priorAttempt = MissionRuntimeState.initial(
      'coc2_m3',
      mode: MissionRuntimeMode.assessment,
      assessmentAttemptId: 'attempt-a',
    ).copyWith(acceptedEvidenceIds: const {'prior-action'});
    final store = _FakeRuntimeStore(saved: priorAttempt);
    final transport = _FakeEvidenceTransport();
    final controller = _controller(
      store: store,
      transport: transport,
      initialState: MissionRuntimeState.initial(
        'coc2_m3',
        mode: MissionRuntimeMode.assessment,
        assessmentAttemptId: 'attempt-b',
      ),
    );

    await expectLater(controller.restore(), throwsFormatException);

    expect(controller.state.acceptedEvidenceIds, isEmpty);
    expect(transport.acknowledgedReads, 0);
  });

  test('persistence keys isolate practice and assessment attempts', () async {
    SharedPreferences.setMockInitialValues({});
    final practice = MissionRuntimeState.initial('coc2_m3').copyWith(
      acceptedEvidenceIds: const {'practice-action'},
    );
    final attemptA = MissionRuntimeState.initial(
      'coc2_m3',
      mode: MissionRuntimeMode.assessment,
      assessmentAttemptId: 'attempt-a',
    ).copyWith(acceptedEvidenceIds: const {'attempt-a-action'});

    expect(
      await ProgressResumeService.saveMissionRuntime(
        userId: 'learner-1',
        state: practice,
      ),
      isTrue,
    );
    expect(
      await ProgressResumeService.saveMissionRuntime(
        userId: 'learner-1',
        state: attemptA,
      ),
      isTrue,
    );

    final restoredPractice = await ProgressResumeService.loadMissionRuntime(
      userId: 'learner-1',
      missionId: 'coc2_m3',
      mode: MissionRuntimeMode.practice,
    );
    final restoredAttemptA = await ProgressResumeService.loadMissionRuntime(
      userId: 'learner-1',
      missionId: 'coc2_m3',
      mode: MissionRuntimeMode.assessment,
      assessmentAttemptId: 'attempt-a',
    );
    final restoredAttemptB = await ProgressResumeService.loadMissionRuntime(
      userId: 'learner-1',
      missionId: 'coc2_m3',
      mode: MissionRuntimeMode.assessment,
      assessmentAttemptId: 'attempt-b',
    );

    expect(restoredPractice?.acceptedEvidenceIds, {'practice-action'});
    expect(restoredAttemptA?.acceptedEvidenceIds, {'attempt-a-action'});
    expect(restoredAttemptB, isNull);
  });

  test('legacy resume APIs retain their existing payload contract', () async {
    SharedPreferences.setMockInitialValues({});

    expect(
      await ProgressResumeService.saveState(
        userId: 'learner-1',
        missionId: 'legacy-mission',
        cocId: 'coc1',
        currentStep: 2,
        totalSteps: 4,
        stateData: const {'selected': 'port-2'},
      ),
      isTrue,
    );

    final restored = await ProgressResumeService.loadState(
      userId: 'learner-1',
      missionId: 'legacy-mission',
    );
    expect(restored?['currentStep'], 2);
    expect(restored?['stateData'], {'selected': 'port-2'});
    expect(
      await ProgressResumeService.clearState(
        userId: 'learner-1',
        missionId: 'legacy-mission',
      ),
      isTrue,
    );
  });
}

MissionRuntimeController _controller({
  required _FakeRuntimeStore store,
  required _FakeEvidenceTransport transport,
  MissionRuntimeState? initialState,
  MissionRuntimeActionReducer? restoreReducer,
}) {
  return MissionRuntimeController(
    userId: 'learner-1',
    initialState: initialState ?? MissionRuntimeState.initial('coc2_m3'),
    store: store,
    evidenceGateway: MissionEvidenceGateway(transport: transport),
    restoreReducer: restoreReducer,
    clientActionIdFactory: () => 'stable-generated-id',
    clock: () => DateTime.utc(2026),
  );
}

MissionEvidenceAction _actionFor({
  required String id,
  required String missionId,
  required String phaseId,
  required String actionType,
  String? target,
  Map<String, dynamic> value = const {},
}) =>
    MissionEvidenceAction(
      clientActionId: id,
      missionId: missionId,
      phaseId: phaseId,
      actionType: actionType,
      target: target,
      value: value,
      occurredAt: DateTime.utc(2026, 1, 1, 0, 0, 1),
    );

AcknowledgedMissionEvidenceAction _acknowledged(
  MissionEvidenceAction action, {
  required int order,
}) =>
    AcknowledgedMissionEvidenceAction(
      action: action,
      serverRecordId: 'server-$order',
      serverOrder: order,
      recordedAt: DateTime.utc(2026, 1, 1, 0, 0, order),
    );

MissionEvidenceAction _action(String id) {
  return MissionEvidenceAction(
    clientActionId: id,
    missionId: 'coc2_m3',
    phaseId: 'verify',
    actionType: 'test_run',
    value: const {'result': 'link_detected'},
    occurredAt: DateTime.utc(2026),
  );
}

final class _FakeRuntimeStore implements MissionRuntimeStore {
  _FakeRuntimeStore({this.saved, List<String>? events})
      : events = events ?? <String>[];

  MissionRuntimeState? saved;
  final List<String> events;

  @override
  Future<bool> clearMissionRuntime({
    required String userId,
    required String missionId,
    required MissionRuntimeMode mode,
    String? assessmentAttemptId,
  }) async {
    saved = null;
    return true;
  }

  @override
  Future<MissionRuntimeState?> loadMissionRuntime({
    required String userId,
    required String missionId,
    required MissionRuntimeMode mode,
    String? assessmentAttemptId,
  }) async =>
      saved;

  @override
  Future<bool> saveMissionRuntime({
    required String userId,
    required MissionRuntimeState state,
  }) async {
    events.add(
        state.pendingEvidence.isNotEmpty ? 'save:pending' : 'save:accepted');
    saved = state;
    return true;
  }
}

final class _FakeEvidenceTransport implements MissionEvidenceTransport {
  _FakeEvidenceTransport({
    Set<String> acknowledgedIds = const {},
    List<AcknowledgedMissionEvidenceAction> acknowledgedActions = const [],
    Set<String> failIds = const {},
    List<String>? events,
    this.readError,
  })  : acknowledgedIds = Set<String>.from(acknowledgedIds),
        acknowledgedActions = List.from(acknowledgedActions),
        failIds = Set<String>.from(failIds),
        events = events ?? <String>[];

  final Set<String> acknowledgedIds;
  final List<AcknowledgedMissionEvidenceAction> acknowledgedActions;
  final Set<String> failIds;
  final List<String> events;
  final Object? readError;
  final List<String> appendedIds = [];
  int acknowledgedReads = 0;

  @override
  Future<List<AcknowledgedMissionEvidenceAction>>
      readAcknowledgedActions() async {
    acknowledgedReads += 1;
    events.add('acknowledged');
    if (readError case final error?) throw error;
    return [
      ...acknowledgedActions,
      for (final id in acknowledgedIds)
        if (!acknowledgedActions.any(
          (record) => record.action.clientActionId == id,
        ))
          _acknowledged(_action(id), order: acknowledgedActions.length + 1),
    ];
  }

  @override
  Future<void> append(MissionEvidenceAction action) async {
    events.add('append');
    if (failIds.contains(action.clientActionId)) {
      throw StateError('transport unavailable');
    }
    appendedIds.add(action.clientActionId);
    acknowledgedIds.add(action.clientActionId);
  }
}
