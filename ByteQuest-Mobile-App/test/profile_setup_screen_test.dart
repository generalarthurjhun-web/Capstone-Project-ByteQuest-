import 'package:bytequest/screens/profile_setup/profile_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-publishable-key',
    );
  });

  test('sign-up metadata resolves to a trimmed profile name', () {
    expect(
      resolveProfileSetupFullName({'full_name': '  Maria Santos  '}),
      'Maria Santos',
    );
    expect(resolveProfileSetupFullName({'full_name': '   '}), isNull);
    expect(resolveProfileSetupFullName(null), isNull);
  });

  testWidgets('section or set is a free-text field, not a dropdown',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ProfileSetupScreen()),
    );

    final sectionField = find.byKey(const Key('profileSetupSectionField'));
    expect(sectionField, findsOneWidget);
    expect(
      find.widgetWithText(
        DropdownButtonFormField<String>,
        'Select your section',
      ),
      findsNothing,
    );

    await tester.ensureVisible(sectionField);
    await tester.enterText(sectionField, 'CSS NC II - Set B');
    expect(find.text('CSS NC II - Set B'), findsOneWidget);
  });
}
