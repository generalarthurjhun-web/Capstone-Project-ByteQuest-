import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'status_badge.dart';

/// Reusable mission card widget
class MissionCard extends StatelessWidget {
  final String title;
  final String description;
  final String cocId;
  final int xpReward;
  final String status; // 'Completed', 'In Progress', 'Locked'
  final VoidCallback onTap;
  final int? score;
  final bool isLocked;

  const MissionCard({
    super.key,
    required this.title,
    required this.description,
    required this.cocId,
    required this.xpReward,
    required this.status,
    required this.onTap,
    this.score,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLocked ? null : onTap,
      borderRadius: AppTheme.radiusLg,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: AppTheme.radiusLg,
          border: Border.all(
            color: AppTheme.borderLight,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // COC Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        isLocked ? AppTheme.surfaceMuted : AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    cocId.toUpperCase().replaceAll('COC', 'COC '),
                    style: AppTheme.labelSmall.copyWith(
                      color: isLocked ? AppTheme.textMedium : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                // Status Badge
                StatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 12),
            // Title
            Text(
              title,
              style: AppTheme.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: isLocked ? AppTheme.textLight : AppTheme.textDark,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // Description
            Text(
              description,
              style: AppTheme.bodySmall.copyWith(
                color: isLocked ? AppTheme.textLight : AppTheme.textMedium,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            // Bottom Row
            Row(
              children: [
                // Practice mode label. Official rewards require approved
                // server configuration and are never inferred here.
                Icon(
                  Icons.science_outlined,
                  color: isLocked ? AppTheme.textLight : AppTheme.accentOrange,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Practice',
                  style: AppTheme.labelMedium.copyWith(
                    color:
                        isLocked ? AppTheme.textLight : AppTheme.accentOrange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (score != null) ...[
                  const Spacer(),
                  Text(
                    'Local feedback: $score%',
                    style: AppTheme.labelMedium.copyWith(
                      color: AppTheme.textMedium,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (isLocked) ...[
                  const Spacer(),
                  Icon(
                    Icons.lock,
                    color: AppTheme.textLight,
                    size: 16,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
