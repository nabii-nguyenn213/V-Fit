import 'package:flutter/foundation.dart';
import '../../data/models/admin_dashboard_models.dart';

@immutable
abstract class AdminDashboardState {
  const AdminDashboardState();
}

class AdminDashboardInitial extends AdminDashboardState {
  const AdminDashboardInitial();
}

class AdminDashboardLoading extends AdminDashboardState {
  const AdminDashboardLoading();
}

class AdminDashboardLoaded extends AdminDashboardState {
  final MonthlyRevenueResponseModel report;
  final List<RecentTransactionModel> paginatedTransactions;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;

  const AdminDashboardLoaded({
    required this.report,
    required this.paginatedTransactions,
    this.currentPage = 0,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  AdminDashboardLoaded copyWith({
    MonthlyRevenueResponseModel? report,
    List<RecentTransactionModel>? paginatedTransactions,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return AdminDashboardLoaded(
      report: report ?? this.report,
      paginatedTransactions: paginatedTransactions ?? this.paginatedTransactions,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class AdminDashboardError extends AdminDashboardState {
  final String errorMessage;
  const AdminDashboardError(this.errorMessage);
}
