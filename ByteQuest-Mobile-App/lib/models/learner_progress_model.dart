/// Learner Progress Model - matches Supabase learner_progress table
class LearnerProgress {
  final String id;
  final String userId;
  final String cocId;
  final String missionId;
  final String status; // locked, not_started, in_progress, completed, failed
  final int completionPercentage;
  final int bestScore;
  final int latestScore;
  final int attemptsCount;
  final int totalTimeSpentSeconds;
  final DateTime? lastActivityAt;
  final DateTime? unlockedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  LearnerProgress({
    required this.id,
    required this.userId,
    required this.cocId,
    required this.missionId,
    this.status = 'locked',
    this.completionPercentage = 0,
    this.bestScore = 0,
    this.latestScore = 0,
    this.attemptsCount = 0,
    this.totalTimeSpentSeconds = 0,
    this.lastActivityAt,
    this.unlockedAt,
    this.startedAt,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LearnerProgress.fromJson(Map<String, dynamic> json) {
    return LearnerProgress(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      cocId: json['coc_id'] as String,
      missionId: json['mission_id'] as String,
      status: json['status'] as String? ?? 'locked',
      completionPercentage: json['completion_percentage'] as int? ?? 0,
      bestScore: json['best_score'] as int? ?? 0,
      latestScore: json['latest_score'] as int? ?? 0,
      attemptsCount: json['attempts_count'] as int? ?? 0,
      totalTimeSpentSeconds: json['total_time_spent_seconds'] as int? ?? 0,
      lastActivityAt: json['last_activity_at'] != null
          ? DateTime.parse(json['last_activity_at'] as String)
          : null,
      unlockedAt: json['unlocked_at'] != null
          ? DateTime.parse(json['unlocked_at'] as String)
          : null,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'coc_id': cocId,
      'mission_id': missionId,
      'status': status,
      'completion_percentage': completionPercentage,
      'best_score': bestScore,
      'latest_score': latestScore,
      'attempts_count': attemptsCount,
      'total_time_spent_seconds': totalTimeSpentSeconds,
      'last_activity_at': lastActivityAt?.toIso8601String(),
      'unlocked_at': unlockedAt?.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  LearnerProgress copyWith({
    String? id,
    String? userId,
    String? cocId,
    String? missionId,
    String? status,
    int? completionPercentage,
    int? bestScore,
    int? latestScore,
    int? attemptsCount,
    int? totalTimeSpentSeconds,
    DateTime? lastActivityAt,
    DateTime? unlockedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LearnerProgress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      cocId: cocId ?? this.cocId,
      missionId: missionId ?? this.missionId,
      status: status ?? this.status,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      bestScore: bestScore ?? this.bestScore,
      latestScore: latestScore ?? this.latestScore,
      attemptsCount: attemptsCount ?? this.attemptsCount,
      totalTimeSpentSeconds:
          totalTimeSpentSeconds ?? this.totalTimeSpentSeconds,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isLocked => status == 'locked';
  bool get isCompleted => status == 'completed';
  bool get isUnlocked => status != 'locked';
}
