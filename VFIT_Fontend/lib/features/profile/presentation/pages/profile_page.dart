import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_controller.dart';
import '../../../../core/utils/enum_parsers.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_radius.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../../auth/application/auth_controller.dart';
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
        padding: const EdgeInsets.all(20),
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
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sử dụng ứng dụng miễn phí như khách. Tạo tài khoản khi bạn cần lưu tiến trình, sử dụng gói tập VIP và công cụ hồ sơ.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
          const _VipPricingCard(),
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
      padding: const EdgeInsets.all(20),
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
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(user.email),
                  const SizedBox(height: 6),
                  Chip(label: Text('Customer')),
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
        const _VipPricingCard(),
        const SizedBox(height: 16),
        bodyMetrics.when(
          data: (metric) => AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chỉ số cơ thể',
                  style: Theme.of(context).textTheme.titleMedium,
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

class _VipPricingCard extends StatelessWidget {
  const _VipPricingCard();

  @override
  Widget build(BuildContext context) {
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
                  color: AppColors.energyMagenta.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.input),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.energyMagenta,
                ),
              ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: Text(
                  'V-FIT VIP',
                  style: AppTypography.headerMediumFor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x3),
          Wrap(
            spacing: AppSpacing.x2,
            runSpacing: AppSpacing.x2,
            children: const [
              _PlanPill(label: 'Hàng tháng', price: '150K / tháng'),
              _PlanPill(label: 'Hàng năm (Ưu đãi)', price: '1M / năm'),
            ],
          ),
          const SizedBox(height: AppSpacing.x4),
          Text(
            'Bảng so sánh Free và VIP',
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
          const SizedBox(height: AppSpacing.x4),
          AppButton.add(
            label: 'Nạp VIP',
            fullWidth: true,
            onPressed: () {
              AppFeedback.info(
                'Thanh toán VIP đang được kết nối. Giá: 150K/tháng hoặc 1M/năm.',
                title: 'Tính năng đang phát triển',
              );
            },
          ),
        ],
      ),
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
        color: scheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.36)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(
            price,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: scheme.primary, fontWeight: FontWeight.w900),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              free,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              vip,
              style: TextStyle(color: scheme.onSurface),
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
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        Text(label),
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
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.x4),
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
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_outlined),
                label: Text('Sáng'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_outlined),
                label: Text('Tối'),
              ),
            ],
            selected: {value},
            showSelectedIcon: false,
            onSelectionChanged: (selected) => onChanged(selected.first),
          ),
        ],
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
      padding: const EdgeInsets.only(bottom: AppSpacing.x2),
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x4,
          vertical: AppSpacing.x3,
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
