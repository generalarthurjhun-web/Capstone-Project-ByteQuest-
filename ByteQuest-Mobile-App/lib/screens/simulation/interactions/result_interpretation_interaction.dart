import 'package:flutter/material.dart';

import '../components/tool_tray.dart';
import '../runtime/mission_runtime_models.dart';

class ResultInterpretationInteraction extends StatefulWidget {
  const ResultInterpretationInteraction({
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
  State<ResultInterpretationInteraction> createState() =>
      _ResultInterpretationInteractionState();
}

class _ResultInterpretationInteractionState
    extends State<ResultInterpretationInteraction> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.state.interpretations[widget.phase.id] as String? ?? '',
    )..addListener(_refresh);
  }

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
        label: 'Record result interpretation',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: ValueKey('interpretation-input-${widget.phase.id}'),
              controller: _controller,
              enabled: widget.enabled,
              minLines: 3,
              maxLines: 6,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                labelText: 'Interpret the recorded result',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: widget.enabled && _controller.text.trim().isNotEmpty
                  ? () => widget.onAction(
                        'result_interpreted',
                        widget.phase.id,
                        {
                          'interpretation': _controller.text.trim(),
                          'input_method': 'keyboard',
                        },
                      )
                  : null,
              child: const Text('Record interpretation'),
            ),
          ],
        ),
      );
}
