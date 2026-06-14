import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/ai_planners_repository.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../profile/data/repositories/profile_repository.dart';
import '../../../../core/utils/enum_parsers.dart';

class AiMealPlannerState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? plan;

  const AiMealPlannerState({
    required this.isLoading,
    this.error,
    this.plan,
  });

  AiMealPlannerState copyWith({
    bool? isLoading,
    String? error,
    Map<String, dynamic>? plan,
  }) {
    return AiMealPlannerState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      plan: plan ?? this.plan,
    );
  }
}

class AiMealPlannerNotifier extends StateNotifier<AiMealPlannerState> {
  final Ref _ref;

  AiMealPlannerNotifier(this._ref)
      : super(const AiMealPlannerState(isLoading: false));

  Future<void> generateMealPlan({
    required int mealsPerDay,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final auth = _ref.read(authControllerProvider);
      final user = auth.user;
      final bodyMetricsAsync = _ref.read(bodyMetricsProvider);
      final bodyMetrics = bodyMetricsAsync.valueOrNull;

      final int age = user?.dateOfBirth != null
          ? DateTime.now().year - user!.dateOfBirth!.year
          : 25;
      final String gender = user?.gender != null
          ? (user!.gender == Gender.male ? 'Nam' : (user.gender == Gender.female ? 'Nữ' : 'Khác'))
          : 'Nam';
      final double weight = bodyMetrics?.weightKg ?? 70.0;
      final double height = bodyMetrics?.heightCm ?? 170.0;
      final String goal = user?.goalType != null
          ? (user!.goalType == GoalType.loseWeight ? 'Giảm mỡ' : 'Tăng cơ')
          : 'Tăng cơ';
      const String activityLevel = 'Vừa phải';

      final repository = _ref.read(aiPlannersRepositoryProvider);
      final planData = await repository.createMealPlan(
        age: age,
        gender: gender,
        weight: weight,
        height: height,
        goal: goal,
        activityLevel: activityLevel,
        mealsPerDay: mealsPerDay,
      );

      state = state.copyWith(isLoading: false, plan: planData);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void reset() {
    state = const AiMealPlannerState(isLoading: false);
  }
}

final aiMealPlannerProvider =
    StateNotifierProvider.autoDispose<AiMealPlannerNotifier, AiMealPlannerState>((ref) {
  return AiMealPlannerNotifier(ref);
});
