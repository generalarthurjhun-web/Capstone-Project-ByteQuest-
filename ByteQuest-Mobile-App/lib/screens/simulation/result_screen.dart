import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/learner_ui.dart';
import '../../models/mission_model.dart';
import '../../services/authoritative_assessment_service.dart';
import 'interactions/evidence_review_panel.dart';

/// Completion presentation. Official assessment outcomes never come from the
/// local MissionResult; the mobile client only submits ordered evidence.
class ResultScreen extends StatefulWidget {
  final Mission mission;
  final MissionResult result;
  final AuthoritativeAssessmentService? assessmentService;

  const ResultScreen({
    super.key,
    required this.mission,
    required this.result,
    this.assessmentService,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late final AuthoritativeAssessmentService _assessmentService;
  late final bool _wasAssigned;
  late final bool _wasAssessment;
  bool _submitting = false;
  bool _submitted = false;
  bool _loadingEvidence = false;
  bool _evidenceLoadFailed = false;
  int _evidenceCount = 0;
  List<Map<String, dynamic>> _evidence = const [];
  String? _submissionError;

  @override
  void initState() {
    super.initState();
    _assessmentService =
        widget.assessmentService ?? AuthoritativeAssessmentService.instance;
    final session = _assessmentService.activeSession;
    _wasAssigned = session != null;
    _wasAssessment = session?.isAssessment ?? false;
    if (_wasAssigned) _loadEvidenceSummary();
  }

  Future<void> _loadEvidenceSummary() async {
    setState(() {
      _loadingEvidence = true;
      _submissionError = null;
    });
    try {
      final actions = await _assessmentService.getActiveAttemptActions();
      if (!mounted) return;
      setState(() {
        _evidenceCount = actions
            .where((action) => action['action_type'] != 'attempt_started')
            .length;
        _evidence = actions
            .where((action) => action['action_type'] != 'attempt_started')
            .toList(growable: false);
        _loadingEvidence = false;
        _evidenceLoadFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingEvidence = false;
        _evidenceLoadFailed = true;
        _submissionError =
            'Your evidence summary could not be loaded. Return to the activity and try again.';
      });
    }
  }

  Future<void> _confirmSubmission() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Submit recorded evidence?'),
        content: const Text(
          'Submission is final for this attempt. PostgreSQL will evaluate the recorded evidence, then your Instructor must review and release the result.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep reviewing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Submit evidence'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _submitEvidence();
  }

  Future<void> _submitEvidence() async {
    setState(() {
      _submitting = true;
      _evidenceLoadFailed = false;
      _submissionError = null;
    });
    try {
      await _assessmentService.submitAttempt(finalEvidence: {
        'local_mission_id': widget.mission.id,
        'elapsed_seconds_reported_by_simulation': widget.result.timeSpent,
        'completion_signal': true,
      });
      if (!mounted) return;
      setState(() {
        _submitted = true;
        _submitting = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submissionError =
            'Evidence was not submitted. Keep this screen open and try again.';
        _submitting = false;
      });
      debugPrint('Attempt submission failed: $error');
    }
  }

  void _returnToLearningHub() {
    Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final title = _wasAssessment
        ? (_submitted
            ? 'Assessment submitted'
            : _submitting
                ? 'Submitting assessment'
                : 'Review assessment submission')
        : _wasAssigned
            ? (_submitted
                ? 'Practice submitted'
                : _submitting
                    ? 'Submitting practice'
                    : 'Review practice submission')
            : 'Practice complete';
    final accent = _submissionError != null
        ? AppTheme.errorRed
        : _wasAssessment
            ? AppTheme.accentOrange
            : AppTheme.primaryBlue;

    return Scaffold(
      backgroundColor: AppTheme.backgroundOffWhite,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  Semantics(
                    label: title,
                    child: AnimatedContainer(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.1),
                          shape: BoxShape.circle),
                      child: _submitting
                          ? Padding(
                              padding: const EdgeInsets.all(24),
                              child: CircularProgressIndicator(
                                  strokeWidth: 3, color: accent))
                          : Icon(
                              _submissionError != null
                                  ? Icons.cloud_off_outlined
                                  : _wasAssessment
                                      ? Icons.fact_check_outlined
                                      : Icons.school_outlined,
                              size: 36,
                              color: accent),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(title,
                      style: AppTheme.headlineLarge.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(widget.mission.title,
                      style: AppTheme.bodyLarge
                          .copyWith(color: AppTheme.textMedium),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  LearnerSurface(
                    padding: const EdgeInsets.all(18),
                    child: _buildResultBody(),
                  ),
                  const SizedBox(height: 20),
                  if (_submissionError != null)
                    SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton.icon(
                            onPressed: _submitting
                                ? null
                                : (_evidenceLoadFailed
                                    ? _loadEvidenceSummary
                                    : _submitEvidence),
                            icon: const Icon(Icons.refresh_rounded),
                            label: Text(_evidenceLoadFailed
                                ? 'Reload evidence summary'
                                : 'Retry secure submission'))),
                  if (_wasAssigned &&
                      !_wasAssessment &&
                      !_submitted &&
                      !_submitting &&
                      _submissionError == null) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: _loadingEvidence ? null : _confirmSubmission,
                        icon: const Icon(Icons.send_rounded),
                        label: const Text('Submit recorded evidence'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Review activity'),
                      ),
                    ),
                  ],
                  if (_submissionError == null && (!_wasAssigned || _submitted))
                    SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                            onPressed:
                                _submitting ? null : _returnToLearningHub,
                            child:
                                const Text('Return to learning activities'))),
                  if (!_wasAssigned) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Review practice activity'))),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultBody() {
    if (_submissionError != null) {
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.error_outline, color: AppTheme.errorRed),
        const SizedBox(width: 12),
        Expanded(
            child: Text(_submissionError!,
                style: AppTheme.bodyMedium.copyWith(height: 1.45)))
      ]);
    }
    if (_wasAssessment) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(
              _submitted
                  ? Icons.lock_outline
                  : _submitting
                      ? Icons.sync_rounded
                      : Icons.fact_check_outlined,
              color: AppTheme.accentOrange),
          const SizedBox(width: 10),
          Expanded(
              child: Text(
                  _submitted
                      ? 'Evidence received'
                      : _submitting
                          ? 'Saving chronological evidence…'
                          : _loadingEvidence
                              ? 'Loading evidence summary…'
                              : '$_evidenceCount recorded evidence events ready',
                  style: AppTheme.titleMedium
                      .copyWith(fontWeight: FontWeight.w700)))
        ]),
        const SizedBox(height: 12),
        Text(
            _submitted
                ? 'The app does not declare your score, pass/fail state, competency, XP, or reward. Trusted evaluation creates a provisional criterion result; your Instructor reviews, finalizes, and releases it.'
                : 'Review the activity before submitting. No score, competency decision, XP, or reward is created until the recorded evidence is submitted to the trusted evaluator.',
            style: AppTheme.bodyMedium
                .copyWith(color: AppTheme.textMedium, height: 1.5)),
        const SizedBox(height: 12),
        Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppTheme.backgroundPaleBlue,
                borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              const Icon(Icons.visibility_outlined,
                  size: 20, color: AppTheme.primaryBlue),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(
                      'Your official result will appear only after release.',
                      style: AppTheme.bodySmall
                          .copyWith(fontWeight: FontWeight.w600)))
            ])),
        if (!_submitted && !_submitting && _evidence.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            'Recorded evidence',
            style: AppTheme.titleSmall.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ..._evidence.map((action) {
            final sequence = action['sequence_number'] as int? ?? 0;
            final type = (action['action_type'] as String? ?? 'evidence')
                .replaceAll('_', ' ');
            final target = action['target'] as String?;
            return Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      '$sequence.',
                      style: AppTheme.labelSmall
                          .copyWith(color: AppTheme.textMedium),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      target == null ? type : '$type · $target',
                      style: AppTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
        if (!_submitted && !_submitting) ...[
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 14),
          EvidenceReviewPanel(
            completedPhaseTitles: const ['Simulation activity'],
            authoritativeEvidenceCount: _evidenceCount,
            pendingEvidenceCount: 0,
            failedEvidenceCount: 0,
            canSubmit: !_loadingEvidence && !_evidenceLoadFailed,
            confirmLabel: 'Submit recorded evidence',
            returnLabel: 'Review activity',
            onConfirm: _confirmSubmission,
            onReturn: () => Navigator.of(context).pop(),
          ),
        ],
      ]);
    }
    if (_wasAssigned) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
            _submitted
                ? 'Practice evidence saved'
                : 'Saving practice evidence…',
            style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(
            'This practice assignment does not create an official competency outcome or reward.',
            style: AppTheme.bodyMedium
                .copyWith(color: AppTheme.textMedium, height: 1.45))
      ]);
    }
    return Column(children: [
      Text('${widget.result.percentage}%',
          style: AppTheme.displaySmall.copyWith(
              fontWeight: FontWeight.w800, color: AppTheme.primaryBlue)),
      const SizedBox(height: 4),
      Text('Local practice feedback',
          style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      Text(
          'This legacy practice score is for immediate feedback only. It is not an official TESDA-aligned score, competency decision, class result, XP, or reward.',
          style: AppTheme.bodyMedium
              .copyWith(color: AppTheme.textMedium, height: 1.5),
          textAlign: TextAlign.center)
    ]);
  }
}
