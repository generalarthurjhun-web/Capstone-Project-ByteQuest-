import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/config/supabase_config.dart';
import '../../models/mission_model.dart';
import '../../services/authoritative_assessment_service.dart';
import '../../services/practice_mission_evidence_service.dart';
import '../../services/progress_resume_service.dart';
import 'runtime/mission_evidence_gateway.dart';
import 'runtime/mission_runtime_controller.dart';
import 'runtime/mission_runtime_models.dart';

/// UI-transparent boundary for practice-only legacy mission evidence.
class LegacyPracticeEvidenceScope extends StatefulWidget {
  const LegacyPracticeEvidenceScope({
    super.key,
    required this.mission,
    required this.child,
  }) : _controller = null;

  @visibleForTesting
  const LegacyPracticeEvidenceScope.forTesting({
    super.key,
    required this.mission,
    required this.child,
    required MissionRuntimeController controller,
  }) : _controller = controller;

  final Mission mission;
  final Widget child;
  final MissionRuntimeController? _controller;

  /// Records through practice transport when a legacy practice scope exists.
  /// Explicit assessment adapters remain unwrapped and retain their existing
  /// authoritative attempt-action transport.
  static Future<void> record(
    BuildContext context, {
    required String phaseId,
    required String actionType,
    String? target,
    Map<String, dynamic> value = const {},
  }) {
    final scope =
        context.findAncestorStateOfType<_LegacyPracticeEvidenceScopeState>();
    if (scope == null) {
      return AuthoritativeAssessmentService.instance.safeRecordAction(
        actionType: actionType,
        target: target,
        value: value,
      );
    }
    return scope._record(
      phaseId: phaseId,
      actionType: actionType,
      target: target,
      value: value,
    );
  }

  @override
  State<LegacyPracticeEvidenceScope> createState() =>
      _LegacyPracticeEvidenceScopeState();
}

class _LegacyPracticeEvidenceScopeState
    extends State<LegacyPracticeEvidenceScope> with WidgetsBindingObserver {
  MissionRuntimeController? _controller;
  late final Future<void> _restoreOperation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    try {
      _controller = widget._controller ?? _createController();
      if (_controller!.state.missionId != widget.mission.id ||
          _controller!.state.mode != MissionRuntimeMode.practice ||
          _controller!.state.assessmentAttemptId != null) {
        throw ArgumentError(
          'Legacy practice evidence controller must match ${widget.mission.id} '
          'in practice mode.',
        );
      }
      _restoreOperation = _restore();
    } catch (error, stackTrace) {
      _logFailure('initialize', error, stackTrace);
      _controller = null;
      _restoreOperation = Future<void>.value();
    }
  }

  MissionRuntimeController _createController() {
    final userId = SupabaseConfig.currentUserId;
    if (userId == null || userId.trim().isEmpty) {
      throw StateError(
        'An authenticated learner is required for legacy practice evidence.',
      );
    }
    return MissionRuntimeController(
      userId: userId,
      initialState: MissionRuntimeState.initial(widget.mission.id),
      store: const SharedPreferencesMissionRuntimeStore(),
      evidenceGateway: MissionEvidenceGateway(
        transport: PracticeMissionEvidenceService(
          missionId: widget.mission.id,
        ),
      ),
    );
  }

  Future<void> _restore() async {
    try {
      await _controller!.restore();
    } catch (error, stackTrace) {
      _logFailure('restore', error, stackTrace);
    }
  }

  Future<void> _record({
    required String phaseId,
    required String actionType,
    required String? target,
    required Map<String, dynamic> value,
  }) async {
    await _restoreOperation;
    final controller = _controller;
    if (controller == null) {
      debugPrint(
        '[ByteQuest legacy practice evidence] missionId=${widget.mission.id} '
        'operation=record skipped=no_practice_controller',
      );
      return;
    }

    try {
      await controller.dispatch(
        phaseId: phaseId,
        actionType: actionType,
        target: target,
        value: value,
        transition: (state) => state.copyWith(currentPhaseId: phaseId),
      );
      await _retryPending();
    } catch (error, stackTrace) {
      _logFailure('record', error, stackTrace);
    }
  }

  Future<void> _retryPending() async {
    await _restoreOperation;
    final controller = _controller;
    if (controller == null) return;
    try {
      await controller.flushPending();
    } catch (error, stackTrace) {
      _logFailure('retry', error, stackTrace);
    }
  }

  Future<void> _persist() async {
    await _restoreOperation;
    final controller = _controller;
    if (controller == null) return;
    try {
      await controller.persist();
    } catch (error, stackTrace) {
      _logFailure('persist', error, stackTrace);
    }
  }

  void _logFailure(
    String operation,
    Object error,
    StackTrace stackTrace,
  ) {
    final controller = _controller;
    debugPrint(
      '[ByteQuest legacy practice evidence] missionId=${widget.mission.id} '
      'operation=$operation pendingActions='
      '${controller?.state.pendingEvidence.length ?? 0} error=$error',
    );
    debugPrintStack(stackTrace: stackTrace);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_retryPending());
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        unawaited(_persist());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_persist());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
