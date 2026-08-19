import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/learner_ui.dart';
import '../../models/attempt_history_model.dart';
import '../../services/authoritative_assessment_service.dart';
import '../../services/learner_realtime_coordinator.dart';

class AttemptHistoryScreen extends StatefulWidget {
  const AttemptHistoryScreen({super.key});

  @override
  State<AttemptHistoryScreen> createState() => _AttemptHistoryScreenState();
}

class _AttemptHistoryScreenState extends State<AttemptHistoryScreen>
    with LearnerRealtimeRefreshMixin<AttemptHistoryScreen> {
  final _service = AuthoritativeAssessmentService.instance;
  List<AttemptHistoryEntry> _attempts = const [];
  bool _loading = true;
  String? _error;

  @override
  Set<LearnerRealtimeDomain> get realtimeDomains => const {
        LearnerRealtimeDomain.assessment,
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
      final attempts = await _service.getAttemptHistory();
      if (!mounted) return;
      setState(() {
        _attempts = attempts;
        _loading = false;
      });
    } catch (error) {
      debugPrint('Attempt history load failed: $error');
      if (!mounted) return;
      setState(() {
        _error = 'Attempt history could not be loaded.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundOffWhite,
      body: SafeArea(
        child: _loading
            ? const LearnerLoadingView(label: 'Loading attempt history')
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                  children: [
                    LearnerPageHeader(
                      title: 'Attempt history',
                      subtitle: 'Your saved assessment and practice timeline',
                      padding: EdgeInsets.zero,
                      trailing: IconButton.filledTonal(
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Close attempt history',
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (_error != null)
                      LearnerStateView(
                        icon: Icons.cloud_off_outlined,
                        title: 'History unavailable',
                        message:
                            '${_error!} Check your connection and try again.',
                        actionLabel: 'Try again',
                        onAction: _load,
                      )
                    else if (_attempts.isEmpty)
                      const LearnerStateView(
                        icon: Icons.history_rounded,
                        title: 'No attempts yet',
                        message:
                            'Completed or submitted activities will appear here.',
                      )
                    else
                      ..._attempts.map(_buildAttempt),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildAttempt(AttemptHistoryEntry attempt) {
    final status = _statusLabel(attempt.status);
    final statusColor = attempt.isReleased
        ? AppTheme.accentGreen
        : attempt.isProvisional
            ? AppTheme.accentOrange
            : AppTheme.textMedium;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: LearnerSurface(
        semanticLabel:
            '${attempt.title}, $status, started ${DateFormat.yMMMd().format(attempt.startedAt.toLocal())}',
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                attempt.isReleased
                    ? Icons.verified_outlined
                    : attempt.isProvisional
                        ? Icons.pending_actions_outlined
                        : Icons.edit_note_outlined,
                color: statusColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(attempt.title, style: AppTheme.titleMedium),
                  const SizedBox(height: 3),
                  Text(attempt.classTitle, style: AppTheme.bodySmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _StatusChip(label: status, color: statusColor),
                      Text(
                        DateFormat.yMMMd().format(attempt.startedAt.toLocal()),
                        style: AppTheme.labelSmall,
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

  String _statusLabel(String value) => value
      .split('_')
      .map((part) => part.isEmpty
          ? part
          : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
      .join(' ');
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

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
