import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/mission_header.dart';
import '../../../models/mission_model.dart';
import '../../../services/authoritative_assessment_service.dart';
import '../components/mission_simulation_profile.dart';
import '../components/simulation_framework.dart';
import '../result_screen.dart';
import 'authoritative_mission_contract.dart';

class AuthoritativeMissionAssessmentScreen extends StatefulWidget {
  final Mission mission;
  final Map<String, dynamic> learnerPayload;

  const AuthoritativeMissionAssessmentScreen({
    super.key,
    required this.mission,
    required this.learnerPayload,
  });

  @override
  State<AuthoritativeMissionAssessmentScreen> createState() =>
      _AuthoritativeMissionAssessmentScreenState();
}

class _AuthoritativeMissionAssessmentScreenState
    extends State<AuthoritativeMissionAssessmentScreen> {
  final _assessment = AuthoritativeAssessmentService.instance;
  final _selectedItems = <String>{};
  final _sequence = <String>[];
  final _fieldValues = <String, String>{};
  final _inspectedObjects = <String>{};
  final _operationalActions = <String>{};
  AuthoritativeMissionContract? _contract;
  String? _contractError;
  String? _selectedOption;
  String? _selectedMatchField;
  String? _writeError;
  int _stageIndex = 0;
  int _elapsedSeconds = 0;
  bool _writing = false;
  bool _restoring = true;
  bool _evidenceComplete = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    try {
      _contract = AuthoritativeMissionContract.fromLearnerPayload(
          widget.learnerPayload);
    } on FormatException catch (error) {
      _contractError = error.message.toString();
    }
    unawaited(_restoreProgress());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  AuthoritativeMissionStage get _stage => _contract!.stages[_stageIndex];

  MissionSimulationProfile get _profile =>
      MissionSimulationProfile.forMission(_contract!.localMissionCode);

  Future<void> _restoreProgress() async {
    if (_contract == null || _assessment.activeSession == null) {
      if (mounted) setState(() => _restoring = false);
      _startTimer();
      return;
    }
    try {
      final actions = await _assessment.getActiveAttemptActions();
      var firstIncomplete = 0;
      var allComplete = true;
      for (var index = 0; index < _contract!.stages.length; index++) {
        final stage = _contract!.stages[index];
        final stageActions = actions.where((action) {
          final value = Map<String, dynamic>.from(
              action['value'] as Map? ?? const <String, dynamic>{});
          return value['criterion_code'] == stage.criterionCode;
        }).toList(growable: false);
        final criterionActions = stageActions
            .where((action) => action['action_type'] == stage.actionType)
            .toList(growable: false);
        final complete = switch (stage.type) {
          AuthoritativeStageType.sequence => criterionActions
                  .where((action) => action['target'] != null)
                  .length >=
              stage.requiredCount,
          AuthoritativeStageType.selection ||
          AuthoritativeStageType.configuration ||
          AuthoritativeStageType.matching =>
            criterionActions.any((action) {
              final value = Map<String, dynamic>.from(
                  action['value'] as Map? ?? const <String, dynamic>{});
              return (value['selected_items'] as List?)?.length ==
                  stage.requiredCount;
            }),
          AuthoritativeStageType.singleChoice => criterionActions.any((action) {
              final value = Map<String, dynamic>.from(
                  action['value'] as Map? ?? const <String, dynamic>{});
              return value['selected_option'] != null;
            }),
        };
        if (!complete) {
          firstIncomplete = index;
          allComplete = false;
          if (stage.type == AuthoritativeStageType.sequence) {
            _sequence
              ..clear()
              ..addAll(criterionActions
                  .map((action) => action['target'] as String?)
                  .whereType<String>());
          }
          _restoreDraftState(stageActions);
          break;
        }
      }
      final startedAt = _assessment.activeSession!.startedAt;
      if (!mounted) return;
      setState(() {
        _stageIndex =
            allComplete ? _contract!.stages.length - 1 : firstIncomplete;
        _elapsedSeconds = DateTime.now().difference(startedAt).inSeconds;
        _restoring = false;
        _evidenceComplete = allComplete;
      });
      if (allComplete) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_openSubmissionReview());
        });
      } else {
        _startTimer();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _restoring = false;
        _contractError =
            'Your saved assessment progress could not be restored. Try again.';
      });
    }
  }

  void _restoreDraftState(List<Map<String, dynamic>> actions) {
    for (final action in actions) {
      final actionType = action['action_type'] as String? ?? '';
      final value = Map<String, dynamic>.from(
          action['value'] as Map? ?? const <String, dynamic>{});
      if (actionType == 'simulation_scene_inspected') {
        final target = action['target'] as String?;
        if (target != null) _inspectedObjects.add(target);
      } else if (actionType == 'simulation_operational_action') {
        final operation = value['operation'] as String?;
        if (operation != null) _operationalActions.add(operation);
      } else if (actionType == 'simulation_selection_draft') {
        _selectedItems
          ..clear()
          ..addAll((value['selected_items'] as List? ?? const [])
              .whereType<String>());
      } else if (actionType == 'simulation_decision_draft') {
        _selectedOption = value['selected_option'] as String?;
      } else if (actionType == 'simulation_field_draft') {
        final field = action['target'] as String?;
        final selectedValue = value['selected_value'] as String?;
        if (field != null && selectedValue != null) {
          _fieldValues[field] = selectedValue;
        }
      }
    }
  }

  void _startTimer() {
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  Future<bool> _record({
    required String actionType,
    String? target,
    Map<String, dynamic> value = const {},
  }) async {
    if (_writing) return false;
    setState(() {
      _writing = true;
      _writeError = null;
    });
    try {
      await _assessment.recordAction(
        actionType: actionType,
        target: target,
        value: {
          ...value,
          'assessment_package_id': _contract!.packageId,
          'criterion_code': _stage.criterionCode,
          'local_mission_id': widget.mission.id,
        },
      );
      if (mounted) setState(() => _writing = false);
      return true;
    } catch (_) {
      if (mounted) {
        setState(() {
          _writing = false;
          _writeError =
              'This evidence was not saved. Check the connection and try again.';
        });
      }
      return false;
    }
  }

  Future<void> _chooseSequenceItem(String id) async {
    if (_writing || _sequence.contains(id)) return;
    if (!await _record(actionType: _stage.actionType, target: id)) return;
    if (mounted) setState(() => _sequence.add(id));
  }

  Future<void> _inspectSceneObject(String id) async {
    if (_writing || _inspectedObjects.contains(id)) return;
    if (!await _record(
      actionType: 'simulation_scene_inspected',
      target: id,
      value: {
        'interaction_type': 'scene_inspection',
        'scene_kind': _profile.sceneKind.name,
      },
    )) {
      return;
    }
    if (mounted) setState(() => _inspectedObjects.add(id));
  }

  Future<void> _performOperationalAction(String operation) async {
    if (_writing || _operationalActions.contains(operation)) return;
    if (!await _record(
      actionType: 'simulation_operational_action',
      target: _stage.id,
      value: {
        'interaction_type': operation,
        'operation': operation,
      },
    )) {
      return;
    }
    if (mounted) setState(() => _operationalActions.add(operation));
  }

  Future<void> _changeSelection(String id, bool selected) async {
    if (_writing) return;
    final next = {..._selectedItems};
    if (selected) {
      if (next.length >= _stage.requiredCount) return;
      next.add(id);
    } else {
      next.remove(id);
    }
    if (!await _record(
      actionType: 'simulation_selection_draft',
      value: {
        'interaction_type': 'multi_select',
        'selected_items': next.toList()..sort(),
      },
    )) {
      return;
    }
    if (mounted) {
      setState(() {
        _selectedItems
          ..clear()
          ..addAll(next);
      });
    }
  }

  Future<void> _changeDecision(String id) async {
    if (_writing || _selectedOption == id) return;
    if (!await _record(
      actionType: 'simulation_decision_draft',
      target: id,
      value: {
        'interaction_type': 'scenario_decision',
        'selected_option': id,
      },
    )) {
      return;
    }
    if (mounted) setState(() => _selectedOption = id);
  }

  Future<void> _changeField(String field, String value) async {
    if (_writing || _fieldValues[field] == value) return;
    if (!await _record(
      actionType: 'simulation_field_draft',
      target: field,
      value: {
        'interaction_type': _stage.type == AuthoritativeStageType.matching
            ? 'source_destination_connection'
            : 'configuration_change',
        'selected_value': value,
      },
    )) {
      return;
    }
    if (mounted) setState(() => _fieldValues[field] = value);
  }

  bool get _canContinue {
    if (_writing || _contract == null) return false;
    final evidenceReady = switch (_stage.type) {
      AuthoritativeStageType.selection =>
        _selectedItems.length == _stage.requiredCount,
      AuthoritativeStageType.sequence =>
        _sequence.length == _stage.requiredCount,
      AuthoritativeStageType.singleChoice => _selectedOption != null,
      AuthoritativeStageType.configuration ||
      AuthoritativeStageType.matching =>
        _fieldValues.length == _stage.requiredCount,
    };
    final presentation = presentationForStage(_stage);
    if (presentation == SimulationPresentationKind.testing) {
      return evidenceReady &&
          _operationalActions.contains('run_simulated_test');
    }
    if (presentation == SimulationPresentationKind.troubleshooting) {
      return evidenceReady && _operationalActions.contains('inspect_symptom');
    }
    return evidenceReady;
  }

  Future<void> _continue() async {
    if (!_canContinue) return;
    final recorded = switch (_stage.type) {
      AuthoritativeStageType.selection => await _record(
          actionType: _stage.actionType,
          value: {'selected_items': _selectedItems.toList()..sort()},
        ),
      AuthoritativeStageType.sequence => true,
      AuthoritativeStageType.singleChoice => await _record(
          actionType: _stage.actionType,
          value: {'selected_option': _selectedOption},
        ),
      AuthoritativeStageType.configuration ||
      AuthoritativeStageType.matching =>
        await _record(
          actionType: _stage.actionType,
          value: {
            'selected_items': _fieldValues.entries
                .map((entry) => '${entry.key}=${entry.value}')
                .toList()
              ..sort(),
          },
        ),
    };
    if (!recorded || !mounted) return;
    if (_stageIndex == _contract!.stages.length - 1) {
      setState(() => _evidenceComplete = true);
      _timer?.cancel();
      await _openSubmissionReview();
      return;
    }
    setState(() {
      _stageIndex++;
      _selectedItems.clear();
      _sequence.clear();
      _fieldValues.clear();
      _selectedOption = null;
      _selectedMatchField = null;
      _inspectedObjects.clear();
      _operationalActions.clear();
      _writeError = null;
    });
  }

  Future<void> _openSubmissionReview() async {
    _timer?.cancel();
    _timer = null;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          mission: widget.mission,
          result: MissionResult(
            missionId: widget.mission.id,
            score: 0,
            percentage: 0,
            passed: false,
            xpEarned: 0,
            timeSpent: _elapsedSeconds,
            rating: 'awaiting-database-evaluation',
            competencyStatus: 'provisional-review-required',
          ),
        ),
      ),
    );
    if (mounted && _assessment.activeSession != null) _startTimer();
  }

  Future<void> _showExitNotice() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Assessment in progress'),
        content: const Text(
          'Recorded evidence remains protected if you leave. The incomplete attempt will not be evaluated or released.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Leave assessment'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Continue assessment'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_restoring) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_contractError != null || _contract == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Assessment unavailable')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _contractError ?? 'The published assessment could not be loaded.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_showExitNotice());
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundOffWhite,
        body: Column(
          children: [
            MissionHeader(
              mission: widget.mission,
              subtitle: 'Assessment · ${_contract!.unitCode}',
              onBackPressed: _showExitNotice,
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final gutter = constraints.maxWidth < 380 ? 12.0 : 20.0;
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 32),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 780),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            MissionProgress(
                              unitTitle: _contract!.unitTitle,
                              profile: _profile,
                              current: _stageIndex + 1,
                              total: _contract!.stages.length,
                            ),
                            const SizedBox(height: 16),
                            AnimatedSwitcher(
                              duration: MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : const Duration(milliseconds: 200),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              child: SimulationStageExperience(
                                key: ValueKey(_stage.id),
                                stage: _stage,
                                profile: _profile,
                                inspectedObjectIds: _inspectedObjects,
                                selectedItems: _selectedItems,
                                sequence: _sequence,
                                selectedOption: _selectedOption,
                                selectedMatchField: _selectedMatchField,
                                fieldValues: _fieldValues,
                                writing: _writing,
                                onInspectObject: (id) =>
                                    unawaited(_inspectSceneObject(id)),
                                onSelectionChanged: (id, selected) =>
                                    unawaited(_changeSelection(id, selected)),
                                onSequenceSelected: _chooseSequenceItem,
                                onSingleSelected: (id) =>
                                    unawaited(_changeDecision(id)),
                                onFieldSelected: (field, value) =>
                                    unawaited(_changeField(field, value)),
                                onMatchSourceSelected: (field) => setState(
                                  () => _selectedMatchField = field,
                                ),
                                onMatchDestinationSelected: (destination) {
                                  final field = _selectedMatchField;
                                  if (field == null) return;
                                  unawaited(_changeField(field, destination));
                                  setState(() => _selectedMatchField = null);
                                  unawaited(HapticFeedback.selectionClick());
                                },
                                onOperationalAction: _performOperationalAction,
                                operationalActions: _operationalActions,
                              ),
                            ),
                            if (_writeError != null) ...[
                              const SizedBox(height: 12),
                              _EvidenceError(message: _writeError!),
                            ],
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: _evidenceComplete
                                  ? _openSubmissionReview
                                  : (_canContinue ? _continue : null),
                              icon: _writing
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Icon(
                                      _evidenceComplete ||
                                              _stageIndex ==
                                                  _contract!.stages.length - 1
                                          ? Icons.verified_outlined
                                          : Icons.arrow_forward_rounded,
                                    ),
                              label: Text(
                                _evidenceComplete
                                    ? 'Review recorded evidence'
                                    : _stageIndex ==
                                            _contract!.stages.length - 1
                                        ? 'Review before submission'
                                        : 'Record stage and continue',
                              ),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No correctness is revealed during assessment. PostgreSQL evaluates the recorded evidence, and your Instructor reviews the provisional result before release.',
                              style: AppTheme.caption.copyWith(
                                color: AppTheme.textMedium,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Retained temporarily for binary-safe rollback of the previous generalized
// renderer. The active assessment path uses MissionProgress above.
// ignore: unused_element
class _AssessmentContext extends StatelessWidget {
  final String unitTitle;
  final int current;
  final int total;
  final double progress;

  const _AssessmentContext({
    required this.unitTitle,
    required this.current,
    required this.total,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Assessment stage $current of $total',
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppTheme.radiusMd,
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      unitTitle,
                      style: AppTheme.labelLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('$current / $total', style: AppTheme.labelMedium),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppTheme.softBlueAccent,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
        ),
      );
}

// Retained temporarily for binary-safe rollback of the previous stage UI. The
// active path uses SimulationStageExperience from the shared 2D framework.
// ignore: unused_element
class _StagePanel extends StatelessWidget {
  final AuthoritativeMissionStage stage;
  final Set<String> selectedItems;
  final List<String> sequence;
  final String? selectedOption;
  final String? selectedMatchField;
  final Map<String, String> fieldValues;
  final bool writing;
  final void Function(String id, bool selected) onSelectionChanged;
  final Future<void> Function(String id) onSequenceSelected;
  final ValueChanged<String> onSingleSelected;
  final void Function(String field, String value) onFieldSelected;
  final ValueChanged<String?> onMatchSourceSelected;
  final ValueChanged<String> onMatchDestinationSelected;

  const _StagePanel({
    required this.stage,
    required this.selectedItems,
    required this.sequence,
    required this.selectedOption,
    required this.selectedMatchField,
    required this.fieldValues,
    required this.writing,
    required this.onSelectionChanged,
    required this.onSequenceSelected,
    required this.onSingleSelected,
    required this.onFieldSelected,
    required this.onMatchSourceSelected,
    required this.onMatchDestinationSelected,
  });

  String _label(String id) {
    for (final option in stage.options) {
      if (option.id == id) return option.label;
    }
    return id.replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppTheme.radiusMd,
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.softBlueAccent,
                    borderRadius: AppTheme.radiusSm,
                  ),
                  child: Icon(_iconFor(stage.type), color: AppTheme.deepBlue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stage.title, style: AppTheme.headlineSmall),
                      const SizedBox(height: 6),
                      Text(stage.instruction, style: AppTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            switch (stage.type) {
              AuthoritativeStageType.selection => _selection(),
              AuthoritativeStageType.sequence => _sequence(),
              AuthoritativeStageType.singleChoice => _singleChoice(),
              AuthoritativeStageType.configuration => _fields(),
              AuthoritativeStageType.matching => _matching(),
            },
          ],
        ),
      );

  Widget _selection() => Column(
        children: [
          for (final option in stage.options)
            Semantics(
              selected: selectedItems.contains(option.id),
              child: CheckboxListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(option.label, style: AppTheme.bodyLarge),
                value: selectedItems.contains(option.id),
                onChanged: writing
                    ? null
                    : (value) => onSelectionChanged(option.id, value ?? false),
              ),
            ),
          const SizedBox(height: 8),
          _CountStatus(
            icon: Icons.checklist_rounded,
            text:
                '${selectedItems.length} of ${stage.requiredCount} selections recorded',
          ),
        ],
      );

  Widget _sequence() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Choose the next action',
            style: AppTheme.labelLarge,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: stage.options.map((option) {
              final used = sequence.contains(option.id);
              return Semantics(
                button: true,
                enabled: !used && !writing,
                label: used
                    ? '${option.label}, already recorded'
                    : 'Record ${option.label} as the next action',
                child: OutlinedButton.icon(
                  onPressed: used || writing
                      ? null
                      : () => onSequenceSelected(option.id),
                  icon: Icon(used
                      ? Icons.check_rounded
                      : Icons.add_circle_outline_rounded),
                  label: Text(option.label),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ),
                ),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 18),
          Text('Recorded timeline', style: AppTheme.labelLarge),
          const SizedBox(height: 8),
          if (sequence.isEmpty)
            Text(
              'No actions recorded yet.',
              style: AppTheme.bodyMedium,
            )
          else
            for (var index = 0; index < sequence.length; index++)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  child: Text('${index + 1}'),
                ),
                title: Text(_label(sequence[index]), style: AppTheme.bodyLarge),
                subtitle: const Text('Chronological evidence saved'),
              ),
          const SizedBox(height: 8),
          _CountStatus(
            icon: Icons.timeline_rounded,
            text:
                '${sequence.length} of ${stage.requiredCount} actions recorded',
          ),
        ],
      );

  Widget _singleChoice() => RadioGroup<String>(
        groupValue: selectedOption,
        onChanged: (value) {
          if (writing) return;
          if (value != null) onSingleSelected(value);
        },
        child: Column(
          children: [
            for (final option in stage.options)
              RadioListTile<String>(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                title: Text(option.label, style: AppTheme.bodyLarge),
                value: option.id,
                enabled: !writing,
              ),
          ],
        ),
      );

  Widget _fields() => Column(
        children: [
          for (final field in stage.fields) ...[
            DropdownButtonFormField<String>(
              initialValue: fieldValues[field.id],
              decoration: InputDecoration(
                labelText: field.label,
                helperText: stage.type == AuthoritativeStageType.matching
                    ? 'Choose the destination required by the scenario.'
                    : 'Choose the value required by the scenario design.',
                border: const OutlineInputBorder(),
              ),
              isExpanded: true,
              items: field.options
                  .map((item) => DropdownMenuItem(
                        value: item.id,
                        child: Text(item.label),
                      ))
                  .toList(growable: false),
              onChanged: writing
                  ? null
                  : (value) {
                      if (value != null) onFieldSelected(field.id, value);
                    },
            ),
            const SizedBox(height: 16),
          ],
          _CountStatus(
            icon: stage.type == AuthoritativeStageType.matching
                ? Icons.hub_outlined
                : Icons.tune_rounded,
            text:
                '${fieldValues.length} of ${stage.requiredCount} fields completed',
          ),
        ],
      );

  Widget _matching() {
    final destinations = <String, String>{};
    for (final field in stage.fields) {
      for (final option in field.options) {
        destinations.putIfAbsent(option.id, () => option.label);
      }
    }
    String fieldLabel(String id) =>
        stage.fields.firstWhere((field) => field.id == id).label;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Items to place', style: AppTheme.labelLarge),
        const SizedBox(height: 6),
        Text(
          'Drag an item to a destination, or select the item and then select its destination.',
          style: AppTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: stage.fields.map((field) {
            final selected = selectedMatchField == field.id;
            final destination = fieldValues[field.id];
            final label = destination == null
                ? field.label
                : '${field.label} · ${destinations[destination] ?? destination}';
            return Semantics(
              key: ValueKey('assessment-match-source-${field.id}'),
              button: true,
              selected: selected,
              label: destination == null
                  ? '${field.label}, not placed'
                  : '${field.label}, placed at ${destinations[destination] ?? destination}',
              child: Draggable<String>(
                data: field.id,
                maxSimultaneousDrags: writing ? 0 : 1,
                feedback: Material(
                  color: Colors.transparent,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 260),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppTheme.deepBlue,
                        borderRadius: AppTheme.radiusSm,
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Text(
                          field.label,
                          style: AppTheme.labelLarge.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.35,
                  child: _MatchSource(label: label, selected: selected),
                ),
                child: InkWell(
                  onTap: writing
                      ? null
                      : () => onMatchSourceSelected(
                            selected ? null : field.id,
                          ),
                  borderRadius: AppTheme.radiusSm,
                  child: _MatchSource(label: label, selected: selected),
                ),
              ),
            );
          }).toList(growable: false),
        ),
        const SizedBox(height: 20),
        Text('Destinations', style: AppTheme.labelLarge),
        const SizedBox(height: 10),
        for (final destination in destinations.entries) ...[
          DragTarget<String>(
            onWillAcceptWithDetails: (_) => !writing,
            onAcceptWithDetails: (details) {
              onFieldSelected(details.data, destination.key);
              onMatchSourceSelected(null);
              unawaited(HapticFeedback.selectionClick());
            },
            builder: (context, candidates, _) {
              final assigned = fieldValues.entries
                  .where((entry) => entry.value == destination.key)
                  .map((entry) => fieldLabel(entry.key))
                  .toList(growable: false);
              final active = candidates.isNotEmpty;
              return Semantics(
                key:
                    ValueKey('assessment-match-destination-${destination.key}'),
                button: true,
                label: assigned.isEmpty
                    ? '${destination.value}, empty destination'
                    : '${destination.value}, contains ${assigned.join(", ")}',
                child: InkWell(
                  onTap: writing || selectedMatchField == null
                      ? null
                      : () => onMatchDestinationSelected(destination.key),
                  borderRadius: AppTheme.radiusSm,
                  child: AnimatedContainer(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 160),
                    constraints: const BoxConstraints(minHeight: 64),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: active
                          ? AppTheme.softBlueAccent
                          : AppTheme.backgroundOffWhite,
                      borderRadius: AppTheme.radiusSm,
                      border: Border.all(
                        color: active
                            ? AppTheme.primaryBlue
                            : AppTheme.borderLight,
                        width: active ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          active
                              ? Icons.move_to_inbox_rounded
                              : Icons.place_outlined,
                          color: active
                              ? AppTheme.primaryBlue
                              : AppTheme.textMedium,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(destination.value,
                                  style: AppTheme.labelLarge),
                              if (assigned.isNotEmpty)
                                Text(
                                  assigned.join(', '),
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.textMedium,
                                  ),
                                )
                              else
                                Text(
                                  selectedMatchField == null
                                      ? 'Drag or select an item'
                                      : 'Select to place the chosen item',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.textMedium,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 6),
        _CountStatus(
          icon: Icons.hub_outlined,
          text: '${fieldValues.length} of ${stage.requiredCount} items placed',
        ),
      ],
    );
  }

  static IconData _iconFor(AuthoritativeStageType type) => switch (type) {
        AuthoritativeStageType.selection => Icons.checklist_rounded,
        AuthoritativeStageType.sequence => Icons.timeline_rounded,
        AuthoritativeStageType.singleChoice => Icons.visibility_outlined,
        AuthoritativeStageType.configuration => Icons.tune_rounded,
        AuthoritativeStageType.matching => Icons.hub_outlined,
      };
}

class _MatchSource extends StatelessWidget {
  final String label;
  final bool selected;

  const _MatchSource({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AppTheme.softBlueAccent : Colors.white,
          borderRadius: AppTheme.radiusSm,
          border: Border.all(
            color: selected ? AppTheme.primaryBlue : AppTheme.borderLight,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.touch_app_rounded : Icons.drag_indicator_rounded,
              size: 20,
              color: selected ? AppTheme.primaryBlue : AppTheme.textMedium,
            ),
            const SizedBox(width: 8),
            Flexible(child: Text(label, style: AppTheme.labelMedium)),
          ],
        ),
      );
}

class _CountStatus extends StatelessWidget {
  final IconData icon;
  final String text;

  const _CountStatus({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.backgroundPaleBlue,
            borderRadius: AppTheme.radiusSm,
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.deepBlue),
              const SizedBox(width: 8),
              Expanded(child: Text(text, style: AppTheme.labelMedium)),
            ],
          ),
        ),
      );
}

class _EvidenceError extends StatelessWidget {
  final String message;

  const _EvidenceError({required this.message});

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.errorRed.withValues(alpha: 0.08),
            borderRadius: AppTheme.radiusSm,
            border: Border.all(color: AppTheme.errorRed),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: AppTheme.errorRed),
              const SizedBox(width: 10),
              Expanded(child: Text(message, style: AppTheme.bodyMedium)),
            ],
          ),
        ),
      );
}
