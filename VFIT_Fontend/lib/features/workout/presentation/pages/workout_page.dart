import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/enum_parsers.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_radius.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../../ai/data/repositories/ai_recommendation_repository.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../exercise_library/data/repositories/exercise_library_repository_impl.dart';
import '../../../exercise_library/presentation/bloc/exercise_library_bloc.dart';
import '../../../exercise_library/presentation/pages/exercise_library_page.dart';
import '../../../personalized_workout/data/repositories/personalized_workout_repository_impl.dart';
import '../../../personalized_workout/presentation/bloc/personalized_workout_bloc.dart';
import '../../../personalized_workout/presentation/bloc/personalized_workout_event.dart';
import '../../../personalized_workout/presentation/bloc/personalized_workout_state.dart';
import '../../../personalized_workout/presentation/widgets/personal_workout_plan_widget.dart';
import '../../../profile/data/models/user_model.dart';

class WorkoutPage extends ConsumerStatefulWidget {
  const WorkoutPage({super.key});

  @override
  ConsumerState<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends ConsumerState<WorkoutPage> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final hasGoal = user?.goalType != null;

    return MultiBlocProvider(
      key: ValueKey(user?.goalType),
      providers: [
        BlocProvider<ExerciseLibraryBloc>(
          create: (_) =>
              ExerciseLibraryBloc(ref.read(getExerciseCatalogProvider))
                ..add(const ExerciseLibraryRequested()),
        ),
        if (hasGoal)
          BlocProvider<PersonalizedWorkoutBloc>(
            create: (_) => PersonalizedWorkoutBloc(
              ref.read(getPersonalizedWorkoutProvider),
            )..add(const PersonalizedWorkoutRequested()),
          ),
      ],
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _WorkoutHeader(user: user),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppResponsive.horizontalPadding(context),
                ),
                child: ScanBodyButton(user: user),
              ),
              const SizedBox(height: AppSpacing.x2),
              _WorkoutTabs(
                selectedTab: _selectedTab,
                hasGoal: hasGoal,
                onChanged: (index) => setState(() => _selectedTab = index),
              ),
              Expanded(
                child: IndexedStack(
                  index: _selectedTab,
                  children: [
                    if (hasGoal)
                      const PersonalizedWorkoutView(
                        key: PageStorageKey('personalized-workout-view'),
                      )
                    else
                      WorkoutFreeContent(
                        key: const PageStorageKey('workout-free-content'),
                        user: user,
                      ),
                    const ExerciseLibraryView(
                      key: PageStorageKey('exercise-library-tab-key'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkoutHeader extends StatelessWidget {
  const _WorkoutHeader({required this.user});

  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppResponsive.pagePadding(context).copyWith(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Không gian tập luyện',
                  style: AppTypography.headerLargeFor(context),
                ),
                const SizedBox(height: AppSpacing.x1),
                Text(
                  user == null
                      ? 'Bài tập cơ bản luôn miễn phí.'
                      : 'Luyện tập theo nhịp độ của bạn.',
                  style: AppTypography.bodySmallFor(context),
                ),
              ],
            ),
          ),
          Icon(
            Icons.fitness_center_rounded,
            size: 28,
            color: AppColors.primaryOf(context),
          ),
        ],
      ),
    );
  }
}

class _WorkoutTabs extends StatelessWidget {
  const _WorkoutTabs({
    required this.selectedTab,
    required this.hasGoal,
    required this.onChanged,
  });

  final int selectedTab;
  final bool hasGoal;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x5,
        vertical: AppSpacing.x2,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.x1),
        decoration: BoxDecoration(
          color: AppColors.surface1Of(context),
          borderRadius: BorderRadius.circular(AppRadius.input),
          border: Border.all(color: AppColors.borderSubtleOf(context)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _TabButton(
                label: hasGoal ? 'Lịch cá nhân' : 'Lịch mẫu',
                icon: hasGoal
                    ? Icons.assignment_turned_in_rounded
                    : Icons.calendar_month_rounded,
                isSelected: selectedTab == 0,
                onTap: () => onChanged(0),
              ),
            ),
            Expanded(
              child: _TabButton(
                label: 'Thư viện bài tập',
                icon: Icons.local_library_rounded,
                isSelected: selectedTab == 1,
                onTap: () => onChanged(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.small),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.x3),
          decoration: BoxDecoration(
            color:
                isSelected ? AppColors.primaryOf(context) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? AppColors.onAccentOf(context)
                    : AppColors.textSecondaryOf(context),
              ),
              const SizedBox(width: AppSpacing.x2),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label(
                    color: isSelected
                        ? AppColors.onAccentOf(context)
                        : AppColors.textSecondaryOf(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WorkoutFreeContent extends StatelessWidget {
  const WorkoutFreeContent({
    super.key,
    required this.user,
  });

  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppResponsive.pagePadding(context).copyWith(top: AppSpacing.x2),
      children: [
        if (user == null) const LoginToSetGoalState(),
        if (user?.goalType == null && user != null) const GoalRequiredState(),
        const SizedBox(height: AppSpacing.x3),
        AppButton.secondary(
          label: 'Xem thư viện bài tập',
          icon: Icons.local_library_rounded,
          fullWidth: true,
          onPressed: () => context.push('/exercises'),
        ),
      ],
    );
  }
}

class ScanBodyButton extends StatefulWidget {
  const ScanBodyButton({
    super.key,
    required this.user,
  });

  final UserModel? user;

  @override
  State<ScanBodyButton> createState() => _ScanBodyButtonState();
}

class _ScanBodyButtonState extends State<ScanBodyButton> {
  bool _openingAiTools = false;

  @override
  Widget build(BuildContext context) {
    final isVip = widget.user?.isVipActive == true;
    final accent = isVip ? AppColors.success : AppColors.energyMagenta;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.large),
      onTap: _openingAiTools ? null : _handlePressed,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.x4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.large),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surface2Of(context),
              AppColors.surface1Of(context),
              accent.withValues(alpha: AppColors.isDark(context) ? 0.18 : 0.08),
            ],
          ),
          border: Border.all(color: accent.withValues(alpha: 0.42)),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.16),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.input),
                border: Border.all(color: accent.withValues(alpha: 0.36)),
              ),
              child: _openingAiTools
                  ? Padding(
                      padding: const EdgeInsets.all(14),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(accent),
                      ),
                    )
                  : Icon(Icons.document_scanner_rounded, color: accent),
            ),
            const SizedBox(width: AppSpacing.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quét cơ thể AI',
                    style: AppTypography.headerMediumFor(context),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'AI phân tích body, form tập và cá nhân hóa nâng cao.',
                    style: AppTypography.bodySmallFor(context),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.x2),
            Icon(Icons.chevron_right_rounded, color: accent),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePressed() async {
    final user = widget.user;
    if (user == null) {
      await showDialog<void>(
        context: context,
        builder: (context) => const LoginRequiredModal(),
      );
      return;
    }

    if (!user.isVipActive) {
      await showDialog<void>(
        context: context,
        builder: (context) => const VipRequiredModal(),
      );
      return;
    }

    setState(() => _openingAiTools = true);
    try {
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) => _AiRealtimeActionSheet(user: user),
      );
    } finally {
      if (mounted) {
        setState(() => _openingAiTools = false);
      }
    }
  }
}

class _AiRealtimeActionSheet extends ConsumerWidget {
  const _AiRealtimeActionSheet({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x4,
          0,
          AppSpacing.x4,
          AppSpacing.x4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Trợ lý AI luyện tập',
              style: AppTypography.headerMediumFor(context),
            ),
            const SizedBox(height: AppSpacing.x2),
            Text(
              'Mở camera realtime, hỏi coach hoặc tạo lịch tập từ AI team.',
              style: AppTypography.bodySmallFor(context),
            ),
            const SizedBox(height: AppSpacing.x4),
            _AiRealtimeActionTile(
              icon: Icons.psychology_rounded,
              title: 'AI Coach',
              subtitle:
                  'Hỏi nhanh về kỹ thuật tập, phục hồi, lịch tập hoặc thói quen.',
              onTap: () => _openCoach(context, ref),
            ),
            const SizedBox(height: AppSpacing.x2),
            _AiRealtimeActionTile(
              icon: Icons.auto_awesome_rounded,
              title: 'Tạo lịch tập AI',
              subtitle:
                  'Gửi hồ sơ tập luyện sang Workout Planner để sinh giáo án mới.',
              onTap: () => _openWorkoutPlanner(context, ref),
            ),
            const SizedBox(height: AppSpacing.x2),
            _AiRealtimeActionTile(
              icon: Icons.directions_run_rounded,
              title: 'Kiểm tra form tập',
              subtitle:
                  'Nhận điểm đúng sai và cue sửa động tác theo thời gian thực.',
              onTap: () {
                final router = GoRouter.of(context);
                Navigator.of(context).pop();
                router.push(
                  AppRoutes.aiFormCheckLocation(exerciseId: 'squat'),
                );
              },
            ),
            const SizedBox(height: AppSpacing.x2),
            _AiRealtimeActionTile(
              icon: Icons.accessibility_new_rounded,
              title: 'Phân tích dáng người',
              subtitle:
                  'Cập nhật posture, imbalance và gợi ý cá nhân liên tục.',
              onTap: () {
                final router = GoRouter.of(context);
                Navigator.of(context).pop();
                router.push(AppRoutes.aiBodyAnalysis);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCoach(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _AiCoachSheet(
        user: user,
        onSubmit: ref.read(aiRecommendationRepositoryProvider).askCoach,
      ),
    );
  }

  Future<void> _openWorkoutPlanner(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _AiWorkoutPlannerSheet(
        user: user,
        onSubmit:
            ref.read(aiRecommendationRepositoryProvider).createWorkoutPlan,
      ),
    );
  }
}

class _AiCoachSheet extends StatefulWidget {
  const _AiCoachSheet({
    required this.user,
    required this.onSubmit,
  });

  final UserModel user;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic> payload)
      onSubmit;

  @override
  State<_AiCoachSheet> createState() => _AiCoachSheetState();
}

class _AiCoachSheetState extends State<_AiCoachSheet> {
  late final TextEditingController _questionController;
  late final TextEditingController _ageController;
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  late final TextEditingController _activityController;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController();
    _ageController = TextEditingController(
      text: _ageFromDate(widget.user.dateOfBirth).toString(),
    );
    _weightController = TextEditingController(text: '70');
    _heightController = TextEditingController(text: '170');
    _activityController = TextEditingController(text: 'moderate');
  }

  @override
  void dispose() {
    _questionController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _activityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading || _questionController.text.trim().isEmpty) {
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await widget.onSubmit({
        ..._aiProfilePayload(
          widget.user,
          age: int.tryParse(_ageController.text) ?? 25,
          weight: double.tryParse(_weightController.text) ?? 70,
          height: double.tryParse(_heightController.text) ?? 170,
          activityLevel: _activityController.text.trim(),
        ),
        'question': _questionController.text.trim(),
      });
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) => _AiJsonResultSheet(
          title: 'AI Coach',
          result: result,
        ),
      );
    } catch (error) {
      if (mounted) {
        AppFeedback.error(error.toString(), title: 'AI Coach chưa phản hồi');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AiFormShell(
      title: 'AI Coach',
      loading: _loading,
      submitLabel: 'Hỏi coach',
      onSubmit: _submit,
      children: [
        TextField(
          controller: _questionController,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Câu hỏi',
            prefixIcon: Icon(Icons.psychology_rounded),
          ),
        ),
        const SizedBox(height: AppSpacing.x3),
        _AiProfileInputs(
          ageController: _ageController,
          weightController: _weightController,
          heightController: _heightController,
          activityController: _activityController,
        ),
      ],
    );
  }
}

class _AiWorkoutPlannerSheet extends StatefulWidget {
  const _AiWorkoutPlannerSheet({
    required this.user,
    required this.onSubmit,
  });

  final UserModel user;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic> payload)
      onSubmit;

  @override
  State<_AiWorkoutPlannerSheet> createState() => _AiWorkoutPlannerSheetState();
}

class _AiWorkoutPlannerSheetState extends State<_AiWorkoutPlannerSheet> {
  late final TextEditingController _ageController;
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  late final TextEditingController _activityController;
  late final TextEditingController _levelController;
  late final TextEditingController _daysController;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _ageController = TextEditingController(
      text: _ageFromDate(widget.user.dateOfBirth).toString(),
    );
    _weightController = TextEditingController(text: '70');
    _heightController = TextEditingController(text: '170');
    _activityController = TextEditingController(text: 'moderate');
    _levelController = TextEditingController(text: 'beginner');
    _daysController = TextEditingController(text: '4');
  }

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _activityController.dispose();
    _levelController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final result = await widget.onSubmit({
        ..._aiProfilePayload(
          widget.user,
          age: int.tryParse(_ageController.text) ?? 25,
          weight: double.tryParse(_weightController.text) ?? 70,
          height: double.tryParse(_heightController.text) ?? 170,
          activityLevel: _activityController.text.trim(),
        ),
        'level': _levelController.text.trim().isEmpty
            ? 'beginner'
            : _levelController.text.trim(),
        'days_per_week': int.tryParse(_daysController.text) ?? 4,
      });
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (context) => _AiJsonResultSheet(
          title: 'Lịch tập AI',
          result: result,
        ),
      );
    } catch (error) {
      if (mounted) {
        AppFeedback.error(error.toString(), title: 'Chưa tạo được lịch tập AI');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AiFormShell(
      title: 'Tạo lịch tập AI',
      loading: _loading,
      submitLabel: 'Tạo lịch tập',
      onSubmit: _submit,
      children: [
        _AiProfileInputs(
          ageController: _ageController,
          weightController: _weightController,
          heightController: _heightController,
          activityController: _activityController,
        ),
        const SizedBox(height: AppSpacing.x3),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _levelController,
                decoration: const InputDecoration(
                  labelText: 'Trình độ',
                  prefixIcon: Icon(Icons.trending_up_rounded),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.x2),
            Expanded(
              child: TextField(
                controller: _daysController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Buổi/tuần',
                  prefixIcon: Icon(Icons.calendar_month_rounded),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AiFormShell extends StatelessWidget {
  const _AiFormShell({
    required this.title,
    required this.loading,
    required this.submitLabel,
    required this.onSubmit,
    required this.children,
  });

  final String title;
  final bool loading;
  final String submitLabel;
  final VoidCallback onSubmit;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: AppResponsive.pagePadding(context).copyWith(
          top: 0,
          bottom: AppSpacing.x4 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: AppTypography.headerMediumFor(context)),
              const SizedBox(height: AppSpacing.x3),
              ...children,
              const SizedBox(height: AppSpacing.x4),
              FilledButton.icon(
                onPressed: loading ? null : onSubmit,
                icon: loading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_rounded),
                label: Text(loading ? 'Đang phân tích...' : submitLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiProfileInputs extends StatelessWidget {
  const _AiProfileInputs({
    required this.ageController,
    required this.weightController,
    required this.heightController,
    required this.activityController,
  });

  final TextEditingController ageController;
  final TextEditingController weightController;
  final TextEditingController heightController;
  final TextEditingController activityController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Tuổi'),
              ),
            ),
            const SizedBox(width: AppSpacing.x2),
            Expanded(
              child: TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Cân nặng kg'),
              ),
            ),
            const SizedBox(width: AppSpacing.x2),
            Expanded(
              child: TextField(
                controller: heightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Cao cm'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x3),
        TextField(
          controller: activityController,
          decoration: const InputDecoration(
            labelText: 'Mức vận động',
            prefixIcon: Icon(Icons.directions_run_rounded),
          ),
        ),
      ],
    );
  }
}

class _AiJsonResultSheet extends StatelessWidget {
  const _AiJsonResultSheet({
    required this.title,
    required this.result,
  });

  final String title;
  final Map<String, dynamic> result;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: AppResponsive.pagePadding(context).copyWith(top: 0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: AppTypography.headerMediumFor(context)),
              const SizedBox(height: AppSpacing.x3),
              ...result.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.x2),
                  child: _AiResultRow(
                    label: entry.key,
                    value: _formatAiValue(entry.value),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.x3),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Xong'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiResultRow extends StatelessWidget {
  const _AiResultRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.label(color: scheme.primary)),
          const SizedBox(height: 4),
          Text(value, style: AppTypography.bodyFor(context)),
        ],
      ),
    );
  }
}

Map<String, dynamic> _aiProfilePayload(
  UserModel user, {
  required int age,
  required double weight,
  required double height,
  required String activityLevel,
}) {
  final goal =
      user.goalType == null ? 'general fitness' : goalLabel(user.goalType!);
  final gender = user.gender == null ? 'other' : genderLabel(user.gender!);
  return {
    'age': age,
    'gender': gender,
    'weight': weight,
    'height': height,
    'goal': goal,
    'activity_level': activityLevel.isEmpty ? 'moderate' : activityLevel,
  };
}

int _ageFromDate(DateTime? dateOfBirth) {
  if (dateOfBirth == null) {
    return 25;
  }
  final now = DateTime.now();
  var age = now.year - dateOfBirth.year;
  if (now.month < dateOfBirth.month ||
      (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
    age--;
  }
  return age.clamp(13, 100);
}

String _formatAiValue(Object? value) {
  if (value is Map) {
    return value.entries
        .map((entry) => '${entry.key}: ${_formatAiValue(entry.value)}')
        .join('\n');
  }
  if (value is Iterable) {
    return value.map(_formatAiValue).join('\n');
  }
  return value?.toString() ?? '-';
}

class _AiRealtimeActionTile extends StatelessWidget {
  const _AiRealtimeActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.primaryOf(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.input),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.x3),
        decoration: BoxDecoration(
          color: AppColors.surface1Of(context),
          borderRadius: BorderRadius.circular(AppRadius.input),
          border: Border.all(color: AppColors.borderSubtleOf(context)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: AppSpacing.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.label()),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypography.bodySmallFor(context)),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.x2),
            Icon(Icons.chevron_right_rounded, color: color),
          ],
        ),
      ),
    );
  }
}

class LoginRequiredModal extends StatelessWidget {
  const LoginRequiredModal({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.login_rounded),
      title: const Text('Đăng nhập để sử dụng AI Scan'),
      content: const Text(
        'Đăng nhập tài khoản để mở khóa tính năng AI Scan Body của V-FIT.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Để sau'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            context.go('/login');
          },
          child: const Text('Đăng nhập ngay'),
        ),
      ],
    );
  }
}

class VipRequiredModal extends StatelessWidget {
  const VipRequiredModal({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.workspace_premium_rounded),
      title: const Text('Tính năng dành cho V-FIT VIP'),
      content: const Text(
        'Nâng cấp VIP để sử dụng AI Scan Body, phân tích cơ thể và giáo án cá nhân hóa.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Để sau'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            context.go('/premium');
          },
          child: const Text('Nâng cấp VIP'),
        ),
      ],
    );
  }
}

// Shared card structure used by LoginToSetGoalState and GoalRequiredState.
// Both states have identical layout: icon-container, gradient card, title,
// body text, and a full-width primary CTA button.
class _CallToActionCard extends StatelessWidget {
  const _CallToActionCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.body,
    required this.buttonLabel,
    required this.buttonIcon,
    required this.onPressed,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String body;
  final String buttonLabel;
  final IconData buttonIcon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.large),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface2Of(context),
            AppColors.surface1Of(context),
            accent.withValues(
              alpha: AppColors.isDark(context) ? 0.08 : 0.05,
            ),
          ],
        ),
        border: Border.all(
          color: accent.withValues(alpha: 0.34),
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.input),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.headerMediumFor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x3),
          Text(body, style: AppTypography.bodyFor(context)),
          const SizedBox(height: AppSpacing.x4),
          AppButton.primary(
            label: buttonLabel,
            icon: buttonIcon,
            fullWidth: true,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}

class LoginToSetGoalState extends StatelessWidget {
  const LoginToSetGoalState({super.key});

  @override
  Widget build(BuildContext context) {
    return _CallToActionCard(
      icon: Icons.login_rounded,
      accent: AppColors.primaryOf(context),
      title: 'Đăng nhập để tạo lịch tập',
      body:
          'Lịch tập là tính năng miễn phí, nhưng V-FIT cần biết mục tiêu của bạn để tạo đúng một lịch phù hợp.',
      buttonLabel: 'Đăng nhập để thiết lập mục tiêu',
      buttonIcon: Icons.login_rounded,
      onPressed: () => context.go('/login'),
    );
  }
}

class GoalRequiredState extends StatelessWidget {
  const GoalRequiredState({super.key});

  @override
  Widget build(BuildContext context) {
    return _CallToActionCard(
      icon: Icons.flag_rounded,
      accent: AppColors.limePerformance,
      title: 'Chưa có lịch tập cá nhân',
      body:
          'Thiết lập mục tiêu luyện tập để V-FIT tạo đúng một lịch theo mục tiêu của bạn.',
      buttonLabel: 'Thiết lập mục tiêu luyện tập',
      buttonIcon: Icons.tune_rounded,
      onPressed: () => context.push('/profile/edit'),
    );
  }
}

class PersonalizedWorkoutView extends ConsumerWidget {
  const PersonalizedWorkoutView({super.key});

  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<PersonalizedWorkoutBloc>();
    bloc.add(const PersonalizedWorkoutRequested(forceRefresh: true));
    await bloc.stream.firstWhere((state) => state is! WorkoutLoading);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPendingOnboarding =
        ref.watch(authControllerProvider).isPendingOnboarding;
    if (isPendingOnboarding) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        children: const [PendingOnboardingPlaceholder()],
      );
    }

    return BlocBuilder<PersonalizedWorkoutBloc, PersonalizedWorkoutState>(
      builder: (context, state) {
        if (state is WorkoutInitial || state is WorkoutLoading) {
          return const LoadingView();
        }

        if (state is WorkoutUnconfigured) {
          return ListView(
            padding: AppResponsive.pagePadding(context),
            children: const [GoalRequiredState()],
          );
        }

        if (state is! WorkoutLoaded) {
          return ErrorView(
            message: 'Không thể tải lịch tập cá nhân.',
            onRetry: () => context
                .read<PersonalizedWorkoutBloc>()
                .add(const PersonalizedWorkoutRequested(forceRefresh: true)),
          );
        }

        final plan = state.plan;
        return RefreshIndicator(
          onRefresh: () => _refresh(context),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              if (plan.isStale == true)
                _InfoNote(
                  icon: Icons.wifi_off_rounded,
                  message:
                      'Đang hiển thị dữ liệu đã lưu vì chưa kết nối được máy chủ.',
                  isWarning: true,
                ),
              if (state.errorMessage != null)
                _InfoNote(
                  icon: Icons.warning_amber_rounded,
                  message: state.errorMessage!,
                  isWarning: true,
                ),
              PersonalWorkoutPlanWidget(plan: plan),
            ],
          ),
        );
      },
    );
  }
}

class _InfoNote extends StatelessWidget {
  const _InfoNote({
    required this.icon,
    required this.message,
    this.isWarning = false,
  });

  final IconData icon;
  final String message;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final color = isWarning ? AppColors.warning : AppColors.primaryOf(context);
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppResponsive.horizontalPadding(context),
        vertical: AppSpacing.x2,
      ),
      padding: const EdgeInsets.all(AppSpacing.x3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.x2),
          Expanded(
            child: Text(message, style: AppTypography.bodyFor(context)),
          ),
        ],
      ),
    );
  }
}
