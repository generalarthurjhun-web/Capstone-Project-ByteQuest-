import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../components/tool_tray.dart';
import '../runtime/mission_runtime_models.dart';
import '../templates/authoritative_mission_contract.dart';
import 'multi_select_interaction.dart';

class SequencingInteraction extends StatefulWidget {
  const SequencingInteraction({
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
  State<SequencingInteraction> createState() => _SequencingInteractionState();
}

class _SequencingInteractionState extends State<SequencingInteraction> {
  late final List<InteractionItem> _definitions =
      interactionItems(widget.phase.presentation['items']);
  late final List<String> _order = widget.state.sequenceOrder.isEmpty
      ? _definitions.map((item) => item.id).toList()
      : List<String>.from(widget.state.sequenceOrder);

  String _label(String id) =>
      _definitions.firstWhere((item) => item.id == id).label;

  @override
  Widget build(BuildContext context) => ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _order.length,
        onReorderItem: widget.enabled
            ? (oldIndex, newIndex) => _move(oldIndex, newIndex, 'drag')
            : (_, __) {},
        itemBuilder: (context, index) {
          final id = _order[index];
          final label = _label(id);
          return Card(
            key: ValueKey('sequence-item-$id'),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  enabled: widget.enabled,
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.drag_handle_rounded),
                  ),
                ),
                Expanded(child: Text(label)),
                IconButton(
                  tooltip: 'Move $label up',
                  onPressed: widget.enabled && index > 0
                      ? () => _move(index, index - 1, 'button')
                      : null,
                  icon: const Icon(Icons.arrow_upward_rounded),
                ),
                IconButton(
                  tooltip: 'Move $label down',
                  onPressed: widget.enabled && index < _order.length - 1
                      ? () => _move(index, index + 1, 'button')
                      : null,
                  icon: const Icon(Icons.arrow_downward_rounded),
                ),
              ],
            ),
          );
        },
      );

  void _move(int oldIndex, int newIndex, String inputMethod) {
    setState(() {
      final item = _order.removeAt(oldIndex);
      _order.insert(newIndex, item);
    });
    unawaited(widget.onAction('sequence_reordered', widget.phase.id, {
      'order': List<String>.from(_order),
      'input_method': inputMethod,
    }));
  }
}

class SequenceActivity extends StatelessWidget {
  const SequenceActivity({
    super.key,
    required this.stage,
    required this.sequence,
    required this.writing,
    required this.onSelected,
  });

  final AuthoritativeMissionStage stage;
  final List<String> sequence;
  final bool writing;
  final Future<void> Function(String id) onSelected;

  String _label(String id) =>
      stage.options.firstWhere((option) => option.id == id).label;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const MissionSectionLabel(
            icon: Icons.playlist_add_check_rounded,
            text: 'Choose next action',
          ),
          const SizedBox(height: 10),
          for (final option in stage.options) ...[
            MissionSelectableActionCard(
              key: ValueKey('sequence-option-${option.id}'),
              label: option.label,
              selected: sequence.contains(option.id),
              enabled: !writing && !sequence.contains(option.id),
              icon: Icons.arrow_forward_rounded,
              onTap: () => unawaited(onSelected(option.id)),
            ),
            const SizedBox(height: 8),
          ],
          EvidenceTimeline(labels: sequence.map(_label).toList()),
          const SizedBox(height: 10),
          SimulationFeedback(
            icon: Icons.timeline_rounded,
            text: '${sequence.length} of ${stage.requiredCount} actions recorded',
          ),
        ],
      );
}

class EvidenceTimeline extends StatelessWidget {
  const EvidenceTimeline({super.key, required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Evidence timeline', style: AppTheme.labelLarge),
          const SizedBox(height: 8),
          if (labels.isEmpty)
            Text('No actions recorded yet.', style: AppTheme.bodyMedium)
          else
            for (var index = 0; index < labels.length; index++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('${index + 1}. ${labels[index]}'),
              ),
        ],
      );
}
