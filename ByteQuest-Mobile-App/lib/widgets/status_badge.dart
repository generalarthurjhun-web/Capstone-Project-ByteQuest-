import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Reusable status badge widget
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({
    super.key,
    required this.status,
  });

  Color get backgroundColor {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppTheme.accentGreen;
      case 'in progress':
        return AppTheme.primaryBlue;
      case 'locked':
        return Colors.grey.shade400;
      case 'not started':
        return AppTheme.textLight;
      default:
        return AppTheme.accentOrange;
    }
  }

  IconData? get icon {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'in progress':
        return Icons.play_circle;
      case 'locked':
        return Icons.lock;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: backgroundColor,
              size: 12,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            status,
            style: AppTheme.labelSmall.copyWith(
              color: backgroundColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
