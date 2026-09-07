import 'package:bytequest/core/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('null action renders a visibly disabled control', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppButton.primary(
            label: 'Unavailable action',
            onPressed: null,
          ),
        ),
      ),
    );

    expect(tester.widget<InkWell>(find.byType(InkWell)).onTap, isNull);
  });

  testWidgets('available action remains operable', (tester) async {
    var presses = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton.primary(
            label: 'Available action',
            onPressed: () => presses++,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Available action'));
    expect(presses, 1);
  });
}
