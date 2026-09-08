import 'dart:ui' show SemanticsAction, SemanticsFlag;

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
    final semantics = tester
        .getSemantics(find.bySemanticsLabel('Unavailable action'))
        .getSemanticsData();
    expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue);
    expect(semantics.hasFlag(SemanticsFlag.hasEnabledState), isTrue);
    expect(semantics.hasFlag(SemanticsFlag.isEnabled), isFalse);
    expect(semantics.hasAction(SemanticsAction.tap), isFalse);
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
    final semantics = tester
        .getSemantics(find.bySemanticsLabel('Available action'))
        .getSemanticsData();
    expect(semantics.hasFlag(SemanticsFlag.isEnabled), isTrue);
    expect(semantics.hasAction(SemanticsAction.tap), isTrue);
  });

  testWidgets('small actions retain a 48 dp accessible target', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton.text(
            label: 'Inline action',
            onPressed: () {},
          ),
        ),
      ),
    );

    final size = tester.getSize(find.byType(TextButton));
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
  });
}
