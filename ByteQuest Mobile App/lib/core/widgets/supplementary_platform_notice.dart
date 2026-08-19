import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SupplementaryPlatformNotice extends StatelessWidget {
  const SupplementaryPlatformNotice({super.key});

  static const message =
      'ByteQuest is a supplementary learning and assessment platform. '
      'It does not issue TESDA certification and does not replace assessment '
      'by an accredited TESDA provider.';

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label: message,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.backgroundPaleBlue,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: AppTheme.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textMedium,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
