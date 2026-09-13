import 'package:bytequest/screens/simulation/runtime/mission_runtime_models.dart';
import 'package:bytequest/services/practice_mission_evidence_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PracticeMissionEvidenceService', () {
    test('writes learner-owned structured evidence without evaluation fields',
        () async {
      Map<String, dynamic>? written;
      final service = PracticeMissionEvidenceService.forTesting(
        missionId: 'coc1_m1',
        currentUserId: () => 'learner-1',
        upsertAction: (row) async => written = row,
        readActions: (_, __) async => const [],
      );
      final action = _action();

      await service.append(action);

      expect(written, {
        'learner_id': 'learner-1',
        'client_action_id': 'stable-1',
        'mission_id': 'coc1_m1',
        'phase_id': 'coc1_m1_p1',
        'action_type': 'object_inspected',
        'target': 'motherboard',
        'value': {'input_method': 'tap'},
        'client_occurred_at': '2026-08-22T02:00:00.000Z',
      });
      expect(
        written!.keys,
        isNot(containsAll(const [
          'score',
          'passed',
          'outcome',
          'percentage',
          'released_at',
        ])),
      );
    });

    test('reads full ordered actions for the authenticated learner', () async {
      String? queriedLearner;
      String? queriedMission;
      final service = PracticeMissionEvidenceService.forTesting(
        missionId: 'coc1_m1',
        currentUserId: () => 'learner-1',
        upsertAction: (_) async {},
        readActions: (learnerId, missionId) async {
          queriedLearner = learnerId;
          queriedMission = missionId;
          return [
            {
              'id': 4,
              'client_action_id': 'stable-1',
              'mission_id': 'coc1_m1',
              'phase_id': 'coc1_m1_p1',
              'action_type': 'object_inspected',
              'target': 'motherboard',
              'value': {'input_method': 'tap'},
              'client_occurred_at': '2026-08-22T02:00:00.000Z',
              'created_at': '2026-08-22T02:00:01.000Z',
            },
          ];
        },
      );

      final records = await service.readAcknowledgedActions();
      expect(records.single.serverRecordId, '4');
      expect(records.single.serverOrder, 1);
      expect(records.single.action, _action());
      expect(records.single.recordedAt,
          DateTime.parse('2026-08-22T02:00:01.000Z'));
      expect(queriedLearner, 'learner-1');
      expect(queriedMission, 'coc1_m1');
    });

    test('replays only evidence after the latest append-only discard marker',
        () async {
      final service = PracticeMissionEvidenceService.forTesting(
        missionId: 'coc1_m1',
        currentUserId: () => 'learner-1',
        upsertAction: (_) async {},
        readActions: (_, __) async => [
          _row(
            id: 2,
            clientActionId: 'discard-marker',
            actionType:
                PracticeMissionEvidenceService.progressDiscardedActionType,
          ),
          _row(id: 3, clientActionId: 'new-action'),
          _row(id: 1, clientActionId: 'old-action'),
        ],
      );

      final records = await service.readAcknowledgedActions();

      expect(
        records.map((record) => record.action.clientActionId),
        ['new-action'],
      );
      expect(records.single.serverOrder, 1);
    });

    test('records an explicit discard as non-evaluative append-only evidence',
        () async {
      Map<String, dynamic>? written;
      final service = PracticeMissionEvidenceService.forTesting(
        missionId: 'coc1_m1',
        currentUserId: () => 'learner-1',
        upsertAction: (row) async => written = row,
        readActions: (_, __) async => const [],
      );

      await service.markProgressDiscarded(
        phaseId: 'coc1_m1_p2',
        clientActionId: 'discard-marker',
        occurredAt: DateTime.parse('2026-09-08T03:00:00Z'),
      );

      expect(written!['action_type'],
          PracticeMissionEvidenceService.progressDiscardedActionType);
      expect(written!['phase_id'], 'coc1_m1_p2');
      expect(written!['value'], {'reason': 'learner_confirmed_discard'});
      expect(
        written!.keys,
        isNot(containsAll(const ['score', 'passed', 'outcome', 'released_at'])),
      );
    });

    test('fails closed without an authenticated learner', () async {
      var writes = 0;
      final service = PracticeMissionEvidenceService.forTesting(
        missionId: 'coc1_m1',
        currentUserId: () => null,
        upsertAction: (_) async => writes++,
        readActions: (_, __) async => const [],
      );

      await expectLater(service.append(_action()), throwsStateError);
      await expectLater(
        service.readAcknowledgedActions(),
        throwsStateError,
      );
      expect(writes, 0);
    });

    test('propagates network failure for the runtime pending queue', () async {
      final service = PracticeMissionEvidenceService.forTesting(
        missionId: 'coc1_m1',
        currentUserId: () => 'learner-1',
        upsertAction: (_) async => throw StateError('offline'),
        readActions: (_, __) async => const [],
      );

      await expectLater(service.append(_action()), throwsStateError);
    });
  });
}

MissionEvidenceAction _action() => MissionEvidenceAction(
      clientActionId: 'stable-1',
      missionId: 'coc1_m1',
      phaseId: 'coc1_m1_p1',
      actionType: 'object_inspected',
      target: 'motherboard',
      value: const {'input_method': 'tap'},
      occurredAt: DateTime.parse('2026-08-22T10:00:00+08:00'),
    );

Map<String, dynamic> _row({
  required int id,
  required String clientActionId,
  String actionType = 'object_inspected',
}) =>
    {
      'id': id,
      'client_action_id': clientActionId,
      'mission_id': 'coc1_m1',
      'phase_id': 'coc1_m1_p1',
      'action_type': actionType,
      'target': actionType == 'object_inspected' ? 'motherboard' : null,
      'value': const {'input_method': 'tap'},
      'client_occurred_at': '2026-08-22T02:00:0$id.000Z',
      'created_at': '2026-08-22T02:00:1$id.000Z',
    };
