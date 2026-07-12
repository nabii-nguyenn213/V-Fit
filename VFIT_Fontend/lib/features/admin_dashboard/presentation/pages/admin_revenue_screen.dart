import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/state_views.dart';
import 'package:vfit_frontend/features/auth/application/auth_controller.dart';
import '../../data/repositories/admin_dashboard_repository.dart';
import '../bloc/admin_dashboard_bloc.dart';
import '../bloc/admin_dashboard_event.dart';
import '../bloc/admin_dashboard_state.dart';
import '../widgets/animated_counter.dart';
import '../widgets/financial_chart.dart';

class AdminRevenueScreen extends ConsumerWidget {
  const AdminRevenueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(adminDashboardRepositoryProvider);

    return BlocProvider<AdminDashboardBloc>(
      create: (context) =>
          AdminDashboardBloc(repository)..add(const FetchMonthlyRevenue()),
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
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
              'Bảng Điều Khiển Admin',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            actions: [
              Builder(
                builder: (context) {
                  return IconButton(
                    icon: const Icon(Icons.security, color: Color(0xff00E676)),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Hệ thống bảo mật tối cao V-FIT Admin Gate đang kích hoạt.',
                          ),
                          backgroundColor: Color(0xff1C1D24),
                        ),
                      );
                    },
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white70),
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).logout();
                },
              ),
            ],
            bottom: const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: Color(0xff00E676),
              labelColor: Color(0xff00E676),
              unselectedLabelColor: Colors.grey,
              indicatorWeight: 3,
              tabs: [
                Tab(icon: Icon(Icons.analytics_outlined), text: 'Doanh thu'),
                Tab(icon: Icon(Icons.people_alt_outlined), text: 'Khách hàng'),
                Tab(icon: Icon(Icons.traffic_outlined), text: 'Lưu lượng Web'),
                Tab(icon: Icon(Icons.search_outlined), text: 'Tìm kiếm'),
              ],
            ),
          ),
          body: BlocBuilder<AdminDashboardBloc, AdminDashboardState>(
            builder: (context, state) {
              if (state is AdminDashboardInitial ||
                  state is AdminDashboardLoading) {
                return const LoadingView();
              }

              if (state is AdminDashboardState && state is AdminDashboardError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.redAccent,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.errorMessage,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            context
                                .read<AdminDashboardBloc>()
                                .add(const FetchMonthlyRevenue());
                          },
                          child: const Text('Thử Lại'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state is AdminDashboardLoaded) {
                return TabBarView(
                  children: [
                    _buildRevenueTab(context, state),
                    _buildUsersTab(context, state),
                    _buildTrafficTab(context, state),
                    _buildSearchesTab(context, state),
                  ],
                );
              }

              return const SizedBox();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueTab(BuildContext context, AdminDashboardLoaded state) {
    final report = state.report;
    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );

    return RefreshIndicator(
      color: const Color(0xff00E676),
      backgroundColor: const Color(0xff1C1D24),
      onRefresh: () async {
        context.read<AdminDashboardBloc>().add(const FetchMonthlyRevenue());
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppResponsive.pagePadding(context).copyWith(top: 16),
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
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedCounter(
                  value: report.lifetimeRevenue,
                  style: const TextStyle(
                    color: Color(0xff00E676), // Neon Emerald Green
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(
                        color: Color(0xff00E676),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. Financial Trend Column Chart
          FinancialChart(data: report.monthlyDetails),
          const SizedBox(height: 24),

          // 3. Section Title - Monthly Grid Overview
          const Text(
            'TỔNG QUAN THU NHẬP THEO THÁNG',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),

          // 4. Monthly Grid Cards
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
            ),
            itemCount: report.monthlyDetails.length,
            itemBuilder: (context, index) {
              final item = report.monthlyDetails[index];
              final isPositive = item.growthRate >= 0.0;

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xff1C1D24).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tháng ${item.month.substring(5)}/${item.month.substring(0, 4)}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currencyFormatter.format(item.totalRevenue),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.totalOrders} hóa đơn',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isPositive
                              ? const Color(0xff00E676).withValues(alpha: 0.1)
                              : const Color(0xffFF3D00).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                              color: isPositive ? const Color(0xff00E676) : const Color(0xffFF3D00),
                              size: 10,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${item.growthRate.abs().toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: isPositive ? const Color(0xff00E676) : const Color(0xffFF3D00),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 28),

          // 5. Live Transaction Stream Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'GIAO DỊCH GẦN NHẤT',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xff00E676).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.fiber_manual_record,
                      color: Color(0xff00E676),
                      size: 8,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'LIVE STREAM',
                      style: TextStyle(
                        color: Color(0xff00E676),
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 6. Paginated ListView stream list
          if (state.isLoadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Color(0xff00E676),
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else if (state.paginatedTransactions.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: const Center(
                child: Text(
                  'Chưa phát sinh giao dịch thành công nào.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.paginatedTransactions.length,
              itemBuilder: (context, index) {
                final tx = state.paginatedTransactions[index];
                final timeString = _formatRelativeTime(tx.createdAt);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xff1C1D24).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.03),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xff00E676).withValues(alpha: 0.1),
                        child: const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: Color(0xff00E676),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'User_${tx.userId.length > 8 ? tx.userId.substring(tx.userId.length - 8) : tx.userId} mua gói ${tx.orderType}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              timeString,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.3),
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '+${currencyFormatter.format(tx.amount)}',
                        style: const TextStyle(
                          color: Color(0xff00E676),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

          // 7. Pagination Controls
          if (!state.isLoadingMore && state.paginatedTransactions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.chevron_left,
                      color: Colors.white,
                    ),
                    onPressed: state.currentPage > 0
                        ? () {
                            context.read<AdminDashboardBloc>().add(
                                  ChangeTransactionPage(
                                    state.currentPage - 1,
                                  ),
                                );
                          }
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xff1C1D24),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Trang ${state.currentPage + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.chevron_right,
                  color: Colors.white,
                ),
                onPressed: state.hasMore
                    ? () {
                        context.read<AdminDashboardBloc>().add(
                              ChangeTransactionPage(
                                state.currentPage + 1,
                              ),
                            );
                      }
                    : null,
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),
      ],
    ),
  );
}

  Widget _buildUsersTab(BuildContext context, AdminDashboardLoaded state) {
    final userResponse = state.users;

    return RefreshIndicator(
      color: const Color(0xff00E676),
      backgroundColor: const Color(0xff1C1D24),
      onRefresh: () async {
        context.read<AdminDashboardBloc>().add(ToggleVipFilter(state.onlyVipFilter));
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppResponsive.pagePadding(context).copyWith(top: 16),
        children: [
          // Filter Row
          Row(
            children: [
              const Text(
                'DANH SÁCH TÀI KHOẢN',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              ChoiceChip(
                label: const Text('Tất cả'),
                selected: !state.onlyVipFilter,
                selectedColor: const Color(0xff00E676).withValues(alpha: 0.2),
                backgroundColor: const Color(0xff1C1D24),
                labelStyle: TextStyle(
                  color: !state.onlyVipFilter ? const Color(0xff00E676) : Colors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: !state.onlyVipFilter ? const Color(0xff00E676) : Colors.transparent,
                  ),
                ),
                onSelected: (selected) {
                  if (selected) {
                    context.read<AdminDashboardBloc>().add(const ToggleVipFilter(false));
                  }
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Khách VIP'),
                selected: state.onlyVipFilter,
                selectedColor: const Color(0xffFFB300).withValues(alpha: 0.2),
                backgroundColor: const Color(0xff1C1D24),
                labelStyle: TextStyle(
                  color: state.onlyVipFilter ? const Color(0xffFFB300) : Colors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: state.onlyVipFilter ? const Color(0xffFFB300) : Colors.transparent,
                  ),
                ),
                onSelected: (selected) {
                  if (selected) {
                    context.read<AdminDashboardBloc>().add(const ToggleVipFilter(true));
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (state.isUserLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xff00E676)),
              ),
            )
          else if (userResponse == null || userResponse.content.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: const Center(
                child: Text(
                  'Không tìm thấy người dùng nào phù hợp.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            )
          else ...[
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: userResponse.content.length,
              itemBuilder: (context, index) {
                final user = userResponse.content[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xff1C1D24).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.03),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xff1C1D24),
                        backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                            ? NetworkImage(user.avatarUrl!)
                            : null,
                        child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                            ? Text(
                                user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.fullName.isNotEmpty ? user.fullName : 'Chưa thiết lập tên',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user.email,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (user.premiumActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xffFFB300), Color(0xffFF8F00)],
                            ),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xffFFB300).withValues(alpha: 0.2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Text(
                            'VIP',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xff1C1D24),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: const Text(
                            'FREE',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),

            // Pagination user controls
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                    onPressed: userResponse.page > 0
                        ? () {
                            context.read<AdminDashboardBloc>().add(
                                  ChangeUserPage(
                                    userResponse.page - 1,
                                    state.onlyVipFilter,
                                  ),
                                );
                          }
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xff1C1D24),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Trang ${userResponse.page + 1} / ${userResponse.totalPages}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                    onPressed: (userResponse.page + 1 < userResponse.totalPages)
                        ? () {
                            context.read<AdminDashboardBloc>().add(
                                  ChangeUserPage(
                                    userResponse.page + 1,
                                    state.onlyVipFilter,
                                  ),
                                );
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTrafficTab(BuildContext context, AdminDashboardLoaded state) {
    final trafficResponse = state.traffic;

    return RefreshIndicator(
      color: const Color(0xff00E676),
      backgroundColor: const Color(0xff1C1D24),
      onRefresh: () async {
        context.read<AdminDashboardBloc>().add(const RefreshTrafficLogs());
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppResponsive.pagePadding(context).copyWith(top: 16),
        children: [
          if (trafficResponse == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xff00E676)),
              ),
            )
          else ...[
            // KPI Traffic Cards
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xff1A237E), Color(0xff0D0E11)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TỔNG LƯỢT TRUY CẬP HỆ THỐNG',
                    style: TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.trending_up, color: Colors.blueAccent, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        '${trafficResponse.totalVisits} lượt',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Statistics Breakdown (OS & Browser)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildStatBreakdownCard(
                    title: 'Hệ điều hành',
                    icon: Icons.laptop_mac,
                    stats: trafficResponse.osStats,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatBreakdownCard(
                    title: 'Trình duyệt',
                    icon: Icons.open_in_browser,
                    stats: trafficResponse.browserStats,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Logs Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'NHẬT KÝ TRUY CẬP (REAL-TIME)',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xff00E676), size: 20),
                  onPressed: () {
                    context.read<AdminDashboardBloc>().add(const RefreshTrafficLogs());
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (state.isTrafficLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Color(0xff00E676), strokeWidth: 2),
                  ),
                ),
              )
            else if (trafficResponse.logs.content.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Chưa có log truy cập nào được lưu.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              )
            else ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: trafficResponse.logs.content.length,
                itemBuilder: (context, index) {
                  final logItem = trafficResponse.logs.content[index];
                  final localTime = logItem.createdAt.toLocal(); // Convert from UTC to Local (UTC+7 automatically in Dart)
                  final timeString = DateFormat('HH:mm:ss dd/MM').format(localTime);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xff1C1D24).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.02)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.white10,
                          child: Icon(Icons.language, color: Colors.grey, size: 14),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    logItem.ip,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    timeString,
                                    style: const TextStyle(
                                      color: Colors.white30,
                                      fontSize: 9,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${logItem.os} • ${logItem.browser} • ${logItem.action}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Traffic logs pagination controls
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: Colors.white),
                      onPressed: trafficResponse.logs.page > 0
                          ? () {
                              context.read<AdminDashboardBloc>().add(
                                    ChangeTrafficPage(
                                      trafficResponse.logs.page - 1,
                                    ),
                                  );
                            }
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xff1C1D24),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Trang ${trafficResponse.logs.page + 1} / ${trafficResponse.logs.totalPages}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: Colors.white),
                      onPressed: (trafficResponse.logs.page + 1 < trafficResponse.logs.totalPages)
                          ? () {
                              context.read<AdminDashboardBloc>().add(
                                    ChangeTrafficPage(
                                      trafficResponse.logs.page + 1,
                                    ),
                                  );
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatBreakdownCard({
    required String title,
    required IconData icon,
    required Map<String, int> stats,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xff1C1D24).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blueGrey, size: 16),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (stats.isEmpty)
            const Text(
              'Không có dữ liệu',
              style: TextStyle(color: Colors.white30, fontSize: 10),
            )
          else
            ...stats.entries.take(4).map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${entry.value} lượt',
                        style: const TextStyle(color: Color(0xff00E676), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildSearchesTab(BuildContext context, AdminDashboardLoaded state) {
    final searches = state.searches;

    return RefreshIndicator(
      color: const Color(0xff00E676),
      backgroundColor: const Color(0xff1C1D24),
      onRefresh: () async {
        context.read<AdminDashboardBloc>().add(const FetchMonthlyRevenue());
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppResponsive.pagePadding(context).copyWith(top: 16),
        children: [
          const Text(
            'XU HƯỚNG TÌM KIẾM MÓN ĂN',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 16),

          if (searches == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xff00E676)),
              ),
            )
          else if (searches.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: const Center(
                child: Text(
                  'Chưa ghi nhận từ khóa tìm kiếm thực tế nào.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: searches.length,
              itemBuilder: (context, index) {
                final item = searches[index];
                final isTop3 = index < 3;
                final Color rankingColor = index == 0
                    ? const Color(0xffFFD700) // Gold
                    : index == 1
                        ? const Color(0xffC0C0C0) // Silver
                        : index == 2
                            ? const Color(0xffCD7F32) // Bronze
                            : Colors.grey;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xff1C1D24).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.02)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: rankingColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: rankingColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          item.keyword,
                          style: TextStyle(
                            color: isTop3 ? Colors.white : Colors.white70,
                            fontSize: 13,
                            fontWeight: isTop3 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xff00E676).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.search, color: Color(0xff00E676), size: 12),
                            const SizedBox(width: 4),
                            Text(
                              '${item.searchCount}',
                              style: const TextStyle(
                                color: Color(0xff00E676),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _formatRelativeTime(DateTime dateTime) {
    final duration = DateTime.now().difference(dateTime);
    if (duration.inMinutes < 1) {
      return 'Vừa xong';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes} phút trước';
    } else if (duration.inHours < 24) {
      return '${duration.inHours} giờ trước';
    } else {
      return '${duration.inDays} ngày trước';
    }
  }
}
