import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    if (message.contains('Onboarding must be completed')) {
      return const PendingOnboardingPlaceholder();
    }

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

class PendingOnboardingPlaceholder extends StatelessWidget {
  const PendingOnboardingPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.surfaceContainerHighest.withValues(alpha: 0.7),
            scheme.surfaceContainer.withValues(alpha: 0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.assignment_ind_rounded,
                size: 38,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Vui lòng nhập thông tin để hiển thị',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: scheme.onSurface,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hệ thống cần biết các chỉ số cơ thể của bạn (chiều cao, cân nặng...) để có thể tính toán lộ trình và cung cấp dữ liệu cá nhân hóa chính xác nhất.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push('/onboarding'),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('Cập nhật hồ sơ ngay', style: TextStyle(fontWeight: FontWeight.bold)),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ],
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
