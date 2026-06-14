import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/coach_message_model.dart';
import '../../data/repositories/ai_coach_repository.dart';
import '../../../auth/application/auth_controller.dart';
import '../../data/repositories/profile_repository.dart';
import '../../../../core/utils/enum_parsers.dart';

class AiCoachState {
  final List<CoachMessageModel> messages;
  final bool isLoading;
  final String? error;

  const AiCoachState({
    required this.messages,
    required this.isLoading,
    this.error,
  });

  AiCoachState copyWith({
    List<CoachMessageModel>? messages,
    bool? isLoading,
    String? error,
  }) {
    return AiCoachState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AiCoachNotifier extends StateNotifier<AiCoachState> {
  final Ref _ref;

  AiCoachNotifier(this._ref) : super(const AiCoachState(messages: [], isLoading: false)) {
    _initChat();
  }

  void _initChat() {
    state = AiCoachState(
      messages: [
        CoachMessageModel(
          id: 'initial',
          text: 'Xin chào! Tôi là Huấn luyện viên ảo V-FIT AI Coach. Hôm nay tôi có thể giúp gì cho bạn về dinh dưỡng hay kế hoạch tập luyện?',
          isUser: false,
          createdAt: DateTime.now(),
        ),
      ],
      isLoading: false,
    );
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = CoachMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    try {
      final auth = _ref.read(authControllerProvider);
      final user = auth.user;
      final bodyMetricsAsync = _ref.read(bodyMetricsProvider);
      final bodyMetrics = bodyMetricsAsync.valueOrNull;

      final int age = user?.dateOfBirth != null
          ? DateTime.now().year - user!.dateOfBirth!.year
          : 25;
      final String gender = user?.gender != null
          ? (user!.gender == Gender.male ? 'MALE' : (user.gender == Gender.female ? 'FEMALE' : 'OTHER'))
          : 'MALE';
      final double weight = bodyMetrics?.weightKg ?? 70.0;
      final double height = bodyMetrics?.heightCm ?? 170.0;
      final String goal = user?.goalType != null
          ? (user!.goalType == GoalType.loseWeight ? 'LOSE_WEIGHT' : 'GAIN_MUSCLE')
          : 'GAIN_MUSCLE';
      const String activityLevel = 'moderate';

      final repository = _ref.read(aiCoachRepositoryProvider);
      final responseText = await repository.askCoach(
        question: text,
        age: age,
        gender: gender,
        weight: weight,
        height: height,
        goal: goal,
        activityLevel: activityLevel,
      );

      final coachMessage = CoachMessageModel(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        text: responseText,
        isUser: false,
        createdAt: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, coachMessage],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Lỗi kết nối AI: ${e.toString()}',
      );
    }
  }

  void clearChat() {
    _initChat();
  }
}

final aiCoachProvider = StateNotifierProvider.autoDispose<AiCoachNotifier, AiCoachState>((ref) {
  return AiCoachNotifier(ref);
});
