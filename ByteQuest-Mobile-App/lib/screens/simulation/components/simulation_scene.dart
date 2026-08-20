import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../runtime/mission_runtime_models.dart';
import 'hotspot_widget.dart';
import 'mission_simulation_profile.dart';
import 'scene_connection_painter.dart';

/// Responsive, presentation-only 2D scene engine.
///
/// New runtime callers provide [scene]. Existing assessment screens may keep
/// providing [profile]; it is adapted to the same scene-definition pipeline.
class SimulationScene extends StatefulWidget {
  static const Size logicalCanvasSize = Size(1200, 720);

  final SimulationSceneDefinition? scene;
  final MissionSimulationProfile? profile;
  final Map<String, HotspotVisualState> hotspotStates;
  final Set<String> inspectedObjectIds;
  final Set<String> connectedNodePairs;
  final bool enabled;
  final ValueChanged<String> onObjectSelected;
  final Widget? backgroundRenderer;
  final List<Widget> statusOverlays;

  const SimulationScene({
    super.key,
    this.scene,
    this.profile,
    this.hotspotStates = const {},
    this.inspectedObjectIds = const {},
    this.connectedNodePairs = const {},
    this.enabled = true,
    required this.onObjectSelected,
    this.backgroundRenderer,
    this.statusOverlays = const [],
  }) : assert(
          scene != null || profile != null,
          'Provide either a runtime scene definition or a legacy profile.',
        );

  @override
  State<SimulationScene> createState() => _SimulationSceneState();
}

class _SimulationSceneState extends State<SimulationScene> {
  final TransformationController _transformationController =
      TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _resetView() {
    _transformationController.value = Matrix4.identity();
    unawaited(HapticFeedback.selectionClick());
  }

  void _fitView() {
    // The logical workspace is fitted into the viewport before camera
    // transforms are applied, so identity is the fit-to-screen transform.
    _transformationController.value = Matrix4.identity();
  }

  void _selectObject(String id) {
    if (!widget.enabled) return;
    widget.onObjectSelected(id);
    unawaited(HapticFeedback.selectionClick());
  }

  @override
  Widget build(BuildContext context) {
    final resolved = _ResolvedScene.fromWidget(widget);
    return Semantics(
      container: true,
      label: '${resolved.title}. ${resolved.prompt}',
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFE),
          borderRadius: AppTheme.radiusMd,
          border: Border.all(color: AppTheme.borderLight),
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final usesAvailableHeight =
                constraints.hasBoundedHeight && constraints.maxHeight.isFinite;
            final canvas = _SceneViewport(
              resolved: resolved,
              transformationController: _transformationController,
              hotspotStates: widget.hotspotStates,
              inspectedObjectIds: widget.inspectedObjectIds,
              connectedNodePairs: widget.connectedNodePairs,
              enabled: widget.enabled,
              onObjectSelected: _selectObject,
              backgroundRenderer: widget.backgroundRenderer,
              statusOverlays: widget.statusOverlays,
            );
            return Column(
              mainAxisSize:
                  usesAvailableHeight ? MainAxisSize.max : MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SceneToolbar(
                  title: resolved.title,
                  onShowObjects: () => _showObjectPicker(resolved),
                  onReset: _resetView,
                  onFit: _fitView,
                ),
                if (usesAvailableHeight)
                  Expanded(child: canvas)
                else
                  AspectRatio(
                    aspectRatio: SimulationScene.logicalCanvasSize.aspectRatio,
                    child: canvas,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _showObjectPicker(_ResolvedScene resolved) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 420),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Text('Objects', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final object in resolved.definition.objects)
                ListTile(
                  key: ValueKey('object-list-${object.id}'),
                  enabled: widget.enabled,
                  leading: Icon(_iconForObject(resolved, object)),
                  title: Text(object.label),
                  subtitle: Text(_stateFor(object.id).name),
                  onTap: widget.enabled
                      ? () {
                          Navigator.of(sheetContext).pop();
                          _selectObject(object.id);
                        }
                      : null,
                ),
            ],
          ),
        ),
      ),
    );
  }

  HotspotVisualState _stateFor(String id) =>
      widget.hotspotStates[id] ??
      (widget.inspectedObjectIds.contains(id)
          ? HotspotVisualState.completed
          : HotspotVisualState.neutral);
}

class _SceneToolbar extends StatelessWidget {
  final String title;
  final VoidCallback onShowObjects;
  final VoidCallback onReset;
  final VoidCallback onFit;

  const _SceneToolbar({
    required this.title,
    required this.onShowObjects,
    required this.onReset,
    required this.onFit,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final titleWidget = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.labelLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Inspect the schematic workspace and its objects.',
                  style: AppTheme.caption.copyWith(color: AppTheme.textMedium),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            );
            final actions = Wrap(
              alignment: WrapAlignment.end,
              runAlignment: WrapAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onShowObjects,
                  icon: const Icon(Icons.list_alt_outlined, size: 20),
                  label: const Text('Objects'),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ),
                ),
                IconButton(
                  tooltip: 'Reset workspace view',
                  onPressed: onReset,
                  icon: const Icon(Icons.refresh_rounded),
                ),
                IconButton(
                  tooltip: 'Fit workspace to screen',
                  onPressed: onFit,
                  icon: const Icon(Icons.center_focus_strong_outlined),
                ),
              ],
            );
            if (constraints.maxWidth < 560) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  titleWidget,
                  Align(alignment: Alignment.centerRight, child: actions),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: titleWidget),
                const SizedBox(width: 8),
                actions,
              ],
            );
          },
        ),
      );
}

class _SceneViewport extends StatelessWidget {
  final _ResolvedScene resolved;
  final TransformationController transformationController;
  final Map<String, HotspotVisualState> hotspotStates;
  final Set<String> inspectedObjectIds;
  final Set<String> connectedNodePairs;
  final bool enabled;
  final ValueChanged<String> onObjectSelected;
  final Widget? backgroundRenderer;
  final List<Widget> statusOverlays;

  const _SceneViewport({
    required this.resolved,
    required this.transformationController,
    required this.hotspotStates,
    required this.inspectedObjectIds,
    required this.connectedNodePairs,
    required this.enabled,
    required this.onObjectSelected,
    required this.backgroundRenderer,
    required this.statusOverlays,
  });

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final viewport = Size(
              constraints.maxWidth,
              constraints.maxHeight,
            );
            const logicalWorkspace = SimulationScene.logicalCanvasSize;
            final workspaceScale = math.max(
              .0001,
              math.min(
                viewport.width / logicalWorkspace.width,
                viewport.height / logicalWorkspace.height,
              ),
            );
            final mappedObjects = {
              for (final object in resolved.definition.objects)
                object.id: _mappedRect(
                  object,
                  logicalWorkspace,
                  minimumTapExtent:
                      HotspotWidget.minimumTapExtent / workspaceScale,
                ),
            };
            final connections = _connectionsFor(
              resolved.definition.objects,
              mappedObjects,
              connectedNodePairs,
              hotspotStates,
            );
            final reducedMotion = MediaQuery.disableAnimationsOf(context);
            return InteractiveViewer(
              transformationController: transformationController,
              minScale: 1,
              maxScale: 3,
              boundaryMargin: const EdgeInsets.all(96),
              panEnabled: true,
              scaleEnabled: true,
              child: SizedBox.fromSize(
                size: viewport,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    key: const Key('simulation-logical-workspace'),
                    width: logicalWorkspace.width,
                    height: logicalWorkspace.height,
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        Positioned.fill(
                          child: backgroundRenderer ??
                              Semantics(
                                label: 'Replaceable technical schematic',
                                image: true,
                                child: CustomPaint(
                                  painter: _SchematicScenePainter(
                                    kind: resolved.legacyKind,
                                    objects: resolved.definition.objects,
                                  ),
                                ),
                              ),
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: TweenAnimationBuilder<double>(
                              key: ValueKey(
                                'scene-connection-animation-${connectedNodePairs.toList()..sort()}-$reducedMotion',
                              ),
                              tween: Tween(
                                begin: reducedMotion ? 1 : 0,
                                end: 1,
                              ),
                              duration: reducedMotion
                                  ? Duration.zero
                                  : SceneConnectionPainter.drawDuration,
                              builder: (context, progress, _) => CustomPaint(
                                key: const Key('scene-connections'),
                                painter: SceneConnectionPainter(
                                  connections: connections,
                                  progress: progress,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (statusOverlays.isNotEmpty)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Stack(children: statusOverlays),
                            ),
                          ),
                        for (final object in resolved.definition.objects)
                          Positioned.fromRect(
                            key: ValueKey('simulation-object-${object.id}'),
                            rect: mappedObjects[object.id]!,
                            child: HotspotWidget(
                              object: object,
                              state: hotspotStates[object.id] ??
                                  (inspectedObjectIds.contains(object.id)
                                      ? HotspotVisualState.completed
                                      : object.initialState),
                              enabled: enabled,
                              icon: _iconForObject(resolved, object),
                              onPressed: () => onObjectSelected(object.id),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
}

/// Compatibility adapter retained for callers that used the former hotspot.
class InteractiveHotspot extends StatelessWidget {
  final SimulationSceneObjectSpec object;
  final bool inspected;
  final bool enabled;
  final VoidCallback onPressed;

  const InteractiveHotspot({
    super.key,
    required this.object,
    required this.inspected,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => HotspotWidget(
        key: key ?? ValueKey('simulation-object-${object.id}'),
        object: _legacyObject(object),
        state: inspected
            ? HotspotVisualState.completed
            : HotspotVisualState.neutral,
        enabled: enabled,
        icon: object.icon,
        onPressed: onPressed,
      );
}

class _ResolvedScene {
  final SimulationSceneDefinition definition;
  final String title;
  final String prompt;
  final SimulationSceneKind? legacyKind;
  final Map<String, IconData> legacyIcons;

  const _ResolvedScene({
    required this.definition,
    required this.title,
    required this.prompt,
    required this.legacyKind,
    required this.legacyIcons,
  });

  factory _ResolvedScene.fromWidget(SimulationScene widget) {
    final profile = widget.profile;
    if (profile != null) {
      return _ResolvedScene(
        definition: SimulationSceneDefinition(
          id: profile.missionCode,
          objects: profile.sceneObjects.map(_legacyObject),
          initialStatus: {
            'title': profile.environmentTitle,
            'prompt': profile.scenarioPrompt,
          },
        ),
        title: profile.environmentTitle,
        prompt: profile.scenarioPrompt,
        legacyKind: profile.sceneKind,
        legacyIcons: {
          for (final object in profile.sceneObjects) object.id: object.icon,
        },
      );
    }
    final definition = widget.scene!;
    return _ResolvedScene(
      definition: definition,
      title:
          definition.initialStatus['title'] as String? ?? 'Technical workspace',
      prompt: definition.initialStatus['prompt'] as String? ??
          'Inspect the available schematic objects.',
      legacyKind: null,
      legacyIcons: const {},
    );
  }
}

SceneObjectDefinition _legacyObject(SimulationSceneObjectSpec object) =>
    SceneObjectDefinition(
      id: object.id,
      label: object.label,
      x: (object.position.dx - .04).clamp(0, .92),
      y: (object.position.dy - .06).clamp(0, .88),
      width: .08,
      height: .12,
      hotspotType: 'inspect',
    );

Rect _mappedRect(
  SceneObjectDefinition object,
  Size viewport, {
  double minimumTapExtent = HotspotWidget.minimumTapExtent,
}) {
  final logicalRect = Rect.fromLTWH(
    object.x * viewport.width,
    object.y * viewport.height,
    object.width * viewport.width,
    object.height * viewport.height,
  );
  final width = logicalRect.width.clamp(
    math.min(minimumTapExtent, viewport.width),
    viewport.width,
  ).toDouble();
  final height = logicalRect.height.clamp(
    math.min(minimumTapExtent, viewport.height),
    viewport.height,
  ).toDouble();
  final left = (logicalRect.center.dx - width / 2)
      .clamp(0.0, (viewport.width - width).clamp(0.0, viewport.width));
  final top = (logicalRect.center.dy - height / 2)
      .clamp(0.0, (viewport.height - height).clamp(0.0, viewport.height));
  return Rect.fromLTWH(left, top, width, height);
}

List<SceneConnectionSegment> _connectionsFor(
  List<SceneObjectDefinition> objects,
  Map<String, Rect> mappedObjects,
  Set<String> connectedNodePairs,
  Map<String, HotspotVisualState> hotspotStates,
) {
  final nodes = <String, ({String objectId, Offset center})>{};
  for (final object in objects) {
    for (final node in object.connectionNodeIds) {
      nodes[node] =
          (objectId: object.id, center: mappedObjects[object.id]!.center);
    }
  }
  final segments = <SceneConnectionSegment>[];
  final sortedPairs = connectedNodePairs.toList()..sort();
  for (final pair in sortedPairs) {
    final separator = pair.indexOf('>');
    if (separator <= 0 || separator >= pair.length - 1) continue;
    final source = nodes[pair.substring(0, separator)];
    final destination = nodes[pair.substring(separator + 1)];
    if (source == null || destination == null) continue;
    final state = hotspotStates[source.objectId] == HotspotVisualState.error ||
            hotspotStates[destination.objectId] == HotspotVisualState.error
        ? HotspotVisualState.error
        : HotspotVisualState.completed;
    segments.add(
      SceneConnectionSegment(
        id: pair,
        start: source.center,
        end: destination.center,
        state: state,
      ),
    );
  }
  return List.unmodifiable(segments);
}

IconData _iconForObject(
  _ResolvedScene resolved,
  SceneObjectDefinition object,
) =>
    resolved.legacyIcons[object.id] ??
    (object.hotspotType.toLowerCase().contains('port')
        ? Icons.cable_outlined
        : Icons.memory_outlined);

class _SchematicScenePainter extends CustomPainter {
  final SimulationSceneKind? kind;
  final List<SceneObjectDefinition> objects;

  const _SchematicScenePainter({required this.kind, required this.objects});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF2F6FD),
    );
    final grid = Paint()
      ..color = const Color(0xFFD9E3F4)
      ..strokeWidth = 1;
    for (var index = 0; index <= 12; index++) {
      final x = size.width * index / 12;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var index = 0; index <= 7; index++) {
      final y = size.height * index / 7;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final surface = Paint()..color = const Color(0xFFE1E9F7);
    final equipment = Paint()..color = const Color(0xFF27466F);
    final accent = Paint()
      ..color = AppTheme.primaryBlue.withValues(alpha: .42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    if (kind == SimulationSceneKind.openChassis ||
        kind == SimulationSceneKind.maintenanceBay) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * .17,
            size.height * .18,
            size.width * .66,
            size.height * .68,
          ),
          const Radius.circular(16),
        ),
        surface,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * .28,
            size.height * .28,
            size.width * .38,
            size.height * .42,
          ),
          const Radius.circular(8),
        ),
        equipment,
      );
    } else if (kind == SimulationSceneKind.networkPlan ||
        kind == SimulationSceneKind.networkBench ||
        kind == SimulationSceneKind.cableTester) {
      final points = [
        Offset(size.width * .18, size.height * .62),
        Offset(size.width * .50, size.height * .42),
        Offset(size.width * .82, size.height * .24),
      ];
      canvas.drawPath(
        Path()
          ..moveTo(points[0].dx, points[0].dy)
          ..lineTo(points[1].dx, points[1].dy)
          ..lineTo(points[2].dx, points[2].dy),
        accent,
      );
      for (final point in points) {
        canvas.drawCircle(point, 32, surface);
      }
    } else if (kind == SimulationSceneKind.serverRack ||
        kind == SimulationSceneKind.accessConsole) {
      for (var index = 0; index < 3; index++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              size.width * (.29 + index * .15),
              size.height * .15,
              size.width * .12,
              size.height * .70,
            ),
            const Radius.circular(7),
          ),
          equipment,
        );
      }
    } else if (kind == SimulationSceneKind.firmwareConsole) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * .15,
            size.height * .15,
            size.width * .70,
            size.height * .70,
          ),
          const Radius.circular(14),
        ),
        equipment,
      );
      for (var index = 0; index < 5; index++) {
        canvas.drawRect(
          Rect.fromLTWH(
            size.width * .23,
            size.height * (.28 + index * .09),
            size.width * .42,
            3,
          ),
          Paint()..color = const Color(0xFF8DB0FF),
        );
      }
    } else if (kind == SimulationSceneKind.workbench) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * .08,
            size.height * .55,
            size.width * .84,
            size.height * .25,
          ),
          const Radius.circular(12),
        ),
        surface,
      );
    } else {
      for (final object in objects) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              object.x * size.width,
              object.y * size.height,
              object.width * size.width,
              object.height * size.height,
            ),
            const Radius.circular(8),
          ),
          surface,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SchematicScenePainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.objects != objects;
}
