import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/flashy_vip_required_modal.dart';
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
import '../../../ai/data/repositories/ai_planners_repository.dart';
import '../../../ai/presentation/widgets/ai_meal_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../auth/application/auth_controller.dart';
import 'package:go_router/go_router.dart';
import '../widgets/food_scan_modal.dart';  // ✨ NEW: Import food scan modal

class NutritionPage extends ConsumerStatefulWidget {
  const NutritionPage({super.key});

  @override
  ConsumerState<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends ConsumerState<NutritionPage> {
  late final TextEditingController _searchController;
  Timer? _debounce;
  bool _scanLoading = false;
  String _nutritionSelectedDayKey = 'monday';
  bool _itemResolving = false;

  String _currentDayKey() {
    switch (DateTime.now().weekday) {
      case DateTime.monday: return 'monday';
      case DateTime.tuesday: return 'tuesday';
      case DateTime.wednesday: return 'wednesday';
      case DateTime.thursday: return 'thursday';
      case DateTime.friday: return 'friday';
      case DateTime.saturday: return 'saturday';
      case DateTime.sunday: return 'sunday';
      default: return 'monday';
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _nutritionSelectedDayKey = _currentDayKey();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// ✨ NEW: Show food scan modal
  Future<void> _scanFood(BuildContext context) async {
    try {
      setState(() => _scanLoading = true);

      final result = await showFoodScanModal(
        context,
        onFoodScanned: (scannedFood) {
          // Handle scanned food
          if (mounted) {
            AppFeedback.success('Đã quét thành công!');
            // Có thể add vào danh sách hoặc calculator
          }
        },
      );

      if (result != null && mounted) {
        // Use the scanned result
        final servingSizeGrams = (int.tryParse(result.servingSize.replaceAll(RegExp(r'[^0-9]'), ''))) ?? 100;
        final calories = result.calories.toDouble();
        final protein = result.proteinGrams;
        final carbs = result.carbGrams;
        final fat = result.fatGrams;
        
        final food = Food(
          id: 'food-scanned-${DateTime.now().millisecondsSinceEpoch}',
          name: result.foodName,
          normalizedName: result.foodName.toLowerCase(),
          servingSizeGrams: servingSizeGrams.toDouble(),
          calories: calories,
          protein: protein,
          carbs: carbs,
          fat: fat,
          // Calculate per100g values
          caloriesPer100g: servingSizeGrams > 0 ? (calories / servingSizeGrams * 100) : calories,
          proteinPer100g: servingSizeGrams > 0 ? (protein / servingSizeGrams * 100) : protein,
          carbsPer100g: servingSizeGrams > 0 ? (carbs / servingSizeGrams * 100) : carbs,
          fatPer100g: servingSizeGrams > 0 ? (fat / servingSizeGrams * 100) : fat,
          isGymFriendly: true,
          searchCount: 0,
          popularityScore: 0,
        );

        await _openCalculator(context, food);
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.error('Lỗi quét ảnh: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _scanLoading = false);
      }
    }
  }

  Food parseFoodString(String text) {
    final lowerText = text.toLowerCase();
    
    double grams = 100;
    final gramMatch = RegExp(r'(\d+)\s*g').firstMatch(lowerText);
    if (gramMatch != null) {
      grams = double.tryParse(gramMatch.group(1) ?? '') ?? 100.0;
    } else {
      final unitMatch = RegExp(r'(\d+)\s*(quả|lát|chén|bát|muỗng|hộp)').firstMatch(lowerText);
      if (unitMatch != null) {
        final units = double.tryParse(unitMatch.group(1) ?? '') ?? 1.0;
        if (lowerText.contains('trứng')) {
          grams = units * 50;
        } else {
          grams = units * 100;
        }
      }
    }

    double calPer100 = 150;
    double proteinPer100 = 10;
    double carbsPer100 = 15;
    double fatPer100 = 5;
    String name = text;
    String id = 'food-custom';

    if (lowerText.contains('ức gà') || lowerText.contains('uc ga')) {
      id = 'food-chicken-breast-fillet';
      name = 'Ức gà phi lê';
      calPer100 = 165; proteinPer100 = 31; carbsPer100 = 0; fatPer100 = 3.6;
    } else if (lowerText.contains('trứng') || lowerText.contains('trung')) {
      id = 'food-whole-egg';
      name = 'Trứng gà';
      calPer100 = 143; proteinPer100 = 12.6; carbsPer100 = 0.7; fatPer100 = 9.5;
    } else if (lowerText.contains('gạo lứt') || lowerText.contains('gao lut') || lowerText.contains('cơm lứt') || lowerText.contains('com lut')) {
      id = 'food-brown-rice';
      name = 'Gạo lứt';
      calPer100 = 111; proteinPer100 = 2.6; carbsPer100 = 23; fatPer100 = 0.9;
    } else if (lowerText.contains('thịt bò') || lowerText.contains('thit bo') || lowerText.contains('bò')) {
      id = 'food-beef-tenderloin';
      name = 'Thịt bò thăn';
      calPer100 = 190; proteinPer100 = 29; carbsPer100 = 0; fatPer100 = 7.6;
    } else if (lowerText.contains('whey')) {
      id = 'food-whey-isolate';
      name = 'Whey Protein';
      calPer100 = 370; proteinPer100 = 88; carbsPer100 = 3; fatPer100 = 1;
    } else if (lowerText.contains('cá hồi') || lowerText.contains('ca hoi')) {
      id = 'food-salmon';
      name = 'Cá hồi';
      calPer100 = 208; proteinPer100 = 20; carbsPer100 = 0; fatPer100 = 13;
    } else if (lowerText.contains('hạnh nhân') || lowerText.contains('hanh nhan') || lowerText.contains('hạt')) {
      id = 'food-almond';
      name = 'Hạt hạnh nhân';
      calPer100 = 579; proteinPer100 = 21; carbsPer100 = 22; fatPer100 = 49;
    } else if (lowerText.contains('yến mạch') || lowerText.contains('yen mach')) {
      id = 'food-oats';
      name = 'Yến mạch';
      calPer100 = 389; proteinPer100 = 16.9; carbsPer100 = 66.3; fatPer100 = 6.9;
    } else if (lowerText.contains('khoai lang')) {
      id = 'food-sweet-potato';
      name = 'Khoai lang';
      calPer100 = 86; proteinPer100 = 1.6; carbsPer100 = 20; fatPer100 = 0.1;
    } else if (lowerText.contains('rau') || lowerText.contains('súp lơ') || lowerText.contains('sup lo')) {
      id = 'food-vegetable';
      name = 'Rau xanh';
      calPer100 = 25; proteinPer100 = 2; carbsPer100 = 5; fatPer100 = 0.1;
    }

    final factor = grams / 100.0;
    return Food(
      id: id,
      name: name,
      normalizedName: name.toLowerCase(),
      servingSizeGrams: grams,
      calories: calPer100 * factor,
      protein: proteinPer100 * factor,
      carbs: carbsPer100 * factor,
      fat: fatPer100 * factor,
      caloriesPer100g: calPer100,
      proteinPer100g: proteinPer100,
      carbsPer100g: carbsPer100,
      fatPer100g: fatPer100,
      isGymFriendly: true,
      searchCount: 0,
      popularityScore: 0,
    );
  }

  Future<void> _handleAiFoodTap(BuildContext context, String foodItem) async {
    if (_itemResolving) return;
    
    setState(() => _itemResolving = true);
    
    Food? resolvedFood;
    try {
      final repo = ref.read(aiPlannersRepositoryProvider);
      final result = await repo.scanFoodText(
        foodName: foodItem,
        portion: '1 phần',
      );
      
      final calories = (result['total_calories'] as num?)?.toInt() ?? 0;
      final protein = (result['protein_g'] as num?)?.toDouble() ?? 0.0;
      final carbs = (result['carbs_g'] as num?)?.toDouble() ?? 0.0;
      final fat = (result['fat_g'] as num?)?.toDouble() ?? 0.0;
      final portion = result['portion']?.toString() ?? '1 phần';

      int servingGrams = 100;
      final gramMatch = RegExp(r'(\d+)\s*g').firstMatch(portion.toLowerCase());
      if (gramMatch != null) {
        servingGrams = int.tryParse(gramMatch.group(1) ?? '') ?? 100;
      }

      resolvedFood = Food(
        id: 'food-ai-resolved-${DateTime.now().millisecondsSinceEpoch}',
        name: result['food_name']?.toString() ?? foodItem,
        normalizedName: (result['food_name']?.toString() ?? foodItem).toLowerCase(),
        servingSizeGrams: servingGrams.toDouble(),
        calories: calories.toDouble(),
        protein: protein,
        carbs: carbs,
        fat: fat,
        caloriesPer100g: servingGrams > 0 ? ((calories / servingGrams) * 100).toDouble() : calories.toDouble(),
        proteinPer100g: servingGrams > 0 ? ((protein / servingGrams) * 100).toDouble() : protein,
        carbsPer100g: servingGrams > 0 ? ((carbs / servingGrams) * 100).toDouble() : carbs,
        fatPer100g: servingGrams > 0 ? ((fat / servingGrams) * 100).toDouble() : fat,
        isGymFriendly: true,
        searchCount: 0,
        popularityScore: 0,
      );
    } catch (_) {
      resolvedFood = parseFoodString(foodItem);
    } finally {
      if (mounted) {
        setState(() => _itemResolving = false);
      }
    }

    if (resolvedFood != null && mounted) {
      await _openCalculator(context, resolvedFood);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(foodRepositoryProvider);
    final isAiAppliedAsync = ref.watch(isAiMealPlanAppliedProvider);
    final aiPlanAsync = ref.watch(aiMealPlanProvider);

    return Scaffold(
      body: BlocProvider(
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
                ref.invalidate(isAiMealPlanAppliedProvider);
                ref.invalidate(aiMealPlanProvider);
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
                    onTap: () => _scanFood(context),
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
                  else if (state.hasKeyword)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _FoodListSection(
                          title: 'Kết quả phù hợp',
                          foods: state.foods,
                          onFoodTap: (food) => _openCalculator(context, food),
                        ),
                        const SizedBox(height: 20),
                        _buildSearchAiPlanButton(context),
                      ],
                    )
                  else
                    isAiAppliedAsync.when(
                      data: (isAiApplied) {
                        if (isAiApplied) {
                          return aiPlanAsync.when(
                            data: (plan) {
                              if (plan != null) {
                                return _buildAiWeeklyPlanSection(context, plan);
                              }
                              return _buildNoAiPlanPlaceholder(context);
                            },
                            loading: () => const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24.0),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            error: (err, _) => Text('Lỗi tải thực đơn AI: $err'),
                          );
                        } else {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildAiBanner(context),
                              const SizedBox(height: 18),
                              _FoodListSection(
                                title: 'Món ăn phổ biến cho gymer',
                                foods: state.foods,
                                onFoodTap: (food) => _openCalculator(context, food),
                              ),
                            ],
                          );
                        }
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (err, _) => _FoodListSection(
                        title: 'Món ăn phổ biến cho gymer',
                        foods: state.foods,
                        onFoodTap: (food) => _openCalculator(context, food),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAiBanner(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: scheme.primary, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Thiết lập Thực đơn AI',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Hãy để AI thiết kế một thực đơn dinh dưỡng 7 ngày đầy đủ protein, tinh bột, chất béo phù hợp hoàn hảo với thể trạng của bạn.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 14),
          AppButton.primary(
            label: 'Tạo ngay thực đơn AI',
            icon: Icons.bolt_rounded,
            onPressed: () async {
              final user = ref.read(authControllerProvider).user;
              if (user == null) {
                context.go('/login');
                return;
              }
              if (!user.isVipActive) {
                await showDialog<void>(
                  context: context,
                  builder: (context) => const FlashyVipRequiredModal(),
                );
                return;
              }

              final result = await AiMealSheet.show(context);
              if (result == true) {
                ref.invalidate(isAiMealPlanAppliedProvider);
                ref.invalidate(aiMealPlanProvider);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNoAiPlanPlaceholder(BuildContext context) {
    return Column(
      children: [
        const Text('Không tìm thấy thực đơn AI.'),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () async {
            final user = ref.read(authControllerProvider).user;
            if (user == null) {
              context.go('/login');
              return;
            }
            if (!user.isVipActive) {
              await showDialog<void>(
                context: context,
                builder: (context) => const FlashyVipRequiredModal(),
              );
              return;
            }

            final result = await AiMealSheet.show(context);
            if (result == true) {
              ref.invalidate(isAiMealPlanAppliedProvider);
              ref.invalidate(aiMealPlanProvider);
            }
          },
          child: const Text('Tạo thực đơn AI mới'),
        ),
      ],
    );
  }

  Widget _buildAiWeeklyPlanSection(BuildContext context, Map<String, dynamic> plan) {
    final weeklyPlan = plan['weekly_plan'] as Map<String, dynamic>? ?? {};
    final dayKeys = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final dayLabels = {
      'monday': 'Thứ 2',
      'tuesday': 'Thứ 3',
      'wednesday': 'Thứ 4',
      'thursday': 'Thứ 5',
      'friday': 'Thứ 6',
      'saturday': 'Thứ 7',
      'sunday': 'Chủ Nhật',
    };

    final selectedDayData = weeklyPlan[_nutritionSelectedDayKey] as Map<String, dynamic>? ?? {};
    final dailyCal = selectedDayData['daily_calories'] ?? 0;
    final protein = selectedDayData['protein_g'] ?? 0;
    final carbs = selectedDayData['carbs_g'] ?? 0;
    final fat = selectedDayData['fat_g'] ?? 0;
    final meals = selectedDayData['meal_plan'] as Map<String, dynamic>? ?? {};
    final note = plan['note'] ?? '';

    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Thực đơn tuần AI',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            IconButton.outlined(
              icon: const Icon(Icons.close_rounded, size: 18),
              tooltip: 'Hủy áp dụng',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Hủy áp dụng thực đơn AI?'),
                    content: const Text('Bạn có chắc chắn muốn quay lại danh sách món ăn phổ biến không?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Không'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Có'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref.read(nutritionRepositoryProvider).applyAiMealPlan(false);
                  ref.invalidate(isAiMealPlanAppliedProvider);
                  ref.invalidate(aiMealPlanProvider);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: dayKeys.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final key = dayKeys[index];
              final isSelected = _nutritionSelectedDayKey == key;
              return ChoiceChip(
                label: Text(dayLabels[key]!),
                selected: isSelected,
                onSelected: (val) {
                  if (val) {
                    setState(() => _nutritionSelectedDayKey = key);
                  }
                },
                selectedColor: scheme.primary.withValues(alpha: 0.18),
                checkmarkColor: scheme.primary,
                labelStyle: TextStyle(
                  color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.teal.withValues(alpha: 0.18),
                scheme.primary.withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Text(
                'Mục tiêu dinh dưỡng ${dayLabels[_nutritionSelectedDayKey]}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Text(
                '$dailyCal kcal',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: scheme.primary,
                ),
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMacroDetailItem('Protein', '${protein}g', Colors.orange),
                  _buildMacroDetailItem('Tinh bột', '${carbs}g', Colors.blue),
                  _buildMacroDetailItem('Chất béo', '${fat}g', Colors.red),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_itemResolving) ...[
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text('Đang nạp dữ liệu món ăn...', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
        ...meals.entries.map((entry) {
          final mealName = entry.key;
          final mealItems = List<String>.from(entry.value ?? []);

          if (mealItems.isEmpty) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getMealDisplayName(mealName),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const Divider(height: 16),
                  ...mealItems.map((item) {
                    return InkWell(
                      onTap: () => _handleAiFoodTap(context, item),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: scheme.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.calculate_rounded, size: 16, color: scheme.primary),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, size: 18, color: scheme.onSurfaceVariant),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        }),
        if (note.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lời khuyên tuần: $note',
                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        AppButton.secondary(
          label: 'Thiết lập lại thực đơn AI',
          icon: Icons.auto_awesome_rounded,
          onPressed: () async {
            final result = await AiMealSheet.show(context);
            if (result == true) {
              ref.invalidate(isAiMealPlanAppliedProvider);
              ref.invalidate(aiMealPlanProvider);
            }
          },
        ),
      ],
    );
  }

  Widget _buildMacroDetailItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  String _getMealDisplayName(String key) {
    switch (key.toLowerCase()) {
      case 'breakfast': return 'Bữa sáng';
      case 'lunch': return 'Bữa trưa';
      case 'dinner': return 'Bữa tối';
      case 'snack': return 'Bữa phụ / Ăn nhẹ';
      default: return key;
    }
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

  Widget _buildSearchAiPlanButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE81CFF).withOpacity(0.35),
          width: 1.5,
        ),
        gradient: LinearGradient(
          colors: isDark 
              ? [const Color(0xFF1E1B4B).withOpacity(0.4), const Color(0xFF311042).withOpacity(0.4)]
              : [const Color(0xFFFAF5FF), const Color(0xFFFDF4FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFE81CFF), Color(0xFF06B6D4)],
                ).createShader(bounds),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Tự động lên thực đơn AI từ món này?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Để AI phân tích và tự động thiết lập thực đơn 7 ngày tối ưu riêng theo thể trạng của bạn dựa trên kết quả tìm kiếm.',
            style: TextStyle(fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 12),
          AppButton.primary(
            label: 'Thiết lập thực đơn AI ✨',
            onPressed: () async {
              final user = ref.read(authControllerProvider).user;
              if (user == null) {
                context.go('/login');
                return;
              }
              if (!user.isVipActive) {
                await showDialog<void>(
                  context: context,
                  builder: (context) => const FlashyVipRequiredModal(),
                );
                return;
              }

              final result = await AiMealSheet.show(context);
              if (result == true) {
                ref.invalidate(isAiMealPlanAppliedProvider);
                ref.invalidate(aiMealPlanProvider);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _FoodScanSheet extends ConsumerStatefulWidget {
  const _FoodScanSheet({required this.onAnalyze});

  final Future<FoodCalorieEstimateModel> Function(_TransientFoodImage image)
      onAnalyze;

  @override
  ConsumerState<_FoodScanSheet> createState() => _FoodScanSheetState();
}

class _FoodScanSheetState extends ConsumerState<_FoodScanSheet> {
  _TransientFoodImage? _image;
  Uint8List? _previewBytes;
  bool _loading = false;
  String? _errorMessage;

  Future<void> _pick(ImageSource source) async {
    if (_loading) {
      debugPrint('FOOD_SCAN_PICK: Already loading, ignoring tap');
      return;
    }
    debugPrint('FOOD_SCAN_PICK: Starting pick from source $source');
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1280,
      );
      debugPrint('FOOD_SCAN_PICK: picked = ${picked?.path}');
      if (picked == null || !mounted) {
        return;
      }
      final bytes = await picked.readAsBytes();
      debugPrint('FOOD_SCAN_PICK: read bytes count = ${bytes.length}');
      if (source == ImageSource.camera) {
        unawaited(_deleteTemporaryPickedImage(picked.path));
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _image = _TransientFoodImage(
          bytes: bytes,
          filename: picked.name,
          mimeType: picked.mimeType,
        );
        _previewBytes = bytes;
        _errorMessage = null;
      });
      await _analyze();
    } catch (e) {
      debugPrint('FOOD_SCAN_PICK_ERROR: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Lỗi chọn ảnh: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _deleteTemporaryPickedImage(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Best-effort cleanup for camera temp files.
    }
  }

  Future<void> _analyze() async {
    final image = _image;
    if (image == null) {
      debugPrint('FOOD_SCAN_ANALYZE: image is null, returning early');
      return;
    }
    if (_loading) {
      debugPrint('FOOD_SCAN_ANALYZE: already loading, returning early');
      return;
    }
    debugPrint('FOOD_SCAN_ANALYZE: starting onAnalyze callback...');
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final estimate = await widget.onAnalyze(image);
      debugPrint('FOOD_SCAN_ANALYZE: success! estimate = $estimate');
      if (mounted) {
        Navigator.of(context).pop(estimate);
      }
    } catch (error) {
      debugPrint('FOOD_SCAN_ANALYZE: failed with error: $error');
      if (mounted) {
        final userMessage = error is ApiException
            ? error.message
            : 'Không thể phân tích ảnh. Vui lòng thử lại.';
        setState(() {
          _errorMessage = userMessage;
        });
        AppFeedback.error(
          userMessage,
          title: 'Không quét được món ăn',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final previewBytes = _previewBytes;
    return Stack(
      children: [
        SafeArea(
          child: Padding(
            padding: AppResponsive.pagePadding(context).copyWith(top: 0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.document_scanner_rounded,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quét calo món ăn',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            Text(
                              'Chụp hoặc chọn ảnh rõ món ăn để AI ước tính macro.',
                              style: TextStyle(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest.withValues(
                          alpha: 0.52,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: previewBytes == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.restaurant_menu_rounded,
                                  size: 54,
                                  color: scheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Chưa có ảnh món ăn',
                                  style: TextStyle(
                                    color: scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.memory(
                                previewBytes,
                                fit: BoxFit.cover,
                              ),
                            ),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.errorContainer.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: scheme.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: scheme.error,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: scheme.onErrorContainer,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              _loading ? null : () => _pick(ImageSource.camera),
                          icon: const Icon(Icons.photo_camera_outlined),
                          label: const Text('Camera'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              _loading ? null : () => _pick(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Thư viện'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _image == null || _loading ? null : _analyze,
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('Phân tích calo'),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_loading)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.45),
                  child: Center(
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      color: Theme.of(context).colorScheme.surface,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 24,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 20),
                            Text(
                              'Đang phân tích món ăn...',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'AI đang xác định calo & dinh dưỡng',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 18),
                            OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close_rounded),
                              label: const Text('Hủy quét'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TransientFoodImage {
  const _TransientFoodImage({
    required this.bytes,
    required this.filename,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String filename;
  final String? mimeType;
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
        child: SingleChildScrollView(
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



