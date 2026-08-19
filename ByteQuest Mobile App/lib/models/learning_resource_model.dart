class LearningResource {
  final String id;
  final String classId;
  final String classTitle;
  final String title;
  final String? description;
  final String storageBucket;
  final String storagePath;
  final String? mimeType;
  final int? sizeBytes;
  final DateTime createdAt;

  const LearningResource({
    required this.id,
    required this.classId,
    required this.classTitle,
    required this.title,
    required this.storageBucket,
    required this.storagePath,
    required this.createdAt,
    this.description,
    this.mimeType,
    this.sizeBytes,
  });

  factory LearningResource.fromMap(Map<String, dynamic> data) {
    final classroom = Map<String, dynamic>.from(
      data['classes'] as Map? ?? const <String, dynamic>{},
    );
    return LearningResource(
      id: data['id'] as String,
      classId: data['class_id'] as String,
      classTitle: classroom['title'] as String? ?? 'Assigned class',
      title: data['title'] as String,
      description: data['description'] as String?,
      storageBucket: data['storage_bucket'] as String,
      storagePath: data['storage_path'] as String,
      mimeType: data['mime_type'] as String?,
      sizeBytes: (data['size_bytes'] as num?)?.toInt(),
      createdAt: DateTime.parse(data['created_at'] as String),
    );
  }
}
