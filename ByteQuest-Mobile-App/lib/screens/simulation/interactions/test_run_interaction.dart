import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../components/tool_tray.dart';
import '../runtime/mission_runtime_models.dart';

class TestRunInteraction extends StatelessWidget {
  const TestRunInteraction({
    super.key,
    required this.phase,
    required this.state,
    required this.onAction,
    this.duration = AppTheme.simulationTransitionDuration,
    this.enabled = true,
  });

  final MissionPhaseDefinition phase;
  final MissionRuntimeState state;
  final MissionActionCallback onAction;
  final Duration duration;
  final bool enabled;

  String get _target => phase.presentation['target'] as String? ?? phase.id;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        state.reducedMotion || MediaQuery.disableAnimationsOf(context);
    final status = state.testStatusFor(_target);
    final running = status == MissionTestStatus.running;
    final completed = status == MissionTestStatus.completed;
    final transitionDuration = reduceMotion ? Duration.zero : duration;
    return Semantics(
      container: true,
      label: 'Technical test run',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(phase.instruction, style: AppTheme.bodyMedium),
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
            key: ValueKey(running ? 'test-run-complete' : 'test-run-start'),
            onPressed: !enabled
                ? null
                : running
                    ? () => _complete(reduceMotion)
                    : _run,
            icon: Icon(
              running ? Icons.stop_circle_outlined : Icons.play_arrow_rounded,
            ),
            label: Text(
              running
                  ? 'Complete test'
                  : completed
                      ? 'Run test again'
                      : 'Run test',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _run() {
    final actionType =
        phase.presentation['actionType'] as String? ?? 'test_started';
    return onAction(actionType, _target, const {
      'input_method': 'tap',
      'test_status': 'running',
    });
  }

  Future<void> _complete(bool reduceMotion) =>
      onAction('test_completed', _target, {
        'duration_ms': reduceMotion ? 0 : duration.inMilliseconds,
        'reduced_motion': reduceMotion,
        'test_status': 'completed',
        'input_method': 'button',
      });
}
