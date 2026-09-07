import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Step Progress Card Widget
/// Shows step number, progress bar, and XP reward badge
class StepProgressCard extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final int xpReward;
  final String modeLabel;
  final double progress;
  final IconData? stepIcon;
  final Color? progressColor;
  final EdgeInsetsGeometry? margin;

  const StepProgressCard({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.xpReward,
    this.modeLabel = 'Practice',
    required this.progress,
    this.stepIcon,
    this.progressColor,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final progressValue = progress.clamp(0.0, 1.0);

    return Container(
      margin: margin ?? const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.radiusLg,
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          // Step Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              stepIcon ?? Icons.flag,
              color: AppTheme.primaryBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),

          // Progress Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Step $currentStep of $totalSteps',
                  style: AppTheme.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    backgroundColor:
                        AppTheme.primaryBlue.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progressColor ?? AppTheme.primaryBlue,
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // XP Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.backgroundPaleBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: AppTheme.cardWhite,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.science_outlined,
                    color: AppTheme.primaryBlue,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  modeLabel,
                  style: AppTheme.labelMedium.copyWith(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
