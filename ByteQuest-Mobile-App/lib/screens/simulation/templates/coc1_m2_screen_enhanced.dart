import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/mission_header.dart';
import '../../../core/widgets/step_progress_card.dart';
import '../../../core/widgets/instruction_card.dart';
import '../../../core/widgets/feedback_card.dart';
import '../../../models/mission_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/progress_resume_service.dart';
import '../../../services/authoritative_assessment_service.dart';
import '../legacy_practice_evidence_scope.dart';
import '../result_screen.dart';

/// COC1 Mission 2: Install Internal Components - Enhanced UI
/// Professional 2D Drag-and-Drop Simulation with Reference UI
class COC1M2ScreenEnhanced extends StatefulWidget {
  final Mission mission;

  const COC1M2ScreenEnhanced({
    super.key,
    required this.mission,
  });

  @override
  State<COC1M2ScreenEnhanced> createState() => _COC1M2ScreenEnhancedState();
}

class _COC1M2ScreenEnhancedState extends State<COC1M2ScreenEnhanced> {
  bool get _assessmentMode =>
      AuthoritativeAssessmentService.instance.isAssessmentMode;
  // Component installation tracking
  final Map<String, ComponentTask> _tasks = {};
  late List<String> _mistakes = [];
  int _score = 0;
  int _currentStep = 0;
  int _timeSpent = 0;
  int _incorrectAttempts = 0;
  String? _selectedComponentId;
  Timer? _timer;
  String? _feedbackMessage;
  FeedbackType? _feedbackType;
  String? _feedbackSubtitle;
  bool _isSaving = false;

  // Custom states added for redesign
  String? _installedStorageType;
  final List<String> _trayComponents = [
    'motherboard',
    'cpu',
    'ram',
    'ssd',
    'hdd',
    'cooling_fan',
    'psu',
  ];

  // Installation sequence (enforces motherboard first)
  final List<String> _installationSequence = [
    'motherboard',
    'cpu',
    'ram',
    'storage',
    'cooling_fan',
    'psu',
  ];

  int get _displayedStep => _installationSequence.isEmpty
      ? 0
      : (_currentStep + 1).clamp(1, _installationSequence.length);

  @override
  void initState() {
    super.initState();
    _initializeTasks();
    _startTimer();
    _loadProgressState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initializeTasks() {
    _tasks['motherboard'] = ComponentTask(
      id: 'motherboard',
      name: 'Motherboard',
      imagePath: 'assets/COC1/Mission 2/motherboard.png',
      targetZone: 'motherboard_area',
      zoneName: 'Motherboard Area',
      instruction: 'Install the motherboard into the case',
      points: 15,
      order: 0,
    );

    _tasks['cpu'] = ComponentTask(
      id: 'cpu',
      name: 'CPU',
      imagePath: 'assets/COC1/Mission 2/cpu.png',
      targetZone: 'cpu_socket',
      zoneName: 'CPU Socket',
      instruction: 'Install the CPU into the socket',
      points: 15,
      order: 1,
    );

    _tasks['ram'] = ComponentTask(
      id: 'ram',
      name: 'RAM',
      imagePath: 'assets/COC1/Mission 2/ram.png',
      targetZone: 'ram_slot',
      zoneName: 'RAM Slot',
      instruction: 'Insert RAM into the memory slot',
      points: 15,
      order: 2,
    );

    _tasks['storage'] = ComponentTask(
      id: 'storage',
      name: 'Storage',
      imagePath: 'assets/COC1/Mission 2/ssd.png',
      alternateImagePath: 'assets/COC1/Mission 2/hdd.png',
      targetZone: 'drive_bay',
      zoneName: 'Drive Bay',
      instruction: 'Mount SSD or HDD in drive bay',
      points: 15,
      order: 3,
    );

    _tasks['cooling_fan'] = ComponentTask(
      id: 'cooling_fan',
      name: 'Cooling Fan',
      imagePath: 'assets/COC1/Mission 2/cooling_fan.png',
      targetZone: 'fan_area',
      zoneName: 'Fan Area',
      instruction: 'Install cooling fan/heatsink',
      points: 15,
      order: 4,
    );

    _tasks['psu'] = ComponentTask(
      id: 'psu',
      name: 'Power Supply',
      imagePath: 'assets/COC1/Mission 2/psu.png',
      targetZone: 'psu_bay',
      zoneName: 'PSU Bay',
      instruction: 'Install power supply unit',
      points: 15,
      order: 5,
    );
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
        _currentStep = data['currentStep'] ?? 0;
        _score = data['score'] ?? 0;
        _incorrectAttempts = data['incorrectAttempts'] ?? 0;
        _timeSpent = data['timeSpent'] ?? 0;
        _mistakes = List<String>.from(data['mistakes'] ?? []);
        _installedStorageType = data['installedStorageType'];

        final tasksProgress = data['tasksProgress'] as Map<String, dynamic>?;
        if (tasksProgress != null) {
          tasksProgress.forEach((key, val) {
            final t = _tasks[key];
            if (t != null) {
              t.isCompleted = val['isCompleted'] ?? false;
              t.attempts = val['attempts'] ?? 0;
            }
          });
        }
      });
      debugPrint(
          'Loaded simulation state. Starting at step index: $_currentStep');
    }
  }

  Future<void> _saveProgressState() async {
    final userId = AuthService().currentUserId;
    if (userId == null) return;

    final Map<String, dynamic> tasksProgress = {};
    _tasks.forEach((key, task) {
      tasksProgress[key] = {
        'isCompleted': task.isCompleted,
        'attempts': task.attempts,
      };
    });

    final stateData = {
      'currentStep': _currentStep,
      'score': _score,
      'incorrectAttempts': _incorrectAttempts,
      'timeSpent': _timeSpent,
      'mistakes': _mistakes,
      'installedStorageType': _installedStorageType,
      'tasksProgress': tasksProgress,
    };

    await ProgressResumeService.saveState(
      userId: userId,
      missionId: widget.mission.id,
      cocId: widget.mission.cocId,
      currentStep: _displayedStep,
      totalSteps: _installationSequence.length,
      stateData: stateData,
    );
  }

  Future<void> _saveResultsToDatabase() async {
    final userId = AuthService().currentUserId;
    if (userId == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await ProgressResumeService.clearState(
        userId: userId,
        missionId: widget.mission.id,
      );
    } catch (e) {
      debugPrint('Error saving internal component results: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  bool _isComponentCompleted(String componentId) {
    if (componentId == 'ssd') {
      return (_tasks['storage']?.isCompleted ?? false) &&
          _installedStorageType == 'ssd';
    }
    if (componentId == 'hdd') {
      return (_tasks['storage']?.isCompleted ?? false) &&
          _installedStorageType == 'hdd';
    }
    return _tasks[componentId]?.isCompleted ?? false;
  }

  bool _isComponentActive(String componentId) {
    if (_currentStep >= _installationSequence.length) return false;
    final currentTaskId = _installationSequence[_currentStep];
    if (currentTaskId == 'storage') {
      return componentId == 'ssd' || componentId == 'hdd';
    }
    return componentId == currentTaskId;
  }

  bool _isComponentDisabled(String componentId) {
    if ((componentId == 'ssd' || componentId == 'hdd') &&
        (_tasks['storage']?.isCompleted ?? false)) {
      if (componentId == 'ssd' && _installedStorageType != 'ssd') return true;
      if (componentId == 'hdd' && _installedStorageType != 'hdd') return true;
    }
    return _isComponentCompleted(componentId) ||
        !_isComponentActive(componentId);
  }

  bool _canInstallComponent(String componentId) {
    if (_currentStep >= _installationSequence.length) {
      return false;
    }
    final currentTaskId = _installationSequence[_currentStep];
    if (currentTaskId == 'storage') {
      return componentId == 'ssd' || componentId == 'hdd';
    }
    return componentId == currentTaskId;
  }

  void _handleComponentDrop(
    String componentId,
    String targetZone, {
    String interactionMethod = 'drag',
  }) {
    unawaited(LegacyPracticeEvidenceScope.record(
      context,
      phaseId: 'placement_$targetZone',
      actionType: 'component_drop_attempted',
      target: targetZone,
      value: {
        'component_id': componentId,
        'local_mission_id': widget.mission.id,
        'interaction_method': interactionMethod,
      },
    ));
    // 1. Identify dropped task
    String taskId = componentId;
    if (componentId == 'ssd' ||
        componentId == 'hdd' ||
        componentId == 'storage') {
      taskId = 'storage';
    } else if (componentId == 'heatsink' || componentId == 'cooling_fan') {
      taskId = 'cooling_fan';
    } else if (componentId == 'power_supply' || componentId == 'psu') {
      taskId = 'psu';
    }
    final droppedTask = _tasks[taskId];
    if (droppedTask == null) return;

    // 2. Identify task associated with this targetZone
    ComponentTask? zoneTask;
    if (targetZone == 'drive_bay') {
      zoneTask = _tasks['storage'];
    } else {
      for (var t in _tasks.values) {
        if (t.targetZone == targetZone) {
          zoneTask = t;
          break;
        }
      }
    }

    if (zoneTask == null) return;

    setState(() {
      _selectedComponentId = null;
      // Check if dropped component belongs in this targetZone
      if (zoneTask!.id != taskId) {
        droppedTask.attempts = (droppedTask.attempts ?? 0) + 1;
        _incorrectAttempts++;
        _mistakes.add(
            '${droppedTask.name} placed in ${zoneTask.zoneName} instead of ${droppedTask.zoneName}');
        _showFeedback(
          'Incorrect placement.',
          FeedbackType.error,
          subtitle:
              '${droppedTask.name} does not belong in the ${zoneTask.zoneName}.',
        );
        _saveProgressState();
        return;
      }

      // Check validation sequence
      if (!_canInstallComponent(componentId)) {
        final currentTaskId = _installationSequence[_currentStep];
        droppedTask.attempts = (droppedTask.attempts ?? 0) + 1;
        _incorrectAttempts++;
        _showFeedback(
          'Install components in order.',
          FeedbackType.warning,
          subtitle: 'Please install the ${_tasks[currentTaskId]?.name} first!',
        );
        _saveProgressState();
        return;
      }

      // Correct drop & sequence!
      if (componentId == 'ssd' || componentId == 'hdd') {
        _installedStorageType = componentId;
      }
      droppedTask.isCompleted = true;
      droppedTask.attempts = (droppedTask.attempts ?? 0) + 1;
      _score += droppedTask.points;
      _currentStep++;

      _saveProgressState();

      String nextPartName = '';
      if (_currentStep < _installationSequence.length) {
        final nextTaskId = _installationSequence[_currentStep];
        nextPartName = _tasks[nextTaskId]?.name ?? '';
      }

      _showFeedback(
        'Good job! ${droppedTask.name} installed.',
        FeedbackType.success,
        subtitle: nextPartName.isNotEmpty
            ? 'Next: place the $nextPartName.'
            : 'All parts placed! Click Finish Mission.',
      );
    });
  }

  void _showFeedback(String message, FeedbackType type, {String? subtitle}) {
    setState(() {
      _feedbackMessage = message;
      _feedbackType = type;
      _feedbackSubtitle = subtitle;
    });
  }

  void _dismissFeedback() {
    setState(() {
      _feedbackMessage = null;
      _feedbackType = null;
      _feedbackSubtitle = null;
    });
  }

  bool get _allTasksCompleted {
    return _tasks.values.every((task) => task.isCompleted);
  }

  int get _completedTasksCount {
    return _tasks.values.where((task) => task.isCompleted).length;
  }

  void _finishMission() async {
    if (!_allTasksCompleted) {
      _showFeedback(
        'Complete installations first.',
        FeedbackType.warning,
        subtitle:
            'Complete all required component installations before finishing.',
      );
      return;
    }

    _timer?.cancel();

    await _saveResultsToDatabase();

    final accuracy = _tasks.isEmpty
        ? 0
        : ((_completedTasksCount / _tasks.length) * 100).toInt();

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

    if (!mounted) return;

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
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final isTablet = screenWidth > 600;
    final isCompactHeight = screenSize.height < 640;

    final currentTask = _currentStep >= _installationSequence.length
        ? null
        : _tasks[_installationSequence[_currentStep]];

    return Scaffold(
      backgroundColor: AppTheme.backgroundOffWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            MissionHeader(
              missionNumber: 2,
              title: 'Install Internal Components',
              subtitle: '',
              onBackPressed: () => Navigator.pop(context),
            ),

            // Body Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 16.0, right: 16.0, top: 4.0, bottom: 0.0),
                child: Column(
                  children: [
                    // Step Progress Card
                    if (!isCompactHeight) ...[
                      StepProgressCard(
                        currentStep: _displayedStep,
                        totalSteps: _installationSequence.length,
                        xpReward: _assessmentMode ? 0 : widget.mission.xpReward,
                        modeLabel: _assessmentMode ? 'Assessment' : 'Practice',
                        progress: _completedTasksCount / _tasks.length,
                        margin: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 4),
                    ],

                    // Instruction Card
                    InstructionCard(
                      icon: Icons.touch_app,
                      instruction: currentTask != null
                          ? (_assessmentMode
                              ? 'Install the selected component in the correct location.'
                              : 'Drag the ${currentTask.name} to the ${currentTask.zoneName}.')
                          : 'All components installed!',
                      highlightedText:
                          _assessmentMode ? null : currentTask?.zoneName,
                      points:
                          _assessmentMode ? null : (currentTask?.points ?? 15),
                    ),
                    const SizedBox(height: 4),

                    // Feedback Card (when shown)
                    if (_feedbackMessage != null && _feedbackType != null) ...[
                      FeedbackCard(
                        type: _feedbackType!,
                        message: _feedbackMessage!,
                        subtitle: _feedbackSubtitle,
                        showRobot: true,
                        dismissible: true,
                        onDismiss: _dismissFeedback,
                      ),
                      const SizedBox(height: 4),
                    ],

                    // Main workspace columns
                    Expanded(
                      child: isTablet
                          ? _buildTabletLayout()
                          : _buildMobileLayout(),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom button
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        if (isLandscape) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildWorkspaceCard()),
              const SizedBox(width: 8),
              SizedBox(
                width: 75,
                child: _buildVerticalComponentTray(),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _buildWorkspaceCard()),
            const SizedBox(height: 8),
            _buildHorizontalComponentTray(),
          ],
        );
      },
    );
  }

  Widget _buildHorizontalComponentTray() {
    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _trayComponents.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) =>
            _buildDraggableComponentCard(_trayComponents[index], false),
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left: Step Tracker (wider)
        SizedBox(
          width: 140,
          child: _buildCompactStepTracker(wide: true),
        ),
        const SizedBox(width: 16),

        // Center: Workspace
        Expanded(
          child: Center(
            child: _buildWorkspaceCard(),
          ),
        ),
        const SizedBox(width: 16),

        // Right: Available Parts (wider)
        SizedBox(
          width: 140,
          child: _buildVerticalComponentTray(wide: true),
        ),
      ],
    );
  }

  Widget _buildCompactStepTracker({bool wide = false}) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      shrinkWrap: false,
      padding: EdgeInsets.zero,
      itemCount: _installationSequence.length,
      itemBuilder: (context, index) {
        final componentId = _installationSequence[index];
        final isLast = index == _installationSequence.length - 1;
        return _buildStepTrackerCard(componentId, index + 1, isLast, wide);
      },
    );
  }

  Widget _buildStepTrackerCard(
      String stepId, int stepNumber, bool isLast, bool wide) {
    final task = _tasks[stepId]!;
    final isCompleted = task.isCompleted;
    final isCurrent = _currentStep == stepNumber - 1;
    final isLocked = stepNumber - 1 > _currentStep;
    final icon = _getComponentIcon(stepId);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: wide ? 130 : 70,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            color: isCurrent ? Colors.white : Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isCurrent
                  ? AppTheme.primaryBlue
                  : (isCompleted
                      ? AppTheme.accentGreen.withOpacity(0.5)
                      : AppTheme.textLight.withOpacity(0.15)),
              width: isCurrent ? 2 : 1.2,
            ),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: wide
              ? Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppTheme.accentGreen
                            : (isCurrent
                                ? AppTheme.primaryBlue.withOpacity(0.1)
                                : AppTheme.backgroundOffWhite),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCompleted ? Icons.check : icon,
                        size: 14,
                        color: isCompleted
                            ? Colors.white
                            : (isCurrent
                                ? AppTheme.primaryBlue
                                : AppTheme.textMedium),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        stepId == 'storage' ? 'Storage' : task.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isCompleted
                              ? AppTheme.accentGreen
                              : (isCurrent
                                  ? AppTheme.primaryBlue
                                  : AppTheme.textDark),
                          fontSize: 11,
                          fontWeight:
                              isCurrent ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? AppTheme.accentGreen
                                : (isCurrent
                                    ? AppTheme.primaryBlue.withOpacity(0.1)
                                    : AppTheme.backgroundOffWhite),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCompleted ? Icons.check : icon,
                            size: 14,
                            color: isCompleted
                                ? Colors.white
                                : (isCurrent
                                    ? AppTheme.primaryBlue
                                    : AppTheme.textMedium),
                          ),
                        ),
                        if (!isCompleted)
                          Positioned(
                            left: 0,
                            top: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? AppTheme.primaryBlue
                                    : AppTheme.textMedium,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 1.2),
                              ),
                              child: Center(
                                child: Text(
                                  '$stepNumber',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 7,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 28,
                      width: 28,
                      padding: const EdgeInsets.all(2),
                      child: Opacity(
                        opacity: isLocked ? 0.3 : 1.0,
                        child: Image.asset(
                          _getComponentImagePath(
                              stepId == 'storage' ? 'ssd' : stepId),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(icon, size: 12, color: AppTheme.textLight),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stepId == 'storage' ? 'Storage' : task.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isCompleted
                            ? AppTheme.accentGreen
                            : (isCurrent
                                ? AppTheme.primaryBlue
                                : AppTheme.textMedium),
                        fontSize: 8.5,
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
        ),
        if (!isLast)
          CustomPaint(
            size: const Size(2, 16),
            painter: _DashedLinePainter(
              color: isCompleted
                  ? AppTheme.accentGreen
                  : AppTheme.textLight.withOpacity(0.3),
            ),
          ),
      ],
    );
  }

  Widget _buildVerticalComponentTray({bool wide = false}) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      shrinkWrap: false,
      padding: EdgeInsets.zero,
      itemCount: _trayComponents.length,
      itemBuilder: (context, index) {
        final componentId = _trayComponents[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildDraggableComponentCard(componentId, wide),
        );
      },
    );
  }

  Widget _buildDraggableComponentCard(String componentId, bool wide) {
    final isCompleted = _isComponentCompleted(componentId);
    final isActive = _isComponentActive(componentId);
    final isDisabled = _isComponentDisabled(componentId);
    final isSelected = _selectedComponentId == componentId;

    final name = _getComponentDisplayName(componentId);
    final imagePath = _getComponentImagePath(componentId);
    final icon = _getComponentIcon(componentId);

    final card = Container(
      width: wide ? 130 : 70,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected
              ? AppTheme.accentYellow
              : isActive
                  ? AppTheme.primaryBlue
                  : (isCompleted
                      ? AppTheme.accentGreen.withOpacity(0.5)
                      : AppTheme.textLight.withOpacity(0.15)),
          width: isSelected ? 3 : (isActive ? 2 : 1.2),
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      child: wide
          ? Row(
              children: [
                Container(
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.primaryBlue.withOpacity(0.05)
                        : AppTheme.backgroundOffWhite,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(icon, size: 14, color: AppTheme.textLight),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isCompleted
                          ? AppTheme.accentGreen
                          : (isActive
                              ? AppTheme.primaryBlue
                              : AppTheme.textMedium),
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
                if (isCompleted)
                  const Icon(
                    Icons.check_circle,
                    size: 12,
                    color: AppTheme.accentGreen,
                  ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.primaryBlue.withOpacity(0.05)
                        : AppTheme.backgroundOffWhite,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(icon, size: 14, color: AppTheme.textLight),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isCompleted
                        ? AppTheme.accentGreen
                        : (isActive
                            ? AppTheme.primaryBlue
                            : AppTheme.textMedium),
                    fontSize: 8.5,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                if (isCompleted)
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.check_circle,
                      size: 10,
                      color: AppTheme.accentGreen,
                    ),
                  ),
              ],
            ),
    );

    if (isCompleted || isDisabled || !isActive) {
      return Semantics(
        button: true,
        enabled: false,
        label: '$name, unavailable',
        child: Opacity(
          opacity: isDisabled ? 0.35 : 1.0,
          child: card,
        ),
      );
    }

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$name${isSelected ? ", selected" : ""}',
      hint:
          'Double tap to select, then activate a placement target. You can also drag it.',
      child: Draggable<String>(
        data: componentId,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        maxSimultaneousDrags: 1,
        feedback: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: wide ? 130 : 70,
            child: card,
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: card,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() {
            _selectedComponentId = isSelected ? null : componentId;
          }),
          child: card,
        ),
      ),
    );
  }

  Widget _buildWorkspaceCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.computer,
                size: 16,
                color: AppTheme.primaryBlue,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'System Unit',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.labelMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Center(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 3,
                boundaryMargin: const EdgeInsets.all(80),
                child: AspectRatio(
                  aspectRatio: 0.75,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.textLight.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.textLight.withOpacity(0.2),
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, workspaceConstraints) {
                        final ww = workspaceConstraints.maxWidth;
                        final wh = workspaceConstraints.maxHeight;
                        return Stack(
                          children: [
                            // Background - Empty System Unit Case
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  'assets/COC1/Mission 2/empty_system_unit_case.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: const Color(0xFF1a1a1a),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.computer,
                                              size: 48,
                                              color:
                                                  Colors.white.withOpacity(0.3),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'System Unit',
                                              style:
                                                  AppTheme.bodySmall.copyWith(
                                                color: Colors.white
                                                    .withOpacity(0.5),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),

                            // Installed Components Overlay Images
                            _buildInstalledComponent(
                                'motherboard_area',
                                'assets/COC1/Mission 2/motherboard.png',
                                0.12,
                                0.12,
                                0.52,
                                0.55,
                                ww,
                                wh),
                            _buildInstalledComponent(
                                'cpu_socket',
                                'assets/COC1/Mission 2/cpu.png',
                                0.20,
                                0.14,
                                0.24,
                                0.22,
                                ww,
                                wh),
                            _buildInstalledComponent(
                                'ram_slot',
                                'assets/COC1/Mission 2/ram.png',
                                0.50,
                                0.14,
                                0.13,
                                0.18,
                                ww,
                                wh),
                            if (_installedStorageType == 'ssd')
                              _buildInstalledComponent(
                                  'drive_bay',
                                  'assets/COC1/Mission 2/ssd.png',
                                  0.67,
                                  0.39,
                                  0.21,
                                  0.26,
                                  ww,
                                  wh)
                            else if (_installedStorageType == 'hdd')
                              _buildInstalledComponent(
                                  'drive_bay',
                                  'assets/COC1/Mission 2/hdd.png',
                                  0.67,
                                  0.39,
                                  0.21,
                                  0.26,
                                  ww,
                                  wh),
                            _buildInstalledComponent(
                                'fan_area',
                                'assets/COC1/Mission 2/cooling_fan.png',
                                0.10,
                                0.70,
                                0.24,
                                0.20,
                                ww,
                                wh),
                            _buildInstalledComponent(
                                'psu_bay',
                                'assets/COC1/Mission 2/psu.png',
                                0.52,
                                0.72,
                                0.36,
                                0.20,
                                ww,
                                wh),

                            // Drop Zone Markers (Dashed Rectangles)
                            _buildDropZone(
                                'motherboard_area',
                                'Motherboard Area',
                                0.15,
                                0.38,
                                0.42,
                                0.28,
                                ww,
                                wh),
                            _buildDropZone('cpu_socket', 'CPU Socket', 0.20,
                                0.14, 0.24, 0.22, ww, wh),
                            _buildDropZone('ram_slot', 'RAM Slot', 0.50, 0.14,
                                0.13, 0.18, ww, wh),
                            _buildDropZone('drive_bay', 'Drive Bay', 0.67, 0.39,
                                0.21, 0.26, ww, wh),
                            _buildDropZone('fan_area', 'Fan Area', 0.10, 0.70,
                                0.24, 0.20, ww, wh),
                            _buildDropZone('psu_bay', 'PSU Bay', 0.52, 0.72,
                                0.36, 0.20, ww, wh),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstalledComponent(
    String zoneId,
    String imagePath,
    double left,
    double top,
    double width,
    double height,
    double parentWidth,
    double parentHeight,
  ) {
    ComponentTask? task;
    if (zoneId == 'drive_bay') {
      task = _tasks['storage'];
    } else {
      task = _tasks.values.firstWhere((t) => t.targetZone == zoneId,
          orElse: () => _tasks.values.first);
    }

    if (task == null || !task.isCompleted) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: left * parentWidth,
      top: top * parentHeight,
      width: width * parentWidth,
      height: height * parentHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          imagePath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  IconData? _getZoneIcon(String zoneId) {
    switch (zoneId) {
      case 'cpu_socket':
        return Icons.memory;
      case 'drive_bay':
        return Icons.storage;
      case 'fan_area':
        return Icons.ac_unit;
      case 'psu_bay':
        return Icons.power;
      default:
        return null;
    }
  }

  Widget _buildDropZone(
    String zoneId,
    String label,
    double left,
    double top,
    double width,
    double height,
    double parentWidth,
    double parentHeight,
  ) {
    ComponentTask? task;
    if (zoneId == 'drive_bay') {
      task = _tasks['storage'];
    } else {
      task = _tasks.values.firstWhere((t) => t.targetZone == zoneId,
          orElse: () => _tasks.values.first);
    }
    final isCompleted = task?.isCompleted ?? false;
    final isCurrent = _isComponentActiveForZone(zoneId);
    final showCurrent = isCurrent && !_assessmentMode;
    final visualWidth = width * parentWidth;
    final visualHeight = height * parentHeight;
    final hitWidth = visualWidth < 48 ? 48.0 : visualWidth;
    final hitHeight = visualHeight < 48 ? 48.0 : visualHeight;
    final canShowZoneContent = visualWidth >= 48 && visualHeight >= 36;

    return Positioned(
      left: (left * parentWidth) - ((hitWidth - visualWidth) / 2),
      top: (top * parentHeight) - ((hitHeight - visualHeight) / 2),
      width: hitWidth,
      height: hitHeight,
      child: Semantics(
        container: true,
        button: true,
        label: _assessmentMode
            ? 'Component placement target'
            : '$label component placement target',
        value: isCompleted ? 'Completed' : 'Available',
        hint: _selectedComponentId == null
            ? 'Select an available component first, or drag one here.'
            : 'Double tap to place the selected component here.',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: isCompleted || _selectedComponentId == null
              ? null
              : () => _handleComponentDrop(
                    _selectedComponentId!,
                    zoneId,
                    interactionMethod: 'select_then_place',
                  ),
          child: DragTarget<String>(
            key: ValueKey('drop-target-$zoneId'),
            onWillAcceptWithDetails: (details) => !isCompleted,
            onAcceptWithDetails: (details) =>
                _handleComponentDrop(details.data, zoneId),
            builder: (context, candidateData, rejectedData) {
              final isHovering = candidateData.isNotEmpty;

              return Center(
                child: SizedBox(
                  width: visualWidth,
                  height: visualHeight,
                  child: CustomPaint(
                    painter: DashedRectPainter(
                      color: isCompleted
                          ? AppTheme.accentGreen.withOpacity(0.8)
                          : (isHovering
                              ? AppTheme.primaryBlue
                              : (showCurrent
                                  ? AppTheme.primaryBlue
                                  : (_assessmentMode
                                      ? Colors.transparent
                                      : Colors.white.withOpacity(0.4)))),
                      strokeWidth: isCompleted
                          ? 1.5
                          : (isHovering ? 2.5 : (showCurrent ? 2.0 : 1.2)),
                      gap: showCurrent ? 3.0 : 4.0,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.transparent
                            : (isHovering
                                ? AppTheme.primaryBlue.withOpacity(0.18)
                                : (showCurrent
                                    ? AppTheme.primaryBlue.withOpacity(0.06)
                                    : (_assessmentMode
                                        ? Colors.transparent
                                        : Colors.black.withOpacity(0.15)))),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: showCurrent
                            ? [
                                BoxShadow(
                                  color: AppTheme.primaryBlue.withOpacity(0.15),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: isCompleted
                            ? Align(
                                alignment: Alignment.topRight,
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: AppTheme.accentGreen,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(2),
                                    child: const Icon(
                                      Icons.check,
                                      size: 10,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              )
                            : ((_assessmentMode && !isHovering) ||
                                    !canShowZoneContent)
                                ? const SizedBox.shrink()
                                : Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (_getZoneIcon(zoneId) != null) ...[
                                          Icon(
                                            _getZoneIcon(zoneId),
                                            size: 18,
                                            color: isHovering
                                                ? AppTheme.primaryBlue
                                                : (showCurrent
                                                    ? AppTheme.primaryBlue
                                                        .withOpacity(0.9)
                                                    : Colors.white
                                                        .withOpacity(0.85)),
                                          ),
                                          const SizedBox(height: 4),
                                        ],
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            label,
                                            textAlign: TextAlign.center,
                                            style:
                                                AppTheme.captionSmall.copyWith(
                                              color: isHovering
                                                  ? AppTheme.primaryBlue
                                                  : (showCurrent
                                                      ? AppTheme.primaryBlue
                                                          .withOpacity(0.9)
                                                      : Colors.white
                                                          .withOpacity(0.85)),
                                              fontWeight:
                                                  isHovering || showCurrent
                                                      ? FontWeight.bold
                                                      : FontWeight.w600,
                                              fontSize: 8.5,
                                              shadows: isCurrent
                                                  ? null
                                                  : [
                                                      Shadow(
                                                        color: Colors.black
                                                            .withOpacity(0.7),
                                                        offset:
                                                            const Offset(0, 1),
                                                        blurRadius: 1.5,
                                                      ),
                                                    ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  bool _isComponentActiveForZone(String zoneId) {
    if (_currentStep >= _installationSequence.length) return false;
    final currentTaskId = _installationSequence[_currentStep];
    final task = _tasks[currentTaskId];
    return task?.targetZone == zoneId;
  }

  IconData _getComponentIcon(String componentId) {
    switch (componentId) {
      case 'motherboard':
        return Icons.developer_board;
      case 'cpu':
        return Icons.memory;
      case 'ram':
        return Icons.view_module;
      case 'storage':
      case 'ssd':
      case 'hdd':
        return Icons.storage;
      case 'cooling_fan':
        return Icons.ac_unit;
      case 'psu':
        return Icons.power;
      default:
        return Icons.hardware;
    }
  }

  String _getComponentDisplayName(String componentId) {
    switch (componentId) {
      case 'motherboard':
        return 'Motherboard';
      case 'cpu':
        return 'CPU';
      case 'ram':
        return 'RAM';
      case 'ssd':
        return 'SSD';
      case 'hdd':
        return 'HDD';
      case 'cooling_fan':
        return 'Cooling Fan';
      case 'psu':
        return 'PSU';
      default:
        return '';
    }
  }

  String _getComponentImagePath(String componentId) {
    switch (componentId) {
      case 'motherboard':
        return 'assets/COC1/Mission 2/motherboard.png';
      case 'cpu':
        return 'assets/COC1/Mission 2/cpu.png';
      case 'ram':
        return 'assets/COC1/Mission 2/ram.png';
      case 'ssd':
        return 'assets/COC1/Mission 2/ssd.png';
      case 'hdd':
        return 'assets/COC1/Mission 2/hdd.png';
      case 'cooling_fan':
        return 'assets/COC1/Mission 2/cooling_fan.png';
      case 'psu':
        return 'assets/COC1/Mission 2/psu.png';
      default:
        return '';
    }
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed:
                (_allTasksCompleted && !_isSaving) ? _finishMission : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              disabledBackgroundColor: AppTheme.textLight.withOpacity(0.3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.0,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Finish Mission',
                        style: AppTheme.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// Component Task Model
class ComponentTask {
  final String id;
  final String name;
  final String imagePath;
  final String? alternateImagePath;
  final String targetZone;
  final String zoneName;
  final String instruction;
  final int points;
  final int order;
  bool isCompleted;
  int? attempts;

  ComponentTask({
    required this.id,
    required this.name,
    required this.imagePath,
    this.alternateImagePath,
    required this.targetZone,
    required this.zoneName,
    required this.instruction,
    required this.points,
    required this.order,
    this.isCompleted = false,
    this.attempts,
  });
}

// Custom Painter to draw beautiful Dashed Rectangles
class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedRectPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.gap = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (color == Colors.transparent) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(8),
    ));

    double distance = 0.0;
    for (final pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        final length = gap;
        canvas.drawPath(
          pathMetric.extractPath(distance, distance + length),
          paint,
        );
        distance += length + gap;
      }
    }
  }

  @override
  bool shouldRepaint(DashedRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap;
  }
}

// Custom Painter to draw Dashed Lines (Vertical Timeline connectors)
class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width
      ..style = PaintingStyle.stroke;

    const dashHeight = 3.0;
    const dashSpace = 2.0;
    double startY = 0.0;
    while (startY < size.height) {
      canvas.drawLine(Offset(size.width / 2, startY),
          Offset(size.width / 2, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
