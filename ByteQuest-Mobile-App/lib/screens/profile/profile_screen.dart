import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/learner_ui.dart';
import '../../models/profile_model.dart';
import '../../services/auth_service.dart';
import '../../services/mission_service.dart';
import '../../services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  ProfileModel? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = context.read<AuthService>();
      final userId = authService.currentUserId;
      if (userId == null) throw Exception('No authenticated user');

      final profile =
          await context.read<ProfileService>().getProfileByUserId(userId);
      if (profile == null) throw Exception('Profile not found');
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      debugPrint('Profile load failed: $error');
      setState(() {
        _errorMessage = 'Your learner profile could not be loaded.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundOffWhite,
      body: SafeArea(
        child: _isLoading
            ? const LearnerLoadingView(label: 'Loading learner profile')
            : _errorMessage != null
                ? LearnerStateView(
                    icon: Icons.person_off_outlined,
                    title: 'Profile unavailable',
                    message: _errorMessage!,
                    actionLabel: 'Try again',
                    onAction: _loadProfile,
                  )
                : RefreshIndicator(
                    onRefresh: _loadProfile,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
                      children: [
                        LearnerPageHeader(
                          title: 'Profile',
                          subtitle: 'Your ByteQuest learner identity',
                          padding: const EdgeInsets.fromLTRB(0, 18, 0, 16),
                          trailing: IconButton.filledTonal(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/settings'),
                            tooltip: 'Settings',
                            icon: const Icon(Icons.settings_outlined),
                          ),
                        ),
                        _ProfileHero(profile: _profile!),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.pushNamed(
                              context,
                              '/edit-profile',
                            );
                            if (result == true && mounted) await _loadProfile();
                          },
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit profile'),
                        ),
                        const SizedBox(height: 28),
                        const LearnerSectionHeader(
                          title: 'Learning record',
                          supportingText:
                              'Trusted learning outcomes and earned records',
                        ),
                        const SizedBox(height: 12),
                        LearnerSurface(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withValues(
                                    alpha: .1,
                                  ),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: const Icon(
                                  Icons.verified_user_outlined,
                                  color: AppTheme.primaryBlue,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Authoritative progress',
                                      style: AppTheme.titleSmall.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      'Open Progress for Instructor-released results, or Achievements for genuinely earned records. Unapproved legacy XP, streak, and badge counters are not displayed.',
                                      style: AppTheme.bodySmall.copyWith(
                                        color: AppTheme.textMedium,
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundPaleBlue,
                            borderRadius: AppTheme.radiusMd,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                color: AppTheme.primaryBlue,
                                size: 21,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Gamification is motivational only and never changes an Instructor-released competency result.',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.textDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        const LearnerSectionHeader(title: 'Account'),
                        const SizedBox(height: 12),
                        LearnerSurface(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              _AccountAction(
                                title: 'Earned achievements',
                                icon: Icons.workspace_premium_outlined,
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/achievements',
                                ),
                              ),
                              const Divider(height: 1),
                              _AccountAction(
                                title: 'Settings',
                                icon: Icons.tune_rounded,
                                onTap: () =>
                                    Navigator.pushNamed(context, '/settings'),
                              ),
                              const Divider(height: 1),
                              _AccountAction(
                                title: 'Help & support',
                                icon: Icons.help_outline_rounded,
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/help-center',
                                ),
                              ),
                              const Divider(height: 1),
                              _AccountAction(
                                title: 'Log out',
                                icon: Icons.logout_rounded,
                                destructive: true,
                                onTap: () => _showLogoutDialog(context),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final parentContext = context;
    showDialog<void>(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'Your saved server progress will remain available when you sign in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorRed),
            onPressed: () async {
              Navigator.pop(dialogContext);
              showDialog<void>(
                context: parentContext,
                barrierDismissible: false,
                builder: (_) =>
                    const Center(child: CircularProgressIndicator()),
              );
              try {
                await parentContext.read<AuthService>().signOut();
                await parentContext.read<MissionService>().resetProgress();
                if (!parentContext.mounted) return;
                Navigator.pop(parentContext);
                Navigator.pushNamedAndRemoveUntil(
                  parentContext,
                  '/login',
                  (route) => false,
                );
              } catch (error) {
                if (!parentContext.mounted) return;
                Navigator.pop(parentContext);
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Log out failed. Check your connection and try again.',
                    ),
                  ),
                );
              }
            },
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final ProfileModel profile;

  const _ProfileHero({required this.profile});

  @override
  Widget build(BuildContext context) {
    final name = profile.fullName.trim().isEmpty ? 'Learner' : profile.fullName;
    return Semantics(
      container: true,
      label: '$name, learner profile, ${profile.email}',
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue,
          borderRadius: AppTheme.radiusXl,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withValues(alpha: .22),
              blurRadius: 26,
              offset: const Offset(0, 12),
              spreadRadius: -10,
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Text(
                    name[0].toUpperCase(),
                    style: AppTheme.headlineLarge.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: AppTheme.titleLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        profile.email,
                        style: AppTheme.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: .94),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Divider(color: Colors.white.withValues(alpha: .18)),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'LEARNER ACCOUNT  •  CSS NC II',
                style: AppTheme.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountAction extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;

  const _AccountAction({
    required this.title,
    required this.icon,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppTheme.errorRed : AppTheme.textDark;
    return Semantics(
      button: true,
      label: title,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.bodyMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: destructive ? AppTheme.errorRed : AppTheme.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
