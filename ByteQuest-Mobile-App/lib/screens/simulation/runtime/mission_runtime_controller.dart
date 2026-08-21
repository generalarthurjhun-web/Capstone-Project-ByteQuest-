import 'package:uuid/uuid.dart';

import '../../../services/progress_resume_service.dart';
import 'mission_evidence_gateway.dart';
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
    ClientActionIdFactory? clientActionIdFactory,
    MissionRuntimeClock? clock,
  })  : _userId = userId,
        _state = initialState,
        _store = store,
        _evidenceGateway = evidenceGateway,
        _submissionPhaseIds = Set<String>.unmodifiable(submissionPhaseIds),
        _clientActionIdFactory = clientActionIdFactory ?? const Uuid().v4,
        _clock = clock ?? DateTime.now;

  final String _userId;
  final MissionRuntimeStore _store;
  final MissionEvidenceGateway _evidenceGateway;
  final Set<String> _submissionPhaseIds;
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
      final restored = await _store.loadMissionRuntime(
        userId: _userId,
        missionId: _state.missionId,
        mode: _state.mode,
        assessmentAttemptId: _state.assessmentAttemptId,
      );
      if (restored == null) return;
      _assertSameSession(restored, source: 'snapshot');
      _state = restored;
      _failedEvidenceIds.clear();
      await _flushPendingNow();
    });
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
