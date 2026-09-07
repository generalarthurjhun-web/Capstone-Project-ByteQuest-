enum AuthoritativeStageType {
  selection,
  sequence,
  singleChoice,
  configuration,
  matching,
}

class AuthoritativeStageOption {
  final String id;
  final String label;

  const AuthoritativeStageOption({required this.id, required this.label});

  factory AuthoritativeStageOption.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final label = json['label'] as String?;
    if (id == null ||
        id.trim().isEmpty ||
        label == null ||
        label.trim().isEmpty) {
      throw const FormatException(
          'Every assessment option needs an id and label.');
    }
    return AuthoritativeStageOption(id: id, label: label);
  }
}

class AuthoritativeStageField {
  final String id;
  final String label;
  final List<AuthoritativeStageOption> options;

  const AuthoritativeStageField({
    required this.id,
    required this.label,
    required this.options,
  });

  factory AuthoritativeStageField.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final label = json['label'] as String?;
    final options = _optionsFrom(json['options']);
    if (id == null ||
        id.trim().isEmpty ||
        label == null ||
        label.trim().isEmpty ||
        options.isEmpty) {
      throw const FormatException(
          'Every assessment field needs an id, label, and options.');
    }
    return AuthoritativeStageField(id: id, label: label, options: options);
  }
}

class AuthoritativeMissionStage {
  final String id;
  final String criterionCode;
  final AuthoritativeStageType type;
  final String title;
  final String instruction;
  final String actionType;
  final int requiredCount;
  final List<AuthoritativeStageOption> options;
  final List<AuthoritativeStageField> fields;

  const AuthoritativeMissionStage({
    required this.id,
    required this.criterionCode,
    required this.type,
    required this.title,
    required this.instruction,
    required this.actionType,
    required this.requiredCount,
    required this.options,
    required this.fields,
  });

  factory AuthoritativeMissionStage.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('expected') || json.containsKey('evidence_rule')) {
      throw const FormatException(
          'Learner payload must not contain authoritative answers.');
    }
    final type = switch (json['type']) {
      'selection' => AuthoritativeStageType.selection,
      'sequence' => AuthoritativeStageType.sequence,
      'single_choice' => AuthoritativeStageType.singleChoice,
      'configuration' => AuthoritativeStageType.configuration,
      'matching' => AuthoritativeStageType.matching,
      _ => throw const FormatException('Unsupported authoritative stage type.'),
    };
    final id = json['id'] as String?;
    final criterionCode = json['criterion_code'] as String?;
    final title = json['title'] as String?;
    final instruction = json['instruction'] as String?;
    final actionType = json['action_type'] as String?;
    final requiredCount = json['required_count'] as int? ?? 0;
    final options = _optionsFrom(json['options']);
    final fields = (json['fields'] as List? ?? const [])
        .map((item) => AuthoritativeStageField.fromJson(
            Map<String, dynamic>.from(item as Map)))
        .toList(growable: false);

    if ([id, criterionCode, title, instruction, actionType]
            .any((value) => value == null || value.trim().isEmpty) ||
        requiredCount <= 0) {
      throw const FormatException('Assessment stage metadata is incomplete.');
    }
    if ((type == AuthoritativeStageType.configuration ||
            type == AuthoritativeStageType.matching) &&
        fields.length != requiredCount) {
      throw const FormatException(
          'Assessment fields do not match the required count.');
    }
    if (type != AuthoritativeStageType.configuration &&
        type != AuthoritativeStageType.matching &&
        (options.isEmpty || requiredCount > options.length)) {
      throw const FormatException(
          'Assessment options do not support the required count.');
    }
    return AuthoritativeMissionStage(
      id: id!,
      criterionCode: criterionCode!,
      type: type,
      title: title!,
      instruction: instruction!,
      actionType: actionType!,
      requiredCount: requiredCount,
      options: options,
      fields: fields,
    );
  }
}

class AuthoritativeMissionContract {
  final String packageId;
  final String localMissionCode;
  final String unitCode;
  final String unitTitle;
  final List<AuthoritativeMissionStage> stages;

  const AuthoritativeMissionContract({
    required this.packageId,
    required this.localMissionCode,
    required this.unitCode,
    required this.unitTitle,
    required this.stages,
  });

  factory AuthoritativeMissionContract.fromLearnerPayload(
      Map<String, dynamic> payload) {
    final packageId = payload['assessment_package_id'] as String?;
    final localMissionCode = payload['local_mission_code'] as String?;
    final unitCode = payload['unit_code'] as String?;
    final unitTitle = payload['unit_title'] as String?;
    final rawStages = payload['stages'] as List?;
    if (payload['simulation_template'] != 'authoritative_mission_v1' ||
        packageId == null ||
        packageId.trim().isEmpty ||
        localMissionCode == null ||
        localMissionCode.trim().isEmpty ||
        unitCode == null ||
        unitCode.trim().isEmpty ||
        unitTitle == null ||
        unitTitle.trim().isEmpty ||
        rawStages == null ||
        rawStages.isEmpty) {
      throw const FormatException(
          'Published assessment payload is incomplete.');
    }
    final stages = rawStages
        .map((item) => AuthoritativeMissionStage.fromJson(
            Map<String, dynamic>.from(item as Map)))
        .toList(growable: false);
    if (stages.map((stage) => stage.id).toSet().length != stages.length ||
        stages.map((stage) => stage.criterionCode).toSet().length !=
            stages.length) {
      throw const FormatException(
          'Assessment stages must have stable unique identities.');
    }
    return AuthoritativeMissionContract(
      packageId: packageId,
      localMissionCode: localMissionCode,
      unitCode: unitCode,
      unitTitle: unitTitle,
      stages: stages,
    );
  }
}

List<AuthoritativeStageOption> _optionsFrom(dynamic value) {
  final options = (value as List? ?? const [])
      .map((item) => AuthoritativeStageOption.fromJson(
          Map<String, dynamic>.from(item as Map)))
      .toList(growable: false);
  if (options.map((item) => item.id).toSet().length != options.length) {
    throw const FormatException(
        'Assessment option identifiers must be unique.');
  }
  return options;
}
