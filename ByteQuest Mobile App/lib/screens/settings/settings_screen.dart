import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/settings_tile.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../services/mission_service.dart';
import '../../services/user_settings_service.dart';
import '../../models/profile_model.dart';

/// Settings screen with profile header
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _isLoading = true;
  bool _savingPreferences = false;
  String? _preferenceError;
  ProfileModel? _profile;
  final _settingsService = UserSettingsService();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUserId;

      if (userId != null) {
        final profileService =
            Provider.of<ProfileService>(context, listen: false);
        final values = await Future.wait<dynamic>([
          profileService.getProfileByUserId(userId),
          _settingsService.getOwnSettings(),
        ]);
        final profile = values[0] as ProfileModel?;
        final settings = values[1] as LearnerSettings;

        if (mounted) {
          setState(() {
            _profile = profile;
            _notificationsEnabled = settings.notificationsEnabled;
            _soundEnabled = settings.soundEnabled;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _savePreferences({bool? notifications, bool? sound}) async {
    final previousNotifications = _notificationsEnabled;
    final previousSound = _soundEnabled;
    setState(() {
      _notificationsEnabled = notifications ?? _notificationsEnabled;
      _soundEnabled = sound ?? _soundEnabled;
      _savingPreferences = true;
      _preferenceError = null;
    });
    try {
      await _settingsService.saveOwnSettings(
        notificationsEnabled: _notificationsEnabled,
        soundEnabled: _soundEnabled,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _notificationsEnabled = previousNotifications;
        _soundEnabled = previousSound;
        _preferenceError = 'Preference could not be saved. Try again.';
      });
    } finally {
      if (mounted) setState(() => _savingPreferences = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundOffWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: AppTheme.headlineMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryBlue, AppTheme.electricBlue],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.white,
                          child: Text(
                            _profile?.fullName[0].toUpperCase() ?? 'U',
                            style: AppTheme.displayLarge.copyWith(
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _profile?.fullName ?? 'User',
                                style: AppTheme.headlineMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _profile?.email ?? '',
                                style: AppTheme.labelMedium.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${_profile?.role ?? "Learner"} account',
                                  style: AppTheme.labelSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Account Section
                  const SettingsSectionHeader(title: 'Account'),
                  SettingsTile(
                    icon: Icons.person_outline,
                    title: 'Profile',
                    subtitle: 'View and edit your profile',
                    iconColor: AppTheme.primaryBlue,
                    onTap: () async {
                      final result =
                          await Navigator.pushNamed(context, '/profile');
                      if (result == true && mounted) {
                        _loadProfile(); // Reload if profile was updated
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  SettingsTile(
                    icon: Icons.edit_outlined,
                    title: 'Edit Profile',
                    subtitle: 'Change your account details',
                    iconColor: AppTheme.accentOrange,
                    onTap: () async {
                      final result =
                          await Navigator.pushNamed(context, '/edit-profile');
                      if (result == true && mounted) {
                        _loadProfile(); // Reload if profile was updated
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  SettingsTile(
                    icon: Icons.lock_outline,
                    title: 'Change Password',
                    subtitle: 'Update your password',
                    iconColor: AppTheme.accentPurple,
                    onTap: () {
                      Navigator.pushNamed(context, '/change-password');
                    },
                  ),

                  // Preferences Section
                  const SettingsSectionHeader(title: 'Preferences'),
                  if (_preferenceError != null) ...[
                    Text(
                      _preferenceError!,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.errorRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  SettingsTile(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    subtitle: 'Push notifications and alerts',
                    iconColor: AppTheme.primaryBlue,
                    trailing: Switch(
                      value: _notificationsEnabled,
                      onChanged: _savingPreferences
                          ? null
                          : (value) => _savePreferences(notifications: value),
                      activeColor: AppTheme.primaryBlue,
                    ),
                    onTap: _savingPreferences
                        ? null
                        : () => _savePreferences(
                            notifications: !_notificationsEnabled),
                  ),
                  const SizedBox(height: 12),
                  SettingsTile(
                    icon: Icons.volume_up_outlined,
                    title: 'Sound Effects',
                    subtitle: 'In-app sounds and audio',
                    iconColor: AppTheme.accentOrange,
                    trailing: Switch(
                      value: _soundEnabled,
                      onChanged: _savingPreferences
                          ? null
                          : (value) => _savePreferences(sound: value),
                      activeColor: AppTheme.primaryBlue,
                    ),
                    onTap: _savingPreferences
                        ? null
                        : () => _savePreferences(sound: !_soundEnabled),
                  ),

                  // Learning & App Section
                  const SettingsSectionHeader(title: 'Learning & App'),
                  SettingsTile(
                    icon: Icons.help_outline,
                    title: 'Help Center',
                    subtitle: 'FAQs and support',
                    iconColor: AppTheme.primaryBlue,
                    onTap: () {
                      Navigator.pushNamed(context, '/help-center');
                    },
                  ),
                  const SizedBox(height: 12),
                  SettingsTile(
                    icon: Icons.info_outline,
                    title: 'About ByteQuest',
                    subtitle: 'Version 1.0.0',
                    iconColor: AppTheme.accentOrange,
                    onTap: () {
                      _showAboutDialog(context);
                    },
                  ),
                  const SizedBox(height: 12),
                  SettingsTile(
                    icon: Icons.description_outlined,
                    title: 'Terms & Privacy',
                    iconColor: AppTheme.textMedium,
                    onTap: () {
                      Navigator.pushNamed(context, '/terms-privacy');
                    },
                  ),
                  const SizedBox(height: 12),
                  SettingsTile(
                    icon: Icons.logout,
                    title: 'Log Out',
                    iconColor: AppTheme.errorRed,
                    isDestructive: true,
                    onTap: () {
                      _showLogoutDialog(context);
                    },
                  ),

                  const SizedBox(height: 80), // Space for bottom nav
                ],
              ),
            ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final parentContext = context;
    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Log Out',
          style: AppTheme.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textMedium),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              // Close dialog
              Navigator.pop(dialogContext);

              // Show loading indicator
              showDialog(
                context: parentContext,
                barrierDismissible: false,
                builder: (loaderContext) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              try {
                // Sign out from Supabase
                final authService =
                    Provider.of<AuthService>(parentContext, listen: false);
                await authService.signOut();

                // Reset local mission progress cache
                final missionService =
                    Provider.of<MissionService>(parentContext, listen: false);
                await missionService.resetProgress();

                // Close loading indicator
                if (parentContext.mounted) {
                  Navigator.pop(parentContext);

                  // Navigate to login screen and clear all previous routes
                  Navigator.pushNamedAndRemoveUntil(
                    parentContext,
                    '/login',
                    (route) => false,
                  );
                }
              } catch (e) {
                // Close loading indicator
                if (parentContext.mounted) {
                  Navigator.pop(parentContext);

                  // Show error message
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(
                      content: Text('Logout failed: ${e.toString()}'),
                      backgroundColor: AppTheme.errorRed,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'About ByteQuest',
          style: AppTheme.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version 1.0.0',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'A Gamified Simulation Platform with Automated Skill Evaluation for NC II Computer Systems Servicing',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textMedium,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
