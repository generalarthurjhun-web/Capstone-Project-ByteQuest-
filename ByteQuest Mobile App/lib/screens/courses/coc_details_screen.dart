import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/soft_card.dart';
import '../../services/mission_service.dart';
import '../../models/mission_model.dart';
import '../../models/learner_learning_path_model.dart';
import '../simulation/mission_launcher.dart';

/// COC Details Screen - Shows missions for a specific COC
class COCDetailsScreen extends StatelessWidget {
  final LearnerCocProjection projection;

  const COCDetailsScreen({
    super.key,
    required this.projection,
  });

  String get cocId => projection.code;

  String _getCOCTitle(String cocId) {
    switch (cocId) {
      case 'coc1':
        return 'Install and Configure Computer Systems';
      case 'coc2':
        return 'Set Up Computer Networks';
      case 'coc3':
        return 'Set Up Computer Servers';
      case 'coc4':
        return 'Maintain and Repair Computer Systems';
      default:
        return 'Course of Competency';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundOffWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'COC ${cocId.replaceAll('coc', '')}',
          style: AppTheme.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Consumer<MissionService>(
          builder: (context, missionService, child) {
            final missions = missionService.getMissionsByCOC(cocId);
            final releasedCount = projection.releasedMissionCount;

            return Column(
              children: [
                // COC Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getCOCTitle(cocId),
                        style: AppTheme.headlineMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(
                              'Missions',
                              '${missions.length}',
                              Icons.assignment_turned_in,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: AppTheme.textLight.withOpacity(0.2),
                          ),
                          Expanded(
                            child: _buildStatItem(
                              'Released',
                              '$releasedCount/${projection.missions.length}',
                              Icons.trending_up,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: AppTheme.textLight.withOpacity(0.2),
                          ),
                          Expanded(
                            child: _buildStatItem(
                              'Status',
                              projection.lifecycleLabel,
                              Icons.route_outlined,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Missions List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: missions.length,
                    itemBuilder: (context, index) {
                      final mission = missions[index];
                      final missionProjection = _projectionFor(mission);
                      return _buildMissionCard(
                          context, mission, missionProjection);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryBlue, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTheme.labelLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildMissionCard(
    BuildContext context,
    Mission mission,
    LearnerMissionProjection? missionProjection,
  ) {
    final isReleased = missionProjection?.released ?? false;
    final hasActiveAttempt = missionProjection?.isInProgress ?? false;

    return SoftCard(
      margin: const EdgeInsets.only(bottom: 16),
      onTap: () => MissionLauncher.launch(context, mission),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Mission Status Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isReleased
                      ? AppTheme.accentGreen.withOpacity(0.1)
                      : (hasActiveAttempt
                          ? AppTheme.primaryBlue.withOpacity(0.1)
                          : AppTheme.surfaceMuted),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    isReleased
                        ? Icons.check_circle
                        : (hasActiveAttempt
                            ? Icons.pending_actions_rounded
                            : Icons.science_outlined),
                    color: isReleased
                        ? AppTheme.accentGreen
                        : (hasActiveAttempt
                            ? AppTheme.primaryBlue
                            : AppTheme.textLight),
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Mission ${mission.order}',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.w600,
                              fontSize: AppTheme.labelSmall.fontSize,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(mission.difficulty)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            mission.difficulty,
                            style: AppTheme.bodySmall.copyWith(
                              color: _getDifficultyColor(mission.difficulty),
                              fontWeight: FontWeight.w600,
                              fontSize: AppTheme.labelSmall.fontSize,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mission.title,
                      style: AppTheme.labelLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            mission.description ?? '',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textMedium,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.science_outlined,
                      size: 16, color: AppTheme.primaryBlue),
                  const SizedBox(width: 4),
                  Text(
                    'Practice',
                    style: AppTheme.labelSmall.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.timer, size: 16, color: AppTheme.textMedium),
                  const SizedBox(width: 4),
                  Text(
                    '~${mission.estimatedTime} min',
                    style: AppTheme.labelSmall.copyWith(
                      color: AppTheme.textMedium,
                    ),
                  ),
                ],
              ),
              if (missionProjection != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _stateColor(missionProjection.accessState)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _stateLabel(missionProjection),
                    style: AppTheme.bodySmall.copyWith(
                      color: _stateColor(missionProjection.accessState),
                      fontWeight: FontWeight.w600,
                      fontSize: AppTheme.labelSmall.fontSize,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  LearnerMissionProjection? _projectionFor(Mission mission) {
    String normalize(String value) =>
        value.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
    final localCode = normalize(mission.id);
    for (final item in projection.missions) {
      if (normalize(item.code) == localCode) return item;
    }
    return null;
  }

  String _stateLabel(LearnerMissionProjection mission) {
    switch (mission.accessState) {
      case 'released':
        return 'Result released';
      case 'in_progress':
        return 'Assessment in progress';
      case 'awaiting_release':
        return 'Awaiting Instructor';
      case 'available':
        return 'Assigned activity';
      case 'not_yet_available':
        return 'Scheduled';
      case 'prerequisite_required':
        return 'Prerequisite required';
      case 'retry_wait':
        return 'Retry wait';
      case 'attempts_exhausted':
      case 'closed':
        return 'Assessment unavailable';
      default:
        return mission.bypassedPractice ? 'Practice bypass' : 'Practice only';
    }
  }

  Color _stateColor(String state) {
    switch (state) {
      case 'released':
        return AppTheme.accentGreen;
      case 'in_progress':
      case 'available':
        return AppTheme.primaryBlue;
      case 'awaiting_release':
      case 'retry_wait':
        return AppTheme.accentOrange;
      default:
        return AppTheme.textMedium;
    }
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
}
