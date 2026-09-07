import 'package:uuid/uuid.dart';

import '../core/config/supabase_config.dart';
import '../models/learner_quiz_model.dart';

class LearnerQuizService {
  LearnerQuizService({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;
  final _client = SupabaseConfig.client;

  Future<List<LearnerQuizSummary>> getAvailableQuizzes() async {
    final response = await _client.rpc('get_available_learner_quizzes');
    if (response is Map && response['error'] != null) {
      throw StateError(response['error'].toString());
    }
    return (response as List? ?? const [])
        .map((item) => LearnerQuizSummary.fromJson(
              Map<String, dynamic>.from(item as Map),
            ))
        .toList(growable: false);
  }

  Future<LearnerQuizAttempt> startOrResume(String assignmentId) async {
    final response = await _client.rpc(
      'start_learner_quiz',
      params: {
        'p_assignment_id': assignmentId,
        'p_client_start_key': _uuid.v4(),
      },
    );
    return LearnerQuizAttempt.fromJson(Map<String, dynamic>.from(response));
  }

  Future<void> saveAnswer({
    required String attemptId,
    required String itemId,
    required String answer,
  }) async {
    await _client.rpc(
      'save_learner_quiz_answer',
      params: {
        'p_attempt_id': attemptId,
        'p_item_id': itemId,
        'p_answer': answer,
      },
    );
  }

  Future<LearnerQuizResult> submit(String attemptId) async {
    await _client.rpc(
      'submit_learner_quiz',
      params: {
        'p_attempt_id': attemptId,
        'p_submission_key': _uuid.v4(),
      },
    );
    return getResult(attemptId);
  }

  Future<LearnerQuizResult> getResult(String attemptId) async {
    final response = await _client.rpc(
      'get_learner_quiz_result',
      params: {'p_attempt_id': attemptId},
    );
    return LearnerQuizResult.fromJson(Map<String, dynamic>.from(response));
  }
}
