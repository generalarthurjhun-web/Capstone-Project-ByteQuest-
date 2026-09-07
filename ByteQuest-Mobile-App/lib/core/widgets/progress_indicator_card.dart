import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Progress Indicator Card
/// Shows current progress like "1 of 10 items identified - 10%"
class ProgressIndicatorCard extends StatelessWidget {
  final int current;
  final int total;
  final String label;
  final IconData? icon;
  final Color? progressColor;

  const ProgressIndicatorCard({
    super.key,
    required this.current,
    required this.total,
    required this.label,
    this.icon,
    this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? ((current / total) * 100).toInt() : 0;
    final progress = total > 0 ? (current / total) : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.radiusLg,
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (progressColor ?? AppTheme.accentGreen)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon ?? Icons.checklist,
              color: progressColor ?? AppTheme.accentGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),

          // Progress Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$current of $total $label',
                        style: AppTheme.labelMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$percentage%',
                      style: AppTheme.labelLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: progressColor ?? AppTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: (progressColor ?? AppTheme.accentGreen)
                        .withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progressColor ?? AppTheme.accentGreen,
                    ),
                    minHeight: 8,
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
