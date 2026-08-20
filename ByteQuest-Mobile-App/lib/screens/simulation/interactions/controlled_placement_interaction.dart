import 'dart:async';

import 'package:flutter/material.dart';

import '../components/tool_tray.dart';
import '../runtime/mission_runtime_models.dart';
import 'multi_select_interaction.dart';

class ControlledPlacementInteraction extends StatefulWidget {
  const ControlledPlacementInteraction({
    super.key,
    required this.phase,
    required this.state,
    required this.onAction,
    this.onFeedbackRequested,
    this.enabled = true,
  });

  final MissionPhaseDefinition phase;
  final MissionRuntimeState state;
  final MissionActionCallback onAction;
  final MissionFeedbackCallback? onFeedbackRequested;
  final bool enabled;

  @override
  State<ControlledPlacementInteraction> createState() =>
      _ControlledPlacementInteractionState();
}

class _ControlledPlacementInteractionState
    extends State<ControlledPlacementInteraction> {
  String? _itemId;
  String? _destinationId;
  String? _orientation;

  @override
  Widget build(BuildContext context) {
    final items = interactionItems(widget.phase.presentation['items']);
    final destinations =
        interactionItems(widget.phase.presentation['destinations']);
    final selectedItem = _itemId == null
        ? null
        : items.firstWhere((item) => item.id == _itemId);
    final orientations = (selectedItem?.data['orientations'] as List? ?? const [])
        .whereType<String>()
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MissionSectionLabel(icon: Icons.memory_rounded, text: 'Components'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in items)
              ChoiceChip(
                key: ValueKey('placement-item-${item.id}'),
                label: Text(item.label),
                selected: _itemId == item.id,
                onSelected: widget.enabled
                    ? (_) => setState(() {
                          _itemId = item.id;
                          _orientation = null;
                        })
                    : null,
              ),
          ],
        ),
        const SizedBox(height: 12),
        const MissionSectionLabel(
          icon: Icons.place_outlined,
          text: 'Destinations',
        ),
        const SizedBox(height: 8),
        for (final destination in destinations)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              key: ValueKey('placement-destination-${destination.id}'),
              onPressed: widget.enabled
                  ? () => setState(() => _destinationId = destination.id)
                  : null,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(destination.label),
            ),
          ),
        if (orientations.isNotEmpty) ...[
          const MissionSectionLabel(
            icon: Icons.screen_rotation_outlined,
            text: 'Orientation',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final orientation in orientations)
                ChoiceChip(
                  key: ValueKey('placement-orientation-$orientation'),
                  label: Text(orientation.replaceAll('_', ' ')),
                  selected: _orientation == orientation,
                  onSelected: widget.enabled
                      ? (_) => setState(() => _orientation = orientation)
                      : null,
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        FilledButton.icon(
          key: const ValueKey('placement-place'),
          onPressed: widget.enabled &&
                  _itemId != null &&
                  _destinationId != null &&
                  (orientations.isEmpty || _orientation != null)
              ? () => _place(items, destinations)
              : null,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          icon: const Icon(Icons.place_rounded),
          label: const Text('Place'),
        ),
      ],
    );
  }

  void _place(List<InteractionItem> items, List<InteractionItem> destinations) {
    final item = items.firstWhere((candidate) => candidate.id == _itemId);
    final destination = destinations
        .firstWhere((candidate) => candidate.id == _destinationId);
    final accepted =
        (destination.data['accepted_categories'] as List? ?? const [])
            .whereType<String>()
            .toSet();
    final category = item.data['category'] as String?;
    final compatible = accepted.isEmpty || accepted.contains(category);
    if (!compatible) widget.onFeedbackRequested?.call('placement_incompatible');
    unawaited(widget.onAction('placement_attempted', destination.id, {
      'item_id': item.id,
      'destination_id': destination.id,
      'compatible': compatible,
      if (_orientation != null) 'orientation': _orientation,
      if (!compatible) 'feedback_id': 'placement_incompatible',
      'input_method': 'button',
    }));
  }
}
