import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../core/config/supabase_config.dart';
import '../models/assigned_activity_model.dart';
import '../models/attempt_history_model.dart';
import '../screens/simulation/runtime/mission_evidence_gateway.dart';
import '../screens/simulation/runtime/mission_runtime_models.dart';

class AttemptSession {
  final String attemptId;
  final String assignmentId;
  final String assignmentType;
  final String preferenceScope;
  final DateTime startedAt;
  final String submissionKey;
  int nextSequence;

  AttemptSession({
    required this.attemptId,
    required this.assignmentId,
    required this.assignmentType,
    required this.preferenceScope,
    required this.startedAt,
    required this.submissionKey,
    this.nextSequence = 1,
  });

  bool get isAssessment => assignmentType == 'assessment';
}

/// The only mobile write path for assessment attempts. It never sends a score,
/// competency outcome, pass flag, XP, points, or reward.
class AuthoritativeAssessmentService implements MissionEvidenceTransport {
  AuthoritativeAssessmentService._();
  static final AuthoritativeAssessmentService instance =
      AuthoritativeAssessmentService._();

  SupabaseClient get _supabase => SupabaseConfig.client;
  final Uuid _uuid = const Uuid();
  AttemptSession? _activeSession;
  Future<void> _actionQueue = Future<void>.value();
  Object? _actionWriteError;

  AttemptSession? get activeSession => _activeSession;
  bool get isAssessmentMode => _activeSession?.isAssessment ?? false;

  @override
  Future<void> append(MissionEvidenceAction action) async {
    if (_activeSession == null) {
      throw StateError('No authoritative attempt is active.');
    }
    await recordAction(
      actionType: action.actionType,
      target: action.target,
      value: {
        ...action.value,
        'client_action_id': action.clientActionId,
      },
      occurredAt: action.occurredAt,
    );
  }

  @override
  Future<Set<String>> acknowledgedClientActionIds() async {
    final actions = await getActiveAttemptActions();
    return actions
        .map((action) => action['value'])
        .whereType<Map>()
        .map((value) => value['client_action_id'])
        .whereType<String>()
        .toSet();
  }

  Future<List<AssignedActivity>> getAssignedActivities() async {
    final responses = await Future.wait<dynamic>([
      _supabase
          .from('assignments')
          .select(
              'id,class_id,activity_version_id,rubric_version_id,assignment_type,title,instructions,available_at,due_at,classes(title),activity_versions(title,delivery_mode,learner_payload,missions(id,mission_code))')
          .eq('status', 'active')
          .order('created_at', ascending: false),
      _supabase.rpc('get_bypassed_activities'),
    ]);
    final assignments = (responses[0] as List)
        .map((row) =>
            AssignedActivity.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
    final assignedVersionIds =
        assignments.map((item) => item.activityVersionId).toSet();
    final bypassed = (responses[1] as List)
        .map((row) => AssignedActivity.fromBypassJson(
            Map<String, dynamic>.from(row as Map)))
        .where((item) => !assignedVersionIds.contains(item.activityVersionId));
    return [...assignments, ...bypassed];
  }

  Future<AttemptSession> startAttempt(AssignedActivity assignment) async {
    if (assignment.isBypassAccess) {
      throw StateError('Bypassed content is practice-only and has no attempt.');
    }

    final preferences = await SharedPreferences.getInstance();
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('An authenticated learner is required.');
    }
    final startPreference = _startPreference(userId, assignment.id);
    final submissionPreference = _submissionPreference(userId, assignment.id);
    final startKey = preferences.getString(startPreference) ?? _uuid.v4();
    final submissionKey =
        preferences.getString(submissionPreference) ?? _uuid.v4();
    await preferences.setString(startPreference, startKey);
    await preferences.setString(submissionPreference, submissionKey);

    final response = await _supabase.rpc('start_attempt', params: {
      'p_assignment_id': assignment.id,
      'p_client_start_key': startKey,
    }) as Map<String, dynamic>;
    final status = response['status'] as String? ?? 'in_progress';
    if (status != 'in_progress') {
      await _clearAttemptPreferences(preferences, userId, assignment.id);
      throw StateError(
          'Your previous submission was already recorded with status $status.');
    }

    final actionRows = await _supabase
        .from('attempt_actions')
        .select('sequence_number')
        .eq('attempt_id', response['id'] as String)
        .order('sequence_number', ascending: false)
        .limit(1);
    final lastSequence = (actionRows as List).isEmpty
        ? 0
        : ((actionRows.first as Map)['sequence_number'] as int? ?? 0);
    final session = AttemptSession(
      attemptId: response['id'] as String,
      assignmentId: assignment.id,
      assignmentType: assignment.assignmentType,
      preferenceScope: userId,
      startedAt: DateTime.parse(response['started_at'] as String),
      submissionKey: submissionKey,
      nextSequence: lastSequence + 1,
    );
    _activeSession = session;
    _actionWriteError = null;
    if (lastSequence == 0) {
      await recordAction(
        actionType: 'attempt_started',
        target: assignment.activityVersionId,
        value: {
          'assignment_type': assignment.assignmentType,
          'client_start_key': startKey,
        },
      );
    }
    return session;
  }

  Future<void> recordAction({
    required String actionType,
    String? target,
    Map<String, dynamic> value = const {},
    DateTime? occurredAt,
  }) async {
    final completion = _actionQueue.then((_) => _recordActionNow(
          actionType: actionType,
          target: target,
          value: value,
          occurredAt: occurredAt,
        ));
    _actionQueue = completion.catchError((error) {
      _actionWriteError ??= error;
    });
    return completion;
  }

  Future<void> _recordActionNow({
    required String actionType,
    String? target,
    required Map<String, dynamic> value,
    DateTime? occurredAt,
  }) async {
    final session = _activeSession;
    if (session == null) return;
    final sequence = session.nextSequence;
    await _supabase.rpc('append_attempt_action', params: {
      'p_attempt_id': session.attemptId,
      'p_sequence_number': sequence,
      'p_action_type': actionType,
      'p_target': target,
      'p_value': value,
      'p_client_occurred_at':
          (occurredAt ?? DateTime.now()).toUtc().toIso8601String(),
    });
    session.nextSequence = sequence + 1;
  }

  Future<String> submitAttempt(
      {Map<String, dynamic> finalEvidence = const {}}) async {
    final session = _activeSession;
    if (session == null) {
      throw StateError('No authoritative attempt is active.');
    }
    if (finalEvidence.isNotEmpty) {
      await recordAction(
          actionType: 'simulation_completed', value: finalEvidence);
    }
    await _actionQueue;
    if (_actionWriteError != null) {
      throw StateError(
          'One or more ordered evidence events could not be recorded.');
    }
    final elapsed =
        DateTime.now().difference(session.startedAt).inSeconds.clamp(0, 86400);
    final response = await _supabase.rpc('submit_attempt', params: {
      'p_attempt_id': session.attemptId,
      'p_submission_key': session.submissionKey,
      'p_elapsed_time_seconds': elapsed,
    }) as Map<String, dynamic>;
    final preferences = await SharedPreferences.getInstance();
    await _clearAttemptPreferences(
      preferences,
      session.preferenceScope,
      session.assignmentId,
    );
    _activeSession = null;
    return response['status'] as String? ?? 'submitted';
  }

  void abandonLocalSession() {
    _activeSession = null;
  }

  String _startPreference(String userId, String assignmentId) =>
      'authoritative_attempt_start_key_${userId}_$assignmentId';

  String _submissionPreference(String userId, String assignmentId) =>
      'authoritative_attempt_submission_key_${userId}_$assignmentId';

  Future<void> _clearAttemptPreferences(
    SharedPreferences preferences,
    String userId,
    String assignmentId,
  ) async {
    await preferences.remove(_startPreference(userId, assignmentId));
    await preferences.remove(_submissionPreference(userId, assignmentId));
  }

  Future<List<ReleasedAssessmentResult>> getReleasedResults() async {
    final releases = await _supabase
        .from('result_releases')
        .select(
            'attempt_id,released_at,score_revisions(percentage,outcome,remarks),attempts(activity_versions(missions(title,mission_code,coc_modules(coc_code))),assignments(title,classes(title)))')
        .eq('is_current', true)
        .order('released_at', ascending: false);
    final releaseRows = (releases as List)
        .map((raw) => Map<String, dynamic>.from(raw as Map))
        .toList(growable: false);
    final attemptIds = releaseRows
        .map((row) => row['attempt_id'] as String)
        .toList(growable: false);
    final criterionByAttempt = <String, List<ReleasedCriterionFeedback>>{};
    if (attemptIds.isNotEmpty) {
      final criterionResponse = await _supabase
          .from('criterion_results')
          .select(
              'attempt_id,observation,rubric_criteria(criterion_code,title,order_index)')
          .inFilter('attempt_id', attemptIds);
      final sortable = (criterionResponse as List)
          .map((raw) => Map<String, dynamic>.from(raw as Map))
          .toList(growable: false)
        ..sort((left, right) {
          final leftDefinition = Map<String, dynamic>.from(
              left['rubric_criteria'] as Map? ?? const {});
          final rightDefinition = Map<String, dynamic>.from(
              right['rubric_criteria'] as Map? ?? const {});
          return (leftDefinition['order_index'] as int? ?? 0)
              .compareTo(rightDefinition['order_index'] as int? ?? 0);
        });
      for (final row in sortable) {
        final attemptId = row['attempt_id'] as String;
        final definition = Map<String, dynamic>.from(
            row['rubric_criteria'] as Map? ?? const {});
        criterionByAttempt.putIfAbsent(attemptId, () => []).add(
              ReleasedCriterionFeedback(
                code: definition['criterion_code'] as String? ?? 'Criterion',
                title: definition['title'] as String? ?? 'Assessment criterion',
                observation: row['observation'] as String? ?? 'not_observed',
              ),
            );
      }
    }
    return releaseRows.map((row) {
      final revision =
          Map<String, dynamic>.from(row['score_revisions'] as Map? ?? const {});
      final attempt =
          Map<String, dynamic>.from(row['attempts'] as Map? ?? const {});
      final assignment =
          Map<String, dynamic>.from(attempt['assignments'] as Map? ?? const {});
      final activity = Map<String, dynamic>.from(
          attempt['activity_versions'] as Map? ?? const {});
      final mission =
          Map<String, dynamic>.from(activity['missions'] as Map? ?? const {});
      final coc =
          Map<String, dynamic>.from(mission['coc_modules'] as Map? ?? const {});
      final classroom =
          Map<String, dynamic>.from(assignment['classes'] as Map? ?? const {});
      return ReleasedAssessmentResult(
        attemptId: row['attempt_id'] as String,
        assignmentTitle: assignment['title'] as String? ?? 'Assigned activity',
        classTitle: classroom['title'] as String? ?? 'Class',
        cocCode: coc['coc_code'] as String?,
        missionTitle: mission['title'] as String?,
        percentage: revision['percentage'] as num?,
        outcome: revision['outcome'] as String? ?? 'pending',
        remarks: revision['remarks'] as String?,
        releasedAt: DateTime.parse(row['released_at'] as String),
        criteria: List.unmodifiable(
          criterionByAttempt[row['attempt_id'] as String] ?? const [],
        ),
      );
    }).toList(growable: false);
  }

  Future<Map<String, int>> getAttemptStatusCounts() async {
    final response = await _supabase.from('attempts').select('status');
    final counts = <String, int>{};
    for (final raw in response as List) {
      final row = Map<String, dynamic>.from(raw as Map);
      final status = row['status'] as String? ?? 'unknown';
      counts[status] = (counts[status] ?? 0) + 1;
    }
    return counts;
  }

  /// Returns the authenticated learner's own attempt timeline. RLS scopes
  /// this query to the current learner; no cross-learner history is exposed.
  Future<List<AttemptHistoryEntry>> getAttemptHistory() async {
    final response = await _supabase
        .from('attempts')
        .select(
          'id,status,started_at,submitted_at,released_at,assignments(title,classes(title))',
        )
        .order('started_at', ascending: false);
    return (response as List)
        .map((row) => AttemptHistoryEntry.fromJson(
              Map<String, dynamic>.from(row as Map),
            ))
        .toList(growable: false);
  }

  Future<void> safeRecordAction({
    required String actionType,
    String? target,
    Map<String, dynamic> value = const {},
  }) async {
    try {
      await recordAction(actionType: actionType, target: target, value: value);
    } catch (error) {
      debugPrint('Authoritative evidence write failed: $error');
      _actionWriteError = error;
    }
  }

  /// Reads only the current learner's active attempt evidence. RLS and the
  /// attempt ownership policy remain authoritative; this is used to rebuild
  /// a paused simulation after process termination and to summarize evidence
  /// before submission.
  Future<List<Map<String, dynamic>>> getActiveAttemptActions() async {
    final session = _activeSession;
    if (session == null) return const [];
    final response = await _supabase
        .from('attempt_actions')
        .select('sequence_number,action_type,target,value,client_occurred_at')
        .eq('attempt_id', session.attemptId)
        .order('sequence_number');
    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }
}
