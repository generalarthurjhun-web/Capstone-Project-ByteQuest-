import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/mission_model.dart';
import '../../../services/authoritative_assessment_service.dart';
import '../result_screen.dart';
import '../components/practice_mission_chrome.dart';
import 'coc2_cable_assessment_contract.dart';

class Coc2CableTerminationAssessmentScreen extends StatefulWidget {
  final Mission mission;

  const Coc2CableTerminationAssessmentScreen({
    super.key,
    required this.mission,
  });

  @override
  State<Coc2CableTerminationAssessmentScreen> createState() =>
      _Coc2CableTerminationAssessmentScreenState();
}

class _Coc2CableTerminationAssessmentScreenState
    extends State<Coc2CableTerminationAssessmentScreen> {
  static const _stageTitles = <String>[
    'PPE & OHS',
    'Tools & materials',
    'Cable preparation',
    'T568B conductors',
    'Termination',
    'Cable tester',
    'Tester result',
    'Inspection',
    '5S completion',
  ];

  static const _labels = <String, String>{
    'gloves': 'Protective gloves',
    'goggles': 'Protective goggles',
    'working_clothes': 'Appropriate working clothes',
    'earphones': 'Personal earphones',
    'jewelry': 'Loose jewelry',
    'copper_cable': 'Copper network cable',
    'rj45_connector': 'RJ45 connectors',
    'wire_stripper': 'Wire stripper',
    'crimping_tool': 'Crimping tool',
    'lan_cable_tester': 'LAN cable tester',
    'paint_brush': 'Paint brush',
    'stapler': 'Office stapler',
    'usb_drive': 'USB flash drive',
    'measure_cable': 'Measure the required cable length',
    'strip_jacket': 'Strip the outer jacket carefully',
    'untwist_and_straighten': 'Untwist and straighten conductors',
    'insert_conductors': 'Insert conductors fully into the connector',
    'verify_jacket_depth': 'Verify jacket depth and conductor seating',
    'crimp_connector': 'Crimp the connector',
    'connect_both_ends': 'Connect both cable ends to the tester',
    'power_on_tester': 'Power on the tester',
    'observe_indicator_sequence': 'Observe the indicator sequence',
    'no_visible_damage': 'No visible cable or connector damage',
    'pin_order_compliant': 'Conductor order matches the completed pin map',
    'connector_secure': 'Connector and cable jacket are secure',
    'ignore_split_jacket': 'Ignore a split cable jacket',
    'accept_loose_connector': 'Accept a loose connector',
    'tools_returned': 'Return tools and tester safely',
    'work_area_cleared': 'Clear the work area',
    'scraps_sorted': 'Sort cable scraps for approved disposal',
    'leave_scraps': 'Leave scraps on the workbench',
    'keep_tester_powered': 'Leave the tester powered on',
    'white_orange': 'White–Orange',
    'orange': 'Orange',
    'white_green': 'White–Green',
    'blue': 'Blue',
    'white_blue': 'White–Blue',
    'green': 'Green',
    'white_brown': 'White–Brown',
    'brown': 'Brown',
  };

  static const _wireColors = <String, Color>{
    'white_orange': Color(0xFFFFE7CC),
    'orange': Color(0xFFF97316),
    'white_green': Color(0xFFDDF7E7),
    'blue': Color(0xFF2563EB),
    'white_blue': Color(0xFFDCEAFF),
    'green': Color(0xFF16A34A),
    'white_brown': Color(0xFFF1E3D3),
    'brown': Color(0xFF8B5E3C),
  };

  final _assessment = AuthoritativeAssessmentService.instance;
  final _ppe = <String>{};
  final _tools = <String>{};
  final _inspection = <String>{};
  final _cleanup = <String>{};
  final _cablePreparation = <String>[];
  final _conductors = <String>[];
  final _termination = <String>[];
  final _tester = <String>[];
  int _stage = 0;
  int _elapsedSeconds = 0;
  String? _testerResult;
  String? _selectedWire;
  String? _writeError;
  bool _writing = false;
  bool _evidenceComplete = false;
  bool _restoring = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    unawaited(_restoreProgress());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _label(String id) => _labels[id] ?? id.replaceAll('_', ' ');

  Future<void> _restoreProgress() async {
    try {
      final actions = await _assessment.getActiveAttemptActions();
      Iterable<Map<String, dynamic>> matching(String type) =>
          actions.where((action) => action['action_type'] == type);
      Set<String> submittedSelection(String type) {
        final rows = matching(type);
        if (rows.isEmpty) return <String>{};
        final value = Map<String, dynamic>.from(
            rows.last['value'] as Map? ?? const <String, dynamic>{});
        return (value['selected_items'] as List? ?? const [])
            .whereType<String>()
            .toSet();
      }

      _ppe.addAll(submittedSelection('ppe_selection_submitted'));
      _tools.addAll(submittedSelection('tools_materials_selection_submitted'));
      _inspection.addAll(submittedSelection('inspection_selection_submitted'));
      _cleanup.addAll(submittedSelection('cleanup_selection_submitted'));
      _cablePreparation.addAll(matching('cable_preparation_step')
          .map((action) => action['target'] as String?)
          .whereType<String>());
      _conductors.addAll(matching('conductor_placed')
          .map((action) => action['target'] as String?)
          .whereType<String>());
      _termination.addAll(matching('termination_step')
          .map((action) => action['target'] as String?)
          .whereType<String>());
      _tester.addAll(matching('tester_step')
          .map((action) => action['target'] as String?)
          .whereType<String>());
      final testerResults = matching('tester_result_submitted');
      if (testerResults.isNotEmpty) {
        final value = Map<String, dynamic>.from(
            testerResults.last['value'] as Map? ?? const <String, dynamic>{});
        _testerResult = value['result'] as String?;
      }
      final complete = <bool>[
        _ppe.length == 3,
        _tools.length == 5,
        _cablePreparation.length >= 3,
        _conductors.length >= 8,
        _termination.length >= 3,
        _tester.length >= 3,
        _testerResult != null,
        _inspection.length == 3,
        _cleanup.length == 3,
      ];
      final firstIncomplete = complete.indexWhere((value) => !value);
      final allComplete = firstIncomplete == -1;
      final session = _assessment.activeSession;
      if (!mounted) return;
      setState(() {
        _stage = allComplete ? _stageTitles.length - 1 : firstIncomplete;
        _evidenceComplete = allComplete;
        _elapsedSeconds = session == null
            ? 0
            : DateTime.now().difference(session.startedAt).inSeconds;
        _restoring = false;
      });
      if (allComplete) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_finish());
        });
      } else {
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) setState(() => _elapsedSeconds++);
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _restoring = false;
        _writeError =
            'Your saved assessment progress could not be restored. Try again.';
      });
    }
  }

  Future<bool> _record({
    required String actionType,
    String? target,
    Map<String, dynamic> value = const {},
  }) async {
    if (_writing) return false;
    setState(() {
      _writing = true;
      _writeError = null;
    });
    try {
      await _assessment.recordAction(
        actionType: actionType,
        target: target,
        value: {
          ...value,
          'assessment_package_id': Coc2CableAssessmentContract.packageId,
          'local_mission_id': widget.mission.id,
        },
      );
      if (mounted) setState(() => _writing = false);
      return true;
    } catch (error) {
      if (mounted) {
        setState(() {
          _writing = false;
          _writeError =
              'This action was not saved. Check the connection and try again.';
        });
      }
      return false;
    }
  }

  Future<void> _submitChecklist(
    Set<String> selected,
    String actionType,
  ) async {
    if (!await _record(
      actionType: actionType,
      value: {'selected_items': selected.toList()..sort()},
    )) {
      return;
    }
    _advance();
  }

  Future<void> _chooseProcedureStep(
    List<String> selected,
    String actionType,
    String step,
  ) async {
    if (selected.contains(step)) return;
    if (!await _record(actionType: actionType, target: step)) return;
    if (!mounted) return;
    setState(() => selected.add(step));
  }

  Future<void> _placeConductor(String wire) async {
    if (_conductors.contains(wire)) return;
    final pin = _conductors.length + 1;
    if (!await _record(
      actionType: 'conductor_placed',
      target: wire,
      value: {'pin': pin, 'standard_scenario': 'T568B'},
    )) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _conductors.add(wire);
      _selectedWire = null;
    });
  }

  Future<void> _submitTesterResult() async {
    final result = _testerResult;
    if (result == null) return;
    if (!await _record(
      actionType: 'tester_result_submitted',
      value: {'result': result},
    )) {
      return;
    }
    _advance();
  }

  void _advance() {
    if (!mounted) return;
    setState(() => _stage++);
  }

  Future<void> _finish() async {
    _timer?.cancel();
    _timer = null;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          mission: widget.mission,
          result: MissionResult(
            missionId: widget.mission.id,
            score: 0,
            percentage: 0,
            passed: false,
            xpEarned: 0,
            timeSpent: _elapsedSeconds,
            rating: 'awaiting-database-evaluation',
            competencyStatus: 'provisional-review-required',
          ),
        ),
      ),
    );
    if (mounted && _assessment.activeSession != null) {
      _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _elapsedSeconds++);
      });
    }
  }

  Future<void> _completeCleanup() async {
    if (_evidenceComplete) {
      await _finish();
      return;
    }
    if (!await _record(
      actionType: 'cleanup_selection_submitted',
      value: {'selected_items': _cleanup.toList()..sort()},
    )) {
      return;
    }
    if (mounted) setState(() => _evidenceComplete = true);
    await _finish();
  }

  Future<void> _showExitNotice() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Assessment in progress'),
        content: const Text(
          'Recorded evidence remains protected if you leave. The incomplete attempt will not be evaluated or released.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Leave assessment'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Continue assessment'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_restoring) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final progress = (_stage + 1) / _stageTitles.length;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_showExitNotice());
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundOffWhite,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            onPressed: _showExitNotice,
            tooltip: 'Assessment exit information',
            icon: const Icon(Icons.close_rounded),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cable termination assessment'),
              Text(
                practiceMissionIdentifier(widget.mission),
                style: AppTheme.caption.copyWith(color: AppTheme.textMedium),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  _formatDuration(_elapsedSeconds),
                  style: AppTheme.labelMedium.copyWith(
                    color: AppTheme.textMedium,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: AppTheme.borderLight,
                color: AppTheme.primaryBlue,
                semanticsLabel: 'Assessment stage progress',
                semanticsValue: '${_stage + 1} of ${_stageTitles.length}',
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final horizontal = constraints.maxWidth >= 760;
                    return SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        horizontal ? 32 : 20,
                        20,
                        horizontal ? 32 : 20,
                        32,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 980),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _StageHeader(
                                number: _stage + 1,
                                total: _stageTitles.length,
                                title: _stageTitles[_stage],
                              ),
                              const SizedBox(height: 16),
                              if (_writeError != null) ...[
                                _InlineMessage(
                                  icon: Icons.cloud_off_rounded,
                                  text: _writeError!,
                                  color: AppTheme.errorRed,
                                ),
                                const SizedBox(height: 12),
                              ],
                              AnimatedSwitcher(
                                duration:
                                    MediaQuery.disableAnimationsOf(context)
                                        ? Duration.zero
                                        : const Duration(milliseconds: 180),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                child: KeyedSubtree(
                                  key: ValueKey(_stage),
                                  child: _buildStage(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStage() {
    switch (_stage) {
      case 0:
        return _checklistStage(
          intro:
              'Select exactly three items appropriate for PPE and safe cable-termination work. Your selection is recorded when you continue.',
          selected: _ppe,
          options: const [
            'working_clothes',
            'earphones',
            'gloves',
            'jewelry',
            'goggles',
          ],
          requiredCount: 3,
          buttonLabel: 'Record PPE preparation',
          onContinue: () => _submitChecklist(
            _ppe,
            'ppe_selection_submitted',
          ),
        );
      case 1:
        return _checklistStage(
          intro:
              'Select exactly five tools and materials needed for this cable-termination and testing scenario.',
          selected: _tools,
          options: const [
            'lan_cable_tester',
            'paint_brush',
            'copper_cable',
            'wire_stripper',
            'usb_drive',
            'rj45_connector',
            'stapler',
            'crimping_tool',
          ],
          requiredCount: 5,
          buttonLabel: 'Record tools and materials',
          onContinue: () => _submitChecklist(
            _tools,
            'tools_materials_selection_submitted',
          ),
        );
      case 2:
        return _procedureStage(
          intro:
              'Choose each cable-preparation action in the order you would perform it. The timeline is evidence; no correctness is revealed during assessment.',
          choices: const [
            'untwist_and_straighten',
            'measure_cable',
            'strip_jacket',
          ],
          selected: _cablePreparation,
          actionType: 'cable_preparation_step',
          onContinue: _advance,
        );
      case 3:
        return _conductorStage();
      case 4:
        return _procedureStage(
          intro:
              'Choose all termination actions chronologically. The system records the exact order selected.',
          choices: const [
            'crimp_connector',
            'insert_conductors',
            'verify_jacket_depth',
          ],
          selected: _termination,
          actionType: 'termination_step',
          onContinue: _advance,
        );
      case 5:
        return _procedureStage(
          intro:
              'Operate the LAN cable tester by choosing the three actions in procedural order.',
          choices: const [
            'observe_indicator_sequence',
            'connect_both_ends',
            'power_on_tester',
          ],
          selected: _tester,
          actionType: 'tester_step',
          onContinue: _advance,
        );
      case 6:
        return _testerResultStage();
      case 7:
        return _checklistStage(
          intro:
              'Select exactly three observations that confirm the completed cable is physically compliant with this scenario.',
          selected: _inspection,
          options: const [
            'connector_secure',
            'ignore_split_jacket',
            'pin_order_compliant',
            'accept_loose_connector',
            'no_visible_damage',
          ],
          requiredCount: 3,
          buttonLabel: 'Record physical inspection',
          onContinue: () => _submitChecklist(
            _inspection,
            'inspection_selection_submitted',
          ),
        );
      default:
        return _checklistStage(
          intro:
              'Select exactly three actions that complete the work area safely under the approved 5S/3Rs scenario.',
          selected: _cleanup,
          options: const [
            'leave_scraps',
            'tools_returned',
            'keep_tester_powered',
            'scraps_sorted',
            'work_area_cleared',
          ],
          requiredCount: 3,
          buttonLabel: _evidenceComplete
              ? 'Review recorded evidence'
              : 'Review before submission',
          onContinue: _completeCleanup,
        );
    }
  }

  Widget _checklistStage({
    required String intro,
    required Set<String> selected,
    required List<String> options,
    required int requiredCount,
    required String buttonLabel,
    required Future<void> Function() onContinue,
  }) {
    final ready = Coc2CableAssessmentContract.hasSelectionCount(
      selected,
      requiredCount,
    );
    return _AssessmentPanel(
      intro: intro,
      child: Column(
        children: [
          for (final option in options) ...[
            Semantics(
              selected: selected.contains(option),
              button: true,
              label: _label(option),
              child: CheckboxListTile(
                value: selected.contains(option),
                onChanged: _writing
                    ? null
                    : (value) {
                        setState(() {
                          if (value == true) {
                            if (selected.length < requiredCount) {
                              selected.add(option);
                            }
                          } else {
                            selected.remove(option);
                          }
                        });
                      },
                title: Text(_label(option)),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
          const SizedBox(height: 12),
          _FooterAction(
            status: '${selected.length} of $requiredCount selected',
            label: buttonLabel,
            enabled: ready && !_writing,
            busy: _writing,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }

  Widget _procedureStage({
    required String intro,
    required List<String> choices,
    required List<String> selected,
    required String actionType,
    required VoidCallback onContinue,
  }) {
    return _AssessmentPanel(
      intro: intro,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: choices.map((choice) {
              final used = selected.contains(choice);
              return Semantics(
                button: true,
                enabled: !used && !_writing,
                label: _label(choice),
                hint: used ? 'Already placed in the action timeline' : null,
                child: OutlinedButton.icon(
                  onPressed: used || _writing
                      ? null
                      : () => _chooseProcedureStep(
                            selected,
                            actionType,
                            choice,
                          ),
                  icon: Icon(used
                      ? Icons.check_circle_outline_rounded
                      : Icons.add_circle_outline_rounded),
                  label: Text(_label(choice)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          _Timeline(items: selected.map(_label).toList()),
          const SizedBox(height: 20),
          _FooterAction(
            status: '${selected.length} of ${choices.length} actions recorded',
            label: 'Continue',
            enabled: selected.length == choices.length && !_writing,
            busy: _writing,
            onPressed: () async => onContinue(),
          ),
        ],
      ),
    );
  }

  Widget _conductorStage() {
    const choices = <String>[
      'blue',
      'white_brown',
      'orange',
      'green',
      'white_orange',
      'brown',
      'white_blue',
      'white_green',
    ];
    final nextPin = _conductors.length;
    return _AssessmentPanel(
      intro:
          'Build the T568B scenario one conductor at a time. Drag a conductor to the next neutral pin, or select a conductor and then choose the pin. No answer positions are labeled.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: choices.where((wire) => !_conductors.contains(wire)).map(
              (wire) {
                final selected = _selectedWire == wire;
                return Draggable<String>(
                  data: wire,
                  maxSimultaneousDrags: _writing ? 0 : 1,
                  feedback: Material(
                    color: Colors.transparent,
                    child: _WireToken(
                      label: _label(wire),
                      color: _wireColors[wire]!,
                      selected: true,
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.35,
                    child: _WireToken(
                      label: _label(wire),
                      color: _wireColors[wire]!,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _writing
                        ? null
                        : () => setState(() {
                              _selectedWire = selected ? null : wire;
                            }),
                    child: _WireToken(
                      label: _label(wire),
                      color: _wireColors[wire]!,
                      selected: selected,
                    ),
                  ),
                );
              },
            ).toList(),
          ),
          const SizedBox(height: 24),
          Semantics(
            label:
                'Eight neutral RJ45 pin positions. ${_conductors.length} conductors placed.',
            child: InteractiveViewer(
              minScale: 0.85,
              maxScale: 2.5,
              boundaryMargin: const EdgeInsets.all(36),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 620),
                child: Row(
                  children: List.generate(8, (index) {
                    final wire =
                        index < _conductors.length ? _conductors[index] : null;
                    final active = index == nextPin;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: DragTarget<String>(
                          onWillAcceptWithDetails: (_) => active && !_writing,
                          onAcceptWithDetails: (details) =>
                              unawaited(_placeConductor(details.data)),
                          builder: (context, candidate, _) {
                            final highlighted = candidate.isNotEmpty && active;
                            return Semantics(
                              button: active && _selectedWire != null,
                              label: wire == null
                                  ? 'Neutral pin ${index + 1}${active ? ", next position" : ""}'
                                  : 'Pin ${index + 1}, ${_label(wire)} placed',
                              child: InkWell(
                                onTap:
                                    active && _selectedWire != null && !_writing
                                        ? () => _placeConductor(_selectedWire!)
                                        : null,
                                borderRadius: BorderRadius.circular(12),
                                child: AnimatedContainer(
                                  duration:
                                      MediaQuery.disableAnimationsOf(context)
                                          ? Duration.zero
                                          : const Duration(milliseconds: 160),
                                  height: 112,
                                  decoration: BoxDecoration(
                                    color: wire == null
                                        ? highlighted
                                            ? AppTheme.primaryBlue
                                                .withValues(alpha: 0.1)
                                            : Colors.white
                                        : _wireColors[wire],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: highlighted
                                          ? AppTheme.primaryBlue
                                          : AppTheme.borderLight,
                                      width: highlighted ? 2 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${index + 1}',
                                        style: AppTheme.labelMedium.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: wire == 'blue' ||
                                                  wire == 'green' ||
                                                  wire == 'brown' ||
                                                  wire == 'orange'
                                              ? Colors.white
                                              : AppTheme.textDark,
                                        ),
                                      ),
                                      if (wire != null) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          _label(wire),
                                          textAlign: TextAlign.center,
                                          style: AppTheme.labelSmall.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: wire == 'blue' ||
                                                    wire == 'green' ||
                                                    wire == 'brown' ||
                                                    wire == 'orange'
                                                ? Colors.white
                                                : AppTheme.textDark,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _FooterAction(
            status: '${_conductors.length} of 8 conductors recorded',
            label: 'Continue to termination',
            enabled: _conductors.length == 8 && !_writing,
            busy: _writing,
            onPressed: () async => _advance(),
          ),
        ],
      ),
    );
  }

  Widget _testerResultStage() {
    const results = <(String, String)>[
      ('open_circuit', 'Open circuit / missing pin'),
      ('pass', 'Pins 1–8 match in order'),
      ('short', 'Short between conductors'),
      ('reversed', 'Reversed conductor map'),
    ];
    return _AssessmentPanel(
      intro:
          'The tester display shows pins 1 through 8 matching on the main and remote units. Record the observed result.',
      child: Column(
        children: [
          for (final result in results) ...[
            Semantics(
              selected: _testerResult == result.$1,
              button: true,
              label: result.$2,
              child: SizedBox(
                width: double.infinity,
                child: ChoiceChip(
                  selected: _testerResult == result.$1,
                  onSelected: _writing
                      ? null
                      : (_) => setState(() => _testerResult = result.$1),
                  avatar: Icon(
                    _testerResult == result.$1
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 20,
                  ),
                  label: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(result.$2),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 12),
          _FooterAction(
            status: _testerResult == null
                ? 'Choose one observed result'
                : 'One result selected',
            label: 'Record tester result',
            enabled: _testerResult != null && !_writing,
            busy: _writing,
            onPressed: _submitTesterResult,
          ),
        ],
      ),
    );
  }

  static String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remaining.toString().padLeft(2, '0')}';
  }
}

class _StageHeader extends StatelessWidget {
  final int number;
  final int total;
  final String title;

  const _StageHeader({
    required this.number,
    required this.total,
    required this.title,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stage $number of $total',
            style: AppTheme.labelMedium.copyWith(
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTheme.headlineLarge.copyWith(
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Assessment evidence is saved chronologically. Correctness is evaluated by PostgreSQL after submission.',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textMedium,
              height: 1.45,
            ),
          ),
        ],
      );
}

class _AssessmentPanel extends StatelessWidget {
  final String intro;
  final Widget child;

  const _AssessmentPanel({required this.intro, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A0F172A),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _InlineMessage(
              icon: Icons.info_outline_rounded,
              text: intro,
              color: AppTheme.primaryBlue,
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      );
}

class _InlineMessage extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InlineMessage({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: AppTheme.bodySmall.copyWith(
                  height: 1.45,
                  color: AppTheme.textDark,
                ),
              ),
            ),
          ],
        ),
      );
}

class _FooterAction extends StatelessWidget {
  final String status;
  final String label;
  final bool enabled;
  final bool busy;
  final Future<void> Function() onPressed;

  const _FooterAction({
    required this.status,
    required this.label,
    required this.enabled,
    required this.busy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          final statusWidget = Text(
            status,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textMedium,
              fontWeight: FontWeight.w600,
            ),
          );
          final button = SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: enabled ? onPressed : null,
              icon: busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_forward_rounded),
              label: Text(label),
            ),
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [statusWidget, const SizedBox(height: 10), button],
            );
          }
          return Row(
            children: [
              Expanded(child: statusWidget),
              const SizedBox(width: 16),
              button,
            ],
          );
        },
      );
}

class _Timeline extends StatelessWidget {
  final List<String> items;

  const _Timeline({required this.items});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.backgroundOffWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: items.isEmpty
            ? Text(
                'Your chronological action timeline will appear here.',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.textMedium),
              )
            : Column(
                children: List.generate(items.length, (index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == items.length - 1 ? 0 : 10,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryBlue,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${index + 1}',
                            style: AppTheme.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(items[index])),
                      ],
                    ),
                  );
                }),
              ),
      );
}

class _WireToken extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;

  const _WireToken({
    required this.label,
    required this.color,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final dark = color.computeLuminance() < 0.45;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label conductor',
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 150),
        constraints: const BoxConstraints(minWidth: 108, minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.primaryBlue : AppTheme.borderLight,
            width: selected ? 3 : 1,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x220F172A),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTheme.labelMedium.copyWith(
            color: dark ? Colors.white : AppTheme.textDark,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
