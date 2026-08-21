/// Achievement Model - matches Supabase achievements table
class Achievement {
  final String id;
  final String name;
  final String description;
  final String? iconUrl;
  final String category;
  final int xpReward;
  final String unlockCondition;
  final DateTime createdAt;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    this.iconUrl,
    required this.category,
    required this.xpReward,
    required this.unlockCondition,
    required this.createdAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      iconUrl: json['icon_url'] as String?,
      category: json['category'] as String,
      xpReward: json['xp_reward'] as int,
      unlockCondition: json['unlock_condition'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon_url': iconUrl,
      'category': category,
      'xp_reward': xpReward,
      'unlock_condition': unlockCondition,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// User Achievement Model - matches Supabase user_achievements table
class UserAchievement {
  final String id;
  final String userId;
  final String achievementId;
  final DateTime unlockedAt;
  final Achievement? achievement;

  UserAchievement({
    required this.id,
    required this.userId,
    required this.achievementId,
    required this.unlockedAt,
    this.achievement,
  });

  factory UserAchievement.fromJson(Map<String, dynamic> json) {
    return UserAchievement(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      achievementId: json['achievement_id'] as String,
      unlockedAt: DateTime.parse(json['unlocked_at'] as String),
      achievement: json['achievement'] != null
          ? Achievement.fromJson(json['achievement'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'achievement_id': achievementId,
      'unlocked_at': unlockedAt.toIso8601String(),
    };
  }
}
