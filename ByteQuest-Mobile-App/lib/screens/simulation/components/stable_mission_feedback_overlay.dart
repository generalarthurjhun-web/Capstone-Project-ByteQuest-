import 'package:flutter/material.dart';

/// Displays feedback above a workspace without changing the workspace bounds.
class StableMissionFeedbackOverlay extends StatelessWidget {
  const StableMissionFeedbackOverlay({
    super.key,
    required this.child,
    this.feedback,
    this.top = 8,
    this.bottom,
    this.horizontalInset = 8,
  }) : assert(bottom == null || top == null);

  final Widget child;
  final Widget? feedback;
  final double? top;
  final double? bottom;
  final double horizontalInset;

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          child,
          if (feedback != null)
            Positioned(
              top: top,
              bottom: bottom,
              left: horizontalInset,
              right: horizontalInset,
              child: Semantics(liveRegion: true, child: feedback!),
            ),
        ],
      );
}
