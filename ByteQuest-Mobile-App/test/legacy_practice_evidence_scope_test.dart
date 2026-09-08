import 'dart:async';
import 'dart:io';

import 'package:bytequest/models/mission_model.dart';
import 'package:bytequest/screens/simulation/legacy_practice_evidence_scope.dart';
import 'package:bytequest/screens/simulation/runtime/mission_evidence_gateway.dart';
import 'package:bytequest/screens/simulation/runtime/mission_runtime_controller.dart';
import 'package:bytequest/screens/simulation/runtime/mission_runtime_models.dart';
import 'package:bytequest/services/progress_resume_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all legacy template callback sites use the practice evidence scope',
      () {
    const expectedCallbackCounts = <String, int>{
      'coc1_m2_screen_enhanced.dart': 1,
      'coc1_m3_screen_enhanced.dart': 1,
      'configuration_mission_screen.dart': 1,
      'drag_drop_mission_screen.dart': 3,
      'identification_mission_screen.dart': 1,
      'identification_mission_screen_enhanced.dart': 1,
      'step_procedure_mission_screen.dart': 2,
      'troubleshooting_mission_screen.dart': 1,
    };

    for (final entry in expectedCallbackCounts.entries) {
      final source = File(
        'lib/screens/simulation/templates/${entry.key}',
      ).readAsStringSync();
      expect(
        'LegacyPracticeEvidenceScope.record('.allMatches(source),
        hasLength(entry.value),
        reason: entry.key,
      );
      expect(
        source,
        isNot(contains(
          'AuthoritativeAssessmentService.instance.safeRecordAction(',
        )),
        reason: entry.key,
      );
    }
  });

  testWidgets('records one structured practice action with a stable client ID',
      (tester) async {
    final store = _MemoryRuntimeStore();
    final transport = _MemoryEvidenceTransport();
    final controller = _controller(
      store: store,
      transport: transport,
      clientActionId: 'stable-answer-1',
    );

    await tester.pumpWidget(_host(controller));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Record evidence'));
    await tester.pumpAndSettle();

    final action = transport.actions.single;
    expect(action.clientActionId, 'stable-answer-1');
    expect(action.missionId, 'coc1_m1');
    expect(action.phaseId, 'question_q1');
    expect(action.actionType, 'answer_submitted');
    expect(action.target, 'q1');
    expect(action.value, {
      'selected_answer': 'Motherboard',
      'local_mission_id': 'coc1_m1',
    });
    expect(controller.state.pendingEvidence, isEmpty);
    expect(controller.state.acceptedEvidenceIds, {'stable-answer-1'});
    expect(controller.state.mode, MissionRuntimeMode.practice);
    expect(controller.state.assessmentAttemptId, isNull);
  });

  testWidgets('retries queued evidence when connectivity resumes',
      (tester) async {
    final store = _MemoryRuntimeStore();
    final transport = _MemoryEvidenceTransport(online: false);
    final controller = _controller(
      store: store,
      transport: transport,
      clientActionId: 'stable-offline-1',
    );

    await tester.pumpWidget(_host(controller));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Record evidence'));
    await tester.pumpAndSettle();

    expect(controller.state.pendingEvidence.single.clientActionId,
        'stable-offline-1');
    expect(
        store.saved?.pendingEvidence.single.clientActionId, 'stable-offline-1');
    expect(
      find.text(
          'Practice evidence is saved locally but has not synchronized yet.'),
      findsOneWidget,
    );
    expect(find.text('Retry evidence sync'), findsOneWidget);

    transport.online = true;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(transport.actions.single.clientActionId, 'stable-offline-1');
    expect(controller.state.pendingEvidence, isEmpty);
    expect(controller.state.acceptedEvidenceIds, {'stable-offline-1'});
    expect(find.text('Retry evidence sync'), findsNothing);
  });

  testWidgets('restores a force-closed pending action without duplication',
      (tester) async {
    final store = _MemoryRuntimeStore();
    final transport = _MemoryEvidenceTransport(online: false);
    final firstController = _controller(
      store: store,
      transport: transport,
      clientActionId: 'stable-force-close-1',
    );

    await tester.pumpWidget(_host(firstController));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Record evidence'));
    await tester.pumpAndSettle();
    expect(store.saved?.pendingEvidence.single.clientActionId,
        'stable-force-close-1');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    transport.online = true;

    final restoredController = _controller(
      store: store,
      transport: transport,
      clientActionId: 'unused-after-restore',
    );
    await tester.pumpWidget(_host(restoredController));
    await tester.pumpAndSettle();

    expect(transport.actions.single.clientActionId, 'stable-force-close-1');
    expect(restoredController.state.pendingEvidence, isEmpty);
    expect(
        restoredController.state.acceptedEvidenceIds, {'stable-force-close-1'});

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    final secondRestore = _controller(
      store: store,
      transport: transport,
      clientActionId: 'still-unused-after-restore',
    );
    await tester.pumpWidget(_host(secondRestore));
    await tester.pumpAndSettle();

    expect(transport.appendCalls, 1);
    expect(transport.actions, hasLength(1));
    expect(secondRestore.state.acceptedEvidenceIds, {'stable-force-close-1'});
  });
}

Widget _host(MissionRuntimeController controller) {
  return MaterialApp(
    home: LegacyPracticeEvidenceScope.forTesting(
      mission: _mission,
      controller: controller,
      child: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => unawaited(
              LegacyPracticeEvidenceScope.record(
                context,
                phaseId: 'question_q1',
                actionType: 'answer_submitted',
                target: 'q1',
                value: const {
                  'selected_answer': 'Motherboard',
                  'local_mission_id': 'coc1_m1',
                },
              ),
            ),
            child: const Text('Record evidence'),
          ),
        ),
      ),
    ),
  );
}

final Mission _mission = Mission(
  id: 'coc1_m1',
  cocId: 'coc1',
  missionCode: 'COC1-M1',
  missionNumber: 1,
  title: 'Identify Computer Parts and Tools',
  missionType: MissionType.identification,
  orderIndex: 1,
);

MissionRuntimeController _controller({
  required _MemoryRuntimeStore store,
  required _MemoryEvidenceTransport transport,
  required String clientActionId,
}) {
  return MissionRuntimeController(
    userId: 'learner-1',
    initialState: MissionRuntimeState.initial(_mission.id),
    store: store,
    evidenceGateway: MissionEvidenceGateway(transport: transport),
    clientActionIdFactory: () => clientActionId,
    clock: () => DateTime.utc(2026, 8, 23, 12),
  );
}

final class _MemoryRuntimeStore implements MissionRuntimeStore {
  MissionRuntimeState? saved;

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
    saved = state;
    return true;
  }
}

final class _MemoryEvidenceTransport implements MissionEvidenceTransport {
  _MemoryEvidenceTransport({this.online = true});

  bool online;
  int appendCalls = 0;
  final List<MissionEvidenceAction> actions = [];

  @override
  Future<void> append(MissionEvidenceAction action) async {
    if (!online) throw StateError('offline');
    appendCalls += 1;
    if (actions.every(
      (existing) => existing.clientActionId != action.clientActionId,
    )) {
      actions.add(action);
    }
  }

  @override
  Future<List<AcknowledgedMissionEvidenceAction>>
      readAcknowledgedActions() async {
    if (!online) throw StateError('offline');
    return [
      for (var index = 0; index < actions.length; index++)
        AcknowledgedMissionEvidenceAction(
          action: actions[index],
          serverRecordId: 'server-${index + 1}',
          serverOrder: index + 1,
          recordedAt: actions[index].occurredAt,
        ),
    ];
  }
}
