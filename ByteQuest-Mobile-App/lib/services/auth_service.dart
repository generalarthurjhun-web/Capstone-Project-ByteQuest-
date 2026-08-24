import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../models/profile_model.dart';
import 'profile_service.dart';

Future<void> verifySignUpProfileProvisioning({
  required AuthResponse response,
  required Future<ProfileModel?> Function(String userId) getProfile,
  required Future<void> Function(
    String userId,
    Map<String, dynamic> updates,
  ) updateProfile,
  required Future<void> Function() signOut,
  String? learnerId,
  String? school,
  String? courseSection,
}) async {
  if (response.session == null) return;

  await Future.delayed(const Duration(milliseconds: 500));
  final existingProfile = await getProfile(response.user!.id);

  if (existingProfile == null) {
    await signOut();
    throw Exception(
      'Account provisioning is incomplete. Contact an Administrator.',
    );
  }
  if (learnerId != null || school != null || courseSection != null) {
    await updateProfile(response.user!.id, {
      if (learnerId != null) 'learner_id': learnerId,
      if (school != null) 'school': school,
      if (courseSection != null) 'course_section': courseSection,
    });
  }
}

/// Authentication Service
/// Handles user authentication with Supabase Auth
class AuthService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final ProfileService _profileService = ProfileService();

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  /// Get current user
  User? get currentUser => _supabase.auth.currentUser;

  /// Get current user ID
  String? get currentUserId => currentUser?.id;

  /// Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  /// Get auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String? learnerId,
    String? school,
    String? courseSection,
  }) async {
    try {
      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'email': email,
        },
      );

      if (response.user == null) {
        throw Exception('Sign up failed: No user returned');
      }

      await verifySignUpProfileProvisioning(
        response: response,
        getProfile: _profileService.getProfileByUserId,
        updateProfile: _profileService.updateProfile,
        signOut: _supabase.auth.signOut,
        learnerId: learnerId,
        school: school,
        courseSection: courseSection,
      );

      return response;
    } on AuthException catch (e) {
      throw Exception('Sign up failed: ${e.message}');
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Sign in failed: No user returned');
      }

      final profile =
          await _profileService.getProfileByUserId(response.user!.id);
      if (profile == null) {
        await _supabase.auth.signOut();
        throw Exception(
            'Account profile is missing. Contact an Administrator.');
      }
      if (profile.status != 'active') {
        await _supabase.auth.signOut();
        throw Exception(
            'Account is not active. Contact your Instructor or Administrator.');
      }
      if (profile.role != 'learner') {
        await _supabase.auth.signOut();
        throw Exception(
            'This mobile application is available to Learner accounts only.');
      }

      return response;
    } on AuthException catch (e) {
      throw Exception('Sign in failed: ${e.message}');
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw Exception('Password reset failed: ${e.message}');
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  /// Get current user profile
  Future<ProfileModel?> getCurrentProfile() async {
    if (!isLoggedIn) return null;
    return await _profileService.getProfileByUserId(currentUserId!);
  }

  /// Check if account is active
  Future<bool> isAccountActive() async {
    if (!isLoggedIn) return false;
    final profile = await getCurrentProfile();
    return profile != null &&
        profile.status == 'active' &&
        profile.role == 'learner';
  }

  /// Check if user data is initialized
  Future<bool> isUserInitialized() async {
    if (!isLoggedIn) return false;
    return await isAccountActive();
  }

  /// Get initialization status
  Future<Map<String, dynamic>> getInitializationStatus() async {
    if (!isLoggedIn) {
      return {'initialized': false, 'error': 'Not logged in'};
    }
    final profile = await getCurrentProfile();
    return {
      'initialized': profile != null,
      'active': profile?.status == 'active',
      'role': profile?.role,
    };
  }
}
