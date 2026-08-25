import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/mission_content_data.dart';
import '../../../models/mission_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/progress_resume_service.dart';

String practiceMissionIdentifier(Mission mission) {
  final idMatch = RegExp(r'^coc(\d+)_m(\d+)$', caseSensitive: false)
      .firstMatch(mission.id.trim());
  if (idMatch != null) {
    return 'COC${idMatch.group(1)} M${idMatch.group(2)}';
  }
  final codeMatch = RegExp(
    r'^coc\s*(\d+)[\s_-]*m\s*(\d+)$',
    caseSensitive: false,
  ).firstMatch(mission.missionCode.trim());
  if (codeMatch != null) {
    return 'COC${codeMatch.group(1)} M${codeMatch.group(2)}';
  }
  return '${mission.cocId.toUpperCase()} M${mission.missionNumber}';
}

/// Shared compact title/identity row for practice and activity screens.
class PracticeMissionHeader extends StatelessWidget {
  const PracticeMissionHeader({
    super.key,
    required this.mission,
    required this.onBackPressed,
    this.subtitle,
    this.trailing,
  });

  final Mission mission;
  final VoidCallback onBackPressed;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final identity = practiceMissionIdentifier(mission);
    final secondary = subtitle == null || subtitle!.trim().isEmpty
        ? identity
        : '$identity · ${subtitle!.trim()}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(
        color: AppTheme.cardWhite,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton.filledTonal(
              tooltip: 'Leave mission',
              onPressed: onBackPressed,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mission.title,
                    style: AppTheme.headlineSmall.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    secondary,
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.textMedium,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// App-bar form of the shared practice mission identity treatment.
class PracticeMissionAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const PracticeMissionAppBar({
    super.key,
    required this.mission,
    required this.onBackPressed,
    this.trailing,
  });

  final Mission mission;
  final VoidCallback onBackPressed;
  final Widget? trailing;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) => AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Leave mission',
          onPressed: onBackPressed,
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textDark),
        ),
        titleSpacing: 4,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mission.title,
              style: AppTheme.titleMedium.copyWith(
                color: AppTheme.textDark,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              practiceMissionIdentifier(mission),
              style: AppTheme.caption.copyWith(
                color: AppTheme.textMedium,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: trailing == null
            ? null
            : [
                Center(child: trailing!),
                const SizedBox(width: 16),
              ],
      );
}

typedef PracticeExitBuilder = Widget Function(
  BuildContext context,
  VoidCallback requestExit,
);

/// Gives visible and system back navigation one progress-aware exit contract.
class PracticeMissionExitGuard extends StatelessWidget {
  const PracticeMissionExitGuard({
    super.key,
    required this.mission,
    required this.hasProgress,
    required this.builder,
    this.onDiscard,
  });

  final Mission mission;
  final bool Function() hasProgress;
  final PracticeExitBuilder builder;
  final Future<void> Function()? onDiscard;

  Future<void> _discard() async {
    if (onDiscard != null) return onDiscard!();
    final userId = AuthService().currentUserId;
    if (userId == null) return;
    final cleared = await ProgressResumeService.clearState(
      userId: userId,
      missionId: mission.id,
    );
    if (!cleared) {
      throw StateError('Legacy mission progress could not be cleared.');
    }
  }

  Future<void> _requestExit(BuildContext context) async {
    if (!hasProgress()) {
      if (context.mounted) Navigator.of(context).pop();
      return;
    }

    final exit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(MissionContentData.exitMissionTitle),
        content: const Text(MissionContentData.exitMissionMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(MissionContentData.cancelExitLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text(MissionContentData.confirmExitLabel),
          ),
        ],
      ),
    );
    if (exit != true || !context.mounted) return;

    try {
      await _discard();
      if (context.mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(MissionContentData.discardProgressFailedMessage),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) unawaited(_requestExit(context));
        },
        child: Builder(
          builder: (guardContext) => builder(
            guardContext,
            () => unawaited(_requestExit(guardContext)),
          ),
        ),
      );
}
