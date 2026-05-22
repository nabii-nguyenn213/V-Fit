import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/enum_parsers.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../checkin/data/models/checkin_models.dart';
import '../../../checkin/data/repositories/checkin_repository.dart';
import '../../data/repositories/app_config_repository.dart';

import '../../../challenges/presentation/widgets/force_camera_overlay.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final auth = ref.watch(authControllerProvider);
    final appConfig = ref.watch(appConfigProvider);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ForceCameraOverlay(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(appConfigProvider);
          if (auth.isAuthenticated) {
            await ref.read(authControllerProvider.notifier).reloadMe();
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [
                        Color(0xFF10112A),
                        Color(0xFF2A0D3F),
                        Color(0xFF061F2A),
                      ]
                    : const [
                        Color(0xFFE5FBFF),
                        Color(0xFFFFE7FB),
                        Color(0xFFFFFFFF),
                      ],
              ),
              border: Border.all(color: scheme.primary.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: isDark ? 0.34 : 0.14),
                  blurRadius: 34,
                  offset: const Offset(-12, 18),
                ),
                BoxShadow(
                  color:
                      scheme.secondary.withValues(alpha: isDark ? 0.28 : 0.1),
                  blurRadius: 30,
                  offset: const Offset(14, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color:
                        scheme.primary.withValues(alpha: isDark ? 0.16 : 0.22),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'GIAO THỨC TẬP LUYỆN V-FIT',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: isDark ? scheme.primary : scheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Nâng cấp\ncơ thể của bạn.',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                ),
                const SizedBox(height: 12),
                appConfig.when(
                  data: (config) => Text(
                    config.slogan ?? 'Tập thông minh hơn, sống khỏe mạnh hơn',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  loading: () => Text(
                    'Đang tải V-FIT...',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  error: (_, __) => Text(
                    'Tập thông minh hơn, sống khỏe mạnh hơn',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: () => context.go('/workouts'),
                      icon: const Icon(Icons.bolt_rounded),
                      label: const Text('Bắt đầu'),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/progress'),
                      icon: const Icon(Icons.show_chart),
                      label: const Text('Tiến độ'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppCard(
            child: Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'Cấp độ',
                    value: '${user?.level ?? 1}',
                  ),
                ),
                Expanded(
                  child: _MetricTile(label: 'XP', value: '${user?.xp ?? 0}'),
                ),
                Expanded(
                  child: _MetricTile(
                    label: 'Gói cước',
                    value: subscriptionLabel(
                      user?.subscriptionStatus ?? SubscriptionStatus.free,
                      user?.subscriptionPlanCode,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Xin chào, ${user?.fullName ?? 'hội viên'}',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          const _CheckinVoucherCard(),
          const SizedBox(height: 18),
          if (!auth.isAuthenticated) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mở khóa tập luyện VIP',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Đăng ký tài khoản để lưu lại tiến độ, sử dụng các kế hoạch tập VIP và các công cụ huấn luyện cá nhân.',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton.add(
                          label: 'Đăng ký VIP',
                          fullWidth: true,
                          onPressed: () => context.go('/register'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      AppButton.ghost(
                        label: 'Đăng nhập',
                        onPressed: () => context.go('/login'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],
          _QuickAction(
            title: 'Chương trình luyện tập',
            subtitle: 'Khám phá các chương trình luyện tập đa dạng.',
            icon: Icons.fitness_center,
            onTap: () => context.go('/workouts'),
          ),
          const SizedBox(height: 12),
          _QuickAction(
            title: 'Danh mục dinh dưỡng',
            subtitle: 'Tra cứu thực phẩm và tính toán Calo thông minh.',
            icon: Icons.restaurant,
            onTap: () => context.go('/nutrition'),
          ),
          const SizedBox(height: 12),
          _QuickAction(
            title: 'Tiến độ tập luyện',
            subtitle: 'Xem chỉ số cơ thể, huy hiệu và thử thách.',
            icon: Icons.show_chart,
            onTap: () => context.go('/progress'),
          ),
          const SizedBox(height: 20),
          appConfig.when(
            data: (config) => config.maintenanceMode
                ? ErrorView(
                    message:
                        config.maintenanceMessage ?? 'V-FIT đang được bảo trì.',
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    ),
  );
}
}

class _CheckinVoucherCard extends ConsumerStatefulWidget {
  const _CheckinVoucherCard();

  @override
  ConsumerState<_CheckinVoucherCard> createState() =>
      _CheckinVoucherCardState();
}

class _CheckinVoucherCardState extends ConsumerState<_CheckinVoucherCard> {
  bool _loading = false;
  bool _checkedToday = false;
  CheckinResult? _result;
  int? _initialCount;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadCheckinStatus());
  }

  Future<void> _loadCheckinStatus() async {
    final auth = ref.read(authControllerProvider);
    if (!auth.isAuthenticated) return;

    setState(() {
      _loading = true;
    });

    try {
      final status = await ref.read(checkinRepositoryProvider).getCheckinStatus();
      if (mounted) {
        setState(() {
          _checkedToday = status.checkedToday;
          _initialCount = status.monthCheckinCount;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _handleCheckin() async {
    final auth = ref.read(authControllerProvider);
    if (!auth.isAuthenticated) {
      context.go('/login');
      return;
    }

    if (_loading) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final result = await ref.read(checkinRepositoryProvider).checkinToday();
      if (!mounted) {
        return;
      }
      setState(() {
        _result = result;
        _checkedToday = true;
      });

      final awarded = result.awardedVouchers;
      if (awarded.isEmpty) {
        AppFeedback.success(
          'Bạn đã có ${result.monthCheckinCount}/30 ngày trong tháng này.',
          title: 'Điểm danh thành công',
        );
      } else {
        final codes = awarded.map((voucher) {
          return '${voucher.amountLabel} (${voucher.code})';
        }).join(', ');
        AppFeedback.success(
          'Nhận voucher $codes.',
          title: 'Chạm mốc thưởng',
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = error.toString();
      if (message.contains('điểm danh') || message.contains('xử lý')) {
        setState(() {
          _checkedToday = true;
        });
        AppFeedback.warning(message, title: 'Bạn đã điểm danh');
      } else {
        AppFeedback.error(message, title: 'Không điểm danh được');
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final scheme = Theme.of(context).colorScheme;
    final count = _result?.monthCheckinCount ?? _initialCount;
    final progress = count == null ? 0.0 : (count.clamp(0, 30) / 30);
    final subtitle = count == null
        ? 'Điểm danh 1 lần mỗi ngày để nhận voucher.'
        : 'Tháng này bạn đã điểm danh $count/30 ngày.';

    return AppCard(
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.surfaceContainerHighest.withValues(alpha: 0.72),
              scheme.primaryContainer.withValues(alpha: 0.28),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.event_available_rounded,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Điểm danh đổi Voucher',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 9,
                value: progress,
                backgroundColor: scheme.surface.withValues(alpha: 0.5),
                valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MilestonePill(
                    label: '15 ngày',
                    reward: 'Voucher 10K',
                    reached: (count ?? 0) >= 15,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MilestonePill(
                    label: '30 ngày',
                    reward: 'Voucher 30K',
                    reached: (count ?? 0) >= 30,
                  ),
                ),
              ],
            ),
            if (_result?.awardedVouchers.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              _AwardedVoucherStrip(vouchers: _result!.awardedVouchers),
            ],
            const SizedBox(height: 16),
            AppButton.primary(
              label: auth.isAuthenticated
                  ? (_checkedToday
                      ? 'Đã điểm danh hôm nay'
                      : 'Điểm danh hôm nay')
                  : 'Đăng nhập để điểm danh',
              icon: auth.isAuthenticated
                  ? Icons.touch_app_rounded
                  : Icons.login_rounded,
              loading: _loading,
              onPressed:
                  _checkedToday && auth.isAuthenticated ? null : _handleCheckin,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.errorContainer.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: scheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: scheme.error,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Lưu ý quan trọng tránh mất Voucher:',
                        style: TextStyle(
                          color: scheme.error,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Voucher và tiến độ điểm danh được liên kết trực tiếp với tài khoản đang đăng nhập.\n'
                    '• Hãy chắc chắn bạn đã đăng nhập đúng tài khoản chính trước khi điểm danh. Việc đổi sang tài khoản khác sẽ không thể truy cập voucher của tài khoản cũ.\n'
                    '• Hạn sử dụng: 15 ngày (Voucher 10K) và 30 ngày (Voucher 30K) kể từ ngày nhận thưởng.',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
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
}

class _MilestonePill extends StatelessWidget {
  const _MilestonePill({
    required this.label,
    required this.reward,
    required this.reached,
  });

  final String label;
  final String reward;
  final bool reached;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = reached
        ? const Color(0xFF32D583).withValues(alpha: 0.18)
        : scheme.surface.withValues(alpha: 0.6);
    final foreground =
        reached ? const Color(0xFF32D583) : scheme.onSurfaceVariant;

    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: foreground.withValues(alpha: reached ? 0.62 : 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(
                reached
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 16,
                color: foreground,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            reward,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _AwardedVoucherStrip extends StatelessWidget {
  const _AwardedVoucherStrip({required this.vouchers});

  final List<CheckinVoucher> vouchers;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Voucher vừa nhận',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          ...vouchers.map(
            (voucher) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      voucher.code,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    voucher.amountLabel,
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: scheme.onSurfaceVariant)),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: scheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
