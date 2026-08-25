import 'package:bytequest/core/theme/app_theme.dart';
import 'package:bytequest/models/learner_quiz_model.dart';
import 'package:bytequest/screens/quizzes/quiz_taking_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'sb_publishable_quiz_test_key',
    );
  });

  test('quiz summary maps authoritative lifecycle states', () {
    LearnerQuizSummary summary(String? status, {bool available = true}) =>
        LearnerQuizSummary.fromJson({
          'assignment_id': 'assignment',
          'quiz_version_id': 'version',
          'quiz_id': 'quiz',
          'title': 'Networking review',
          'topic': 'Networks',
          'class_id': 'class',
          'class_title': 'CSS NC II',
          'question_count': 4,
          'is_available': available,
          'attempt_status': status,
        });

    expect(summary(null).state, LearnerQuizState.available);
    expect(summary('in_progress').state, LearnerQuizState.inProgress);
    expect(summary('submitted').state, LearnerQuizState.submitted);
    expect(summary('completed').state, LearnerQuizState.completed);
    expect(summary(null, available: false).state, LearnerQuizState.unavailable);
  });

  test('learner question contract contains no answer key field', () {
    const payload = {
      'id': 'item',
      'code': 'Q1',
      'type': 'multiple_choice',
      'prompt': 'Choose the network device.',
      'options': ['Router', 'Keyboard'],
      'order_index': 1,
      'saved_answer': 'Router',
      'correct_answer': 'secret answer',
    };
    final question = LearnerQuizQuestion.fromJson(payload);

    expect(question.savedAnswer, 'Router');
    expect(question.options, isNot(contains('secret answer')));
  });

  for (final fixture in <({String type, List<String> options, String label})>[
    (
      type: 'multiple_choice',
      options: const ['Router', 'Switch'],
      label: 'Multiple choice'
    ),
    (type: 'true_false', options: const [], label: 'True or false'),
    (type: 'identification', options: const [], label: 'Identification'),
    (
      type: 'scenario_based',
      options: const ['Inspect cable', 'Restart server'],
      label: 'Scenario question'
    ),
  ]) {
    testWidgets('${fixture.type} renders without exposing an answer key',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: QuizTakingScreen(
            attempt: _attemptFor(fixture.type, fixture.options),
          ),
        ),
      );

      expect(find.text(fixture.label.toUpperCase()), findsOneWidget);
      expect(find.text('Question 1 of 1'), findsOneWidget);
      expect(find.text('secret answer'), findsNothing);
      if (fixture.type == 'identification') {
        expect(find.byType(TextField), findsOneWidget);
      } else if (fixture.type == 'true_false') {
        expect(find.text('True'), findsOneWidget);
        expect(find.text('False'), findsOneWidget);
      } else {
        expect(find.text(fixture.options.first), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('quiz choices shuffle deterministically across restoration',
      (tester) async {
    const source = ['Correct', 'Distractor A', 'Distractor B', 'Distractor C'];
    final attempt = _attemptFor('scenario_based', source);

    Future<List<String>> visibleOrder() async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: QuizTakingScreen(attempt: attempt),
        ),
      );
      await tester.pump();
      return [...source]..sort((left, right) => tester
          .getTopLeft(find.text(left))
          .dy
          .compareTo(tester.getTopLeft(find.text(right)).dy));
    }

    final first = await visibleOrder();
    expect(first, isNot(source));
    expect(first.toSet(), source.toSet());

    await tester.pumpWidget(const SizedBox.shrink());
    final restored = await visibleOrder();
    expect(restored, first);
    expect(restored, contains('Correct'));
  });
}

LearnerQuizAttempt _attemptFor(String type, List<String> options) =>
    LearnerQuizAttempt(
      attemptId: 'attempt',
      status: 'in_progress',
      startedAt: DateTime.utc(2026, 8, 12),
      assignmentId: 'assignment',
      title: 'Networking quiz',
      description: null,
      topic: 'Networks',
      instructions: null,
      classTitle: 'CSS NC II',
      versionNumber: 1,
      questions: [
        LearnerQuizQuestion(
          id: 'item',
          code: 'Q1',
          type: type,
          prompt: 'Select or enter the best response.',
          options: options,
          orderIndex: 1,
        ),
      ],
    );
