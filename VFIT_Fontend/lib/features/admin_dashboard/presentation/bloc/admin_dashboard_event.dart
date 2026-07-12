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
  final String? search;
  final String? startDate;
  final String? endDate;
  const ChangeUserPage(this.pageIndex, this.onlyVip, {this.search, this.startDate, this.endDate});
}

class ChangeTrafficPage extends AdminDashboardEvent {
  final int pageIndex;
  const ChangeTrafficPage(this.pageIndex);
}

class ToggleVipFilter extends AdminDashboardEvent {
  final bool onlyVip;
  final String? search;
  final String? startDate;
  final String? endDate;
  const ToggleVipFilter(this.onlyVip, {this.search, this.startDate, this.endDate});
}

class RefreshTrafficLogs extends AdminDashboardEvent {
  const RefreshTrafficLogs();
}
