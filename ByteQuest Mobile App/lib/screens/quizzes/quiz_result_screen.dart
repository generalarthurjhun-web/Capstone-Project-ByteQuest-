import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/learner_ui.dart';
import '../../models/learner_quiz_model.dart';
import '../../services/learner_quiz_service.dart';
import '../../services/learner_realtime_coordinator.dart';

class QuizResultScreen extends StatefulWidget {
  const QuizResultScreen({
    super.key,
    required this.attemptId,
    this.initialResult,
  });

  final String attemptId;
  final LearnerQuizResult? initialResult;

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen>
    with LearnerRealtimeRefreshMixin<QuizResultScreen> {
  final _service = LearnerQuizService();
  LearnerQuizResult? _result;
  String? _error;

  @override
  Set<LearnerRealtimeDomain> get realtimeDomains => const {
        LearnerRealtimeDomain.quizzes,
      };

  @override
  Future<void> refreshFromRealtime() => _load();

  @override
  void initState() {
    super.initState();
    _result = widget.initialResult;
    if (_result == null) _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final result = await _service.getResult(widget.attemptId);
      if (mounted) setState(() => _result = result);
    } catch (error) {
      debugPrint('Quiz result load failed: $error');
      if (mounted) {
        setState(() => _error = 'This quiz result is not available right now.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_result == null && _error == null) {
      return const Scaffold(
        body: SafeArea(child: LearnerLoadingView(label: 'Loading quiz result')),
      );
    }
    if (_result == null) {
      return Scaffold(
        body: SafeArea(
          child: LearnerStateView(
            icon: Icons.schedule_rounded,
            title: 'Result unavailable',
            message: _error!,
            actionLabel: 'Try again',
            onAction: _load,
          ),
        ),
      );
    }

    final result = _result!;
    return Scaffold(
      backgroundColor: AppTheme.backgroundOffWhite,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          children: [
            LearnerPageHeader(
              title: 'Quiz result',
              subtitle: result.classTitle,
              padding: EdgeInsets.zero,
              trailing: IconButton.filledTonal(
                onPressed: () => Navigator.pop(context),
                tooltip: 'Close quiz result',
                icon: const Icon(Icons.close_rounded),
              ),
            ),
            const SizedBox(height: 18),
            Semantics(
              container: true,
              label:
                  '${result.title}. ${result.correctCount} correct out of ${result.questionCount}. Supplementary quiz result.',
              child: LearnerSurface(
                elevated: true,
                color: AppTheme.deepBlue,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COMPLETED',
                      style: AppTheme.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      result.title,
                      style:
                          AppTheme.headlineLarge.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '${result.correctCount} / ${result.questionCount}',
                      style:
                          AppTheme.displaySmall.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'questions answered correctly',
                      style: AppTheme.bodyMedium.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Completed ${DateFormat.MMMd().add_jm().format(result.completedAt.toLocal())}',
                      style: AppTheme.labelMedium.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            LearnerSurface(
              color: AppTheme.backgroundPaleBlue,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.verified_user_outlined,
                      color: AppTheme.primaryBlue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This is a supplementary quiz result. It does not determine TESDA competency or replace an Instructor-released practical assessment.',
                      style:
                          AppTheme.bodySmall.copyWith(color: AppTheme.deepBlue),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const LearnerSectionHeader(
              title: 'Question feedback',
              supportingText:
                  'Your answer is shown without exposing answer keys.',
            ),
            const SizedBox(height: 10),
            ...result.items.map(_buildItem),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(LearnerQuizItemResult item) {
    final color = item.isCorrect ? AppTheme.accentGreen : AppTheme.accentOrange;
    final label = item.isCorrect ? 'Correct' : 'Needs review';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: LearnerSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  item.isCorrect
                      ? Icons.check_circle_outline_rounded
                      : Icons.info_outline_rounded,
                  color: color,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(item.prompt, style: AppTheme.titleMedium)),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: AppTheme.labelMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Your answer', style: AppTheme.labelMedium),
            const SizedBox(height: 3),
            Text(item.learnerAnswer, style: AppTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
