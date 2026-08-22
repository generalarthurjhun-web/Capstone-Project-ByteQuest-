import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../components/tool_tray.dart';
import '../runtime/mission_runtime_models.dart';
import 'multi_select_interaction.dart';

class TapInspectInteraction extends StatelessWidget {
  const TapInspectInteraction({
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
    final objects = interactionItems(
      phase.presentation['objects'],
      fallbackIds: phase.availableObjectIds,
    );
    final selectedIds = state.hotspotStates.entries
        .where((entry) => entry.value == HotspotVisualState.selected)
        .map((entry) => entry.key)
        .toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MissionSectionLabel(
          icon: Icons.search_rounded,
          text: 'Inspection targets',
        ),
        const SizedBox(height: 8),
        for (final object in objects) ...[
          MissionSelectableActionCard(
            key: ValueKey('inspect-target-${object.id}'),
            label: object.label,
            selected: selectedIds.contains(object.id),
            enabled: enabled,
            icon: Icons.visibility_outlined,
            onTap: () => unawaited(onAction(
              'object_inspected',
              object.id,
              const {'input_method': 'tap'},
            )),
          ),
          if (object.data['imageAsset'] case final String imagePath
              when imagePath.isNotEmpty) ...[
            const SizedBox(height: 6),
            _InspectionImage(assetPath: imagePath, label: object.label),
          ],
          if (selectedIds.contains(object.id) &&
              object.data['inspection'] is String) ...[
            const SizedBox(height: 6),
            Semantics(
              liveRegion: true,
              label: 'Technical inspection for ${object.label}',
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(object.data['inspection'] as String),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _InspectionImage extends StatefulWidget {
  const _InspectionImage({required this.assetPath, required this.label});

  final String assetPath;
  final String label;

  @override
  State<_InspectionImage> createState() => _InspectionImageState();
}

class _InspectionImageState extends State<_InspectionImage> {
  @override
  void initState() {
    super.initState();
    debugPrint(
        '[ByteQuest image] loading inspection asset: ${widget.assetPath}');
    rootBundle.load(widget.assetPath).then<void>(
          (_) =>
              debugPrint('[ByteQuest image] asset exists: ${widget.assetPath}'),
          onError: (Object error, StackTrace stack) => debugPrint(
            '[ByteQuest image] asset missing: ${widget.assetPath} ($error)',
          ),
        );
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 120,
        child: Image.asset(
          widget.assetPath,
          fit: BoxFit.contain,
          semanticLabel: widget.label,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.red.shade100,
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image_outlined, color: Colors.red),
          ),
        ),
      );
}
