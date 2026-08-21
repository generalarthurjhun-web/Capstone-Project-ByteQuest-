import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../models/mission_model.dart';
import '../../services/auth_service.dart';
import '../../services/authoritative_assessment_service.dart';
import '../../services/progress_resume_service.dart';
import 'components/simulation_scene.dart';
import 'interactions/mission_interactions.dart';
import 'runtime/mission_evidence_gateway.dart';
import 'runtime/mission_runtime_controller.dart';
import 'runtime/mission_runtime_models.dart';

typedef MissionSubmitCallback = Future<void> Function();

abstract interface class MissionOrientationCoordinator {
  Future<void> requestLandscape();

  Future<void> restoreSupportedOrientations();
}

final class SystemMissionOrientationCoordinator
    implements MissionOrientationCoordinator {
  const SystemMissionOrientationCoordinator();

  @override
  Future<void> requestLandscape() => SystemChrome.setPreferredOrientations(
        const [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
      );

  @override
  Future<void> restoreSupportedOrientations() =>
      SystemChrome.setPreferredOrientations(
        const [
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
      );
}

/// Lifecycle-owning shell for catalog-backed practice and assessment missions.
class MissionSimulationScreen extends StatefulWidget {
  const MissionSimulationScreen({
    super.key,
    required this.mission,
    required this.definition,
    this.learnerPayload = const {},
    this.controller,
    this.orientationCoordinator = const SystemMissionOrientationCoordinator(),
    this.onSubmit,
  });

  final Mission mission;
  final MissionSimulationDefinition definition;
  final Map<String, dynamic> learnerPayload;
  final MissionRuntimeController? controller;
  final MissionOrientationCoordinator orientationCoordinator;
  final MissionSubmitCallback? onSubmit;

  @override
  State<MissionSimulationScreen> createState() =>
      _MissionSimulationScreenState();
}

class _MissionSimulationScreenState extends State<MissionSimulationScreen>
    with WidgetsBindingObserver {
  late final MissionRuntimeController _controller =
      widget.controller ?? _createController();
  late final MissionRuntimeState _initialState;
  MissionRuntimeTransition? _pendingInteractionTransition;
  var _restoring = true;
  var _writing = false;
  var _submitting = false;
  var _submitted = false;
  String? _restoreFailure;
  String? _technicalFeedback;

  MissionRuntimeState get _state => _controller.state;

  MissionRuntimeController _createController() {
    final assessment = AuthoritativeAssessmentService.instance;
    final firstPhaseId = widget.definition.phases.first.id;
    final userId = AuthService().currentUserId ?? 'local-practice';
    final assessmentSession = assessment.activeSession?.isAssessment == true
        ? assessment.activeSession
        : null;
    final isAssessment = assessmentSession != null;
    return MissionRuntimeController(
      userId: userId,
      initialState: MissionRuntimeState.initial(
        widget.definition.id,
        mode: isAssessment
            ? MissionRuntimeMode.assessment
            : MissionRuntimeMode.practice,
        assessmentAttemptId: assessmentSession?.attemptId,
      ).copyWith(
        currentPhaseId: firstPhaseId,
      ),
      store: const SharedPreferencesMissionRuntimeStore(),
      evidenceGateway: MissionEvidenceGateway(
        transport: isAssessment ? assessment : _PracticeEvidenceTransport(),
      ),
      submissionPhaseIds: {widget.definition.phases.last.id},
    );
  }

  @override
  void initState() {
    super.initState();
    _initialState = _controller.state;
    WidgetsBinding.instance.addObserver(this);
    unawaited(widget.orientationCoordinator.requestLandscape());
    unawaited(_restore());
  }

  Future<void> _restore() async {
    try {
      await _controller.restore();
      if (!_hasKnownPhase(_state.currentPhaseId)) {
        _restoreFailure =
            'Saved progress references a mission phase that is no longer '
            'available.';
      }
    } catch (_) {
      _restoreFailure =
          'Saved progress could not be restored for this mission session.';
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  Future<void> _retryRestore() async {
    setState(() {
      _restoring = true;
      _restoreFailure = null;
    });
    await _restore();
  }

  Future<void> _resetSavedProgress() async {
    setState(() => _restoring = true);
    try {
      await _controller.reset(_initialState);
      _restoreFailure = null;
      _technicalFeedback = null;
      _submitted = false;
    } catch (_) {
      _restoreFailure =
          'Saved progress could not be reset. Retry or return to the mission '
          'list.';
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_persistForLifecycle());
    }
  }

  Future<void> _persistForLifecycle() async {
    try {
      await _controller.persist();
    } catch (_) {
      if (mounted) {
        setState(() {
          _technicalFeedback =
              'Progress could not be saved. Keep the mission open and retry.';
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(widget.orientationCoordinator.restoreSupportedOrientations());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_restoring) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_restoreFailure case final failure?) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: TechnicalUnavailableState(
                phaseTitle: widget.definition.title,
                message: failure,
                onRetry: () => unawaited(_retryRestore()),
                onReset: () => unawaited(_resetSavedProgress()),
              ),
            ),
          ),
        ),
      );
    }

    final phaseIndex = _phaseIndex;
    final phase = widget.definition.phases[phaseIndex];
    final scene = SimulationScene(
      scene: widget.definition.scene,
      hotspotStates: _state.hotspotStates,
      inspectedObjectIds: _state.hotspotStates.entries
          .where((entry) => entry.value != HotspotVisualState.neutral)
          .map((entry) => entry.key)
          .toSet(),
      connectedNodePairs: _state.connectedNodePairs,
      enabled:
          !_writing && phase.primaryInteraction != InteractionFamily.review,
      onObjectSelected: (objectId) => unawaited(
        _recordAction(
          phase,
          'object_inspected',
          objectId,
          const {'input_method': 'scene'},
        ),
      ),
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _MissionHeader(
              title: widget.definition.title,
              environment: widget.definition.environmentLabel,
              phaseIndex: phaseIndex,
              phaseCount: widget.definition.phases.length,
              onBack: () => unawaited(_leave()),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final controls = _buildControls(phase, phaseIndex);
                  if (constraints.maxWidth >= 720) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 3, child: scene),
                        const VerticalDivider(width: 1),
                        Expanded(flex: 2, child: controls),
                      ],
                    );
                  }
                  final sceneHeight = (constraints.maxHeight * .36)
                      .clamp(190.0, 300.0)
                      .toDouble();
                  return Column(
                    children: [
                      SizedBox(height: sceneHeight, child: scene),
                      const Divider(height: 1),
                      Expanded(child: controls),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(MissionPhaseDefinition phase, int phaseIndex) {
    return SingleChildScrollView(
      key: const ValueKey('mission-controls-scroll'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(phase.title, style: AppTheme.titleMedium),
          const SizedBox(height: 6),
          Text(phase.instruction, style: AppTheme.bodyMedium),
          const SizedBox(height: 16),
          MissionPhaseInteraction(
            key: ValueKey('mission-interaction-${phase.id}'),
            phase: phase,
            state: _state,
            enabled: !_writing && !_submitting,
            onAction: (actionType, target, value) =>
                _recordAction(phase, actionType, target, value),
            onRuntimeTransition: (transition) {
              _pendingInteractionTransition = transition;
            },
            completedPhaseTitles: widget.definition.phases
                .where((item) => _state.completedPhaseIds.contains(item.id))
                .map((item) => item.title)
                .toList(growable: false),
            authoritativeEvidenceCount: _state.acceptedEvidenceIds.length,
            pendingEvidenceCount: _state.pendingEvidence.length,
            failedEvidenceCount: _controller.failedPendingEvidence.length,
            canSubmit: _controller.canSubmit && !_submitting && !_submitted,
            returnLabel:
                widget.definition.reviewMetadata['returnLabel'] as String? ??
                    'Return to mission',
            confirmLabel:
                widget.definition.reviewMetadata['confirmLabel'] as String? ??
                    'Confirm evidence',
            onReturnFromReview: () => unawaited(_returnFromReview()),
            onConfirmReview: () => unawaited(_confirmSubmission()),
          ),
          if (_technicalFeedback case final feedback?) ...[
            const SizedBox(height: 14),
            Semantics(
              liveRegion: true,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundPaleBlue,
                  borderRadius: AppTheme.radiusSm,
                ),
                child: Text(feedback, style: AppTheme.bodySmall),
              ),
            ),
          ],
          if (phase.primaryInteraction != InteractionFamily.review) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              key: const ValueKey('mission-next'),
              onPressed:
                  _writing ? null : () => unawaited(_advance(phaseIndex)),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(
                phaseIndex == widget.definition.phases.length - 2
                    ? 'Review evidence'
                    : 'Continue',
              ),
            ),
          ],
        ],
      ),
    );
  }

  int get _phaseIndex {
    final phaseId = _state.currentPhaseId;
    final index = widget.definition.phases.indexWhere(
      (phase) => phase.id == phaseId,
    );
    if (index < 0) {
      throw StateError('The active mission phase is not in the catalog.');
    }
    return index;
  }

  bool _hasKnownPhase(String? phaseId) => widget.definition.phases.any(
        (phase) => phase.id == phaseId,
      );

  Future<void> _recordAction(
    MissionPhaseDefinition phase,
    String emittedActionType,
    String? target,
    Map<String, dynamic> value,
  ) async {
    if (_writing) return;
    final queuedTransition = _pendingInteractionTransition;
    _pendingInteractionTransition = null;
    setState(() => _writing = true);
    try {
      await _controller.dispatch(
        phaseId: phase.id,
        actionType: _adaptActionType(phase, emittedActionType),
        target: target,
        value: value,
        transition: queuedTransition ??
            (state) => _transitionForAction(
                  state,
                  emittedActionType,
                  target,
                  value,
                ),
      );
      if (phase.feedbackIds.isNotEmpty) {
        _technicalFeedback =
            widget.definition.feedbackCatalog[phase.feedbackIds.first];
      } else {
        _technicalFeedback = 'Technical evidence recorded.';
      }
    } catch (_) {
      _technicalFeedback =
          'Technical evidence could not be synchronized. Retry this action.';
    } finally {
      if (mounted) setState(() => _writing = false);
    }
  }

  String _adaptActionType(
    MissionPhaseDefinition phase,
    String emittedActionType,
  ) {
    final protectedType = phase.presentation['action_type'];
    if (protectedType is String && protectedType.isNotEmpty) {
      return protectedType;
    }
    final configuredType = phase.presentation['actionType'];
    if (configuredType is String && configuredType.isNotEmpty) {
      return configuredType;
    }
    return emittedActionType;
  }

  MissionRuntimeState _transitionForAction(
    MissionRuntimeState state,
    String actionType,
    String? target,
    Map<String, dynamic> value,
  ) {
    final testStatusName = value['test_status'];
    if (target != null && testStatusName is String) {
      for (final status in MissionTestStatus.values) {
        if (status.name == testStatusName) {
          return state.withTestStatus(target, status);
        }
      }
    }
    switch (actionType) {
      case 'object_inspected':
        if (target == null) return state;
        return state.copyWith(hotspotStates: {
          ...state.hotspotStates,
          target: HotspotVisualState.selected,
        });
      case 'selection_confirmed':
        final selected =
            (value['selected_ids'] as List? ?? const []).whereType<String>();
        return state.copyWith(hotspotStates: {
          ...state.hotspotStates,
          for (final id in selected) id: HotspotVisualState.selected,
        });
      case 'tool_attempted':
        final toolId = value['tool_id'] as String?;
        return state.copyWith(
          selectedToolId: toolId,
          toolApplications: target == null || toolId == null
              ? state.toolApplications
              : {...state.toolApplications, target: toolId},
        );
      case 'connection_created':
        final source = value['source_id'] as String?;
        final destination = value['destination_id'] as String?;
        if (source == null || destination == null) return state;
        return state.copyWith(connectedNodePairs: {
          ...state.connectedNodePairs,
          '$source>$destination',
        });
      case 'configuration_applied':
        final values = value['values'];
        return values is Map
            ? state.copyWith(
                configurationValues: {
                  ...state.configurationValues,
                  ...Map<String, dynamic>.from(values),
                },
              )
            : state;
      case 'sequence_reordered':
        return state.copyWith(
          sequenceOrder: (value['order'] as List? ?? const [])
              .whereType<String>()
              .toList(growable: false),
        );
      case 'match_created':
        final source = value['source_id'] as String?;
        final destination = value['destination_id'] as String?;
        if (source == null || destination == null) return state;
        return state.copyWith(matches: {...state.matches, source: destination});
      case 'placement_attempted':
        final item = value['item_id'] as String?;
        final destination = value['destination_id'] as String?;
        if (item == null ||
            destination == null ||
            value['compatible'] != true) {
          return state;
        }
        return state.copyWith(placements: {
          ...state.placements,
          item: destination,
        });
      case 'diagnostic_action':
        final factId = value['reveals_fact_id'] as String?;
        return factId == null
            ? state
            : state.copyWith(
                revealedFactIds: {...state.revealedFactIds, factId},
              );
      case 'observation_recorded':
        final observation = value['observation'];
        return observation is String && target != null
            ? state.copyWith(observations: {
                ...state.observations,
                target: observation,
              })
            : state;
      case 'result_interpreted':
        final interpretation = value['interpretation'];
        return interpretation is String && target != null
            ? state.copyWith(interpretations: {
                ...state.interpretations,
                target: interpretation,
              })
            : state;
      default:
        return state;
    }
  }

  Future<void> _advance(int phaseIndex) async {
    if (_writing || phaseIndex >= widget.definition.phases.length - 1) return;
    final current = widget.definition.phases[phaseIndex];
    final next = widget.definition.phases[phaseIndex + 1];
    setState(() => _writing = true);
    try {
      await _controller.dispatch(
        phaseId: current.id,
        actionType: 'phase_completed',
        target: next.id,
        value: const {'input_method': 'button'},
        transition: (state) => state.copyWith(
          currentPhaseId: next.id,
          completedPhaseIds: {...state.completedPhaseIds, current.id},
        ),
      );
      _technicalFeedback = null;
    } catch (_) {
      _technicalFeedback =
          'The phase could not be saved. Retry before continuing.';
    } finally {
      if (mounted) setState(() => _writing = false);
    }
  }

  Future<void> _returnFromReview() async {
    final reviewIndex = _phaseIndex;
    if (_writing || reviewIndex == 0) return;
    final previous = widget.definition.phases[reviewIndex - 1];
    final review = widget.definition.phases[reviewIndex];
    setState(() => _writing = true);
    try {
      await _controller.dispatch(
        phaseId: review.id,
        actionType: 'review_returned',
        target: previous.id,
        value: const {'input_method': 'button'},
        transition: (state) => state.copyWith(currentPhaseId: previous.id),
      );
    } catch (_) {
      _technicalFeedback =
          'The review state could not be saved. Retry before returning.';
    } finally {
      if (mounted) setState(() => _writing = false);
    }
  }

  Future<void> _confirmSubmission() async {
    if (_submitting || _submitted || !_controller.canSubmit) return;
    setState(() => _submitting = true);
    try {
      final callback = widget.onSubmit ?? _submitAuthoritatively;
      await callback();
      _submitted = true;
      _technicalFeedback =
          'Evidence submitted for authoritative evaluation and review.';
    } catch (_) {
      _technicalFeedback =
          'Evidence could not be submitted. Your mission progress is preserved.';
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _submitAuthoritatively() async {
    final assessment = AuthoritativeAssessmentService.instance;
    if (assessment.activeSession == null) {
      throw StateError('No authoritative attempt is active.');
    }
    await assessment.submitAttempt(finalEvidence: {
      'mission_id': widget.definition.id,
      'runtime_schema_version': MissionRuntimeState.schemaVersion,
    });
  }

  Future<void> _leave() async {
    await _persistForLifecycle();
    if (mounted) await Navigator.of(context).maybePop();
  }
}

/// Maps catalog interaction declarations to the fourteen runtime components.
/// Unknown component names and structurally incomplete declarations render a
/// technical unavailable state rather than an inert control or exception.
class MissionPhaseInteraction extends StatelessWidget {
  const MissionPhaseInteraction({
    super.key,
    required this.phase,
    required this.state,
    required this.onAction,
    required this.onRuntimeTransition,
    required this.onReturnFromReview,
    required this.onConfirmReview,
    this.completedPhaseTitles = const [],
    this.authoritativeEvidenceCount = 0,
    this.pendingEvidenceCount = 0,
    this.failedEvidenceCount = 0,
    this.canSubmit = false,
    this.returnLabel = 'Return',
    this.confirmLabel = 'Confirm submission',
    this.enabled = true,
  });

  final MissionPhaseDefinition phase;
  final MissionRuntimeState state;
  final MissionActionCallback onAction;
  final ScenarioRuntimeTransitionCallback onRuntimeTransition;
  final VoidCallback onReturnFromReview;
  final VoidCallback onConfirmReview;
  final List<String> completedPhaseTitles;
  final int authoritativeEvidenceCount;
  final int pendingEvidenceCount;
  final int failedEvidenceCount;
  final bool canSubmit;
  final String returnLabel;
  final String confirmLabel;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    try {
      final component = _componentForPhase();
      if (component == null) {
        return TechnicalUnavailableState(phaseTitle: phase.title);
      }
      return _buildComponent(component);
    } catch (_) {
      return TechnicalUnavailableState(phaseTitle: phase.title);
    }
  }

  _MissionComponent? _componentForPhase() {
    final override = phase.presentation['component'];
    if (override != null && override is! String) return null;
    if (override is String) {
      return switch (override) {
        'tap_inspect' => _MissionComponent.inspect,
        'multi_select' => _MissionComponent.select,
        'tool_selection' => _MissionComponent.tool,
        'connection' => _MissionComponent.connect,
        'configuration' ||
        'configuration_decision' ||
        'service_controls' =>
          _MissionComponent.configure,
        'sequencing' ||
        'sequencing_and_placement' =>
          _MissionComponent.sequence,
        'matching' => _MissionComponent.match,
        'controlled_placement' => _MissionComponent.place,
        'troubleshooting' => _MissionComponent.troubleshoot,
        'test_run' ||
        'link_test' ||
        'test_with_interpretation' =>
          _MissionComponent.testRun,
        'observation' => _MissionComponent.observe,
        'scenario_decision' => _MissionComponent.decide,
        'result_interpretation' => _MissionComponent.interpret,
        'evidence_review' => _MissionComponent.review,
        _ => null,
      };
    }
    return _MissionComponent.values[phase.primaryInteraction.index];
  }

  Widget _buildComponent(_MissionComponent component) {
    final adaptedPhase = _adaptedPhase(component);
    if (!_hasRequiredInputs(component, adaptedPhase)) {
      return TechnicalUnavailableState(phaseTitle: phase.title);
    }
    return switch (component) {
      _MissionComponent.inspect => TapInspectInteraction(
          phase: adaptedPhase,
          state: state,
          onAction: onAction,
          enabled: enabled,
        ),
      _MissionComponent.select => MultiSelectInteraction(
          phase: adaptedPhase,
          state: state,
          onAction: onAction,
          enabled: enabled,
        ),
      _MissionComponent.tool => ToolSelectionInteraction(
          phase: adaptedPhase,
          state: state,
          onAction: onAction,
          enabled: enabled,
        ),
      _MissionComponent.connect => ConnectionInteraction(
          phase: adaptedPhase,
          state: state,
          onAction: onAction,
          enabled: enabled,
        ),
      _MissionComponent.configure => ConfigurationPanel(
          phase: adaptedPhase,
          state: state,
          onAction: onAction,
          enabled: enabled,
        ),
      _MissionComponent.sequence => SequencingInteraction(
          phase: adaptedPhase,
          state: state,
          onAction: onAction,
          enabled: enabled,
        ),
      _MissionComponent.match => MatchingInteraction(
          phase: adaptedPhase,
          state: state,
          onAction: onAction,
          enabled: enabled,
        ),
      _MissionComponent.place => ControlledPlacementInteraction(
          phase: adaptedPhase,
          state: state,
          onAction: onAction,
          enabled: enabled,
        ),
      _MissionComponent.troubleshoot => TroubleshootingBranchInteraction(
          phase: adaptedPhase,
          state: state,
          onAction: onAction,
          enabled: enabled,
        ),
      _MissionComponent.testRun => TestRunInteraction(
          phase: adaptedPhase,
          state: state,
          onAction: onAction,
          enabled: enabled,
        ),
      _MissionComponent.observe => ObservationInteraction(
          phase: adaptedPhase,
          state: state,
          onAction: onAction,
          enabled: enabled,
        ),
      _MissionComponent.decide => ScenarioDecisionInteraction(
          phase: adaptedPhase,
          state: state,
          onAction: onAction,
          onRuntimeTransition: onRuntimeTransition,
          enabled: enabled,
        ),
      _MissionComponent.interpret => ResultInterpretationInteraction(
          phase: adaptedPhase,
          state: state,
          onAction: onAction,
          enabled: enabled,
        ),
      _MissionComponent.review => EvidenceReviewPanel(
          completedPhaseTitles: completedPhaseTitles,
          authoritativeEvidenceCount: authoritativeEvidenceCount,
          pendingEvidenceCount: pendingEvidenceCount,
          failedEvidenceCount: failedEvidenceCount,
          canSubmit: canSubmit,
          onReturn: onReturnFromReview,
          onConfirm: onConfirmReview,
          returnLabel: returnLabel,
          confirmLabel: confirmLabel,
        ),
    };
  }

  MissionPhaseDefinition _adaptedPhase(_MissionComponent component) {
    if (component != _MissionComponent.sequence) return phase;
    if (_nonEmptyList(phase.presentation['items'])) return phase;
    final rawItems = phase.presentation['conductors'];
    final items = _nonEmptyList(rawItems)
        ? rawItems
        : [
            for (final id in phase.availableObjectIds)
              {'id': id, 'label': _labelForId(id)},
          ];
    return MissionPhaseDefinition(
      id: phase.id,
      title: phase.title,
      instruction: phase.instruction,
      primaryInteraction: phase.primaryInteraction,
      supportingInteractions: phase.supportingInteractions,
      availableObjectIds: phase.availableObjectIds,
      feedbackIds: phase.feedbackIds,
      presentation: {...phase.presentation, 'items': items},
    );
  }

  bool _hasRequiredInputs(
    _MissionComponent component,
    MissionPhaseDefinition candidate,
  ) {
    final data = candidate.presentation;
    return switch (component) {
      _MissionComponent.inspect ||
      _MissionComponent.select =>
        candidate.availableObjectIds.isNotEmpty ||
            _nonEmptyList(data['objects']) ||
            _nonEmptyList(data['options']),
      _MissionComponent.tool =>
        _nonEmptyList(data['targets']) && _nonEmptyList(data['tools']),
      _MissionComponent.connect ||
      _MissionComponent.match =>
        _nonEmptyList(data['sources']) && _nonEmptyList(data['destinations']),
      _MissionComponent.configure => _nonEmptyList(data['fields']),
      _MissionComponent.sequence => _nonEmptyList(data['items']),
      _MissionComponent.place =>
        _nonEmptyList(data['items']) && _nonEmptyList(data['destinations']),
      _MissionComponent.troubleshoot =>
        _nonEmptyList(data['diagnostic_actions']),
      _MissionComponent.decide => _nonEmptyList(data['choices']),
      _MissionComponent.testRun ||
      _MissionComponent.observe ||
      _MissionComponent.interpret ||
      _MissionComponent.review =>
        true,
    };
  }

  bool _nonEmptyList(dynamic value) => value is List && value.isNotEmpty;

  String _labelForId(String id) => id
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

class TechnicalUnavailableState extends StatelessWidget {
  const TechnicalUnavailableState({
    super.key,
    required this.phaseTitle,
    this.message,
    this.onRetry,
    this.onReset,
  });

  final String phaseTitle;
  final String? message;
  final VoidCallback? onRetry;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        label: '$phaseTitle is not available',
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceMuted,
            borderRadius: AppTheme.radiusSm,
            border: Border.all(color: AppTheme.borderMedium),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.build_circle_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message ??
                          'This technical interaction is not available. '
                              'Return to the mission list or contact your '
                              'Instructor.',
                    ),
                    if (onRetry != null || onReset != null) ...[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (onRetry != null)
                            OutlinedButton(
                              onPressed: onRetry,
                              child: const Text('Retry restore'),
                            ),
                          if (onReset != null)
                            FilledButton(
                              onPressed: onReset,
                              child: const Text('Reset saved progress'),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _MissionHeader extends StatelessWidget {
  const _MissionHeader({
    required this.title,
    required this.environment,
    required this.phaseIndex,
    required this.phaseCount,
    required this.onBack,
  });

  final String title;
  final String environment;
  final int phaseIndex;
  final int phaseCount;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
        ),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Leave mission',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.titleSmall,
                  ),
                  Text(
                    environment,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              label: 'Phase ${phaseIndex + 1} of $phaseCount',
              child: Text(
                '${phaseIndex + 1}/$phaseCount',
                style: AppTheme.labelLarge,
              ),
            ),
          ],
        ),
      );
}

enum _MissionComponent {
  inspect,
  select,
  tool,
  connect,
  configure,
  sequence,
  match,
  place,
  troubleshoot,
  testRun,
  observe,
  decide,
  interpret,
  review,
}

final class _PracticeEvidenceTransport implements MissionEvidenceTransport {
  final Set<String> _acceptedIds = <String>{};

  @override
  Future<void> append(MissionEvidenceAction action) async {
    _acceptedIds.add(action.clientActionId);
  }

  @override
  Future<Set<String>> acknowledgedClientActionIds() async =>
      Set<String>.from(_acceptedIds);
}
