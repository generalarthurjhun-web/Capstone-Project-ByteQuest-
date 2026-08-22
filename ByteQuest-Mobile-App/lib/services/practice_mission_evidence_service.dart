import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../screens/simulation/runtime/mission_evidence_gateway.dart';
import '../screens/simulation/runtime/mission_runtime_models.dart';

typedef PracticeEvidenceUserId = String? Function();
typedef PracticeEvidenceUpsert = Future<void> Function(
  Map<String, dynamic> row,
);
typedef PracticeEvidenceAcknowledgements = Future<Set<String>> Function(
  String learnerId,
  String missionId,
);

/// Authenticated, RLS-scoped transport for practice interaction evidence.
/// Practice evidence is an activity timeline only; it carries no score,
/// competency, release, or evaluation authority.
final class PracticeMissionEvidenceService implements MissionEvidenceTransport {
  PracticeMissionEvidenceService({required this.missionId})
      : _currentUserId = (() => SupabaseConfig.client.auth.currentUser?.id),
        _upsertAction = _upsertWithSupabase,
        _readAcknowledgedIds = _readWithSupabase;

  @visibleForTesting
  PracticeMissionEvidenceService.forTesting({
    required this.missionId,
    required PracticeEvidenceUserId currentUserId,
    required PracticeEvidenceUpsert upsertAction,
    required PracticeEvidenceAcknowledgements readAcknowledgedIds,
  })  : _currentUserId = currentUserId,
        _upsertAction = upsertAction,
        _readAcknowledgedIds = readAcknowledgedIds;

  final String missionId;
  final PracticeEvidenceUserId _currentUserId;
  final PracticeEvidenceUpsert _upsertAction;
  final PracticeEvidenceAcknowledgements _readAcknowledgedIds;

  @override
  Future<void> append(MissionEvidenceAction action) async {
    final learnerId = _authenticatedLearnerId();
    if (action.missionId != missionId) {
      throw ArgumentError.value(
        action.missionId,
        'action.missionId',
        'must match the active practice mission',
      );
    }
    await _upsertAction({
      'learner_id': learnerId,
      'client_action_id': action.clientActionId,
      'mission_id': action.missionId,
      'phase_id': action.phaseId,
      'action_type': action.actionType,
      'target': action.target,
      'value': Map<String, dynamic>.from(action.value),
      'client_occurred_at': action.occurredAt.toUtc().toIso8601String(),
    });
  }

  @override
  Future<Set<String>> acknowledgedClientActionIds() async {
    return await _readAcknowledgedIds(
      _authenticatedLearnerId(),
      missionId,
    );
  }

  String _authenticatedLearnerId() {
    final learnerId = _currentUserId();
    if (learnerId == null || learnerId.trim().isEmpty) {
      throw StateError(
        'An authenticated learner is required to record practice evidence.',
      );
    }
    return learnerId;
  }

  static SupabaseClient get _supabase => SupabaseConfig.client;

  static Future<void> _upsertWithSupabase(Map<String, dynamic> row) async {
    await _supabase.from('practice_mission_actions').upsert(
          row,
          onConflict: 'learner_id,client_action_id',
          ignoreDuplicates: true,
        );
  }

  static Future<Set<String>> _readWithSupabase(
    String learnerId,
    String missionId,
  ) async {
    final response = await _supabase
        .from('practice_mission_actions')
        .select('client_action_id')
        .eq('learner_id', learnerId)
        .eq('mission_id', missionId);
    return (response as List)
        .map((row) => (row as Map)['client_action_id'])
        .whereType<String>()
        .toSet();
  }
}
