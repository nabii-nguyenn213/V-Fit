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
