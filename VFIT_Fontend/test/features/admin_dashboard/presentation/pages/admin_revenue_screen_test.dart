import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vfit_frontend/features/admin_dashboard/data/models/admin_dashboard_models.dart';
import 'package:vfit_frontend/features/admin_dashboard/data/repositories/admin_dashboard_repository.dart';
import 'package:vfit_frontend/features/admin_dashboard/presentation/pages/admin_revenue_screen.dart';

final _transaction = RecentTransactionModel(
  id: 'payment-001',
  userId: 'vip-user-001',
  userEmail: 'vip@example.com',
  orderType: 'VIP_YEARLY',
  amount: 1500000,
  status: 'SUCCESS',
  voucherCode: 'VIP50',
  createdAt: DateTime.utc(2026, 5, 26, 0, 34),
);

final _vipUser = AdminUserModel(
  id: 'vip-user-001',
  email: 'vip@example.com',
  fullName: 'Khach VIP',
  role: 'USER',
  active: true,
  premiumActive: true,
  premiumPlan: 'VIP_YEARLY',
  premiumExpiredAt: DateTime.utc(2027, 5, 26),
  createdAt: DateTime.utc(2026, 5, 15),
);

class _StubAdminDashboardRepository extends AdminDashboardRepository {
  _StubAdminDashboardRepository({List<RecentTransactionModel>? userHistory})
      : userHistory = userHistory ?? [_transaction],
        super(Dio());

  String? requestedHistoryUserId;
  String? requestedRevenueMonth;
  final List<RecentTransactionModel> userHistory;

  @override
  Future<MonthlyRevenueResponseModel> getMonthlyRevenueReport() async {
    return MonthlyRevenueResponseModel(
      lifetimeRevenue: 1500000,
      monthlyDetails: const [
        MonthlyRevenueItemModel(
          month: '2026-05',
          totalRevenue: 1500000,
          totalOrders: 1,
          growthRate: 0,
        ),
      ],
      recentTransactions: [_transaction],
    );
  }

  @override
  Future<PaginatedTransactionResponseModel> getTransactions({
    int page = 0,
    int size = 5,
  }) async {
    return PaginatedTransactionResponseModel(
      content: [_transaction],
      page: page,
      size: size,
      totalElements: 1,
      totalPages: 1,
      last: true,
    );
  }

  @override
  Future<PaginatedUserResponseModel> getAdminUsers({
    bool onlyVip = false,
    String? search,
    String? startDate,
    String? endDate,
    int page = 0,
    int size = 20,
  }) async {
    return PaginatedUserResponseModel(
      content: [_vipUser],
      page: page,
      size: size,
      totalElements: 1,
      totalPages: 1,
      last: true,
    );
  }

  @override
  Future<TrafficMetricsResponseModel> getTrafficMetrics({
    int page = 0,
    int size = 20,
  }) async {
    return const TrafficMetricsResponseModel(
      totalVisits: 0,
      logs: PaginatedVisitorLogResponseModel(
        content: [],
        page: 0,
        size: 20,
        totalElements: 0,
        totalPages: 0,
        last: true,
      ),
      osStats: {},
      browserStats: {},
    );
  }

  @override
  Future<List<SearchMetricItemModel>> getSearchMetrics({int limit = 20}) async {
    return const [];
  }

  @override
  Future<List<RecentTransactionModel>> getMonthlyRevenueDetails(
    String month,
  ) async {
    requestedRevenueMonth = month;
    return [_transaction];
  }

  @override
  Future<List<RecentTransactionModel>> getUserTransactionHistory(
    String userId,
  ) async {
    requestedHistoryUserId = userId;
    return userHistory;
  }
}

Future<_StubAdminDashboardRepository> _pumpAdminScreen(
  WidgetTester tester, {
  List<RecentTransactionModel>? userHistory,
}) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final repository = _StubAdminDashboardRepository(userHistory: userHistory);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        adminDashboardRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(home: AdminRevenueScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

void _expectStrongBackdrop(WidgetTester tester) {
  final barriers = tester
      .widgetList<ModalBarrier>(find.byType(ModalBarrier))
      .where((barrier) => barrier.color != null);

  expect(
    barriers.any((barrier) => barrier.color!.a >= 0.8),
    isTrue,
    reason: 'The page behind the dialog must be visibly dimmed.',
  );
}

void main() {
  testWidgets('monthly revenue dialog stays compact on a desktop viewport', (
    tester,
  ) async {
    final repository = await _pumpAdminScreen(tester);

    await tester.tap(find.text('Tháng 05/2026'));
    await tester.pumpAndSettle();

    expect(repository.requestedRevenueMonth, '2026-05');
    expect(find.text('CHI TIẾT DOANH THU'), findsOneWidget);
    expect(find.text('vip@example.com'), findsWidgets);

    final surface = find.byKey(
      const Key('monthly-details-dialog-surface'),
    );
    expect(surface, findsOneWidget);
    final rect = tester.getRect(surface);
    expect(rect.width, lessThanOrEqualTo(620));
    expect(rect.height, lessThanOrEqualTo(600));
    expect(rect.width, lessThan(tester.view.physicalSize.width * 0.6));
    expect(rect.height, lessThan(tester.view.physicalSize.height * 0.8));
    _expectStrongBackdrop(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('VIP customer dialog requests and renders that user history', (
    tester,
  ) async {
    final repository = await _pumpAdminScreen(tester);

    await tester.tap(find.text('Khách hàng'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Khach VIP'));
    await tester.pumpAndSettle();

    expect(repository.requestedHistoryUserId, _vipUser.id);
    expect(find.text('THÔNG TIN KHÁCH HÀNG'), findsOneWidget);
    expect(find.text('VIP 1 Năm'), findsOneWidget);
    expect(
      find.text('Khách hàng này chưa từng đăng ký gói VIP.'),
      findsNothing,
    );

    final surface = find.byKey(
      const Key('user-details-dialog-surface'),
    );
    expect(surface, findsOneWidget);
    final rect = tester.getRect(surface);
    expect(rect.width, lessThanOrEqualTo(640));
    expect(rect.height, lessThanOrEqualTo(680));
    expect(rect.width, lessThan(tester.view.physicalSize.width * 0.6));
    expect(rect.height, lessThan(tester.view.physicalSize.height * 0.85));
    _expectStrongBackdrop(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('active VIP without payment history gets a truthful empty state',
      (
    tester,
  ) async {
    final repository = await _pumpAdminScreen(tester, userHistory: const []);

    await tester.tap(find.text('Khách hàng'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Khach VIP'));
    await tester.pumpAndSettle();

    expect(repository.requestedHistoryUserId, _vipUser.id);
    expect(find.text('VIP đang hoạt động'), findsOneWidget);
    expect(find.text('Chưa có giao dịch thanh toán'), findsOneWidget);
    expect(
      find.text(
        'VIP đang hoạt động, nhưng chưa có giao dịch thanh toán được ghi nhận.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Khách hàng này chưa từng đăng ký gói VIP.'),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
