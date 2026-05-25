import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/state_views.dart';
import '../../data/repositories/admin_repository.dart';
import 'package:go_router/go_router.dart';

class AdminPage extends ConsumerWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(adminDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 76,
        leading: const Padding(
          padding: EdgeInsets.only(left: 8),
          child: AppBackButton(),
        ),
        title: const Text('Doanh thu'),
      ),
      body: ListView(
        padding: AppResponsive.pagePadding(context),
        children: [
          dashboard.when(
            data: (stats) => Column(
              children: [
                AppCard(
                  child: _RevenueRow(
                    label: 'Tong doanh thu',
                    value: _vnd(stats.totalRevenue),
                    emphasized: true,
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    children: [
                      _RevenueRow(
                        label: 'VIP thang',
                        value: _vnd(stats.monthlyRevenue),
                        count: stats.monthlyVipCustomers,
                      ),
                      const Divider(height: 24),
                      _RevenueRow(
                        label: 'VIP nam',
                        value: _vnd(stats.yearlyRevenue),
                        count: stats.yearlyVipCustomers,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Giám sát dòng tiền thời gian thực ⚡',
                  onPressed: () => context.push('/admin/revenue'),
                ),
              ],
            ),
            loading: () => const LoadingView(),
            error: (error, _) => ErrorView(
              message: error.toString(),
              onRetry: () => ref.invalidate(adminDashboardProvider),
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueRow extends StatelessWidget {
  const _RevenueRow({
    required this.label,
    required this.value,
    this.count,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final int? count;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: textTheme.titleMedium),
              if (count != null) Text('$count customer'),
            ],
          ),
        ),
        Text(
          value,
          style: (emphasized ? textTheme.headlineSmall : textTheme.titleLarge)
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

String _vnd(num value) {
  return NumberFormat.currency(locale: 'vi_VN', symbol: 'VND').format(value);
}
