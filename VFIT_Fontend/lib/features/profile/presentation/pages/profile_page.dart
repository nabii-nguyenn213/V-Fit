import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

class _VipPricingCard extends ConsumerStatefulWidget {
  const _VipPricingCard();

  @override
  ConsumerState<_VipPricingCard> createState() => _VipPricingCardState();
}

class _VipPricingCardState extends ConsumerState<_VipPricingCard> {
  bool _creating = false;

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
      AppFeedback.info('Vui long dang nhap de nap VIP.');
      if (mounted) {
        context.go('/login');
      }
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
    return AlertDialog(
      title: const Text('Chon goi VIP'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _planTile(PremiumPlan.monthly, 'VIP 1 thang', '150K'),
            _planTile(PremiumPlan.yearly, 'VIP 1 nam', '1M'),
            const SizedBox(height: 12),
            TextField(
              controller: _voucherController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Ma voucher neu co',
                prefixIcon: Icon(Icons.confirmation_number_outlined),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Huy'),
        ),
        FilledButton.icon(
          onPressed: _confirm,
          icon: const Icon(Icons.qr_code_rounded),
          label: const Text('Tao QR'),
        ),
      ],
    );
  }

  Widget _planTile(PremiumPlan plan, String title, String price) {
    return RadioListTile<PremiumPlan>(
      value: plan,
      groupValue: _selected,
      onChanged: (value) {
        if (value == null) return;
        setState(() => _selected = value);
      },
      title: Text(title),
      subtitle: Text(price),
      contentPadding: EdgeInsets.zero,
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

    return Dialog(
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
                    const Icon(Icons.qr_code_rounded),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Quet QR chuyen khoan',
                        style: Theme.of(context).textTheme.titleLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: qrSize,
                            height: qrSize,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.black.withValues(alpha: 0.08),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
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
                        const SizedBox(height: 16),
                        _paymentLine(
                          'Gia goc',
                          '${payment.baseAmount.toStringAsFixed(0)} VND',
                        ),
                        if (payment.discountAmount > 0)
                          _paymentLine(
                            'Giam gia',
                            '${payment.discountAmount.toStringAsFixed(0)} VND',
                          ),
                        _paymentLine(
                          'Can chuyen',
                          '${payment.finalAmount.toStringAsFixed(0)} VND',
                        ),
                        _paymentLine('Noi dung', payment.paymentCode),
                        _paymentLine('Ngan hang', payment.bankCode),
                        _paymentLine('So TK', payment.accountNumber),
                        _paymentLine('Chu TK', payment.accountName),
                        if (payment.expiredAt != null)
                          _paymentLine(
                            'Han thanh toan',
                            payment.expiredAt!.toLocal().toString(),
                          ),
                        const SizedBox(height: 12),
                        AppFeedbackPanel(
                          compact: true,
                          type: _status == PremiumPaymentStatus.paid
                              ? AppFeedbackType.success
                              : AppFeedbackType.info,
                          title: _status == PremiumPaymentStatus.paid
                              ? 'Da mo VIP'
                              : 'Dang cho thanh toan',
                          message: _status == PremiumPaymentStatus.paid
                              ? 'Goi VIP da duoc kich hoat.'
                              : 'App se tu cap nhat sau khi SePay xac nhan giao dich.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: _checking ? null : _pollStatus,
                      child: const Text('Kiem tra'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        _status == PremiumPaymentStatus.paid ? 'Xong' : 'Dong',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _paymentLine(String label, String value) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final labelStyle = TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 12,
        );
        const valueStyle = TextStyle(fontWeight: FontWeight.w800);
        final valueWidget = SelectableText(
          value,
          style: valueStyle,
        );

        if (constraints.maxWidth >= 340) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 116, child: Text(label, style: labelStyle)),
                const SizedBox(width: 10),
                Expanded(child: valueWidget),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: labelStyle),
              const SizedBox(height: 2),
              valueWidget,
            ],
          ),
        );
      },
    );
  }

  void _listenPaymentRealtime() {
    _paymentEvents = ref
        .read(paymentRepositoryProvider)
        .watchPremiumPayments()
        .listen((event) {
      if (!mounted ||
          event.paymentId != widget.payment.paymentId ||
          !event.isPaid) {
        return;
      }
      unawaited(_completePayment('Da nhan thanh toan. VIP da duoc kich hoat.'));
    }, onError: (_) {
      // WebSocket is best-effort; polling below remains the fallback.
    });
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
        await _completePayment('VIP da duoc kich hoat.');
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
