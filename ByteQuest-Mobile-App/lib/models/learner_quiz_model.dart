enum LearnerQuizState {
  available,
  inProgress,
  submitted,
  completed,
  unavailable
}

class LearnerQuizSummary {
  final String assignmentId;
  final String quizVersionId;
  final String quizId;
  final String title;
  final String? description;
  final String topic;
  final String? instructions;
  final String classId;
  final String classTitle;
  final String? cocCode;
  final String? cocTitle;
  final int questionCount;
  final DateTime? availableAt;
  final DateTime? dueAt;
  final int? attemptsAllowed;
  final bool isAvailable;
  final String? attemptId;
  final String? attemptStatus;
  final int answeredCount;
  final DateTime? startedAt;
  final DateTime? completedAt;

  const LearnerQuizSummary({
    required this.assignmentId,
    required this.quizVersionId,
    required this.quizId,
    required this.title,
    required this.description,
    required this.topic,
    required this.instructions,
    required this.classId,
    required this.classTitle,
    required this.cocCode,
    required this.cocTitle,
    required this.questionCount,
    required this.availableAt,
    required this.dueAt,
    required this.attemptsAllowed,
    required this.isAvailable,
    required this.attemptId,
    required this.attemptStatus,
    required this.answeredCount,
    required this.startedAt,
    required this.completedAt,
  });

  LearnerQuizState get state {
    switch (attemptStatus) {
      case 'completed':
        return LearnerQuizState.completed;
      case 'submitted':
        return LearnerQuizState.submitted;
      case 'in_progress':
        return LearnerQuizState.inProgress;
      default:
        return isAvailable
            ? LearnerQuizState.available
            : LearnerQuizState.unavailable;
    }
  }

  factory LearnerQuizSummary.fromJson(Map<String, dynamic> json) {
    DateTime? date(String key) =>
        json[key] == null ? null : DateTime.tryParse(json[key].toString());
    return LearnerQuizSummary(
      assignmentId: json['assignment_id'] as String,
      quizVersionId: json['quiz_version_id'] as String,
      quizId: json['quiz_id'] as String,
      title: json['title'] as String? ?? 'Quiz',
      description: json['description'] as String?,
      topic: json['topic'] as String? ?? 'Supplementary review',
      instructions: json['instructions'] as String?,
      classId: json['class_id'] as String,
      classTitle: json['class_title'] as String? ?? 'Class',
      cocCode: json['coc_code'] as String?,
      cocTitle: json['coc_title'] as String?,
      questionCount: (json['question_count'] as num?)?.toInt() ?? 0,
      availableAt: date('available_at'),
      dueAt: date('due_at'),
      attemptsAllowed: (json['attempts_allowed'] as num?)?.toInt(),
      isAvailable: json['is_available'] as bool? ?? false,
      attemptId: json['attempt_id'] as String?,
      attemptStatus: json['attempt_status'] as String?,
      answeredCount: (json['answered_count'] as num?)?.toInt() ?? 0,
      startedAt: date('started_at'),
      completedAt: date('completed_at'),
    );
  }
}

class LearnerQuizQuestion {
  final String id;
  final String code;
  final String type;
  final String prompt;
  final List<String> options;
  final int orderIndex;
  final String? savedAnswer;

  const LearnerQuizQuestion({
    required this.id,
    required this.code,
    required this.type,
    required this.prompt,
    required this.options,
    required this.orderIndex,
    this.savedAnswer,
  });

  factory LearnerQuizQuestion.fromJson(Map<String, dynamic> json) =>
      LearnerQuizQuestion(
        id: json['id'] as String,
        code: json['code'] as String? ?? 'ITEM',
        type: json['type'] as String? ?? 'multiple_choice',
        prompt: json['prompt'] as String? ?? '',
        options: (json['options'] as List? ?? const [])
            .map((item) => item.toString())
            .toList(growable: false),
        orderIndex: (json['order_index'] as num?)?.toInt() ?? 0,
        savedAnswer: json['saved_answer'] as String?,
      );
}

class LearnerQuizAttempt {
  final String attemptId;
  final String status;
  final DateTime startedAt;
  final String assignmentId;
  final String title;
  final String? description;
  final String topic;
  final String? instructions;
  final String classTitle;
  final int versionNumber;
  final List<LearnerQuizQuestion> questions;

  const LearnerQuizAttempt({
    required this.attemptId,
    required this.status,
    required this.startedAt,
    required this.assignmentId,
    required this.title,
    required this.description,
    required this.topic,
    required this.instructions,
    required this.classTitle,
    required this.versionNumber,
    required this.questions,
  });

  factory LearnerQuizAttempt.fromJson(Map<String, dynamic> json) {
    final quiz = Map<String, dynamic>.from(json['quiz'] as Map? ?? const {});
    return LearnerQuizAttempt(
      attemptId: json['attempt_id'] as String,
      status: json['status'] as String? ?? 'in_progress',
      startedAt: DateTime.parse(json['started_at'] as String),
      assignmentId: quiz['assignment_id'] as String,
      title: quiz['title'] as String? ?? 'Quiz',
      description: quiz['description'] as String?,
      topic: quiz['topic'] as String? ?? 'Supplementary review',
      instructions: quiz['instructions'] as String?,
      classTitle: quiz['class_title'] as String? ?? 'Class',
      versionNumber: (quiz['version_number'] as num?)?.toInt() ?? 1,
      questions: (json['questions'] as List? ?? const [])
          .map((item) => LearnerQuizQuestion.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(growable: false),
    );
  }
}

class LearnerQuizItemResult {
  final String itemId;
  final String code;
  final String type;
  final String prompt;
  final String learnerAnswer;
  final bool isCorrect;
  final int orderIndex;

  const LearnerQuizItemResult({
    required this.itemId,
    required this.code,
    required this.type,
    required this.prompt,
    required this.learnerAnswer,
    required this.isCorrect,
    required this.orderIndex,
  });

  factory LearnerQuizItemResult.fromJson(Map<String, dynamic> json) =>
      LearnerQuizItemResult(
        itemId: json['item_id'] as String,
        code: json['code'] as String? ?? 'ITEM',
        type: json['type'] as String? ?? 'multiple_choice',
        prompt: json['prompt'] as String? ?? '',
        learnerAnswer: json['learner_answer'] as String? ?? '',
        isCorrect: json['is_correct'] as bool? ?? false,
        orderIndex: (json['order_index'] as num?)?.toInt() ?? 0,
      );
}

class LearnerQuizResult {
  final String attemptId;
  final String status;
  final String title;
  final String classTitle;
  final DateTime completedAt;
  final int correctCount;
  final int questionCount;
  final List<LearnerQuizItemResult> items;

  const LearnerQuizResult({
    required this.attemptId,
    required this.status,
    required this.title,
    required this.classTitle,
    required this.completedAt,
    required this.correctCount,
    required this.questionCount,
    required this.items,
  });

  factory LearnerQuizResult.fromJson(Map<String, dynamic> json) =>
      LearnerQuizResult(
        attemptId: json['attempt_id'] as String,
        status: json['status'] as String? ?? 'completed',
        title: json['title'] as String? ?? 'Quiz result',
        classTitle: json['class_title'] as String? ?? 'Class',
        completedAt: DateTime.parse(json['completed_at'] as String),
        correctCount: (json['correct_count'] as num?)?.toInt() ?? 0,
        questionCount: (json['question_count'] as num?)?.toInt() ?? 0,
        items: (json['item_results'] as List? ?? const [])
            .map((item) => LearnerQuizItemResult.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ))
            .toList(growable: false),
      );
}
