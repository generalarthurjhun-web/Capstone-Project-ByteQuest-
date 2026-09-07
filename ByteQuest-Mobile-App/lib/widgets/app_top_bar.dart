import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Reusable top bar with title, notification icon, and settings icon
class AppTopBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onSettingsTap;
  final int notificationCount;
  final bool showIcons;
  final String? avatarLabel;

  const AppTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.onNotificationTap,
    this.onSettingsTap,
    this.notificationCount = 0,
    this.showIcons = true,
    this.avatarLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.headlineLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.35,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textMedium,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (showIcons) ...[
            const SizedBox(width: 8),
            Semantics(
              button: true,
              label: notificationCount == 0
                  ? 'Notifications, none unread'
                  : 'Notifications, $notificationCount unread',
              child: IconButton.filledTonal(
                onPressed: onNotificationTap,
                tooltip: 'Notifications',
                icon: Badge(
                  isLabelVisible: notificationCount > 0,
                  label:
                      Text(notificationCount > 9 ? '9+' : '$notificationCount'),
                  child: const Icon(Icons.notifications_none_rounded, size: 21),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Semantics(
              button: true,
              label: avatarLabel == null
                  ? 'Open learner settings'
                  : 'Open settings for $avatarLabel',
              child: InkWell(
                onTap: onSettingsTap,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.navy,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: avatarLabel == null || avatarLabel!.trim().isEmpty
                      ? const Icon(
                          Icons.person_outline_rounded,
                          color: Colors.white,
                          size: 22,
                        )
                      : Text(
                          avatarLabel!.trim()[0].toUpperCase(),
                          style: AppTheme.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
