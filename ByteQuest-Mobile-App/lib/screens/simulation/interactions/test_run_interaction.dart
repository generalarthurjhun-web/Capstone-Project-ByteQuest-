import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../components/tool_tray.dart';
import '../runtime/mission_runtime_models.dart';

class TestRunInteraction extends StatefulWidget {
  const TestRunInteraction({
    super.key,
    required this.phase,
    required this.state,
    required this.onAction,
    this.duration = const Duration(milliseconds: 200),
    this.enabled = true,
  });

  final MissionPhaseDefinition phase;
  final MissionRuntimeState state;
  final MissionActionCallback onAction;
  final Duration duration;
  final bool enabled;

  @override
  State<TestRunInteraction> createState() => _TestRunInteractionState();
}

class _TestRunInteractionState extends State<TestRunInteraction> {
  bool _running = false;

  Future<void> _run() async {
    if (_running || !widget.enabled) return;
    final reduceMotion = widget.state.reducedMotion ||
        MediaQuery.disableAnimationsOf(context);
    setState(() => _running = true);
    await widget.onAction('test_started', widget.phase.id, const {
      'input_method': 'tap',
    });
    if (!reduceMotion && widget.duration > Duration.zero) {
      await Future<void>.delayed(widget.duration);
    }
    await widget.onAction('test_completed', widget.phase.id, {
      'duration_ms': reduceMotion ? 0 : widget.duration.inMilliseconds,
      'reduced_motion': reduceMotion,
    });
    if (mounted) setState(() => _running = false);
  }

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label: 'Technical test run',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.phase.instruction, style: AppTheme.bodyMedium),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: widget.state.reducedMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 200),
              child: _running
                  ? Semantics(
                      key: const ValueKey('test-run-progress'),
                      liveRegion: true,
                      label: 'Test in progress',
                      child: const LinearProgressIndicator(),
                    )
                  : const SizedBox.shrink(),
            ),
            if (_running) const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: widget.enabled && !_running ? _run : null,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Run test'),
            ),
          ],
        ),
      );
}
