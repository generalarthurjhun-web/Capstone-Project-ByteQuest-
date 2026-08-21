import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/learner_ui.dart';

/// Rewards remain unavailable until an approved, server-side gamification
/// configuration is activated. This avoids presenting legacy client-generated
/// values as authoritative rankings.
class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundOffWhite,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
          children: [
            LearnerPageHeader(
              title: 'Rewards',
              subtitle: 'Motivation that stays separate from competency',
              padding: const EdgeInsets.fromLTRB(0, 18, 0, 16),
              trailing: IconButton.filledTonal(
                onPressed: () => Navigator.pushNamed(context, '/settings'),
                tooltip: 'Settings',
                icon: const Icon(Icons.settings_outlined),
              ),
            ),
            const SizedBox(height: 8),
            Semantics(
              container: true,
              label: 'Rewards are waiting for an approved server configuration',
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppTheme.navy,
                  borderRadius: AppTheme.radiusXl,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.navy.withValues(alpha: .2),
                      blurRadius: 26,
                      offset: const Offset(0, 12),
                      spreadRadius: -10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: Colors.white,
                        size: 29,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Rewards are being prepared',
                      style: AppTheme.headlineMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rankings will appear only after an Admin activates an approved gamification configuration. Your learning record remains available in Progress.',
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: .94),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const LearnerSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RewardPrinciple(
                    icon: Icons.verified_user_outlined,
                    title: 'Competency stays authoritative',
                    message:
                        'Only evidence reviewed through the assessment lifecycle determines the released result.',
                  ),
                  Divider(height: 28),
                  _RewardPrinciple(
                    icon: Icons.stars_outlined,
                    title: 'Rewards stay motivational',
                    message:
                        'XP, badges, points, and rank never change a TESDA-aligned competency outcome.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardPrinciple extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _RewardPrinciple({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.backgroundPaleBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryBlue, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(message, style: AppTheme.bodySmall),
              ],
            ),
          ),
        ],
      );
}
