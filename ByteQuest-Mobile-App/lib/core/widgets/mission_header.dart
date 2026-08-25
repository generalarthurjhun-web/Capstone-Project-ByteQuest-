import 'package:flutter/material.dart';

import '../../models/mission_model.dart';
import '../../screens/simulation/components/practice_mission_chrome.dart';

/// Shared mission header for legacy practice and authoritative activity hosts.
class MissionHeader extends StatelessWidget {
  const MissionHeader({
    super.key,
    required this.mission,
    required this.subtitle,
    this.onBackPressed,
    this.onNotificationPressed,
    this.onSettingsPressed,
  });

  final Mission mission;
  final String subtitle;
  final VoidCallback? onBackPressed;
  final VoidCallback? onNotificationPressed;
  final VoidCallback? onSettingsPressed;

  @override
  Widget build(BuildContext context) => PracticeMissionHeader(
        mission: mission,
        subtitle: subtitle,
        onBackPressed: onBackPressed ?? () => Navigator.of(context).maybePop(),
        trailing: onNotificationPressed == null && onSettingsPressed == null
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onNotificationPressed != null)
                    IconButton.filledTonal(
                      tooltip: 'Notifications',
                      onPressed: onNotificationPressed,
                      icon: const Icon(Icons.notifications_outlined),
                    ),
                  if (onSettingsPressed != null)
                    IconButton.filledTonal(
                      tooltip: 'Settings',
                      onPressed: onSettingsPressed,
                      icon: const Icon(Icons.settings_outlined),
                    ),
                ],
              ),
      );
}
