import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Floating "Start" quick action button
class QuickStartButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;

  const QuickStartButton({
    super.key,
    required this.onPressed,
    this.label = 'Start',
    this.icon = Icons.rocket_launch_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 90, // Above the bottom nav
      right: 24,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(28),
        shadowColor: AppTheme.primaryBlue.withOpacity(0.4),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.accentOrange, Color(0xFFEA580C)],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentOrange.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: AppTheme.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
