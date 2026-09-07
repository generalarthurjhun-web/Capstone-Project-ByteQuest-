import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../components/tool_tray.dart';
import '../runtime/mission_runtime_models.dart';
import '../templates/authoritative_mission_contract.dart';

class MultiSelectInteraction extends StatefulWidget {
  const MultiSelectInteraction({
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
  State<MultiSelectInteraction> createState() => _MultiSelectInteractionState();
}

class _MultiSelectInteractionState extends State<MultiSelectInteraction> {
  late Set<String> _selected = _runtimeSelection(widget.state);

  @override
  void didUpdateWidget(covariant MultiSelectInteraction oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldSelection = _runtimeSelection(oldWidget.state);
    final newSelection = _runtimeSelection(widget.state);
    if (oldWidget.phase.id != widget.phase.id ||
        !setEquals(oldSelection, newSelection)) {
      _selected = newSelection;
    }
  }

  static Set<String> _runtimeSelection(MissionRuntimeState state) =>
      state.hotspotStates.entries
          .where((entry) => entry.value == HotspotVisualState.selected)
          .map((entry) => entry.key)
          .toSet();

  @override
  Widget build(BuildContext context) {
    final options = interactionItems(
      widget.phase.presentation['options'] ??
          widget.phase.presentation['objects'],
      fallbackIds: widget.phase.availableObjectIds,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MissionSectionLabel(
          icon: Icons.fact_check_outlined,
          text: 'Selection set',
        ),
        const SizedBox(height: 8),
        for (final option in options) ...[
          MissionSelectableActionCard(
            key: ValueKey('multi-select-${option.id}'),
            label: option.label,
            selected: _selected.contains(option.id),
            enabled: widget.enabled,
            icon: Icons.check_box_outline_blank_rounded,
            onTap: () => setState(() {
              if (!_selected.add(option.id)) _selected.remove(option.id);
            }),
          ),
          const SizedBox(height: 8),
        ],
        FilledButton.icon(
          key: const ValueKey('multi-select-confirm'),
          onPressed: widget.enabled
              ? () => unawaited(widget.onAction(
                    'selection_confirmed',
                    widget.phase.id,
                    {
                      'selected_ids': _selected.toList(growable: false),
                      'input_method': 'button',
                    },
                  ))
              : null,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          icon: const Icon(Icons.task_alt_rounded),
          label: const Text('Confirm selection'),
        ),
      ],
    );
  }
}

class MultiSelectInspection extends StatelessWidget {
  const MultiSelectInspection({
    super.key,
    required this.stage,
    required this.selectedItems,
    required this.writing,
    required this.onChanged,
  });

  final AuthoritativeMissionStage stage;
  final Set<String> selectedItems;
  final bool writing;
  final void Function(String id, bool selected) onChanged;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const MissionSectionLabel(
            icon: Icons.search_rounded,
            text: 'Inspection record',
          ),
          const SizedBox(height: 10),
          for (final option in stage.options) ...[
            MissionSelectableActionCard(
              key: ValueKey('inspection-option-${option.id}'),
              label: option.label,
              selected: selectedItems.contains(option.id),
              enabled: !writing,
              icon: Icons.visibility_outlined,
              onTap: () => onChanged(
                option.id,
                !selectedItems.contains(option.id),
              ),
            ),
            const SizedBox(height: 8),
          ],
          SimulationFeedback(
            icon: Icons.fact_check_outlined,
            text:
                '${selectedItems.length} of ${stage.requiredCount} observations selected',
          ),
        ],
      );
}

class InteractionItem {
  const InteractionItem({
    required this.id,
    required this.label,
    this.description = '',
    this.imageAsset,
    this.data = const {},
  });

  final String id;
  final String label;
  final String description;
  final String? imageAsset;
  final Map<String, dynamic> data;
}

List<InteractionItem> interactionItems(
  dynamic value, {
  Iterable<String> fallbackIds = const [],
}) {
  final items = (value as List? ?? const []).whereType<Map>().map((item) {
    final map = Map<String, dynamic>.from(item);
    return InteractionItem(
      id: map['id'] as String,
      label: map['label'] as String? ?? map['id'] as String,
      description: map['description'] as String? ??
          map['label'] as String? ??
          map['id'] as String,
      imageAsset: map['imageAsset'] as String?,
      data: map,
    );
  }).toList(growable: false);
  if (items.isNotEmpty) return items;
  return fallbackIds
      .map((id) => InteractionItem(id: id, label: id))
      .toList(growable: false);
}

class MissionSelectableActionCard extends StatelessWidget {
  const MissionSelectableActionCard({
    super.key,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        enabled: enabled,
        child: Material(
          color: selected ? AppTheme.softBlueAccent : Colors.white,
          borderRadius: AppTheme.radiusSm,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: AppTheme.radiusSm,
            child: AnimatedContainer(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : AppTheme.simulationTransitionDuration,
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: AppTheme.radiusSm,
                border: Border.all(
                  color: selected ? AppTheme.primaryBlue : AppTheme.borderLight,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    selected ? Icons.check_circle_rounded : icon,
                    color:
                        selected ? AppTheme.primaryBlue : AppTheme.textMedium,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(label, style: AppTheme.bodyMedium)),
                ],
              ),
            ),
          ),
        ),
      );
}

class MissionSectionLabel extends StatelessWidget {
  const MissionSectionLabel({
    super.key,
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.deepBlue),
          const SizedBox(width: 7),
          Expanded(child: Text(text, style: AppTheme.labelLarge)),
        ],
      );
}

class SimulationFeedback extends StatelessWidget {
  const SimulationFeedback({
    super.key,
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.backgroundPaleBlue,
            borderRadius: AppTheme.radiusSm,
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.deepBlue),
              const SizedBox(width: 8),
              Expanded(child: Text(text, style: AppTheme.labelMedium)),
            ],
          ),
        ),
      );
}
