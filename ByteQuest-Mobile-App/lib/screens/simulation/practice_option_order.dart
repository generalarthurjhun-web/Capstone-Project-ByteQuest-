import 'dart:math';

/// Owns learner-visible option order without changing option values.
///
/// Legacy practice screens persist [toJson] with their local resume state so
/// process recreation cannot remap an answer after it has been shown.
final class PracticeOptionOrder {
  PracticeOptionOrder._({required this.seed, required this.orders});

  factory PracticeOptionOrder.create({
    required Map<String, List<String>> sourceOptions,
    required int seed,
  }) {
    return PracticeOptionOrder._(
      seed: seed,
      orders: {
        for (final entry in sourceOptions.entries)
          entry.key: _shuffle(entry.value, _mixedSeed(seed, entry.key)),
      },
    );
  }

  factory PracticeOptionOrder.fromJson(
    Map<String, dynamic>? json, {
    required Map<String, List<String>> sourceOptions,
    int fallbackSeed = 0,
  }) {
    final seed = (json?['seed'] as num?)?.toInt() ?? fallbackSeed;
    final saved = Map<String, dynamic>.from(
      json?['orders'] as Map? ?? const <String, dynamic>{},
    );
    final rebuilt = PracticeOptionOrder.create(
      sourceOptions: sourceOptions,
      seed: seed,
    );
    final orders = <String, List<String>>{};
    for (final entry in sourceOptions.entries) {
      final candidate = List<String>.from(
        saved[entry.key] as List? ?? const <String>[],
      );
      orders[entry.key] = _sameValues(candidate, entry.value)
          ? List<String>.unmodifiable(candidate)
          : rebuilt.orders[entry.key]!;
    }
    return PracticeOptionOrder._(seed: seed, orders: orders);
  }

  final int seed;
  final Map<String, List<String>> orders;

  List<String> optionsFor(String key, List<String> fallback) =>
      orders[key] ?? List<String>.unmodifiable(fallback);

  Map<String, dynamic> toJson() => {
        'seed': seed,
        'orders': {
          for (final entry in orders.entries)
            entry.key: List<String>.from(entry.value),
        },
      };

  static int stableSeed(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  static List<String> _shuffle(List<String> source, int seed) {
    final shuffled = List<String>.from(source)..shuffle(Random(seed));
    if (source.length > 1 && _sameOrder(shuffled, source)) {
      final offset = 1 + seed.abs() % (source.length - 1);
      return List<String>.unmodifiable([
        ...source.skip(offset),
        ...source.take(offset),
      ]);
    }
    return List<String>.unmodifiable(shuffled);
  }

  static int _mixedSeed(int seed, String key) =>
      (seed ^ stableSeed(key)) & 0x7fffffff;

  static bool _sameValues(List<String> left, List<String> right) =>
      left.length == right.length &&
      left.toSet().length == left.length &&
      left.toSet().containsAll(right);

  static bool _sameOrder(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }
}
