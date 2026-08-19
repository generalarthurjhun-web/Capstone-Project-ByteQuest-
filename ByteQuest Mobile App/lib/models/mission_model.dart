/// Mission Type Enum
enum MissionType {
  identification, // Tap/select to identify items
  dragAndDrop, // Drag components to correct positions
  configurationForm, // Fill forms and settings
  stepProcedure, // Follow step-by-step procedures
  troubleshooting, // Diagnose and solve problems
  checklist, // Checklist-based missions
  matching, // Matching-based missions
}

/// Extension methods for MissionType DB conversion
extension MissionTypeExtension on MissionType {
  /// Convert enum value to DB snake_case string
  String toDbString() {
    switch (this) {
      case MissionType.identification:
        return 'identification';
      case MissionType.dragAndDrop:
        return 'drag_and_drop';
      case MissionType.configurationForm:
        return 'configuration_form';
      case MissionType.stepProcedure:
        return 'step_procedure';
      case MissionType.troubleshooting:
        return 'troubleshooting';
      case MissionType.checklist:
        return 'checklist';
      case MissionType.matching:
        return 'matching';
    }
  }

  /// Convert DB snake_case string to enum value
  static MissionType fromDbString(String value) {
    switch (value) {
      case 'identification':
        return MissionType.identification;
      case 'drag_and_drop':
        return MissionType.dragAndDrop;
      case 'configuration_form':
        return MissionType.configurationForm;
      case 'step_procedure':
        return MissionType.stepProcedure;
      case 'troubleshooting':
        return MissionType.troubleshooting;
      case 'checklist':
        return MissionType.checklist;
      case 'matching':
        return MissionType.matching;
      default:
        return MissionType.identification;
    }
  }
}

/// Mission Model - matches Supabase missions table
class Mission {
  final String id;
  final String cocId;
  final String? competencyId;
  final String missionCode;
  final int missionNumber;
  final String title;
  final String? description;
  final String? scenario;
  final String? objective;
  final List<String>? skillsAssessed;
  final String? challengeDescription;
  final MissionType missionType;
  final String difficulty;
  final int xpReward;
  final int pointsReward;
  final int passingScore;
  final int? timeLimitSeconds;
  final int estimatedTimeMinutes;
  final String status;
  final bool isLocked;
  final int orderIndex;
  final int hintCount;
  final String? iconUrl;
  final String? assetPath;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Additional runtime properties (not from database)
  final bool? isUnlocked;
  final bool? isCompleted;
  final int? highScore;

  Mission({
    required this.id,
    required this.cocId,
    this.competencyId,
    required this.missionCode,
    required this.missionNumber,
    required this.title,
    this.description,
    this.scenario,
    this.objective,
    this.skillsAssessed,
    this.challengeDescription,
    required this.missionType,
    this.difficulty = 'beginner',
    this.xpReward = 0,
    this.pointsReward = 0,
    this.passingScore = 0,
    this.timeLimitSeconds,
    this.estimatedTimeMinutes = 10,
    this.status = 'published',
    this.isLocked = true,
    required this.orderIndex,
    this.hintCount = 0,
    this.iconUrl,
    this.assetPath,
    this.createdAt,
    this.updatedAt,
    // Runtime properties
    this.isUnlocked,
    this.isCompleted,
    this.highScore,
  });

  // Convenience getters for compatibility
  int get order => orderIndex;
  int get estimatedTime => estimatedTimeMinutes;
  MissionType get type => missionType;

  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: json['id'] as String,
      cocId: json['coc_id'] as String,
      competencyId: json['competency_id'] as String?,
      missionCode: json['mission_code'] as String? ?? '',
      missionNumber: json['mission_number'] as int? ?? 0,
      title: json['title'] as String,
      description: json['description'] as String?,
      scenario: json['scenario'] as String?,
      objective: json['objective'] as String?,
      skillsAssessed: json['skills_assessed'] != null
          ? List<String>.from(json['skills_assessed'])
          : null,
      challengeDescription: json['challenge_description'] as String?,
      missionType: MissionTypeExtension.fromDbString(
          json['mission_type'] as String? ?? 'identification'),
      difficulty: json['difficulty'] as String? ?? 'beginner',
      xpReward: json['xp_reward'] as int? ?? 0,
      pointsReward: json['points_reward'] as int? ?? 0,
      passingScore: json['passing_score'] as int? ?? 0,
      timeLimitSeconds: json['time_limit_seconds'] as int?,
      estimatedTimeMinutes: json['estimated_time_minutes'] as int? ?? 10,
      status: json['status'] as String? ?? 'published',
      isLocked: json['is_locked'] as bool? ?? true,
      orderIndex: json['order_index'] as int? ?? 0,
      hintCount: json['hint_count'] as int? ?? 0,
      iconUrl: json['icon_url'] as String?,
      assetPath: json['asset_path'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'coc_id': cocId,
      'competency_id': competencyId,
      'mission_code': missionCode,
      'mission_number': missionNumber,
      'title': title,
      'description': description,
      'scenario': scenario,
      'objective': objective,
      'skills_assessed': skillsAssessed,
      'challenge_description': challengeDescription,
      'mission_type': missionType.toDbString(),
      'difficulty': difficulty,
      'xp_reward': xpReward,
      'points_reward': pointsReward,
      'passing_score': passingScore,
      'time_limit_seconds': timeLimitSeconds,
      'estimated_time_minutes': estimatedTimeMinutes,
      'status': status,
      'is_locked': isLocked,
      'order_index': orderIndex,
      'hint_count': hintCount,
      'icon_url': iconUrl,
      'asset_path': assetPath,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Mission copyWith({
    String? id,
    String? cocId,
    String? competencyId,
    String? missionCode,
    int? missionNumber,
    String? title,
    String? description,
    String? scenario,
    String? objective,
    List<String>? skillsAssessed,
    String? challengeDescription,
    MissionType? missionType,
    String? difficulty,
    int? xpReward,
    int? pointsReward,
    int? passingScore,
    int? timeLimitSeconds,
    int? estimatedTimeMinutes,
    String? status,
    bool? isLocked,
    int? orderIndex,
    int? hintCount,
    String? iconUrl,
    String? assetPath,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isUnlocked,
    bool? isCompleted,
    int? highScore,
  }) {
    return Mission(
      id: id ?? this.id,
      cocId: cocId ?? this.cocId,
      competencyId: competencyId ?? this.competencyId,
      missionCode: missionCode ?? this.missionCode,
      missionNumber: missionNumber ?? this.missionNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      scenario: scenario ?? this.scenario,
      objective: objective ?? this.objective,
      skillsAssessed: skillsAssessed ?? this.skillsAssessed,
      challengeDescription: challengeDescription ?? this.challengeDescription,
      missionType: missionType ?? this.missionType,
      difficulty: difficulty ?? this.difficulty,
      xpReward: xpReward ?? this.xpReward,
      pointsReward: pointsReward ?? this.pointsReward,
      passingScore: passingScore ?? this.passingScore,
      timeLimitSeconds: timeLimitSeconds ?? this.timeLimitSeconds,
      estimatedTimeMinutes: estimatedTimeMinutes ?? this.estimatedTimeMinutes,
      status: status ?? this.status,
      isLocked: isLocked ?? this.isLocked,
      orderIndex: orderIndex ?? this.orderIndex,
      hintCount: hintCount ?? this.hintCount,
      iconUrl: iconUrl ?? this.iconUrl,
      assetPath: assetPath ?? this.assetPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isCompleted: isCompleted ?? this.isCompleted,
      highScore: highScore ?? this.highScore,
    );
  }
}

/// Question/Task Item for Mission
class MissionQuestion {
  final String id;
  final String question;
  final String? imagePath;
  final List<String> options;
  final String correctAnswer;
  final String? explanation;
  final int points;

  MissionQuestion({
    required this.id,
    required this.question,
    this.imagePath,
    required this.options,
    required this.correctAnswer,
    this.explanation,
    this.points = 10,
  });
}

/// Draggable Component for Drag-and-Drop Missions
class DraggableComponent {
  final String id;
  final String name;
  final String? imagePath;
  final String targetZone;
  final String? description;

  DraggableComponent({
    required this.id,
    required this.name,
    this.imagePath,
    required this.targetZone,
    this.description,
  });
}

/// Target Zone for Drag-and-Drop Missions
class DropZone {
  final String id;
  final String name;
  final String? imagePath;
  final List<String> acceptedComponents;

  DropZone({
    required this.id,
    required this.name,
    this.imagePath,
    required this.acceptedComponents,
  });
}

/// Step for Step-Based Procedures
class ProcedureStep {
  final String id;
  final int order;
  final String title;
  final String description;
  final bool isRequired;
  final int points;

  ProcedureStep({
    required this.id,
    required this.order,
    required this.title,
    required this.description,
    this.isRequired = true,
    this.points = 10,
  });
}

/// Troubleshooting Scenario
class TroubleshootingScenario {
  final String symptom;
  final List<String> possibleCauses;
  final String correctCause;
  final String correctAction;
  final String explanation;

  TroubleshootingScenario({
    required this.symptom,
    required this.possibleCauses,
    required this.correctCause,
    required this.correctAction,
    required this.explanation,
  });
}

/// Mission Result - for passing mission completion data
class MissionResult {
  final String missionId;
  final int score;
  final int percentage;
  final bool passed;
  final int xpEarned;
  final int timeSpent;
  final String rating;
  final String competencyStatus;

  MissionResult({
    required this.missionId,
    required this.score,
    required this.percentage,
    required this.passed,
    required this.xpEarned,
    required this.timeSpent,
    required this.rating,
    required this.competencyStatus,
  });
}
