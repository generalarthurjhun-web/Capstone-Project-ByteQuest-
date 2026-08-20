import 'package:flutter/material.dart';

import '../components/tool_tray.dart';
import '../runtime/mission_runtime_models.dart';
import '../templates/authoritative_mission_contract.dart';
import 'multi_select_interaction.dart';

class ToolSelectionInteraction extends StatefulWidget {
  const ToolSelectionInteraction({
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
  State<ToolSelectionInteraction> createState() =>
      _ToolSelectionInteractionState();
}

class _ToolSelectionInteractionState extends State<ToolSelectionInteraction> {
  String? _targetId;
  String? _targetCategory;

  @override
  Widget build(BuildContext context) {
    final targets = interactionItems(widget.phase.presentation['targets']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MissionSectionLabel(icon: Icons.ads_click, text: 'Target'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final target in targets)
              ChoiceChip(
                key: ValueKey('tool-target-${target.id}'),
                label: Text(target.label),
                selected: _targetId == target.id,
                onSelected: widget.enabled
                    ? (_) => setState(() {
                          _targetId = target.id;
                          _targetCategory = target.data['category'] as String?;
                        })
                    : null,
              ),
          ],
        ),
        const SizedBox(height: 12),
        ToolTray(
          phase: widget.phase,
          state: widget.state,
          targetId: _targetId,
          targetCategory: _targetCategory,
          onAction: widget.onAction,
          onFeedbackRequested: widget.onFeedbackRequested,
          enabled: widget.enabled,
        ),
      ],
    );
  }
}

class ToolPalette extends StatelessWidget {
  const ToolPalette({
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
            icon: Icons.handyman_outlined,
            text: 'Available resources',
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.sizeOf(context).width < 440 ? 1 : 2,
              mainAxisExtent: 72,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: stage.options.length,
            itemBuilder: (context, index) {
              final option = stage.options[index];
              final selected = selectedItems.contains(option.id);
              return MissionSelectableActionCard(
                key: ValueKey('tool-option-${option.id}'),
                label: option.label,
                selected: selected,
                enabled: !writing,
                icon: Icons.build_outlined,
                onTap: () => onChanged(option.id, !selected),
              );
            },
          ),
          const SizedBox(height: 12),
          SimulationFeedback(
            icon: Icons.inventory_2_outlined,
            text:
                '${selectedItems.length} of ${stage.requiredCount} resources prepared',
          ),
        ],
      );
}
