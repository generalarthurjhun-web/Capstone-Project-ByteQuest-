class AssignedActivity {
  final String id;
  final String classId;
  final String classTitle;
  final String activityVersionId;
  final String? rubricVersionId;
  final String assignmentType;
  final String title;
  final String? instructions;
  final DateTime? availableAt;
  final DateTime? dueAt;
  final String activityTitle;
  final String deliveryMode;
  final Map<String, dynamic> learnerPayload;
  final String missionId;
  final String missionCode;

  const AssignedActivity({
    required this.id,
    required this.classId,
    required this.classTitle,
    required this.activityVersionId,
    required this.rubricVersionId,
    required this.assignmentType,
    required this.title,
    required this.instructions,
    required this.availableAt,
    required this.dueAt,
    required this.activityTitle,
    required this.deliveryMode,
    required this.learnerPayload,
    required this.missionId,
    required this.missionCode,
  });

  bool get isAssessment => assignmentType == 'assessment';
  bool get isBypassAccess => assignmentType == 'bypass_practice';

  factory AssignedActivity.fromJson(Map<String, dynamic> json) {
    final activity = Map<String, dynamic>.from(
        json['activity_versions'] as Map? ?? const {});
    final mission =
        Map<String, dynamic>.from(activity['missions'] as Map? ?? const {});
    final classroom =
        Map<String, dynamic>.from(json['classes'] as Map? ?? const {});
    return AssignedActivity(
      id: json['id'] as String,
      classId: json['class_id'] as String,
      classTitle: classroom['title'] as String? ?? 'Assigned class',
      activityVersionId: json['activity_version_id'] as String,
      rubricVersionId: json['rubric_version_id'] as String?,
      assignmentType: json['assignment_type'] as String? ?? 'practice',
      title: json['title'] as String? ?? 'Assigned activity',
      instructions: json['instructions'] as String?,
      availableAt: json['available_at'] == null
          ? null
          : DateTime.parse(json['available_at'] as String),
      dueAt: json['due_at'] == null
          ? null
          : DateTime.parse(json['due_at'] as String),
      activityTitle: activity['title'] as String? ?? 'Versioned activity',
      deliveryMode: activity['delivery_mode'] as String? ?? 'practice',
      learnerPayload: Map<String, dynamic>.from(
          activity['learner_payload'] as Map? ?? const {}),
      missionId: mission['id'] as String? ?? '',
      missionCode: mission['mission_code'] as String? ?? '',
    );
  }

  factory AssignedActivity.fromBypassJson(Map<String, dynamic> json) {
    return AssignedActivity(
      id: 'bypass:${json['bypass_id']}:${json['activity_version_id']}',
      classId: json['class_id'] as String,
      classTitle: json['class_title'] as String? ?? 'Assigned class',
      activityVersionId: json['activity_version_id'] as String,
      rubricVersionId: null,
      assignmentType: 'bypass_practice',
      title: json['activity_title'] as String? ?? 'Unlocked practice',
      instructions: json['instructions'] as String? ??
          'Unlocked by your Instructor for practice access only.',
      availableAt: null,
      dueAt: null,
      activityTitle: json['activity_title'] as String? ?? 'Versioned activity',
      deliveryMode: 'practice',
      learnerPayload: Map<String, dynamic>.from(
          json['learner_payload'] as Map? ?? const {}),
      missionId: json['mission_id'] as String? ?? '',
      missionCode: json['mission_code'] as String? ?? '',
    );
  }
}

class ReleasedAssessmentResult {
  final String attemptId;
  final String assignmentTitle;
  final String classTitle;
  final String? cocCode;
  final String? missionTitle;
  final num? percentage;
  final String outcome;
  final String? remarks;
  final DateTime releasedAt;
  final List<ReleasedCriterionFeedback> criteria;

  const ReleasedAssessmentResult({
    required this.attemptId,
    required this.assignmentTitle,
    required this.classTitle,
    this.cocCode,
    this.missionTitle,
    required this.percentage,
    required this.outcome,
    required this.remarks,
    required this.releasedAt,
    this.criteria = const [],
  });
}

class ReleasedCriterionFeedback {
  final String code;
  final String title;
  final String observation;

  const ReleasedCriterionFeedback({
    required this.code,
    required this.title,
    required this.observation,
  });

  bool get isSatisfied => observation == 'satisfied';
}
