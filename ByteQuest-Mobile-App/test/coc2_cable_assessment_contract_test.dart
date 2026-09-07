import 'package:flutter_test/flutter_test.dart';

import 'package:bytequest/screens/simulation/templates/coc2_cable_assessment_contract.dart';

void main() {
  group('COC2 cable assessment evidence contract', () {
    test('preserves the approved chronological T568B conductor order', () {
      expect(
        Coc2CableAssessmentContract.t568bOrder,
        const [
          'white_orange',
          'orange',
          'white_green',
          'blue',
          'white_blue',
          'green',
          'white_brown',
          'brown',
        ],
      );
      expect(
        Coc2CableAssessmentContract.t568bOrder.toSet().length,
        Coc2CableAssessmentContract.t568bOrder.length,
      );
    });

    test('keeps procedure evidence as ordered actions', () {
      expect(
        Coc2CableAssessmentContract.cablePreparationOrder,
        const ['measure_cable', 'strip_jacket', 'untwist_and_straighten'],
      );
      expect(
        Coc2CableAssessmentContract.terminationOrder,
        const ['insert_conductors', 'verify_jacket_depth', 'crimp_connector'],
      );
      expect(
        Coc2CableAssessmentContract.testerOrder,
        const [
          'connect_both_ends',
          'power_on_tester',
          'observe_indicator_sequence',
        ],
      );
    });

    test('defines complete preparation, inspection, and cleanup sets', () {
      expect(Coc2CableAssessmentContract.ppeRequired.length, 3);
      expect(Coc2CableAssessmentContract.toolsRequired.length, 5);
      expect(Coc2CableAssessmentContract.inspectionRequired.length, 3);
      expect(Coc2CableAssessmentContract.cleanupRequired.length, 3);
      expect(
        Coc2CableAssessmentContract.hasSelectionCount(
          Coc2CableAssessmentContract.toolsRequired,
          5,
        ),
        isTrue,
      );
    });
  });
}
