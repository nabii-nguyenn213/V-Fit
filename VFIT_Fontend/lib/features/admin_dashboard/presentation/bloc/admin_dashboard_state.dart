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

  // New fields for User Monitoring, Traffic Logging, and Searches
  final PaginatedUserResponseModel? users;
  final bool onlyVipFilter;
  final bool isUserLoading;
  final TrafficMetricsResponseModel? traffic;
  final bool isTrafficLoading;
  final List<SearchMetricItemModel>? searches;
  final bool isSearchesLoading;

  const AdminDashboardLoaded({
    required this.report,
    required this.paginatedTransactions,
    this.currentPage = 0,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.users,
    this.onlyVipFilter = false,
    this.isUserLoading = false,
    this.traffic,
    this.isTrafficLoading = false,
    this.searches,
    this.isSearchesLoading = false,
  });

  AdminDashboardLoaded copyWith({
    MonthlyRevenueResponseModel? report,
    List<RecentTransactionModel>? paginatedTransactions,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
    PaginatedUserResponseModel? users,
    bool? onlyVipFilter,
    bool? isUserLoading,
    TrafficMetricsResponseModel? traffic,
    bool? isTrafficLoading,
    List<SearchMetricItemModel>? searches,
    bool? isSearchesLoading,
  }) {
    return AdminDashboardLoaded(
      report: report ?? this.report,
      paginatedTransactions: paginatedTransactions ?? this.paginatedTransactions,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      users: users ?? this.users,
      onlyVipFilter: onlyVipFilter ?? this.onlyVipFilter,
      isUserLoading: isUserLoading ?? this.isUserLoading,
      traffic: traffic ?? this.traffic,
      isTrafficLoading: isTrafficLoading ?? this.isTrafficLoading,
      searches: searches ?? this.searches,
      isSearchesLoading: isSearchesLoading ?? this.isSearchesLoading,
    );
  }
}

class AdminDashboardError extends AdminDashboardState {
  final String errorMessage;
  const AdminDashboardError(this.errorMessage);
}
