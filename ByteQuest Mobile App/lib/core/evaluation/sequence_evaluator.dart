/// A deterministic comparison between the required procedure and the learner's
/// chronological actions.
class SequenceEvaluation {
  const SequenceEvaluation({
    required this.expected,
    required this.observed,
    required this.correctlyPositioned,
  });

  final List<String> expected;
  final List<String> observed;
  final Set<String> correctlyPositioned;

  bool get isExactMatch {
    if (expected.length != observed.length) return false;

    for (var index = 0; index < expected.length; index++) {
      if (expected[index] != observed[index]) return false;
    }

    return true;
  }

  bool isAtExpectedPosition(String stepId) =>
      correctlyPositioned.contains(stepId);
}

/// Evaluates order from chronological evidence rather than from the final set
/// of selected steps. Optional or unrelated actions are excluded, while
/// repeated required actions remain visible and therefore invalidate an exact
/// sequence match.
SequenceEvaluation evaluateRequiredSequence({
  required List<String> expected,
  required List<String> chronologicalActions,
}) {
  final expectedIds = List<String>.unmodifiable(expected);
  final requiredIds = expectedIds.toSet();
  final observed = List<String>.unmodifiable(
    chronologicalActions.where(requiredIds.contains),
  );
  final correctlyPositioned = <String>{};

  final comparableLength = expectedIds.length < observed.length
      ? expectedIds.length
      : observed.length;
  for (var index = 0; index < comparableLength; index++) {
    if (expectedIds[index] == observed[index]) {
      correctlyPositioned.add(expectedIds[index]);
    }
  }

  return SequenceEvaluation(
    expected: expectedIds,
    observed: observed,
    correctlyPositioned: Set<String>.unmodifiable(correctlyPositioned),
  );
}
