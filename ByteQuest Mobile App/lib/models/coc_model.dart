/// COC Module Model - matches Supabase coc_modules table
class CocModule {
  final String id;
  final String cocCode;
  final String title;
  final String moduleName;
  final String? description;
  final String competencyArea;
  final String? competencyId;
  final int totalMissions;
  final int orderIndex;
  final String status;
  final String? difficulty;
  final int xpReward;
  final String? iconUrl;
  final String? colorHex;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CocModule({
    required this.id,
    required this.cocCode,
    required this.title,
    required this.moduleName,
    this.description,
    required this.competencyArea,
    this.competencyId,
    this.totalMissions = 5,
    required this.orderIndex,
    this.status = 'published',
    this.difficulty = 'beginner',
    this.xpReward = 0,
    this.iconUrl,
    this.colorHex,
    this.createdAt,
    this.updatedAt,
  });

  factory CocModule.fromJson(Map<String, dynamic> json) {
    return CocModule(
      id: json['id'] as String,
      cocCode: json['coc_code'] as String? ?? '',
      title: json['title'] as String,
      moduleName: json['module_name'] as String? ?? '',
      description: json['description'] as String?,
      competencyArea: json['competency_area'] as String? ?? '',
      competencyId: json['competency_id'] as String?,
      totalMissions: json['total_missions'] as int? ?? 5,
      orderIndex: json['order_index'] as int? ?? 0,
      status: json['status'] as String? ?? 'published',
      difficulty: json['difficulty'] as String? ?? 'beginner',
      xpReward: json['xp_reward'] as int? ?? 0,
      iconUrl: json['icon_url'] as String?,
      colorHex: json['color_hex'] as String?,
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
      'coc_code': cocCode,
      'title': title,
      'module_name': moduleName,
      'description': description,
      'competency_area': competencyArea,
      'competency_id': competencyId,
      'total_missions': totalMissions,
      'order_index': orderIndex,
      'status': status,
      'difficulty': difficulty,
      'xp_reward': xpReward,
      'icon_url': iconUrl,
      'color_hex': colorHex,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  CocModule copyWith({
    String? id,
    String? cocCode,
    String? title,
    String? moduleName,
    String? description,
    String? competencyArea,
    String? competencyId,
    int? totalMissions,
    int? orderIndex,
    String? status,
    String? difficulty,
    int? xpReward,
    String? iconUrl,
    String? colorHex,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CocModule(
      id: id ?? this.id,
      cocCode: cocCode ?? this.cocCode,
      title: title ?? this.title,
      moduleName: moduleName ?? this.moduleName,
      description: description ?? this.description,
      competencyArea: competencyArea ?? this.competencyArea,
      competencyId: competencyId ?? this.competencyId,
      totalMissions: totalMissions ?? this.totalMissions,
      orderIndex: orderIndex ?? this.orderIndex,
      status: status ?? this.status,
      difficulty: difficulty ?? this.difficulty,
      xpReward: xpReward ?? this.xpReward,
      iconUrl: iconUrl ?? this.iconUrl,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
