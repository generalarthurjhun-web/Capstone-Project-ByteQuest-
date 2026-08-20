import 'package:bytequest/screens/simulation/runtime/mission_evidence_gateway.dart';
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

    failingIds.remove('stable-a');
    await service.append(_action('stable-a'));
    await expectLater(service.submitAttempt(), throwsStateError);
    expect(submitCalls, 0);

    failingIds.remove('stable-b');
    await service.append(_action('stable-b'));
    expect(await service.submitAttempt(), 'submitted');
    expect(submitCalls, 1);
  });

  test('authoritative reconciliation clears an acknowledged action failure',
      () async {
    SharedPreferences.setMockInitialValues({});
    final action = _action('stable-acknowledged');
    var appendCalls = 0;
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
      activeActions: () async => [
        {
          'sequence_number': 1,
          'action_type': action.actionType,
          'target': action.target,
          'value': {'client_action_id': action.clientActionId},
          'client_occurred_at': action.occurredAt.toIso8601String(),
        },
      ],
      rpc: (function, params) async {
        if (function == 'append_attempt_action') {
          appendCalls += 1;
          throw StateError('response lost after authoritative write');
        }
        if (function == 'submit_attempt') {
          submitCalls += 1;
          return <String, dynamic>{'status': 'submitted'};
        }
        throw StateError('Unexpected RPC: $function');
      },
    );

    await expectLater(service.append(action), throwsStateError);
    await MissionEvidenceGateway(transport: service).reconcile([action]);

    expect(appendCalls, 1);
    expect(await service.submitAttempt(), 'submitted');
    expect(submitCalls, 1);
  });
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
