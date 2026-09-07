import 'package:bytequest/screens/simulation/practice_option_order.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const options = [
    'Correct answer',
    'Distractor A',
    'Distractor B',
    'Distractor C'
  ];

  test('four-choice answers are shuffled without changing their values', () {
    final order = PracticeOptionOrder.create(
      sourceOptions: const {'question-1': options},
      seed: 7,
    );

    final shuffled = order.optionsFor('question-1', options);
    expect(shuffled, isNot(options));
    expect(shuffled.toSet(), options.toSet());
    expect(shuffled, contains('Correct answer'));
  });

  test('the correct answer can occupy different positions', () {
    final positions = <int>{
      for (var seed = 1; seed <= 12; seed++)
        PracticeOptionOrder.create(
          sourceOptions: const {'question-1': options},
          seed: seed,
        ).optionsFor('question-1', options).indexOf('Correct answer'),
    };

    expect(positions.length, greaterThan(1));
  });

  test('serialized answer order restores the exact learner mapping', () {
    final initial = PracticeOptionOrder.create(
      sourceOptions: const {'question-1': options},
      seed: 11,
    );
    final restored = PracticeOptionOrder.fromJson(
      initial.toJson(),
      sourceOptions: const {'question-1': options},
    );

    expect(
      restored.optionsFor('question-1', options),
      initial.optionsFor('question-1', options),
    );
  });

  test('stale saved mappings are safely rebuilt from current content', () {
    final restored = PracticeOptionOrder.fromJson(
      const {
        'seed': 4,
        'orders': {
          'question-1': ['Old A', 'Old B', 'Old C', 'Old D'],
        },
      },
      sourceOptions: const {'question-1': options},
    );

    expect(restored.optionsFor('question-1', options).toSet(), options.toSet());
  });
}
