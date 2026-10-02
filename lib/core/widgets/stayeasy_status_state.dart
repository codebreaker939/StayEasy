import 'package:flutter/material.dart';

import '../theme/stayeasy_colors.dart';
import '../theme/stayeasy_spacing.dart';
import '../theme/stayeasy_typography.dart';

class StayEasyStatusState extends StatelessWidget {
  const StayEasyStatusState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.actionLabel,
    this.onAction,
    this.isError = false,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? StayEasyColors.error : StayEasyColors.primary;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(StayEasySpacing.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: StayEasySpacing.space12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: StayEasyTypography.titleLarge,
              ),
              const SizedBox(height: StayEasySpacing.space8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: StayEasyTypography.bodyMedium.copyWith(
                  color: StayEasyColors.textSecondary,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: StayEasySpacing.space16),
                FilledButton.tonal(
                  onPressed: onAction,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(44, 44),
                  ),
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
