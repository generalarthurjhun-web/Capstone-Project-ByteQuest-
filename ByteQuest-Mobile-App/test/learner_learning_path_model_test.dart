import 'package:flutter_test/flutter_test.dart';
import 'package:bytequest/models/learner_learning_path_model.dart';

void main() {
  test('COC projection counts only trusted released mission states', () {
    LearnerMissionProjection mission(String state, {bool released = false}) =>
        LearnerMissionProjection.fromJson({
          'mission_id': 'mission-$state',
          'mission_code': 'coc2_$state',
          'mission_number': 1,
          'mission_title': 'Mission',
          'assessment_assignment_id':
              state == 'practice_only' ? null : 'assignment-$state',
          'assessment_access_state': state,
          'released': released,
          'bypassed_practice': false,
        });

    final coc = LearnerCocProjection(
      id: 'coc-2',
      code: 'coc2',
      title: 'Set Up Computer Networks',
      description: '',
      order: 2,
      missions: [
        mission('released', released: true),
        mission('in_progress'),
        mission('practice_only'),
      ],
    );

    expect(coc.releasedMissionCount, 1);
    expect(coc.assignedMissionCount, 2);
    expect(coc.activeMissionCount, 1);
    expect(coc.releasedRatio, closeTo(1 / 3, 0.0001));
    expect(coc.lifecycleLabel, 'In progress');
  });

  test('practice-only COC never invents locked or completion state', () {
    final mission = LearnerMissionProjection.fromJson({
      'mission_id': 'mission-1',
      'mission_code': 'coc1_m1',
      'mission_number': 1,
      'mission_title': 'Mission 1',
      'assessment_access_state': 'practice_only',
      'released': false,
      'bypassed_practice': false,
    });
    final coc = LearnerCocProjection(
      id: 'coc-1',
      code: 'coc1',
      title: 'Install and Configure Computer Systems',
      description: '',
      order: 1,
      missions: [mission],
    );

    expect(coc.lifecycleLabel, 'Practice available');
    expect(coc.releasedMissionCount, 0);
    expect(coc.releasedRatio, 0);
  });
}
