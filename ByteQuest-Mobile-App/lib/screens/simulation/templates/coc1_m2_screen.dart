import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/soft_card.dart';
import '../../../core/widgets/app_button.dart';
import '../../../models/mission_model.dart';
import '../result_screen.dart';

/// COC1 Mission 2: Install Internal Components
/// Professional 2D Drag-and-Drop Simulation
class COC1M2Screen extends StatefulWidget {
  final Mission mission;

  const COC1M2Screen({
    super.key,
    required this.mission,
  });

  @override
  State<COC1M2Screen> createState() => _COC1M2ScreenState();
}

class _COC1M2ScreenState extends State<COC1M2Screen> {
  // Component installation tracking
  final Map<String, ComponentTask> _tasks = {};
  final List<String> _mistakes = [];
  int _score = 0;
  int _currentStep = 0;
  int _timeSpent = 0;
  Timer? _timer;
  String? _feedbackMessage;
  Color? _feedbackColor;

  // Installation sequence (enforces motherboard first)
  final List<String> _installationSequence = [
    'motherboard',
    'cpu',
    'ram',
    'storage',
    'cooling_fan',
    'psu',
  ];

  @override
  void initState() {
    super.initState();
    _initializeTasks();
    _startTimer();
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
      name: 'Storage (SSD/HDD)',
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

  bool _canInstallComponent(String componentId) {
    // Motherboard must be installed first
    if (componentId != 'motherboard') {
      final motherboardInstalled = _tasks['motherboard']?.isCompleted ?? false;
      if (!motherboardInstalled) {
        return false;
      }
    }

    // Check if already installed
    if (_tasks[componentId]?.isCompleted ?? false) {
      return false;
    }

    return true;
  }

  void _handleComponentDrop(String componentId, String targetZone) {
    final task = _tasks[componentId];
    if (task == null) return;

    setState(() {
      // Check motherboard-first rule
      if (!_canInstallComponent(componentId)) {
        _showFeedback(
          'Install the motherboard first before adding other internal components.',
          AppTheme.accentOrange,
        );
        return;
      }

      // Check if correct target zone
      if (targetZone == task.targetZone) {
        // Correct placement
        task.isCompleted = true;
        task.attempts = (task.attempts ?? 0) + 1;
        _score += task.points;
        _currentStep++;

        _showFeedback(
          'Correct! ${task.name} installed successfully.',
          AppTheme.accentGreen,
        );
      } else {
        // Incorrect placement
        task.attempts = (task.attempts ?? 0) + 1;

        final correctZone =
            _tasks.values.firstWhere((t) => t.targetZone == targetZone);
        _mistakes.add(
            '${task.name} placed in ${correctZone.zoneName} instead of ${task.zoneName}');

        _showFeedback(
          'Incorrect. ${task.name} does not belong in ${correctZone.zoneName}.',
          AppTheme.errorRed,
        );
      }
    });
  }

  void _showFeedback(String message, Color color) {
    setState(() {
      _feedbackMessage = message;
      _feedbackColor = color;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _feedbackMessage = null;
          _feedbackColor = null;
        });
      }
    });
  }

  bool get _allTasksCompleted {
    return _tasks.values.every((task) => task.isCompleted);
  }

  int get _completedTasksCount {
    return _tasks.values.where((task) => task.isCompleted).length;
  }

  void _resetMission() {
    setState(() {
      for (var task in _tasks.values) {
        task.isCompleted = false;
        task.attempts = 0;
      }
      _score = 0;
      _currentStep = 0;
      _mistakes.clear();
      _feedbackMessage = null;
      _feedbackColor = null;
    });
  }

  void _finishMission() {
    if (!_allTasksCompleted) {
      _showFeedback(
        'Complete all required component installations before finishing the mission.',
        AppTheme.accentOrange,
      );
      return;
    }

    _timer?.cancel();

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

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          mission: widget.mission,
          result: result,
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundOffWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.textDark),
          onPressed: () => _showExitDialog(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.mission.title,
              style: AppTheme.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              'Install the internal components',
              style: AppTheme.captionSmall.copyWith(
                color: AppTheme.textMedium,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textMedium),
            onPressed: _resetMission,
            tooltip: 'Reset',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Row(
                children: [
                  Icon(Icons.timer, size: 16, color: AppTheme.textMedium),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(_timeSpent),
                    style: AppTheme.labelMedium.copyWith(
                      color: AppTheme.textMedium,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Feedback Banner
            if (_feedbackMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: _feedbackColor?.withValues(alpha: 0.1),
                child: Row(
                  children: [
                    Icon(
                      _feedbackColor == AppTheme.accentGreen
                          ? Icons.check_circle
                          : (_feedbackColor == AppTheme.errorRed
                              ? Icons.error
                              : Icons.info),
                      color: _feedbackColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _feedbackMessage!,
                        style: AppTheme.bodySmall.copyWith(
                          color: _feedbackColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Progress Card
                    SoftCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Step $_currentStep of ${_tasks.length}',
                                style: AppTheme.labelSmall.copyWith(
                                  color: AppTheme.textMedium,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$_completedTasksCount/${_tasks.length} Installed',
                                style: AppTheme.labelLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppTheme.accentGradient,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.stars,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$_score pts',
                                  style: AppTheme.labelMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Checklist Panel
                    SoftCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.checklist,
                                size: 20,
                                color: AppTheme.primaryBlue,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Installation Checklist',
                                style: AppTheme.labelLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ..._installationSequence.map((componentId) {
                            final task = _tasks[componentId]!;
                            final isCurrent =
                                _currentStep == task.order && !task.isCompleted;
                            return _buildChecklistItem(task, isCurrent);
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Workspace - System Unit Case with Drop Zones
                    Text(
                      'System Unit Workspace',
                      style: AppTheme.headlineSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildWorkspaceArea(),
                    const SizedBox(height: 16),

                    // Component Tray
                    Text(
                      'Available Components',
                      style: AppTheme.headlineSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildComponentTray(),
                  ],
                ),
              ),
            ),

            // Finish Button
            Container(
              padding: const EdgeInsets.all(16),
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
                child: AppButton.primary(
                  label: 'Finish Mission',
                  icon: Icons.check_circle,
                  onPressed: _allTasksCompleted ? _finishMission : () {},
                  width: double.infinity,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItem(ComponentTask task, bool isCurrent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrent
            ? AppTheme.primaryBlue.withValues(alpha: 0.05)
            : (task.isCompleted
                ? AppTheme.accentGreen.withValues(alpha: 0.05)
                : Colors.transparent),
        border: Border.all(
          color: isCurrent
              ? AppTheme.primaryBlue
              : (task.isCompleted
                  ? AppTheme.accentGreen
                  : AppTheme.textLight.withValues(alpha: 0.2)),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            task.isCompleted
                ? Icons.check_circle
                : (isCurrent
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked),
            color: task.isCompleted
                ? AppTheme.accentGreen
                : (isCurrent ? AppTheme.primaryBlue : AppTheme.textLight),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.name,
                  style: AppTheme.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: task.isCompleted
                        ? AppTheme.accentGreen
                        : (isCurrent
                            ? AppTheme.primaryBlue
                            : AppTheme.textDark),
                  ),
                ),
                if (isCurrent) ...[
                  const SizedBox(height: 2),
                  Text(
                    task.instruction,
                    style: AppTheme.captionSmall.copyWith(
                      color: AppTheme.textMedium,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '+${task.points}',
            style: AppTheme.labelSmall.copyWith(
              color: AppTheme.accentOrange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspaceArea() {
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: AspectRatio(
        aspectRatio: 0.75,
        child: Stack(
          children: [
            // Background - Empty System Unit Case
            Positioned.fill(
              child: Image.asset(
                'assets/COC1/Mission 2/empty_system_unit_case.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      color: AppTheme.textLight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.textLight.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.computer,
                            size: 48,
                            color: AppTheme.textLight,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'System Unit Case',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Drop Zone Markers
            _buildDropZone(
                'motherboard_area', 'Motherboard\nArea', 0.15, 0.25, 0.7, 0.35),
            _buildDropZone('cpu_socket', 'CPU\nSocket', 0.35, 0.3, 0.3, 0.15),
            _buildDropZone('ram_slot', 'RAM\nSlot', 0.7, 0.3, 0.25, 0.2),
            _buildDropZone('drive_bay', 'Drive\nBay', 0.15, 0.65, 0.35, 0.25),
            _buildDropZone('fan_area', 'Fan\nArea', 0.55, 0.5, 0.35, 0.2),
            _buildDropZone('psu_bay', 'PSU\nBay', 0.2, 0.05, 0.6, 0.15),
          ],
        ),
      ),
    );
  }

  Widget _buildDropZone(
    String zoneId,
    String label,
    double left,
    double top,
    double width,
    double height,
  ) {
    final task = _tasks.values.firstWhere((t) => t.targetZone == zoneId);
    final isCompleted = task.isCompleted;

    return Positioned(
      left: left * 100,
      top: top * 100,
      width: width * 100,
      height: height * 100,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return DragTarget<String>(
            onWillAccept: (data) => data != null,
            onAccept: (componentId) =>
                _handleComponentDrop(componentId, zoneId),
            builder: (context, candidateData, rejectedData) {
              final isHovering = candidateData.isNotEmpty;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppTheme.accentGreen.withValues(alpha: 0.2)
                      : (isHovering
                          ? AppTheme.primaryBlue.withValues(alpha: 0.3)
                          : AppTheme.textDark.withValues(alpha: 0.1)),
                  border: Border.all(
                    color: isCompleted
                        ? AppTheme.accentGreen
                        : (isHovering ? AppTheme.primaryBlue : Colors.white),
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: isCompleted
                      ? Icon(
                          Icons.check_circle,
                          color: AppTheme.accentGreen,
                          size: constraints.maxWidth * 0.3,
                        )
                      : Text(
                          label,
                          textAlign: TextAlign.center,
                          style: AppTheme.captionSmall.copyWith(
                            color: isHovering
                                ? AppTheme.primaryBlue
                                : Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: constraints.maxWidth * 0.08,
                          ),
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildComponentTray() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _tasks.values.map((task) {
        return _buildDraggableComponent(task);
      }).toList(),
    );
  }

  Widget _buildDraggableComponent(ComponentTask task) {
    final canDrag = _canInstallComponent(task.id);
    final isCompleted = task.isCompleted;

    if (isCompleted) {
      return Opacity(
        opacity: 0.4,
        child: _buildComponentCard(task, false),
      );
    }

    return Draggable<String>(
      data: task.id,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: _buildComponentCard(task, true),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildComponentCard(task, false),
      ),
      child: canDrag
          ? _buildComponentCard(task, false)
          : Opacity(
              opacity: 0.5,
              child: _buildComponentCard(task, false),
            ),
    );
  }

  Widget _buildComponentCard(ComponentTask task, bool isFeedback) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isFeedback ? AppTheme.primaryBlue : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFeedback
              ? AppTheme.primaryBlue
              : AppTheme.textLight.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Component Image
          Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              color: isFeedback
                  ? Colors.white.withValues(alpha: 0.2)
                  : AppTheme.textLight.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                task.imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.memory,
                    size: 40,
                    color: isFeedback ? Colors.white : AppTheme.textLight,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Component Name
          Text(
            task.name,
            textAlign: TextAlign.center,
            style: AppTheme.labelMedium.copyWith(
              color: isFeedback ? Colors.white : AppTheme.textDark,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
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
