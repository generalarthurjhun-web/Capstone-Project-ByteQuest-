import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/learner_ui.dart';
import '../../models/learner_quiz_model.dart';
import '../../services/learner_quiz_service.dart';
import '../../services/learner_realtime_coordinator.dart';
import 'quiz_details_screen.dart';
import 'quiz_result_screen.dart';

class LearnerQuizzesScreen extends StatefulWidget {
  const LearnerQuizzesScreen({super.key});

  @override
  State<LearnerQuizzesScreen> createState() => _LearnerQuizzesScreenState();
}

class _LearnerQuizzesScreenState extends State<LearnerQuizzesScreen>
    with LearnerRealtimeRefreshMixin<LearnerQuizzesScreen> {
  final _service = LearnerQuizService();
  List<LearnerQuizSummary> _quizzes = const [];
  bool _loading = true;
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
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final quizzes = await _service.getAvailableQuizzes();
      if (!mounted) return;
      setState(() {
        _quizzes = quizzes;
        _loading = false;
      });
    } catch (error) {
      debugPrint('Learner quiz list failed: $error');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Your assigned quizzes could not be loaded.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppTheme.backgroundOffWhite,
        body: SafeArea(
          child: _loading
              ? const LearnerLoadingView(label: 'Loading assigned quizzes')
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                    children: [
                      LearnerPageHeader(
                        title: 'Quizzes',
                        subtitle:
                            'Supplementary checks assigned by your Instructor',
                        padding: EdgeInsets.zero,
                        trailing: IconButton.filledTonal(
                          onPressed: () => Navigator.pop(context),
                          tooltip: 'Close quizzes',
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ),
                      const SizedBox(height: 14),
                      LearnerSurface(
                        color: AppTheme.backgroundPaleBlue,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                color: AppTheme.primaryBlue),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Quiz results support learning only. They do not determine TESDA competency or replace Instructor-reviewed practical assessment.',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.deepBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (_error != null)
                        LearnerStateView(
                          icon: Icons.cloud_off_outlined,
                          title: 'Quizzes unavailable',
                          message:
                              '${_error!} Check your connection and try again.',
                          actionLabel: 'Try again',
                          onAction: _load,
                        )
                      else if (_quizzes.isEmpty)
                        const LearnerStateView(
                          icon: Icons.quiz_outlined,
                          title: 'No quizzes assigned',
                          message:
                              'Published quizzes assigned through your active classes will appear here.',
                        )
                      else
                        ..._quizzes.map(_buildQuizCard),
                    ],
                  ),
                ),
        ),
      );

  Widget _buildQuizCard(LearnerQuizSummary quiz) {
    final state = quiz.state;
    final color = _stateColor(state);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: LearnerSurface(
        onTap: () => _open(quiz),
        semanticLabel:
            '${quiz.title}. ${_stateLabel(state)}. ${quiz.questionCount} questions.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.quiz_outlined, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(quiz.title, style: AppTheme.titleMedium),
                      const SizedBox(height: 3),
                      Text('${quiz.classTitle} · ${quiz.topic}',
                          style: AppTheme.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _QuizStatus(label: _stateLabel(state), color: color),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.format_list_numbered_rounded,
                    size: 17, color: AppTheme.textMedium),
                const SizedBox(width: 5),
                Text('${quiz.questionCount} questions',
                    style: AppTheme.labelMedium),
                if (quiz.dueAt != null) ...[
                  const SizedBox(width: 16),
                  const Icon(Icons.event_outlined,
                      size: 17, color: AppTheme.textMedium),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'Due ${DateFormat.MMMd().add_jm().format(quiz.dueAt!.toLocal())}',
                      style: AppTheme.labelMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            if (state == LearnerQuizState.inProgress) ...[
              const SizedBox(height: 12),
              LearnerProgressBar(
                value: quiz.questionCount == 0
                    ? 0
                    : quiz.answeredCount / quiz.questionCount,
                semanticLabel: 'Quiz answer progress',
              ),
              const SizedBox(height: 6),
              Text('${quiz.answeredCount} of ${quiz.questionCount} answered',
                  style: AppTheme.labelSmall),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _open(LearnerQuizSummary quiz) async {
    if (quiz.state == LearnerQuizState.completed && quiz.attemptId != null) {
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => QuizResultScreen(attemptId: quiz.attemptId!),
        ),
      );
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => QuizDetailsScreen(quiz: quiz)),
      );
    }
    if (mounted) await _load();
  }

  String _stateLabel(LearnerQuizState state) => switch (state) {
        LearnerQuizState.available => 'Available',
        LearnerQuizState.inProgress => 'In progress',
        LearnerQuizState.submitted => 'Awaiting result',
        LearnerQuizState.completed => 'Completed',
        LearnerQuizState.unavailable => 'Unavailable',
      };

  Color _stateColor(LearnerQuizState state) => switch (state) {
        LearnerQuizState.available => AppTheme.primaryBlue,
        LearnerQuizState.inProgress => AppTheme.accentOrange,
        LearnerQuizState.submitted => AppTheme.accentPurple,
        LearnerQuizState.completed => AppTheme.accentGreen,
        LearnerQuizState.unavailable => AppTheme.textMedium,
      };
}

class _QuizStatus extends StatelessWidget {
  const _QuizStatus({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: AppTheme.labelSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}
