/// Profile Model - matches Supabase profiles table
class ProfileModel {
  final String id;
  final String userId;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final String role;
  final String status;
  final String? learnerId;
  final String? school;
  final String? courseSection;
  final int currentLevel;
  final int totalXp;
  final int totalPoints;
  final int totalBadges;
  final int completedMissions;
  final int currentStreak;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;
  final DateTime? lastActivityAt;

  ProfileModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    this.avatarUrl,
    this.role = 'learner',
    this.status = 'active',
    this.learnerId,
    this.school,
    this.courseSection,
    this.currentLevel = 1,
    this.totalXp = 0,
    this.totalPoints = 0,
    this.totalBadges = 0,
    this.completedMissions = 0,
    this.currentStreak = 0,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
    this.lastActivityAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String? ?? 'learner',
      status: json['status'] as String? ?? 'active',
      learnerId: json['learner_id'] as String?,
      school: json['school'] as String?,
      courseSection: json['course_section'] as String?,
      currentLevel: json['current_level'] as int? ?? 1,
      totalXp: json['total_xp'] as int? ?? 0,
      totalPoints: json['total_points'] as int? ?? 0,
      totalBadges: json['total_badges'] as int? ?? 0,
      completedMissions: json['completed_missions'] as int? ?? 0,
      currentStreak: json['current_streak'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'] as String)
          : null,
      lastActivityAt: json['last_activity_at'] != null
          ? DateTime.parse(json['last_activity_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': fullName,
      'email': email,
      'avatar_url': avatarUrl,
      'role': role,
      'status': status,
      'learner_id': learnerId,
      'school': school,
      'course_section': courseSection,
      'current_level': currentLevel,
      'total_xp': totalXp,
      'total_points': totalPoints,
      'total_badges': totalBadges,
      'completed_missions': completedMissions,
      'current_streak': currentStreak,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'last_activity_at': lastActivityAt?.toIso8601String(),
    };
  }

  ProfileModel copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? email,
    String? avatarUrl,
    String? role,
    String? status,
    String? learnerId,
    String? school,
    String? courseSection,
    int? currentLevel,
    int? totalXp,
    int? totalPoints,
    int? totalBadges,
    int? completedMissions,
    int? currentStreak,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    DateTime? lastActivityAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      status: status ?? this.status,
      learnerId: learnerId ?? this.learnerId,
      school: school ?? this.school,
      courseSection: courseSection ?? this.courseSection,
      currentLevel: currentLevel ?? this.currentLevel,
      totalXp: totalXp ?? this.totalXp,
      totalPoints: totalPoints ?? this.totalPoints,
      totalBadges: totalBadges ?? this.totalBadges,
      completedMissions: completedMissions ?? this.completedMissions,
      currentStreak: currentStreak ?? this.currentStreak,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
    );
  }
}
