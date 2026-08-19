/// Badge Model - matches Supabase badges table
class Badge {
  final String id;
  final String name;
  final String description;
  final String? iconUrl;
  final String category;
  final int requiredValue;
  final DateTime createdAt;

  Badge({
    required this.id,
    required this.name,
    required this.description,
    this.iconUrl,
    required this.category,
    required this.requiredValue,
    required this.createdAt,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      iconUrl: json['icon_url'] as String?,
      category: json['category'] as String,
      requiredValue: json['required_value'] as int,
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
      'required_value': requiredValue,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// User Badge Model - matches Supabase user_badges table
class UserBadge {
  final String id;
  final String userId;
  final String badgeId;
  final DateTime earnedAt;
  final Badge? badge;

  UserBadge({
    required this.id,
    required this.userId,
    required this.badgeId,
    required this.earnedAt,
    this.badge,
  });

  factory UserBadge.fromJson(Map<String, dynamic> json) {
    return UserBadge(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      badgeId: json['badge_id'] as String,
      earnedAt: DateTime.parse(json['earned_at'] as String),
      badge: json['badge'] != null ? Badge.fromJson(json['badge']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'badge_id': badgeId,
      'earned_at': earnedAt.toIso8601String(),
    };
  }
}
