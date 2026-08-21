/// Mission Scenario Model
/// Contains detailed mission information for gamified learning
class MissionScenario {
  final String missionId;
  final String cocId;
  final int missionNumber;
  final String missionTitle;
  final String moduleName;
  final String scenario;
  final String objective;
  final List<String> skillsAssessed;
  final String challengeDescription;
  final String difficulty;
  final int xpReward;
  final int estimatedTime; // in minutes
  final int passingScore;
  final String? iconPath;

  MissionScenario({
    required this.missionId,
    required this.cocId,
    required this.missionNumber,
    required this.missionTitle,
    required this.moduleName,
    required this.scenario,
    required this.objective,
    required this.skillsAssessed,
    required this.challengeDescription,
    this.difficulty = 'Medium',
    this.xpReward = 0,
    this.estimatedTime = 15,
    this.passingScore = 0,
    this.iconPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'missionId': missionId,
      'cocId': cocId,
      'missionNumber': missionNumber,
      'missionTitle': missionTitle,
      'moduleName': moduleName,
      'scenario': scenario,
      'objective': objective,
      'skillsAssessed': skillsAssessed,
      'challengeDescription': challengeDescription,
      'difficulty': difficulty,
      'xpReward': xpReward,
      'estimatedTime': estimatedTime,
      'passingScore': passingScore,
      'iconPath': iconPath,
    };
  }

  factory MissionScenario.fromMap(Map<String, dynamic> map) {
    return MissionScenario(
      missionId: map['missionId'] ?? '',
      cocId: map['cocId'] ?? '',
      missionNumber: map['missionNumber'] ?? 1,
      missionTitle: map['missionTitle'] ?? '',
      moduleName: map['moduleName'] ?? '',
      scenario: map['scenario'] ?? '',
      objective: map['objective'] ?? '',
      skillsAssessed: List<String>.from(map['skillsAssessed'] ?? []),
      challengeDescription: map['challengeDescription'] ?? '',
      difficulty: map['difficulty'] ?? 'Medium',
      xpReward: map['xpReward'] ?? 0,
      estimatedTime: map['estimatedTime'] ?? 15,
      passingScore: map['passingScore'] ?? 0,
      iconPath: map['iconPath'],
    );
  }
}

/// Hint Model for Mission 1 COC 1
class MissionHint {
  final String itemId;
  final String hintText;

  MissionHint({
    required this.itemId,
    required this.hintText,
  });
}
