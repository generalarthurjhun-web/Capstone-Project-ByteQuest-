class AttemptHistoryEntry {
  final String id;
  final String title;
  final String classTitle;
  final String status;
  final DateTime startedAt;
  final DateTime? submittedAt;
  final DateTime? releasedAt;

  const AttemptHistoryEntry({
    required this.id,
    required this.title,
    required this.classTitle,
    required this.status,
    required this.startedAt,
    this.submittedAt,
    this.releasedAt,
  });

  bool get isReleased => releasedAt != null || status == 'released';
  bool get isProvisional => !isReleased && status != 'in_progress';

  factory AttemptHistoryEntry.fromJson(Map<String, dynamic> json) {
    final assignment = Map<String, dynamic>.from(
      json['assignments'] as Map? ?? const {},
    );
    final classroom = Map<String, dynamic>.from(
      assignment['classes'] as Map? ?? const {},
    );
    return AttemptHistoryEntry(
      id: json['id'] as String,
      title: assignment['title'] as String? ?? 'Assessment attempt',
      classTitle: classroom['title'] as String? ?? 'Class',
      status: json['status'] as String? ?? 'unknown',
      startedAt: DateTime.parse(json['started_at'] as String),
      submittedAt: json['submitted_at'] == null
          ? null
          : DateTime.parse(json['submitted_at'] as String),
      releasedAt: json['released_at'] == null
          ? null
          : DateTime.parse(json['released_at'] as String),
    );
  }
}
