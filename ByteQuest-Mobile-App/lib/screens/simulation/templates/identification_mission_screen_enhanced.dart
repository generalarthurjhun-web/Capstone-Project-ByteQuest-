import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/mission_header.dart';
import '../../../core/widgets/instruction_card.dart';
import '../../../core/widgets/progress_indicator_card.dart';
import '../../../core/widgets/feedback_card.dart';
import '../../../models/mission_model.dart';
import '../../../data/mission_content_data.dart';
import '../../../data/mission_scenarios_data.dart';
import '../../../services/auth_service.dart';
import '../../../services/progress_resume_service.dart';
import '../../../services/authoritative_assessment_service.dart';
import '../legacy_practice_evidence_scope.dart';
import '../components/practice_mission_chrome.dart';
import '../practice_option_order.dart';
import '../result_screen.dart';

/// Enhanced Identification Mission Screen (Mission 1)
/// Professional UI matching reference design with:
/// - Enhanced header with notification and settings
/// - Step progress card with XP badge
/// - Instruction card with highlighted text
/// - 3-column responsive grid
/// - Progress indicator card
/// - Robot assistant feedback card
/// - Distraction-free full-screen simulation workspace
class IdentificationMissionScreenEnhanced extends StatefulWidget {
  final Mission mission;
  final List<MissionQuestion> questions;
  final List<HardwareItem>? hardwareItems;

  const IdentificationMissionScreenEnhanced({
    super.key,
    required this.mission,
    required this.questions,
    this.hardwareItems,
  });

  @override
  State<IdentificationMissionScreenEnhanced> createState() =>
      _IdentificationMissionScreenEnhancedState();
}

class _IdentificationMissionScreenEnhancedState
    extends State<IdentificationMissionScreenEnhanced> {
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

  // Feedback
  String? _feedbackMessage;
  String? _feedbackSubtitle;
  FeedbackType? _feedbackType;
  late PracticeOptionOrder _optionOrder;

  @override
  void initState() {
    super.initState();
    _optionOrder = PracticeOptionOrder.create(
      sourceOptions: _sourceOptions,
      seed: PracticeOptionOrder.stableSeed(
        '${widget.mission.id}:${AuthService().currentUserId ?? 'anonymous-practice'}',
      ),
    );
    _startTimer();
    _loadProgressState();
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

  bool get _isImageBasedMission =>
      widget.hardwareItems != null && widget.hardwareItems!.isNotEmpty;
  bool get _isCOC1M1 => widget.mission.id == 'coc1_m1';
  bool get _assessmentMode =>
      AuthoritativeAssessmentService.instance.isAssessmentMode;
  bool get _hasProgress =>
      _currentQuestionIndex > 0 ||
      _selectedAnswer != null ||
      _hasAnswered ||
      _correctAnswers > 0 ||
      _mistakes.isNotEmpty ||
      _hintsUsed > 0;
  Map<String, List<String>> get _sourceOptions => {
        for (final question in widget.questions)
          question.id: List<String>.from(question.options),
      };

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
        _optionOrder = PracticeOptionOrder.fromJson(
          data['optionOrder'] as Map<String, dynamic>?,
          sourceOptions: _sourceOptions,
          fallbackSeed: PracticeOptionOrder.stableSeed(widget.mission.id),
        );
      });
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
      'optionOrder': _optionOrder.toJson(),
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

  Future<void> _saveResultsToDatabase() async {
    final userId = AuthService().currentUserId;
    if (userId == null) return;
    await ProgressResumeService.clearState(
      userId: userId,
      missionId: widget.mission.id,
    );
  }

  void _selectAnswer(String answer) {
    if (_hasAnswered) return;

    setState(() {
      _selectedAnswer = answer;
      _showingHint = false;
    });
  }

  void _onCardTapped(String answer) {
    if (_hasAnswered) return;

    final question = widget.questions[_currentQuestionIndex];
    final isCorrect = answer == question.correctAnswer;
    unawaited(LegacyPracticeEvidenceScope.record(
      context,
      phaseId: 'question_${question.id}',
      actionType: 'answer_submitted',
      target: question.id,
      value: {'selected_answer': answer, 'local_mission_id': widget.mission.id},
    ));

    setState(() {
      _selectedAnswer = answer;
      _hasAnswered = true;
      _showingHint = false;

      if (isCorrect) {
        _score += question.points;
        _correctAnswers++;
        if (!_assessmentMode) {
          _feedbackMessage =
              'Great! You identified the ${question.correctAnswer}.';
          _feedbackSubtitle =
              question.explanation ?? 'Keep it up, ByteQuester!';
          _feedbackType = FeedbackType.success;
        }
      } else {
        _mistakes.add(
            'Q${_currentQuestionIndex + 1}: Selected "$answer" instead of "${question.correctAnswer}"');
        if (!_assessmentMode) {
          _feedbackMessage =
              'Incorrect. That\'s not the ${question.correctAnswer}.';
          _feedbackSubtitle =
              question.explanation ?? 'Review the item details and continue.';
          _feedbackType = FeedbackType.error;
        }
      }
    });

    _saveProgressState();
  }

  void _showHint() {
    if (_assessmentMode) return;
    if (_hintsRemaining <= 0 || _hasAnswered) {
      if (_hintsRemaining <= 0) {
        setState(() {
          _feedbackMessage = 'No hints remaining';
          _feedbackType = FeedbackType.warning;
        });

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _feedbackMessage = null;
              _feedbackType = null;
            });
          }
        });
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

  void _nextQuestion() {
    if (_currentQuestionIndex < widget.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = null;
        _hasAnswered = false;
        _showingHint = false;
        _currentHint = null;
        _feedbackMessage = null;
        _feedbackSubtitle = null;
        _feedbackType = null;
      });
      _saveProgressState();
    } else {
      _finishMission();
    }
  }

  void _finishMission() async {
    _timer?.cancel();

    await _saveResultsToDatabase();

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

    if (!mounted) return;

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
    final question = widget.questions[_currentQuestionIndex];
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;

    // Responsive grid column count
    int gridColumns = 3;
    if (screenWidth < 360) {
      gridColumns = 2;
    } else if (screenWidth > 600) {
      gridColumns = 4;
    }

    return PracticeMissionExitGuard(
      mission: widget.mission,
      hasProgress: () => _hasProgress,
      builder: (context, requestExit) => Scaffold(
        backgroundColor: AppTheme.backgroundOffWhite,
        body: SafeArea(
          child: Column(
            children: [
              // Mission Header
              MissionHeader(
                mission: widget.mission,
                subtitle: '',
                onBackPressed: requestExit,
              ),

              const SizedBox(height: 12),
              ProgressIndicatorCard(
                current: _correctAnswers,
                total: widget.questions.length,
                label: 'items identified',
                icon: Icons.fact_check_outlined,
              ),
              const SizedBox(height: 4),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // Instruction Card
                      InstructionCard(
                        instruction: _assessmentMode
                            ? question.question
                            : 'Tap the correct item: ${question.correctAnswer}',
                        highlightedText:
                            _assessmentMode ? null : question.correctAnswer,
                        icon: Icons.touch_app,
                      ),
                      const SizedBox(height: 16),

                      // Hint Button (COC1-M1 specific)
                      if (!_assessmentMode && _isCOC1M1 && !_hasAnswered) ...[
                        Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            child: OutlinedButton.icon(
                              onPressed: _hintsRemaining > 0 ? _showHint : null,
                              icon: Icon(
                                Icons.lightbulb_outline,
                                size: 18,
                                color: _hintsRemaining > 0
                                    ? AppTheme.accentOrange
                                    : AppTheme.textLight,
                              ),
                              label: Text(
                                'Use Hint ($_hintsRemaining remaining)',
                                style: TextStyle(
                                  color: _hintsRemaining > 0
                                      ? AppTheme.accentOrange
                                      : AppTheme.textLight,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: _hintsRemaining > 0
                                      ? AppTheme.accentOrange
                                      : AppTheme.textLight,
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Hint Display
                      if (!_assessmentMode &&
                          _showingHint &&
                          _currentHint != null) ...[
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.accentOrange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  AppTheme.accentOrange.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
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
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.accentOrange,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _currentHint!,
                                      style: AppTheme.bodyMedium.copyWith(
                                        color: AppTheme.textDark,
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

                      // Hardware Items Grid
                      if (_isImageBasedMission)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildImageBasedGrid(question, gridColumns),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildTextBasedOptions(question),
                        ),
                      const SizedBox(height: 16),

                      // Feedback Card
                      if (!_assessmentMode &&
                          _feedbackMessage != null &&
                          _feedbackType != null) ...[
                        FeedbackCard(
                          message: _feedbackMessage!,
                          subtitle: _feedbackSubtitle,
                          type: _feedbackType!,
                          showRobot: true,
                          dismissible: false,
                        ),
                      ],
                      if (_hasAnswered) ...[
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: FilledButton.icon(
                            onPressed: _nextQuestion,
                            icon: const Icon(Icons.arrow_forward_rounded),
                            label: const Text(MissionContentData.continueLabel),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageBasedGrid(MissionQuestion question, int gridColumns) {
    final List<HardwareItem> displayItems;
    if (_isCOC1M1) {
      displayItems = widget.hardwareItems!;
    } else {
      displayItems = widget.hardwareItems!.where((item) {
        return question.options.contains(item.name);
      }).toList()
        ..sort((left, right) => _optionOrder
            .optionsFor(question.id, question.options)
            .indexOf(left.name)
            .compareTo(_optionOrder
                .optionsFor(question.id, question.options)
                .indexOf(right.name)));
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridColumns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: _isCOC1M1 ? 1.0 : 0.82,
      ),
      itemCount: displayItems.length,
      itemBuilder: (context, index) {
        final item = displayItems[index];
        return _buildHardwareCard(item, question);
      },
    );
  }

  Widget _buildHardwareCard(HardwareItem item, MissionQuestion question) {
    final isSelected = _selectedAnswer == item.name;
    final isCorrect = item.name == question.correctAnswer;

    Color borderColor;
    Color backgroundColor;
    Widget? statusWidget;

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
        statusWidget = Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: AppTheme.accentGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 16,
            ),
          ),
        );
      } else if (isSelected && !isCorrect) {
        borderColor = AppTheme.errorRed;
        backgroundColor = AppTheme.errorRed.withValues(alpha: 0.1);
        statusWidget = Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: AppTheme.errorRed,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.close,
              color: Colors.white,
              size: 16,
            ),
          ),
        );
      } else {
        borderColor = AppTheme.textLight.withValues(alpha: 0.2);
        backgroundColor = Colors.white;
      }
    }

    return InkWell(
      onTap: _hasAnswered ? null : () => _onCardTapped(item.name),
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
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: item.id == 'not_sure'
                        ? Center(
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundOffWhite,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color:
                                      AppTheme.textLight.withValues(alpha: 0.3),
                                  width: 1.5,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '?',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textLight
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Image.asset(
                            item.imagePath,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.broken_image,
                                size: 32,
                                color: AppTheme.textLight,
                              );
                            },
                          ),
                  ),
                ),
                if (!_isCOC1M1)
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Text(
                      item.name,
                      style: AppTheme.labelSmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
            if (!_assessmentMode && statusWidget != null) statusWidget,
          ],
        ),
      ),
    );
  }

  Widget _buildTextBasedOptions(MissionQuestion question) {
    return Column(
      children:
          _optionOrder.optionsFor(question.id, question.options).map((option) {
        final isSelected = _selectedAnswer == option;
        final isCorrect = option == question.correctAnswer;
        final showFeedback = _hasAnswered && !_assessmentMode;

        Color backgroundColor;
        Color borderColor;
        IconData? icon;
        Color? iconColor;

        if (!showFeedback) {
          backgroundColor = isSelected
              ? AppTheme.primaryBlue.withValues(alpha: 0.05)
              : Colors.white;
          borderColor = isSelected
              ? AppTheme.primaryBlue
              : AppTheme.textLight.withValues(alpha: 0.2);
        } else {
          if (isCorrect) {
            backgroundColor = AppTheme.accentGreen.withValues(alpha: 0.1);
            borderColor = AppTheme.accentGreen;
            icon = Icons.check_circle;
            iconColor = AppTheme.accentGreen;
          } else if (isSelected) {
            backgroundColor = AppTheme.errorRed.withValues(alpha: 0.1);
            borderColor = AppTheme.errorRed;
            icon = Icons.cancel;
            iconColor = AppTheme.errorRed;
          } else {
            backgroundColor = Colors.white;
            borderColor = AppTheme.textLight.withValues(alpha: 0.2);
          }
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: _hasAnswered ? null : () => _selectAnswer(option),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: backgroundColor,
                border: Border.all(color: borderColor, width: 2),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option,
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textDark,
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
}
