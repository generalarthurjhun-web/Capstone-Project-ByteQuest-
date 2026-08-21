import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Keeps immersive display state local to the current simulation route.
/// Disposing the route always restores normal edge-to-edge system UI.
class SimulationFullscreenButton extends StatefulWidget {
  const SimulationFullscreenButton({super.key});

  @override
  State<SimulationFullscreenButton> createState() =>
      _SimulationFullscreenButtonState();
}

class _SimulationFullscreenButtonState
    extends State<SimulationFullscreenButton> {
  bool _isFullscreen = false;

  Future<void> _toggleFullscreen() async {
    final nextValue = !_isFullscreen;
    setState(() => _isFullscreen = nextValue);
    await SystemChrome.setEnabledSystemUIMode(
      nextValue ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
  }

  @override
  void dispose() {
    if (_isFullscreen) {
      unawaited(
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge),
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = _isFullscreen
        ? 'Exit full-screen simulation'
        : 'Enter full-screen simulation';
    return Semantics(
      button: true,
      toggled: _isFullscreen,
      label: label,
      child: Tooltip(
        message: label,
        child: IconButton.filledTonal(
          key: const ValueKey('simulation-fullscreen-button'),
          onPressed: _toggleFullscreen,
          icon: Icon(
            _isFullscreen
                ? Icons.fullscreen_exit_rounded
                : Icons.fullscreen_rounded,
          ),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        ),
      ),
    );
  }
}
