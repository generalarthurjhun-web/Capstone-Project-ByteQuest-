import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/learner_ui.dart';
import '../../models/learner_quiz_model.dart';
import '../../services/learner_quiz_service.dart';
import 'quiz_result_screen.dart';

class QuizTakingScreen extends StatefulWidget {
  const QuizTakingScreen({super.key, required this.attempt});

  final LearnerQuizAttempt attempt;

  @override
  State<QuizTakingScreen> createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends State<QuizTakingScreen> {
  final _service = LearnerQuizService();
  final _identificationController = TextEditingController();
  late final Map<String, String> _answers;
  int _index = 0;
  bool _saving = false;
  bool _submitting = false;
  String? _error;

  LearnerQuizQuestion get _question => widget.attempt.questions[_index];
  String? get _answer => _answers[_question.id];

  @override
  void initState() {
    super.initState();
    _answers = {
      for (final question in widget.attempt.questions)
        if (question.savedAnswer?.isNotEmpty ?? false)
          question.id: question.savedAnswer!,
    };
    _syncTextAnswer();
  }

  @override
  void dispose() {
    _identificationController.dispose();
    super.dispose();
  }

  void _syncTextAnswer() {
    if (widget.attempt.questions.isEmpty) return;
    final value = _question.type == 'identification' ? (_answer ?? '') : '';
    _identificationController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.attempt.questions.isEmpty) {
      return const Scaffold(
        body: SafeArea(
          child: LearnerStateView(
            icon: Icons.quiz_outlined,
            title: 'Quiz has no questions',
            message: 'Ask your Instructor to review the published quiz.',
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundOffWhite,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
                child: Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: _saving || _submitting ? null : _confirmLeave,
                      tooltip: 'Leave quiz',
                      icon: const Icon(Icons.close_rounded),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.attempt.title,
                            style: AppTheme.titleLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Question ${_index + 1} of ${widget.attempt.questions.length}',
                            style: AppTheme.labelMedium,
                          ),
                        ],
                      ),
                    ),
                    if (_saving)
                      Semantics(
                        label: 'Saving answer',
                        liveRegion: true,
                        child: const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      )
                    else
                      Semantics(
                        label: '${_answers.length} answers saved',
                        child: const Icon(
                          Icons.cloud_done_outlined,
                          color: AppTheme.accentGreen,
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: LearnerProgressBar(
                  value: (_index + 1) / widget.attempt.questions.length,
                  semanticLabel: 'Quiz question progress',
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _QuestionTypeLabel(type: _question.type),
                      const SizedBox(height: 12),
                      LearnerSurface(
                        elevated: true,
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          _question.prompt,
                          style: AppTheme.titleLarge.copyWith(height: 1.4),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildAnswerEditor(),
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        Semantics(
                          liveRegion: true,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.errorRed.withValues(alpha: .08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.errorRed.withValues(alpha: .25),
                              ),
                            ),
                            child: Text(_error!, style: AppTheme.bodySmall),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerEditor() {
    if (_question.type == 'identification') {
      return LearnerSurface(
        child: TextField(
          controller: _identificationController,
          enabled: !_submitting,
          maxLength: 2000,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Your answer',
            hintText: 'Enter your answer',
            helperText: 'Your answer is saved when you continue.',
          ),
          onSubmitted: (_) => _saveCurrent(),
        ),
      );
    }

    final options = _question.type == 'true_false'
        ? const ['True', 'False']
        : _question.options;
    if (options.isEmpty) {
      return const LearnerStateView(
        icon: Icons.warning_amber_rounded,
        title: 'Question unavailable',
        message: 'This published question has no answer options.',
      );
    }
    return Column(
      children: [
        for (final option in options)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _AnswerOption(
              label: option,
              selected: _answer == option,
              enabled: !_saving && !_submitting,
              onTap: () => _selectOption(option),
            ),
          ),
      ],
    );
  }

  Widget _buildFooter() => Material(
        color: AppTheme.cardWhite,
        child: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.borderLight)),
            ),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _index == 0 || _saving || _submitting
                      ? null
                      : _goPrevious,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Previous'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _saving || _submitting ? null : _continue,
                    icon: _submitting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(_index == widget.attempt.questions.length - 1
                            ? Icons.fact_check_outlined
                            : Icons.arrow_forward_rounded),
                    label: Text(
                      _submitting
                          ? 'Submitting'
                          : _index == widget.attempt.questions.length - 1
                              ? 'Review & submit'
                              : 'Next',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Future<void> _selectOption(String value) async {
    setState(() {
      _answers[_question.id] = value;
      _error = null;
    });
    await _saveCurrent();
  }

  Future<bool> _saveCurrent() async {
    final value = _question.type == 'identification'
        ? _identificationController.text.trim()
        : (_answer ?? '').trim();
    if (value.isEmpty) {
      setState(() => _error = 'Choose or enter an answer before continuing.');
      return false;
    }
    setState(() {
      _saving = true;
      _error = null;
      _answers[_question.id] = value;
    });
    try {
      await _service.saveAnswer(
        attemptId: widget.attempt.attemptId,
        itemId: _question.id,
        answer: value,
      );
      return true;
    } catch (error) {
      debugPrint('Quiz answer save failed: $error');
      if (mounted) {
        setState(() => _error =
            'Your answer was not saved. Check your connection and try again.');
      }
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _goPrevious() async {
    final currentValue = _question.type == 'identification'
        ? _identificationController.text.trim()
        : (_answer ?? '').trim();
    if (currentValue.isNotEmpty && !await _saveCurrent()) return;
    if (!mounted) return;
    setState(() {
      _index--;
      _error = null;
      _syncTextAnswer();
    });
  }

  Future<void> _continue() async {
    if (!await _saveCurrent() || !mounted) return;
    if (_index < widget.attempt.questions.length - 1) {
      setState(() {
        _index++;
        _syncTextAnswer();
      });
      return;
    }
    await _showSubmissionReview();
  }

  Future<void> _showSubmissionReview() async {
    final missing = widget.attempt.questions
        .where((question) => (_answers[question.id]?.trim().isEmpty ?? true))
        .length;
    final submit = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Submit quiz?', style: AppTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                missing == 0
                    ? 'You answered all ${widget.attempt.questions.length} questions. After submission, answers can no longer be changed.'
                    : '$missing questions still need an answer.',
                style: AppTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Review answers'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: missing == 0
                          ? () => Navigator.pop(context, true)
                          : null,
                      child: const Text('Submit'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (submit == true) await _submit();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await _service.submit(widget.attempt.attemptId);
      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => QuizResultScreen(
            attemptId: widget.attempt.attemptId,
            initialResult: result,
          ),
        ),
      );
    } catch (error) {
      debugPrint('Quiz submission failed: $error');
      if (mounted) {
        setState(() => _error =
            'The quiz was not submitted. Your saved answers remain available.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave this quiz?'),
        content: const Text(
          'Answers already saved to ByteQuest will be restored when you continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave quiz'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.pop(context);
  }
}

class _QuestionTypeLabel extends StatelessWidget {
  const _QuestionTypeLabel({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    final label = switch (type) {
      'multiple_choice' => 'Multiple choice',
      'true_false' => 'True or false',
      'identification' => 'Identification',
      'scenario_based' => 'Scenario question',
      _ => 'Question',
    };
    return Text(
      label.toUpperCase(),
      style: AppTheme.labelMedium.copyWith(
        color: AppTheme.primaryBlue,
        fontWeight: FontWeight.w800,
        letterSpacing: .7,
      ),
    );
  }
}

class _AnswerOption extends StatelessWidget {
  const _AnswerOption({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        selected: selected,
        button: true,
        label: '$label${selected ? ", selected" : ""}',
        child: Material(
          color: selected ? AppTheme.backgroundPaleBlue : AppTheme.cardWhite,
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.radiusLg,
            side: BorderSide(
              color: selected ? AppTheme.primaryBlue : AppTheme.borderLight,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: AppTheme.radiusLg,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                child: Row(
                  children: [
                    Icon(
                      selected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color:
                          selected ? AppTheme.primaryBlue : AppTheme.textMedium,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(label, style: AppTheme.bodyMedium)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
