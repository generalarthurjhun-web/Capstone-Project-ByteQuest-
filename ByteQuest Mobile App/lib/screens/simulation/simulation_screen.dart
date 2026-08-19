import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/soft_card.dart';
import '../../core/widgets/app_button.dart';
import '../../services/mission_service.dart';
import 'mission_launcher.dart';

class SimulationScreen extends StatelessWidget {
  const SimulationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundOffWhite,
      body: SafeArea(
        child: Consumer<MissionService>(
          builder: (context, missionService, child) {
            final currentMissionId = missionService.currentActiveMission;
            final currentMission = currentMissionId != null
                ? missionService.getMissionById(currentMissionId)
                : null;
            final allMissions = missionService.getAllMissions();
            final completedMissions =
                allMissions.where((m) => m.isCompleted == true).toList();
            final recentMissions = completedMissions.isEmpty
                ? <dynamic>[]
                : completedMissions.reversed.take(3).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Simulation Lab',
                    style: AppTheme.headlineLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Practice and master your skills',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textMedium,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Current Mission Card
                  if (currentMission != null) ...[
                    SoftCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  currentMission.cocId
                                      .toUpperCase()
                                      .replaceAll('COC', 'COC '),
                                  style: AppTheme.labelSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.science_outlined,
                                color: AppTheme.primaryBlue,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Practice',
                                style: AppTheme.labelMedium.copyWith(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            currentMission.title,
                            style: AppTheme.headlineMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            currentMission.description ?? '',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.textMedium,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(Icons.timer,
                                  size: 16, color: AppTheme.textMedium),
                              const SizedBox(width: 4),
                              Text(
                                '~${currentMission.estimatedTime} min',
                                style: AppTheme.labelMedium.copyWith(
                                  color: AppTheme.textMedium,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getDifficultyColor(
                                          currentMission.difficulty)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  currentMission.difficulty,
                                  style: AppTheme.labelSmall.copyWith(
                                    color: _getDifficultyColor(
                                        currentMission.difficulty),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    AppButton.primary(
                      label: (currentMission.isCompleted == true)
                          ? 'Retry Mission'
                          : 'Start Mission',
                      icon: Icons.play_arrow_rounded,
                      onPressed: (currentMission.isUnlocked == true)
                          ? () =>
                              MissionLauncher.launch(context, currentMission)
                          : () {},
                      width: double.infinity,
                    ),
                  ] else ...[
                    SoftCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 64,
                            color: AppTheme.accentGreen,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'All Missions Completed!',
                            style: AppTheme.headlineMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You\'ve completed all available missions. Great work!',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.textMedium,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Recent Missions
                  Text(
                    'Recent Missions',
                    style: AppTheme.headlineSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Mission History Cards
                  if (recentMissions.isEmpty) ...[
                    SoftCard(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No completed missions yet',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textMedium,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    ...recentMissions.map((mission) {
                      final result =
                          missionService.getMissionResult(mission.id);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildMissionHistoryCard(
                          mission.title,
                          'Completed',
                          AppTheme.accentGreen,
                          result != null ? '${result.score}%' : '100%',
                          Icons.check_circle,
                        ),
                      );
                    }),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return AppTheme.accentGreen;
      case 'medium':
        return AppTheme.accentOrange;
      case 'hard':
        return AppTheme.errorRed;
      default:
        return AppTheme.textMedium;
    }
  }

  Widget _buildMissionHistoryCard(
    String title,
    String status,
    Color statusColor,
    String completion,
    IconData icon,
  ) {
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      status,
                      style: AppTheme.bodySmall.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• $completion',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textMedium,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: AppTheme.textLight,
            size: 16,
          ),
        ],
      ),
    );
  }
}
