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
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
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
              child: Icon(
                _stateIcon(state, icon ?? _iconFor(object.hotspotType)),
                color: colors.foreground,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

({Color background, Color foreground}) _colorsFor(
  HotspotVisualState state,
) =>
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
