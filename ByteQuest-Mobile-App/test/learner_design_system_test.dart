import 'package:bytequest/core/theme/app_theme.dart';
import 'package:bytequest/core/widgets/learner_ui.dart';
import 'package:bytequest/widgets/bytequest_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ByteQuest typography exposes one Tarsi-inspired role scale', () {
    final theme = AppTheme.lightTheme;
    final text = theme.textTheme;

    expect(text.displayMedium?.fontSize, 28);
    expect(text.headlineMedium?.fontSize, 20);
    expect(text.titleMedium?.fontSize, 16);
    expect(text.bodyMedium?.fontSize, 15);
    expect(text.labelSmall?.fontSize, 12);
    expect(text.displayMedium?.fontWeight, FontWeight.bold);
    expect(text.titleMedium?.fontWeight, FontWeight.w600);
  });

  testWidgets('learner navigation remains usable at 320 logical pixels',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var selected = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: const SizedBox.expand(),
            bottomNavigationBar: ByteQuestBottomNav(
              currentIndex: selected,
              onTap: (value) => setState(() => selected = value),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Learn'), findsOneWidget);
    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('Rewards'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Progress'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(selected, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('learner state view supports large text without overflow',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: Scaffold(
            body: LearnerStateView(
              icon: Icons.route_outlined,
              title: 'No learning path yet',
              message:
                  'Published competency modules will appear here when they are available.',
            ),
          ),
        ),
      ),
    );

    expect(find.text('No learning path yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('progress bar exposes an accessible percentage', (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Center(
            child: LearnerProgressBar(
              value: .4,
              semanticLabel: 'Practice progress',
            ),
          ),
        ),
      ),
    );

    expect(
      find.bySemanticsLabel(RegExp('Practice progress')),
      findsOneWidget,
    );
    semantics.dispose();
  });
}
