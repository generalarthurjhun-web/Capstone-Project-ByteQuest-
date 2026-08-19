/// Mobile interaction contract for the published COC2 cable-termination
/// assessment. These identifiers are evidence event values, not scores.
abstract final class Coc2CableAssessmentContract {
  static const packageId = 'coc2-cable-termination-testing-v1';

  static const ppeRequired = <String>{
    'gloves',
    'goggles',
    'working_clothes',
  };
  static const toolsRequired = <String>{
    'copper_cable',
    'rj45_connector',
    'wire_stripper',
    'crimping_tool',
    'lan_cable_tester',
  };
  static const cablePreparationOrder = <String>[
    'measure_cable',
    'strip_jacket',
    'untwist_and_straighten',
  ];
  static const t568bOrder = <String>[
    'white_orange',
    'orange',
    'white_green',
    'blue',
    'white_blue',
    'green',
    'white_brown',
    'brown',
  ];
  static const terminationOrder = <String>[
    'insert_conductors',
    'verify_jacket_depth',
    'crimp_connector',
  ];
  static const testerOrder = <String>[
    'connect_both_ends',
    'power_on_tester',
    'observe_indicator_sequence',
  ];
  static const inspectionRequired = <String>{
    'no_visible_damage',
    'pin_order_compliant',
    'connector_secure',
  };
  static const cleanupRequired = <String>{
    'tools_returned',
    'work_area_cleared',
    'scraps_sorted',
  };

  static bool hasSelectionCount(Set<String> selected, int count) =>
      selected.length == count;
}
