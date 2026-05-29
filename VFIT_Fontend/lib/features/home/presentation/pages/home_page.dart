import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/enum_parsers.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_radius.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../../../presentation/widgets/common/metric_tile.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../challenges/presentation/widgets/force_camera_overlay.dart';
import '../../../checkin/data/models/checkin_models.dart';
import '../../../checkin/data/repositories/checkin_repository.dart';
import '../../data/repositories/app_config_repository.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final auth = ref.watch(authControllerProvider);
    final appConfig = ref.watch(appConfigProvider);
    final subscription = subscriptionLabel(
      user?.subscriptionStatus ?? SubscriptionStatus.free,
      user?.subscriptionPlanCode,
    );

    return ForceCameraOverlay(
      child: RefreshIndicator(
        color: AppColors.primaryOf(context),
        backgroundColor: AppColors.surface1Of(context),
        onRefresh: () async {
          ref.invalidate(appConfigProvider);
          if (auth.isAuthenticated) {
            await ref.read(authControllerProvider.notifier).reloadMe();
          }
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 720;
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                AppSpacing.x4,
                AppSpacing.x3,
                AppSpacing.x4,
                MediaQuery.paddingOf(context).bottom + AppSpacing.x8,
              ),
              children: [
                _HomeHero(
                  name: user?.fullName ?? 'hội viên',
                  slogan: appConfig.when(
                    data: (config) =>
                        config.slogan ??
                        'Tập thông minh hơn, sống khỏe mạnh hơn.',
                    loading: () => 'Đang đồng bộ dữ liệu V-FIT...',
                    error: (_, __) => 'Tập thông minh hơn, sống khỏe mạnh hơn.',
                  ),
                  onStart: () => context.go('/workouts'),
                  onProgress: () => context.go('/progress'),
                ),
                const SizedBox(height: AppSpacing.x4),
                _MetricGrid(
                  wide: wide,
                  level: user?.level ?? 1,
                  xp: user?.xp ?? 0,
                  subscription: subscription,
                ),
                const SizedBox(height: AppSpacing.x4),
                const _CheckinVoucherCard(),
                const SizedBox(height: AppSpacing.x4),
                if (!auth.isAuthenticated) ...[
                  _GuestUnlockCard(
                    onRegister: () => context.go('/register'),
                    onLogin: () => context.go('/login'),
                  ),
                  const SizedBox(height: AppSpacing.x4),
                ],
                _CommandGrid(
                  wide: wide,
                  actions: [
                    _HomeCommand(
                      title: 'Luyện tập',
                      subtitle:
                          'Giáo án, thư viện bài tập và kế hoạch cá nhân.',
                      icon: Icons.fitness_center_rounded,
                      onTap: () => context.go('/workouts'),
                    ),
                    _HomeCommand(
                      title: 'Dinh dưỡng',
                      subtitle: 'Tra cứu món ăn, quét calo và tính macro.',
                      icon: Icons.restaurant_rounded,
                      onTap: () => context.go('/nutrition'),
                    ),
                    _HomeCommand(
                      title: 'Tiến độ',
                      subtitle: 'Theo dõi chỉ số, ảnh hành trình và thử thách.',
                      icon: Icons.show_chart_rounded,
                      onTap: () => context.go('/progress'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.x4),
                appConfig.when(
                  data: (config) => config.maintenanceMode
                      ? ErrorView(
                          message: config.maintenanceMessage ??
                              'V-FIT đang được bảo trì.',
                        )
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({
    required this.name,
    required this.slogan,
    required this.onStart,
    required this.onProgress,
  });

  final String name;
  final String slogan;
  final VoidCallback onStart;
  final VoidCallback onProgress;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.x5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.card),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surface2Of(context),
              AppColors.surface1Of(context),
              Color(0xFF0D1C28),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatusPill(
                  icon: Icons.bolt_rounded,
                  label: 'V-FIT COACHING',
                  color: AppColors.limePerformance,
                ),
                const Spacer(),
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primaryOf(context).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          AppColors.primaryOf(context).withValues(alpha: 0.24),
                    ),
                  ),
                  child: Icon(
                    Icons.monitor_heart_rounded,
                    color: AppColors.primaryOf(context),
                    size: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x6),
            Text(
              'Xin chào, $name',
              style: AppTypography.headerLargeFor(context),
            ),
            const SizedBox(height: AppSpacing.x2),
            Text(
              slogan,
              style: AppTypography.bodyFor(context),
            ),
            const SizedBox(height: AppSpacing.x6),
            Row(
              children: [
                Expanded(
                  child: AppButton.primary(
                    label: 'Bắt đầu tập',
                    icon: Icons.play_arrow_rounded,
                    onPressed: onStart,
                  ),
                ),
                const SizedBox(width: AppSpacing.x3),
                AppButton.ghost(
                  label: 'Tiến độ',
                  icon: Icons.show_chart_rounded,
                  onPressed: onProgress,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({
    required this.wide,
    required this.level,
    required this.xp,
    required this.subscription,
  });

  final bool wide;
  final int level;
  final int xp;
  final String subscription;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      MetricTile(
        label: 'Cấp độ',
        value: '$level',
        icon: Icons.workspace_premium_rounded,
        accentColor: AppColors.limePerformance,
      ),
      MetricTile(
        label: 'XP hiện tại',
        value: '$xp',
        icon: Icons.auto_graph_rounded,
        accentColor: AppColors.primaryCyan,
      ),
      MetricTile(
        label: 'Gói cước',
        value: subscription,
        icon: Icons.verified_rounded,
        accentColor: AppColors.energyMagenta,
      ),
    ];

    if (wide) {
      return Row(
        children: [
          Expanded(child: tiles[0]),
          const SizedBox(width: AppSpacing.x3),
          Expanded(child: tiles[1]),
          const SizedBox(width: AppSpacing.x3),
          Expanded(child: tiles[2]),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: tiles[0]),
            const SizedBox(width: AppSpacing.x3),
            Expanded(child: tiles[1]),
          ],
        ),
        const SizedBox(height: AppSpacing.x3),
        tiles[2],
      ],
    );
  }
}

class _GuestUnlockCard extends StatelessWidget {
  const _GuestUnlockCard({
    required this.onRegister,
    required this.onLogin,
  });

  final VoidCallback onRegister;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusPill(
            icon: Icons.lock_open_rounded,
            label: 'VIP ACCESS',
            color: AppColors.energyMagenta,
          ),
          const SizedBox(height: AppSpacing.x4),
          Text(
            'Mở khóa tập luyện cá nhân hóa',
            style: AppTypography.headerMediumFor(context),
          ),
          const SizedBox(height: AppSpacing.x2),
          Text(
            'Đăng ký tài khoản để lưu tiến độ, dùng giáo án VIP và công cụ huấn luyện cá nhân.',
            style: AppTypography.bodyFor(context),
          ),
          const SizedBox(height: AppSpacing.x4),
          Row(
            children: [
              Expanded(
                child: AppButton.add(
                  label: 'Đăng ký',
                  fullWidth: true,
                  onPressed: onRegister,
                ),
              ),
              const SizedBox(width: AppSpacing.x3),
              AppButton.ghost(
                label: 'Đăng nhập',
                onPressed: onLogin,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommandGrid extends StatelessWidget {
  const _CommandGrid({
    required this.wide,
    required this.actions,
  });

  final bool wide;
  final List<_HomeCommand> actions;

  @override
  Widget build(BuildContext context) {
    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < actions.length; index++) ...[
            Expanded(child: _CommandTile(action: actions[index])),
            if (index != actions.length - 1)
              const SizedBox(width: AppSpacing.x3),
          ],
        ],
      );
    }

    return Column(
      children: [
        for (var index = 0; index < actions.length; index++) ...[
          _CommandTile(action: actions[index]),
          if (index != actions.length - 1)
            const SizedBox(height: AppSpacing.x3),
        ],
      ],
    );
  }
}

class _CommandTile extends StatelessWidget {
  const _CommandTile({required this.action});

  final _HomeCommand action;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: action.onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryOf(context).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.input),
            ),
            child: Icon(action.icon, color: AppColors.primaryOf(context)),
          ),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action.title,
                  style: AppTypography.headerMediumFor(context),
                ),
                const SizedBox(height: AppSpacing.x1),
                Text(
                  action.subtitle,
                  style: AppTypography.bodySmallFor(context),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondaryOf(context),
          ),
        ],
      ),
    );
  }
}

class _HomeCommand {
  const _HomeCommand({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x3,
        vertical: AppSpacing.x2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: AppSpacing.x1),
          Text(label, style: AppTypography.label(color: color)),
        ],
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
      final status =
          await ref.read(checkinRepositoryProvider).getCheckinStatus();
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

    if (_loading) return;

    setState(() {
      _loading = true;
    });

    try {
      final result = await ref.read(checkinRepositoryProvider).checkinToday();
      if (!mounted) return;
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
      if (!mounted) return;
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
    final count = _result?.monthCheckinCount ?? _initialCount;
    final progress = count == null ? 0.0 : (count.clamp(0, 30) / 30);
    final subtitle = count == null
        ? 'Điểm danh mỗi ngày để giữ nhịp và nhận voucher.'
        : 'Tháng này bạn đã điểm danh $count/30 ngày.';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.input),
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Điểm danh đổi voucher',
                      style: AppTypography.headerMediumFor(context),
                    ),
                    const SizedBox(height: AppSpacing.x1),
                    Text(subtitle, style: AppTypography.bodySmallFor(context)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x4),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: progress,
              backgroundColor: AppColors.surface2Of(context),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.success,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x3),
          Row(
            children: [
              Expanded(
                child: _MilestonePill(
                  label: '15 ngày',
                  reward: 'Voucher 10K',
                  reached: (count ?? 0) >= 15,
                ),
              ),
              const SizedBox(width: AppSpacing.x2),
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
            const SizedBox(height: AppSpacing.x3),
            _AwardedVoucherStrip(vouchers: _result!.awardedVouchers),
          ],
          const SizedBox(height: AppSpacing.x4),
          AppButton.primary(
            label: auth.isAuthenticated
                ? (_checkedToday ? 'Đã điểm danh hôm nay' : 'Điểm danh hôm nay')
                : 'Đăng nhập để điểm danh',
            icon: auth.isAuthenticated
                ? Icons.touch_app_rounded
                : Icons.login_rounded,
            loading: _loading,
            onPressed:
                _checkedToday && auth.isAuthenticated ? null : _handleCheckin,
          ),
        ],
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
    final color =
        reached ? AppColors.success : AppColors.textSecondaryOf(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: reached ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: color.withValues(alpha: 0.20)),
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
                size: 15,
                color: color,
              ),
              const SizedBox(width: AppSpacing.x1),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label(color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x1),
          Text(
            reward,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmallFor(context),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.x3),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Voucher vừa nhận',
            style: AppTypography.label(color: AppColors.success),
          ),
          const SizedBox(height: AppSpacing.x1),
          ...vouchers.map(
            (voucher) => Padding(
              padding: const EdgeInsets.only(top: AppSpacing.x1),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      voucher.code,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyFor(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x2),
                  Text(
                    voucher.amountLabel,
                    style: AppTypography.label(color: AppColors.success),
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
