import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/flashy_vip_required_modal.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_radius.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
// import '../../../ai/data/repositories/ai_recommendation_repository.dart'; // AI repository removed
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
    final isVip = user?.isVipActive == true;
    final isAiApplied = isVip && (ref.watch(isAiWorkoutPlanAppliedProvider).value ?? false);

    return MultiBlocProvider(
      key: ValueKey('${user?.goalType}_$isAiApplied'),
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
            )..add(PersonalizedWorkoutRequested(isVip: isVip)),
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
        builder: (context) => const FlashyVipRequiredModal(),
      );
      return;
    }

    setState(() => _openingAiTools = true);
    try {
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (ctx) => _AiToolsSheet(user: user),
      );
    } finally {
      if (mounted) {
        setState(() => _openingAiTools = false);
      }
    }
  }
}


class _AiToolsSheet extends StatelessWidget {
  const _AiToolsSheet({required this.user});

  final dynamic user;

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
            Text(
              'Công cụ AI',
              style: AppTypography.headerMediumFor(context),
            ),
            const SizedBox(height: AppSpacing.x1),
            Text(
              'Chọn tính năng AI bạn muốn sử dụng.',
              style: AppTypography.bodySmallFor(context),
            ),
            const SizedBox(height: AppSpacing.x4),
            _AiToolTile(
              icon: Icons.accessibility_new_rounded,
              title: 'Quét cơ thể AI',
              subtitle: 'Phân tích hình thể, tư thế và cân bằng cơ thể realtime.',
              accentColor: AppColors.success,
              onTap: () {
                Navigator.of(context).pop();
                context.push(AppRoutes.aiBodyAnalysis);
              },
            ),
            const SizedBox(height: AppSpacing.x3),
            _AiToolTile(
              icon: Icons.sports_gymnastics_rounded,
              title: 'Kiểm tra form tập',
              subtitle: 'AI phân tích tư thế bài tập theo thời gian thực.',
              accentColor: AppColors.primaryOf(context),
              onTap: () {
                Navigator.of(context).pop();
                context.push(
                  AppRoutes.aiFormCheckLocation(exerciseId: 'squat'),
                );
              },
            ),
            const SizedBox(height: AppSpacing.x4),
          ],
        ),
        ),
      ),
    );
  }
}

class _AiToolTile extends StatelessWidget {
  const _AiToolTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.input),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.x4),
        decoration: BoxDecoration(
          color: AppColors.surface1Of(context),
          borderRadius: BorderRadius.circular(AppRadius.input),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.36),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: Icon(icon, color: accentColor),
            ),
            const SizedBox(width: AppSpacing.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.label()),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmallFor(context),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.x2),
            Icon(Icons.chevron_right_rounded, color: accentColor),
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

  Future<void> _refresh(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authControllerProvider).user;
    final isVip = user?.isVipActive == true;
    final bloc = context.read<PersonalizedWorkoutBloc>();
    bloc.add(PersonalizedWorkoutRequested(forceRefresh: true, isVip: isVip));
    await bloc.stream.firstWhere((state) => state is! WorkoutLoading);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final isPendingOnboarding =
        ref.watch(authControllerProvider).isPendingOnboarding;
    if (isPendingOnboarding) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        children: const [PendingOnboardingPlaceholder()],
      );
    }

    final isVip = user?.isVipActive == true;
    final isAiApplied = isVip && (ref.watch(isAiWorkoutPlanAppliedProvider).value ?? false);

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
                .add(PersonalizedWorkoutRequested(forceRefresh: true, isVip: isVip)),
          );
        }

        final plan = state.plan;
        return RefreshIndicator(
          onRefresh: () => _refresh(context, ref),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              if (isAiApplied)
                _InfoNote(
                  icon: Icons.auto_awesome_rounded,
                  message: 'Bạn đang sử dụng lịch tập cá nhân hóa do AI đề xuất.',
                  action: TextButton(
                    onPressed: () async {
                      await ref.read(personalizedWorkoutRepositoryProvider).revertAiPlan();
                      ref.invalidate(isAiWorkoutPlanAppliedProvider);
                    },
                    child: const Text(
                      'Hủy áp dụng',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                    ),
                  ),
                ),
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
    this.action,
  });

  final IconData icon;
  final String message;
  final bool isWarning;
  final Widget? action;

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
          if (action != null) ...[
            const SizedBox(width: AppSpacing.x2),
            action!,
          ],
        ],
      ),
    );
  }
}
