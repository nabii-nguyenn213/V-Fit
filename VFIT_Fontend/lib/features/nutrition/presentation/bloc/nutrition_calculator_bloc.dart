import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/app_error_mapper.dart';
import '../../../../core/error/crash_reporter.dart';
import '../../domain/entities/food.dart';
import '../../domain/usecases/remember_food.dart';
import '../../domain/usecases/search_foods.dart';

sealed class NutritionCalculatorEvent extends Equatable {
  const NutritionCalculatorEvent();

  @override
  List<Object?> get props => [];
}

class NutritionSearchRequested extends NutritionCalculatorEvent {
  const NutritionSearchRequested(this.keyword);

  final String keyword;

  @override
  List<Object?> get props => [keyword];
}

class NutritionFoodSelected extends NutritionCalculatorEvent {
  const NutritionFoodSelected(this.food);

  final Food food;

  @override
  List<Object?> get props => [food];
}

class NutritionCalculatorState extends Equatable {
  const NutritionCalculatorState({
    this.keyword = '',
    this.foods = const [],
    this.loading = false,
    this.errorMessage,
    this.offlineFallback = false,
  });

  final String keyword;
  final List<Food> foods;
  final bool loading;
  final String? errorMessage;
  final bool offlineFallback;

  bool get hasKeyword => keyword.trim().isNotEmpty;
  bool get isEmptyResult => !loading && hasKeyword && foods.isEmpty;

  NutritionCalculatorState copyWith({
    String? keyword,
    List<Food>? foods,
    bool? loading,
    String? errorMessage,
    bool? offlineFallback,
    bool clearError = false,
  }) {
    return NutritionCalculatorState(
      keyword: keyword ?? this.keyword,
      foods: foods ?? this.foods,
      loading: loading ?? this.loading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      offlineFallback: offlineFallback ?? this.offlineFallback,
    );
  }

  @override
  List<Object?> get props => [
        keyword,
        foods,
        loading,
        errorMessage,
        offlineFallback,
      ];
}

class NutritionCalculatorBloc
    extends Bloc<NutritionCalculatorEvent, NutritionCalculatorState> {
  NutritionCalculatorBloc({
    required SearchFoods searchFoods,
    required RememberFood rememberFood,
  })  : _searchFoods = searchFoods,
        _rememberFood = rememberFood,
        super(const NutritionCalculatorState(loading: true)) {
    on<NutritionSearchRequested>(_onSearchRequested);
    on<NutritionFoodSelected>(_onFoodSelected);
  }

  static const _popularLimit = 6;
  static const _searchLimit = 10;

  final SearchFoods _searchFoods;
  final RememberFood _rememberFood;

  Future<void> _onSearchRequested(
    NutritionSearchRequested event,
    Emitter<NutritionCalculatorState> emit,
  ) async {
    final keyword = event.keyword.trim();
    emit(
      state.copyWith(
        keyword: keyword,
        loading: true,
        clearError: true,
        offlineFallback: false,
      ),
    );
    try {
      final foods = await _searchFoods(
        keyword,
        size: keyword.isEmpty ? _popularLimit : _searchLimit,
      );
      emit(
        NutritionCalculatorState(
          keyword: keyword,
          foods: foods,
        ),
      );
    } catch (error, stackTrace) {
      await CrashReporter.record(error, stackTrace);
      emit(
        state.copyWith(
          keyword: keyword,
          loading: false,
          errorMessage: AppErrorMapper.friendlyMessage(error),
        ),
      );
    }
  }

  Future<void> _onFoodSelected(
    NutritionFoodSelected event,
    Emitter<NutritionCalculatorState> emit,
  ) async {
    try {
      await _rememberFood(event.food);
    } catch (error, stackTrace) {
      await CrashReporter.record(error, stackTrace);
    }
  }
}
