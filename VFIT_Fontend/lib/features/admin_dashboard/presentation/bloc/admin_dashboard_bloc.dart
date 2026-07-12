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
    on<ChangeUserPage>(_onChangeUserPage);
    on<ChangeTrafficPage>(_onChangeTrafficPage);
    on<ToggleVipFilter>(_onToggleVipFilter);
    on<RefreshTrafficLogs>(_onRefreshTrafficLogs);
  }

  Future<void> _onFetchMonthlyRevenue(
    FetchMonthlyRevenue event,
    Emitter<AdminDashboardState> emit,
  ) async {
    emit(const AdminDashboardLoading());
    try {
      final report = await _repository.getMonthlyRevenueReport();
      final transactions = await _repository.getTransactions(page: 0, size: 5);
      final users = await _repository.getAdminUsers(onlyVip: false, page: 0, size: 20);
      final traffic = await _repository.getTrafficMetrics(page: 0, size: 20);
      final searches = await _repository.getSearchMetrics(limit: 20);

      emit(AdminDashboardLoaded(
        report: report,
        paginatedTransactions: transactions.content,
        currentPage: 0,
        hasMore: !transactions.last && transactions.page < 49,
        users: users,
        onlyVipFilter: false,
        isUserLoading: false,
        traffic: traffic,
        isTrafficLoading: false,
        searches: searches,
        isSearchesLoading: false,
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
        paginatedTransactions: transactions.content,
        currentPage: event.pageIndex,
        hasMore: !transactions.last && event.pageIndex < 49,
        isLoadingMore: false,
      ));
    } catch (error) {
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onChangeUserPage(
    ChangeUserPage event,
    Emitter<AdminDashboardState> emit,
  ) async {
    if (state is! AdminDashboardLoaded) return;
    final currentState = state as AdminDashboardLoaded;

    emit(currentState.copyWith(isUserLoading: true));
    try {
      final users = await _repository.getAdminUsers(
        onlyVip: event.onlyVip,
        page: event.pageIndex,
        size: 20,
      );
      emit(currentState.copyWith(
        users: users,
        onlyVipFilter: event.onlyVip,
        isUserLoading: false,
      ));
    } catch (error) {
      emit(currentState.copyWith(isUserLoading: false));
    }
  }

  Future<void> _onChangeTrafficPage(
    ChangeTrafficPage event,
    Emitter<AdminDashboardState> emit,
  ) async {
    if (state is! AdminDashboardLoaded) return;
    final currentState = state as AdminDashboardLoaded;

    emit(currentState.copyWith(isTrafficLoading: true));
    try {
      final traffic = await _repository.getTrafficMetrics(
        page: event.pageIndex,
        size: 20,
      );
      emit(currentState.copyWith(
        traffic: traffic,
        isTrafficLoading: false,
      ));
    } catch (error) {
      emit(currentState.copyWith(isTrafficLoading: false));
    }
  }

  Future<void> _onToggleVipFilter(
    ToggleVipFilter event,
    Emitter<AdminDashboardState> emit,
  ) async {
    if (state is! AdminDashboardLoaded) return;
    final currentState = state as AdminDashboardLoaded;

    emit(currentState.copyWith(isUserLoading: true, onlyVipFilter: event.onlyVip));
    try {
      final users = await _repository.getAdminUsers(
        onlyVip: event.onlyVip,
        page: 0,
        size: 20,
      );
      emit(currentState.copyWith(
        users: users,
        onlyVipFilter: event.onlyVip,
        isUserLoading: false,
      ));
    } catch (error) {
      emit(currentState.copyWith(isUserLoading: false));
    }
  }

  Future<void> _onRefreshTrafficLogs(
    RefreshTrafficLogs event,
    Emitter<AdminDashboardState> emit,
  ) async {
    if (state is! AdminDashboardLoaded) return;
    final currentState = state as AdminDashboardLoaded;

    emit(currentState.copyWith(isTrafficLoading: true));
    try {
      final traffic = await _repository.getTrafficMetrics(
        page: 0,
        size: 20,
      );
      emit(currentState.copyWith(
        traffic: traffic,
        isTrafficLoading: false,
      ));
    } catch (error) {
      emit(currentState.copyWith(isTrafficLoading: false));
    }
  }
}
