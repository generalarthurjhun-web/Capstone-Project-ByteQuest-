import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Feedback Card Widget with Robot Assistant
/// Shows success/error feedback with animated robot character
class FeedbackCard extends StatelessWidget {
  final String message;
  final String? subtitle;
  final FeedbackType type;
  final bool showRobot;
  final bool dismissible;
  final VoidCallback? onDismiss;

  const FeedbackCard({
    super.key,
    required this.message,
    this.subtitle,
    this.type = FeedbackType.success,
    this.showRobot = true,
    this.dismissible = false,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getFeedbackConfig();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: AppTheme.radiusLg,
        border: Border.all(
          color: config.borderColor,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Robot Assistant or Icon
          if (showRobot) ...[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/System Unit Mascot.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      config.icon,
                      color: config.iconColor,
                      size: 28,
                    );
                  },
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: config.iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                config.icon,
                color: config.iconColor,
                size: 24,
              ),
            ),
          ],
          const SizedBox(width: 12),

          // Message Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      config.icon,
                      size: 18,
                      color: config.iconColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        message,
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textMedium,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Dismiss Button
          if (dismissible && onDismiss != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onDismiss,
              color: AppTheme.textMedium,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }

  _FeedbackConfig _getFeedbackConfig() {
    switch (type) {
      case FeedbackType.success:
        return _FeedbackConfig(
          backgroundColor: AppTheme.accentGreen.withValues(alpha: 0.1),
          borderColor: AppTheme.accentGreen.withValues(alpha: 0.3),
          icon: Icons.check_circle,
          iconColor: AppTheme.accentGreen,
        );
      case FeedbackType.error:
        return _FeedbackConfig(
          backgroundColor: AppTheme.errorRed.withValues(alpha: 0.1),
          borderColor: AppTheme.errorRed.withValues(alpha: 0.3),
          icon: Icons.error,
          iconColor: AppTheme.errorRed,
        );
      case FeedbackType.warning:
        return _FeedbackConfig(
          backgroundColor: AppTheme.accentOrange.withValues(alpha: 0.1),
          borderColor: AppTheme.accentOrange.withValues(alpha: 0.3),
          icon: Icons.warning_amber,
          iconColor: AppTheme.accentOrange,
        );
      case FeedbackType.info:
        return _FeedbackConfig(
          backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
          borderColor: AppTheme.primaryBlue.withValues(alpha: 0.3),
          icon: Icons.info,
          iconColor: AppTheme.primaryBlue,
        );
    }
  }
}

enum FeedbackType {
  success,
  error,
  warning,
  info,
}

class _FeedbackConfig {
  final Color backgroundColor;
  final Color borderColor;
  final IconData icon;
  final Color iconColor;

  _FeedbackConfig({
    required this.backgroundColor,
    required this.borderColor,
    required this.icon,
    required this.iconColor,
  });
}
