import 'package:bytequest/core/evaluation/sequence_evaluator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('evaluateRequiredSequence', () {
    const expected = ['A', 'B', 'C'];

    test('accepts the exact chronological procedure', () {
      final result = evaluateRequiredSequence(
        expected: expected,
        chronologicalActions: const ['A', 'B', 'C'],
      );

      expect(result.isExactMatch, isTrue);
      expect(result.correctlyPositioned, {'A', 'B', 'C'});
    });

    test('rejects the same final set when actions are out of order', () {
      final result = evaluateRequiredSequence(
        expected: expected,
        chronologicalActions: const ['B', 'A', 'C'],
      );

      expect(result.isExactMatch, isFalse);
      expect(result.observed, ['B', 'A', 'C']);
      expect(result.correctlyPositioned, {'C'});
    });

    test('ignores optional actions but preserves duplicate required actions',
        () {
      final withOptionalAction = evaluateRequiredSequence(
        expected: expected,
        chronologicalActions: const ['A', 'optional', 'B', 'C'],
      );
      final withDuplicateRequiredAction = evaluateRequiredSequence(
        expected: expected,
        chronologicalActions: const ['A', 'B', 'B', 'C'],
      );

      expect(withOptionalAction.isExactMatch, isTrue);
      expect(withOptionalAction.observed, expected);
      expect(withDuplicateRequiredAction.isExactMatch, isFalse);
      expect(withDuplicateRequiredAction.observed, ['A', 'B', 'B', 'C']);
    });

    test('rejects incomplete evidence', () {
      final result = evaluateRequiredSequence(
        expected: expected,
        chronologicalActions: const ['A', 'B'],
      );

      expect(result.isExactMatch, isFalse);
      expect(result.correctlyPositioned, {'A', 'B'});
    });
  });
}
