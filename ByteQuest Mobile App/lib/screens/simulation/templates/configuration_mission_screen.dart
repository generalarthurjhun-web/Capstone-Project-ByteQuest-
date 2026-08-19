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
import '../result_screen.dart';

/// Template 3: Configuration Form Mission Screen
/// Used for: COC1-M4, COC2-M5, COC3-M3, COC3-M4
class ConfigurationMissionScreen extends StatefulWidget {
  final Mission mission;
  final Map<String, dynamic> configData;

  const ConfigurationMissionScreen({
    super.key,
    required this.mission,
    required this.configData,
  });

  @override
  State<ConfigurationMissionScreen> createState() =>
      _ConfigurationMissionScreenState();
}

class _ConfigurationMissionScreenState
    extends State<ConfigurationMissionScreen> {
  bool get _assessmentMode =>
      AuthoritativeAssessmentService.instance.isAssessmentMode;
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String?> _selectedValues = {};
  final Map<String, bool> _fieldValidation = {};
  bool _showValidation = false;
  int _timeSpent = 0;
  Timer? _timer;
  int _correctFields = 0;
  List<String> _mistakes = [];

  @override
  void initState() {
    super.initState();
    _startTimer();
    _initializeFields();
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
        _correctFields = data['correctFields'] ?? 0;
        _mistakes = List<String>.from(data['mistakes'] ?? []);

        final values = data['fieldValues'] as Map<String, dynamic>?;
        if (values != null) {
          values.forEach((key, val) {
            if (_controllers.containsKey(key)) {
              _controllers[key]!.text = val as String? ?? '';
            } else {
              _selectedValues[key] = val as String?;
            }
          });
        }
      });
      debugPrint('Loaded state for configuration.');
    }
  }

  Future<void> _saveProgressState() async {
    final userId = AuthService().currentUserId;
    if (userId == null) return;

    final Map<String, String> fieldValues = {};
    _controllers.forEach((key, controller) {
      fieldValues[key] = controller.text;
    });
    _selectedValues.forEach((key, val) {
      if (val != null) {
        fieldValues[key] = val;
      }
    });

    final stateData = {
      'timeSpent': _timeSpent,
      'correctFields': _correctFields,
      'mistakes': _mistakes,
      'fieldValues': fieldValues,
    };

    int filledFields = 0;
    fieldValues.forEach((key, val) {
      if (val.isNotEmpty) filledFields++;
    });

    await ProgressResumeService.saveState(
      userId: userId,
      missionId: widget.mission.id,
      cocId: widget.mission.cocId,
      currentStep: filledFields,
      totalSteps: widget.configData.length,
      stateData: stateData,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
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

  void _initializeFields() {
    widget.configData.forEach((key, value) {
      if (value is Map) {
        _controllers[key] = TextEditingController();
      }
    });
  }

  void _validateConfiguration() {
    final submittedValues = <String, String>{
      for (final entry in _controllers.entries)
        entry.key: entry.value.text.trim(),
      for (final entry in _selectedValues.entries)
        if (entry.value != null) entry.key: entry.value!,
    };
    unawaited(AuthoritativeAssessmentService.instance.safeRecordAction(
      actionType: 'configuration_submitted',
      target: widget.mission.id,
      value: {
        'fields': submittedValues,
        'local_mission_id': widget.mission.id,
      },
    ));

    if (_assessmentMode) {
      _finishMission();
      return;
    }

    setState(() {
      _showValidation = true;
      _correctFields = 0;
      _mistakes.clear();
      _fieldValidation.clear();

      widget.configData.forEach((key, value) {
        if (value is Map) {
          final userInput = _controllers[key]?.text.trim() ?? '';
          final correctAnswer = value['correctAnswer'] as String?;
          final validation = value['validation'] as String?;

          bool isCorrect = false;
          if (validation != null) {
            final regex = RegExp(validation);
            isCorrect = regex.hasMatch(userInput);
          } else if (correctAnswer != null) {
            isCorrect = userInput.toLowerCase() == correctAnswer.toLowerCase();
          }

          _fieldValidation[key] = isCorrect;

          if (isCorrect) {
            _correctFields++;
          } else {
            final question = value['question'] as String? ?? key;
            _mistakes.add('$question: Incorrect value "$userInput"');
          }
        }
      });
    });
    _saveProgressState();

    // If all correct, auto-finish after 2 seconds
    if (_correctFields == _controllers.length) {
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

    final totalFields = _controllers.length;
    final accuracy = (((_correctFields / totalFields) * 100)).toInt();

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
                    Icons.settings_outlined,
                    color: AppTheme.primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Configure the settings with correct values',
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
                    if (_showValidation) ...[
                      SoftCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              _correctFields == _controllers.length
                                  ? Icons.check_circle
                                  : Icons.warning,
                              color: _correctFields == _controllers.length
                                  ? AppTheme.accentGreen
                                  : AppTheme.accentOrange,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _correctFields == _controllers.length
                                        ? 'All configurations are correct!'
                                        : 'Some values need correction',
                                    style: AppTheme.labelMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color:
                                          _correctFields == _controllers.length
                                              ? AppTheme.accentGreen
                                              : AppTheme.accentOrange,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$_correctFields/${_controllers.length} fields correct',
                                    style: AppTheme.bodySmall.copyWith(
                                      color: AppTheme.textMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Configuration Form
                    Text(
                      'Configuration Panel',
                      style: AppTheme.headlineSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    ...widget.configData.entries.map((entry) {
                      final key = entry.key;
                      final value = entry.value;

                      if (value is Map) {
                        return _buildConfigField(
                          key,
                          value['question'] as String? ?? key,
                          value['points'] as int? ?? 10,
                        );
                      }
                      return const SizedBox.shrink();
                    }),

                    const SizedBox(height: 24),

                    // Hints Card
                    SoftCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                color: AppTheme.accentOrange,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Configuration Hints',
                                style: AppTheme.labelMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.accentOrange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...(_getHintsForMission()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Submit Button
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
                        _correctFields < _controllers.length) ...[
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
                                'Review the highlighted fields and correct the values.',
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
                              _correctFields == _controllers.length
                          ? 'View Results'
                          : 'Test Configuration',
                      icon: Icons.check,
                      onPressed: _validateConfiguration,
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

  Widget _buildConfigField(String fieldKey, String question, int points) {
    final controller = _controllers[fieldKey]!;
    final showFeedback = !_assessmentMode &&
        _showValidation &&
        _fieldValidation.containsKey(fieldKey);
    final isCorrect = _fieldValidation[fieldKey] ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SoftCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    question,
                    style: AppTheme.labelLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (showFeedback) ...[
                  Icon(
                    isCorrect ? Icons.check_circle : Icons.cancel,
                    color: isCorrect ? AppTheme.accentGreen : AppTheme.errorRed,
                    size: 20,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: AppTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Enter value',
                hintStyle: TextStyle(
                  color: AppTheme.textLight,
                ),
                filled: true,
                fillColor: showFeedback
                    ? (isCorrect
                        ? AppTheme.accentGreen.withValues(alpha: 0.05)
                        : AppTheme.errorRed.withValues(alpha: 0.05))
                    : AppTheme.textLight.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.textLight.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryBlue,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.errorRed,
                    width: 2,
                  ),
                ),
              ),
              onChanged: (value) {
                if (_showValidation) {
                  setState(() {
                    _showValidation = false;
                    _fieldValidation.clear();
                  });
                }
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (showFeedback && !isCorrect) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Incorrect value',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.errorRed,
                      ),
                    ),
                  ),
                ] else
                  const SizedBox(),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '$points pts',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textMedium,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _getHintsForMission() {
    // Provide mission-specific hints
    if (widget.mission.id.contains('coc2_m5')) {
      return [
        _buildHintItem(
            'IP addresses for local networks typically start with 192.168'),
        _buildHintItem(
            'Standard subnet mask for home networks is 255.255.255.0'),
        _buildHintItem('Gateway is usually the router\'s IP address'),
        _buildHintItem('Google DNS is a commonly used DNS server (8.8.8.8)'),
      ];
    } else if (widget.mission.id.contains('coc3')) {
      return [
        _buildHintItem('Use static IP for server reliability'),
        _buildHintItem('Ensure all network values are in the same subnet'),
        _buildHintItem('DNS settings enable name resolution'),
      ];
    }

    return [
      _buildHintItem('Follow standard configuration practices'),
      _buildHintItem('Ensure all fields are filled correctly'),
      _buildHintItem('Double-check your values before testing'),
    ];
  }

  Widget _buildHintItem(String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppTheme.accentOrange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hint,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textMedium,
              ),
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
            'Your progress will be saved. Are you sure you want to exit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _saveProgressState();
              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
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
