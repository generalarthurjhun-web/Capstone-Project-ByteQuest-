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
