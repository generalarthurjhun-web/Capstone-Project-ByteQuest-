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
        readAcknowledgedIds: (_, __) async => const <String>{},
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

    test('reads only acknowledged IDs for the authenticated learner', () async {
      String? queriedLearner;
      String? queriedMission;
      final service = PracticeMissionEvidenceService.forTesting(
        missionId: 'coc1_m1',
        currentUserId: () => 'learner-1',
        upsertAction: (_) async {},
        readAcknowledgedIds: (learnerId, missionId) async {
          queriedLearner = learnerId;
          queriedMission = missionId;
          return const {'stable-1', 'stable-2'};
        },
      );

      expect(
        await service.acknowledgedClientActionIds(),
        const {'stable-1', 'stable-2'},
      );
      expect(queriedLearner, 'learner-1');
      expect(queriedMission, 'coc1_m1');
    });

    test('fails closed without an authenticated learner', () async {
      var writes = 0;
      final service = PracticeMissionEvidenceService.forTesting(
        missionId: 'coc1_m1',
        currentUserId: () => null,
        upsertAction: (_) async => writes++,
        readAcknowledgedIds: (_, __) async => const <String>{},
      );

      await expectLater(service.append(_action()), throwsStateError);
      await expectLater(
        service.acknowledgedClientActionIds(),
        throwsStateError,
      );
      expect(writes, 0);
    });

    test('propagates network failure for the runtime pending queue', () async {
      final service = PracticeMissionEvidenceService.forTesting(
        missionId: 'coc1_m1',
        currentUserId: () => 'learner-1',
        upsertAction: (_) async => throw StateError('offline'),
        readAcknowledgedIds: (_, __) async => const <String>{},
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
