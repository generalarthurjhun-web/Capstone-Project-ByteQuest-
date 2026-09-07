// ByteQuest widget test
//
// This test verifies that the ByteQuest app launches correctly
// and the splash screen is displayed.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bytequest/main.dart';

void main() {
  testWidgets('ByteQuest app launches successfully',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ByteQuestApp());

    // Wait for splash screen to load
    await tester.pump();

    // Verify that the app contains a MaterialApp widget
    expect(find.byType(MaterialApp), findsOneWidget);

    // Verify that the app title is 'ByteQuest'
    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.title, 'ByteQuest');

    // Verify debugShowCheckedModeBanner is false
    expect(app.debugShowCheckedModeBanner, false);
  });

  testWidgets('ByteQuest splash screen displays', (WidgetTester tester) async {
    // Build our app
    await tester.pumpWidget(const ByteQuestApp());

    // Pump a frame
    await tester.pump();

    // Verify that we're on the splash screen (initial route '/')
    // The splash screen should be the first screen shown
    expect(find.byType(Scaffold), findsWidgets);
  });
}
