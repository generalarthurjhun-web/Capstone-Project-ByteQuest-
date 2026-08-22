import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../components/tool_tray.dart';
import '../runtime/mission_runtime_models.dart';

abstract interface class TestRunScheduler {
  ScheduledTestRun schedule(Duration duration, VoidCallback onElapsed);
}

abstract interface class ScheduledTestRun {
  void cancel();
}

final class TimerTestRunScheduler implements TestRunScheduler {
  const TimerTestRunScheduler();

  @override
  ScheduledTestRun schedule(Duration duration, VoidCallback onElapsed) =>
      _TimerScheduledTestRun(Timer(duration, onElapsed));
}

final class _TimerScheduledTestRun implements ScheduledTestRun {
  _TimerScheduledTestRun(this._timer);

  final Timer _timer;

  @override
  void cancel() => _timer.cancel();
}

class TestRunInteraction extends StatefulWidget {
  const TestRunInteraction({
    super.key,
    required this.phase,
    required this.state,
    required this.onAction,
    this.duration = AppTheme.simulationTransitionDuration,
    this.scheduler = const TimerTestRunScheduler(),
    this.enabled = true,
  });

  final MissionPhaseDefinition phase;
  final MissionRuntimeState state;
  final MissionActionCallback onAction;
  final Duration duration;
  final TestRunScheduler scheduler;
  final bool enabled;

  @override
  State<TestRunInteraction> createState() => _TestRunInteractionState();
}

class _TestRunInteractionState extends State<TestRunInteraction> {
  ScheduledTestRun? _scheduledRun;
  String? _scheduledPhaseId;
  String? _scheduledTarget;
  Duration? _scheduledDuration;
  late final TextEditingController _interpretationController;

  bool get _requiresInterpretation =>
      widget.phase.presentation['requires_interpretation'] == true;

  String get _target =>
      widget.phase.presentation['target'] as String? ?? widget.phase.id;

  Duration get _testDuration {
    final milliseconds = widget.phase.presentation['duration_ms'];
    return milliseconds is num && milliseconds >= 0
        ? Duration(milliseconds: milliseconds.round())
        : widget.duration;
  }

  @override
  void initState() {
    super.initState();
    _interpretationController = TextEditingController(
      text: widget.state.interpretations[widget.phase.id] as String? ?? '',
    )..addListener(_refresh);
    _syncSchedule();
  }

  @override
  void didUpdateWidget(covariant TestRunInteraction oldWidget) {
    super.didUpdateWidget(oldWidget);
    final identityChanged = oldWidget.phase.id != widget.phase.id ||
        (oldWidget.phase.presentation['target'] as String? ??
                oldWidget.phase.id) !=
            _target ||
        oldWidget.duration != widget.duration ||
        oldWidget.scheduler != widget.scheduler;
    if (identityChanged) _cancelSchedule();
    final persisted =
        widget.state.interpretations[widget.phase.id] as String? ?? '';
    final previousPersisted =
        oldWidget.state.interpretations[oldWidget.phase.id] as String? ?? '';
    if (_interpretationController.text != persisted &&
        (identityChanged || persisted != previousPersisted)) {
      _interpretationController.value = TextEditingValue(
        text: persisted,
        selection: TextSelection.collapsed(offset: persisted.length),
      );
    }
    _syncSchedule();
  }

  @override
  void dispose() {
    _cancelSchedule();
    _interpretationController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  void _syncSchedule() {
    final running =
        widget.state.testStatusFor(_target) == MissionTestStatus.running;
    if (!running) {
      _cancelSchedule();
      return;
    }
    if (_scheduledRun != null &&
        _scheduledPhaseId == widget.phase.id &&
        _scheduledTarget == _target &&
        _scheduledDuration == _testDuration) {
      return;
    }
    _cancelSchedule();
    _scheduledPhaseId = widget.phase.id;
    _scheduledTarget = _target;
    _scheduledDuration = _testDuration;
    _scheduledRun = widget.scheduler.schedule(_testDuration, () {
      if (!mounted ||
          widget.state.testStatusFor(_target) != MissionTestStatus.running) {
        return;
      }
      unawaited(_complete());
    });
  }

  void _cancelSchedule() {
    _scheduledRun?.cancel();
    _scheduledRun = null;
    _scheduledPhaseId = null;
    _scheduledTarget = null;
    _scheduledDuration = null;
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        widget.state.reducedMotion || MediaQuery.disableAnimationsOf(context);
    final status = widget.state.testStatusFor(_target);
    final running = status == MissionTestStatus.running;
    final completed = status == MissionTestStatus.completed;
    final transitionDuration =
        reduceMotion ? Duration.zero : AppTheme.simulationTransitionDuration;
    return Semantics(
      container: true,
      label: 'Technical test run',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.phase.instruction, style: AppTheme.bodyMedium),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: transitionDuration,
            child: running
                ? Semantics(
                    key: const ValueKey('test-run-progress'),
                    liveRegion: true,
                    label: 'Test in progress',
                    child: const LinearProgressIndicator(),
                  )
                : completed
                    ? Semantics(
                        key: const ValueKey('test-run-completed'),
                        liveRegion: true,
                        label: 'Test completed',
                        excludeSemantics: true,
                        child: Container(
                          constraints: const BoxConstraints(
                            minHeight: AppTheme.minimumTapTarget,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.softBlueAccent,
                            borderRadius: AppTheme.radiusSm,
                            border: Border.all(color: AppTheme.primaryBlue),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: AppTheme.primaryBlue,
                              ),
                              SizedBox(width: 10),
                              Expanded(child: Text('Test completed')),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
          ),
          if (running || completed) const SizedBox(height: 12),
          FilledButton.icon(
            key: ValueKey(running ? 'test-run-running' : 'test-run-start'),
            onPressed: !widget.enabled || running ? null : _run,
            icon: Icon(
              running ? Icons.timer_outlined : Icons.play_arrow_rounded,
            ),
            label: Text(
              running
                  ? 'Test running'
                  : completed
                      ? 'Run test again'
                      : 'Run test',
            ),
          ),
          if (completed && _requiresInterpretation) ...[
            const SizedBox(height: 16),
            TextField(
              key: ValueKey('test-interpretation-${widget.phase.id}'),
              controller: _interpretationController,
              enabled: widget.enabled,
              minLines: 3,
              maxLines: 6,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                labelText: 'Interpret the displayed test result',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 10),
            FilledButton(
              key: ValueKey('test-interpretation-record-${widget.phase.id}'),
              onPressed: widget.enabled &&
                      _interpretationController.text.trim().isNotEmpty
                  ? _recordInterpretation
                  : null,
              child: const Text('Record test interpretation'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _run() {
    return widget.onAction('test_started', _target, const {
      'input_method': 'tap',
      'test_status': 'running',
    });
  }

  Future<void> _complete() => widget.onAction('test_completed', _target, {
        'duration_ms': _testDuration.inMilliseconds,
        'reduced_motion': widget.state.reducedMotion ||
            MediaQuery.disableAnimationsOf(context),
        'test_status': 'completed',
        'input_method': 'timer',
      });

  Future<void> _recordInterpretation() => widget.onAction(
        'result_interpreted',
        widget.phase.id,
        {
          'interpretation': _interpretationController.text.trim(),
          'test_target': _target,
          'input_method': 'keyboard',
        },
      );
}
