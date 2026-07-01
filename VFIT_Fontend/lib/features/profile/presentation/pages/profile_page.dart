import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/app_error_mapper.dart';
import '../../../../core/error/crash_reporter.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/utils/enum_parsers.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_radius.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../payment/data/models/payment_models.dart';
import '../../../payment/data/repositories/payment_repository.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/profile_repository.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    final bodyMetrics = ref.watch(bodyMetricsProvider);
    final themeMode = ref.watch(themeControllerProvider);

    if (user == null) {
      return ListView(
        padding: AppResponsive.pagePadding(context),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.workspace_premium_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 42,
                ),
                const SizedBox(height: 14),
                Text(
                  'Tham gia V-FIT VIP',
                  style: AppTypography.headerMediumFor(context),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sử dụng ứng dụng miễn phí như khách. Tạo tài khoản khi bạn cần lưu tiến trình, sử dụng gói tập VIP và công cụ hồ sơ.',
                  style: AppTypography.bodyFor(
                    context,
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
                const SizedBox(height: 18),
                AppButton.add(
                  label: 'Đăng ký bằng Email',
                  fullWidth: true,
                  onPressed: () => context.go('/register'),
                ),
                const SizedBox(height: 10),
                AppButton.ghost(
                  label: 'Tôi đã có tài khoản',
                  fullWidth: true,
                  onPressed: () => context.go('/login'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const VipPromotionCard(),
          const SizedBox(height: 16),
          _ThemeSelector(
            value: themeMode,
            onChanged: (mode) =>
                ref.read(themeControllerProvider.notifier).setThemeMode(mode),
          ),
        ],
      );
    }

    return ListView(
      padding: AppResponsive.pagePadding(context),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 34,
              backgroundImage:
                  MediaUrlResolver.resolveNullable(user.avatarUrl) == null
                      ? null
                      : NetworkImage(
                          MediaUrlResolver.resolveNullable(user.avatarUrl)!,
                        ),
              child: user.avatarUrl == null
                  ? Text(
                      user.fullName.isEmpty
                          ? 'V'
                          : user.fullName[0].toUpperCase(),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    style: AppTypography.headerMediumFor(context),
                  ),
                  Text(
                    user.email,
                    style: AppTypography.bodySmallFor(context),
                  ),
                  const SizedBox(height: 6),
                  // Role pill — consistent with _StatusPill style used throughout
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.x3,
                      vertical: AppSpacing.x1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOf(context).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: AppColors.primaryOf(context).withValues(alpha: 0.24),
                      ),
                    ),
                    child: Text(
                      'Customer',
                      style: AppTypography.label(
                        color: AppColors.primaryOf(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        AppCard(
          child: Row(
            children: [
              Expanded(child: _Value(label: 'Cấp độ', value: '${user.level}')),
              Expanded(child: _Value(label: 'XP', value: '${user.xp}')),
              Expanded(
                child: _Value(
                  label: 'Trạng thái',
                  value: subscriptionLabel(
                    user.subscriptionStatus,
                    user.subscriptionPlanCode,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (user.isVipActive) VipActiveStatusCard(user: user),
        if (!user.isVipActive || user.canRenewVip) ...[
          const SizedBox(height: 16),
          VipPromotionCard(user: user),
        ],
        const SizedBox(height: 16),
        if (user.onboardingStatus == OnboardingStatus.pending)
          const PendingOnboardingPlaceholder()
        else
          bodyMetrics.when(
            data: (metric) => AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chỉ số cơ thể',
                    style: AppTypography.labelFor(context),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      _Value(
                        label: 'Chiều cao',
                        value: '${metric.heightCm ?? '-'} cm',
                      ),
                      _Value(
                        label: 'Cân nặng',
                        value: '${metric.weightKg ?? '-'} kg',
                      ),
                      _Value(
                        label: 'Chỉ số BMI',
                        value: metric.bmi?.toStringAsFixed(1) ?? '-',
                      ),
                      _Value(
                        label: 'Tỷ lệ mỡ',
                        value: '${metric.bodyFatPercent ?? '-'}%',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            loading: () => const AppCard(child: LinearProgressIndicator()),
            error: (error, _) => ErrorView(
              message: error.toString(),
              onRetry: () => ref.invalidate(bodyMetricsProvider),
            ),
          ),
        const SizedBox(height: 16),
        _ProfileAction(
          icon: Icons.edit,
          title: 'Chỉnh sửa hồ sơ',
          onTap: () => context.push('/profile/edit'),
        ),
        _ProfileAction(
          icon: Icons.lock_outline,
          title: 'Thay đổi mật khẩu',
          onTap: () => context.push('/profile/change-password'),
        ),
        _ThemeSelector(
          value: themeMode,
          onChanged: (mode) =>
              ref.read(themeControllerProvider.notifier).setThemeMode(mode),
        ),
        if (user.role == RoleName.admin)
          _ProfileAction(
            icon: Icons.admin_panel_settings,
            title: 'Bảng điều khiển Admin',
            onTap: () => context.push('/admin'),
          ),
        _ProfileAction(
          icon: Icons.logout,
          title: 'Đăng xuất',
          onTap: () => ref.read(authControllerProvider.notifier).logout(),
        ),
        if (!user.isAdmin)
          _ProfileAction(
            icon: Icons.delete_forever_outlined,
            title: 'Xóa tài khoản',
            color: Theme.of(context).colorScheme.error,
            onTap: () => _deleteAccount(context, ref),
          ),
      ],
    );
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tài khoản?'),
        content: const Text(
          'Tài khoản của bạn sẽ bị vô hiệu hóa ngay lập tức và sẽ bị xóa vĩnh viễn sau 30 ngày. Trong thời gian này, bạn có thể liên hệ Support để khôi phục.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Xóa tài khoản'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(profileRepositoryProvider).deleteAccount();
        await ref.read(authControllerProvider.notifier).logout();
        if (context.mounted) {
          AppFeedback.success('Tài khoản đã được vô hiệu hóa thành công.');
        }
      } catch (error) {
        if (context.mounted) {
          AppFeedback.error(error.toString(), title: 'Xóa tài khoản thất bại');
        }
      }
    }
  }
}

class VipPromotionCard extends ConsumerStatefulWidget {
  const VipPromotionCard({super.key, this.user});

  final UserModel? user;

  @override
  ConsumerState<VipPromotionCard> createState() => _VipPromotionCardState();
}

class _VipPromotionCardState extends ConsumerState<VipPromotionCard> {
  bool _creating = false;

  @override
  Widget build(BuildContext context) {
    final isRenewal =
        widget.user?.isVipActive == true && widget.user?.canRenewVip == true;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.24),
                  ),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: Text(
                  'V-FIT Premium',
                  style: AppTypography.headerMediumFor(context).copyWith(
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x3),
          const VipPlanSelector(),
          const SizedBox(height: AppSpacing.x4),
          const VipBenefitsTable(),
          const SizedBox(height: AppSpacing.x4),
          AppButton.add(
            label: isRenewal ? 'Gia hạn Premium' : 'Premium',
            fullWidth: true,
            loading: _creating,
            onPressed: _creating ? null : _startVipPayment,
          ),
        ],
      ),
    );
  }

  Future<void> _startVipPayment() async {
    final user = ref.read(authControllerProvider).user;
    if (user == null) {
      AppFeedback.info('Vui lòng đăng nhập để nạp VIP.');
      if (mounted) {
        context.go('/login');
      }
      return;
    }
    if (user.isVipActive && !user.canRenewVip) {
      AppFeedback.info(
        'VIP đang hoạt động. Bạn có thể gia hạn khi còn dưới 3 ngày.',
      );
      return;
    }

    final selection = await showDialog<_PremiumPlanSelection>(
      context: context,
      builder: (context) => const _PremiumPlanDialog(),
    );
    if (selection == null || !mounted) {
      return;
    }

    setState(() => _creating = true);
    try {
      final payment =
          await ref.read(paymentRepositoryProvider).createPremiumPayment(
                plan: selection.plan,
                voucherCode: selection.voucherCode,
              );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _PremiumPaymentDialog(payment: payment),
      );
    } catch (error, stackTrace) {
      await CrashReporter.record(error, stackTrace);
      if (mounted) {
        AppFeedback.error(AppErrorMapper.friendlyMessage(error));
      }
    } finally {
      if (mounted) {
        setState(() => _creating = false);
      }
    }
  }
}

class VipActiveStatusCard extends StatelessWidget {
  const VipActiveStatusCard({
    super.key,
    required this.user,
  });

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startedAt = user.premiumStartedAt;
    final expiredAt = user.premiumExpiredAt;
    final totalDays = expiredAt == null
        ? 0
        : _positiveDaysBetween(startedAt ?? now, expiredAt);
    final elapsedDays =
        startedAt == null ? 0 : _positiveDaysBetween(startedAt, now);
    final localRemainingDays = expiredAt == null
        ? user.premiumRemainingDays
        : expiredAt.difference(now).inDays + 1;
    final remainingDays = math.max(
      1,
      user.premiumRemainingDays > 0
          ? user.premiumRemainingDays
          : localRemainingDays,
    );
    final progress = totalDays == 0
        ? 1.0
        : (elapsedDays / totalDays).clamp(0.0, 1.0).toDouble();
    final isExpiringSoon = user.canRenewVip;
    final accent = isExpiringSoon ? AppColors.warning : AppColors.success;
    final plan =
        _formatPremiumPlan(user.premiumPlan ?? user.subscriptionPlanCode);
    final isMonthlyPlan =
        _isMonthlyPlan(user.premiumPlan ?? user.subscriptionPlanCode);
    final dateFormat = DateFormat('dd/MM/yyyy');
    final expiredAtText = expiredAt == null
        ? 'Ngày hết hạn đang được đồng bộ'
        : 'Hết hạn: ${dateFormat.format(expiredAt.toLocal())}';
    final headline =
        isMonthlyPlan ? 'Còn $remainingDays ngày VIP' : expiredAtText;
    final supportingText =
        isMonthlyPlan ? expiredAtText : 'Gói VIP năm đang hoạt động';

    return Container(
      padding: AppResponsive.cardPadding(context),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF18181B), // Zinc 900
            Color(0xFF09090B), // Zinc 950
            Color(0xFF0F766E), // Deep modern teal accent
          ],
          stops: [0.0, 0.7, 1.0],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  border: Border.all(color: accent.withValues(alpha: 0.32)),
                ),
                child: Icon(
                  isExpiringSoon
                      ? Icons.warning_amber_rounded
                      : Icons.workspace_premium_rounded,
                  color: accent,
                ),
              ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'V-FIT Premium',
                      style: AppTypography.headerMedium(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gói hiện tại: $plan',
                      style: AppTypography.bodySmall(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              _VipStatusBadge(label: '✓ VIP đang hoạt động', color: accent),
            ],
          ),
          const SizedBox(height: AppSpacing.x4),
          Text(
            headline,
            style: AppTypography.metric(color: Colors.white),
          ),
          if (!isMonthlyPlan) ...[
            const SizedBox(height: AppSpacing.x2),
            Text(
              supportingText,
              style: AppTypography.body(color: Colors.white.withValues(alpha: 0.9)),
            ),
          ],
          const SizedBox(height: AppSpacing.x4),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              minHeight: 9,
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: AppSpacing.x3),
          Wrap(
            spacing: AppSpacing.x2,
            runSpacing: AppSpacing.x2,
            children: [
              _VipDateChip(
                icon: Icons.event_available_rounded,
                label: 'Kích hoạt',
                value: startedAt == null
                    ? '-'
                    : dateFormat.format(startedAt.toLocal()),
              ),
              if (expiredAt != null)
                _VipDateChip(
                  icon: Icons.event_busy_rounded,
                  label: 'Hết hạn',
                  value: dateFormat.format(expiredAt.toLocal()),
                ),
            ],
          ),
          if (isExpiringSoon) ...[
            const SizedBox(height: AppSpacing.x3),
            Container(
              padding: const EdgeInsets.all(AppSpacing.x3),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.small),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.42),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.x2),
                  Expanded(
                    child: Text(
                      'VIP sắp hết hạn',
                      style: AppTypography.body(color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static int _positiveDaysBetween(DateTime start, DateTime end) {
    return math.max(0, end.difference(start).inDays);
  }

  static String _formatPremiumPlan(String? value) {
    return switch (value) {
      'VIP_MONTHLY' || 'MONTHLY' => 'MONTHLY',
      'VIP_YEARLY' || 'YEARLY' => 'YEARLY',
      'VIP_TRIAL' => 'Vip Trial',
      final plan? when plan.isNotEmpty => plan,
      _ => 'VIP',
    };
  }

  static bool _isMonthlyPlan(String? value) {
    return switch (value) {
      'VIP_MONTHLY' || 'MONTHLY' => true,
      _ => false,
    };
  }
}

class _VipStatusBadge extends StatelessWidget {
  const _VipStatusBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.36)),
      ),
      child: Text(label, style: AppTypography.label(color: color)),
    );
  }
}

class _VipDateChip extends StatelessWidget {
  const _VipDateChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x3,
        vertical: AppSpacing.x2,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.x2),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.bodySmall(color: AppColors.textSecondary),
              ),
              Text(
                value,
                style: AppTypography.body(color: AppColors.textPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PremiumPlanSelection {
  const _PremiumPlanSelection({
    required this.plan,
    this.voucherCode,
  });

  final PremiumPlan plan;
  final String? voucherCode;
}

class _PremiumPlanDialog extends StatefulWidget {
  const _PremiumPlanDialog();

  @override
  State<_PremiumPlanDialog> createState() => _PremiumPlanDialogState();
}

class _PremiumPlanDialogState extends State<_PremiumPlanDialog> {
  PremiumPlan _selected = PremiumPlan.monthly;
  final TextEditingController _voucherController = TextEditingController();

  @override
  void dispose() {
    _voucherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      title: const Text('Chọn gói Premium'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _planTile(PremiumPlan.monthly, 'VIP 1 tháng', '150K'),
            _planTile(PremiumPlan.yearly, 'VIP 1 năm', '1M'),
            const SizedBox(height: AppSpacing.x3),
            TextField(
              controller: _voucherController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Mã voucher',
                prefixIcon: Icon(Icons.confirmation_number_outlined),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton.icon(
          onPressed: _confirm,
          icon: const Icon(Icons.qr_code_rounded),
          label: const Text('Tạo QR'),
        ),
      ],
    );
  }

  Widget _planTile(PremiumPlan plan, String title, String price) {
    final selected = _selected == plan;
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.input),
      onTap: () => setState(() => _selected = plan),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.x2),
        padding: const EdgeInsets.all(AppSpacing.x3),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.success.withValues(alpha: 0.1)
              : scheme.surfaceContainerHighest.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(AppRadius.input),
          border: Border.all(
            color: selected
                ? AppColors.success.withValues(alpha: 0.7)
                : scheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? AppColors.success : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    price,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirm() {
    final voucher = _voucherController.text.trim().toUpperCase();
    Navigator.of(context).pop(
      _PremiumPlanSelection(
        plan: _selected,
        voucherCode: voucher.isEmpty ? null : voucher,
      ),
    );
  }
}

class _PremiumPaymentDialog extends ConsumerStatefulWidget {
  const _PremiumPaymentDialog({required this.payment});

  final PremiumPayment payment;

  @override
  ConsumerState<_PremiumPaymentDialog> createState() =>
      _PremiumPaymentDialogState();
}

class _PremiumPaymentDialogState extends ConsumerState<_PremiumPaymentDialog> {
  Timer? _timer;
  StreamSubscription<PremiumPaymentRealtimeEvent>? _paymentEvents;
  PremiumPaymentStatus? _status = PremiumPaymentStatus.pending;
  bool _checking = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _listenPaymentRealtime();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _pollStatus());
    unawaited(_pollStatus());
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_paymentEvents?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final payment = widget.payment;
    final media = MediaQuery.of(context);
    final size = media.size;
    final compact = size.width < 390 || size.height < 700;
    final horizontalInset = compact ? 8.0 : 24.0;
    final verticalInset = compact ? 8.0 : 24.0;
    final maxWidth = math.min(size.width - horizontalInset * 2, 420.0);
    final maxHeight = size.height -
        media.padding.vertical -
        media.viewInsets.vertical -
        verticalInset * 2;
    final qrSize = math
        .min(
          maxWidth - 48,
          math.max(140.0, maxHeight * (compact ? 0.34 : 0.38)),
        )
        .clamp(140.0, compact ? 200.0 : 260.0);
    final amountText =
        '${NumberFormat.decimalPattern('vi_VN').format(payment.finalAmount)} VND';
    final planLabel = switch (payment.plan) {
      PremiumPlan.yearly => 'VIP năm',
      PremiumPlan.monthly => 'VIP tháng',
      _ => 'V-FIT VIP',
    };
    final paid = _status == PremiumPaymentStatus.paid;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: horizontalInset,
        vertical: verticalInset,
      ),
      child: SafeArea(
        minimum: EdgeInsets.zero,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: maxHeight,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF07110F),
                  Color(0xFF11141E),
                  Color(0xFF071A14),
                ],
              ),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.34),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.14),
                  blurRadius: 28,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 14 : 20,
                compact ? 14 : 18,
                compact ? 14 : 20,
                compact ? 10 : 14,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.28),
                          ),
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.x3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thanh toán Premium',
                              style: AppTypography.headerMedium(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              planLabel,
                              style: AppTypography.bodySmall(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _VipStatusBadge(
                        label: paid ? 'Đã mở' : 'Chờ thanh toán',
                        color: paid ? AppColors.success : AppColors.warning,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Text(
                            amountText,
                            textAlign: TextAlign.center,
                            style: AppTypography.metric(
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.x3),
                          Center(
                            child: Container(
                              width: qrSize,
                              height: qrSize,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 18,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(
                                  payment.vietQrUrl,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.none,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(Icons.broken_image_outlined),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.x4),
                          _paymentLine('Nội dung', payment.paymentCode),
                          _paymentLine('Ngân hàng', payment.bankCode),
                          _paymentLine('Số tài khoản', payment.accountNumber),
                          if (payment.expiredAt != null)
                            _paymentLine(
                              'Hạn thanh toán',
                              DateFormat('HH:mm dd/MM/yyyy').format(
                                payment.expiredAt!.toLocal(),
                              ),
                            ),
                          const SizedBox(height: AppSpacing.x3),
                          AppFeedbackPanel(
                            compact: true,
                            type: paid
                                ? AppFeedbackType.success
                                : AppFeedbackType.info,
                            title: paid ? 'VIP đã kích hoạt' : 'Đang xác nhận',
                            message: paid
                                ? 'Tài khoản đã được nâng cấp.'
                                : 'Giữ nguyên nội dung chuyển khoản để hệ thống tự đối soát.',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _checking ? null : _pollStatus,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                          ),
                          child: const Text('Kiểm tra'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.x2),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.black,
                          ),
                          child: Text(paid ? 'Xong' : 'Đóng'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _paymentLine(String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.x2),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x3,
        vertical: AppSpacing.x2,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySmall(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: AppSpacing.x2),
          Flexible(
            flex: 2,
            child: SelectableText(
              value,
              textAlign: TextAlign.right,
              style: AppTypography.label(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  void _listenPaymentRealtime() {
    _paymentEvents =
        ref.read(paymentRepositoryProvider).watchPremiumPayments().listen(
      (event) {
        if (!mounted ||
            event.paymentId != widget.payment.paymentId ||
            !event.isPaid) {
          return;
        }
        unawaited(
          _completePayment('Đã nhận thanh toán. VIP đã được kích hoạt.'),
        );
      },
      onError: (_) {
        // WebSocket is best-effort; polling below remains the fallback.
      },
    );
  }

  Future<void> _pollStatus() async {
    if (_checking || _status == PremiumPaymentStatus.paid) {
      return;
    }
    setState(() => _checking = true);
    try {
      final result = await ref
          .read(paymentRepositoryProvider)
          .getPremiumPaymentStatus(widget.payment.paymentId);
      if (!mounted) return;
      setState(() => _status = result.status);
      if (result.premiumUnlocked ||
          result.status == PremiumPaymentStatus.paid) {
        await _completePayment('VIP đã được kích hoạt.');
      }
    } catch (_) {
      // Polling is best-effort; users can still press the manual check button.
    } finally {
      if (mounted) {
        setState(() => _checking = false);
      }
    }
  }

  Future<void> _completePayment(String message) async {
    if (_completed || !mounted) {
      return;
    }
    _completed = true;
    _timer?.cancel();
    await _paymentEvents?.cancel();
    if (!mounted) {
      return;
    }
    setState(() {
      _status = PremiumPaymentStatus.paid;
      _checking = false;
    });

    await ref.read(authControllerProvider.notifier).reloadMe();
    if (!mounted) {
      return;
    }
    AppFeedback.success(message);
    Navigator.of(context).pop(true);
  }
}

class VipPlanSelector extends StatelessWidget {
  const VipPlanSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: AppSpacing.x2,
      runSpacing: AppSpacing.x2,
      children: [
        _PlanPill(label: 'Hàng tháng', price: '150K / tháng'),
        _PlanPill(label: 'Hàng năm (ưu đãi)', price: '1M / năm'),
      ],
    );
  }
}

class VipBenefitsTable extends StatelessWidget {
  const VipBenefitsTable({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quyền lợi Premium',
          style: AppTypography.labelFor(context),
        ),
        const SizedBox(height: AppSpacing.x3),
        const _BenefitRow(
          free: 'Xem bài tập, món ăn cơ bản',
          vip: 'Kế hoạch tập và ăn cá nhân hóa',
        ),
        const _BenefitRow(
          free: 'Theo dõi level, XP cơ bản',
          vip: 'Lưu tiến trình chi tiết, body metrics, mục tiêu',
        ),
        const _BenefitRow(
          free: 'Không có ưu tiên AI/coach',
          vip: 'Gợi ý form, phân tích cơ thể, thử thách VIP',
        ),
      ],
    );
  }
}

class _PlanPill extends StatelessWidget {
  const _PlanPill({
    required this.label,
    required this.price,
  });

  final String label;
  final String price;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(
            price,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.free,
    required this.vip,
  });

  final String free;
  final String vip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.x2),
      padding: const EdgeInsets.all(AppSpacing.x3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              free,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Text(
              vip,
              style: TextStyle(
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Value extends StatelessWidget {
  const _Value({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySmallFor(context),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.headerMediumFor(context),
        ),
      ],
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({
    required this.value,
    required this.onChanged,
  });

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x4,
          vertical: 12,
        ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryOf(context).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.input),
            ),
            child: Icon(Icons.contrast, color: AppColors.primaryOf(context)),
          ),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Text(
              'Giao diện',
              style: AppTypography.headerMediumFor(context),
            ),
          ),
          GestureDetector(
            onTap: () => onChanged(value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light),
            child: Container(
              width: 110,
              height: 44,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.isDark(context) 
                    ? Colors.black.withValues(alpha: 0.5) 
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: AppColors.isDark(context)
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              child: Stack(
                children: [
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    alignment: value == ThemeMode.light
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: Container(
                      width: 50,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.isDark(context)
                            ? Colors.white.withValues(alpha: 0.15)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: AppColors.isDark(context) ? [] : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: TextStyle(
                              color: value == ThemeMode.light
                                  ? (AppColors.isDark(context) ? Colors.white : Colors.black)
                                  : (AppColors.isDark(context) ? Colors.white54 : Colors.black54),
                              fontWeight: value == ThemeMode.light ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 12,
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.light_mode_rounded, size: 14),
                                SizedBox(width: 4),
                                Text('Sáng'),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: TextStyle(
                              color: value == ThemeMode.dark
                                  ? (AppColors.isDark(context) ? Colors.white : Colors.black)
                                  : (AppColors.isDark(context) ? Colors.white54 : Colors.black54),
                              fontWeight: value == ThemeMode.dark ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 12,
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.dark_mode_rounded, size: 14),
                                SizedBox(width: 4),
                                Text('Tối'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? AppColors.textPrimaryOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x4,
          vertical: 16,
        ),
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: themeColor),
            const SizedBox(width: AppSpacing.x3),
            Expanded(
              child: Text(
                title,
                style: AppTypography.body(color: themeColor),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: themeColor),
          ],
        ),
      ),
    );
  }
}
