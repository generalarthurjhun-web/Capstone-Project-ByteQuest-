import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../runtime/mission_runtime_models.dart';

@immutable
class SceneConnectionSegment {
  final String id;
  final Offset start;
  final Offset end;
  final HotspotVisualState state;

  const SceneConnectionSegment({
    required this.id,
    required this.start,
    required this.end,
    this.state = HotspotVisualState.completed,
  });
}

/// Draws immutable runtime connection state up to [progress].
class SceneConnectionPainter extends CustomPainter {
  static const Duration drawDuration = AppTheme.simulationTransitionDuration;

  final List<SceneConnectionSegment> connections;
  final double progress;

  SceneConnectionPainter({
    required Iterable<SceneConnectionSegment> connections,
    required this.progress,
  }) : connections = List.unmodifiable(connections);

  @override
  void paint(Canvas canvas, Size size) {
    final clampedProgress = progress.clamp(0.0, 1.0);
    for (final connection in connections) {
      final path = Path()
        ..moveTo(connection.start.dx, connection.start.dy)
        ..cubicTo(
          connection.start.dx + (connection.end.dx - connection.start.dx) / 3,
          connection.start.dy,
          connection.end.dx - (connection.end.dx - connection.start.dx) / 3,
          connection.end.dy,
          connection.end.dx,
          connection.end.dy,
        );
      final metric = path.computeMetrics().firstOrNull;
      if (metric == null) continue;
      final visible = metric.extractPath(0, metric.length * clampedProgress);
      canvas.drawPath(
        visible,
        Paint()
          ..color = _connectionColor(connection.state)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
      if (clampedProgress == 1) {
        canvas.drawCircle(
          connection.end,
          5,
          Paint()..color = _connectionColor(connection.state),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant SceneConnectionPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      !_sameConnections(oldDelegate.connections, connections);
}

Color _connectionColor(HotspotVisualState state) => switch (state) {
      HotspotVisualState.error => AppTheme.errorRed,
      HotspotVisualState.selected => AppTheme.primaryBlue,
      HotspotVisualState.completed => AppTheme.deepBlue,
      HotspotVisualState.neutral => AppTheme.borderMedium,
    };

bool _sameConnections(
  List<SceneConnectionSegment> left,
  List<SceneConnectionSegment> right,
) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    final a = left[index];
    final b = right[index];
    if (a.id != b.id ||
        a.start != b.start ||
        a.end != b.end ||
        a.state != b.state) {
      return false;
    }
  }
  return true;
}

extension on Iterable<ui.PathMetric> {
  ui.PathMetric? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
