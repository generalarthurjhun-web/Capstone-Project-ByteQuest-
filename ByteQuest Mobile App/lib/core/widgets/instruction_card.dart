import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Instruction Card Widget
/// Displays current task instruction with icon and highlighted text
class InstructionCard extends StatelessWidget {
  final String instruction;
  final String? highlightedText;
  final IconData? icon;
  final int? points;
  final Color? backgroundColor;
  final Color? borderColor;

  const InstructionCard({
    super.key,
    required this.instruction,
    this.highlightedText,
    this.icon,
    this.points,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: AppTheme.radiusLg,
        border: Border.all(
          color: borderColor ?? AppTheme.borderLight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Instruction Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (highlightedText != null) ...[
                  _buildRichText(),
                ] else ...[
                  Text(
                    instruction,
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Points Badge (optional)
          if (points != null) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.accentOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.accentOrange.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star,
                    color: AppTheme.accentOrange,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$points',
                    style: AppTheme.labelSmall.copyWith(
                      color: AppTheme.accentOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRichText() {
    if (highlightedText == null) {
      return Text(
        instruction,
        style: AppTheme.bodyLarge.copyWith(
          color: AppTheme.textDark,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    // Split instruction by highlighted text
    final parts = instruction.split(highlightedText!);

    if (parts.length < 2) {
      return Text(
        instruction,
        style: AppTheme.bodyLarge.copyWith(
          color: AppTheme.textDark,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return RichText(
      text: TextSpan(
        style: AppTheme.bodyLarge.copyWith(
          color: AppTheme.textDark,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
        children: [
          TextSpan(text: parts[0]),
          TextSpan(
            text: highlightedText,
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (parts.length > 1)
            TextSpan(text: parts.sublist(1).join(highlightedText!)),
        ],
      ),
    );
  }
}
