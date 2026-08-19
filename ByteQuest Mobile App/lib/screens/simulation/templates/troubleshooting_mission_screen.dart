import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/soft_card.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/simulation_fullscreen_button.dart';
import '../../../models/mission_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/progress_resume_service.dart';
import '../../../services/authoritative_assessment_service.dart';
import '../result_screen.dart';

/// Template 5: Troubleshooting Mission Screen
/// Used for: COC3-M5, COC4-M3, COC4-M4, COC4-M5
class TroubleshootingMissionScreen extends StatefulWidget {
  final Mission mission;
  final List<Map<String, dynamic>> scenarios;

  const TroubleshootingMissionScreen({
    super.key,
    required this.mission,
    required this.scenarios,
  });

  @override
  State<TroubleshootingMissionScreen> createState() =>
      _TroubleshootingMissionScreenState();
}

class _TroubleshootingMissionScreenState
    extends State<TroubleshootingMissionScreen> {
  bool get _assessmentMode =>
      AuthoritativeAssessmentService.instance.isAssessmentMode;
  int _currentScenarioIndex = 0;
  int _score = 0;
  int _correctAnswers = 0;
  List<String> _mistakes = [];
  String? _selectedCause;
  bool _hasAnswered = false;
  int _timeSpent = 0;
  Timer? _timer;

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
        _currentScenarioIndex = data['currentScenarioIndex'] ?? 0;
        _score = data['score'] ?? 0;
        _correctAnswers = data['correctAnswers'] ?? 0;
        _mistakes = List<String>.from(data['mistakes'] ?? []);
        _timeSpent = data['timeSpent'] ?? 0;
      });
      debugPrint('Loaded state for troubleshooting.');
    }
  }

  Future<void> _saveProgressState() async {
    final userId = AuthService().currentUserId;
    if (userId == null) return;

    final stateData = {
      'currentScenarioIndex': _currentScenarioIndex,
      'score': _score,
      'correctAnswers': _correctAnswers,
      'mistakes': _mistakes,
      'timeSpent': _timeSpent,
    };

    await ProgressResumeService.saveState(
      userId: userId,
      missionId: widget.mission.id,
      cocId: widget.mission.cocId,
      currentStep: _currentScenarioIndex + 1,
      totalSteps: widget.scenarios.length,
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

  void _selectCause(String cause) {
    if (_hasAnswered) return;

    setState(() {
      _selectedCause = cause;
    });
  }

  void _submitDiagnosis() {
    if (_selectedCause == null || _hasAnswered) return;

    final scenario = widget.scenarios[_currentScenarioIndex];
    final isCorrect = _selectedCause == scenario['correctCause'];
    unawaited(AuthoritativeAssessmentService.instance.safeRecordAction(
      actionType: 'diagnosis_submitted',
      target: 'scenario_${_currentScenarioIndex + 1}',
      value: {
        'selected_cause': _selectedCause,
        'local_mission_id': widget.mission.id,
      },
    ));

    setState(() {
      _hasAnswered = true;

      if (isCorrect) {
        final points = scenario['points'] as int? ?? 10;
        _score += points;
        _correctAnswers++;
      } else {
        _mistakes.add(
            'Scenario ${_currentScenarioIndex + 1}: Selected "$_selectedCause" instead of "${scenario['correctCause']}"');
      }
    });

    _saveProgressState();

    // Auto-advance after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _nextScenario();
      }
    });
  }

  void _nextScenario() {
    if (_currentScenarioIndex < widget.scenarios.length - 1) {
      setState(() {
        _currentScenarioIndex++;
        _selectedCause = null;
        _hasAnswered = false;
      });
      _saveProgressState();
    } else {
      _finishMission();
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

    final totalPoints = widget.scenarios
        .fold<int>(0, (sum, s) => sum + (s['points'] as int? ?? 10));
    final finalScore = ((_score / totalPoints) * 100).toInt();
    final accuracy =
        ((_correctAnswers / widget.scenarios.length) * 100).toInt();
    final result = MissionResult(
      missionId: widget.mission.id,
      score: finalScore,
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

  Color _getCauseColor(String cause) {
    if (!_hasAnswered || _assessmentMode) {
      return _selectedCause == cause
          ? AppTheme.primaryBlue.withValues(alpha: 0.1)
          : Colors.transparent;
    }

    final scenario = widget.scenarios[_currentScenarioIndex];
    if (cause == scenario['correctCause']) {
      return AppTheme.accentGreen.withValues(alpha: 0.1);
    } else if (cause == _selectedCause) {
      return AppTheme.errorRed.withValues(alpha: 0.1);
    }
    return Colors.transparent;
  }

  IconData? _getCauseIcon(String cause) {
    if (!_hasAnswered || _assessmentMode) return null;

    final scenario = widget.scenarios[_currentScenarioIndex];
    if (cause == scenario['correctCause']) {
      return Icons.check_circle;
    } else if (cause == _selectedCause) {
      return Icons.cancel;
    }
    return null;
  }

  Color? _getCauseIconColor(String cause) {
    if (!_hasAnswered || _assessmentMode) return null;

    final scenario = widget.scenarios[_currentScenarioIndex];
    if (cause == scenario['correctCause']) {
      return AppTheme.accentGreen;
    } else if (cause == _selectedCause) {
      return AppTheme.errorRed;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scenario = widget.scenarios[_currentScenarioIndex];
    final progress = (_currentScenarioIndex + 1) / widget.scenarios.length;
    final causes = scenario['causes'] as List<String>;

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

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Scenario Header
                    SoftCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.errorRed.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Scenario ${_currentScenarioIndex + 1}/${widget.scenarios.length}',
                                  style: AppTheme.labelSmall.copyWith(
                                    color: AppTheme.errorRed,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.stars,
                                    size: 16,
                                    color: AppTheme.accentOrange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${scenario['points'] ?? 10} pts',
                                    style: AppTheme.labelSmall.copyWith(
                                      color: AppTheme.accentOrange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: AppTheme.errorRed,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Problem Symptom',
                                style: AppTheme.labelMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.errorRed,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            scenario['symptom'] as String,
                            style: AppTheme.headlineMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Question
                    Text(
                      'What is the most likely cause?',
                      style: AppTheme.headlineSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Possible Causes
                    ...causes.map((cause) {
                      final icon = _getCauseIcon(cause);
                      final iconColor = _getCauseIconColor(cause);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => _selectCause(cause),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: _getCauseColor(cause),
                              border: Border.all(
                                color: _selectedCause == cause
                                    ? AppTheme.primaryBlue
                                    : AppTheme.textLight.withValues(alpha: 0.2),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    cause,
                                    style: AppTheme.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (icon != null) ...[
                                  const SizedBox(width: 12),
                                  Icon(icon, color: iconColor, size: 24),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    // Explanation (shown after answering)
                    if (!_assessmentMode && _hasAnswered) ...[
                      const SizedBox(height: 24),
                      SoftCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color:
                                      _selectedCause == scenario['correctCause']
                                          ? AppTheme.accentGreen
                                          : AppTheme.errorRed,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _selectedCause == scenario['correctCause']
                                      ? 'Correct Diagnosis!'
                                      : 'Incorrect Diagnosis',
                                  style: AppTheme.labelMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: _selectedCause ==
                                            scenario['correctCause']
                                        ? AppTheme.accentGreen
                                        : AppTheme.errorRed,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Correct Cause: ${scenario['correctCause']}',
                              style: AppTheme.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (scenario['explanation'] != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                scenario['explanation'] as String,
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppTheme.textMedium,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Submit/Next Button
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
                child: AppButton.primary(
                  label: _hasAnswered
                      ? (_currentScenarioIndex < widget.scenarios.length - 1
                          ? 'Next Scenario'
                          : 'View Results')
                      : 'Submit Diagnosis',
                  icon: _hasAnswered ? Icons.arrow_forward : Icons.check,
                  onPressed: _selectedCause == null
                      ? () {}
                      : (_hasAnswered ? _nextScenario : _submitDiagnosis),
                  width: double.infinity,
                ),
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
