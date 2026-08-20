import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../components/tool_tray.dart';
import '../runtime/mission_runtime_models.dart';
import '../templates/authoritative_mission_contract.dart';
import 'multi_select_interaction.dart';

class ConfigurationPanel extends StatefulWidget {
  const ConfigurationPanel({
    super.key,
    this.phase,
    this.state,
    this.onAction,
    this.stage,
    this.fieldValues = const {},
    this.writing = false,
    this.onFieldSelected,
    this.enabled = true,
  }) : assert(
          (phase != null && state != null && onAction != null) ||
              (stage != null && onFieldSelected != null),
          'Provide runtime phase/state/onAction or the legacy stage callback.',
        );

  final MissionPhaseDefinition? phase;
  final MissionRuntimeState? state;
  final MissionActionCallback? onAction;
  final AuthoritativeMissionStage? stage;
  final Map<String, String> fieldValues;
  final bool writing;
  final void Function(String field, String value)? onFieldSelected;
  final bool enabled;

  @override
  State<ConfigurationPanel> createState() => _ConfigurationPanelState();
}

class _ConfigurationPanelState extends State<ConfigurationPanel> {
  late Map<String, dynamic> _values =
      Map<String, dynamic>.from(widget.state?.configurationValues ?? const {});
  var _runtimeRevision = 0;

  @override
  void didUpdateWidget(covariant ConfigurationPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldValues = oldWidget.state?.configurationValues ?? const {};
    final newValues = widget.state?.configurationValues ?? const {};
    if (oldWidget.phase?.id != widget.phase?.id ||
        !mapEquals(oldValues, newValues)) {
      _values = Map<String, dynamic>.from(newValues);
      _runtimeRevision++;
    }
  }

  @override
  Widget build(BuildContext context) => widget.phase == null
      ? _buildLegacy(context)
      : _buildRuntime(context);

  Widget _buildRuntime(BuildContext context) {
    final fields = interactionItems(widget.phase!.presentation['fields']);
    return KeyedSubtree(
      key: ValueKey(
        'configuration-runtime-${widget.phase!.id}-$_runtimeRevision',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        const MissionSectionLabel(
          icon: Icons.tune_rounded,
          text: 'Configuration values',
        ),
        const SizedBox(height: 8),
        for (final field in fields) ...[
          _runtimeField(field),
          const SizedBox(height: 12),
        ],
        FilledButton.icon(
          onPressed: widget.enabled
              ? () => unawaited(widget.onAction!(
                    'configuration_applied',
                    widget.phase!.id,
                    {
                      'values': Map<String, dynamic>.from(_values),
                      'input_method': 'button',
                    },
                  ))
              : null,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          icon: const Icon(Icons.settings_ethernet_outlined),
          label: const Text('Apply configuration'),
        ),
        ],
      ),
    );
  }

  Widget _runtimeField(InteractionItem field) {
    final type = field.data['type'] as String? ?? 'text';
    if (type == 'toggle') {
      return SwitchListTile(
        key: ValueKey('configuration-field-${field.id}'),
        title: Text(field.label),
        value: _values[field.id] as bool? ?? false,
        onChanged: widget.enabled
            ? (value) => setState(() => _values[field.id] = value)
            : null,
      );
    }
    if (type == 'dropdown') {
      final options = interactionItems(field.data['options']);
      return DropdownButtonFormField<String>(
        key: ValueKey('configuration-field-${field.id}'),
        initialValue: _values[field.id] as String?,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: field.label,
          border: const OutlineInputBorder(),
        ),
        items: options
            .map((option) => DropdownMenuItem(
                  value: option.id,
                  child: Text(option.label),
                ))
            .toList(growable: false),
        onChanged: widget.enabled
            ? (value) {
                if (value != null) _values[field.id] = value;
              }
            : null,
      );
    }
    return TextFormField(
      key: ValueKey('configuration-field-${field.id}'),
      initialValue: _values[field.id]?.toString(),
      enabled: widget.enabled,
      decoration: InputDecoration(
        labelText: field.label,
        border: const OutlineInputBorder(),
      ),
      onChanged: (value) => _values[field.id] = value,
    );
  }

  Widget _buildLegacy(BuildContext context) {
    final stage = widget.stage!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MissionSectionLabel(
          icon: Icons.tune_rounded,
          text: 'Simulated configuration',
        ),
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
                  initialValue: widget.fieldValues[field.id],
                  dropdownColor: Colors.white,
                  decoration: InputDecoration(
                    labelText: field.label,
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
                  onChanged: widget.writing
                      ? null
                      : (value) {
                          if (value != null) {
                            widget.onFieldSelected!(field.id, value);
                          }
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
              '${widget.fieldValues.length} of ${stage.requiredCount} values applied',
        ),
      ],
    );
  }
}
