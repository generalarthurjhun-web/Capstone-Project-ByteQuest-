import 'dart:async';

import 'package:flutter/material.dart';

import '../components/tool_tray.dart';
import '../runtime/mission_runtime_models.dart';
import 'multi_select_interaction.dart';

class MatchingInteraction extends StatefulWidget {
  const MatchingInteraction({
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
  State<MatchingInteraction> createState() => _MatchingInteractionState();
}

class _MatchingInteractionState extends State<MatchingInteraction> {
  String? _selectedSource;

  @override
  Widget build(BuildContext context) {
    final sources = interactionItems(widget.phase.presentation['sources']);
    final destinations =
        interactionItems(widget.phase.presentation['destinations']);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              const Text('Sources'),
              for (final source in sources)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Semantics(
                    button: true,
                    selected: _selectedSource == source.id,
                    child: OutlinedButton(
                      key: ValueKey('matching-source-${source.id}'),
                      onPressed: widget.enabled
                          ? () => setState(() => _selectedSource = source.id)
                          : null,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: Text(source.label),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              const Text('Matches'),
              for (final destination in destinations)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: OutlinedButton(
                    key: ValueKey('matching-destination-${destination.id}'),
                    onPressed: widget.enabled && _selectedSource != null
                        ? () => _match(destination.id)
                        : null,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: Text(destination.label),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _match(String destination) {
    final source = _selectedSource!;
    setState(() => _selectedSource = null);
    unawaited(widget.onAction('match_created', destination, {
      'source_id': source,
      'destination_id': destination,
      'input_method': 'tap',
    }));
  }
}
