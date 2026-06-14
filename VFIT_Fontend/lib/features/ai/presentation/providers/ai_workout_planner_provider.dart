import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/ai_planners_repository.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../profile/data/repositories/profile_repository.dart';
import '../../../../core/utils/enum_parsers.dart';

class AiWorkoutPlannerState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? plan;

  const AiWorkoutPlannerState({
    required this.isLoading,
    this.error,
    this.plan,
  });

  AiWorkoutPlannerState copyWith({
    bool? isLoading,
    String? error,
    Map<String, dynamic>? plan,
  }) {
    return AiWorkoutPlannerState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      plan: plan ?? this.plan,
    );
  }
}

class AiWorkoutPlannerNotifier extends StateNotifier<AiWorkoutPlannerState> {
  final Ref _ref;

  AiWorkoutPlannerNotifier(this._ref)
      : super(const AiWorkoutPlannerState(isLoading: false));

  Future<void> generateWorkoutPlan({
    required String level,
    required int daysPerWeek,
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
      final planData = await repository.createWorkoutPlan(
        age: age,
        gender: gender,
        weight: weight,
        height: height,
        goal: goal,
        activityLevel: activityLevel,
        level: level,
        daysPerWeek: daysPerWeek,
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
    state = const AiWorkoutPlannerState(isLoading: false);
  }
}

final aiWorkoutPlannerProvider =
    StateNotifierProvider.autoDispose<AiWorkoutPlannerNotifier, AiWorkoutPlannerState>((ref) {
  return AiWorkoutPlannerNotifier(ref);
});
