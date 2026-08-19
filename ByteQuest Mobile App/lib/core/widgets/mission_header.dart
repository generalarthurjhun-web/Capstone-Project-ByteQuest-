import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'simulation_fullscreen_button.dart';

/// Compact workspace header. Controls remain reachable without competing with
/// the simulation canvas.
class MissionHeader extends StatelessWidget {
  final int missionNumber;
  final String title;
  final String subtitle;
  final VoidCallback? onBackPressed;
  final VoidCallback? onNotificationPressed;
  final VoidCallback? onSettingsPressed;

  const MissionHeader({
    super.key,
    required this.missionNumber,
    required this.title,
    required this.subtitle,
    this.onBackPressed,
    this.onNotificationPressed,
    this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        border: const Border(
          bottom: BorderSide(color: AppTheme.borderLight),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Back Button
            IconButton.filledTonal(
              tooltip: 'Leave mission',
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 10),

            // Title and Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: AppTheme.headlineSmall.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle.isEmpty
                        ? 'Mission $missionNumber'
                        : 'Mission $missionNumber · $subtitle',
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.textMedium,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SimulationFullscreenButton(),

            // Optional notification action
            if (onNotificationPressed != null) ...[
              const SizedBox(width: 8),
              Stack(
                children: [
                  IconButton.filledTonal(
                    icon: const Icon(Icons.notifications_outlined,
                        color: AppTheme.textDark),
                    onPressed: onNotificationPressed,
                    iconSize: 20,
                    padding: const EdgeInsets.all(12),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.errorRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Optional settings action
            if (onSettingsPressed != null) ...[
              const SizedBox(width: 8),
              IconButton.filledTonal(
                icon: const Icon(Icons.settings_outlined,
                    color: AppTheme.textDark),
                onPressed: onSettingsPressed,
                iconSize: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
