import 'package:flutter/material.dart';

import '../../presentation/theme/app_colors.dart';
import '../../presentation/theme/app_typography.dart';
import 'app_feedback.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: AppColors.primaryOf(context),
            strokeWidth: 2.4,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmallFor(context),
            ),
          ],
        ],
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AppFeedbackPanel(
          title: 'Không tải được dữ liệu',
          message: message,
          type: AppFeedbackType.error,
          actionLabel: onRetry == null ? null : 'Thử lại',
          onAction: onRetry,
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.message,
    this.title,
    this.icon = Icons.inbox_outlined,
  });

  final String message;
  // Optional context-specific title; falls back to the generic 'Chưa có dữ liệu'.
  final String? title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AppFeedbackPanel(
          title: title ?? 'Chưa có dữ liệu',
          message: message,
          type: AppFeedbackType.info,
          compact: true,
          icon: icon,
        ),
      ),
    );
  }
}
