import 'package:bytequest/data/mission_simulation_definitions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('catalog covers every COC mission with required phase depth', () {
    final definitions = MissionSimulationDefinitions.all;

    expect(definitions, hasLength(20));
    expect(definitions.map((item) => item.id).toSet(), hasLength(20));

    for (final definition in definitions) {
      expect(
        definition.phases.length,
        inInclusiveRange(3, 6),
        reason: definition.id,
      );
      expect(
        definition.interactionFamilies.length,
        inInclusiveRange(2, 4),
        reason: definition.id,
      );
      expect(definition.hasTechnicalDecision, isTrue, reason: definition.id);
      expect(definition.hasVerification, isTrue, reason: definition.id);
    }
  });
}
