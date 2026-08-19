import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Compact page heading used across the learner experience.
class LearnerPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const LearnerPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(20, 18, 20, 14),
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.headlineLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.35,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textMedium,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              trailing!,
            ],
          ],
        ),
      );
}

/// A restrained ByteQuest surface. It uses a border or a soft shadow according
/// to hierarchy, never both at full strength.
class LearnerSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color color;
  final bool elevated;
  final String? semanticLabel;

  const LearnerSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color = AppTheme.cardWhite,
    this.elevated = false,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: color,
      borderRadius: AppTheme.radiusLg,
      border: elevated ? null : Border.all(color: AppTheme.borderLight),
      boxShadow: elevated ? AppTheme.softShadow : const [],
    );

    Widget content = Container(
      decoration: decoration,
      child: Padding(padding: padding, child: child),
    );
    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppTheme.radiusLg,
          child: content,
        ),
      );
    }
    if (semanticLabel != null) {
      content = Semantics(
        container: true,
        button: onTap != null,
        label: semanticLabel,
        child: content,
      );
    }
    return content;
  }
}

class LearnerSectionHeader extends StatelessWidget {
  final String title;
  final String? supportingText;
  final String? actionLabel;
  final VoidCallback? onAction;

  const LearnerSectionHeader({
    super.key,
    required this.title,
    this.supportingText,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                if (supportingText != null) ...[
                  const SizedBox(height: 3),
                  Text(supportingText!, style: AppTheme.bodySmall),
                ],
              ],
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(actionLabel!),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_forward_rounded, size: 17),
                ],
              ),
            ),
        ],
      );
}

/// Truthful loading state with stable dimensions and no artificial delay.
class LearnerLoadingView extends StatefulWidget {
  final String label;

  const LearnerLoadingView({
    super.key,
    this.label = 'Loading your learning record',
  });

  @override
  State<LearnerLoadingView> createState() => _LearnerLoadingViewState();
}

class _LearnerLoadingViewState extends State<LearnerLoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = .35;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        label: widget.label,
        liveRegion: true,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final tint = Color.lerp(
              AppTheme.surfaceMuted,
              AppTheme.softBlueAccent,
              _controller.value,
            )!;
            return ListView(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
              children: [
                _SkeletonBlock(widthFactor: .52, height: 26, color: tint),
                const SizedBox(height: 9),
                _SkeletonBlock(widthFactor: .72, height: 14, color: tint),
                const SizedBox(height: 24),
                _SkeletonBlock(widthFactor: 1, height: 142, color: tint),
                const SizedBox(height: 26),
                _SkeletonBlock(widthFactor: .38, height: 20, color: tint),
                const SizedBox(height: 12),
                _SkeletonBlock(widthFactor: 1, height: 82, color: tint),
                const SizedBox(height: 10),
                _SkeletonBlock(widthFactor: 1, height: 82, color: tint),
              ],
            );
          },
        ),
      );
}

class _SkeletonBlock extends StatelessWidget {
  final double widthFactor;
  final double height;
  final Color color;

  const _SkeletonBlock({
    required this.widthFactor,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: widthFactor,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
}

class LearnerStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const LearnerStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Semantics(
            container: true,
            label: '$title. $message',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundPaleBlue,
                    borderRadius: AppTheme.radiusLg,
                  ),
                  child: Icon(icon, color: AppTheme.primaryBlue, size: 29),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  style: AppTheme.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Text(
                    message,
                    style: AppTheme.bodyMedium.copyWith(height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (actionLabel != null) ...[
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: onAction,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
}

class LearnerProgressBar extends StatelessWidget {
  final double value;
  final String semanticLabel;
  final Color color;

  const LearnerProgressBar({
    super.key,
    required this.value,
    required this.semanticLabel,
    this.color = AppTheme.primaryBlue,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = value.clamp(0.0, 1.0);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: semanticLabel,
      value: '${(normalized * 100).round()} percent',
      child: TweenAnimationBuilder<double>(
        duration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        tween: Tween(begin: 0, end: normalized),
        builder: (context, progress, _) => LinearProgressIndicator(
          value: progress,
          color: color,
          backgroundColor: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          minHeight: 7,
        ),
      ),
    );
  }
}
