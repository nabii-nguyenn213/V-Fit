import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

class WorkoutPage extends ConsumerStatefulWidget {
  const WorkoutPage({super.key});

  @override
  ConsumerState<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends ConsumerState<WorkoutPage> {
  int _selectedTab = 0; // 0: Lịch Tập Cá Nhân, 1: Thư Viện Bài Tập

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;

    return MultiBlocProvider(
      key: ValueKey(user?.goalType),
      providers: [
        BlocProvider<ExerciseLibraryBloc>(
          create: (_) =>
              ExerciseLibraryBloc(ref.read(getExerciseCatalogProvider))
                ..add(const ExerciseLibraryRequested()),
        ),
        BlocProvider<PersonalizedWorkoutBloc>(
          create: (_) =>
              PersonalizedWorkoutBloc(ref.read(getPersonalizedWorkoutProvider))
                ..add(const PersonalizedWorkoutRequested()),
        ),
      ],
      child: Scaffold(
        body: SafeArea(
          child: BlocBuilder<PersonalizedWorkoutBloc, PersonalizedWorkoutState>(
            builder: (context, state) {
              if (state is WorkoutInitial || state is WorkoutLoading) {
                return const LoadingView();
              }

              if (state is WorkoutUnconfigured) {
                // Trạng thái Bỏ Qua / Chưa Cấu Hình: Hiển thị giao diện chặn thông minh với NestedScrollView
                return NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Header ──
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.x5,
                                AppSpacing.x5,
                                AppSpacing.x5,
                                AppSpacing.x2,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Workout Space',
                                    style:
                                        AppTypography.headerLargeFor(context),
                                  ),
                                  Icon(
                                    Icons.fitness_center_rounded,
                                    size: 28,
                                    color: AppColors.primaryOf(context),
                                  ),
                                ],
                              ),
                            ),

                            // ── Onboarding Gateway Banner ──
                            _buildOnboardingGateway(context),

                            const SizedBox(height: 12),
                            // Thư viện bài tập header phân tách đại trà
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              child: Text(
                                'TẤT CẢ BÀI TẬP ĐẠI TRÀ',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ];
                  },
                  body: const ExerciseLibraryView(
                    key: PageStorageKey('exercise-library-unconfigured-key'),
                  ),
                );
              }

              // Trạng thái WorkoutLoaded: Kích hoạt đầy đủ Tab Bar
              final loadedState = state as WorkoutLoaded;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header Premium ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Workout Space',
                          style: AppTypography.headerLargeFor(context),
                        ),
                        Icon(
                          Icons.fitness_center_rounded,
                          size: 28,
                          color: AppColors.primaryOf(context),
                        ),
                      ],
                    ),
                  ),

                  // ── Pill Segmented Tab Control ──
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.x5,
                      vertical: AppSpacing.x2,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.x1),
                      decoration: BoxDecoration(
                        color: AppColors.surface1Of(context),
                        borderRadius: BorderRadius.circular(AppRadius.input),
                        border: Border.all(
                          color: AppColors.borderSubtleOf(context),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _TabButton(
                              label: 'Lịch tập cá nhân',
                              icon: Icons.assignment_turned_in_rounded,
                              isSelected: _selectedTab == 0,
                              onTap: () => setState(() => _selectedTab = 0),
                            ),
                          ),
                          Expanded(
                            child: _TabButton(
                              label: 'Thư viện bài tập',
                              icon: Icons.local_library_rounded,
                              isSelected: _selectedTab == 1,
                              onTap: () => setState(() => _selectedTab = 1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Body / Content (Preserving State) ──
                  Expanded(
                    child: IndexedStack(
                      index: _selectedTab,
                      children: [
                        // Tab 0: Lịch Tập Cá Nhân
                        _PersonalPlanTab(
                          planState: loadedState,
                          key: const PageStorageKey('personal-plan-tab-key'),
                        ),

                        // Tab 1: Thư Viện Bài Tập
                        const ExerciseLibraryView(
                          key: PageStorageKey('exercise-library-tab-key'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardingGateway(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x5,
        vertical: AppSpacing.x3,
      ),
      padding: const EdgeInsets.all(AppSpacing.x5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.large),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface2Of(context),
            AppColors.surface1Of(context),
            Color(0xFF0D1C28),
          ],
        ),
        border: Border.all(color: AppColors.borderSubtleOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Visual Hint AI-Generated theme (Barbell, body visual)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.x3),
                decoration: BoxDecoration(
                  color: AppColors.primaryOf(context).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryOf(context).withValues(alpha: 0.28),
                  ),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primaryOf(context),
                  size: 32,
                ),
              ),
              const SizedBox(width: AppSpacing.x4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PERSONAL PLAN',
                      style: AppTypography.label(
                        color: AppColors.limePerformance,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x1),
                    Text(
                      'Thiết lập mục tiêu riêng',
                      style: AppTypography.headerMediumFor(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x4),
          Text(
            'Mở khóa giáo án cá nhân hóa từ chuyên gia V-FIT được thiết kế chuẩn xác theo mục tiêu thể hình của bạn (Tăng cơ hoặc Giảm cân). Hãy bắt đầu hành trình chuyển đổi hình thể ngay hôm nay.',
            style: AppTypography.bodyFor(context),
          ),
          const SizedBox(height: AppSpacing.x5),
          ElevatedButton(
            onPressed: () => context.push('/profile/edit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOf(context),
              foregroundColor: AppColors.onAccentOf(context),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.x4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.input),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bolt_rounded, size: 22),
                SizedBox(width: 8),
                Text(
                  'Thiết lập mục tiêu ngay (Chỉ 30 giây)',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
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

class _PersonalPlanTab extends StatelessWidget {
  const _PersonalPlanTab({
    required this.planState,
    super.key,
  });

  final WorkoutLoaded planState;

  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<PersonalizedWorkoutBloc>();
    bloc.add(const PersonalizedWorkoutRequested(forceRefresh: true));
    await bloc.stream.firstWhere((state) => state is! WorkoutLoading);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final plan = planState.plan;

    return RefreshIndicator(
      onRefresh: () => _refresh(context),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // Offline warning banner
          if (plan.isStale == true)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: scheme.errorContainer.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: scheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.wifi_off_rounded, color: scheme.error, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Đang hiển thị dữ liệu ngoại tuyến',
                      style: TextStyle(
                        color: scheme.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (planState.errorMessage != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      planState.errorMessage!,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          PersonalWorkoutPlanWidget(plan: plan),
        ],
      ),
    );
  }
}
