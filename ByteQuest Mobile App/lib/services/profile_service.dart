import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../models/profile_model.dart';

/// Read access to the trusted profile plus a narrowly allow-listed learner
/// self-service update path. Role, status, and gamification projections are
/// never accepted from the mobile client.
class ProfileService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  static const _editableFields = {
    'full_name',
    'avatar_url',
    'learner_id',
    'school',
    'course_section',
  };

  Future<ProfileModel?> getProfileByUserId(String userId) async {
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    return response == null ? null : ProfileModel.fromJson(response);
  }

  Future<ProfileModel?> getProfile(String userId) => getProfileByUserId(userId);

  /// Completes a profile created by the trusted auth trigger. It never creates
  /// an application identity or assigns a role from the learner client.
  Future<ProfileModel> createProfile({
    required String userId,
    required String fullName,
    required String email,
    String? learnerId,
    String? school,
    String? courseSection,
    String? avatarUrl,
  }) async {
    final existing = await getProfileByUserId(userId);
    if (existing == null) {
      throw StateError(
        'Account provisioning is incomplete. Contact an Administrator.',
      );
    }

    await updateProfile(userId, {
      'full_name': fullName,
      if (learnerId != null) 'learner_id': learnerId,
      if (school != null) 'school': school,
      if (courseSection != null) 'course_section': courseSection,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    });
    final updated = await getProfileByUserId(userId);
    if (updated == null)
      throw StateError('Profile update could not be verified.');
    return updated;
  }

  Future<void> updateProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    final rejected = updates.keys
        .where((key) => !_editableFields.contains(key))
        .toList(growable: false);
    if (rejected.isNotEmpty) {
      throw ArgumentError(
        'Protected profile fields cannot be changed by the learner: ${rejected.join(', ')}',
      );
    }
    if (updates.isEmpty) return;

    await _supabase.from('profiles').update(updates).eq('user_id', userId);
  }
}
