import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/soft_card.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/simulation_fullscreen_button.dart';
import '../../../models/mission_model.dart';
import '../../../data/mission_content_data.dart';
import '../../../data/mission_scenarios_data.dart';
import '../../../services/auth_service.dart';
import '../../../services/progress_resume_service.dart';
import '../../../services/authoritative_assessment_service.dart';
import '../result_screen.dart';

/// Template 1: Identification Mission Screen
/// Used for: COC1-M1, COC2-M1, COC3-M1, COC4-M1
/// Supports both text-based and image-based identification
/// COC1-M1 has special features: image-only display + 3-hint system
class IdentificationMissionScreen extends StatefulWidget {
  final Mission mission;
  final List<MissionQuestion> questions;
  final List<HardwareItem>?
      hardwareItems; // Optional: for image-based identification

  const IdentificationMissionScreen({
    super.key,
    required this.mission,
    required this.questions,
    this.hardwareItems,
  });

  @override
  State<IdentificationMissionScreen> createState() =>
      _IdentificationMissionScreenState();
}

class _IdentificationMissionScreenState
    extends State<IdentificationMissionScreen> {
  int _currentQuestionIndex = 0;
  int _score = 0;
  int _correctAnswers = 0;
  List<String> _mistakes = [];
  String? _selectedAnswer;
  bool _hasAnswered = false;
  int _timeSpent = 0;
  Timer? _timer;

  // COC1-M1 Specific: Hint System
  int _hintsRemaining = 3;
  bool _showingHint = false;
  String? _currentHint;
  int _hintsUsed = 0;

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
        _currentQuestionIndex = data['currentQuestionIndex'] ?? 0;
        _score = data['score'] ?? 0;
        _correctAnswers = data['correctAnswers'] ?? 0;
        _mistakes = List<String>.from(data['mistakes'] ?? []);
        _hintsRemaining = data['hintsRemaining'] ?? 3;
        _hintsUsed = data['hintsUsed'] ?? 0;
        _timeSpent = data['timeSpent'] ?? 0;
      });
      debugPrint(
          'Loaded state. Starting at question index: $_currentQuestionIndex');
    }
  }

  Future<void> _saveProgressState() async {
    final userId = AuthService().currentUserId;
    if (userId == null) return;

    final stateData = {
      'currentQuestionIndex': _currentQuestionIndex,
      'score': _score,
      'correctAnswers': _correctAnswers,
      'mistakes': _mistakes,
      'hintsRemaining': _hintsRemaining,
      'hintsUsed': _hintsUsed,
      'timeSpent': _timeSpent,
    };

    await ProgressResumeService.saveState(
      userId: userId,
      missionId: widget.mission.id,
      cocId: widget.mission.cocId,
      currentStep: _currentQuestionIndex + 1,
      totalSteps: widget.questions.length,
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
      setState(() {
        _timeSpent++;
      });
    });
  }

  bool get _isImageBasedMission =>
      widget.hardwareItems != null && widget.hardwareItems!.isNotEmpty;
  bool get _isCOC1M1 => widget.mission.id == 'coc1_m1';
  bool get _assessmentMode =>
      AuthoritativeAssessmentService.instance.isAssessmentMode;

  void _selectAnswer(String answer) {
    if (_hasAnswered) return;

    setState(() {
      _selectedAnswer = answer;
      _showingHint = false; // Hide hint when answer is selected
    });
  }

  void _showHint() {
    if (_assessmentMode) return;
    if (_hintsRemaining <= 0 || _hasAnswered) {
      if (_hintsRemaining <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 12),
                Text('No hints remaining'),
              ],
            ),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
      return;
    }

    final question = widget.questions[_currentQuestionIndex];
    final correctItem = widget.hardwareItems?.firstWhere(
      (item) => item.name == question.correctAnswer,
      orElse: () => widget.hardwareItems!.first,
    );

    if (correctItem != null) {
      final hint = MissionScenariosData.getHintForItem(correctItem.id);

      setState(() {
        _hintsRemaining--;
        _hintsUsed++;
        _currentHint = hint ?? 'No hint available for this item.';
        _showingHint = true;
      });
    }
  }

  void _submitAnswer() {
    if (_selectedAnswer == null || _hasAnswered) return;

    final question = widget.questions[_currentQuestionIndex];
    final isCorrect = _selectedAnswer == question.correctAnswer;
    unawaited(AuthoritativeAssessmentService.instance.safeRecordAction(
      actionType: 'answer_submitted',
      target: question.id,
      value: {
        'selected_answer': _selectedAnswer,
        'local_mission_id': widget.mission.id
      },
    ));

    setState(() {
      _hasAnswered = true;
      _showingHint = false;

      if (isCorrect) {
        _score += question.points;
        _correctAnswers++;
      } else {
        _mistakes.add(
            'Q${_currentQuestionIndex + 1}: Selected "$_selectedAnswer" instead of "${question.correctAnswer}"');
      }
    });

    _saveProgressState();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _nextQuestion();
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < widget.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = null;
        _hasAnswered = false;
        _showingHint = false;
        _currentHint = null;
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

    final accuracy = widget.questions.isEmpty
        ? 0
        : ((_correctAnswers / widget.questions.length) * 100).toInt();

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

  Color _getAnswerColor(String option) {
    if (!_hasAnswered || _assessmentMode) {
      return _selectedAnswer == option
          ? AppTheme.primaryBlue.withValues(alpha: 0.1)
          : Colors.transparent;
    }

    final question = widget.questions[_currentQuestionIndex];
    if (option == question.correctAnswer) {
      return AppTheme.accentGreen.withValues(alpha: 0.1);
    } else if (option == _selectedAnswer) {
      return AppTheme.errorRed.withValues(alpha: 0.1);
    }
    return Colors.transparent;
  }

  IconData? _getAnswerIcon(String option) {
    if (!_hasAnswered || _assessmentMode) return null;

    final question = widget.questions[_currentQuestionIndex];
    if (option == question.correctAnswer) {
      return Icons.check_circle;
    } else if (option == _selectedAnswer) {
      return Icons.cancel;
    }
    return null;
  }

  Color? _getAnswerIconColor(String option) {
    if (!_hasAnswered || _assessmentMode) return null;

    final question = widget.questions[_currentQuestionIndex];
    if (option == question.correctAnswer) {
      return AppTheme.accentGreen;
    } else if (option == _selectedAnswer) {
      return AppTheme.errorRed;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / widget.questions.length;

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
          if (_isCOC1M1) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _hintsRemaining > 0
                        ? AppTheme.accentOrange.withValues(alpha: 0.1)
                        : AppTheme.textLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _hintsRemaining > 0
                          ? AppTheme.accentOrange.withValues(alpha: 0.3)
                          : AppTheme.textLight.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: _hintsRemaining > 0
                            ? AppTheme.accentOrange
                            : AppTheme.textLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Hints: $_hintsRemaining',
                        style: AppTheme.labelSmall.copyWith(
                          color: _hintsRemaining > 0
                              ? AppTheme.accentOrange
                              : AppTheme.textLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_formatTime(_timeSpent)}',
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
                                  color: AppTheme.primaryBlue
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Question ${_currentQuestionIndex + 1}/${widget.questions.length}',
                                  style: AppTheme.labelSmall.copyWith(
                                    color: AppTheme.primaryBlue,
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
                                    '${question.points} pts',
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
                          Text(
                            question.question,
                            style: AppTheme.headlineMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!_assessmentMode && _isCOC1M1 && !_hasAnswered) ...[
                      Center(
                        child: AppButton.outline(
                          label: 'Use Hint',
                          icon: Icons.lightbulb_outline,
                          onPressed: _hintsRemaining > 0 ? _showHint : () {},
                          width: 200,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (!_assessmentMode &&
                        _showingHint &&
                        _currentHint != null) ...[
                      SoftCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.accentOrange
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.lightbulb,
                                color: AppTheme.accentOrange,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hint',
                                    style: AppTheme.labelMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.accentOrange,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _currentHint!,
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: AppTheme.textMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_isImageBasedMission)
                      _buildImageBasedOptions()
                    else
                      _buildTextBasedOptions(),
                    if (!_assessmentMode &&
                        _hasAnswered &&
                        question.explanation != null) ...[
                      const SizedBox(height: 24),
                      SoftCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppTheme.primaryBlue,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Explanation',
                                    style: AppTheme.labelMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryBlue,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    question.explanation!,
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: AppTheme.textMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
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
                      ? (_currentQuestionIndex < widget.questions.length - 1
                          ? 'Next Question'
                          : 'View Results')
                      : 'Submit Answer',
                  icon: _hasAnswered ? Icons.arrow_forward : Icons.check,
                  onPressed: _selectedAnswer == null
                      ? () {}
                      : (_hasAnswered ? _nextQuestion : _submitAnswer),
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

  Widget _buildTextBasedOptions() {
    final question = widget.questions[_currentQuestionIndex];
    return Column(
      children: question.options.map((option) {
        final icon = _getAnswerIcon(option);
        final iconColor = _getAnswerIconColor(option);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _selectAnswer(option),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _getAnswerColor(option),
                border: Border.all(
                  color: _selectedAnswer == option
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
                      option,
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
      }).toList(),
    );
  }

  Widget _buildImageBasedOptions() {
    final question = widget.questions[_currentQuestionIndex];

    final filteredItems = widget.hardwareItems!.where((item) {
      return question.options.contains(item.name);
    }).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return _buildHardwareCard(item);
      },
    );
  }

  Widget _buildHardwareCard(HardwareItem item) {
    final isSelected = _selectedAnswer == item.name;
    final question = widget.questions[_currentQuestionIndex];
    final isCorrect = item.name == question.correctAnswer;

    Color borderColor;
    Color backgroundColor;
    IconData? statusIcon;
    Color? statusIconColor;

    if (!_hasAnswered || _assessmentMode) {
      borderColor = isSelected
          ? AppTheme.primaryBlue
          : AppTheme.textLight.withValues(alpha: 0.2);
      backgroundColor = isSelected
          ? AppTheme.primaryBlue.withValues(alpha: 0.05)
          : Colors.white;
    } else {
      if (isCorrect) {
        borderColor = AppTheme.accentGreen;
        backgroundColor = AppTheme.accentGreen.withValues(alpha: 0.1);
        statusIcon = Icons.check_circle;
        statusIconColor = AppTheme.accentGreen;
      } else if (isSelected && !isCorrect) {
        borderColor = AppTheme.errorRed;
        backgroundColor = AppTheme.errorRed.withValues(alpha: 0.1);
        statusIcon = Icons.cancel;
        statusIconColor = AppTheme.errorRed;
      } else {
        borderColor = AppTheme.textLight.withValues(alpha: 0.2);
        backgroundColor = Colors.white;
      }
    }

    return InkWell(
      onTap: _hasAnswered ? null : () => _selectAnswer(item.name),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(
            color: borderColor,
            width: isSelected || (isCorrect && _hasAnswered && !_assessmentMode)
                ? 2
                : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_assessmentMode && _hasAnswered && statusIcon != null) ...[
              Icon(
                statusIcon,
                color: statusIconColor,
                size: 32,
              ),
              const SizedBox(height: 8),
            ],
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Image.asset(
                  item.imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          size: 48,
                          color: AppTheme.textLight,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Image\nnot found',
                          style: AppTheme.captionSmall.copyWith(
                            color: AppTheme.textLight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            if (!_isCOC1M1 || _hasAnswered) ...[
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Text(
                  item.name,
                  style: AppTheme.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Exit Mission?'),
        content: const Text(
            'Your progress will not be saved. Are you sure you want to exit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
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
