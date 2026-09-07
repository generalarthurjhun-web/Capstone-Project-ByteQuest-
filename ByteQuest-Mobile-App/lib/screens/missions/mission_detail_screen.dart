import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/soft_card.dart';
import '../../core/widgets/app_button.dart';
import '../../models/mission_model.dart';
import '../../data/mission_scenarios_data.dart';
import '../simulation/mission_launcher.dart';
import '../../services/mission_service.dart';

/// Mission Detail Screen
/// Displays scenario, objectives, skills assessed, and challenge rules before starting
class MissionDetailScreen extends StatelessWidget {
  final Mission mission;

  const MissionDetailScreen({
    super.key,
    required this.mission,
  });

  @override
  Widget build(BuildContext context) {
    final scenario = MissionScenariosData.getScenarioByMissionId(mission.id);

    if (scenario == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mission Details'),
        ),
        body: const Center(
          child: Text('Scenario data not found'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundOffWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Custom AppBar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon:
                        const Icon(Icons.arrow_back, color: AppTheme.textDark),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mission ${scenario.missionNumber}',
                          style: AppTheme.labelSmall.copyWith(
                            color: AppTheme.textMedium,
                          ),
                        ),
                        Text(
                          scenario.moduleName,
                          style: AppTheme.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mission Header Card
                    SoftCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.flag,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      scenario.missionTitle,
                                      style: AppTheme.headlineMedium.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      scenario.cocId.toUpperCase(),
                                      style: AppTheme.labelSmall.copyWith(
                                        color: AppTheme.primaryBlue,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Stats Row
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildStatChip(
                                Icons.trending_up,
                                scenario.difficulty,
                                _getDifficultyColor(scenario.difficulty),
                              ),
                              _buildStatChip(
                                Icons.science_outlined,
                                'Practice',
                                AppTheme.primaryBlue,
                              ),
                              _buildStatChip(
                                Icons.access_time,
                                '${scenario.estimatedTime} min',
                                AppTheme.textMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Scenario Section
                    _buildSectionHeader('Scenario', Icons.auto_stories),
                    const SizedBox(height: 12),
                    SoftCard(
                      child: Text(
                        scenario.scenario,
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textMedium,
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Objective Section
                    _buildSectionHeader(
                        'Objective', Icons.check_circle_outline),
                    const SizedBox(height: 12),
                    SoftCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.accentGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.rocket_launch,
                              color: AppTheme.accentGreen,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              scenario.objective,
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.textDark,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Skills Assessed Section
                    _buildSectionHeader('Skills Assessed', Icons.psychology),
                    const SizedBox(height: 12),
                    SoftCard(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: scenario.skillsAssessed.map((skill) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.primaryBlue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    AppTheme.primaryBlue.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 14,
                                  color: AppTheme.primaryBlue,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  skill,
                                  style: AppTheme.labelSmall.copyWith(
                                    color: AppTheme.primaryBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Challenge Section
                    _buildSectionHeader('Challenge Rules', Icons.military_tech),
                    const SizedBox(height: 12),
                    SoftCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            scenario.challengeDescription,
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.textMedium,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.accentYellow.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.accentYellow
                                    .withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: AppTheme.accentYellow,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Practice feedback only — no official passing threshold',
                                    style: AppTheme.labelMedium.copyWith(
                                      color: AppTheme.textDark,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Reward Info Card
                    SoftCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: AppTheme.accentGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.fact_check_outlined,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Assessment authority',
                                  style: AppTheme.labelMedium.copyWith(
                                    color: AppTheme.textMedium,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Official results require Instructor release',
                                  style: AppTheme.titleMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),

            // Start Mission Button
            Builder(builder: (context) {
              final missionService = Provider.of<MissionService>(context);
              final isCompleted = mission.isCompleted == true ||
                  missionService.completedMissions.contains(mission.id);
              final isUnlocked = mission.isUnlocked == true ||
                  missionService.isMissionUnlocked(mission.id);
              final isActive =
                  missionService.currentActiveMission == mission.id;

              String buttonLabel = 'Start Mission';
              IconData buttonIcon = Icons.play_arrow;
              bool isButtonEnabled = true;
              AppButtonVariant buttonVariant = AppButtonVariant.primary;

              if (!isUnlocked) {
                buttonLabel = 'Mission Locked';
                buttonIcon = Icons.lock;
                isButtonEnabled = false;
              } else if (isCompleted) {
                buttonLabel = 'Retry Mission';
                buttonIcon = Icons.refresh;
                buttonVariant = AppButtonVariant.outline;
              } else if (isActive) {
                buttonLabel = 'Resume Mission';
                buttonIcon = Icons.play_arrow;
              }

              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: AppButton(
                    label: buttonLabel,
                    icon: buttonIcon,
                    isDisabled: !isButtonEnabled,
                    variant: buttonVariant,
                    onPressed: isButtonEnabled
                        ? () {
                            // Close detail screen and launch mission
                            Navigator.of(context).pop();
                            MissionLauncher.launch(context, mission);
                          }
                        : null,
                    width: double.infinity,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.primaryBlue,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTheme.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTheme.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return AppTheme.accentGreen;
      case 'medium':
        return AppTheme.accentYellow;
      case 'hard':
        return AppTheme.errorRed;
      default:
        return AppTheme.textMedium;
    }
  }
}
