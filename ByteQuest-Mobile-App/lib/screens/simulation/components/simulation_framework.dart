import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../templates/authoritative_mission_contract.dart';
import 'mission_simulation_profile.dart';
import 'simulation_scene.dart';

export 'simulation_scene.dart' show InteractiveHotspot, SimulationScene;

/// Presentation-only interaction vocabulary for the generalized authoritative
/// mission renderer. The published rubric and PostgreSQL evaluator remain the
/// sole source of correctness; this resolver never receives expected answers.
enum SimulationPresentationKind {
  inspection,
  toolSelection,
  procedure,
  connection,
  configuration,
  troubleshooting,
  observation,
  testing,
  decision,
}

SimulationPresentationKind presentationForStage(
  AuthoritativeMissionStage stage,
) {
  final haystack =
      '${stage.id} ${stage.title} ${stage.actionType}'.toLowerCase();
  if (stage.type == AuthoritativeStageType.matching) {
    return SimulationPresentationKind.connection;
  }
  if (stage.type == AuthoritativeStageType.configuration) {
    return SimulationPresentationKind.configuration;
  }
  if (stage.type == AuthoritativeStageType.sequence) {
    return SimulationPresentationKind.procedure;
  }
  if (haystack.contains('diagnos') ||
      haystack.contains('fault') ||
      haystack.contains('symptom') ||
      haystack.contains('corrective')) {
    return SimulationPresentationKind.troubleshooting;
  }
  if (haystack.contains('test') ||
      haystack.contains('verify') ||
      haystack.contains('result')) {
    return SimulationPresentationKind.testing;
  }
  if (haystack.contains('observ') ||
      haystack.contains('inspect') ||
      haystack.contains('condition')) {
    return SimulationPresentationKind.observation;
  }
  if (haystack.contains('tool') ||
      haystack.contains('resource') ||
      haystack.contains('material') ||
      haystack.contains('component')) {
    return SimulationPresentationKind.toolSelection;
  }
  if (stage.type == AuthoritativeStageType.selection) {
    return SimulationPresentationKind.inspection;
  }
  return SimulationPresentationKind.decision;
}

class MissionProgress extends StatelessWidget {
  final String unitTitle;
  final MissionSimulationProfile profile;
  final int current;
  final int total;

  const MissionProgress({
    super.key,
    required this.unitTitle,
    required this.profile,
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final progress = current / total;
    return Semantics(
      label: '${profile.identityLabel}. Assessment stage $current of $total',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppTheme.radiusMd,
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.softBlueAccent,
                    borderRadius: AppTheme.radiusSm,
                  ),
                  child: Icon(
                    _identityIcon(profile.identity),
                    color: AppTheme.deepBlue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.identityLabel, style: AppTheme.labelLarge),
                      const SizedBox(height: 2),
                      Text(
                        unitTitle,
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textMedium,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text('$current / $total', style: AppTheme.labelMedium),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppTheme.softBlueAccent,
                color: AppTheme.primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SimulationStageExperience extends StatelessWidget {
  final AuthoritativeMissionStage stage;
  final MissionSimulationProfile profile;
  final Set<String> inspectedObjectIds;
  final Set<String> selectedItems;
  final List<String> sequence;
  final String? selectedOption;
  final String? selectedMatchField;
  final Map<String, String> fieldValues;
  final bool writing;
  final ValueChanged<String> onInspectObject;
  final void Function(String id, bool selected) onSelectionChanged;
  final Future<void> Function(String id) onSequenceSelected;
  final ValueChanged<String> onSingleSelected;
  final void Function(String field, String value) onFieldSelected;
  final ValueChanged<String?> onMatchSourceSelected;
  final ValueChanged<String> onMatchDestinationSelected;
  final Future<void> Function(String actionType) onOperationalAction;
  final Set<String> operationalActions;

  const SimulationStageExperience({
    super.key,
    required this.stage,
    required this.profile,
    required this.inspectedObjectIds,
    required this.selectedItems,
    required this.sequence,
    required this.selectedOption,
    required this.selectedMatchField,
    required this.fieldValues,
    required this.writing,
    required this.onInspectObject,
    required this.onSelectionChanged,
    required this.onSequenceSelected,
    required this.onSingleSelected,
    required this.onFieldSelected,
    required this.onMatchSourceSelected,
    required this.onMatchDestinationSelected,
    required this.onOperationalAction,
    required this.operationalActions,
  });

  @override
  Widget build(BuildContext context) {
    final presentation = presentationForStage(stage);
    return Container(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 380 ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.radiusMd,
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StageBriefing(stage: stage, presentation: presentation),
          const SizedBox(height: 16),
          SimulationScene(
            profile: profile,
            inspectedObjectIds: inspectedObjectIds,
            enabled: !writing,
            onObjectSelected: onInspectObject,
          ),
          const SizedBox(height: 16),
          SimulationHint(
            message: _hintFor(presentation),
          ),
          const SizedBox(height: 16),
          switch (presentation) {
            SimulationPresentationKind.toolSelection => ToolPalette(
                stage: stage,
                selectedItems: selectedItems,
                writing: writing,
                onChanged: onSelectionChanged,
              ),
            SimulationPresentationKind.inspection => MultiSelectInspection(
                stage: stage,
                selectedItems: selectedItems,
                writing: writing,
                onChanged: onSelectionChanged,
              ),
            SimulationPresentationKind.procedure => SequenceActivity(
                stage: stage,
                sequence: sequence,
                writing: writing,
                onSelected: onSequenceSelected,
              ),
            SimulationPresentationKind.connection => ComponentPlacement(
                stage: stage,
                selectedMatchField: selectedMatchField,
                fieldValues: fieldValues,
                writing: writing,
                onFieldSelected: onFieldSelected,
                onSourceSelected: onMatchSourceSelected,
                onDestinationSelected: onMatchDestinationSelected,
              ),
            SimulationPresentationKind.configuration => ConfigurationPanel(
                stage: stage,
                fieldValues: fieldValues,
                writing: writing,
                onFieldSelected: onFieldSelected,
              ),
            SimulationPresentationKind.troubleshooting => TroubleshootingFlow(
                stage: stage,
                selectedItems: selectedItems,
                selectedOption: selectedOption,
                writing: writing,
                inspected: operationalActions.contains('inspect_symptom'),
                onInspect: () => onOperationalAction('inspect_symptom'),
                onSelectionChanged: onSelectionChanged,
                onSingleSelected: onSingleSelected,
              ),
            SimulationPresentationKind.testing => TestingPanel(
                stage: stage,
                selectedItems: selectedItems,
                selectedOption: selectedOption,
                writing: writing,
                testRun: operationalActions.contains('run_simulated_test'),
                onRunTest: () => onOperationalAction('run_simulated_test'),
                onSelectionChanged: onSelectionChanged,
                onSingleSelected: onSingleSelected,
              ),
            SimulationPresentationKind.observation => ObservationPanel(
                stage: stage,
                selectedItems: selectedItems,
                selectedOption: selectedOption,
                writing: writing,
                onSelectionChanged: onSelectionChanged,
                onSingleSelected: onSingleSelected,
              ),
            SimulationPresentationKind.decision => ScenarioDecision(
                stage: stage,
                selectedOption: selectedOption,
                writing: writing,
                onSelected: onSingleSelected,
              ),
          },
        ],
      ),
    );
  }

  static String _hintFor(SimulationPresentationKind kind) => switch (kind) {
        SimulationPresentationKind.inspection =>
          'Inspect the scene, then record only the items supported by the scenario.',
        SimulationPresentationKind.toolSelection =>
          'Choose resources deliberately. Selection alone does not reveal correctness.',
        SimulationPresentationKind.procedure =>
          'Record the next technical action in the order you would perform it.',
        SimulationPresentationKind.connection =>
          'Connect by dragging, or use the accessible source-then-destination method.',
        SimulationPresentationKind.configuration =>
          'Apply values from the scenario design, then verify every configured field.',
        SimulationPresentationKind.troubleshooting =>
          'Observe symptoms before choosing a diagnostic or corrective decision.',
        SimulationPresentationKind.observation =>
          'Record what the simulated condition supports; do not infer hidden results.',
        SimulationPresentationKind.testing =>
          'Run the simulated test before interpreting the displayed scenario evidence.',
        SimulationPresentationKind.decision =>
          'Choose the most appropriate next action for the current technical state.',
      };
}

class _StageBriefing extends StatelessWidget {
  final AuthoritativeMissionStage stage;
  final SimulationPresentationKind presentation;

  const _StageBriefing({required this.stage, required this.presentation});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.softBlueAccent,
              borderRadius: AppTheme.radiusSm,
            ),
            child:
                Icon(_presentationIcon(presentation), color: AppTheme.deepBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stage.title, style: AppTheme.headlineSmall),
                const SizedBox(height: 5),
                Text(stage.instruction, style: AppTheme.bodyMedium),
              ],
            ),
          ),
        ],
      );
}

class MultiSelectInspection extends StatelessWidget {
  final AuthoritativeMissionStage stage;
  final Set<String> selectedItems;
  final bool writing;
  final void Function(String id, bool selected) onChanged;

  const MultiSelectInspection({
    super.key,
    required this.stage,
    required this.selectedItems,
    required this.writing,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionLabel(
              icon: Icons.search_rounded, text: 'Inspection record'),
          const SizedBox(height: 10),
          for (final option in stage.options) ...[
            _SelectableActionCard(
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

class ToolPalette extends StatelessWidget {
  final AuthoritativeMissionStage stage;
  final Set<String> selectedItems;
  final bool writing;
  final void Function(String id, bool selected) onChanged;

  const ToolPalette({
    super.key,
    required this.stage,
    required this.selectedItems,
    required this.writing,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionLabel(
              icon: Icons.handyman_outlined, text: 'Available resources'),
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
              return _SelectableActionCard(
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

class SequenceActivity extends StatelessWidget {
  final AuthoritativeMissionStage stage;
  final List<String> sequence;
  final bool writing;
  final Future<void> Function(String id) onSelected;

  const SequenceActivity({
    super.key,
    required this.stage,
    required this.sequence,
    required this.writing,
    required this.onSelected,
  });

  String _label(String id) =>
      stage.options.firstWhere((option) => option.id == id).label;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionLabel(
              icon: Icons.playlist_add_check_rounded,
              text: 'Choose next action'),
          const SizedBox(height: 10),
          for (final option in stage.options) ...[
            _SelectableActionCard(
              key: ValueKey('sequence-option-${option.id}'),
              label: option.label,
              selected: sequence.contains(option.id),
              enabled: !writing && !sequence.contains(option.id),
              icon: sequence.contains(option.id)
                  ? Icons.check_rounded
                  : Icons.arrow_forward_rounded,
              onTap: () => unawaited(onSelected(option.id)),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 4),
          EvidenceTimeline(labels: sequence.map(_label).toList()),
          const SizedBox(height: 10),
          SimulationFeedback(
            icon: Icons.timeline_rounded,
            text:
                '${sequence.length} of ${stage.requiredCount} actions recorded',
          ),
        ],
      );
}

class EvidenceTimeline extends StatelessWidget {
  final List<String> labels;

  const EvidenceTimeline({super.key, required this.labels});

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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      child: Text('${index + 1}',
                          style: AppTheme.labelSmall
                              .copyWith(color: Colors.white)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(labels[index], style: AppTheme.bodyMedium)),
                  ],
                ),
              ),
        ],
      );
}

class ScenarioDecision extends StatelessWidget {
  final AuthoritativeMissionStage stage;
  final String? selectedOption;
  final bool writing;
  final ValueChanged<String> onSelected;

  const ScenarioDecision({
    super.key,
    required this.stage,
    required this.selectedOption,
    required this.writing,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionLabel(
              icon: Icons.alt_route_rounded, text: 'Technical decision'),
          const SizedBox(height: 10),
          for (final option in stage.options) ...[
            _SelectableActionCard(
              key: ValueKey('decision-option-${option.id}'),
              label: option.label,
              selected: selectedOption == option.id,
              enabled: !writing,
              icon: Icons.chevron_right_rounded,
              onTap: () => onSelected(option.id),
            ),
            const SizedBox(height: 8),
          ],
        ],
      );
}

class ConfigurationPanel extends StatelessWidget {
  final AuthoritativeMissionStage stage;
  final Map<String, String> fieldValues;
  final bool writing;
  final void Function(String field, String value) onFieldSelected;

  const ConfigurationPanel({
    super.key,
    required this.stage,
    required this.fieldValues,
    required this.writing,
    required this.onFieldSelected,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionLabel(
              icon: Icons.tune_rounded, text: 'Simulated configuration'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.navy,
              borderRadius: AppTheme.radiusSm,
            ),
            child: Column(
              children: [
                for (final field in stage.fields) ...[
                  DropdownButtonFormField<String>(
                    key: ValueKey('configuration-field-${field.id}'),
                    initialValue: fieldValues[field.id],
                    dropdownColor: Colors.white,
                    style: AppTheme.bodyMedium,
                    decoration: InputDecoration(
                      labelText: field.label,
                      labelStyle: AppTheme.labelMedium
                          .copyWith(color: AppTheme.textMedium),
                      filled: true,
                      fillColor: Colors.white,
                      border: const OutlineInputBorder(),
                    ),
                    isExpanded: true,
                    items: field.options
                        .map((option) => DropdownMenuItem(
                              value: option.id,
                              child: Text(option.label),
                            ))
                        .toList(growable: false),
                    onChanged: writing
                        ? null
                        : (value) {
                            if (value != null) onFieldSelected(field.id, value);
                          },
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          SimulationFeedback(
            icon: Icons.settings_ethernet_outlined,
            text:
                '${fieldValues.length} of ${stage.requiredCount} values applied',
          ),
        ],
      );
}

class ComponentPlacement extends StatelessWidget {
  final AuthoritativeMissionStage stage;
  final String? selectedMatchField;
  final Map<String, String> fieldValues;
  final bool writing;
  final void Function(String field, String value) onFieldSelected;
  final ValueChanged<String?> onSourceSelected;
  final ValueChanged<String> onDestinationSelected;

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
        const _SectionLabel(
            icon: Icons.cable_outlined, text: 'Source components'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: stage.fields.map((field) {
            final selected = selectedMatchField == field.id;
            final destination = fieldValues[field.id];
            return Semantics(
              key: ValueKey('assessment-match-source-${field.id}'),
              button: true,
              selected: selected,
              label: destination == null
                  ? '${field.label}, not connected'
                  : '${field.label}, connected to ${destinations[destination]}',
              child: Draggable<String>(
                data: field.id,
                maxSimultaneousDrags: writing ? 0 : 1,
                feedback: Material(
                  color: Colors.transparent,
                  child: _ConnectionChip(label: field.label, selected: true),
                ),
                childWhenDragging: Opacity(
                  opacity: .4,
                  child:
                      _ConnectionChip(label: field.label, selected: selected),
                ),
                child: InkWell(
                  onTap: writing
                      ? null
                      : () => onSourceSelected(selected ? null : field.id),
                  borderRadius: AppTheme.radiusSm,
                  child: _ConnectionChip(
                    label: destination == null
                        ? field.label
                        : '${field.label} → ${destinations[destination]}',
                    selected: selected,
                  ),
                ),
              ),
            );
          }).toList(growable: false),
        ),
        const SizedBox(height: 16),
        ConnectionPath(
          connections: fieldValues.entries
              .map((entry) =>
                  '${sourceLabel(entry.key)} → ${destinations[entry.value]}')
              .toList(growable: false),
        ),
        const SizedBox(height: 12),
        const _SectionLabel(icon: Icons.hub_outlined, text: 'Destinations'),
        const SizedBox(height: 8),
        for (final destination in destinations.entries) ...[
          DragTarget<String>(
            onWillAcceptWithDetails: (_) => !writing,
            onAcceptWithDetails: (details) {
              onFieldSelected(details.data, destination.key);
              onSourceSelected(null);
              unawaited(HapticFeedback.selectionClick());
            },
            builder: (context, candidates, _) {
              final assigned = fieldValues.entries
                  .where((entry) => entry.value == destination.key)
                  .map((entry) => sourceLabel(entry.key))
                  .toList(growable: false);
              return Semantics(
                key:
                    ValueKey('assessment-match-destination-${destination.key}'),
                button: true,
                label: assigned.isEmpty
                    ? '${destination.value}, available destination'
                    : '${destination.value}, connected from ${assigned.join(', ')}',
                child: InkWell(
                  onTap: writing || selectedMatchField == null
                      ? null
                      : () => onDestinationSelected(destination.key),
                  borderRadius: AppTheme.radiusSm,
                  child: AnimatedContainer(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 160),
                    constraints: const BoxConstraints(minHeight: 64),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: candidates.isNotEmpty
                          ? AppTheme.softBlueAccent
                          : AppTheme.backgroundOffWhite,
                      borderRadius: AppTheme.radiusSm,
                      border: Border.all(
                        color: candidates.isNotEmpty
                            ? AppTheme.primaryBlue
                            : AppTheme.borderLight,
                        width: candidates.isNotEmpty ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.settings_input_component_outlined,
                            color: AppTheme.deepBlue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(destination.value,
                                  style: AppTheme.labelLarge),
                              Text(
                                assigned.isEmpty
                                    ? (selectedMatchField == null
                                        ? 'Drag or choose a source first'
                                        : 'Select to connect the chosen source')
                                    : assigned.join(', '),
                                style: AppTheme.bodySmall
                                    .copyWith(color: AppTheme.textMedium),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
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
  final List<String> connections;

  const ConnectionPath({super.key, required this.connections});

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
                    .map((value) => Chip(
                          avatar: const Icon(Icons.cable_outlined, size: 18),
                          label: Text(value),
                        ))
                    .toList(growable: false),
              ),
      );
}

class TroubleshootingFlow extends StatelessWidget {
  final AuthoritativeMissionStage stage;
  final Set<String> selectedItems;
  final String? selectedOption;
  final bool writing;
  final bool inspected;
  final Future<void> Function() onInspect;
  final void Function(String id, bool selected) onSelectionChanged;
  final ValueChanged<String> onSingleSelected;

  const TroubleshootingFlow({
    super.key,
    required this.stage,
    required this.selectedItems,
    required this.selectedOption,
    required this.writing,
    required this.inspected,
    required this.onInspect,
    required this.onSelectionChanged,
    required this.onSingleSelected,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _OperationalAction(
            icon: Icons.manage_search_rounded,
            title: 'Inspect symptom state',
            subtitle: inspected
                ? 'Symptom inspection recorded. Continue with your diagnosis.'
                : 'Observe the simulated equipment before deciding.',
            completed: inspected,
            enabled: !writing,
            onPressed: () => unawaited(onInspect()),
          ),
          const SizedBox(height: 12),
          if (stage.type == AuthoritativeStageType.selection)
            MultiSelectInspection(
              stage: stage,
              selectedItems: selectedItems,
              writing: writing || !inspected,
              onChanged: onSelectionChanged,
            )
          else
            ScenarioDecision(
              stage: stage,
              selectedOption: selectedOption,
              writing: writing || !inspected,
              onSelected: onSingleSelected,
            ),
        ],
      );
}

class TestingPanel extends StatelessWidget {
  final AuthoritativeMissionStage stage;
  final Set<String> selectedItems;
  final String? selectedOption;
  final bool writing;
  final bool testRun;
  final Future<void> Function() onRunTest;
  final void Function(String id, bool selected) onSelectionChanged;
  final ValueChanged<String> onSingleSelected;

  const TestingPanel({
    super.key,
    required this.stage,
    required this.selectedItems,
    required this.selectedOption,
    required this.writing,
    required this.testRun,
    required this.onRunTest,
    required this.onSelectionChanged,
    required this.onSingleSelected,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _OperationalAction(
            icon: Icons.play_circle_outline_rounded,
            title: 'Run simulated test',
            subtitle: testRun
                ? 'Test execution recorded. Interpret the scenario result below.'
                : 'Perform the test before recording an interpretation.',
            completed: testRun,
            enabled: !writing,
            onPressed: () => unawaited(onRunTest()),
          ),
          const SizedBox(height: 12),
          if (stage.type == AuthoritativeStageType.selection)
            MultiSelectInspection(
              stage: stage,
              selectedItems: selectedItems,
              writing: writing || !testRun,
              onChanged: onSelectionChanged,
            )
          else
            ScenarioDecision(
              stage: stage,
              selectedOption: selectedOption,
              writing: writing || !testRun,
              onSelected: onSingleSelected,
            ),
        ],
      );
}

class ObservationPanel extends StatelessWidget {
  final AuthoritativeMissionStage stage;
  final Set<String> selectedItems;
  final String? selectedOption;
  final bool writing;
  final void Function(String id, bool selected) onSelectionChanged;
  final ValueChanged<String> onSingleSelected;

  const ObservationPanel({
    super.key,
    required this.stage,
    required this.selectedItems,
    required this.selectedOption,
    required this.writing,
    required this.onSelectionChanged,
    required this.onSingleSelected,
  });

  @override
  Widget build(BuildContext context) =>
      stage.type == AuthoritativeStageType.selection
          ? MultiSelectInspection(
              stage: stage,
              selectedItems: selectedItems,
              writing: writing,
              onChanged: onSelectionChanged,
            )
          : ScenarioDecision(
              stage: stage,
              selectedOption: selectedOption,
              writing: writing,
              onSelected: onSingleSelected,
            );
}

class SimulationFeedback extends StatelessWidget {
  final IconData icon;
  final String text;

  const SimulationFeedback({super.key, required this.icon, required this.text});

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

class SimulationHint extends StatelessWidget {
  final String message;

  const SimulationHint({super.key, required this.message});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.backgroundOffWhite,
          borderRadius: AppTheme.radiusSm,
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline_rounded,
                size: 20, color: AppTheme.deepBlue),
            const SizedBox(width: 9),
            Expanded(child: Text(message, style: AppTheme.bodySmall)),
          ],
        ),
      );
}

class _OperationalAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool completed;
  final bool enabled;
  final VoidCallback onPressed;

  const _OperationalAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.completed,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        enabled: enabled && !completed,
        label: completed ? '$title, completed' : title,
        child: OutlinedButton(
          onPressed: enabled && !completed ? onPressed : null,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(64),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          child: Row(
            children: [
              Icon(completed ? Icons.check_circle_rounded : icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTheme.labelLarge),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _SelectableActionCard extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final IconData icon;
  final VoidCallback onTap;

  const _SelectableActionCard({
    super.key,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.icon,
    required this.onTap,
  });

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
                  : const Duration(milliseconds: 160),
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

class _ConnectionChip extends StatelessWidget {
  final String label;
  final bool selected;

  const _ConnectionChip({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minHeight: 48, maxWidth: 280),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.softBlueAccent : Colors.white,
          borderRadius: AppTheme.radiusSm,
          border: Border.all(
            color: selected ? AppTheme.primaryBlue : AppTheme.borderLight,
            width: selected ? 2 : 1,
          ),
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cable_outlined,
                size: 20,
                color: selected ? AppTheme.primaryBlue : AppTheme.textMedium),
            const SizedBox(width: 8),
            Flexible(child: Text(label, style: AppTheme.labelMedium)),
          ],
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SectionLabel({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.deepBlue),
          const SizedBox(width: 7),
          Expanded(child: Text(text, style: AppTheme.labelLarge)),
        ],
      );
}

IconData _identityIcon(MissionInteractionIdentity identity) =>
    switch (identity) {
      MissionInteractionIdentity.planning => Icons.assignment_outlined,
      MissionInteractionIdentity.inspection => Icons.search_rounded,
      MissionInteractionIdentity.assembly =>
        Icons.precision_manufacturing_outlined,
      MissionInteractionIdentity.connection => Icons.hub_outlined,
      MissionInteractionIdentity.configuration => Icons.tune_rounded,
      MissionInteractionIdentity.deployment => Icons.install_desktop_outlined,
      MissionInteractionIdentity.diagnostics => Icons.troubleshoot_rounded,
      MissionInteractionIdentity.maintenance =>
        Icons.cleaning_services_outlined,
      MissionInteractionIdentity.repair => Icons.build_circle_outlined,
      MissionInteractionIdentity.verification => Icons.verified_outlined,
    };

IconData _presentationIcon(SimulationPresentationKind presentation) =>
    switch (presentation) {
      SimulationPresentationKind.inspection => Icons.fact_check_outlined,
      SimulationPresentationKind.toolSelection => Icons.handyman_outlined,
      SimulationPresentationKind.procedure => Icons.timeline_rounded,
      SimulationPresentationKind.connection => Icons.hub_outlined,
      SimulationPresentationKind.configuration => Icons.tune_rounded,
      SimulationPresentationKind.troubleshooting => Icons.troubleshoot_rounded,
      SimulationPresentationKind.observation => Icons.visibility_outlined,
      SimulationPresentationKind.testing => Icons.science_outlined,
      SimulationPresentationKind.decision => Icons.alt_route_rounded,
    };
