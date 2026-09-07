import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/mission_header.dart';
import '../../../core/widgets/step_progress_card.dart';
import '../../../core/widgets/feedback_card.dart';
import '../../../models/mission_model.dart';
import '../../../data/mission_content_data.dart';
import '../../../services/auth_service.dart';
import '../../../services/progress_resume_service.dart';
import '../../../services/authoritative_assessment_service.dart';
import '../legacy_practice_evidence_scope.dart';
import '../components/practice_mission_chrome.dart';
import '../components/stable_mission_feedback_overlay.dart';
import '../result_screen.dart';

/// COC1 Mission 3: Connect Power and Data Cables - Enhanced UI
/// Professional cable matching simulation following the reference UI
class COC1M3ScreenEnhanced extends StatefulWidget {
  final Mission mission;

  const COC1M3ScreenEnhanced({
    super.key,
    required this.mission,
  });

  @override
  State<COC1M3ScreenEnhanced> createState() => _COC1M3ScreenEnhancedState();
}

class _COC1M3ScreenEnhancedState extends State<COC1M3ScreenEnhanced> {
  bool get _assessmentMode =>
      AuthoritativeAssessmentService.instance.isAssessmentMode;
  // Cable connection tracking
  final Map<String, CableConnection> _connections = {};
  final List<String> _mistakes = [];
  int _score = 0;
  int _timeSpent = 0;
  int _incorrectAttempts = 0;
  Timer? _timer;
  String? _feedbackMessage;
  String? _feedbackSubtitle;
  FeedbackType? _feedbackType;
  String? _selectedCableId;
  bool _isSaving = false;

  bool get _hasProgress =>
      _connections.values.any((connection) => connection.isConnected) ||
      _selectedCableId != null ||
      _incorrectAttempts > 0 ||
      _mistakes.isNotEmpty;

  // Cable lists
  final List<CableData> _cables = [];
  final List<PortData> _ports = [];

  @override
  void initState() {
    super.initState();
    _initializeCables();
    _loadProgressState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initializeCables() {
    final components = MissionContentData.getCOC1M3Components();
    final dropZones = MissionContentData.getCOC1M3DropZones();

    for (var i = 0; i < components.length; i++) {
      final component = components[i];
      _cables.add(CableData(
        id: component.id,
        name: _getCableDisplayName(component.id),
        description: component.description ?? '',
        targetZone: component.targetZone,
        points: 20,
        imagePath: _getCableImagePath(component.id),
      ));

      _connections[component.id] = CableConnection(
        cableId: component.id,
        targetPortId: component.targetZone,
        isConnected: false,
      );
    }

    for (var zone in dropZones) {
      _ports.add(PortData(
        id: zone.id,
        name: _getPortDisplayName(zone.id),
        position: _getPortPosition(zone.id),
      ));
    }
  }

  String _getCableDisplayName(String id) {
    switch (id) {
      case '24pin_cable':
        return '24-pin ATX';
      case 'cpu_power':
        return 'CPU Power';
      case 'sata_data':
        return 'SATA Data';
      case 'sata_power':
        return 'SATA Power';
      case 'front_panel':
        return 'Front Panel';
      default:
        return id;
    }
  }

  String _getCableImagePath(String id) {
    switch (id) {
      case '24pin_cable':
        return 'assets/COC1/Mission 3/24 Pin ATX.png';
      case 'cpu_power':
        return 'assets/COC1/Mission 3/CPU Power.png';
      case 'sata_data':
        return 'assets/COC1/Mission 3/Sata Cable.png';
      case 'sata_power':
        return 'assets/COC1/Mission 3/Sata Power.png';
      case 'front_panel':
        return 'assets/COC1/Mission 3/Front Panel.png';
      default:
        return 'assets/COC1/Mission 3/24 Pin ATX.png';
    }
  }

  String _getPortDisplayName(String id) {
    switch (id) {
      case 'cpu_power_port':
        return 'CPU PWR';
      case 'motherboard_power':
        return 'ATX 24-PIN';
      case 'storage_data':
        return 'SATA DATA';
      case 'storage_power':
        return 'SATA PWR';
      case 'front_panel_pins':
        return 'Front Panel';
      default:
        return id;
    }
  }

  Offset _getPortPosition(String portId) {
    // Define port positions on the System Unit image (normalized coords 0.0 - 1.0)
    switch (portId) {
      case 'cpu_power_port':
        return const Offset(0.58, 0.25);
      case 'motherboard_power':
        return const Offset(0.74, 0.33);
      case 'storage_data':
        return const Offset(0.74, 0.44);
      case 'storage_power':
        return const Offset(0.74, 0.54);
      case 'front_panel_pins':
        return const Offset(0.55, 0.47);
      default:
        return const Offset(0.5, 0.5);
    }
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

  // Load progress from SharedPreferences or Supabase DB
  void _loadProgressState() async {
    final userId = AuthService().currentUserId;
    if (userId == null) return;

    final state = await ProgressResumeService.loadState(
      userId: userId,
      missionId: widget.mission.id,
    );

    if (state != null) {
      setState(() {
        if (state['from_db'] == true) {
          final percentage = state['percentage'] as int;
          final completedCount = (percentage * _cables.length / 100).round();
          for (var i = 0; i < completedCount && i < _cables.length; i++) {
            final cableId = _cables[i].id;
            _connections[cableId]?.isConnected = true;
            _score += _cables[i].points;
          }
        } else {
          final stateData = state['stateData'] as Map<String, dynamic>;
          _score = stateData['score'] as int? ?? 0;
          _timeSpent = stateData['timeSpent'] as int? ?? 0;
          _incorrectAttempts = stateData['incorrectAttempts'] as int? ?? 0;
          if (stateData['mistakes'] != null) {
            _mistakes.addAll(List<String>.from(stateData['mistakes']));
          }
          final completedCables =
              stateData['completedCables'] as List<dynamic>? ?? [];
          for (var cableId in completedCables) {
            if (_connections.containsKey(cableId)) {
              _connections[cableId]!.isConnected = true;
            }
          }
        }
      });
    }
  }

  // Save progress state to SharedPreferences and update Supabase DB
  void _saveProgressState() async {
    final userId = AuthService().currentUserId;
    if (userId == null) return;

    final completedCables = _connections.entries
        .where((e) => e.value.isConnected)
        .map((e) => e.key)
        .toList();

    await ProgressResumeService.saveState(
      userId: userId,
      missionId: widget.mission.id,
      cocId: widget.mission.cocId,
      currentStep: completedCables.length,
      totalSteps: _connections.length,
      stateData: {
        'score': _score,
        'timeSpent': _timeSpent,
        'incorrectAttempts': _incorrectAttempts,
        'mistakes': _mistakes,
        'completedCables': completedCables,
      },
    );
  }

  void _handleCableSelection(String cableId) {
    final connection = _connections[cableId];
    if (connection?.isConnected ?? false) {
      _showFeedback(
        'This cable is already connected.',
        FeedbackType.info,
      );
      return;
    }

    setState(() {
      _selectedCableId = cableId;
    });

    _showFeedback(
      'Selected ${_getCableDisplayName(cableId)}. Tap the correct port on the workspace.',
      FeedbackType.info,
    );
  }

  void _handlePortTap(String portId) {
    if (_selectedCableId == null) {
      _showFeedback(
        'Select a cable first, then tap on a port.',
        FeedbackType.warning,
      );
      return;
    }

    _connectCableToPort(
      _selectedCableId!,
      portId,
      interactionMethod: 'select_then_place',
    );
  }

  void _connectCableToPort(
    String cableId,
    String portId, {
    String interactionMethod = 'drag',
  }) {
    final connection = _connections[cableId];
    if (connection == null) return;

    final cable = _cables.firstWhere((c) => c.id == cableId);
    unawaited(LegacyPracticeEvidenceScope.record(
      context,
      phaseId: 'connection_$cableId',
      actionType: 'cable_connection_attempted',
      target: portId,
      value: {
        'cable_id': cableId,
        'local_mission_id': widget.mission.id,
        'interaction_method': interactionMethod,
      },
    ));

    setState(() {
      connection.attempts = (connection.attempts ?? 0) + 1;

      if (portId == connection.targetPortId) {
        connection.isConnected = true;
        _score += cable.points;
        _selectedCableId = null;

        _showFeedback(
          'Correct! ${_getCableDisplayName(cableId)} connected.',
          FeedbackType.success,
          subtitle: _getSuccessMessage(cableId),
        );

        _saveProgressState();
      } else {
        _incorrectAttempts++;
        final port = _ports.firstWhere((p) => p.id == portId);
        _mistakes.add(
            '${cable.name} connected to ${port.name} instead of correct port');

        _showFeedback(
          'Incorrect. ${cable.name} does not connect to ${port.name}.',
          FeedbackType.error,
          subtitle: 'Double check the port and try again!',
        );
      }
    });
  }

  String _getSuccessMessage(String cableId) {
    switch (cableId) {
      case '24pin_cable':
        return 'Great job! You\'re powering up the motherboard.';
      case 'cpu_power':
        return 'Excellent! The CPU now has auxiliary power.';
      case 'sata_data':
        return 'Perfect! High-speed data cable connected to the drive.';
      case 'sata_power':
        return 'Awesome! Power cable connected to the storage device.';
      case 'front_panel':
        return 'Good! The front buttons and LEDs are connected.';
      default:
        return 'Connection established!';
    }
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

  bool get _allCablesConnected {
    return _connections.values.every((conn) => conn.isConnected);
  }

  int get _connectedCount {
    return _connections.values.where((conn) => conn.isConnected).length;
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
      debugPrint('Error saving simulation results: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _finishMission() async {
    if (!_allCablesConnected) {
      _showFeedback(
        'Connect all cables before finishing.',
        FeedbackType.warning,
      );
      return;
    }

    _timer?.cancel();

    // Save everything in Supabase
    await _saveResultsToDatabase();

    if (!mounted) return;

    final accuracy = _connections.isEmpty
        ? 0
        : ((_connectedCount / _connections.length) * 100).toInt();

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
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final isShortScreen = screenHeight < 680;
    final isCompactLandscape =
        screenSize.width > screenHeight && screenHeight <= 400;

    return PracticeMissionExitGuard(
      mission: widget.mission,
      hasProgress: () => _hasProgress,
      builder: (context, requestExit) => Scaffold(
        backgroundColor: AppTheme.backgroundOffWhite,
        body: SafeArea(
          child: _isSaving
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Saving your results...',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      )
                    ],
                  ),
                )
              : StableMissionFeedbackOverlay(
                  top: 88,
                  feedback: _feedbackMessage != null && _feedbackType != null
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: FeedbackCard(
                            type: _feedbackType!,
                            message: _feedbackMessage!,
                            subtitle: _feedbackSubtitle,
                            showRobot: true,
                            dismissible: true,
                            onDismiss: _dismissFeedback,
                          ),
                        )
                      : null,
                  child: Column(
                    children: [
                      // Enhanced Header
                      MissionHeader(
                        mission: widget.mission,
                        subtitle: '',
                        onBackPressed: requestExit,
                      ),

                      // Step Progress Card
                      if (!isCompactLandscape)
                        StepProgressCard(
                          currentStep: 3,
                          totalSteps: 5,
                          xpReward:
                              _assessmentMode ? 0 : widget.mission.xpReward,
                          modeLabel:
                              _assessmentMode ? 'Assessment' : 'Practice',
                          progress: _connectedCount / _connections.length,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),

                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: isCompactLandscape
                              ? _buildWorkspaceCard()
                              : Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Left side: Progress checklist and Tip Card (Flex 4)
                                    Expanded(
                                      flex: 4,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Expanded(
                                            child: _buildChecklistCard(
                                                isShortScreen),
                                          ),
                                          const SizedBox(height: 8),
                                          _buildTipCard(isShortScreen),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Right side: workspace system unit motherboard (Flex 6)
                                    Expanded(
                                      flex: 6,
                                      child: _buildWorkspaceCard(),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Cable Selection Cards Drawer
                      _buildCableSelectionSection(isShortScreen),

                      // Bottom Action Button
                      _buildBottomButton(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildTipCard(bool isShort) {
    return Container(
      padding: EdgeInsets.all(isShort ? 8 : 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb,
            color: AppTheme.primaryBlue,
            size: isShort ? 16 : 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tip',
                  style: TextStyle(
                    fontSize: isShort ? 10 : 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Match each cable to its correct port.',
                  style: TextStyle(
                    fontSize: isShort ? 9 : 10.5,
                    color: AppTheme.textMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistCard(bool isShort) {
    return Container(
      padding: EdgeInsets.all(isShort ? 10 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your progress',
            style: TextStyle(
              fontSize: isShort ? 12 : 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          Text(
            '$_connectedCount of ${_connections.length} connected',
            style: TextStyle(
              fontSize: isShort ? 10 : 11.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: _cables.length,
              itemBuilder: (context, index) {
                final cable = _cables[index];
                final connection = _connections[cable.id]!;
                final isConnected = connection.isConnected;

                return Padding(
                  padding: EdgeInsets.symmetric(vertical: isShort ? 4 : 6),
                  child: Row(
                    children: [
                      Icon(
                        isConnected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: isConnected
                            ? AppTheme.accentGreen
                            : AppTheme.textLight.withOpacity(0.5),
                        size: isShort ? 16 : 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              cable.name == '24-pin ATX'
                                  ? '24-pin ATX Cable'
                                  : cable.name == 'SATA Power'
                                      ? 'Storage Power Cable'
                                      : cable.name == 'Front Panel'
                                          ? 'Front Panel Connectors'
                                          : '${cable.name} Cable',
                              style: TextStyle(
                                fontSize: isShort ? 10 : 11,
                                fontWeight: isConnected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isConnected
                                    ? AppTheme.textDark
                                    : AppTheme.textDark.withOpacity(0.7),
                                decoration: isConnected
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (isConnected)
                              Text(
                                'Connected',
                                style: TextStyle(
                                  fontSize: isShort ? 8.5 : 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.accentGreen,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspaceCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          return InteractiveViewer(
            minScale: 1,
            maxScale: 3,
            boundaryMargin: const EdgeInsets.all(80),
            child: SizedBox(
              width: w,
              height: h,
              child: Stack(
                children: [
                  // 1. Motherboard Case Base Image
                  Positioned.fill(
                    child: Image.asset(
                      'assets/COC1/Mission 3/System Unit.png',
                      fit: BoxFit.cover,
                    ),
                  ),

                  // 2. Custom Painter to draw Glowing Bezier wires
                  Positioned.fill(
                    child: CustomPaint(
                      painter: CablePainter(
                        connectedCables: _connections.entries
                            .where((e) => e.value.isConnected)
                            .map((e) => e.key)
                            .toSet(),
                      ),
                    ),
                  ),

                  // 3. Port Markers & Drag Targets
                  ..._ports.map((port) => _buildPortMarker(port, w, h)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPortMarker(PortData port, double w, double h) {
    final connection = _connections.values.firstWhere(
      (conn) => conn.targetPortId == port.id,
    );
    final isConnected = connection.isConnected;
    final isSelectedTarget = !_assessmentMode &&
        _selectedCableId != null &&
        _connections[_selectedCableId]?.targetPortId == port.id;

    // Relative coordinates
    final left = port.position.dx * w;
    final top = port.position.dy * h;

    // Size configurations based on port type
    double boxWidth = 56;
    double boxHeight = 56;

    if (port.id == 'motherboard_power') {
      boxWidth = 56;
      boxHeight = 72;
    }

    return Positioned(
      left: left - (boxWidth / 2),
      top: top - (boxHeight / 2),
      child: Semantics(
        button: true,
        label: _assessmentMode ? 'Cable connection target' : port.name,
        value: isConnected ? 'Connected' : 'Available',
        hint: _selectedCableId == null
            ? 'Select a cable first, or drag one here.'
            : 'Double tap to connect the selected cable.',
        child: DragTarget<String>(
          onWillAcceptWithDetails: (details) => !isConnected,
          onAcceptWithDetails: (details) =>
              _connectCableToPort(details.data, port.id),
          builder: (context, candidateData, rejectedData) {
            final isHovering = candidateData.isNotEmpty;

            Color borderColor;
            Color fillColor;

            if (isConnected) {
              borderColor = AppTheme.accentGreen;
              fillColor = AppTheme.accentGreen.withOpacity(0.15);
            } else if (isHovering || isSelectedTarget) {
              borderColor = AppTheme.primaryBlue;
              fillColor = AppTheme.primaryBlue.withOpacity(0.2);
            } else if (_assessmentMode) {
              borderColor = Colors.transparent;
              fillColor = Colors.transparent;
            } else {
              borderColor = AppTheme.primaryBlue.withOpacity(0.5);
              fillColor = Colors.black.withOpacity(0.25);
            }

            return GestureDetector(
              onTap: isConnected ? null : () => _handlePortTap(port.id),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Highlight box around port
                  Container(
                    width: boxWidth,
                    height: boxHeight,
                    decoration: BoxDecoration(
                      color: fillColor,
                      border: Border.all(
                        color: borderColor,
                        width: isSelectedTarget || isHovering || isConnected
                            ? 2
                            : 1,
                        style:
                            isConnected ? BorderStyle.solid : BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: (isSelectedTarget || isHovering || isConnected)
                          ? [
                              BoxShadow(
                                color: borderColor.withOpacity(0.4),
                                blurRadius: 8,
                                spreadRadius: 1,
                              )
                            ]
                          : null,
                    ),
                    child: isConnected
                        ? const Center(
                            child: Icon(
                              Icons.check_circle,
                              color: AppTheme.accentGreen,
                              size: 16,
                            ),
                          )
                        : null,
                  ),

                  // Port Label Badge (above/below the box)
                  if (!_assessmentMode || isHovering || isConnected)
                    Positioned(
                      top: port.id == 'cpu_power_port'
                          ? -18
                          : (port.id == 'front_panel_pins'
                              ? -18
                              : boxHeight + 2),
                      left: (boxWidth / 2) - 35,
                      child: Container(
                        width: 70,
                        padding: const EdgeInsets.symmetric(
                            vertical: 2, horizontal: 4),
                        decoration: BoxDecoration(
                          color: isConnected
                              ? AppTheme.accentGreen
                              : const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isConnected
                                ? AppTheme.accentGreen
                                : Colors.blue.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            port.name,
                            style: const TextStyle(
                              fontSize: 7.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCableSelectionSection(bool isShort) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.symmetric(vertical: isShort ? 6 : 10, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Drag a cable to the correct connection',
                style: TextStyle(
                  fontSize: isShort ? 11 : 12.5,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF334155),
                ),
              ),
              Icon(
                Icons.info_outline,
                size: isShort ? 14 : 16,
                color: Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _cables.map((cable) {
                final connection = _connections[cable.id]!;
                final isSelected = _selectedCableId == cable.id;
                final isConnected = connection.isConnected;

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child:
                      _buildCableCard(cable, isSelected, isConnected, isShort),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCableCard(
      CableData cable, bool isSelected, bool isConnected, bool isShort) {
    final card = Container(
      width: isShort ? 80 : 90,
      padding: EdgeInsets.all(isShort ? 4 : 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? AppTheme.primaryBlue
              : (isConnected
                  ? AppTheme.accentGreen
                  : Colors.black.withOpacity(0.08)),
          width: isSelected || isConnected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.15),
                  blurRadius: 6,
                  spreadRadius: 1,
                )
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cable Image representation
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: isShort ? 45 : 55,
                width: isShort ? 55 : 65,
                padding: const EdgeInsets.all(2),
                child: Image.asset(
                  cable.imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.cable,
                      size: isShort ? 24 : 32,
                      color: AppTheme.textLight,
                    );
                  },
                ),
              ),
              if (isConnected)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppTheme.accentGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            cable.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isShort ? 8.5 : 9.5,
              fontWeight: FontWeight.bold,
              color: isConnected ? AppTheme.accentGreen : AppTheme.textDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    if (isConnected) {
      return Semantics(
        button: true,
        enabled: false,
        label: '${cable.name}, connected',
        child: Opacity(
          opacity: 0.5,
          child: card,
        ),
      );
    }

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${cable.name}${isSelected ? ", selected" : ""}',
      hint:
          'Double tap to select, then activate a cable connection target. You can also drag it.',
      child: GestureDetector(
        onTap: () => _handleCableSelection(cable.id),
        child: Draggable<String>(
          data: cable.id,
          dragAnchorStrategy: pointerDragAnchorStrategy,
          maxSimultaneousDrags: 1,
          feedback: Material(
            color: Colors.transparent,
            child: Opacity(
              opacity: 0.85,
              child: card,
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.35,
            child: card,
          ),
          child: card,
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
            onPressed: _allCablesConnected ? _finishMission : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              disabledBackgroundColor: AppTheme.textLight.withOpacity(0.3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Row(
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

// Custom Painter to draw Glowing Bezier curves
class CablePainter extends CustomPainter {
  final Set<String> connectedCables;

  CablePainter({required this.connectedCables});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.accentGreen
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = AppTheme.accentGreen.withOpacity(0.35)
      ..strokeWidth = 7.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    // ATX 24-Pin Cable drawing
    if (connectedCables.contains('24pin_cable')) {
      final path = Path()
        ..moveTo(w * 0.55, h * 0.9) // grommet entry
        ..cubicTo(
          w * 0.65, h * 0.8,
          w * 0.70, h * 0.50,
          w * 0.74, h * 0.33, // ATX 24-pin socket (exact match)
        );
      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, paint);
    }

    // CPU Power Cable drawing
    if (connectedCables.contains('cpu_power')) {
      final path = Path()
        ..moveTo(w * 0.50, h * 0.9)
        ..cubicTo(
          w * 0.35, h * 0.8,
          w * 0.40, h * 0.4,
          w * 0.58, h * 0.25, // CPU power port (exact match)
        );
      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, paint);
    }

    // SATA Data Cable drawing
    if (connectedCables.contains('sata_data')) {
      final path = Path()
        ..moveTo(w * 0.74, h * 0.44) // SATA DATA port (exact match)
        ..quadraticBezierTo(
          w * 0.82, h * 0.44,
          w * 0.88, h * 0.50, // SSD bay area
        );
      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, paint);
    }

    // SATA Power Cable drawing
    if (connectedCables.contains('sata_power')) {
      final path = Path()
        ..moveTo(w * 0.60, h * 0.9)
        ..cubicTo(
          w * 0.68, h * 0.82,
          w * 0.72, h * 0.64,
          w * 0.74, h * 0.54, // SATA PWR port (exact match)
        );
      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, paint);
    }

    // Front Panel Cable drawing
    if (connectedCables.contains('front_panel')) {
      final path = Path()
        ..moveTo(w * 0.55, h * 0.47) // Front Panel header (exact match)
        ..quadraticBezierTo(
          w * 0.53, h * 0.70,
          w * 0.55, h * 0.90, // Grommet entry
        );
      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CablePainter oldDelegate) {
    return oldDelegate.connectedCables != connectedCables;
  }
}

// Models used locally
class CableData {
  final String id;
  final String name;
  final String description;
  final String targetZone;
  final int points;
  final String imagePath;

  CableData({
    required this.id,
    required this.name,
    required this.description,
    required this.targetZone,
    required this.points,
    required this.imagePath,
  });
}

class PortData {
  final String id;
  final String name;
  final Offset position;

  PortData({
    required this.id,
    required this.name,
    required this.position,
  });
}

class CableConnection {
  final String cableId;
  final String targetPortId;
  bool isConnected;
  int? attempts;

  CableConnection({
    required this.cableId,
    required this.targetPortId,
    this.isConnected = false,
    this.attempts,
  });
}
