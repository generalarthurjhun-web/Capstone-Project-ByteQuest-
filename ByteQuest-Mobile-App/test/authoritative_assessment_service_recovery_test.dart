import 'package:bytequest/screens/simulation/runtime/mission_runtime_models.dart';
import 'package:bytequest/services/authoritative_assessment_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('successful retries clear only their stable action failure', () async {
    SharedPreferences.setMockInitialValues({});
    final failingIds = {'stable-a', 'stable-b'};
    var submitCalls = 0;
    final service = AuthoritativeAssessmentService.forTesting(
      activeSession: AttemptSession(
        attemptId: 'attempt-1',
        assignmentId: 'assignment-1',
        assignmentType: 'assessment',
        preferenceScope: 'learner-1',
        startedAt: DateTime.utc(2026),
        submissionKey: 'submission-1',
      ),
      rpc: (function, params) async {
        if (function == 'append_attempt_action') {
          final value = Map<String, dynamic>.from(params['p_value'] as Map);
          final id = value['client_action_id'] as String;
          if (failingIds.contains(id)) {
            throw StateError('write failed for $id');
          }
          return null;
        }
        if (function == 'submit_attempt') {
          submitCalls += 1;
          return <String, dynamic>{'status': 'submitted'};
        }
        throw StateError('Unexpected RPC: $function');
      },
    );

    await expectLater(service.append(_action('stable-a')), throwsStateError);
    await expectLater(service.append(_action('stable-b')), throwsStateError);
    await service.settleActionQueue();
    expect(service.pendingActionCount, 0);
    expect(service.failedActionCount, 2);

    failingIds.remove('stable-a');
    await service.append(_action('stable-a'));
    expect(service.failedActionCount, 1);
    await expectLater(service.submitAttempt(), throwsStateError);
    expect(submitCalls, 0);

    failingIds.remove('stable-b');
    await service.append(_action('stable-b'));
    expect(service.failedActionCount, 0);
    expect(await service.submitAttempt(), 'submitted');
    expect(submitCalls, 1);
  });

  test('lost append response is acknowledged without duplicate evidence',
      () async {
    SharedPreferences.setMockInitialValues({});
    final action = _action('stable-acknowledged');
    final rows = <Map<String, dynamic>>[];
    var appendCalls = 0;
    final attemptedSequences = <int>[];
    final service = AuthoritativeAssessmentService.forTesting(
      activeSession: AttemptSession(
        attemptId: 'attempt-1',
        assignmentId: 'assignment-1',
        assignmentType: 'assessment',
        preferenceScope: 'learner-1',
        startedAt: DateTime.utc(2026),
        submissionKey: 'submission-1',
      ),
      activeActions: () async => List.unmodifiable(rows),
      rpc: (function, params) async {
        if (function == 'append_attempt_action') {
          appendCalls += 1;
          attemptedSequences.add(params['p_sequence_number'] as int);
          if (appendCalls == 1) {
            rows.add({
              'sequence_number': params['p_sequence_number'],
              'id': 'record-1',
              'action_type': params['p_action_type'],
              'target': params['p_target'],
              'value': params['p_value'],
              'client_occurred_at': params['p_client_occurred_at'],
              'recorded_at': params['p_client_occurred_at'],
            });
            throw StateError('response lost after authoritative write');
          }
          return null;
        }
        throw StateError('Unexpected RPC: $function');
      },
    );

    await service.append(action);
    await service.append(_action('stable-next'));

    expect(appendCalls, 2);
    expect(attemptedSequences, [1, 2]);
    expect(rows, hasLength(1));
  });

  test('sequence conflict resynchronizes once to the next server sequence',
      () async {
    final rows = <Map<String, dynamic>>[
      {
        'sequence_number': 1,
        'id': 'existing-record',
        'action_type': 'attempt_started',
        'target': null,
        'value': const {'client_start_key': 'existing'},
        'client_occurred_at': DateTime.utc(2026).toIso8601String(),
        'recorded_at': DateTime.utc(2026).toIso8601String(),
      },
    ];
    final attemptedSequences = <int>[];
    final service = AuthoritativeAssessmentService.forTesting(
      activeSession: _session(),
      activeActions: () async => List.unmodifiable(rows),
      rpc: (function, params) async {
        attemptedSequences.add(params['p_sequence_number'] as int);
        if (attemptedSequences.length == 1) {
          throw StateError('ACTION_SEQUENCE_CONFLICT');
        }
        return null;
      },
    );

    await service.append(_action('stable-resync'));

    expect(attemptedSequences, [1, 2]);
    expect(service.activeSession!.nextSequence, 3);
  });

  test('client action identifier collision fails closed', () async {
    final action = _action('stable-collision');
    final service = AuthoritativeAssessmentService.forTesting(
      activeSession: _session(),
      activeActions: () async => [
        {
          'sequence_number': 1,
          'id': 'different-record',
          'action_type': 'different_action',
          'target': action.target,
          'value': {
            'client_action_id': action.clientActionId,
            'mission_id': action.missionId,
            'phase_id': action.phaseId,
          },
          'client_occurred_at': action.occurredAt.toIso8601String(),
          'recorded_at': action.occurredAt.toIso8601String(),
        },
      ],
      rpc: (function, params) async {
        throw StateError('ACTION_SEQUENCE_CONFLICT');
      },
    );

    await expectLater(
      service.append(action),
      throwsA(isA<StateError>().having(
        (error) => error.message,
        'message',
        contains('different evidence'),
      )),
    );
  });
}

AttemptSession _session() => AttemptSession(
      attemptId: 'attempt-1',
      assignmentId: 'assignment-1',
      assignmentType: 'assessment',
      preferenceScope: 'learner-1',
      startedAt: DateTime.utc(2026),
      submissionKey: 'submission-1',
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
