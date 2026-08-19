import 'package:flutter_test/flutter_test.dart';

import 'package:bytequest/screens/simulation/templates/authoritative_mission_contract.dart';

void main() {
  Map<String, dynamic> payload({
    List<Map<String, dynamic>>? stages,
  }) =>
      {
        'simulation_template': 'authoritative_mission_v1',
        'assessment_package_id': 'coc1_m1_v1',
        'local_mission_code': 'COC1_M1',
        'unit_code': 'ELC724331',
        'unit_title': 'Install and Configure Computer Systems',
        'stages': stages ??
            [
              {
                'id': 'coc1_m1_01',
                'criterion_code': 'COC1_M1_01',
                'type': 'sequence',
                'title': 'Plan the work',
                'instruction': 'Select each step in chronological order.',
                'action_type': 'work_plan_step_selected',
                'required_count': 3,
                'options': [
                  {'id': 'inspect', 'label': 'Inspect the work order'},
                  {'id': 'prepare', 'label': 'Prepare the work area'},
                  {'id': 'verify', 'label': 'Verify the plan'},
                ],
              },
            ],
      };

  group('authoritative mission learner contract', () {
    test('parses a complete chronological assessment stage', () {
      final contract =
          AuthoritativeMissionContract.fromLearnerPayload(payload());

      expect(contract.localMissionCode, 'COC1_M1');
      expect(contract.stages, hasLength(1));
      expect(contract.stages.single.type, AuthoritativeStageType.sequence);
      expect(contract.stages.single.requiredCount, 3);
    });

    test('supports selection, choice, configuration, and matching stages', () {
      final optionList = [
        {'id': 'a', 'label': 'Option A'},
        {'id': 'b', 'label': 'Option B'},
      ];
      final fieldList = [
        {
          'id': 'mode',
          'label': 'Mode',
          'options': optionList,
        },
      ];
      final contract = AuthoritativeMissionContract.fromLearnerPayload(
        payload(stages: [
          {
            'id': 'selection',
            'criterion_code': 'C01',
            'type': 'selection',
            'title': 'Select',
            'instruction': 'Select required items.',
            'action_type': 'items_selected',
            'required_count': 1,
            'options': optionList,
          },
          {
            'id': 'choice',
            'criterion_code': 'C02',
            'type': 'single_choice',
            'title': 'Choose',
            'instruction': 'Choose one observation.',
            'action_type': 'observation_selected',
            'required_count': 1,
            'options': optionList,
          },
          {
            'id': 'configuration',
            'criterion_code': 'C03',
            'type': 'configuration',
            'title': 'Configure',
            'instruction': 'Configure the field.',
            'action_type': 'configuration_submitted',
            'required_count': 1,
            'fields': fieldList,
          },
          {
            'id': 'matching',
            'criterion_code': 'C04',
            'type': 'matching',
            'title': 'Match',
            'instruction': 'Match the item.',
            'action_type': 'matching_submitted',
            'required_count': 1,
            'fields': fieldList,
          },
        ]),
      );

      expect(
        contract.stages.map((stage) => stage.type),
        containsAll(<AuthoritativeStageType>{
          AuthoritativeStageType.selection,
          AuthoritativeStageType.singleChoice,
          AuthoritativeStageType.configuration,
          AuthoritativeStageType.matching,
        }),
      );
    });

    test('rejects authoritative answers in learner-visible stage data', () {
      final leakedStage = Map<String, dynamic>.from(payload()['stages'][0])
        ..['expected'] = ['inspect', 'prepare', 'verify'];

      expect(
        () => AuthoritativeMissionContract.fromLearnerPayload(
          payload(stages: [leakedStage]),
        ),
        throwsFormatException,
      );
    });

    test('rejects duplicate stage and criterion identities', () {
      final stage = Map<String, dynamic>.from(payload()['stages'][0] as Map);

      expect(
        () => AuthoritativeMissionContract.fromLearnerPayload(
          payload(stages: [stage, Map<String, dynamic>.from(stage)]),
        ),
        throwsFormatException,
      );
    });

    test('rejects incomplete configuration fields', () {
      expect(
        () => AuthoritativeMissionContract.fromLearnerPayload(
          payload(stages: [
            {
              'id': 'configuration',
              'criterion_code': 'C01',
              'type': 'configuration',
              'title': 'Configure',
              'instruction': 'Configure both fields.',
              'action_type': 'configuration_submitted',
              'required_count': 2,
              'fields': [
                {
                  'id': 'one',
                  'label': 'Only field',
                  'options': [
                    {'id': 'a', 'label': 'A'},
                  ],
                },
              ],
            },
          ]),
        ),
        throwsFormatException,
      );
    });
  });
}
