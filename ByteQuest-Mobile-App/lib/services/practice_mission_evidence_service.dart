import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../core/config/supabase_config.dart';
import '../screens/simulation/runtime/mission_evidence_gateway.dart';
import '../screens/simulation/runtime/mission_runtime_models.dart';

typedef PracticeEvidenceUserId = String? Function();
typedef PracticeEvidenceUpsert = Future<void> Function(
  Map<String, dynamic> row,
);
typedef PracticeEvidenceActionsReader = Future<List<Map<String, dynamic>>>
    Function(
  String learnerId,
  String missionId,
);

/// Authenticated, RLS-scoped transport for practice interaction evidence.
/// Practice evidence is an activity timeline only; it carries no score,
/// competency, release, or evaluation authority.
final class PracticeMissionEvidenceService implements MissionEvidenceTransport {
  static const progressDiscardedActionType = 'practice_progress_discarded';

  PracticeMissionEvidenceService({required this.missionId})
      : _currentUserId = (() => SupabaseConfig.client.auth.currentUser?.id),
        _upsertAction = _upsertWithSupabase,
        _readActions = _readWithSupabase;

  @visibleForTesting
  PracticeMissionEvidenceService.forTesting({
    required this.missionId,
    required PracticeEvidenceUserId currentUserId,
    required PracticeEvidenceUpsert upsertAction,
    required PracticeEvidenceActionsReader readActions,
  })  : _currentUserId = currentUserId,
        _upsertAction = upsertAction,
        _readActions = readActions;

  final String missionId;
  final PracticeEvidenceUserId _currentUserId;
  final PracticeEvidenceUpsert _upsertAction;
  final PracticeEvidenceActionsReader _readActions;

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
  Future<List<AcknowledgedMissionEvidenceAction>>
      readAcknowledgedActions() async {
    final rows = await _readActions(
      _authenticatedLearnerId(),
      missionId,
    );
    int? latestDiscardServerId;
    for (final row in rows) {
      if (row['action_type'] != progressDiscardedActionType) continue;
      final serverId = _serverId(row);
      if (latestDiscardServerId == null || serverId > latestDiscardServerId) {
        latestDiscardServerId = serverId;
      }
    }
    final activeRows = rows
        .where(
          (row) =>
              row['action_type'] != progressDiscardedActionType &&
              (latestDiscardServerId == null ||
                  _serverId(row) > latestDiscardServerId),
        )
        .toList(growable: false)
      ..sort((left, right) {
        final occurredAt = DateTime.parse(
          left['client_occurred_at'] as String,
        ).compareTo(DateTime.parse(right['client_occurred_at'] as String));
        if (occurredAt != 0) return occurredAt;
        return _serverId(left).compareTo(_serverId(right));
      });
    return List.unmodifiable([
      for (var index = 0; index < activeRows.length; index++)
        _recordFromRow(activeRows[index], index),
    ]);
  }

  /// Starts a clean practice timeline without deleting append-only evidence.
  /// Earlier actions remain available for audit but are not replayed into a
  /// learner's newly started practice state.
  Future<void> markProgressDiscarded({
    required String phaseId,
    String? clientActionId,
    DateTime? occurredAt,
  }) {
    return append(
      MissionEvidenceAction(
        clientActionId: clientActionId ?? const Uuid().v4(),
        missionId: missionId,
        phaseId: phaseId,
        actionType: progressDiscardedActionType,
        value: const {'reason': 'learner_confirmed_discard'},
        occurredAt: occurredAt ?? DateTime.now(),
      ),
    );
  }

  Future<Set<String>> acknowledgedClientActionIds() async =>
      (await readAcknowledgedActions())
          .map((record) => record.action.clientActionId)
          .toSet();

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

  static Future<List<Map<String, dynamic>>> _readWithSupabase(
    String learnerId,
    String missionId,
  ) async {
    final response = await _supabase
        .from('practice_mission_actions')
        .select(
          'id,client_action_id,mission_id,phase_id,action_type,target,value,'
          'client_occurred_at,created_at',
        )
        .eq('learner_id', learnerId)
        .eq('mission_id', missionId)
        .order('id', ascending: true);
    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  static AcknowledgedMissionEvidenceAction _recordFromRow(
    Map<String, dynamic> row,
    int index,
  ) {
    final occurredAt = DateTime.parse(row['client_occurred_at'] as String);
    final recordedAt = row['created_at'] is String
        ? DateTime.parse(row['created_at'] as String)
        : occurredAt;
    return AcknowledgedMissionEvidenceAction(
      action: MissionEvidenceAction(
        clientActionId: row['client_action_id'] as String,
        missionId: row['mission_id'] as String,
        phaseId: row['phase_id'] as String,
        actionType: row['action_type'] as String,
        target: row['target'] as String?,
        value: Map<String, dynamic>.from(row['value'] as Map? ?? const {}),
        occurredAt: occurredAt,
      ),
      serverRecordId: row['id'].toString(),
      serverOrder: index + 1,
      recordedAt: recordedAt,
    );
  }

  static int _serverId(Map<String, dynamic> row) {
    final id = row['id'];
    if (id is num) return id.toInt();
    return int.parse(id.toString());
  }
}
