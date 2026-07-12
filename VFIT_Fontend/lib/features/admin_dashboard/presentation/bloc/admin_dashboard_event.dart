import 'package:flutter/foundation.dart';

@immutable
abstract class AdminDashboardEvent {
  const AdminDashboardEvent();
}

class FetchMonthlyRevenue extends AdminDashboardEvent {
  const FetchMonthlyRevenue();
}

class ChangeTransactionPage extends AdminDashboardEvent {
  final int pageIndex;
  const ChangeTransactionPage(this.pageIndex);
}

class ChangeUserPage extends AdminDashboardEvent {
  final int pageIndex;
  final bool onlyVip;
  const ChangeUserPage(this.pageIndex, this.onlyVip);
}

class ChangeTrafficPage extends AdminDashboardEvent {
  final int pageIndex;
  const ChangeTrafficPage(this.pageIndex);
}

class ToggleVipFilter extends AdminDashboardEvent {
  final bool onlyVip;
  const ToggleVipFilter(this.onlyVip);
}

class RefreshTrafficLogs extends AdminDashboardEvent {
  const RefreshTrafficLogs();
}
