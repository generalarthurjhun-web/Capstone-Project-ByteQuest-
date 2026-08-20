import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../components/tool_tray.dart';
import '../runtime/mission_runtime_models.dart';

/// A diagnostic branch that reveals only facts earned by recorded actions.
class TroubleshootingBranchInteraction extends StatelessWidget {
  const TroubleshootingBranchInteraction({
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
  Widget build(BuildContext context) {
    final presentation = phase.presentation;
    final symptom = presentation['symptom'] as String? ?? phase.instruction;
    final facts = _stringMap(presentation['facts']);
    final actions = _mapList(presentation['diagnostic_actions']);
    final requiredFacts = _stringList(presentation['required_fact_ids']).toSet();
    final correction = _map(presentation['correction']);
    final retest = _map(presentation['retest']);
    final correctionId = correction['id'] as String?;
    final canCorrect = enabled &&
        requiredFacts.isNotEmpty &&
        state.revealedFactIds.containsAll(requiredFacts);
    final canRetest = enabled &&
        correctionId != null &&
        state.selectedBranchActionIds.contains(correctionId);

    return Semantics(
      container: true,
      label: 'Troubleshooting diagnostics',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Reported symptom', style: AppTheme.labelLarge),
          const SizedBox(height: 6),
          Text(symptom, style: AppTheme.bodyLarge),
          const SizedBox(height: 16),
          Text('Diagnostic actions', style: AppTheme.labelLarge),
          const SizedBox(height: 8),
          for (final action in actions) ...[
            OutlinedButton.icon(
              onPressed: enabled ? () => _recordDiagnostic(action) : null,
              icon: const Icon(Icons.search_rounded),
              label: Text(action['label'] as String? ?? 'Inspect'),
            ),
            const SizedBox(height: 8),
          ],
          if (state.revealedFactIds.any(facts.containsKey)) ...[
            const SizedBox(height: 4),
            Text('Recorded findings', style: AppTheme.labelLarge),
            const SizedBox(height: 8),
            for (final factId in state.revealedFactIds)
              if (facts[factId] case final fact?)
                Semantics(
                  liveRegion: true,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(fact, style: AppTheme.bodyMedium),
                  ),
                ),
          ],
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: canCorrect ? () => _recordCorrection(correction) : null,
            icon: const Icon(Icons.build_outlined),
            label: Text(correction['label'] as String? ?? 'Apply correction'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: canRetest ? () => _recordRetest(retest) : null,
            icon: const Icon(Icons.replay_rounded),
            label: Text(retest['label'] as String? ?? 'Retest'),
          ),
        ],
      ),
    );
  }

  void _recordDiagnostic(Map<String, dynamic> action) {
    final id = action['id'] as String?;
    final factId = action['reveals_fact_id'] as String?;
    if (id == null || factId == null) return;
    unawaited(onAction('diagnostic_action', id, {
      'reveals_fact_id': factId,
      'input_method': 'tap',
    }));
  }

  void _recordCorrection(Map<String, dynamic> correction) {
    final id = correction['id'] as String?;
    if (id == null) return;
    unawaited(onAction('correction_applied', id, const {
      'input_method': 'tap',
    }));
  }

  void _recordRetest(Map<String, dynamic> retest) {
    final id = retest['id'] as String?;
    if (id == null) return;
    unawaited(onAction('retest_requested', id, const {
      'input_method': 'tap',
    }));
  }
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

List<Map<String, dynamic>> _mapList(dynamic value) => (value as List? ?? const [])
    .whereType<Map>()
    .map((item) => Map<String, dynamic>.from(item))
    .toList(growable: false);

Map<String, String> _stringMap(dynamic value) => value is Map
    ? value.map((key, item) => MapEntry(key.toString(), item.toString()))
    : <String, String>{};

List<String> _stringList(dynamic value) =>
    (value as List? ?? const []).whereType<String>().toList(growable: false);
