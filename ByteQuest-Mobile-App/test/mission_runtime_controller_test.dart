import 'dart:convert';

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
}) {
  return MissionRuntimeController(
    userId: 'learner-1',
    initialState: initialState ?? MissionRuntimeState.initial('coc2_m3'),
    store: store,
    evidenceGateway: MissionEvidenceGateway(transport: transport),
    clientActionIdFactory: () => 'stable-generated-id',
    clock: () => DateTime.utc(2026),
  );
}

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
    Set<String> failIds = const {},
    List<String>? events,
  })  : acknowledgedIds = Set<String>.from(acknowledgedIds),
        failIds = Set<String>.from(failIds),
        events = events ?? <String>[];

  final Set<String> acknowledgedIds;
  final Set<String> failIds;
  final List<String> events;
  final List<String> appendedIds = [];
  int acknowledgedReads = 0;

  @override
  Future<Set<String>> acknowledgedClientActionIds() async {
    acknowledgedReads += 1;
    events.add('acknowledged');
    return Set<String>.from(acknowledgedIds);
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
