import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../services/progress_resume_service.dart';
import 'mission_evidence_gateway.dart';
import 'mission_runtime_action_reducer.dart';
import 'mission_runtime_models.dart';

typedef MissionRuntimeTransition = MissionRuntimeState Function(
  MissionRuntimeState state,
);

typedef ClientActionIdFactory = String Function();
typedef MissionRuntimeClock = DateTime Function();

/// Owns the durable local-to-server evidence handoff for one mission runtime.
final class MissionRuntimeController {
  MissionRuntimeController({
    required String userId,
    required MissionRuntimeState initialState,
    required MissionRuntimeStore store,
    required MissionEvidenceGateway evidenceGateway,
    Iterable<String> submissionPhaseIds = const {'review', 'final'},
    MissionRuntimeActionReducer? restoreReducer,
    ClientActionIdFactory? clientActionIdFactory,
    MissionRuntimeClock? clock,
  })  : _userId = userId,
        _initialState = initialState,
        _state = initialState,
        _store = store,
        _evidenceGateway = evidenceGateway,
        _submissionPhaseIds = Set<String>.unmodifiable(submissionPhaseIds),
        _restoreReducer = restoreReducer,
        _clientActionIdFactory = clientActionIdFactory ?? const Uuid().v4,
        _clock = clock ?? DateTime.now;

  final String _userId;
  final MissionRuntimeState _initialState;
  final MissionRuntimeStore _store;
  final MissionEvidenceGateway _evidenceGateway;
  final Set<String> _submissionPhaseIds;
  final MissionRuntimeActionReducer? _restoreReducer;
  final ClientActionIdFactory _clientActionIdFactory;
  final MissionRuntimeClock _clock;
  final Set<String> _failedEvidenceIds = <String>{};

  MissionRuntimeState _state;
  Future<void> _operationQueue = Future<void>.value();

  MissionRuntimeState get state => _state;

  List<MissionEvidenceAction> get failedPendingEvidence => List.unmodifiable(
        _state.pendingEvidence.where(
          (action) => _failedEvidenceIds.contains(action.clientActionId),
        ),
      );

  bool get canSubmit =>
      _submissionPhaseIds.contains(_state.currentPhaseId) &&
      _state.pendingEvidence.isEmpty &&
      _failedEvidenceIds.isEmpty;

  Future<MissionEvidenceAction> dispatch({
    required String phaseId,
    required String actionType,
    String? target,
    Map<String, dynamic> value = const {},
    required MissionRuntimeTransition transition,
  }) {
    final action = MissionEvidenceAction(
      clientActionId: _clientActionIdFactory(),
      missionId: _state.missionId,
      phaseId: phaseId,
      actionType: actionType,
      target: target,
      value: value,
      occurredAt: _clock(),
    );
    return _enqueue(() => _dispatchNow(action, transition));
  }

  Future<void> restore() {
    return _enqueue(() async {
      _logRestoreDiagnostics(syncState: 'loading_local_snapshot');
      final local = await _store.loadMissionRuntime(
        userId: _userId,
        missionId: _state.missionId,
        mode: _state.mode,
        assessmentAttemptId: _state.assessmentAttemptId,
      );
      _logRestoreDiagnostics(
        syncState: local == null ? 'local_snapshot_absent' : 'local_snapshot_loaded',
        snapshot: local,
      );
      if (local != null) {
        _assertSameSession(local, source: 'snapshot');
        for (final action in local.pendingEvidence) {
          if (action.missionId != _state.missionId) {
            throw FormatException(
              'Pending evidence ${action.clientActionId} does not match '
              '${_state.missionId}.',
            );
          }
        }
      }

      late final List<AcknowledgedMissionEvidenceAction> acknowledged;
      _logRestoreDiagnostics(
        syncState: 'reading_acknowledged_server_actions',
        snapshot: local,
      );
      try {
        final serverActions =
            await _evidenceGateway.readAcknowledgedActions();
        // Assessment transports read the complete active-attempt timeline.
        // Reconcile only this mission; other mission actions must not reach
        // this mission's reducer.
        acknowledged = serverActions
            .where((record) => record.action.missionId == _state.missionId)
            .toList(growable: false);
        _logRestoreDiagnostics(
          syncState: 'server_actions_loaded',
          snapshot: local,
          acknowledgedCount: acknowledged.length,
        );
      } catch (error, stackTrace) {
        _logRestoreDiagnostics(
          syncState: local == null
              ? 'server_actions_failed_without_local_snapshot'
              : 'server_actions_failed_using_local_snapshot',
          snapshot: local,
          error: error,
          stackTrace: stackTrace,
        );
        if (local == null) rethrow;
        _state = local;
        _failedEvidenceIds.clear();
        return;
      }

      final serverIds =
          acknowledged.map((record) => record.action.clientActionId).toSet();
      final baseline = local ?? _initialState;
      final pending = baseline.pendingEvidence
          .where((action) => !serverIds.contains(action.clientActionId))
          .toList(growable: false);
      final reducer = _restoreReducer;
      var rebuilt = reducer == null
          ? local ?? _initialState
          : acknowledged.fold<MissionRuntimeState>(
              _initialState,
              (state, record) => reducer.reduce(state, record.action),
            );
      if (reducer != null) {
        for (final action in pending) {
          rebuilt = reducer.reduce(rebuilt, action);
        }
      }
      rebuilt = rebuilt.copyWith(
        acceptedEvidenceIds: serverIds,
        pendingEvidence: pending,
        reducedMotion: local?.reducedMotion ?? rebuilt.reducedMotion,
        cameraScale: local?.cameraScale ?? rebuilt.cameraScale,
        cameraOffsetX: local?.cameraOffsetX ?? rebuilt.cameraOffsetX,
        cameraOffsetY: local?.cameraOffsetY ?? rebuilt.cameraOffsetY,
      );
      _state = rebuilt;
      _failedEvidenceIds.clear();
      final shouldSave = acknowledged.isNotEmpty ||
          (local != null && reducer != null) ||
          baseline.pendingEvidence.length != pending.length ||
          (local == null && pending.isNotEmpty);
      if (shouldSave && !await _saveState()) {
        throw StateError('Restored mission progress could not be saved.');
      }
      await _flushPendingNow();
      _logRestoreDiagnostics(
        syncState: 'restore_complete',
        snapshot: _state,
        acknowledgedCount: acknowledged.length,
      );
    });
  }

  void _logRestoreDiagnostics({
    required String syncState,
    MissionRuntimeState? snapshot,
    int? acknowledgedCount,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final state = snapshot ?? _state;
    debugPrint(
      '[ByteQuest restore] missionId=${state.missionId} '
      'runtimeStateVersion=${state.persistedSchemaVersion} '
      'snapshotTimestamp=${state.updatedAt.toIso8601String()} '
      'storedPhase=${state.currentPhaseId ?? '<none>'} '
      'evidenceCount=${state.acceptedEvidenceIds.length} '
      'pendingActions=${state.pendingEvidence.length} '
      'supabaseSyncState=$syncState'
      '${acknowledgedCount == null ? '' : ' acknowledgedActions=$acknowledgedCount'}',
    );
    if (error != null) {
      debugPrint('[ByteQuest restore] exception=$error');
      if (stackTrace != null) debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> flushPending() => _enqueue(_flushPendingNow);

  /// Persists the current runtime snapshot without creating or submitting
  /// evidence. Mission hosts use this for app lifecycle checkpoints.
  Future<void> persist() {
    return _enqueue(() async {
      if (!await _saveState()) {
        throw StateError('Mission runtime progress could not be saved.');
      }
    });
  }

  /// Clears the active session's local snapshot and returns to a caller-owned
  /// clean state without changing mission, mode, or assessment attempt.
  Future<void> reset(MissionRuntimeState initialState) {
    return _enqueue(() async {
      _assertSameSession(initialState, source: 'reset state');
      final cleared = await _store.clearMissionRuntime(
        userId: _userId,
        missionId: _state.missionId,
        mode: _state.mode,
        assessmentAttemptId: _state.assessmentAttemptId,
      );
      if (!cleared) {
        throw StateError('Mission runtime progress could not be cleared.');
      }
      _state = initialState;
      _failedEvidenceIds.clear();
    });
  }

  Future<MissionEvidenceAction> _dispatchNow(
    MissionEvidenceAction action,
    MissionRuntimeTransition transition,
  ) async {
    final transitioned = transition(_state);
    if (transitioned.missionId != _state.missionId ||
        transitioned.mode != _state.mode ||
        transitioned.assessmentAttemptId != _state.assessmentAttemptId) {
      throw ArgumentError.value(
        transitioned.missionId,
        'transition',
        'must preserve the active mission session',
      );
    }

    _state = transitioned.copyWith(
      pendingEvidence: [...transitioned.pendingEvidence, action],
    );
    if (!await _saveState()) {
      _failedEvidenceIds.add(action.clientActionId);
      throw StateError('Mission evidence could not be saved for retry.');
    }

    try {
      await _evidenceGateway.record(action);
    } catch (_) {
      _failedEvidenceIds.add(action.clientActionId);
      rethrow;
    }

    await _acceptEvidence({action.clientActionId});
    return action;
  }

  Future<void> _flushPendingNow() async {
    if (_state.pendingEvidence.isEmpty) {
      _failedEvidenceIds.clear();
      return;
    }

    for (final action in _state.pendingEvidence) {
      if (action.missionId != _state.missionId) {
        throw FormatException(
          'Pending evidence ${action.clientActionId} does not match '
          '${_state.missionId}.',
        );
      }
    }

    final pendingIds =
        _state.pendingEvidence.map((action) => action.clientActionId).toSet();
    try {
      final acknowledged =
          await _evidenceGateway.reconcile(_state.pendingEvidence);
      await _acceptEvidence(pendingIds.intersection(acknowledged));
    } catch (_) {
      _failedEvidenceIds.addAll(pendingIds);
      rethrow;
    }
  }

  Future<void> _acceptEvidence(Set<String> acceptedIds) async {
    if (acceptedIds.isEmpty) return;
    _state = _state.copyWith(
      pendingEvidence: _state.pendingEvidence
          .where((action) => !acceptedIds.contains(action.clientActionId))
          .toList(growable: false),
      acceptedEvidenceIds: {
        ..._state.acceptedEvidenceIds,
        ...acceptedIds,
      },
    );
    _failedEvidenceIds.removeAll(acceptedIds);
    if (!await _saveState()) {
      throw StateError('Accepted mission evidence could not be saved locally.');
    }
  }

  Future<bool> _saveState() {
    return _store.saveMissionRuntime(userId: _userId, state: _state);
  }

  void _assertSameSession(
    MissionRuntimeState candidate, {
    required String source,
  }) {
    if (candidate.missionId != _state.missionId ||
        candidate.mode != _state.mode ||
        candidate.assessmentAttemptId != _state.assessmentAttemptId) {
      throw FormatException(
        'Mission runtime $source does not match the active session.',
      );
    }
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final completion = _operationQueue.then((_) => operation());
    _operationQueue = completion.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return completion;
  }
}
