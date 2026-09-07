import 'package:flutter/material.dart';

import '../components/tool_tray.dart';
import '../runtime/mission_runtime_models.dart';

class ObservationInteraction extends StatefulWidget {
  const ObservationInteraction({
    super.key,
    required this.phase,
    required this.state,
    required this.onAction,
    this.enabled = true,
  });

  final MissionPhaseDefinition phase;
  final MissionRuntimeState state;
  final MissionActionCallback onAction;
  final bool enabled;

  @override
  State<ObservationInteraction> createState() => _ObservationInteractionState();
}

class _ObservationInteractionState extends State<ObservationInteraction> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: _persistedValue(widget),
    )..addListener(_refresh);
  }

  @override
  void didUpdateWidget(covariant ObservationInteraction oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previousValue = _persistedValue(oldWidget);
    final nextValue = _persistedValue(widget);
    if (oldWidget.phase.id == widget.phase.id &&
        previousValue == nextValue) {
      return;
    }
    _controller
      ..removeListener(_refresh)
      ..value = TextEditingValue(
        text: nextValue,
        selection: TextSelection.collapsed(offset: nextValue.length),
      )
      ..addListener(_refresh);
  }

  String _persistedValue(ObservationInteraction source) =>
      source.state.observations[source.phase.id] as String? ?? '';

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _controller
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label: 'Record technical observation',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: ValueKey('observation-input-${widget.phase.id}'),
              controller: _controller,
              enabled: widget.enabled,
              minLines: 3,
              maxLines: 6,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                labelText: 'Observed value or condition',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: widget.enabled && _controller.text.trim().isNotEmpty
                  ? () => widget.onAction(
                        'observation_recorded',
                        widget.phase.id,
                        {
                          'observation': _controller.text.trim(),
                          'input_method': 'keyboard',
                        },
                      )
                  : null,
              child: const Text('Record observation'),
            ),
          ],
        ),
      );
}
