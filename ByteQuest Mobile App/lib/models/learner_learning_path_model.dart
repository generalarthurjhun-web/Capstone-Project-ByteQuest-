class LearnerMissionProjection {
  const LearnerMissionProjection({
    required this.id,
    required this.code,
    required this.number,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.estimatedMinutes,
    required this.accessState,
    required this.released,
    required this.bypassedPractice,
    this.assignmentId,
    this.latestAttemptId,
    this.latestAttemptStatus,
    this.releasedOutcome,
  });

  final String id;
  final String code;
  final int number;
  final String title;
  final String description;
  final String difficulty;
  final int estimatedMinutes;
  final String accessState;
  final bool released;
  final bool bypassedPractice;
  final String? assignmentId;
  final String? latestAttemptId;
  final String? latestAttemptStatus;
  final String? releasedOutcome;

  bool get isAssigned => assignmentId != null;
  bool get isAwaitingInstructor => accessState == 'awaiting_release';
  bool get isInProgress => accessState == 'in_progress';

  factory LearnerMissionProjection.fromJson(Map<String, dynamic> json) {
    return LearnerMissionProjection(
      id: json['mission_id'] as String,
      code: json['mission_code'] as String? ?? '',
      number: json['mission_number'] as int? ?? 0,
      title: json['mission_title'] as String? ?? 'Mission',
      description: json['mission_description'] as String? ?? '',
      difficulty: json['mission_difficulty'] as String? ?? 'beginner',
      estimatedMinutes: json['estimated_time_minutes'] as int? ?? 10,
      accessState:
          json['assessment_access_state'] as String? ?? 'practice_only',
      released: json['released'] as bool? ?? false,
      bypassedPractice: json['bypassed_practice'] as bool? ?? false,
      assignmentId: json['assessment_assignment_id'] as String?,
      latestAttemptId: json['latest_attempt_id'] as String?,
      latestAttemptStatus: json['latest_attempt_status'] as String?,
      releasedOutcome: json['released_outcome'] as String?,
    );
  }
}

class LearnerCocProjection {
  const LearnerCocProjection({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.order,
    required this.missions,
  });

  final String id;
  final String code;
  final String title;
  final String description;
  final int order;
  final List<LearnerMissionProjection> missions;

  int get releasedMissionCount =>
      missions.where((mission) => mission.released).length;
  int get assignedMissionCount =>
      missions.where((mission) => mission.isAssigned).length;
  int get activeMissionCount => missions
      .where((mission) => mission.isInProgress || mission.isAwaitingInstructor)
      .length;
  double get releasedRatio =>
      missions.isEmpty ? 0 : releasedMissionCount / missions.length;

  String get lifecycleLabel {
    if (missions.isNotEmpty && releasedMissionCount == missions.length) {
      return 'All results released';
    }
    if (activeMissionCount > 0 || releasedMissionCount > 0) {
      return 'In progress';
    }
    if (assignedMissionCount > 0) return 'Assigned';
    return 'Practice available';
  }
}
