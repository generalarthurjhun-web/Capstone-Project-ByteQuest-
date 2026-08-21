/// Leaderboard Entry Model - matches Supabase leaderboard_entries table
class LeaderboardEntry {
  final String id;
  final String userId;
  final String? cocId;
  final int totalXp;
  final int level;
  final int missionsCompleted;
  final int rank;
  final DateTime updatedAt;

  // Profile data (from join)
  final String? userName;
  final String? avatarUrl;

  LeaderboardEntry({
    required this.id,
    required this.userId,
    this.cocId,
    required this.totalXp,
    required this.level,
    required this.missionsCompleted,
    this.rank = 0,
    required this.updatedAt,
    this.userName,
    this.avatarUrl,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      id: (json['id'] ?? json['user_id']) as String,
      userId: json['user_id'] as String,
      cocId: json['coc_id'] as String?,
      totalXp: (json['total_xp'] ?? json['xp']) as int? ?? 0,
      level: (json['current_level'] ?? json['level']) as int? ?? 1,
      missionsCompleted:
          (json['completed_missions'] ?? json['missions_completed']) as int? ??
              0,
      rank: json['rank'] as int? ?? 0,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      userName: (json['full_name'] ?? json['user_name']) as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'coc_id': cocId,
      'total_xp': totalXp,
      'level': level,
      'missions_completed': missionsCompleted,
      'rank': rank,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  LeaderboardEntry copyWith({
    String? id,
    String? userId,
    String? cocId,
    int? totalXp,
    int? level,
    int? missionsCompleted,
    int? rank,
    DateTime? updatedAt,
    String? userName,
    String? avatarUrl,
  }) {
    return LeaderboardEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      cocId: cocId ?? this.cocId,
      totalXp: totalXp ?? this.totalXp,
      level: level ?? this.level,
      missionsCompleted: missionsCompleted ?? this.missionsCompleted,
      rank: rank ?? this.rank,
      updatedAt: updatedAt ?? this.updatedAt,
      userName: userName ?? this.userName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
