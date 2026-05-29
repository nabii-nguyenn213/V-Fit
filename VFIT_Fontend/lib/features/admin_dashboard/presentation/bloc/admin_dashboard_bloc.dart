import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/admin_dashboard_repository.dart';
import 'admin_dashboard_event.dart';
import 'admin_dashboard_state.dart';

class AdminDashboardBloc
    extends Bloc<AdminDashboardEvent, AdminDashboardState> {
  final AdminDashboardRepository _repository;

  AdminDashboardBloc(this._repository) : super(const AdminDashboardInitial()) {
    on<FetchMonthlyRevenue>(_onFetchMonthlyRevenue);
    on<ChangeTransactionPage>(_onChangeTransactionPage);
  }

  Future<void> _onFetchMonthlyRevenue(
    FetchMonthlyRevenue event,
    Emitter<AdminDashboardState> emit,
  ) async {
    emit(const AdminDashboardLoading());
    try {
      final report = await _repository.getMonthlyRevenueReport();
      final transactions = await _repository.getTransactions(page: 0, size: 5);
      emit(AdminDashboardLoaded(
        report: report,
        paginatedTransactions: transactions.content,
        currentPage: 0,
        hasMore: !transactions.last &&
            transactions.page < 49, // limit 50 pages (0 to 49)
      ));
    } catch (error) {
      emit(AdminDashboardError(error.toString()));
    }
  }

  Future<void> _onChangeTransactionPage(
    ChangeTransactionPage event,
    Emitter<AdminDashboardState> emit,
  ) async {
    if (state is! AdminDashboardLoaded) return;
    final currentState = state as AdminDashboardLoaded;

    if (event.pageIndex < 0 || event.pageIndex > 49) return;

    emit(currentState.copyWith(isLoadingMore: true));
    try {
      final transactions =
          await _repository.getTransactions(page: event.pageIndex, size: 5);

      emit(currentState.copyWith(
        paginatedTransactions:
            transactions.content, // REPLACE instead of append
        currentPage: event.pageIndex,
        hasMore: !transactions.last && event.pageIndex < 49,
        isLoadingMore: false,
      ));
    } catch (error) {
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }
}
