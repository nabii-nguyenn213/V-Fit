import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/state_views.dart';
import 'package:vfit_frontend/features/auth/application/auth_controller.dart';
import '../../data/models/admin_dashboard_models.dart';
import '../../data/repositories/admin_dashboard_repository.dart';
import '../bloc/admin_dashboard_bloc.dart';
import '../bloc/admin_dashboard_event.dart';
import '../bloc/admin_dashboard_state.dart';
import '../widgets/animated_counter.dart';
import '../widgets/financial_chart.dart';

class AdminRevenueScreen extends ConsumerStatefulWidget {
  const AdminRevenueScreen({super.key});

  @override
  ConsumerState<AdminRevenueScreen> createState() => _AdminRevenueScreenState();
}

class _AdminRevenueScreenState extends ConsumerState<AdminRevenueScreen> {
  String searchQuery = '';
  DateTime? _userStartDate;
  DateTime? _userEndDate;

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(adminDashboardRepositoryProvider);

    return BlocProvider<AdminDashboardBloc>(
      create: (context) =>
          AdminDashboardBloc(repository)..add(const FetchMonthlyRevenue()),
      child: DefaultTabController(
        length: 3,
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
                              await ref
                                  .read(authControllerProvider.notifier)
                                  .logout();
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
              ],
            ),
          ),
          body: BlocBuilder<AdminDashboardBloc, AdminDashboardState>(
            builder: (context, state) {
              if (state is AdminDashboardInitial ||
                  state is AdminDashboardLoading) {
                return const LoadingView();
              }

              if (state is AdminDashboardState &&
                  state is AdminDashboardError) {
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

    return AppResponsive.centeredContent(
      context: context,
      maxWidth: 960,
      child: RefreshIndicator(
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

            // 4. Monthly Grid Cards (Optimized & shrunk by ~30%)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.05,
              ),
              itemCount: report.monthlyDetails.length,
              itemBuilder: (context, index) {
                final item = report.monthlyDetails[index];
                final isPositive = item.growthRate >= 0.0;

                return GestureDetector(
                  onTap: () => _showMonthlyDetailsDialog(context, item.month),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xff1C1D24).withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tháng ${item.month.substring(5)}/${item.month.substring(0, 4)}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Icon(
                              Icons.insights,
                              color: Colors.white24,
                              size: 16,
                            ),
                          ],
                        ),
                        Text(
                          currencyFormatter.format(item.totalRevenue),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${item.totalOrders} hóa đơn',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 10,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isPositive
                                    ? const Color(0xff00E676)
                                        .withValues(alpha: 0.1)
                                    : const Color(0xffFF3D00)
                                        .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isPositive
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward,
                                    color: isPositive
                                        ? const Color(0xff00E676)
                                        : const Color(0xffFF3D00),
                                    size: 8,
                                  ),
                                  const SizedBox(width: 1),
                                  Text(
                                    '${item.growthRate.abs().toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      color: isPositive
                                          ? const Color(0xff00E676)
                                          : const Color(0xffFF3D00),
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
                          backgroundColor:
                              const Color(0xff00E676).withValues(alpha: 0.1),
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
                                '${tx.userEmail} mua gói ${tx.orderType}',
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
      ),
    );
  }

  Future<void> _selectStartDate(BuildContext context, AdminDashboardLoaded state) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _userStartDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xff00E676),
              onPrimary: Colors.black,
              surface: Color(0xff1C1D24),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _userStartDate) {
      setState(() {
        _userStartDate = DateTime(picked.year, picked.month, picked.day, 0, 0, 0);
      });
      _triggerUserSearch(context, state);
    }
  }

  Future<void> _selectEndDate(BuildContext context, AdminDashboardLoaded state) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _userEndDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xff00E676),
              onPrimary: Colors.black,
              surface: Color(0xff1C1D24),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _userEndDate) {
      setState(() {
        _userEndDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      });
      _triggerUserSearch(context, state);
    }
  }

  void _triggerUserSearch(BuildContext context, AdminDashboardLoaded state) {
    context.read<AdminDashboardBloc>().add(
      ChangeUserPage(
        0,
        state.onlyVipFilter,
        search: searchQuery,
        startDate: _userStartDate?.toUtc().toIso8601String(),
        endDate: _userEndDate?.toUtc().toIso8601String(),
      ),
    );
  }

  void _clearFilters(BuildContext context, AdminDashboardLoaded state) {
    setState(() {
      searchQuery = '';
      _userStartDate = null;
      _userEndDate = null;
    });
    context.read<AdminDashboardBloc>().add(
      const ChangeUserPage(0, false, search: '', startDate: null, endDate: null),
    );
  }

  Widget _buildUsersTab(BuildContext context, AdminDashboardLoaded state) {
    final userResponse = state.users;
    final List<AdminUserModel> displayedUsers = userResponse != null ? userResponse.content : [];

    return AppResponsive.centeredContent(
      context: context,
      maxWidth: 960,
      child: RefreshIndicator(
        color: const Color(0xff00E676),
        backgroundColor: const Color(0xff1C1D24),
        onRefresh: () async {
          context.read<AdminDashboardBloc>().add(
            ToggleVipFilter(
              state.onlyVipFilter,
              search: searchQuery,
              startDate: _userStartDate?.toUtc().toIso8601String(),
              endDate: _userEndDate?.toUtc().toIso8601String(),
            ),
          );
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppResponsive.pagePadding(context).copyWith(top: 16),
          children: [
            // Filter Row & VIP Toggle
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
                    color: !state.onlyVipFilter
                        ? const Color(0xff00E676)
                        : Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: !state.onlyVipFilter
                          ? const Color(0xff00E676)
                          : Colors.transparent,
                    ),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      context.read<AdminDashboardBloc>().add(
                        ToggleVipFilter(
                          false,
                          search: searchQuery,
                          startDate: _userStartDate?.toUtc().toIso8601String(),
                          endDate: _userEndDate?.toUtc().toIso8601String(),
                        ),
                      );
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
                    color: state.onlyVipFilter
                        ? const Color(0xffFFB300)
                        : Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: state.onlyVipFilter
                          ? const Color(0xffFFB300)
                          : Colors.transparent,
                    ),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      context.read<AdminDashboardBloc>().add(
                        ToggleVipFilter(
                          true,
                          search: searchQuery,
                          startDate: _userStartDate?.toUtc().toIso8601String(),
                          endDate: _userEndDate?.toUtc().toIso8601String(),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search Box with prefix search icon
            TextField(
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo tên hoặc email...',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 18),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey, size: 16),
                        onPressed: () {
                          setState(() {
                            searchQuery = '';
                          });
                          _triggerUserSearch(context, state);
                        },
                      )
                    : null,
                fillColor: const Color(0xff1C1D24),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (val) {
                _triggerUserSearch(context, state);
              },
              onChanged: (val) {
                searchQuery = val;
              },
            ),
            const SizedBox(height: 10),

            // Date Range Filters
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectStartDate(context, state),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xff1C1D24),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.grey, size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _userStartDate != null
                                  ? DateFormat('dd/MM/yyyy').format(_userStartDate!)
                                  : 'Từ ngày...',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectEndDate(context, state),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xff1C1D24),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.grey, size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _userEndDate != null
                                  ? DateFormat('dd/MM/yyyy').format(_userEndDate!)
                                  : 'Đến ngày...',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_userStartDate != null || _userEndDate != null || searchQuery.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.redAccent, size: 20),
                    tooltip: 'Xóa bộ lọc',
                    onPressed: () => _clearFilters(context, state),
                  ),
                ],
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
            else if (userResponse == null || displayedUsers.isEmpty)
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
                itemCount: displayedUsers.length,
                itemBuilder: (context, index) {
                  final user = displayedUsers[index];
                  final regDate =
                      DateFormat('dd/MM/yyyy').format(user.createdAt.toLocal());
                  return GestureDetector(
                    onTap: () => _showUserDetailsDialog(context, user),
                    child: Container(
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
                                    user.fullName.isNotEmpty
                                        ? user.fullName[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.bold),
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
                                const SizedBox(height: 4),
                                Text(
                                  'Đăng ký: $regDate',
                                  style: TextStyle(
                                    color: Colors.white30,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (user.premiumActive && user.premiumPlan != 'VIP_TRIAL')
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
                                      search: searchQuery,
                                      startDate: _userStartDate?.toUtc().toIso8601String(),
                                      endDate: _userEndDate?.toUtc().toIso8601String(),
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
                                      search: searchQuery,
                                      startDate: _userStartDate?.toUtc().toIso8601String(),
                                      endDate: _userEndDate?.toUtc().toIso8601String(),
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
      ),
    );
  }

  Widget _buildTrafficTab(BuildContext context, AdminDashboardLoaded state) {
    final trafficResponse = state.traffic;

    return AppResponsive.centeredContent(
      context: context,
      maxWidth: 960,
      child: RefreshIndicator(
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
              // KPI Traffic Cards (Blue-Purple glowing color zone)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xff1E293B), Color(0xff0F172A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.blueAccent.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withValues(alpha: 0.03),
                        blurRadius: 10,
                      )
                    ]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TỔNG LƯỢT TRUY CẬP HỆ THỐNG',
                      style: TextStyle(
                        color: Color(0xff94A3B8),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.show_chart,
                            color: Colors.blueAccent, size: 24),
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

              // Statistics Breakdown (Interactive OS & Browser Pie Charts)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildStatBreakdownCard(
                      title: 'Hệ điều hành',
                      icon: Icons.laptop_mac,
                      stats: trafficResponse.osStats,
                      getColor: (name) {
                        final lName = name.toLowerCase();
                        if (lName.contains('windows')) return Colors.blueAccent;
                        if (lName.contains('ios')) return Colors.purpleAccent;
                        if (lName.contains('android'))
                          return const Color(0xff00E676);
                        if (lName.contains('macos')) return Colors.orangeAccent;
                        if (lName.contains('linux')) return Colors.redAccent;
                        return Colors.grey;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatBreakdownCard(
                      title: 'Trình duyệt',
                      icon: Icons.open_in_browser,
                      stats: trafficResponse.browserStats,
                      getColor: (name) {
                        final lName = name.toLowerCase();
                        if (lName.contains('chrome')) return Colors.redAccent;
                        if (lName.contains('safari')) return Colors.blueAccent;
                        if (lName.contains('edge')) return Colors.tealAccent;
                        if (lName.contains('firefox'))
                          return Colors.orangeAccent;
                        return Colors.grey;
                      },
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
                    icon: const Icon(Icons.refresh,
                        color: Color(0xff00E676), size: 20),
                    onPressed: () {
                      context
                          .read<AdminDashboardBloc>()
                          .add(const RefreshTrafficLogs());
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
                      child: CircularProgressIndicator(
                          color: Color(0xff00E676), strokeWidth: 2),
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
                    final localTime = logItem.createdAt
                        .toLocal(); // Convert from UTC to Local (UTC+7 automatically in Dart)
                    final timeString =
                        DateFormat('HH:mm:ss dd/MM').format(localTime);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xff1C1D24).withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.02)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.white10,
                            child: Icon(Icons.language,
                                color: Colors.grey, size: 14),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                        color: Colors.white70,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${logItem.os} • ${logItem.browser} • ${logItem.action} • Vị trí: ${logItem.location ?? "Hà Nội"}',
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
                        icon:
                            const Icon(Icons.chevron_left, color: Colors.white),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
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
                        icon: const Icon(Icons.chevron_right,
                            color: Colors.white),
                        onPressed: (trafficResponse.logs.page + 1 <
                                trafficResponse.logs.totalPages)
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
      ),
    );
  }

  Widget _buildStatBreakdownCard({
    required String title,
    required IconData icon,
    required Map<String, int> stats,
    required Color Function(String) getColor,
  }) {
    final total = stats.values.fold<int>(0, (sum, val) => sum + val);

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
          const SizedBox(height: 14),
          if (stats.isEmpty)
            const SizedBox(
              height: 80,
              child: Center(
                child: Text(
                  'Không có dữ liệu',
                  style: TextStyle(color: Colors.white30, fontSize: 10),
                ),
              ),
            )
          else
            Row(
              children: [
                // 1. Beautiful Pie/Donut Chart using fl_chart
                SizedBox(
                  height: 64,
                  width: 64,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 1.5,
                      centerSpaceRadius: 18,
                      startDegreeOffset: 270,
                      sections: stats.entries.map((entry) {
                        return PieChartSectionData(
                          color: getColor(entry.key),
                          value: entry.value.toDouble(),
                          title: '',
                          radius: 10,
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 2. Legend with names and percentages
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: stats.entries.take(3).map((entry) {
                      final percentage = total > 0
                          ? (entry.value / total * 100).toStringAsFixed(0)
                          : '0';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 5.0),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: getColor(entry.key),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                entry.key,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$percentage%',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }



  void _showMonthlyDetailsDialog(BuildContext context, String month) {
    showDialog(
      context: context,
      barrierColor: const Color(0xff050608).withValues(alpha: 0.82),
      builder: (context) => _MonthlyDetailsDialog(month: month),
    );
  }

  void _showUserDetailsDialog(BuildContext context, AdminUserModel user) {
    showDialog(
      context: context,
      barrierColor: const Color(0xff050608).withValues(alpha: 0.82),
      builder: (context) => _UserDetailsDialog(user: user),
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

class _MonthlyDetailsDialog extends ConsumerStatefulWidget {
  final String month;
  const _MonthlyDetailsDialog({required this.month});

  @override
  ConsumerState<_MonthlyDetailsDialog> createState() =>
      _MonthlyDetailsDialogState();
}

class _MonthlyDetailsDialogState extends ConsumerState<_MonthlyDetailsDialog> {
  late Future<List<RecentTransactionModel>> _detailsFuture;

  @override
  void initState() {
    super.initState();
    _detailsFuture = ref
        .read(adminDashboardRepositoryProvider)
        .getMonthlyRevenueDetails(widget.month);
  }

  @override
  Widget build(BuildContext context) {
    final monthParts = widget.month.split('-');
    final formattedMonth = '${monthParts[1]}/${monthParts[0]}';
    final compact = AppResponsive.isPhone(context) ||
        MediaQuery.sizeOf(context).height < 700;
    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );

    return _AdminDetailsDialogSurface(
      surfaceKey: const Key('monthly-details-dialog-surface'),
      maxWidth: 620,
      maxHeight: 600,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? 18 : 24,
          compact ? 18 : 22,
          compact ? 18 : 24,
          compact ? 18 : 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CHI TIẾT DOANH THU',
                        style: TextStyle(
                          color: Color(0xff31D987),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.35,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Tháng $formattedMonth',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 20 : 22,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Các khoản thanh toán đã ghi nhận trong kỳ',
                        style: TextStyle(
                          color: Color(0xff9298A3),
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                const _DialogCloseButton(),
              ],
            ),
            const SizedBox(height: 18),
            const Divider(height: 1, color: Color(0xff30343B)),
            const SizedBox(height: 16),
            Flexible(
              fit: FlexFit.loose,
              child: FutureBuilder<List<RecentTransactionModel>>(
                future: _detailsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _DialogLoadingState(
                      accentColor: Color(0xff31D987),
                      label: 'Đang tải giao dịch',
                    );
                  }

                  if (snapshot.hasError) {
                    return _DialogStateView(
                      icon: Icons.error_outline_rounded,
                      accentColor: const Color(0xffFF6B5F),
                      title: 'Không thể tải dữ liệu',
                      message: 'Có lỗi xảy ra: ${snapshot.error}',
                    );
                  }

                  final list = snapshot.data ?? [];
                  if (list.isEmpty) {
                    return const _DialogStateView(
                      icon: Icons.receipt_long_outlined,
                      accentColor: Color(0xff31D987),
                      title: 'Chưa có giao dịch',
                      message:
                          'Chưa ghi nhận hóa đơn thanh toán nào trong tháng này.',
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    primary: false,
                    padding: const EdgeInsets.only(bottom: 2),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final tx = list[index];
                      final normalizedOrderType = tx.orderType.toUpperCase();
                      final isVipYear = normalizedOrderType.contains('YEAR') ||
                          normalizedOrderType.contains('NĂM');
                      final packageLabel =
                          isVipYear ? 'VIP 1 Năm' : 'VIP 1 Tháng';
                      final badgeColor = isVipYear
                          ? const Color(0xffF6B94A)
                          : const Color(0xff31D987);
                      final txTime = DateFormat('HH:mm · dd/MM/yyyy')
                          .format(tx.createdAt.toLocal());

                      return Container(
                        padding: EdgeInsets.all(compact ? 12 : 14),
                        decoration: BoxDecoration(
                          color: const Color(0xff202329),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xff343840)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    tx.userEmail,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xffF4F6F8),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '+${currencyFormatter.format(tx.amount)}',
                                  style: const TextStyle(
                                    color: Color(0xff31D987),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final packageBadge = _PackageBadge(
                                  label: packageLabel,
                                  color: badgeColor,
                                );
                                final timeText = Text(
                                  txTime,
                                  style: const TextStyle(
                                    color: Color(0xff9298A3),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                );

                                if (constraints.maxWidth < 340) {
                                  return Wrap(
                                    spacing: 10,
                                    runSpacing: 8,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [packageBadge, timeText],
                                  );
                                }

                                return Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [packageBadge, timeText],
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserDetailsDialog extends ConsumerStatefulWidget {
  final AdminUserModel user;
  const _UserDetailsDialog({required this.user});

  @override
  ConsumerState<_UserDetailsDialog> createState() => _UserDetailsDialogState();
}

class _UserDetailsDialogState extends ConsumerState<_UserDetailsDialog> {
  late Future<List<RecentTransactionModel>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = ref
        .read(adminDashboardRepositoryProvider)
        .getUserTransactionHistory(widget.user.id);
  }

  @override
  Widget build(BuildContext context) {
    final compact = AppResponsive.isPhone(context) ||
        MediaQuery.sizeOf(context).height < 700;
    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );
    final regDate =
        DateFormat('dd/MM/yyyy').format(widget.user.createdAt.toLocal());
    final isVip = widget.user.premiumActive && widget.user.premiumPlan != 'VIP_TRIAL';
    final expiredStr = widget.user.premiumExpiredAt != null
        ? DateFormat('dd/MM/yyyy HH:mm')
            .format(widget.user.premiumExpiredAt!.toLocal())
        : '';
    final planLabel = _formatPremiumPlan(widget.user.premiumPlan);

    return _AdminDetailsDialogSurface(
      surfaceKey: const Key('user-details-dialog-surface'),
      maxWidth: 640,
      maxHeight: 680,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? 18 : 24,
          compact ? 18 : 22,
          compact ? 18 : 24,
          compact ? 18 : 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'THÔNG TIN KHÁCH HÀNG',
                    style: TextStyle(
                      color: Color(0xffF6B94A),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.35,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const _DialogCloseButton(),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Container(
                  width: compact ? 48 : 54,
                  height: compact ? 48 : 54,
                  decoration: BoxDecoration(
                    color: const Color(0xff262A31),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: const Color(0xff3A3F48)),
                    image: widget.user.avatarUrl != null &&
                            widget.user.avatarUrl!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(widget.user.avatarUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: widget.user.avatarUrl == null ||
                          widget.user.avatarUrl!.isEmpty
                      ? Text(
                          widget.user.fullName.isNotEmpty
                              ? widget.user.fullName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.fullName.isNotEmpty
                            ? widget.user.fullName
                            : 'Chưa đặt tên',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xffF4F6F8),
                          fontSize: compact ? 16 : 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xffA2A8B2),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tham gia $regDate',
                        style: const TextStyle(
                          color: Color(0xff757C87),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isVip
                    ? const Color(0xffF6B94A).withValues(alpha: 0.09)
                    : const Color(0xff202329),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isVip
                      ? const Color(0xffF6B94A).withValues(alpha: 0.30)
                      : const Color(0xff343840),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isVip
                          ? const Color(0xffF6B94A).withValues(alpha: 0.14)
                          : const Color(0xff2A2E35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isVip
                          ? Icons.workspace_premium_rounded
                          : Icons.person_outline_rounded,
                      color: isVip
                          ? const Color(0xffF6B94A)
                          : const Color(0xff9298A3),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isVip ? 'VIP đang hoạt động' : 'Gói miễn phí',
                          style: TextStyle(
                            color: isVip
                                ? const Color(0xffF6B94A)
                                : const Color(0xffB0B6BF),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (isVip &&
                            (expiredStr.isNotEmpty || planLabel != null)) ...[
                          const SizedBox(height: 3),
                          Text(
                            [
                              if (planLabel != null) planLabel,
                              if (expiredStr.isNotEmpty) 'Hết hạn $expiredStr',
                            ].join(' · '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xffC7CBD1),
                              fontSize: 10,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 19),
            const Divider(height: 1, color: Color(0xff30343B)),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.receipt_long_outlined,
                    color: Color(0xff9298A3), size: 16),
                SizedBox(width: 8),
                Text(
                  'LỊCH SỬ ĐĂNG KÝ VIP',
                  style: TextStyle(
                    color: Color(0xffA2A8B2),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.85,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              fit: FlexFit.loose,
              child: FutureBuilder<List<RecentTransactionModel>>(
                future: _historyFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _DialogLoadingState(
                      accentColor: Color(0xffF6B94A),
                      label: 'Đang tải lịch sử',
                    );
                  }

                  if (snapshot.hasError) {
                    return _DialogStateView(
                      icon: Icons.error_outline_rounded,
                      accentColor: const Color(0xffFF6B5F),
                      title: 'Không thể tải lịch sử',
                      message: 'Có lỗi khi tải lịch sử: ${snapshot.error}',
                    );
                  }

                  final list = snapshot.data ?? [];
                  if (list.isEmpty) {
                    return _DialogStateView(
                      icon: Icons.receipt_long_outlined,
                      accentColor: isVip
                          ? const Color(0xffF6B94A)
                          : const Color(0xff9298A3),
                      title: 'Chưa có giao dịch thanh toán',
                      message: isVip
                          ? 'VIP đang hoạt động, nhưng chưa có giao dịch thanh toán được ghi nhận.'
                          : 'Các lần đăng ký VIP sẽ xuất hiện tại đây.',
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    primary: false,
                    padding: const EdgeInsets.only(bottom: 2),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final tx = list[index];
                      final normalizedStatus = tx.status.toUpperCase();
                      final isSuccess = normalizedStatus == 'SUCCESS' ||
                          normalizedStatus == 'PAID';
                      final isPending = normalizedStatus == 'PENDING' ||
                          normalizedStatus == 'MANUAL_REVIEW';
                      final statusText = isSuccess
                          ? 'THÀNH CÔNG'
                          : normalizedStatus == 'MANUAL_REVIEW'
                              ? 'CẦN DUYỆT'
                              : isPending
                                  ? 'ĐANG CHỜ'
                                  : normalizedStatus == 'EXPIRED'
                                      ? 'HẾT HẠN'
                                      : 'THẤT BẠI';
                      final statusColor = isSuccess
                          ? const Color(0xff31D987)
                          : isPending
                              ? const Color(0xffF6B94A)
                              : const Color(0xffFF6B5F);
                      final txTime = DateFormat('HH:mm · dd/MM/yyyy')
                          .format(tx.createdAt.toLocal());
                      final normalizedOrderType = tx.orderType.toUpperCase();
                      final isVipYear = normalizedOrderType.contains('YEAR') ||
                          normalizedOrderType.contains('NĂM');
                      final packageLabel =
                          isVipYear ? 'VIP 1 Năm' : 'VIP 1 Tháng';

                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 12 : 14,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xff202329),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: const Color(0xff343840)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    packageLabel,
                                    style: const TextStyle(
                                      color: Color(0xffF4F6F8),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    txTime,
                                    style: const TextStyle(
                                      color: Color(0xff858C97),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (tx.voucherCode != null &&
                                      tx.voucherCode!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Voucher: ${tx.voucherCode}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xffF6B94A),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  currencyFormatter.format(tx.amount),
                                  style: const TextStyle(
                                    color: Color(0xffF4F6F8),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: statusColor.withValues(
                                            alpha: 0.22)),
                                  ),
                                  child: Text(
                                    statusText,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminDetailsDialogSurface extends StatelessWidget {
  final Key surfaceKey;
  final double maxWidth;
  final double maxHeight;
  final Widget child;

  const _AdminDetailsDialogSurface({
    required this.surfaceKey,
    required this.maxWidth,
    required this.maxHeight,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final compact = AppResponsive.isPhone(context) || media.size.height < 700;
    final horizontalInset = compact ? 16.0 : 40.0;
    final verticalInset = compact ? 12.0 : 28.0;
    final availableWidth =
        math.max(0.0, media.size.width - (horizontalInset * 2));
    final availableHeight = math.max(
      0.0,
      media.size.height -
          media.padding.vertical -
          media.viewInsets.vertical -
          (verticalInset * 2),
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: horizontalInset,
        vertical: verticalInset,
      ),
      child: Container(
        key: surfaceKey,
        width: math.min(maxWidth, availableWidth),
        constraints: BoxConstraints(
          maxHeight: math.min(maxHeight, availableHeight),
        ),
        decoration: BoxDecoration(
          color: const Color(0xff17191E),
          borderRadius: BorderRadius.circular(compact ? 18 : 22),
          border: Border.all(color: const Color(0xff3A3E47)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.68),
              blurRadius: 52,
              spreadRadius: 2,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(compact ? 17 : 21),
          child: Material(
            color: const Color(0xff17191E),
            child: child,
          ),
        ),
      ),
    );
  }
}

String? _formatPremiumPlan(String? premiumPlan) {
  final normalized = premiumPlan?.trim().toUpperCase();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  if (normalized.contains('TRIAL')) {
    return 'VIP dùng thử';
  }
  if (normalized.contains('LIFETIME')) {
    return 'VIP trọn đời';
  }
  if (normalized.contains('YEAR') || normalized.contains('NĂM')) {
    return 'VIP 1 Năm';
  }
  if (normalized.contains('MONTH') || normalized.contains('THÁNG')) {
    return 'VIP 1 Tháng';
  }
  return 'Gói VIP';
}

class _DialogCloseButton extends StatelessWidget {
  const _DialogCloseButton();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Đóng',
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xff24272D),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: const Color(0xff363A43)),
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          splashRadius: 18,
          icon: const Icon(Icons.close_rounded,
              color: Color(0xffC2C7CF), size: 19),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}

class _PackageBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _PackageBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _DialogLoadingState extends StatelessWidget {
  final Color accentColor;
  final String label;

  const _DialogLoadingState({required this.accentColor, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: accentColor,
                strokeWidth: 2.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xff9298A3),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogStateView extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String message;

  const _DialogStateView({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 144,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: accentColor, size: 19),
                ),
                const SizedBox(height: 11),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xffE6E9ED),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xff858C97),
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
