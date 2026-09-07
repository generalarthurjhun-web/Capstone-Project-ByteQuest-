import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/mission_content_data.dart';

class EvidenceReviewPanel extends StatelessWidget {
  const EvidenceReviewPanel({
    super.key,
    required this.completedPhaseTitles,
    required this.authoritativeEvidenceCount,
    required this.pendingEvidenceCount,
    required this.failedEvidenceCount,
    required this.canSubmit,
    required this.onReturn,
    required this.onConfirm,
    this.onRetryPending,
    this.retryingPending = false,
    this.returnLabel = 'Return',
    this.confirmLabel = 'Confirm submission',
  });

  final List<String> completedPhaseTitles;
  final int authoritativeEvidenceCount;
  final int pendingEvidenceCount;
  final int failedEvidenceCount;
  final bool canSubmit;
  final VoidCallback onReturn;
  final VoidCallback onConfirm;
  final VoidCallback? onRetryPending;
  final bool retryingPending;
  final String returnLabel;
  final String confirmLabel;

  @override
  Widget build(BuildContext context) {
    final phases = completedPhaseTitles.length;
    final synchronized = pendingEvidenceCount == 0 && failedEvidenceCount == 0;
    return Semantics(
      container: true,
      label: 'Evidence review',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Evidence review', style: AppTheme.titleMedium),
          const SizedBox(height: 10),
          Text('$phases completed ${phases == 1 ? 'phase' : 'phases'}'),
          if (completedPhaseTitles.isNotEmpty) ...[
            const SizedBox(height: 6),
            for (final title in completedPhaseTitles)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $title', style: AppTheme.bodySmall),
              ),
          ],
          const SizedBox(height: 8),
          Text(
            '$authoritativeEvidenceCount synchronized evidence '
            '${authoritativeEvidenceCount == 1 ? 'event' : 'events'}',
          ),
          if (!synchronized) ...[
            const SizedBox(height: 8),
            Semantics(
              liveRegion: true,
              child: Text(
                '$pendingEvidenceCount pending · '
                '$failedEvidenceCount needs retry',
                style:
                    AppTheme.bodySmall.copyWith(color: AppTheme.warningYellow),
              ),
            ),
          ],
          if (pendingEvidenceCount > 0 && onRetryPending != null) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              key: const ValueKey('retry-pending-evidence'),
              onPressed: retryingPending ? null : onRetryPending,
              icon: retryingPending
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync_rounded),
              label: Text(
                retryingPending
                    ? MissionContentData.retryingPendingEvidenceLabel
                    : MissionContentData.retryPendingEvidenceLabel,
              ),
            ),
          ],
          const SizedBox(height: 14),
          FilledButton(
            onPressed: canSubmit && synchronized ? onConfirm : null,
            child: Text(confirmLabel),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: onReturn,
            child: Text(returnLabel),
          ),
        ],
      ),
    );
  }
}
