// Framework-independent definitions, runtime state, and evidence records for
// the simulation platform. These models deliberately contain no assessment
// answers, scoring, or reward state; server-side services remain authoritative.

enum InteractionFamily {
  inspect,
  select,
  tool,
  connect,
  configure,
  sequence,
  match,
  place,
  troubleshoot,
  testRun,
  observe,
  decide,
  interpret,
  review,
}

enum HotspotVisualState { neutral, selected, completed, error }

enum MissionRuntimeMode { practice, assessment }

enum MissionTestStatus { idle, running, completed }

/// Canonical mapping from learner-visible presentation components to the
/// interaction family they actually render. Catalog validation, phase
/// completion, and Flutter rendering all consume this mapping so definition
/// metadata cannot drift from runtime behavior.
abstract final class MissionPhasePresentation {
  static InteractionFamily resolve(MissionPhaseDefinition phase) {
    final component = phase.presentation['component'];
    if (component == null) return phase.primaryInteraction;
    if (component is! String) {
      throw FormatException(
        'Phase ${phase.id} has a non-string presentation component.',
      );
    }
    final family = familyForComponent(component);
    if (family == null) {
      throw FormatException(
        'Phase ${phase.id} uses unknown presentation component $component.',
      );
    }
    return family;
  }

  static InteractionFamily? familyForComponent(String component) =>
      switch (component) {
        'tap_inspect' => InteractionFamily.inspect,
        'multi_select' => InteractionFamily.select,
        'tool_selection' => InteractionFamily.tool,
        'connection' => InteractionFamily.connect,
        'configuration' ||
        'configuration_decision' ||
        'service_controls' =>
          InteractionFamily.configure,
        'sequencing' ||
        'sequencing_and_placement' =>
          InteractionFamily.sequence,
        'matching' => InteractionFamily.match,
        'controlled_placement' => InteractionFamily.place,
        'troubleshooting' => InteractionFamily.troubleshoot,
        'test_run' ||
        'link_test' ||
        'test_with_interpretation' =>
          InteractionFamily.testRun,
        'observation' => InteractionFamily.observe,
        'scenario_decision' => InteractionFamily.decide,
        'result_interpretation' => InteractionFamily.interpret,
        'evidence_review' => InteractionFamily.review,
        _ => null,
      };

  static bool isTechnicalDecision(InteractionFamily family) => switch (family) {
        InteractionFamily.select ||
        InteractionFamily.tool ||
        InteractionFamily.configure ||
        InteractionFamily.match ||
        InteractionFamily.place ||
        InteractionFamily.troubleshoot ||
        InteractionFamily.decide ||
        InteractionFamily.interpret =>
          true,
        InteractionFamily.inspect ||
        InteractionFamily.connect ||
        InteractionFamily.sequence ||
        InteractionFamily.testRun ||
        InteractionFamily.observe ||
        InteractionFamily.review =>
          false,
      };
}

final class SceneObjectDefinition {
  SceneObjectDefinition({
    required this.id,
    required this.label,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.hotspotType,
    Iterable<String> connectionNodeIds = const [],
    this.initialState = HotspotVisualState.neutral,
    Map<String, dynamic> metadata = const {},
  })  : connectionNodeIds = List.unmodifiable(connectionNodeIds),
        metadata = _immutableJsonMap(metadata);

  factory SceneObjectDefinition.fromJson(Map<String, dynamic> json) {
    return SceneObjectDefinition(
      id: json['id'] as String,
      label: json['label'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      hotspotType: json['hotspotType'] as String,
      connectionNodeIds: _stringList(json['connectionNodeIds']),
      initialState: _enumByName(
        HotspotVisualState.values,
        json['initialState'] as String? ?? HotspotVisualState.neutral.name,
      ),
      metadata: _jsonMapOrEmpty(json['metadata']),
    );
  }

  final String id;
  final String label;
  final double x;
  final double y;
  final double width;
  final double height;
  final String hotspotType;
  final List<String> connectionNodeIds;
  final HotspotVisualState initialState;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'hotspotType': hotspotType,
        'connectionNodeIds': List<String>.from(connectionNodeIds),
        'initialState': initialState.name,
        'metadata': _jsonCopy(metadata),
      };

  @override
  bool operator ==(Object other) =>
      other is SceneObjectDefinition &&
      other.id == id &&
      other.label == label &&
      other.x == x &&
      other.y == y &&
      other.width == width &&
      other.height == height &&
      other.hotspotType == hotspotType &&
      _deepEquals(other.connectionNodeIds, connectionNodeIds) &&
      other.initialState == initialState &&
      _deepEquals(other.metadata, metadata);

  @override
  int get hashCode => Object.hash(
        id,
        label,
        x,
        y,
        width,
        height,
        hotspotType,
        _deepHash(connectionNodeIds),
        initialState,
        _deepHash(metadata),
      );
}

final class SimulationSceneDefinition {
  SimulationSceneDefinition({
    required this.id,
    required Iterable<SceneObjectDefinition> objects,
    this.backgroundAsset,
    Map<String, dynamic> initialStatus = const {},
  })  : objects = List.unmodifiable(objects),
        initialStatus = _immutableJsonMap(initialStatus);

  factory SimulationSceneDefinition.fromJson(Map<String, dynamic> json) {
    return SimulationSceneDefinition(
      id: json['id'] as String,
      backgroundAsset: json['backgroundAsset'] as String?,
      objects: _jsonList(json['objects'])
          .map((item) => SceneObjectDefinition.fromJson(_jsonMap(item)))
          .toList(),
      initialStatus: _jsonMapOrEmpty(json['initialStatus']),
    );
  }

  final String id;
  final String? backgroundAsset;
  final List<SceneObjectDefinition> objects;
  final Map<String, dynamic> initialStatus;

  Map<String, dynamic> toJson() => {
        'id': id,
        'backgroundAsset': backgroundAsset,
        'objects': objects.map((object) => object.toJson()).toList(),
        'initialStatus': _jsonCopy(initialStatus),
      };

  @override
  bool operator ==(Object other) =>
      other is SimulationSceneDefinition &&
      other.id == id &&
      other.backgroundAsset == backgroundAsset &&
      _deepEquals(other.objects, objects) &&
      _deepEquals(other.initialStatus, initialStatus);

  @override
  int get hashCode => Object.hash(
      id, backgroundAsset, _deepHash(objects), _deepHash(initialStatus));
}

final class MissionPhaseDefinition {
  MissionPhaseDefinition({
    required this.id,
    required this.title,
    required this.instruction,
    required this.primaryInteraction,
    Iterable<InteractionFamily> supportingInteractions = const [],
    Iterable<String> availableObjectIds = const [],
    Iterable<String> feedbackIds = const [],
    Map<String, dynamic> presentation = const {},
  })  : supportingInteractions = Set.unmodifiable(supportingInteractions),
        availableObjectIds = List.unmodifiable(availableObjectIds),
        feedbackIds = List.unmodifiable(feedbackIds),
        presentation = _immutableJsonMap(presentation);

  factory MissionPhaseDefinition.fromJson(Map<String, dynamic> json) {
    return MissionPhaseDefinition(
      id: json['id'] as String,
      title: json['title'] as String,
      instruction: json['instruction'] as String,
      primaryInteraction: _enumByName(
        InteractionFamily.values,
        json['primaryInteraction'] as String,
      ),
      supportingInteractions: _stringList(json['supportingInteractions'])
          .map((name) => _enumByName(InteractionFamily.values, name)),
      availableObjectIds: _stringList(json['availableObjectIds']),
      feedbackIds: _stringList(json['feedbackIds']),
      presentation: _jsonMapOrEmpty(json['presentation']),
    );
  }

  final String id;
  final String title;
  final String instruction;
  final InteractionFamily primaryInteraction;
  final Set<InteractionFamily> supportingInteractions;
  final List<String> availableObjectIds;
  final List<String> feedbackIds;
  final Map<String, dynamic> presentation;

  InteractionFamily get resolvedInteraction =>
      MissionPhasePresentation.resolve(this);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'instruction': instruction,
        'primaryInteraction': primaryInteraction.name,
        'supportingInteractions':
            supportingInteractions.map((family) => family.name).toList(),
        'availableObjectIds': List<String>.from(availableObjectIds),
        'feedbackIds': List<String>.from(feedbackIds),
        'presentation': _jsonCopy(presentation),
      };

  @override
  bool operator ==(Object other) =>
      other is MissionPhaseDefinition &&
      other.id == id &&
      other.title == title &&
      other.instruction == instruction &&
      other.primaryInteraction == primaryInteraction &&
      _deepEquals(other.supportingInteractions, supportingInteractions) &&
      _deepEquals(other.availableObjectIds, availableObjectIds) &&
      _deepEquals(other.feedbackIds, feedbackIds) &&
      _deepEquals(other.presentation, presentation);

  @override
  int get hashCode => Object.hash(
        id,
        title,
        instruction,
        primaryInteraction,
        _deepHash(supportingInteractions),
        _deepHash(availableObjectIds),
        _deepHash(feedbackIds),
        _deepHash(presentation),
      );
}

final class MissionSimulationDefinition {
  MissionSimulationDefinition({
    required this.id,
    required this.cocId,
    required this.title,
    required this.scenario,
    required this.environmentLabel,
    required this.practiceGuidance,
    required this.scene,
    required Iterable<MissionPhaseDefinition> phases,
    required Iterable<InteractionFamily> interactionFamilies,
    Map<String, String> feedbackCatalog = const {},
    Map<String, dynamic> reviewMetadata = const {},
  })  : phases = List.unmodifiable(phases),
        interactionFamilies = Set.unmodifiable(
          phases
              .map(MissionPhasePresentation.resolve)
              .where((family) => family != InteractionFamily.review),
        ),
        feedbackCatalog =
            Map.unmodifiable(Map<String, String>.from(feedbackCatalog)),
        reviewMetadata = _immutableJsonMap(reviewMetadata) {
    if (this.phases.length < 3 || this.phases.length > 6) {
      throw ArgumentError.value(
          this.phases.length, 'phases', 'must contain 3–6 phases');
    }
    if (this.phases.map((phase) => phase.id).toSet().length !=
        this.phases.length) {
      throw ArgumentError.value(phases, 'phases', 'must have unique IDs');
    }
    for (final phase in this.phases) {
      final resolved = phase.resolvedInteraction;
      if (resolved != phase.primaryInteraction) {
        throw ArgumentError.value(
          phase.primaryInteraction,
          'phases',
          '${phase.id} declares ${phase.primaryInteraction.name} but renders '
              '${resolved.name}',
        );
      }
    }
    if (this.interactionFamilies.length < 2 ||
        this.interactionFamilies.length > 4) {
      throw ArgumentError.value(
        this.interactionFamilies.length,
        'interactionFamilies',
        'must contain 2–4 distinct families',
      );
    }
    final declaredFamilies = interactionFamilies
        .where((family) => family != InteractionFamily.review)
        .toSet();
    if (!_deepEquals(this.interactionFamilies, declaredFamilies)) {
      throw ArgumentError.value(
        interactionFamilies,
        'interactionFamilies',
        'must exactly match the interactions rendered by phases',
      );
    }
    if (!this
        .interactionFamilies
        .any(MissionPhasePresentation.isTechnicalDecision)) {
      throw ArgumentError.value(
        phases,
        'phases',
        'must include a rendered technical decision interaction',
      );
    }
    if (!this.interactionFamilies.contains(InteractionFamily.testRun)) {
      throw ArgumentError.value(phases, 'phases', 'must include verification');
    }
  }

  factory MissionSimulationDefinition.fromJson(Map<String, dynamic> json) {
    return MissionSimulationDefinition(
      id: json['id'] as String,
      cocId: json['cocId'] as String,
      title: json['title'] as String,
      scenario: json['scenario'] as String,
      environmentLabel: json['environmentLabel'] as String,
      practiceGuidance: json['practiceGuidance'] as String,
      scene: SimulationSceneDefinition.fromJson(_jsonMap(json['scene'])),
      phases: _jsonList(json['phases'])
          .map((item) => MissionPhaseDefinition.fromJson(_jsonMap(item)))
          .toList(),
      interactionFamilies: _stringList(json['interactionFamilies'])
          .map((name) => _enumByName(InteractionFamily.values, name)),
      feedbackCatalog: _stringMap(json['feedbackCatalog']),
      reviewMetadata: _jsonMapOrEmpty(json['reviewMetadata']),
    );
  }

  final String id;
  final String cocId;
  final String title;
  final String scenario;
  final String environmentLabel;
  final String practiceGuidance;
  final SimulationSceneDefinition scene;
  final List<MissionPhaseDefinition> phases;
  final Set<InteractionFamily> interactionFamilies;
  final Map<String, String> feedbackCatalog;
  final Map<String, dynamic> reviewMetadata;

  bool get hasTechnicalDecision => interactionFamilies.any(
        MissionPhasePresentation.isTechnicalDecision,
      );

  bool get hasVerification =>
      interactionFamilies.contains(InteractionFamily.testRun);

  Map<String, dynamic> toJson() => {
        'id': id,
        'cocId': cocId,
        'title': title,
        'scenario': scenario,
        'environmentLabel': environmentLabel,
        'practiceGuidance': practiceGuidance,
        'scene': scene.toJson(),
        'phases': phases.map((phase) => phase.toJson()).toList(),
        'interactionFamilies':
            interactionFamilies.map((family) => family.name).toList(),
        'feedbackCatalog': Map<String, String>.from(feedbackCatalog),
        'reviewMetadata': _jsonCopy(reviewMetadata),
      };

  @override
  bool operator ==(Object other) =>
      other is MissionSimulationDefinition &&
      other.id == id &&
      other.cocId == cocId &&
      other.title == title &&
      other.scenario == scenario &&
      other.environmentLabel == environmentLabel &&
      other.practiceGuidance == practiceGuidance &&
      other.scene == scene &&
      _deepEquals(other.phases, phases) &&
      _deepEquals(other.interactionFamilies, interactionFamilies) &&
      _deepEquals(other.feedbackCatalog, feedbackCatalog) &&
      _deepEquals(other.reviewMetadata, reviewMetadata);

  @override
  int get hashCode => Object.hash(
        id,
        cocId,
        title,
        scenario,
        environmentLabel,
        practiceGuidance,
        scene,
        _deepHash(phases),
        _deepHash(interactionFamilies),
        _deepHash(feedbackCatalog),
        _deepHash(reviewMetadata),
      );
}

final class MissionEvidenceAction {
  MissionEvidenceAction({
    required this.clientActionId,
    required this.missionId,
    required this.phaseId,
    required this.actionType,
    this.target,
    required Map<String, dynamic> value,
    required this.occurredAt,
  }) : value = _immutableJsonMap(value);

  factory MissionEvidenceAction.fromJson(Map<String, dynamic> json) {
    return MissionEvidenceAction(
      clientActionId: json['clientActionId'] as String,
      missionId: json['missionId'] as String,
      phaseId: json['phaseId'] as String,
      actionType: json['actionType'] as String,
      target: json['target'] as String?,
      value: _immutableJsonMap(_jsonMap(json['value'])),
      occurredAt: DateTime.parse(json['occurredAt'] as String),
    );
  }

  final String clientActionId;
  final String missionId;
  final String phaseId;
  final String actionType;
  final String? target;
  final Map<String, dynamic> value;
  final DateTime occurredAt;

  Map<String, dynamic> toJson() => {
        'clientActionId': clientActionId,
        'missionId': missionId,
        'phaseId': phaseId,
        'actionType': actionType,
        'target': target,
        'value': _jsonCopy(value),
        'occurredAt': occurredAt.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      other is MissionEvidenceAction &&
      other.clientActionId == clientActionId &&
      other.missionId == missionId &&
      other.phaseId == phaseId &&
      other.actionType == actionType &&
      other.target == target &&
      _deepEquals(other.value, value) &&
      other.occurredAt == occurredAt;

  @override
  int get hashCode => Object.hash(
        clientActionId,
        missionId,
        phaseId,
        actionType,
        target,
        _deepHash(value),
        occurredAt,
      );
}

final class MissionRuntimeState {
  MissionRuntimeState({
    this.persistedSchemaVersion = schemaVersion,
    required this.missionId,
    this.currentPhaseId,
    Iterable<String> completedPhaseIds = const [],
    Iterable<String> interactionCompletedPhaseIds = const [],
    Map<String, HotspotVisualState> hotspotStates = const {},
    this.selectedToolId,
    Map<String, String> toolApplications = const {},
    Iterable<String> connectedNodePairs = const [],
    Map<String, String> placements = const {},
    Map<String, dynamic> configurationValues = const {},
    Iterable<String> sequenceOrder = const [],
    Map<String, String> matches = const {},
    Map<String, dynamic> observations = const {},
    Map<String, dynamic> interpretations = const {},
    Iterable<String> revealedFactIds = const [],
    Iterable<String> selectedBranchActionIds = const [],
    Map<String, dynamic> testState = const {},
    Iterable<String> acceptedEvidenceIds = const [],
    Iterable<MissionEvidenceAction> pendingEvidence = const [],
    this.mode = MissionRuntimeMode.practice,
    this.assessmentAttemptId,
    this.reducedMotion = false,
    this.cameraScale = 1,
    this.cameraOffsetX = 0,
    this.cameraOffsetY = 0,
    DateTime? updatedAt,
  })  : completedPhaseIds = Set.unmodifiable(completedPhaseIds),
        interactionCompletedPhaseIds =
            Set.unmodifiable(interactionCompletedPhaseIds),
        hotspotStates = Map.unmodifiable(
            Map<String, HotspotVisualState>.from(hotspotStates)),
        toolApplications =
            Map.unmodifiable(Map<String, String>.from(toolApplications)),
        connectedNodePairs = Set.unmodifiable(connectedNodePairs),
        placements = Map.unmodifiable(Map<String, String>.from(placements)),
        configurationValues = _immutableJsonMap(configurationValues),
        sequenceOrder = List.unmodifiable(sequenceOrder),
        matches = Map.unmodifiable(Map<String, String>.from(matches)),
        observations = _immutableJsonMap(observations),
        interpretations = _immutableJsonMap(interpretations),
        revealedFactIds = Set.unmodifiable(revealedFactIds),
        selectedBranchActionIds = Set.unmodifiable(selectedBranchActionIds),
        testState = _immutableJsonMap(testState),
        acceptedEvidenceIds = Set.unmodifiable(acceptedEvidenceIds),
        pendingEvidence = List.unmodifiable(pendingEvidence),
        updatedAt = updatedAt ?? DateTime.now() {
    if (persistedSchemaVersion != schemaVersion) {
      throw ArgumentError.value(
        persistedSchemaVersion,
        'persistedSchemaVersion',
        'must match the supported schema version',
      );
    }
    final hasAttemptId = assessmentAttemptId?.trim().isNotEmpty ?? false;
    if (mode == MissionRuntimeMode.assessment && !hasAttemptId) {
      throw ArgumentError.value(
        assessmentAttemptId,
        'assessmentAttemptId',
        'is required for an assessment runtime',
      );
    }
    if (mode == MissionRuntimeMode.practice && assessmentAttemptId != null) {
      throw ArgumentError.value(
        assessmentAttemptId,
        'assessmentAttemptId',
        'must be null for a practice runtime',
      );
    }
  }

  static const schemaVersion = 1;

  factory MissionRuntimeState.initial(
    String missionId, {
    MissionRuntimeMode mode = MissionRuntimeMode.practice,
    String? assessmentAttemptId,
  }) {
    return MissionRuntimeState(
      missionId: missionId,
      mode: mode,
      assessmentAttemptId: assessmentAttemptId,
    );
  }

  factory MissionRuntimeState.fromJson(Map<String, dynamic> json) {
    final version = json['schemaVersion'] as int?;
    if (version != schemaVersion) {
      throw FormatException(
          'Unsupported mission runtime schema version: $version');
    }
    return MissionRuntimeState(
      missionId: json['missionId'] as String,
      currentPhaseId: json['currentPhaseId'] as String?,
      completedPhaseIds: _stringSet(json['completedPhaseIds']),
      interactionCompletedPhaseIds:
          _stringSet(json['interactionCompletedPhaseIds']),
      hotspotStates: _hotspotStates(json['hotspotStates']),
      selectedToolId: json['selectedToolId'] as String?,
      toolApplications: _stringMap(json['toolApplications']),
      connectedNodePairs: _stringSet(json['connectedNodePairs']),
      placements: _stringMap(json['placements']),
      configurationValues: _jsonMapOrEmpty(json['configurationValues']),
      sequenceOrder: _stringList(json['sequenceOrder']),
      matches: _stringMap(json['matches']),
      observations: _jsonMapOrEmpty(json['observations']),
      interpretations: _jsonMapOrEmpty(json['interpretations']),
      revealedFactIds: _stringSet(json['revealedFactIds']),
      selectedBranchActionIds: _stringSet(json['selectedBranchActionIds']),
      testState: _jsonMapOrEmpty(json['testState']),
      acceptedEvidenceIds: _stringSet(json['acceptedEvidenceIds']),
      pendingEvidence: _jsonList(json['pendingEvidence'])
          .map((item) => MissionEvidenceAction.fromJson(_jsonMap(item)))
          .toList(),
      mode: _enumByName(
        MissionRuntimeMode.values,
        json['mode'] as String? ?? MissionRuntimeMode.practice.name,
      ),
      assessmentAttemptId: json['assessmentAttemptId'] as String?,
      reducedMotion: json['reducedMotion'] as bool? ?? false,
      cameraScale: (json['cameraScale'] as num? ?? 1).toDouble(),
      cameraOffsetX: (json['cameraOffsetX'] as num? ?? 0).toDouble(),
      cameraOffsetY: (json['cameraOffsetY'] as num? ?? 0).toDouble(),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  final int persistedSchemaVersion;
  final String missionId;
  final String? currentPhaseId;
  final Set<String> completedPhaseIds;
  final Set<String> interactionCompletedPhaseIds;
  final Map<String, HotspotVisualState> hotspotStates;
  final String? selectedToolId;
  final Map<String, String> toolApplications;
  final Set<String> connectedNodePairs;
  final Map<String, String> placements;
  final Map<String, dynamic> configurationValues;
  final List<String> sequenceOrder;
  final Map<String, String> matches;
  final Map<String, dynamic> observations;
  final Map<String, dynamic> interpretations;
  final Set<String> revealedFactIds;
  final Set<String> selectedBranchActionIds;
  final Map<String, dynamic> testState;
  final Set<String> acceptedEvidenceIds;
  final List<MissionEvidenceAction> pendingEvidence;
  final MissionRuntimeMode mode;
  final String? assessmentAttemptId;
  final bool reducedMotion;
  final double cameraScale;
  final double cameraOffsetX;
  final double cameraOffsetY;
  final DateTime updatedAt;

  MissionRuntimeState copyWith({
    String? currentPhaseId,
    String? selectedToolId,
    bool clearCurrentPhaseId = false,
    bool clearSelectedToolId = false,
    Set<String>? connectedNodePairs,
    Set<String>? acceptedEvidenceIds,
    Set<String>? completedPhaseIds,
    Set<String>? interactionCompletedPhaseIds,
    Map<String, HotspotVisualState>? hotspotStates,
    Map<String, String>? toolApplications,
    Map<String, String>? placements,
    Map<String, dynamic>? configurationValues,
    List<String>? sequenceOrder,
    Map<String, String>? matches,
    Map<String, dynamic>? observations,
    Map<String, dynamic>? interpretations,
    Set<String>? revealedFactIds,
    Set<String>? selectedBranchActionIds,
    Map<String, dynamic>? testState,
    List<MissionEvidenceAction>? pendingEvidence,
    MissionRuntimeMode? mode,
    String? assessmentAttemptId,
    bool clearAssessmentAttemptId = false,
    bool? reducedMotion,
    double? cameraScale,
    double? cameraOffsetX,
    double? cameraOffsetY,
    DateTime? updatedAt,
  }) {
    return MissionRuntimeState(
      missionId: missionId,
      currentPhaseId:
          clearCurrentPhaseId ? null : currentPhaseId ?? this.currentPhaseId,
      completedPhaseIds: completedPhaseIds ?? this.completedPhaseIds,
      interactionCompletedPhaseIds:
          interactionCompletedPhaseIds ?? this.interactionCompletedPhaseIds,
      hotspotStates: hotspotStates ?? this.hotspotStates,
      selectedToolId:
          clearSelectedToolId ? null : selectedToolId ?? this.selectedToolId,
      toolApplications: toolApplications ?? this.toolApplications,
      connectedNodePairs: connectedNodePairs ?? this.connectedNodePairs,
      placements: placements ?? this.placements,
      configurationValues: configurationValues ?? this.configurationValues,
      sequenceOrder: sequenceOrder ?? this.sequenceOrder,
      matches: matches ?? this.matches,
      observations: observations ?? this.observations,
      interpretations: interpretations ?? this.interpretations,
      revealedFactIds: revealedFactIds ?? this.revealedFactIds,
      selectedBranchActionIds:
          selectedBranchActionIds ?? this.selectedBranchActionIds,
      testState: testState ?? this.testState,
      acceptedEvidenceIds: acceptedEvidenceIds ?? this.acceptedEvidenceIds,
      pendingEvidence: pendingEvidence ?? this.pendingEvidence,
      mode: mode ?? this.mode,
      assessmentAttemptId: clearAssessmentAttemptId
          ? null
          : assessmentAttemptId ?? this.assessmentAttemptId,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      cameraScale: cameraScale ?? this.cameraScale,
      cameraOffsetX: cameraOffsetX ?? this.cameraOffsetX,
      cameraOffsetY: cameraOffsetY ?? this.cameraOffsetY,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  MissionTestStatus testStatusFor(String targetId) {
    final value = testState[targetId];
    final statusName = value is Map ? value['status'] : value;
    if (statusName is! String) return MissionTestStatus.idle;
    for (final status in MissionTestStatus.values) {
      if (status.name == statusName) return status;
    }
    return MissionTestStatus.idle;
  }

  MissionRuntimeState withTestStatus(
    String targetId,
    MissionTestStatus status,
  ) =>
      copyWith(
        testState: {
          ...testState,
          targetId: {'status': status.name},
        },
      );

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'missionId': missionId,
        'currentPhaseId': currentPhaseId,
        'completedPhaseIds': completedPhaseIds.toList(),
        'interactionCompletedPhaseIds': interactionCompletedPhaseIds.toList(),
        'hotspotStates': hotspotStates.map(
          (id, state) => MapEntry(id, state.name),
        ),
        'selectedToolId': selectedToolId,
        'toolApplications': Map<String, String>.from(toolApplications),
        'connectedNodePairs': connectedNodePairs.toList(),
        'placements': Map<String, String>.from(placements),
        'configurationValues': _jsonCopy(configurationValues),
        'sequenceOrder': List<String>.from(sequenceOrder),
        'matches': Map<String, String>.from(matches),
        'observations': _jsonCopy(observations),
        'interpretations': _jsonCopy(interpretations),
        'revealedFactIds': revealedFactIds.toList(),
        'selectedBranchActionIds': selectedBranchActionIds.toList(),
        'testState': _jsonCopy(testState),
        'acceptedEvidenceIds': acceptedEvidenceIds.toList(),
        'pendingEvidence':
            pendingEvidence.map((action) => action.toJson()).toList(),
        'mode': mode.name,
        'assessmentAttemptId': assessmentAttemptId,
        'reducedMotion': reducedMotion,
        'cameraScale': cameraScale,
        'cameraOffsetX': cameraOffsetX,
        'cameraOffsetY': cameraOffsetY,
        'updatedAt': updatedAt.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      other is MissionRuntimeState &&
      other.persistedSchemaVersion == persistedSchemaVersion &&
      other.missionId == missionId &&
      other.currentPhaseId == currentPhaseId &&
      _deepEquals(other.completedPhaseIds, completedPhaseIds) &&
      _deepEquals(
        other.interactionCompletedPhaseIds,
        interactionCompletedPhaseIds,
      ) &&
      _deepEquals(other.hotspotStates, hotspotStates) &&
      other.selectedToolId == selectedToolId &&
      _deepEquals(other.toolApplications, toolApplications) &&
      _deepEquals(other.connectedNodePairs, connectedNodePairs) &&
      _deepEquals(other.placements, placements) &&
      _deepEquals(other.configurationValues, configurationValues) &&
      _deepEquals(other.sequenceOrder, sequenceOrder) &&
      _deepEquals(other.matches, matches) &&
      _deepEquals(other.observations, observations) &&
      _deepEquals(other.interpretations, interpretations) &&
      _deepEquals(other.revealedFactIds, revealedFactIds) &&
      _deepEquals(other.selectedBranchActionIds, selectedBranchActionIds) &&
      _deepEquals(other.testState, testState) &&
      _deepEquals(other.acceptedEvidenceIds, acceptedEvidenceIds) &&
      _deepEquals(other.pendingEvidence, pendingEvidence) &&
      other.mode == mode &&
      other.assessmentAttemptId == assessmentAttemptId &&
      other.reducedMotion == reducedMotion &&
      other.cameraScale == cameraScale &&
      other.cameraOffsetX == cameraOffsetX &&
      other.cameraOffsetY == cameraOffsetY &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hashAll([
        persistedSchemaVersion,
        missionId,
        currentPhaseId,
        _deepHash(completedPhaseIds),
        _deepHash(interactionCompletedPhaseIds),
        _deepHash(hotspotStates),
        selectedToolId,
        _deepHash(toolApplications),
        _deepHash(connectedNodePairs),
        _deepHash(placements),
        _deepHash(configurationValues),
        _deepHash(sequenceOrder),
        _deepHash(matches),
        _deepHash(observations),
        _deepHash(interpretations),
        _deepHash(revealedFactIds),
        _deepHash(selectedBranchActionIds),
        _deepHash(testState),
        _deepHash(acceptedEvidenceIds),
        _deepHash(pendingEvidence),
        mode,
        assessmentAttemptId,
        reducedMotion,
        cameraScale,
        cameraOffsetX,
        cameraOffsetY,
        updatedAt,
      ]);
}

Map<String, dynamic> _immutableJsonMap(Map<String, dynamic> source) =>
    Map.unmodifiable(
        source.map((key, value) => MapEntry(key, _freezeJson(value))));

Object? _freezeJson(Object? value) {
  if (value is Map) {
    return Map.unmodifiable(value.map(
      (key, nestedValue) => MapEntry(key.toString(), _freezeJson(nestedValue)),
    ));
  }
  if (value is Iterable) {
    return List.unmodifiable(value.map(_freezeJson));
  }
  return value;
}

Object? _jsonCopy(Object? value) {
  if (value is Map) {
    return value.map(
        (key, nestedValue) => MapEntry(key.toString(), _jsonCopy(nestedValue)));
  }
  if (value is Iterable) {
    return value.map(_jsonCopy).toList();
  }
  return value;
}

Map<String, dynamic> _jsonMap(Object? value) =>
    Map<String, dynamic>.from(value as Map);

Map<String, dynamic> _jsonMapOrEmpty(Object? value) =>
    value == null ? const {} : _jsonMap(value);

List<dynamic> _jsonList(Object? value) =>
    value == null ? const [] : List<dynamic>.from(value as List);

List<String> _stringList(Object? value) =>
    _jsonList(value).map((item) => item as String).toList();

Set<String> _stringSet(Object? value) => Set<String>.from(_stringList(value));

Map<String, String> _stringMap(Object? value) {
  if (value == null) {
    return const {};
  }
  return Map<String, String>.from(value as Map);
}

Map<String, HotspotVisualState> _hotspotStates(Object? value) {
  if (value == null) {
    return const {};
  }
  return (value as Map).map(
    (id, state) => MapEntry(
      id as String,
      _enumByName(HotspotVisualState.values, state as String),
    ),
  );
}

T _enumByName<T extends Enum>(Iterable<T> values, String name) =>
    values.firstWhere((value) => value.name == name);

bool _deepEquals(Object? left, Object? right) {
  if (identical(left, right) || left == right) {
    return true;
  }
  if (left is Map && right is Map) {
    return left.length == right.length &&
        left.entries.every(
          (entry) =>
              right.containsKey(entry.key) &&
              _deepEquals(entry.value, right[entry.key]),
        );
  }
  if (left is Set && right is Set) {
    return left.length == right.length && left.every(right.contains);
  }
  if (left is Iterable && right is Iterable) {
    final leftValues = left.toList();
    final rightValues = right.toList();
    return leftValues.length == rightValues.length &&
        Iterable<int>.generate(leftValues.length).every(
            (index) => _deepEquals(leftValues[index], rightValues[index]));
  }
  return false;
}

int _deepHash(Object? value) {
  if (value is Map) {
    final hashes = value.entries
        .map((entry) =>
            Object.hash(_deepHash(entry.key), _deepHash(entry.value)))
        .toList()
      ..sort();
    return Object.hashAll(hashes);
  }
  if (value is Set) {
    final hashes = value.map(_deepHash).toList()..sort();
    return Object.hashAll(hashes);
  }
  if (value is Iterable) {
    return Object.hashAll(value.map(_deepHash));
  }
  return value.hashCode;
}
