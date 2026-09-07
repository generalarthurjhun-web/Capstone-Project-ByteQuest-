import 'package:bytequest/core/theme/app_theme.dart';
import 'package:bytequest/models/learning_resource_model.dart';
import 'package:bytequest/screens/resources/resource_viewer_screen.dart';
import 'package:bytequest/services/learning_resource_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'sb_publishable_resource_viewer_test_key',
    );
  });

  testWidgets('text resources render inside the ByteQuest viewer',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: ResourceViewerScreen(
          resource: _resource(mimeType: 'text/plain'),
          service: _FakeLearningResourceService(
            text: 'Network safety procedure notes',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Network safety procedure notes'), findsOneWidget);
    expect(find.text('Resource could not be loaded'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PDF resources show an authorized external-open prompt',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: ResourceViewerScreen(
          resource: _resource(mimeType: 'application/pdf'),
          service: _FakeLearningResourceService(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('PDF resource'), findsOneWidget);
    expect(find.text('Open PDF'), findsOneWidget);
    expect(find.byIcon(Icons.open_in_new_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('resource loading errors show a retry state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: ResourceViewerScreen(
          resource: _resource(mimeType: 'image/png'),
          service: _FailingLearningResourceService(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Resource could not be loaded'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

LearningResource _resource({required String mimeType}) => LearningResource(
      id: 'resource-1',
      classId: 'class-1',
      classTitle: 'CSS NC II',
      title: 'Cable testing guide',
      description: 'Instructor shared resource',
      storageBucket: 'learning-resources',
      storagePath: 'class-1/cable-testing-guide',
      mimeType: mimeType,
      sizeBytes: 2048,
      createdAt: DateTime.utc(2026, 8, 13),
    );

class _FakeLearningResourceService extends LearningResourceService {
  final String text;
  bool opened = false;

  _FakeLearningResourceService({this.text = ''});

  @override
  Future<String> createSignedUrl(
    LearningResource resource, {
    int expiresInSeconds = 300,
  }) async =>
      'https://example.test/signed-resource';

  @override
  Future<String> loadTextResource(LearningResource resource) async => text;

  @override
  Future<void> openSignedUrl(String signedUrl) async {
    opened = true;
  }
}

class _FailingLearningResourceService extends LearningResourceService {
  @override
  Future<String> createSignedUrl(
    LearningResource resource, {
    int expiresInSeconds = 300,
  }) async {
    throw StateError('signed URL unavailable');
  }
}
