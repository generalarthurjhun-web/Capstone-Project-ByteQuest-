import 'package:flutter/material.dart';

import '../../core/config/supabase_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/learner_ui.dart';
import '../../services/learner_realtime_coordinator.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with LearnerRealtimeRefreshMixin<AchievementsScreen> {
  List<Map<String, dynamic>> _earned = const [];
  bool _loading = true;
  String? _error;

  @override
  Set<LearnerRealtimeDomain> get realtimeDomains => const {
        LearnerRealtimeDomain.progress,
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
      final response = await SupabaseConfig.client
          .from('user_achievements')
          .select(
              'id,earned_at,achievements(achievement_code,title,description,icon_url)')
          .order('earned_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _earned = (response as List)
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList(growable: false);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Earned achievements could not be loaded.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppTheme.backgroundOffWhite,
        appBar: AppBar(title: const Text('Achievements')),
        body: _loading
            ? const LearnerLoadingView(label: 'Loading earned achievements')
            : _error != null
                ? LearnerStateView(
                    icon: Icons.cloud_off_outlined,
                    title: 'Achievements unavailable',
                    message: _error!,
                    actionLabel: 'Try again',
                    onAction: _load,
                  )
                : _earned.isEmpty
                    ? const LearnerStateView(
                        icon: Icons.workspace_premium_outlined,
                        title: 'No earned achievements yet',
                        message:
                            'Only achievements recorded by ByteQuest will appear here. No badges or rewards are invented.',
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: _earned.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final row = _earned[index];
                            final achievement = Map<String, dynamic>.from(
                                row['achievements'] as Map? ?? const {});
                            return LearnerSurface(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const CircleAvatar(
                                    backgroundColor:
                                        AppTheme.backgroundPaleBlue,
                                    foregroundColor: AppTheme.primaryBlue,
                                    child:
                                        Icon(Icons.workspace_premium_outlined),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          achievement['title'] as String? ??
                                              'Earned achievement',
                                          style: AppTheme.titleMedium.copyWith(
                                              fontWeight: FontWeight.w800),
                                        ),
                                        if ((achievement['description']
                                                    as String?)
                                                ?.trim()
                                                .isNotEmpty ??
                                            false) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            achievement['description']
                                                as String,
                                            style: AppTheme.bodySmall.copyWith(
                                                color: AppTheme.textMedium),
                                          ),
                                        ],
                                        const SizedBox(height: 8),
                                        Text(
                                          'Earned ${DateTime.parse(row['earned_at'] as String).toLocal().toString().split('.').first}',
                                          style: AppTheme.labelSmall.copyWith(
                                              color: AppTheme.textMedium),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
      );
}
