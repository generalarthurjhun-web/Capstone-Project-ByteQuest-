import '../core/config/supabase_config.dart';

class LearnerSettings {
  const LearnerSettings({
    required this.notificationsEnabled,
    required this.soundEnabled,
  });

  final bool notificationsEnabled;
  final bool soundEnabled;
}

class UserSettingsService {
  Future<LearnerSettings> getOwnSettings() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) throw StateError('Authentication required.');
    final row = await SupabaseConfig.client
        .from('user_settings')
        .select('notifications_enabled,sound_enabled')
        .eq('user_id', userId)
        .maybeSingle();
    if (row == null) {
      return const LearnerSettings(
        notificationsEnabled: true,
        soundEnabled: true,
      );
    }
    return LearnerSettings(
      notificationsEnabled: row['notifications_enabled'] as bool? ?? true,
      soundEnabled: row['sound_enabled'] as bool? ?? true,
    );
  }

  Future<void> saveOwnSettings({
    required bool notificationsEnabled,
    required bool soundEnabled,
  }) async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) throw StateError('Authentication required.');
    await SupabaseConfig.client.from('user_settings').upsert({
      'user_id': userId,
      'notifications_enabled': notificationsEnabled,
      'sound_enabled': soundEnabled,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id');
  }
}
