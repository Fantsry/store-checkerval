import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class ErrorStateView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String? title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ErrorStateView({
    super.key,
    required this.message,
    this.onRetry,
    this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xxl,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 16,
                  color: AppColors.lossRed,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'ERROR',
                  style: AppTextStyles.label(color: AppColors.lossRed),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title ?? 'Transmission failed',
              style: AppTextStyles.h3(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: AppTextStyles.bodyMedium(
                color: AppColors.textSecondary,
              ),
            ),
            if (onRetry != null || onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  if (onRetry != null)
                    ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('RETRY'),
                    ),
                  if (onAction != null && actionLabel != null)
                    OutlinedButton.icon(
                      onPressed: onAction,
                      icon: const Icon(Icons.login_rounded, size: 16),
                      label: Text(actionLabel!),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
