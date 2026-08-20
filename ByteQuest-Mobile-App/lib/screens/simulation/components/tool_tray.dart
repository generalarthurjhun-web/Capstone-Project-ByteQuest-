import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../runtime/mission_runtime_models.dart';

typedef MissionActionCallback = Future<void> Function(
  String actionType,
  String? target,
  Map<String, dynamic> value,
);

typedef MissionFeedbackCallback = void Function(String feedbackId);

class ToolTray extends StatelessWidget {
  const ToolTray({
    super.key,
    required this.phase,
    required this.state,
    required this.onAction,
    this.targetId,
    this.targetCategory,
    this.onFeedbackRequested,
    this.enabled = true,
  });

  final MissionPhaseDefinition phase;
  final MissionRuntimeState state;
  final MissionActionCallback onAction;
  final String? targetId;
  final String? targetCategory;
  final MissionFeedbackCallback? onFeedbackRequested;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tools = _items(phase.presentation['tools']);
    return Semantics(
      container: true,
      label: 'Available tools',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            for (final tool in tools) ...[
              _ToolButton(
                key: ValueKey('tool-tray-tool-${tool.id}'),
                tool: tool,
                selected: state.selectedToolId == tool.id,
                enabled: enabled,
                onPressed: () => _attempt(tool),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }

  void _attempt(_ToolDefinition tool) {
    final compatible = tool.compatibleCategories.isEmpty ||
        targetCategory == null ||
        tool.compatibleCategories.contains(targetCategory);
    if (!compatible) {
      onFeedbackRequested?.call('tool_incompatible');
    }
    unawaited(
      onAction(
        targetId == null ? 'tool_selected' : 'tool_attempted',
        targetId ?? tool.id,
        {
          'tool_id': tool.id,
          'tool_category': tool.category,
          if (targetCategory != null) 'target_category': targetCategory,
          'compatible': compatible,
          if (!compatible) 'feedback_id': 'tool_incompatible',
          'input_method': 'tap',
        },
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    super.key,
    required this.tool,
    required this.selected,
    required this.enabled,
    required this.onPressed,
  });

  final _ToolDefinition tool;
  final bool selected;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        enabled: enabled,
        label: selected ? '${tool.label}, active tool' : tool.label,
        child: OutlinedButton.icon(
          onPressed: enabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(96, 48),
            foregroundColor:
                selected ? AppTheme.primaryBlue : AppTheme.textDark,
            backgroundColor: selected ? AppTheme.softBlueAccent : Colors.white,
            side: BorderSide(
              color: selected ? AppTheme.primaryBlue : AppTheme.borderLight,
              width: selected ? 2 : 1,
            ),
          ),
          icon: Icon(selected ? Icons.check_circle_rounded : Icons.build_outlined),
          label: Text(tool.label),
        ),
      );
}

class _ToolDefinition {
  const _ToolDefinition({
    required this.id,
    required this.label,
    required this.category,
    required this.compatibleCategories,
  });

  final String id;
  final String label;
  final String category;
  final Set<String> compatibleCategories;
}

List<_ToolDefinition> _items(dynamic value) => (value as List? ?? const [])
    .whereType<Map>()
    .map((item) {
      final map = Map<String, dynamic>.from(item);
      return _ToolDefinition(
        id: map['id'] as String,
        label: map['label'] as String,
        category: map['category'] as String? ?? 'general',
        compatibleCategories: (map['compatible_categories'] as List? ?? const [])
            .whereType<String>()
            .toSet(),
      );
    })
    .toList(growable: false);
