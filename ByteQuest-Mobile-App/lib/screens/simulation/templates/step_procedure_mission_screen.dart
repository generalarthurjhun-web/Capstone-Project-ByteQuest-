import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/evaluation/sequence_evaluator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/soft_card.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/simulation_fullscreen_button.dart';
import '../../../models/mission_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/progress_resume_service.dart';
import '../../../services/authoritative_assessment_service.dart';
import '../result_screen.dart';

/// Template 4: Step-Based Procedure Mission Screen
/// Used for: COC1-M5, COC2-M3, COC3-M2, COC4-M2
class StepProcedureMissionScreen extends StatefulWidget {
  final Mission mission;
  final List<ProcedureStep> steps;

  const StepProcedureMissionScreen({
    super.key,
    required this.mission,
    required this.steps,
  });

  @override
  State<StepProcedureMissionScreen> createState() =>
      _StepProcedureMissionScreenState();
}

class _StepProcedureMissionScreenState
    extends State<StepProcedureMissionScreen> {
  final Set<String> _completedSteps = {};
  final List<String> _completionOrder = [];
  final Map<String, bool> _stepValidation = {};
  bool _showValidation = false;
  int _timeSpent = 0;
  Timer? _timer;
  int _correctSteps = 0;
  List<String> _mistakes = [];

  @override
  void initState() {
    super.initState();
    _startTimer();
    _loadProgressState();
  }

  Future<void> _loadProgressState() async {
    final userId = AuthService().currentUserId;
    if (userId == null) return;

    final state = await ProgressResumeService.loadState(
      userId: userId,
      missionId: widget.mission.id,
    );

    if (state != null && state['stateData'] != null) {
      final data = state['stateData'] as Map<String, dynamic>;
      setState(() {
        _timeSpent = data['timeSpent'] ?? 0;
        _correctSteps = data['correctSteps'] ?? 0;
        _mistakes = List<String>.from(data['mistakes'] ?? []);

        final completed = data['completedSteps'] as List<dynamic>?;
        if (completed != null) {
          _completedSteps.addAll(completed.cast<String>());
        }
      });
      debugPrint('Loaded state for step procedure.');
    }
  }

  Future<void> _saveProgressState() async {
    final userId = AuthService().currentUserId;
    if (userId == null) return;

    final stateData = {
      'timeSpent': _timeSpent,
      'correctSteps': _correctSteps,
      'mistakes': _mistakes,
      'completedSteps': _completedSteps.toList(),
    };

    await ProgressResumeService.saveState(
      userId: userId,
      missionId: widget.mission.id,
      cocId: widget.mission.cocId,
      currentStep: _completedSteps.length,
      totalSteps: widget.steps.length,
      stateData: stateData,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _timeSpent++;
        });
      }
    });
  }

  void _toggleStep(String stepId) {
    if (_showValidation) return;

    setState(() {
      if (_completedSteps.contains(stepId)) {
        _completedSteps.remove(stepId);
      } else {
        _completedSteps.add(stepId);
        _completionOrder.add(stepId);
      }
    });
    unawaited(AuthoritativeAssessmentService.instance.safeRecordAction(
      actionType: _completedSteps.contains(stepId)
          ? 'procedure_step_selected'
          : 'procedure_step_deselected',
      target: stepId,
      value: {'local_mission_id': widget.mission.id},
    ));
    _saveProgressState();
  }

  void _validateProcedure() {
    final sortedSteps = widget.steps.toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    final requiredIds = sortedSteps
        .where((step) => step.isRequired)
        .map((step) => step.id)
        .toList();
    final sequenceEvaluation = evaluateRequiredSequence(
      expected: requiredIds,
      chronologicalActions: _completionOrder,
    );

    setState(() {
      _showValidation = true;
      _correctSteps = 0;
      _mistakes.clear();
      _stepValidation.clear();

      for (final step in sortedSteps) {
        final isCompleted = _completedSteps.contains(step.id);

        if (step.isRequired) {
          if (isCompleted) {
            if (sequenceEvaluation.isAtExpectedPosition(step.id)) {
              _stepValidation[step.id] = true;
              _correctSteps++;
            } else {
              _stepValidation[step.id] = false;
              _mistakes.add('${step.title}: Completed out of sequence');
            }
          } else {
            _stepValidation[step.id] = false;
            _mistakes.add('${step.title}: Not completed');
          }
        } else {
          // Optional steps always count as correct if completed
          if (isCompleted) {
            _stepValidation[step.id] = true;
            _correctSteps++;
          }
        }
      }
    });

    _saveProgressState();
    unawaited(AuthoritativeAssessmentService.instance.safeRecordAction(
      actionType: 'procedure_validation_requested',
      target: widget.mission.id,
      value: {
        'expected_step_ids': sequenceEvaluation.expected,
        'observed_step_ids': sequenceEvaluation.observed,
        'exact_sequence_match': sequenceEvaluation.isExactMatch,
      },
    ));

    // If all correct, auto-finish after 2 seconds
    if (sequenceEvaluation.isExactMatch) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _finishMission();
        }
      });
    }
  }

  void _finishMission() {
    _timer?.cancel();

    final userId = AuthService().currentUserId;
    if (userId != null) {
      ProgressResumeService.clearState(
        userId: userId,
        missionId: widget.mission.id,
      );
    }

    final requiredSteps = widget.steps.where((s) => s.isRequired).length;
    final accuracy = requiredSteps == 0
        ? 0
        : ((_correctSteps / requiredSteps) * 100).clamp(0, 100).toInt();

    final result = MissionResult(
      missionId: widget.mission.id,
      score: accuracy,
      percentage: accuracy,
      passed: false,
      xpEarned: 0,
      timeSpent: _timeSpent,
      rating: 'practice-feedback',
      competencyStatus: 'awaiting-trusted-evaluation',
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          mission: widget.mission,
          result: result,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _completedSteps.length / widget.steps.length;
    final requiredSteps = widget.steps.where((s) => s.isRequired).length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundOffWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.textDark),
          onPressed: () => _showExitDialog(),
        ),
        title: Text(
          widget.mission.title,
          style: AppTheme.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          const SimulationFullscreenButton(),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                _formatTime(_timeSpent),
                style: AppTheme.labelMedium.copyWith(
                  color: AppTheme.textMedium,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
              minHeight: 6,
            ),

            // Instruction Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: AppTheme.primaryBlue.withValues(alpha: 0.05),
              child: Row(
                children: [
                  Icon(
                    Icons.list_alt,
                    color: AppTheme.primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Complete all steps in the correct order',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Progress Info
                    SoftCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Steps Completed',
                                style: AppTheme.labelSmall.copyWith(
                                  color: AppTheme.textMedium,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_completedSteps.length}/${widget.steps.length}',
                                style: AppTheme.headlineMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          if (_showValidation) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _correctSteps >= requiredSteps
                                    ? AppTheme.accentGreen
                                        .withValues(alpha: 0.1)
                                    : AppTheme.accentOrange
                                        .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _correctSteps >= requiredSteps
                                        ? Icons.check_circle
                                        : Icons.warning,
                                    size: 16,
                                    color: _correctSteps >= requiredSteps
                                        ? AppTheme.accentGreen
                                        : AppTheme.accentOrange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$_correctSteps/$requiredSteps Correct',
                                    style: AppTheme.labelSmall.copyWith(
                                      color: _correctSteps >= requiredSteps
                                          ? AppTheme.accentGreen
                                          : AppTheme.accentOrange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Procedure Steps
                    Text(
                      'Procedure Checklist',
                      style: AppTheme.headlineSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    ...widget.steps.asMap().entries.map((entry) {
                      final index = entry.key;
                      final step = entry.value;
                      final isCompleted = _completedSteps.contains(step.id);
                      final showFeedback = _showValidation &&
                          _stepValidation.containsKey(step.id);
                      final isCorrect = _stepValidation[step.id] ?? false;
                      final isLastStep = index == widget.steps.length - 1;

                      return Column(
                        children: [
                          _buildStepCard(
                              step, isCompleted, showFeedback, isCorrect),
                          if (!isLastStep) ...[
                            Padding(
                              padding: const EdgeInsets.only(left: 24),
                              child: Container(
                                width: 2,
                                height: 12,
                                color: isCompleted
                                    ? AppTheme.primaryBlue
                                        .withValues(alpha: 0.3)
                                    : AppTheme.textLight.withValues(alpha: 0.2),
                              ),
                            ),
                          ],
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Submit Button
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    if (_showValidation && _correctSteps < requiredSteps) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.accentOrange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppTheme.accentOrange,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Review the procedure and ensure all steps are completed in order.',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.accentOrange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    AppButton.primary(
                      label: _showValidation && _correctSteps >= requiredSteps
                          ? 'View Results'
                          : 'Verify Procedure',
                      icon: Icons.check,
                      onPressed: _completedSteps.length >= requiredSteps
                          ? _validateProcedure
                          : () {},
                      width: double.infinity,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard(
      ProcedureStep step, bool isCompleted, bool showFeedback, bool isCorrect) {
    return InkWell(
      onTap: () => _toggleStep(step.id),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: showFeedback
              ? (isCorrect
                  ? AppTheme.accentGreen.withValues(alpha: 0.05)
                  : AppTheme.errorRed.withValues(alpha: 0.05))
              : Colors.white,
          border: Border.all(
            color: showFeedback
                ? (isCorrect ? AppTheme.accentGreen : AppTheme.errorRed)
                : (isCompleted
                    ? AppTheme.primaryBlue
                    : AppTheme.textLight.withValues(alpha: 0.2)),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step Number/Checkbox
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCompleted
                    ? (showFeedback
                        ? (isCorrect ? AppTheme.accentGreen : AppTheme.errorRed)
                        : AppTheme.primaryBlue)
                    : AppTheme.textLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCompleted
                      ? (showFeedback
                          ? (isCorrect
                              ? AppTheme.accentGreen
                              : AppTheme.errorRed)
                          : AppTheme.primaryBlue)
                      : AppTheme.textLight.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Center(
                child: isCompleted
                    ? Icon(
                        showFeedback
                            ? (isCorrect ? Icons.check : Icons.close)
                            : Icons.check,
                        color: Colors.white,
                        size: 20,
                      )
                    : Text(
                        '${step.order}',
                        style: AppTheme.labelMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textMedium,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),

            // Step Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          step.title,
                          style: AppTheme.labelLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration:
                                isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      if (!step.isRequired) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.textLight.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Optional',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textMedium,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    step.description,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.stars,
                        size: 14,
                        color: AppTheme.accentOrange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${step.points} pts',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.accentOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Exit Mission?'),
        content: const Text(
            'Your progress will be saved. Are you sure you want to exit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _saveProgressState();
              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorRed,
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}
