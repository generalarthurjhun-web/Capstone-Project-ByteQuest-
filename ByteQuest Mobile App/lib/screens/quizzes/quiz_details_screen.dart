import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/learner_ui.dart';
import '../../models/learner_quiz_model.dart';
import '../../services/learner_quiz_service.dart';
import 'quiz_taking_screen.dart';

class QuizDetailsScreen extends StatefulWidget {
  const QuizDetailsScreen({super.key, required this.quiz});
  final LearnerQuizSummary quiz;

  @override
  State<QuizDetailsScreen> createState() => _QuizDetailsScreenState();
}

class _QuizDetailsScreenState extends State<QuizDetailsScreen> {
  final _service = LearnerQuizService();
  bool _starting = false;

  @override
  Widget build(BuildContext context) {
    final quiz = widget.quiz;
    return Scaffold(
      backgroundColor: AppTheme.backgroundOffWhite,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          children: [
            LearnerPageHeader(
              title: 'Quiz briefing',
              subtitle: quiz.classTitle,
              padding: EdgeInsets.zero,
              trailing: IconButton.filledTonal(
                onPressed: () => Navigator.pop(context),
                tooltip: 'Close quiz briefing',
                icon: const Icon(Icons.close_rounded),
              ),
            ),
            const SizedBox(height: 18),
            LearnerSurface(
              elevated: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.softBlueAccent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.quiz_outlined,
                        color: AppTheme.primaryBlue),
                  ),
                  const SizedBox(height: 16),
                  Text(quiz.title, style: AppTheme.headlineLarge),
                  const SizedBox(height: 6),
                  Text(quiz.description ?? quiz.topic,
                      style: AppTheme.bodyMedium),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      _Fact(
                        icon: Icons.format_list_numbered_rounded,
                        label: '${quiz.questionCount} questions',
                      ),
                      if (quiz.cocCode != null)
                        _Fact(
                          icon: Icons.route_outlined,
                          label: quiz.cocCode!.toUpperCase(),
                        ),
                      if (quiz.dueAt != null)
                        _Fact(
                          icon: Icons.event_outlined,
                          label:
                              'Due ${DateFormat.MMMd().add_jm().format(quiz.dueAt!.toLocal())}',
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (quiz.instructions?.isNotEmpty ?? false) ...[
              const SizedBox(height: 20),
              const LearnerSectionHeader(title: 'Instructions'),
              const SizedBox(height: 10),
              LearnerSurface(
                child: Text(quiz.instructions!, style: AppTheme.bodyMedium),
              ),
            ],
            const SizedBox(height: 20),
            LearnerSurface(
              color: AppTheme.backgroundPaleBlue,
              child: Text(
                'Your answers are saved as you continue. The database evaluates the published answer contract only after you confirm submission. Quiz results never change competency status.',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.deepBlue),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: !quiz.isAvailable || _starting ? null : _start,
              icon: _starting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(quiz.state == LearnerQuizState.inProgress
                      ? Icons.play_arrow_rounded
                      : Icons.rocket_launch_outlined),
              label: Text(_starting
                  ? 'Opening quiz…'
                  : quiz.state == LearnerQuizState.inProgress
                      ? 'Continue quiz'
                      : quiz.isAvailable
                          ? 'Start quiz'
                          : 'Quiz unavailable'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _start() async {
    setState(() => _starting = true);
    try {
      final attempt = await _service.startOrResume(widget.quiz.assignmentId);
      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => QuizTakingScreen(attempt: attempt),
        ),
      );
    } catch (error) {
      debugPrint('Quiz start failed: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'This quiz could not be opened. Check its availability and try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceMuted,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: AppTheme.textMedium),
            const SizedBox(width: 6),
            Text(label, style: AppTheme.labelMedium),
          ],
        ),
      );
}
