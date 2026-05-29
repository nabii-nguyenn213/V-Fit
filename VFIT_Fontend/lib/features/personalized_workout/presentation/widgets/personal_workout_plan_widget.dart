import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_radius.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../../exercise_library/domain/entities/exercise_catalog.dart';
import '../../../exercise_library/presentation/bloc/exercise_library_bloc.dart';
import '../../../exercise_library/presentation/widgets/exercise_detail_sheet.dart';
import '../../domain/entities/personalized_workout.dart';
import '../notifiers/workout_session_notifier.dart';
import 'weekly_selector_widget.dart';

class PersonalWorkoutPlanWidget extends ConsumerStatefulWidget {
  const PersonalWorkoutPlanWidget({
    super.key,
    required this.plan,
  });

  final PersonalizedWorkout plan;

  @override
  ConsumerState<PersonalWorkoutPlanWidget> createState() =>
      _PersonalWorkoutPlanWidgetState();
}

class _PersonalWorkoutPlanWidgetState
    extends ConsumerState<PersonalWorkoutPlanWidget> {
  late int _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now().weekday;
  }

  // Lookup để lấy chi tiết Exercise từ Thư viện bài tập (được load bởi ExerciseLibraryBloc)
  ExerciseItem? _lookupExercise(BuildContext context, String exerciseId) {
    try {
      final libraryState = context.read<ExerciseLibraryBloc>().state;
      final catalog = libraryState.catalog;
      if (catalog != null) {
        for (final group in catalog.groups) {
          for (final subGroup in group.subGroups) {
            for (final exercise in subGroup.exercises) {
              if (exercise.id == exerciseId) {
                return exercise;
              }
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  // Fallback khi không tìm thấy exercise trong catalog cục bộ
  ExerciseItem _getFallbackExercise(String exerciseId) {
    // Trả về ExerciseItem có tên readable tương ứng từ catalog ID
    final name = exerciseId
        .split('-')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');

    return ExerciseItem(
      id: exerciseId,
      name: name,
      equipment: const ['Dụng cụ chuyên nghiệp'],
      videoSearchHint: 'Tìm kiếm hướng dẫn tập $name',
    );
  }

  void _showExerciseDetail(BuildContext context, String exerciseId) {
    final resolvedExercise = _lookupExercise(context, exerciseId) ??
        _getFallbackExercise(exerciseId);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExerciseDetailSheet(exercise: resolvedExercise),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final scheduleMap = widget.plan.schedule ?? const {};
    final daySchedule = scheduleMap[_selectedDay];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Thanh Chọn Thứ Trong Tuần ─────────────────────────────────
        WeeklySelectorWidget(
          selectedDay: _selectedDay,
          onDaySelected: (day) => setState(() => _selectedDay = day),
        ),
        const SizedBox(height: 8),

        if (daySchedule == null)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppResponsive.horizontalPadding(context),
              vertical: 24,
            ),
            child: const Text(
              'Không tìm thấy lịch trình cho ngày này.',
              textAlign: TextAlign.center,
            ),
          )
        else ...[
          // ── Header Lịch Tập Trong Ngày ──────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppResponsive.horizontalPadding(context),
              vertical: 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        daySchedule.dayType,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: scheme.primary,
                                ),
                      ),
                      if (daySchedule.restDay) ...[
                        const SizedBox(height: 4),
                        Text(
                          daySchedule.cardioAfterWorkout ??
                              'Nghỉ ngơi và phục hồi hoàn toàn',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (daySchedule.restDay)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color:
                              const Color(0xFF10B981).withValues(alpha: 0.3)),
                    ),
                    child: const Text(
                      'NGHỈ PHỤC HỒI',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  )
                else
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: scheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '${daySchedule.exercises.length} BÀI TẬP',
                      style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Danh sách bài tập hoặc màn hình nghỉ ──────────────────────
          if (daySchedule.restDay)
            _buildRestDaySection(context, daySchedule)
          else ...[
            // RIR & Rest Rules Cards
            if (widget.plan.rules != null) ...[
              _buildRulesSection(context, widget.plan.rules!),
              const SizedBox(height: 16),
            ],

            // Exercise Drill-Down Cards
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppResponsive.horizontalPadding(context),
              ),
              child: Text(
                'DANH SÁCH BÀI TẬP',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 8),

            Builder(builder: (ctx) {
                final isToday = _selectedDay == DateTime.now().weekday;
                final exerciseIds = daySchedule.exercises
                    .map((e) => e.exerciseId)
                    .toList();
                final session = ref.watch(workoutSessionProvider(exerciseIds));
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.only(
                        left: AppResponsive.horizontalPadding(ctx),
                        right: AppResponsive.horizontalPadding(ctx),
                        bottom: 12,
                      ),
                      itemCount: daySchedule.exercises.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                      itemBuilder: (ctx2, index) {
                        final exerciseMeta = daySchedule.exercises[index];
                        final exerciseDetails =
                            _lookupExercise(ctx2, exerciseMeta.exerciseId);
                        final displayName = exerciseDetails?.name ??
                            exerciseMeta.exerciseId
                                .split('-')
                                .map((w) => w.isNotEmpty
                                    ? '${w[0].toUpperCase()}${w.substring(1)}'
                                    : '')
                                .join(' ');
                        return _buildExerciseCard(
                          context: ctx2,
                          meta: exerciseMeta,
                          displayName: displayName,
                          details: exerciseDetails,
                          session: session,
                          isToday: isToday,
                          onTick: () => _handleTick(
                            ctx2,
                            exerciseMeta.exerciseId,
                            exerciseIds,
                            session,
                          ),
                        );
                      },
                    ),
                    if (session.allDone)
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppResponsive.horizontalPadding(ctx),
                        ),
                        child: _WorkoutDoneBanner(
                          isSubmitting: session.isSubmitting,
                          submitted: session.submitted,
                        ),
                      ),
                  ],
                );
              }),

            if (daySchedule.cardioAfterWorkout != null) ...[
              _buildCardioBanner(context, daySchedule.cardioAfterWorkout!),
              const SizedBox(height: 20),
            ],
          ],

          // ── Dinh Dưỡng & Phục Hồi Target ─────────────────────────────
          if (widget.plan.nutritionRecovery != null) ...[
            _buildNutritionSection(context, widget.plan.nutritionRecovery!),
            const SizedBox(height: 32),
          ],
        ],
      ],
    );
  }

  Widget _buildRestDaySection(BuildContext context, DaySchedule schedule) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppResponsive.horizontalPadding(context),
        vertical: 12,
      ),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.hotel_rounded,
            size: 64,
            color: scheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Hôm nay là ngày Nghỉ ngơi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            schedule.cardioAfterWorkout ??
                'Cơ bắp phát triển trong lúc nghỉ ngơi. Hãy ngủ đủ giấc, bổ sung dinh dưỡng đầy đủ và chuẩn bị cho buổi tập tiếp theo.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRulesSection(BuildContext context, WorkoutRules rules) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppResponsive.horizontalPadding(context),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildRuleCard(
              context,
              title: 'Bài Compound (Đa khớp)',
              reps: rules.compound.reps,
              rest: rules.compound.rest,
              rir: rules.compound.rir,
              iconColor: scheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildRuleCard(
              context,
              title: 'Bài Isolation (Đơn khớp)',
              reps: rules.isolation.reps,
              rest: rules.isolation.rest,
              rir: rules.isolation.rir,
              iconColor: scheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleCard(
    BuildContext context, {
    required String title,
    required String reps,
    required String rest,
    required String rir,
    required Color iconColor,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          _buildRuleItem(Icons.repeat_rounded, 'Reps: $reps', iconColor),
          const SizedBox(height: 4),
          _buildRuleItem(Icons.timer_rounded, 'Nghỉ: $rest', iconColor),
          const SizedBox(height: 4),
          _buildRuleItem(Icons.bolt_rounded, 'RIR: $rir', iconColor),
        ],
      ),
    );
  }

  Widget _buildRuleItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseCard({
    required BuildContext context,
    required ExerciseItemMetadata meta,
    required String displayName,
    required ExerciseItem? details,
    required WorkoutSessionState session,
    required bool isToday,
    required VoidCallback onTick,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      child: InkWell(
        onTap: () => _showExerciseDetail(context, meta.exerciseId),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              // Exercise visual / index badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    Icons.fitness_center_rounded,
                    color: scheme.primary,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Title and metadata detail
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildBadge(context, '${meta.sets} sets'),
                        const SizedBox(width: 6),
                        _buildBadge(context, '${meta.reps} reps'),
                      ],
                    ),
                    if (meta.notes != null && meta.notes!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        meta.notes!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Arrow indicator / Done / cooldown button
              if (!isToday)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Icon(
                    Icons.lock_rounded,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                    size: 18,
                  ),
                )
              else if (session.isDone(meta.exerciseId))
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.success,
                    size: 20,
                  ),
                )
              else
                _CooldownButton(
                  cooldown: session.cooldownRemaining(),
                  onTap: onTick,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Cooldown tick handler
  // ------------------------------------------------------------------
  void _handleTick(
    BuildContext context,
    String exerciseId,
    List<String> exerciseIds,
    WorkoutSessionState session,
  ) {
    final notifier =
        ref.read(workoutSessionProvider(exerciseIds).notifier);
    final accepted = notifier.markDone(exerciseId);
    if (!accepted) {
      final remaining = session.cooldownRemaining();
      if (remaining != null) {
        final mins = remaining.inMinutes;
        final secs =
            (remaining.inSeconds % 60).toString().padLeft(2, '0');
        AppFeedback.info(
          'Cần chờ $mins:$secs nữa trước khi đánh dấu bài tiếp theo.',
          title: 'Nghỉ giữa hiệp',
        );
      }
    }
  }

  Widget _buildBadge(BuildContext context, String label) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildCardioBanner(BuildContext context, String cardioText) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppResponsive.horizontalPadding(context),
        vertical: 8,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.directions_run_rounded, color: scheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              cardioText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionSection(
      BuildContext context, NutritionRecovery nutrition) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppResponsive.horizontalPadding(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DINH DƯỠNG & PHỤC HỒI HÀNG NGÀY',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: scheme.onSurfaceVariant,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildNutritionTile(
                        context,
                        icon: Icons.local_fire_department_rounded,
                        label: 'Năng Lượng',
                        value: nutrition.caloriesTarget,
                        color: Colors.orange,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 48,
                      color: scheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                    Expanded(
                      child: _buildNutritionTile(
                        context,
                        icon: Icons.fitness_center_rounded,
                        label: 'Protein',
                        value: nutrition.proteinTarget,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                Divider(
                    height: 24,
                    color: scheme.outlineVariant.withValues(alpha: 0.4)),
                Row(
                  children: [
                    Expanded(
                      child: _buildNutritionTile(
                        context,
                        icon: Icons.bedtime_rounded,
                        label: 'Ngủ Đủ Giấc',
                        value: nutrition.sleepTarget,
                        color: Colors.indigo,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 48,
                      color: scheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                    Expanded(
                      child: _buildNutritionTile(
                        context,
                        icon: Icons.water_drop_rounded,
                        label: 'Uống Nước',
                        value: nutrition.waterTarget ?? '2.5 - 4.0 Lít',
                        color: Colors.teal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _CooldownButton — "Xong" tap target, or a live countdown when in cooldown
// ---------------------------------------------------------------------------

class _CooldownButton extends StatefulWidget {
  const _CooldownButton({required this.cooldown, required this.onTap});

  /// Remaining cooldown, or null when the user can tick immediately.
  final Duration? cooldown;
  final VoidCallback onTap;

  @override
  State<_CooldownButton> createState() => _CooldownButtonState();
}

class _CooldownButtonState extends State<_CooldownButton> {
  Timer? _timer;
  Duration? _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.cooldown;
    if (_remaining != null) _startTick();
  }

  @override
  void didUpdateWidget(_CooldownButton old) {
    super.didUpdateWidget(old);
    if (widget.cooldown == null) {
      _timer?.cancel();
      setState(() => _remaining = null);
    } else if (old.cooldown == null && widget.cooldown != null) {
      setState(() => _remaining = widget.cooldown);
      _startTick();
    }
  }

  void _startTick() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        final r = _remaining;
        if (r == null || r.inSeconds <= 1) {
          _remaining = null;
          _timer?.cancel();
        } else {
          _remaining = r - const Duration(seconds: 1);
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _remaining;
    final canTick = remaining == null;

    if (canTick) {
      return GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primaryOf(context).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: AppColors.primaryOf(context).withValues(alpha: 0.2),
            ),
          ),
          child: Icon(
            Icons.radio_button_unchecked_rounded,
            color: AppColors.primaryOf(context).withValues(alpha: 0.7),
            size: 22,
          ),
        ),
      );
    }

    // Cooldown active — show MM:SS countdown badge
    final mins = remaining.inMinutes;
    final secs = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$mins:$secs',
        style: AppTypography.label(color: AppColors.warning),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _WorkoutDoneBanner — shown below the list when all exercises are ticked
// ---------------------------------------------------------------------------

class _WorkoutDoneBanner extends StatelessWidget {
  const _WorkoutDoneBanner({
    required this.isSubmitting,
    required this.submitted,
  });

  final bool isSubmitting;
  final bool submitted;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 340),
      margin: const EdgeInsets.only(bottom: AppSpacing.x4),
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.36),
        ),
      ),
      child: Row(
        children: [
          if (isSubmitting)
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppColors.success,
              ),
            )
          else
            const Icon(
              Icons.celebration_rounded,
              color: AppColors.success,
              size: 28,
            ),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  submitted
                      ? 'Buổi tập hôm nay đã được ghi nhận!'
                      : 'Hoàn thành tất cả bài tập!',
                  style: AppTypography.headerMedium(
                    color: AppColors.success,
                  ),
                ),
                if (submitted)
                  Text(
                    'Streak thử thách của bạn đã được cập nhật.',
                    style: AppTypography.bodySmall(
                      color: AppColors.success.withValues(alpha: 0.8),
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
