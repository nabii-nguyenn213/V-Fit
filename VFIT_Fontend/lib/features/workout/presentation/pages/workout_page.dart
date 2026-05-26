import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_radius.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
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
                  'Workout Space',
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
        AppCard(
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryOf(context).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.input),
                ),
                child: Icon(
                  Icons.local_library_rounded,
                  color: AppColors.primaryOf(context),
                ),
              ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bài tập cơ bản vẫn miễn phí',
                      style: AppTypography.headerMediumFor(context),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bạn có thể xem thư viện bài tập và video hướng dẫn. Lịch tập chỉ được tạo sau khi có mục tiêu.',
                      style: AppTypography.bodySmallFor(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
  bool _openingCamera = false;

  @override
  Widget build(BuildContext context) {
    final isVip = widget.user?.isVipActive == true;
    final accent = isVip ? AppColors.success : AppColors.energyMagenta;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.large),
      onTap: _openingCamera ? null : _handlePressed,
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
              child: _openingCamera
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
                    'Scan Body AI',
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

    setState(() => _openingCamera = true);
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.camera);
      if (!mounted || image == null) {
        return;
      }
      AppFeedback.success(
        'Da nhan anh scan. AI analysis se xu ly o buoc tiep theo.',
      );
    } catch (error) {
      if (mounted) {
        AppFeedback.error('Không thể mở camera: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _openingCamera = false);
      }
    }
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

class LoginToSetGoalState extends StatelessWidget {
  const LoginToSetGoalState({super.key});

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
            AppColors.primaryOf(context).withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(
          color: AppColors.primaryOf(context).withValues(alpha: 0.34),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOf(context).withValues(alpha: 0.12),
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
                  color: AppColors.primaryOf(context).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.input),
                ),
                child: Icon(
                  Icons.login_rounded,
                  color: AppColors.primaryOf(context),
                ),
              ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: Text(
                  'Đăng nhập để tạo lịch tập',
                  style: AppTypography.headerMediumFor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x3),
          Text(
            'Lịch tập là tính năng miễn phí, nhưng V-FIT cần biết mục tiêu của bạn để tạo đúng một lịch phù hợp.',
            style: AppTypography.bodyFor(context),
          ),
          const SizedBox(height: AppSpacing.x4),
          AppButton.primary(
            label: 'Đăng nhập để thiết lập mục tiêu',
            icon: Icons.login_rounded,
            fullWidth: true,
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
    );
  }
}

class GoalRequiredState extends StatelessWidget {
  const GoalRequiredState({super.key});

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
            AppColors.limePerformance.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(
          color: AppColors.limePerformance.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.limePerformance.withValues(alpha: 0.1),
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
                  color: AppColors.limePerformance.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.input),
                ),
                child: const Icon(
                  Icons.flag_rounded,
                  color: AppColors.limePerformance,
                ),
              ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: Text(
                  'Chưa có lịch tập cá nhân',
                  style: AppTypography.headerMediumFor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x2),
          Text(
            'Thiết lập mục tiêu luyện tập để V-FIT tạo đúng một lịch theo mục tiêu của bạn.',
            style: AppTypography.bodyFor(context),
          ),
          const SizedBox(height: AppSpacing.x4),
          AppButton.primary(
            label: 'Thiết lập mục tiêu luyện tập',
            icon: Icons.tune_rounded,
            fullWidth: true,
            onPressed: () => context.push('/profile/edit'),
          ),
        ],
      ),
    );
  }
}

class PersonalizedWorkoutView extends StatelessWidget {
  const PersonalizedWorkoutView({super.key});

  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<PersonalizedWorkoutBloc>();
    bloc.add(const PersonalizedWorkoutRequested(forceRefresh: true));
    await bloc.stream.firstWhere((state) => state is! WorkoutLoading);
  }

  @override
  Widget build(BuildContext context) {
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
