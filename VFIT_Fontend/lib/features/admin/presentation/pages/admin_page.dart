import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/state_views.dart';
import 'package:vfit_frontend/features/auth/application/auth_controller.dart';
import '../../data/repositories/admin_repository.dart';

class AdminPage extends ConsumerWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(adminDashboardProvider);

    return Scaffold(
      backgroundColor: const Color(0xff0D0E11), // Royal Black
      appBar: AppBar(
        backgroundColor: const Color(0xff0D0E11),
        elevation: 0,
        leadingWidth: 76,
        leading: const Padding(
          padding: EdgeInsets.only(left: 8),
          child: AppBackButton(),
        ),
        title: const Text(
          'Doanh Thu Tổng Quan',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: const Color(0xff1C1D24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text(
                      'Xác nhận đăng xuất',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    content: const Text(
                      'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản Admin không?',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Hủy',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await ref.read(authControllerProvider.notifier).logout();
                        },
                        child: const Text(
                          'Đăng xuất',
                          style: TextStyle(
                            color: Color(0xffFF3D00),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: AppResponsive.pagePadding(context).copyWith(top: 16),
        children: [
          dashboard.when(
            data: (stats) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Lifetime Revenue Card (glowing Neon Emerald Green)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xff1C1D24).withValues(alpha: 0.8),
                        const Color(0xff0D0E11),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xff00E676).withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xff00E676).withValues(alpha: 0.05),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TỔNG DOANH THU TOÀN THỜI GIAN',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _vnd(stats.totalRevenue),
                        style: const TextStyle(
                          color: Color(0xff00E676),
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(
                              color: Color(0xff00E676),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Breakdown Detail Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xff1C1D24).withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                  ),
                  child: Column(
                    children: [
                      _RevenueRow(
                        label: 'Gói VIP Tháng',
                        value: _vnd(stats.monthlyRevenue),
                        count: stats.monthlyVipCustomers,
                        iconColor: const Color(0xffFFB300),
                      ),
                      const Divider(height: 28, color: Colors.white10),
                      _RevenueRow(
                        label: 'Gói VIP Năm',
                        value: _vnd(stats.yearlyRevenue),
                        count: stats.yearlyVipCustomers,
                        iconColor: const Color(0xff00E676),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 3. Navigation CTA Button (Neon highlighted button)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff1C1D24),
                    foregroundColor: const Color(0xff00E676),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Color(0xff00E676), width: 1.2),
                    ),
                    elevation: 4,
                    shadowColor: const Color(0xff00E676).withValues(alpha: 0.2),
                  ),
                  onPressed: () => context.push('/admin/revenue'),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.insights, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Giám Sát Dòng Tiền Thời Gian Thực ⚡',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
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
    required this.iconColor,
  });

  final String label;
  final String value;
  final int? count;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.star_border_rounded, color: iconColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (count != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '$count khách hàng',
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ),
            ],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

String _vnd(num value) {
  return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(value);
}
