import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/supabase_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/learner_ui.dart';
import '../../core/widgets/supplementary_platform_notice.dart';
import '../../models/assigned_activity_model.dart';
import '../../models/profile_model.dart';
import '../../services/auth_service.dart';
import '../../services/authoritative_assessment_service.dart';
import '../../services/profile_service.dart';
import '../../services/learner_realtime_coordinator.dart';
import '../../widgets/app_top_bar.dart';
import '../missions/missions_screen.dart';
import '../notifications/notifications_screen.dart';
import '../settings/settings_screen.dart';

/// Learner home backed only by shared Supabase records.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with LearnerRealtimeRefreshMixin<DashboardScreen> {
  final _assessmentService = AuthoritativeAssessmentService.instance;
  ProfileModel? _profile;
  List<AssignedActivity> _assignments = const [];
  List<ReleasedAssessmentResult> _releasedResults = const [];
  Map<String, int> _attemptCounts = const {};
  int _unreadCount = 0;
  bool _loading = true;
  String? _error;

  @override
  Set<LearnerRealtimeDomain> get realtimeDomains => const {
        LearnerRealtimeDomain.account,
        LearnerRealtimeDomain.learning,
        LearnerRealtimeDomain.assessment,
        LearnerRealtimeDomain.progress,
        LearnerRealtimeDomain.notifications,
      };

  @override
  Future<void> refreshFromRealtime() => _loadDashboard();

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final userId = context.read<AuthService>().currentUserId;
      if (userId == null) throw StateError('No learner session is active.');

      final values = await Future.wait<dynamic>([
        context.read<ProfileService>().getProfileByUserId(userId),
        _assessmentService.getAssignedActivities(),
        _assessmentService.getReleasedResults(),
        _assessmentService.getAttemptStatusCounts(),
        _loadUnreadCount(userId),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = values[0] as ProfileModel?;
        _assignments = values[1] as List<AssignedActivity>;
        _releasedResults = values[2] as List<ReleasedAssessmentResult>;
        _attemptCounts = values[3] as Map<String, int>;
        _unreadCount = values[4] as int;
        _loading = false;
      });
    } catch (error) {
      debugPrint('Dashboard load failed: $error');
      if (!mounted) return;
      setState(() {
        _error = 'Your shared learning record could not be loaded.';
        _loading = false;
      });
    }
  }

  Future<int> _loadUnreadCount(String userId) async {
    try {
      final rows = await SupabaseConfig.client
          .from('notifications')
          .select('is_read')
          .eq('user_id', userId);
      return (rows as List).where((raw) {
        final row = Map<String, dynamic>.from(raw as Map);
        return !(row['is_read'] as bool? ?? false);
      }).length;
    } catch (_) {
      return 0;
    }
  }

  int get _awaitingReview {
    const pending = {'submitted', 'evaluated', 'under_review', 'finalized'};
    return _attemptCounts.entries
        .where((entry) => pending.contains(entry.key))
        .fold(0, (sum, entry) => sum + entry.value);
  }

  String get _firstName {
    final fullName = _profile?.fullName.trim() ?? '';
    return fullName.isEmpty ? 'Learner' : fullName.split(RegExp(r'\s+')).first;
  }

  void _openLearningHub() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const MissionsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundOffWhite,
      body: SafeArea(
        child: _loading
            ? const LearnerLoadingView(label: 'Loading learner dashboard')
            : RefreshIndicator(
                onRefresh: _loadDashboard,
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 118),
                  children: [
                    AppTopBar(
                      title: 'Hello, $_firstName',
                      subtitle: 'Ready for your next skill challenge?',
                      notificationCount: _unreadCount,
                      avatarLabel: _firstName,
                      onNotificationTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const NotificationsScreen(),
                          ),
                        );
                        if (mounted) await _loadDashboard();
                      },
                      onSettingsTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const SettingsScreen(),
                        ),
                      ),
                    ),
                    if (_error != null)
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height * .68,
                        child: LearnerStateView(
                          icon: Icons.cloud_off_outlined,
                          title: 'Learning record unavailable',
                          message:
                              '$_error Check your connection, then try again.',
                          actionLabel: 'Try again',
                          onAction: _loadDashboard,
                        ),
                      )
                    else ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _LearningOverview(
                          nextAssignment:
                              _assignments.isEmpty ? null : _assignments.first,
                          assigned: _assignments.length,
                          awaitingReview: _awaitingReview,
                          released: _releasedResults.length,
                          onContinue: _openLearningHub,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: LearnerSectionHeader(
                          title: 'Your activities',
                          supportingText: 'Assigned by your Instructor',
                          actionLabel: 'View all',
                          onAction: _openLearningHub,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_assignments.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: LearnerSurface(
                            child: _CompactEmpty(
                              icon: Icons.assignment_outlined,
                              text:
                                  'Your Instructor has not assigned an activity yet.',
                            ),
                          ),
                        )
                      else
                        ..._assignments.take(3).map(_buildAssignmentCard),
                      const SizedBox(height: 24),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: LearnerSectionHeader(
                          title: 'Released results',
                          supportingText: 'Instructor-reviewed outcomes',
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_releasedResults.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: LearnerSurface(
                            child: _CompactEmpty(
                              icon: Icons.verified_outlined,
                              text:
                                  'Final results appear after Instructor review and release.',
                            ),
                          ),
                        )
                      else
                        ..._releasedResults.take(2).map(_buildResultCard),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: SupplementaryPlatformNotice(),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildAssignmentCard(AssignedActivity assignment) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        child: LearnerSurface(
          onTap: _openLearningHub,
          semanticLabel:
              '${assignment.title}, ${assignment.isAssessment ? "assessment" : "practice"}, ${assignment.classTitle}',
          child: Row(
            children: [
              _FeatureIcon(
                icon: assignment.isAssessment
                    ? Icons.fact_check_outlined
                    : Icons.school_outlined,
                color: assignment.isAssessment
                    ? AppTheme.accentOrange
                    : AppTheme.primaryBlue,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment.title,
                      style: AppTheme.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${assignment.classTitle} · ${assignment.isAssessment ? "Assessment" : "Practice"}',
                      style: AppTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.textLight),
            ],
          ),
        ),
      );

  Widget _buildResultCard(ReleasedAssessmentResult result) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        child: LearnerSurface(
          semanticLabel:
              '${result.assignmentTitle}, released result ${_readableOutcome(result.outcome)}',
          child: Row(
            children: [
              const _FeatureIcon(
                icon: Icons.verified_rounded,
                color: AppTheme.accentGreen,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.assignmentTitle,
                      style: AppTheme.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${result.classTitle} · ${_readableOutcome(result.outcome)}',
                      style: AppTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (result.percentage != null) ...[
                const SizedBox(width: 8),
                Text(
                  '${result.percentage}%',
                  style: AppTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
        ),
      );

  String _readableOutcome(String value) => value
      .split('_')
      .map((part) => part.isEmpty
          ? part
          : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
      .join(' ');
}

class _LearningOverview extends StatelessWidget {
  final AssignedActivity? nextAssignment;
  final int assigned;
  final int awaitingReview;
  final int released;
  final VoidCallback onContinue;

  const _LearningOverview({
    required this.nextAssignment,
    required this.assigned,
    required this.awaitingReview,
    required this.released,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label:
            '$assigned assigned, $awaitingReview awaiting review, $released released results',
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue,
            borderRadius: AppTheme.radiusXl,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withValues(alpha: .22),
                blurRadius: 26,
                offset: const Offset(0, 12),
                spreadRadius: -10,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: Colors.white,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      nextAssignment == null ? 'Learning hub' : 'Up next',
                      style: AppTheme.labelLarge.copyWith(
                        color: Colors.white.withValues(alpha: .94),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                nextAssignment?.title ??
                    'Your next assignment will appear here',
                style: AppTheme.headlineMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              Text(
                nextAssignment?.classTitle ??
                    'Explore practice activities while you wait.',
                style: AppTheme.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: .94),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryBlue,
                  minimumSize: const Size(0, 44),
                ),
                onPressed: onContinue,
                icon: Icon(
                  nextAssignment == null
                      ? Icons.explore_outlined
                      : Icons.play_arrow_rounded,
                ),
                label: Text(
                  nextAssignment == null ? 'Explore activities' : 'Continue',
                ),
              ),
              const SizedBox(height: 18),
              Divider(color: Colors.white.withValues(alpha: .18)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _SummaryValue(label: 'Assigned', value: assigned),
                  _SummaryValue(label: 'In review', value: awaitingReview),
                  _SummaryValue(label: 'Released', value: released),
                ],
              ),
            ],
          ),
        ),
      );
}

class _SummaryValue extends StatelessWidget {
  final String label;
  final int value;

  const _SummaryValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: AppTheme.headlineMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTheme.labelSmall.copyWith(
                color: Colors.white.withValues(alpha: .94),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
}

class _FeatureIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _FeatureIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      );
}

class _CompactEmpty extends StatelessWidget {
  final IconData icon;
  final String text;

  const _CompactEmpty({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.textMedium, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppTheme.bodyMedium)),
        ],
      );
}
