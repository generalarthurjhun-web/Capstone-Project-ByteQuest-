import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/learner_ui.dart';
import '../../core/widgets/supplementary_platform_notice.dart';
import '../../models/assigned_activity_model.dart';
import '../../models/learner_learning_path_model.dart';
import '../../services/authoritative_assessment_service.dart';
import '../../services/mission_database_service.dart';
import '../../services/learner_realtime_coordinator.dart';
import 'attempt_history_screen.dart';

/// Displays only Instructor-released assessment results. Provisional and
/// client-computed outcomes are intentionally excluded.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with LearnerRealtimeRefreshMixin<ProgressScreen> {
  final _assessmentService = AuthoritativeAssessmentService.instance;
  List<ReleasedAssessmentResult> _results = const [];
  Map<String, int> _attemptCounts = const {};
  List<LearnerCocProjection> _learningPath = const [];
  bool _loading = true;
  String? _error;

  @override
  Set<LearnerRealtimeDomain> get realtimeDomains => const {
        LearnerRealtimeDomain.assessment,
        LearnerRealtimeDomain.progress,
        LearnerRealtimeDomain.learning,
      };

  @override
  Future<void> refreshFromRealtime() => _load();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final values = await Future.wait<dynamic>([
        _assessmentService.getReleasedResults(),
        _assessmentService.getAttemptStatusCounts(),
        MissionDatabaseService().getLearnerLearningPath(),
      ]);
      if (!mounted) return;
      setState(() {
        _results = values[0] as List<ReleasedAssessmentResult>;
        _attemptCounts = values[1] as Map<String, int>;
        _learningPath = values[2] as List<LearnerCocProjection>;
        _loading = false;
      });
    } catch (error) {
      debugPrint('Released results load failed: $error');
      if (!mounted) return;
      setState(() {
        _error = 'Released results could not be loaded.';
        _loading = false;
      });
    }
  }

  int get _pendingCount {
    const pending = {'submitted', 'evaluated', 'under_review', 'finalized'};
    return _attemptCounts.entries
        .where((entry) => pending.contains(entry.key))
        .fold(0, (sum, entry) => sum + entry.value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundOffWhite,
      body: SafeArea(
        child: _loading
            ? const LearnerLoadingView(label: 'Loading released results')
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                  children: [
                    const LearnerPageHeader(
                      title: 'Progress',
                      subtitle: 'Instructor-reviewed learning outcomes',
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 18),
                    _AuthorityNotice(pendingCount: _pendingCount),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const AttemptHistoryScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.history_rounded),
                      label: const Text('View attempt history'),
                    ),
                    const SizedBox(height: 20),
                    if (_error == null) ...[
                      Text(
                        'COC and mission progress',
                        style: AppTheme.titleLarge
                            .copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Counts below mean Instructor-released mission results, not a TESDA percentage.',
                        style: AppTheme.bodySmall
                            .copyWith(color: AppTheme.textMedium),
                      ),
                      const SizedBox(height: 12),
                      ..._learningPath.map(_buildCocProgressCard),
                      const SizedBox(height: 8),
                    ],
                    if (_error != null)
                      _MessageCard(
                        icon: Icons.cloud_off_outlined,
                        message: _error!,
                      )
                    else if (_results.isEmpty)
                      const _MessageCard(
                        icon: Icons.verified_outlined,
                        message:
                            'No final result has been released yet. Submitted work remains hidden until Instructor review and release.',
                      )
                    else
                      ..._results.map(_buildResultCard),
                    const SizedBox(height: 12),
                    const _MessageCard(
                      icon: Icons.stars_outlined,
                      message:
                          'XP, points, badges, and levels are motivational only. They never change an official competency result.',
                    ),
                    const SizedBox(height: 12),
                    const SupplementaryPlatformNotice(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildResultCard(ReleasedAssessmentResult result) {
    final outcome = _readableOutcome(result.outcome);
    final satisfiedCount =
        result.criteria.where((criterion) => criterion.isSatisfied).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        container: true,
        label: '${result.assignmentTitle}, Instructor final outcome $outcome, '
            '$satisfiedCount of ${result.criteria.length} criteria satisfied',
        child: Card(
          elevation: 0,
          color: AppTheme.cardWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.borderLight),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.verified_outlined,
                        color: AppTheme.accentGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result.assignmentTitle,
                            style: AppTheme.titleLarge.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            [
                              result.classTitle,
                              if (result.cocCode != null)
                                result.cocCode!.toUpperCase(),
                              if (result.missionTitle != null)
                                result.missionTitle!,
                            ].join(' · '),
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusChip(label: outcome),
                    const _StatusChip(label: 'Instructor final'),
                    if (result.criteria.isNotEmpty)
                      _StatusChip(
                        label:
                            '$satisfiedCount/${result.criteria.length} criteria satisfied',
                      ),
                    _StatusChip(
                      label:
                          'Released ${DateFormat.yMMMd().format(result.releasedAt.toLocal())}',
                    ),
                  ],
                ),
                if (result.remarks?.trim().isNotEmpty ?? false) ...[
                  const SizedBox(height: 14),
                  Text(
                    result.remarks!,
                    style: AppTheme.bodyMedium.copyWith(height: 1.45),
                  ),
                ],
                if (result.criteria.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(bottom: 4),
                      title: Text(
                        'Criterion feedback',
                        style: AppTheme.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        'Review the evidence outcomes released by your Instructor.',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textMedium,
                        ),
                      ),
                      children: result.criteria
                          .map(
                            (criterion) => Semantics(
                              label:
                                  '${criterion.code}, ${criterion.title}, ${criterion.isSatisfied ? "satisfied" : "not satisfied"}',
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 7),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      criterion.isSatisfied
                                          ? Icons.check_circle_outline
                                          : Icons.error_outline,
                                      size: 20,
                                      color: criterion.isSatisfied
                                          ? AppTheme.accentGreen
                                          : AppTheme.warningYellow,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${criterion.code} · ${criterion.title}',
                                            style: AppTheme.bodyMedium.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            criterion.isSatisfied
                                                ? 'Satisfied'
                                                : 'Not satisfied',
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
                          )
                          .toList(growable: false),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCocProgressCard(LearnerCocProjection coc) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Card(
          elevation: 0,
          color: AppTheme.cardWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.borderLight),
          ),
          child: ExpansionTile(
            childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
            leading: CircleAvatar(
              backgroundColor: AppTheme.backgroundPaleBlue,
              foregroundColor: AppTheme.primaryBlue,
              child: Text('${coc.order}'),
            ),
            title: Text(
              coc.title,
              style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              '${coc.releasedMissionCount}/${coc.missions.length} mission results released · ${coc.lifecycleLabel}',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textMedium),
            ),
            children: coc.missions
                .map(
                  (mission) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          mission.released
                              ? Icons.verified_outlined
                              : mission.isInProgress
                                  ? Icons.pending_actions_outlined
                                  : Icons.science_outlined,
                          size: 19,
                          color: mission.released
                              ? AppTheme.accentGreen
                              : mission.isInProgress
                                  ? AppTheme.primaryBlue
                                  : AppTheme.textMedium,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Mission ${mission.number}: ${mission.title}',
                            style: AppTheme.bodySmall,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _missionStateLabel(mission),
                          style: AppTheme.labelSmall.copyWith(
                            color: AppTheme.textMedium,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      );

  String _missionStateLabel(LearnerMissionProjection mission) {
    if (mission.released) return 'Released';
    if (mission.isAwaitingInstructor) return 'Awaiting review';
    if (mission.isInProgress) return 'In progress';
    if (mission.isAssigned) return 'Assigned';
    return 'Practice';
  }

  String _readableOutcome(String value) => value
      .split('_')
      .map((part) => part.isEmpty
          ? part
          : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
      .join(' ');
}

class _AuthorityNotice extends StatelessWidget {
  final int pendingCount;
  const _AuthorityNotice({required this.pendingCount});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue,
          borderRadius: AppTheme.radiusXl,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withValues(alpha: .2),
              blurRadius: 24,
              offset: const Offset(0, 10),
              spreadRadius: -10,
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.policy_outlined, color: Colors.white, size: 30),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pendingCount == 0
                        ? 'You are all caught up'
                        : '$pendingCount ${pendingCount == 1 ? "attempt" : "attempts"} awaiting release',
                    style: AppTheme.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pendingCount == 0
                        ? 'Released Instructor results will appear below.'
                        : 'Your Instructor is reviewing these submissions.',
                    style: AppTheme.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.94),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _StatusChip extends StatelessWidget {
  final String label;
  const _StatusChip({required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.backgroundPaleBlue,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: AppTheme.labelSmall.copyWith(fontWeight: FontWeight.w700),
        ),
      );
}

class _MessageCard extends StatelessWidget {
  final IconData icon;
  final String message;
  const _MessageCard({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.textMedium),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textMedium,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      );
}
