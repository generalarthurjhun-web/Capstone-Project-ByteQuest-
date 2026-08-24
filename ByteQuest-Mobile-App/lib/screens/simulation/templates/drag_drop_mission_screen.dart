import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/soft_card.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/simulation_fullscreen_button.dart';
import '../../../models/mission_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/progress_resume_service.dart';
import '../../../services/authoritative_assessment_service.dart';
import '../legacy_practice_evidence_scope.dart';
import '../result_screen.dart';

/// Template 2: Drag and Drop Mission Screen
/// Used for: COC1-M2, COC1-M3, COC2-M2, COC2-M4
class DragDropMissionScreen extends StatefulWidget {
  final Mission mission;
  final List<DraggableComponent> components;
  final List<DropZone> dropZones;

  const DragDropMissionScreen({
    super.key,
    required this.mission,
    required this.components,
    required this.dropZones,
  });

  @override
  State<DragDropMissionScreen> createState() => _DragDropMissionScreenState();
}

class _DragDropMissionScreenState extends State<DragDropMissionScreen> {
  final Map<String, String?> _placedComponents = {};
  final Map<String, bool> _componentValidation = {};
  bool _showValidation = false;
  int _timeSpent = 0;
  Timer? _timer;
  int _correctPlacements = 0;
  List<String> _mistakes = [];
  String? _selectedComponentId;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Initialize drop zones as empty
    for (var zone in widget.dropZones) {
      _placedComponents[zone.id] = null;
    }
    _loadProgressState();
  }

  Future<void> _loadProgressState() async {
    final userId = AuthService().currentUserId;
    if (userId == null) return;

    final state = await ProgressResumeService.loadState(
      userId: userId,
      missionId: widget.mission.id,
    );

    if (state != null && state['stateData'] != null) {
      final data = state['stateData'] as Map<String, dynamic>;
      setState(() {
        _timeSpent = data['timeSpent'] ?? 0;
        _correctPlacements = data['correctPlacements'] ?? 0;
        _mistakes = List<String>.from(data['mistakes'] ?? []);

        final placed = data['placedComponents'] as Map<String, dynamic>?;
        if (placed != null) {
          placed.forEach((key, val) {
            _placedComponents[key] = val as String?;
          });
        }
      });
      debugPrint('Loaded state for drag & drop.');
    }
  }

  Future<void> _saveProgressState() async {
    final userId = AuthService().currentUserId;
    if (userId == null) return;

    final stateData = {
      'timeSpent': _timeSpent,
      'correctPlacements': _correctPlacements,
      'mistakes': _mistakes,
      'placedComponents': _placedComponents,
    };

    final completedCount =
        _placedComponents.values.where((v) => v != null).length;

    await ProgressResumeService.saveState(
      userId: userId,
      missionId: widget.mission.id,
      cocId: widget.mission.cocId,
      currentStep: completedCount,
      totalSteps: widget.dropZones.length,
      stateData: stateData,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _timeSpent++;
        });
      }
    });
  }

  bool _isComponentPlaced(String componentId) {
    return _placedComponents.values.contains(componentId);
  }

  void _placeComponent(
    String zoneId,
    String componentId, {
    String interactionMethod = 'drag',
  }) {
    setState(() {
      // Remove component from any previous zone
      _placedComponents.forEach((key, value) {
        if (value == componentId) {
          _placedComponents[key] = null;
        }
      });

      // Place in new zone
      _placedComponents[zoneId] = componentId;
      _showValidation = false;
      _componentValidation.clear();
      _selectedComponentId = null;
    });
    unawaited(LegacyPracticeEvidenceScope.record(
      context,
      phaseId: 'placement_$zoneId',
      actionType: 'component_placed',
      target: zoneId,
      value: {
        'component_id': componentId,
        'local_mission_id': widget.mission.id,
        'interaction_method': interactionMethod,
      },
    ));
    _saveProgressState();
  }

  void _removeComponent(String zoneId) {
    final removedComponent = _placedComponents[zoneId];
    setState(() {
      _placedComponents[zoneId] = null;
      _showValidation = false;
      _componentValidation.clear();
    });
    unawaited(LegacyPracticeEvidenceScope.record(
      context,
      phaseId: 'placement_$zoneId',
      actionType: 'component_removed',
      target: zoneId,
      value: {
        'component_id': removedComponent,
        'local_mission_id': widget.mission.id
      },
    ));
    _saveProgressState();
  }

  void _validatePlacements() {
    setState(() {
      _showValidation = true;
      _correctPlacements = 0;
      _mistakes.clear();

      for (var zone in widget.dropZones) {
        final placedId = _placedComponents[zone.id];
        if (placedId != null) {
          final isCorrect = zone.acceptedComponents.contains(placedId);
          _componentValidation[zone.id] = isCorrect;

          if (isCorrect) {
            _correctPlacements++;
          } else {
            final component =
                widget.components.firstWhere((c) => c.id == placedId);
            _mistakes
                .add('${component.name} placed incorrectly in ${zone.name}');
          }
        } else {
          _componentValidation[zone.id] = false;
          _mistakes.add('${zone.name} is empty');
        }
      }
    });
    unawaited(LegacyPracticeEvidenceScope.record(
      context,
      phaseId: 'placement_review',
      actionType: 'placement_validation_requested',
      target: widget.mission.id,
      value: {
        'observed_placements': Map<String, String?>.from(_placedComponents)
      },
    ));
    _saveProgressState();

    // If all correct, auto-finish after 2 seconds
    if (_correctPlacements == widget.dropZones.length) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _finishMission();
        }
      });
    }
  }

  void _finishMission() {
    _timer?.cancel();

    final userId = AuthService().currentUserId;
    if (userId != null) {
      ProgressResumeService.clearState(
        userId: userId,
        missionId: widget.mission.id,
      );
    }

    final totalComponents = widget.dropZones.length;
    final accuracy = ((_correctPlacements / totalComponents) * 100).toInt();

    final result = MissionResult(
      missionId: widget.mission.id,
      score: accuracy,
      percentage: accuracy,
      passed: false,
      xpEarned: 0,
      timeSpent: _timeSpent,
      rating: 'practice-feedback',
      competencyStatus: 'awaiting-trusted-evaluation',
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          mission: widget.mission,
          result: result,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allPlaced = widget.components.every((c) => _isComponentPlaced(c.id));
    final assessmentMode =
        AuthoritativeAssessmentService.instance.isAssessmentMode;

    return Scaffold(
      backgroundColor: AppTheme.backgroundOffWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.textDark),
          onPressed: () => _showExitDialog(),
        ),
        title: Text(
          widget.mission.title,
          style: AppTheme.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          const SimulationFullscreenButton(),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                _formatTime(_timeSpent),
                style: AppTheme.labelMedium.copyWith(
                  color: AppTheme.textMedium,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Instruction Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: AppTheme.primaryBlue.withValues(alpha: 0.05),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      assessmentMode
                          ? 'Assessment mode: drag an item, or select it and then choose a neutral placement area. Destinations never reveal the answer.'
                          : 'Practice mode: drag an item, or select it and then choose a labeled position.',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Progress Info
                    SoftCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Components',
                                style: AppTheme.labelSmall.copyWith(
                                  color: AppTheme.textMedium,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.components.where((c) => _isComponentPlaced(c.id)).length}/${widget.components.length} Placed',
                                style: AppTheme.labelLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          if (_showValidation) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _correctPlacements ==
                                        widget.dropZones.length
                                    ? AppTheme.accentGreen
                                        .withValues(alpha: 0.1)
                                    : AppTheme.accentOrange
                                        .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _correctPlacements ==
                                            widget.dropZones.length
                                        ? Icons.check_circle
                                        : Icons.warning,
                                    size: 16,
                                    color: _correctPlacements ==
                                            widget.dropZones.length
                                        ? AppTheme.accentGreen
                                        : AppTheme.accentOrange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$_correctPlacements/${widget.dropZones.length} Correct',
                                    style: AppTheme.labelSmall.copyWith(
                                      color: _correctPlacements ==
                                              widget.dropZones.length
                                          ? AppTheme.accentGreen
                                          : AppTheme.accentOrange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Available Components
                    Text(
                      'Available Components',
                      style: AppTheme.headlineSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: widget.components.map((component) {
                        final isPlaced = _isComponentPlaced(component.id);
                        final isSelected = _selectedComponentId == component.id;

                        return Semantics(
                          button: true,
                          enabled: !isPlaced,
                          selected: isSelected,
                          label: isPlaced
                              ? '${component.name}, already placed'
                              : '${component.name}${isSelected ? ", selected" : ""}',
                          hint: isPlaced
                              ? 'Remove it from its placement area to move it.'
                              : 'Double tap to select, then activate a placement area. You can also drag it.',
                          child: Draggable<String>(
                            data: component.id,
                            dragAnchorStrategy: pointerDragAnchorStrategy,
                            feedback: Material(
                              elevation: 8,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  component.name,
                                  style: AppTheme.labelMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.3,
                              child: _buildComponentChip(
                                component,
                                isPlaced,
                                isSelected: false,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: isPlaced
                                  ? null
                                  : () => setState(() {
                                        _selectedComponentId =
                                            isSelected ? null : component.id;
                                      }),
                              child: _buildComponentChip(
                                component,
                                isPlaced,
                                isSelected: isSelected,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),

                    // Drop Zones
                    Text(
                      assessmentMode
                          ? 'Simulation workspace'
                          : 'Installation areas',
                      style: AppTheme.headlineSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    InteractiveViewer(
                      minScale: 0.9,
                      maxScale: 2.4,
                      panEnabled: false,
                      clipBehavior: Clip.none,
                      child: Column(
                        children: widget.dropZones.asMap().entries.map((entry) {
                          final zoneIndex = entry.key;
                          final zone = entry.value;
                          final placedId = _placedComponents[zone.id];
                          final showFeedback = _showValidation &&
                              _componentValidation.containsKey(zone.id);
                          final isCorrect =
                              _componentValidation[zone.id] ?? false;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Semantics(
                              button: true,
                              label: assessmentMode
                                  ? 'Placement area ${zoneIndex + 1}${placedId == null ? ", empty" : ", contains ${widget.components.firstWhere((component) => component.id == placedId).name}"}'
                                  : '${zone.name}${placedId == null ? ", empty" : ", contains ${widget.components.firstWhere((component) => component.id == placedId).name}"}',
                              hint: _selectedComponentId == null
                                  ? 'Select an available component first, or drag one here.'
                                  : 'Double tap to place the selected component here.',
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: _selectedComponentId == null
                                    ? null
                                    : () => _placeComponent(
                                          zone.id,
                                          _selectedComponentId!,
                                          interactionMethod:
                                              'select_then_place',
                                        ),
                                child: DragTarget<String>(
                                  onWillAcceptWithDetails: (_) => true,
                                  onAcceptWithDetails: (details) =>
                                      _placeComponent(zone.id, details.data),
                                  builder:
                                      (context, candidateData, rejectedData) {
                                    final isHovering = candidateData.isNotEmpty;

                                    return Container(
                                      key: ValueKey('drop-zone-${zone.id}'),
                                      constraints:
                                          const BoxConstraints(minHeight: 96),
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: isHovering
                                            ? AppTheme.primaryBlue
                                                .withValues(alpha: 0.1)
                                            : (showFeedback
                                                ? (isCorrect
                                                    ? AppTheme.accentGreen
                                                        .withValues(alpha: 0.05)
                                                    : AppTheme.errorRed
                                                        .withValues(
                                                            alpha: 0.05))
                                                : (assessmentMode
                                                    ? Colors.transparent
                                                    : Colors.white)),
                                        border: Border.all(
                                          color: isHovering
                                              ? AppTheme.primaryBlue
                                              : (showFeedback
                                                  ? (isCorrect
                                                      ? AppTheme.accentGreen
                                                      : AppTheme.errorRed)
                                                  : (assessmentMode
                                                      ? Colors.transparent
                                                      : AppTheme.textLight
                                                          .withValues(
                                                              alpha: 0.2))),
                                          width: 2,
                                          strokeAlign:
                                              BorderSide.strokeAlignInside,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.04),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  assessmentMode &&
                                                          placedId == null &&
                                                          !isHovering
                                                      ? ' '
                                                      : (assessmentMode
                                                          ? 'Placement area'
                                                          : zone.name),
                                                  style: AppTheme.labelLarge
                                                      .copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              if (showFeedback) ...[
                                                Icon(
                                                  isCorrect
                                                      ? Icons.check_circle
                                                      : Icons.cancel,
                                                  color: isCorrect
                                                      ? AppTheme.accentGreen
                                                      : AppTheme.errorRed,
                                                  size: 24,
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          if (placedId != null) ...[
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      gradient: AppTheme
                                                          .primaryGradient,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: Text(
                                                      widget.components
                                                          .firstWhere((c) =>
                                                              c.id == placedId)
                                                          .name,
                                                      style: AppTheme
                                                          .labelMedium
                                                          .copyWith(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  icon: const Icon(Icons.close,
                                                      size: 20),
                                                  onPressed: () =>
                                                      _removeComponent(zone.id),
                                                  style: IconButton.styleFrom(
                                                    backgroundColor: AppTheme
                                                        .textLight
                                                        .withValues(alpha: 0.1),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ] else ...[
                                            Container(
                                              height: 48,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: assessmentMode
                                                    ? Colors.transparent
                                                    : AppTheme.textLight
                                                        .withValues(
                                                            alpha: 0.05),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: assessmentMode
                                                      ? Colors.transparent
                                                      : AppTheme.textLight
                                                          .withValues(
                                                              alpha: 0.2),
                                                  style: BorderStyle.solid,
                                                ),
                                              ),
                                              child: Text(
                                                assessmentMode
                                                    ? ''
                                                    : 'Drop component here',
                                                style:
                                                    AppTheme.bodySmall.copyWith(
                                                  color: AppTheme.textLight,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    if (_showValidation &&
                        _correctPlacements < widget.dropZones.length) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.accentOrange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppTheme.accentOrange,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Some components are incorrectly placed. Review and try again.',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.accentOrange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    AppButton.primary(
                      label: _showValidation &&
                              _correctPlacements == widget.dropZones.length
                          ? 'View Results'
                          : 'Check Placements',
                      icon: Icons.check,
                      onPressed: allPlaced ? _validatePlacements : () {},
                      width: double.infinity,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComponentChip(
    DraggableComponent component,
    bool isPlaced, {
    required bool isSelected,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 96, minHeight: 48),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: isPlaced ? null : AppTheme.primaryGradient,
        color: isPlaced ? AppTheme.textLight.withValues(alpha: 0.2) : null,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: AppTheme.accentYellow, width: 3)
            : isPlaced
                ? Border.all(
                    color: AppTheme.textLight.withValues(alpha: 0.3),
                  )
                : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSelected) ...[
            const Icon(
              Icons.radio_button_checked_rounded,
              size: 18,
              color: Colors.white,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            component.name,
            style: AppTheme.labelMedium.copyWith(
              color: isPlaced ? AppTheme.textLight : Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Exit Mission?'),
        content: const Text(
            'Your progress will not be saved. Are you sure you want to exit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorRed,
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}
