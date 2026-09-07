import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../runtime/mission_runtime_models.dart';

/// Presentation-only control for a scene object.
///
/// The scene owns coordinate mapping and runtime transitions. This widget only
/// exposes a dependable touch target and renders the supplied visual state.
class HotspotWidget extends StatelessWidget {
  final SceneObjectDefinition object;
  final HotspotVisualState state;
  final bool enabled;
  final VoidCallback onPressed;
  final IconData? icon;

  const HotspotWidget({
    super.key,
    required this.object,
    required this.state,
    required this.enabled,
    required this.onPressed,
    this.icon,
  });

  static const double minimumTapExtent = 48;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsFor(state);
    final imageAsset = object.metadata['imageAsset'];
    final imagePath =
        imageAsset is String && imageAsset.isNotEmpty ? imageAsset : null;
    final transitionDuration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppTheme.simulationTransitionDuration;
    return Semantics(
      key: key ?? ValueKey('hotspot-${object.id}'),
      button: true,
      enabled: enabled,
      selected: state == HotspotVisualState.selected ||
          state == HotspotVisualState.completed,
      label: '${object.label}, ${state.name}',
      excludeSemantics: true,
      child: Tooltip(
        message: '${object.label}, ${state.name}',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: transitionDuration,
              constraints: const BoxConstraints(
                minWidth: minimumTapExtent,
                minHeight: minimumTapExtent,
              ),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.foreground, width: 2),
              ),
              alignment: Alignment.center,
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  if (imagePath != null)
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Image.asset(
                          imagePath,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              ColoredBox(
                            color: AppTheme.errorRed,
                            child: Tooltip(
                              message: 'Image failed: $imagePath',
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  AnimatedScale(
                    duration: transitionDuration,
                    curve: Curves.easeOutCubic,
                    scale: state == HotspotVisualState.neutral ? .92 : 1,
                    child: AnimatedSwitcher(
                      duration: transitionDuration,
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: Icon(
                        _stateIcon(state, icon ?? _iconFor(object.hotspotType)),
                        key: ValueKey(state),
                        color: colors.foreground,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

({Color background, Color foreground}) _colorsFor(HotspotVisualState state) =>
    switch (state) {
      HotspotVisualState.neutral => (
          background: Colors.white,
          foreground: AppTheme.deepBlue,
        ),
      HotspotVisualState.selected => (
          background: AppTheme.softBlueAccent,
          foreground: AppTheme.primaryBlue,
        ),
      HotspotVisualState.completed => (
          background: AppTheme.primaryBlue,
          foreground: Colors.white,
        ),
      HotspotVisualState.error => (
          background: const Color(0xFFFFECEE),
          foreground: AppTheme.errorRed,
        ),
    };

IconData _stateIcon(HotspotVisualState state, IconData neutralIcon) =>
    switch (state) {
      HotspotVisualState.neutral => neutralIcon,
      HotspotVisualState.selected => Icons.radio_button_checked_rounded,
      HotspotVisualState.completed => Icons.check_rounded,
      HotspotVisualState.error => Icons.priority_high_rounded,
    };

IconData _iconFor(String type) {
  final normalized = type.toLowerCase();
  if (normalized.contains('port') || normalized.contains('connect')) {
    return Icons.cable_outlined;
  }
  if (normalized.contains('tool')) return Icons.handyman_outlined;
  if (normalized.contains('server')) return Icons.dns_outlined;
  if (normalized.contains('device')) return Icons.memory_outlined;
  return Icons.add_rounded;
}
