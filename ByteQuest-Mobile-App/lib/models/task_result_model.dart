/// Task Result Model - matches Supabase task_results table
/// Stores individual task/question results within a mission
class TaskResultDb {
  final String id;
  final String missionResultId;
  final String? taskId;
  final String userId;
  final String missionId;
  final bool isCorrect;
  final bool isCompleted;
  final String? selectedAnswer;
  final String? selectedTarget;
  final String? correctAnswer;
  final String? correctTarget;
  final int scoreObtained;
  final int maxScore;
  final int attempts;
  final bool hintUsed;
  final String? feedback;
  final DateTime? completedAt;
  final DateTime createdAt;

  TaskResultDb({
    required this.id,
    required this.missionResultId,
    this.taskId,
    required this.userId,
    required this.missionId,
    this.isCorrect = false,
    this.isCompleted = false,
    this.selectedAnswer,
    this.selectedTarget,
    this.correctAnswer,
    this.correctTarget,
    this.scoreObtained = 0,
    this.maxScore = 0,
    this.attempts = 1,
    this.hintUsed = false,
    this.feedback,
    this.completedAt,
    required this.createdAt,
  });

  factory TaskResultDb.fromJson(Map<String, dynamic> json) {
    return TaskResultDb(
      id: json['id'] as String,
      missionResultId: json['mission_result_id'] as String,
      taskId: json['task_id'] as String?,
      userId: json['user_id'] as String,
      missionId: json['mission_id'] as String,
      isCorrect: json['is_correct'] as bool? ?? false,
      isCompleted: json['is_completed'] as bool? ?? false,
      selectedAnswer: json['selected_answer'] as String?,
      selectedTarget: json['selected_target'] as String?,
      correctAnswer: json['correct_answer'] as String?,
      correctTarget: json['correct_target'] as String?,
      scoreObtained: json['score_obtained'] as int? ?? 0,
      maxScore: json['max_score'] as int? ?? 0,
      attempts: json['attempts'] as int? ?? 1,
      hintUsed: json['hint_used'] as bool? ?? false,
      feedback: json['feedback'] as String?,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mission_result_id': missionResultId,
      'task_id': taskId,
      'user_id': userId,
      'mission_id': missionId,
      'is_correct': isCorrect,
      'is_completed': isCompleted,
      'selected_answer': selectedAnswer,
      'selected_target': selectedTarget,
      'correct_answer': correctAnswer,
      'correct_target': correctTarget,
      'score_obtained': scoreObtained,
      'max_score': maxScore,
      'attempts': attempts,
      'hint_used': hintUsed,
      'feedback': feedback,
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
