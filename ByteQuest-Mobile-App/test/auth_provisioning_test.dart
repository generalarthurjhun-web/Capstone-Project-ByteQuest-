import 'package:bytequest/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('confirmation-pending signup never reads or updates profiles', () async {
    var profileReads = 0;
    var profileUpdates = 0;
    var signOuts = 0;
    final user = User.fromJson({
      'id': 'new-learner-id',
      'aud': 'authenticated',
      'role': 'authenticated',
      'email': 'new.learner@example.com',
      'created_at': '2026-08-24T00:00:00.000Z',
      'app_metadata': <String, dynamic>{},
      'user_metadata': <String, dynamic>{'full_name': 'New Learner'},
    })!;

    await verifySignUpProfileProvisioning(
      response: AuthResponse(user: user),
      getProfile: (_) async {
        profileReads++;
        return null;
      },
      updateProfile: (_, __) async {
        profileUpdates++;
      },
      signOut: () async {
        signOuts++;
      },
    );

    expect(profileReads, 0);
    expect(profileUpdates, 0);
    expect(signOuts, 0);
  });
}
