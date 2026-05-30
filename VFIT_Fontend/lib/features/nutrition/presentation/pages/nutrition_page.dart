import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_radius.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../data/models/food_calorie_estimate_model.dart';
import '../../data/repositories/food_repository_impl.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../../domain/entities/food.dart';
import '../../domain/usecases/remember_food.dart';
import '../../domain/usecases/search_foods.dart';
import '../bloc/nutrition_calculator_bloc.dart';

class NutritionPage extends ConsumerStatefulWidget {
  const NutritionPage({super.key});

  @override
  ConsumerState<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends ConsumerState<NutritionPage> {
  late final TextEditingController _searchController;
  Timer? _debounce;
  bool _scanLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(foodRepositoryProvider);
    return BlocProvider(
      create: (_) => NutritionCalculatorBloc(
        searchFoods: SearchFoods(repository),
        rememberFood: RememberFood(repository),
      )..add(const NutritionSearchRequested('')),
      child: BlocBuilder<NutritionCalculatorBloc, NutritionCalculatorState>(
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () async {
              context
                  .read<NutritionCalculatorBloc>()
                  .add(NutritionSearchRequested(_searchController.text));
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppResponsive.pagePadding(context).copyWith(
                bottom: AppResponsive.pagePadding(context).bottom + 96,
              ),
              children: [
                Text(
                  'Trung tâm dinh dưỡng',
                  style: AppTypography.headerLargeFor(context),
                ),
                const SizedBox(height: AppSpacing.x2),
                Text(
                  'Quét món ăn, tra cứu calo và tính macro trong một workspace gọn.',
                  style: AppTypography.bodySmallFor(context),
                ),
                const SizedBox(height: AppSpacing.x4),
                _FoodScanCard(
                  loading: _scanLoading,
                  onTap: _scanFood,
                ),
                const SizedBox(height: AppSpacing.x4),
                _NutritionSearchBar(
                  controller: _searchController,
                  loading: state.loading,
                  onChanged: (value) => _onSearchChanged(context, value),
                ),
                const SizedBox(height: 18),
                if (state.errorMessage != null)
                  _ErrorStrip(message: state.errorMessage!)
                else if (state.isEmptyResult)
                  _EmptyFoodState(keyword: state.keyword)
                else
                  _FoodListSection(
                    title: state.hasKeyword
                        ? 'Kết quả phù hợp'
                        : 'Món ăn phổ biến cho gymer',
                    foods: state.foods,
                    onFoodTap: (food) => _openCalculator(context, food),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _onSearchChanged(BuildContext context, String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!context.mounted) {
        return;
      }
      context
          .read<NutritionCalculatorBloc>()
          .add(NutritionSearchRequested(value));
    });
  }

  Future<void> _openCalculator(BuildContext context, Food food) async {
    context.read<NutritionCalculatorBloc>().add(NutritionFoodSelected(food));
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => _MacroCalculatorSheet(food: food),
    );
  }

  Future<void> _scanFood() async {
    if (_scanLoading) {
      return;
    }
    setState(() => _scanLoading = true);
    try {
      final estimate =
          await ref.read(nutritionRepositoryProvider).estimateFoodCalories();
      if (!mounted) {
        return;
      }
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) => _FoodEstimateSheet(estimate: estimate),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppFeedback.error(error.toString(), title: 'Không quét được món ăn');
    } finally {
      if (mounted) {
        setState(() => _scanLoading = false);
      }
    }
  }
}

class _FoodScanCard extends StatelessWidget {
  const _FoodScanCard({
    required this.loading,
    required this.onTap,
  });

  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface1Of(context),
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: loading ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.x4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.borderSubtleOf(context)),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.primaryOf(context).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  border: Border.all(
                    color: AppColors.primaryOf(context).withValues(alpha: 0.28),
                  ),
                ),
                child: loading
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryOf(context),
                        ),
                      )
                    : Icon(
                        Icons.document_scanner_rounded,
                        color: AppColors.primaryOf(context),
                        size: 30,
                      ),
              ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quét calo thức ăn',
                      style: AppTypography.headerMediumFor(context),
                    ),
                    const SizedBox(height: AppSpacing.x1),
                    Text(
                      'Mở camera để phân tích và ước tính lượng calo nhanh.',
                      style: AppTypography.bodySmallFor(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.x2),
              FilledButton.icon(
                onPressed: loading ? null : onTap,
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('Quét'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FoodEstimateSheet extends StatelessWidget {
  const _FoodEstimateSheet({required this.estimate});

  final FoodCalorieEstimateModel estimate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final confidence = (estimate.confidence * 100).round();
    return SafeArea(
      child: Padding(
        padding: AppResponsive.pagePadding(context).copyWith(top: 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child:
                      Icon(Icons.auto_awesome_rounded, color: scheme.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        estimate.foodName,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      Text('${estimate.servingSize} - Độ tin cậy $confidence%'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              '${estimate.calories} kcal',
              style: Theme.of(context)
                  .textTheme
                  .displaySmall
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _ScanMacroPill(
                    label: 'Đạm',
                    value: estimate.proteinGrams,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ScanMacroPill(
                    label: 'Tinh bột',
                    value: estimate.carbGrams,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ScanMacroPill(
                    label: 'Chất béo',
                    value: estimate.fatGrams,
                  ),
                ),
              ],
            ),
            if (estimate.notes.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                estimate.notes.first,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Đóng'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanMacroPill extends StatelessWidget {
  const _ScanMacroPill({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(
            '${value.toStringAsFixed(0)}g',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          Text(label, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _NutritionSearchBar extends StatelessWidget {
  const _NutritionSearchBar({
    required this.controller,
    required this.loading,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool loading;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        TextField(
          controller: controller,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Tìm ức gà, gạo lứt, whey...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Xóa',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: loading ? 3 : 0,
          margin: const EdgeInsets.only(top: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              color: scheme.primary,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
        ),
      ],
    );
  }
}

class _FoodListSection extends StatelessWidget {
  const _FoodListSection({
    required this.title,
    required this.foods,
    required this.onFoodTap,
  });

  final String title;
  final List<Food> foods;
  final ValueChanged<Food> onFoodTap;

  @override
  Widget build(BuildContext context) {
    if (foods.isEmpty) {
      return const _FoodSkeletonList();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        ...foods.map(
          (food) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _FoodCard(
              food: food,
              onTap: () => onFoodTap(food),
            ),
          ),
        ),
      ],
    );
  }
}

class _FoodCard extends StatelessWidget {
  const _FoodCard({
    required this.food,
    required this.onTap,
  });

  final Food food;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  food.isGymFriendly
                      ? Icons.fitness_center_rounded
                      : Icons.restaurant_rounded,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            food.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.local_fire_department_rounded,
                          color: Colors.deepOrangeAccent.shade100,
                          size: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _FoodMetric(
                          icon: Icons.local_fire_department_rounded,
                          label:
                              '${food.calories.round()} kcal/${_servingLabel(food)}',
                        ),
                        _FoodMetric(
                          icon: Icons.fitness_center_rounded,
                          label: '${food.protein.toStringAsFixed(1)}g đạm',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.keyboard_arrow_up_rounded, color: scheme.secondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _FoodMetric extends StatelessWidget {
  const _FoodMetric({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: scheme.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

String _servingLabel(Food food) {
  final grams = food.servingSizeGrams;
  if (grams <= 0) {
    return '100g';
  }
  if (grams == grams.roundToDouble()) {
    return '${grams.round()}g';
  }
  return '${grams.toStringAsFixed(1)}g';
}

class _EmptyFoodState extends StatelessWidget {
  const _EmptyFoodState({required this.keyword});

  final String keyword;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 118,
            child: CustomPaint(
              painter: _EmptyPlatePainter(scheme),
              child: const Center(
                child: Icon(Icons.search_off_rounded, size: 44),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Món ăn này chưa được cập nhật trong hệ thống V-FIT',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            keyword,
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              AppFeedback.success(
                'Đã ghi nhận đề xuất thêm món "$keyword".',
                title: 'Cảm ơn bạn',
              );
            },
            icon: const Icon(Icons.add_comment_outlined),
            label: const Text('Đề xuất thêm món ăn'),
          ),
        ],
      ),
    );
  }
}

class _MacroCalculatorSheet extends StatefulWidget {
  const _MacroCalculatorSheet({required this.food});

  final Food food;

  @override
  State<_MacroCalculatorSheet> createState() => _MacroCalculatorSheetState();
}

class _MacroCalculatorSheetState extends State<_MacroCalculatorSheet> {
  late final TextEditingController _gramsController;
  double _grams = 100;

  @override
  void initState() {
    super.initState();
    _grams =
        widget.food.servingSizeGrams <= 0 ? 100 : widget.food.servingSizeGrams;
    _gramsController = TextEditingController(text: _grams.round().toString());
  }

  @override
  void dispose() {
    _gramsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final food = widget.food;
    final scheme = Theme.of(context).colorScheme;
    final calories = food.caloriesFor(_grams);
    final protein = food.proteinFor(_grams);
    final carbs = food.carbsFor(_grams);
    final fat = food.fatFor(_grams);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                food.name,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                'Công thức: gram nhập / ${food.servingSizeGrams.toStringAsFixed(0)}g x giá trị gốc từ bảng calo.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  SizedBox.square(
                    dimension: 132,
                    child: CustomPaint(
                      painter: _MacroRingPainter(
                        protein: food.protein,
                        carbs: food.carbs,
                        fat: food.fat,
                        proteinColor: scheme.primary,
                        carbsColor: scheme.secondary,
                        fatColor: const Color(0xFFD8FF3E),
                        trackColor: scheme.surfaceContainerHighest,
                      ),
                      child: Center(
                        child: Text(
                          '${calories.round()}\nkcal',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        _MacroValueTile(
                          label: 'Protein',
                          value: protein,
                          color: scheme.primary,
                        ),
                        const SizedBox(height: 8),
                        _MacroValueTile(
                          label: 'Carb',
                          value: carbs,
                          color: scheme.secondary,
                        ),
                        const SizedBox(height: 8),
                        _MacroValueTile(
                          label: 'Fat',
                          value: fat,
                          color: const Color(0xFFD8FF3E),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _gramsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Khối lượng',
                  suffixText: 'g',
                  prefixIcon: Icon(Icons.scale_rounded),
                ),
                onChanged: _setGramsFromText,
              ),
              const SizedBox(height: 12),
              Slider(
                value: _grams.clamp(0, 1000),
                min: 0,
                max: 1000,
                divisions: 100,
                label: '${_grams.round()}g',
                onChanged: _setGrams,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _setGrams(double value) {
    setState(() {
      _grams = value;
      _gramsController.text = value.round().toString();
      _gramsController.selection = TextSelection.collapsed(
        offset: _gramsController.text.length,
      );
    });
  }

  void _setGramsFromText(String value) {
    final parsed = double.tryParse(value);
    if (parsed == null) {
      return;
    }
    setState(() => _grams = parsed.clamp(0, 1000).toDouble());
  }
}

class _MacroValueTile extends StatelessWidget {
  const _MacroValueTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value),
            duration: const Duration(milliseconds: 160),
            builder: (context, animatedValue, _) {
              return Text(
                '${animatedValue.toStringAsFixed(1)}g',
                style: const TextStyle(fontWeight: FontWeight.w900),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MacroRingPainter extends CustomPainter {
  const _MacroRingPainter({
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.proteinColor,
    required this.carbsColor,
    required this.fatColor,
    required this.trackColor,
  });

  final double protein;
  final double carbs;
  final double fat;
  final Color proteinColor;
  final Color carbsColor;
  final Color fatColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final total = math.max(protein + carbs + fat, 1);
    final rect = Offset.zero & size;
    final stroke = size.width * 0.13;
    final basePaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect.deflate(stroke), 0, math.pi * 2, false, basePaint);

    var start = -math.pi / 2;
    for (final segment in [
      (value: protein, color: proteinColor),
      (value: carbs, color: carbsColor),
      (value: fat, color: fatColor),
    ]) {
      final sweep = math.pi * 2 * (segment.value / total);
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect.deflate(stroke), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _MacroRingPainter oldDelegate) {
    return oldDelegate.protein != protein ||
        oldDelegate.carbs != carbs ||
        oldDelegate.fat != fat ||
        oldDelegate.trackColor != trackColor;
  }
}

class _FoodSkeletonList extends StatelessWidget {
  const _FoodSkeletonList();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: List.generate(
        4,
        (index) => Container(
          height: 78,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.34),
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _ErrorStrip extends StatelessWidget {
  const _ErrorStrip({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AppFeedbackPanel(
      title: 'Không tải được dữ liệu món ăn',
      message: message,
      type: AppFeedbackType.error,
      compact: true,
    );
  }
}

class _EmptyPlatePainter extends CustomPainter {
  const _EmptyPlatePainter(this.scheme);

  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final platePaint = Paint()
      ..color = scheme.surfaceContainerHighest.withValues(alpha: 0.68)
      ..style = PaintingStyle.fill;
    final rimPaint = Paint()
      ..color = scheme.outlineVariant
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 150, height: 86),
      platePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 126, height: 62),
      rimPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _EmptyPlatePainter oldDelegate) {
    return oldDelegate.scheme != scheme;
  }
}
