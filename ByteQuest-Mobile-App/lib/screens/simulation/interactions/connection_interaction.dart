import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../components/tool_tray.dart';
import '../runtime/mission_runtime_models.dart';
import '../templates/authoritative_mission_contract.dart';
import 'multi_select_interaction.dart';

class ConnectionInteraction extends StatefulWidget {
  const ConnectionInteraction({
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
  State<ConnectionInteraction> createState() => _ConnectionInteractionState();
}

class _ConnectionInteractionState extends State<ConnectionInteraction> {
  String? _sourceId;

  @override
  Widget build(BuildContext context) {
    final sources = interactionItems(widget.phase.presentation['sources']);
    final destinations =
        interactionItems(widget.phase.presentation['destinations']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MissionSectionLabel(icon: Icons.cable_outlined, text: 'Sources'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final source in sources)
              Semantics(
                button: true,
                selected: _sourceId == source.id,
                enabled: widget.enabled,
                child: Draggable<String>(
                  data: source.id,
                  maxSimultaneousDrags: widget.enabled ? 1 : 0,
                  feedback: Material(child: Chip(label: Text(source.label))),
                  child: ChoiceChip(
                    key: ValueKey('connection-source-${source.id}'),
                    label: Text(source.label),
                    selected: _sourceId == source.id,
                    onSelected: widget.enabled
                        ? (_) => setState(() => _sourceId = source.id)
                        : null,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        const MissionSectionLabel(
          icon: Icons.hub_outlined,
          text: 'Destinations',
        ),
        const SizedBox(height: 8),
        for (final destination in destinations) ...[
          DragTarget<String>(
            onWillAcceptWithDetails: (_) => widget.enabled,
            onAcceptWithDetails: (details) => _connect(
              details.data,
              destination.id,
              'drag',
            ),
            builder: (context, candidates, _) => OutlinedButton.icon(
              key: ValueKey('connection-destination-${destination.id}'),
              onPressed: widget.enabled && _sourceId != null
                  ? () => _connect(_sourceId!, destination.id, 'tap')
                  : null,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor:
                    candidates.isEmpty ? null : AppTheme.softBlueAccent,
              ),
              icon: const Icon(Icons.settings_input_component_outlined),
              label: Text(destination.label),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  void _connect(String source, String destination, String inputMethod) {
    setState(() => _sourceId = null);
    unawaited(HapticFeedback.selectionClick());
    unawaited(widget.onAction('connection_created', destination, {
      'source_id': source,
      'destination_id': destination,
      'input_method': inputMethod,
    }));
  }
}

class ComponentPlacement extends StatelessWidget {
  const ComponentPlacement({
    super.key,
    required this.stage,
    required this.selectedMatchField,
    required this.fieldValues,
    required this.writing,
    required this.onFieldSelected,
    required this.onSourceSelected,
    required this.onDestinationSelected,
  });

  final AuthoritativeMissionStage stage;
  final String? selectedMatchField;
  final Map<String, String> fieldValues;
  final bool writing;
  final void Function(String field, String value) onFieldSelected;
  final ValueChanged<String?> onSourceSelected;
  final ValueChanged<String> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final destinations = <String, String>{};
    for (final field in stage.fields) {
      for (final option in field.options) {
        destinations.putIfAbsent(option.id, () => option.label);
      }
    }
    String sourceLabel(String id) =>
        stage.fields.firstWhere((field) => field.id == id).label;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MissionSectionLabel(
          icon: Icons.cable_outlined,
          text: 'Source components',
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final field in stage.fields)
              Semantics(
                key: ValueKey('assessment-match-source-${field.id}'),
                button: true,
                selected: selectedMatchField == field.id,
                child: Draggable<String>(
                  data: field.id,
                  maxSimultaneousDrags: writing ? 0 : 1,
                  feedback: Material(
                    color: Colors.transparent,
                    child: _ConnectionChip(
                      label: field.label,
                      selected: true,
                    ),
                  ),
                  child: InkWell(
                    onTap: writing
                        ? null
                        : () => onSourceSelected(
                              selectedMatchField == field.id ? null : field.id,
                            ),
                    child: _ConnectionChip(
                      label: fieldValues[field.id] == null
                          ? field.label
                          : '${field.label} → ${destinations[fieldValues[field.id]]}',
                      selected: selectedMatchField == field.id,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        ConnectionPath(
          connections: fieldValues.entries
              .map((entry) =>
                  '${sourceLabel(entry.key)} → ${destinations[entry.value]}')
              .toList(growable: false),
        ),
        const SizedBox(height: 12),
        const MissionSectionLabel(icon: Icons.hub_outlined, text: 'Destinations'),
        const SizedBox(height: 8),
        for (final destination in destinations.entries) ...[
          DragTarget<String>(
            onWillAcceptWithDetails: (_) => !writing,
            onAcceptWithDetails: (details) {
              onFieldSelected(details.data, destination.key);
              onSourceSelected(null);
            },
            builder: (context, candidates, _) => Semantics(
              key: ValueKey(
                'assessment-match-destination-${destination.key}',
              ),
              button: true,
              child: InkWell(
                onTap: writing || selectedMatchField == null
                    ? null
                    : () => onDestinationSelected(destination.key),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 64),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: candidates.isNotEmpty
                        ? AppTheme.softBlueAccent
                        : AppTheme.backgroundOffWhite,
                    borderRadius: AppTheme.radiusSm,
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Text(destination.value, style: AppTheme.labelLarge),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        SimulationFeedback(
          icon: Icons.hub_outlined,
          text:
              '${fieldValues.length} of ${stage.requiredCount} connections recorded',
        ),
      ],
    );
  }
}

class ConnectionPath extends StatelessWidget {
  const ConnectionPath({super.key, required this.connections});

  final List<String> connections;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 54),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.backgroundPaleBlue,
          borderRadius: AppTheme.radiusSm,
        ),
        child: connections.isEmpty
            ? Text('No connection path recorded.', style: AppTheme.bodySmall)
            : Wrap(
                spacing: 8,
                runSpacing: 6,
                children: connections
                    .map((value) => Chip(label: Text(value)))
                    .toList(growable: false),
              ),
      );
}

class _ConnectionChip extends StatelessWidget {
  const _ConnectionChip({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.softBlueAccent : Colors.white,
          borderRadius: AppTheme.radiusSm,
          border: Border.all(
            color: selected ? AppTheme.primaryBlue : AppTheme.borderLight,
          ),
        ),
        child: Text(label),
      );
}
