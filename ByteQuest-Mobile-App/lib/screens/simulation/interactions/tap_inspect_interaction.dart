import 'dart:async';

import 'package:flutter/material.dart';

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
            onTap: () => unawaited(
              onAction('object_inspected', object.id, const {
                'input_method': 'tap',
              }),
            ),
          ),
          if (object.imageAsset case final String imagePath
              when imagePath.isNotEmpty) ...[
            const SizedBox(height: 6),
            _InspectionImage(objectName: object.label, assetPath: imagePath),
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

class _InspectionImage extends StatelessWidget {
  const _InspectionImage({required this.objectName, required this.assetPath});

  final String objectName;
  final String assetPath;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final mediaSize = MediaQuery.sizeOf(context);
          final width = constraints.hasBoundedWidth && constraints.maxWidth > 0
              ? constraints.maxWidth
              : mediaSize.width;
          const height = 120.0;
          return SizedBox(
            width: width,
            height: height,
            child: Image.asset(
              assetPath,
              fit: BoxFit.contain,
              semanticLabel: objectName,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.red.shade100,
                alignment: Alignment.center,
                child:
                    const Icon(Icons.broken_image_outlined, color: Colors.red),
              ),
            ),
          );
        },
      );
}
