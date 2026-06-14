import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../nutrition/data/repositories/nutrition_repository.dart';
import '../providers/ai_meal_planner_provider.dart';

class AiMealSheet extends ConsumerStatefulWidget {
  const AiMealSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AiMealSheet(),
    );
  }

  @override
  ConsumerState<AiMealSheet> createState() => _AiMealSheetState();
}

class _AiMealSheetState extends ConsumerState<AiMealSheet> {
  int _mealsPerDay = 3;
  String _selectedDayKey = 'monday';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final state = ref.watch(aiMealPlannerProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.76,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 15,
              spreadRadius: 2,
            )
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Thực đơn Dinh dưỡng AI',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'AI tự động phân chia Calorie & Macro cho gymer.',
              style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 12),
            ),
            const Divider(height: 20),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildFormLabel('Số bữa ăn mong muốn: $_mealsPerDay bữa'),
                    Slider(
                      value: _mealsPerDay.toDouble(),
                      min: 3,
                      max: 5,
                      divisions: 2,
                      activeColor: AppColors.primaryOf(context),
                      onChanged: (val) {
                        setState(() => _mealsPerDay = val.round());
                      },
                    ),
                    const SizedBox(height: 16),
                    AppButton.primary(
                      label: 'Tạo thực đơn dinh dưỡng',
                      icon: Icons.auto_awesome_rounded,
                      loading: state.isLoading,
                      onPressed: () {
                        ref.read(aiMealPlannerProvider.notifier).generateMealPlan(
                              mealsPerDay: _mealsPerDay,
                            );
                      },
                    ),
                    if (state.error != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        state.error!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                    if (state.plan != null) ...[
                      const SizedBox(height: 20),
                      _buildMealPlanResult(state.plan!),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealPlanResult(Map<String, dynamic> plan) {
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

    final selectedDayData = weeklyPlan[_selectedDayKey] as Map<String, dynamic>? ?? {};
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
        // Horizontal Day Selector
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: dayKeys.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final key = dayKeys[index];
              final isSelected = _selectedDayKey == key;
              return ChoiceChip(
                label: Text(dayLabels[key]!),
                selected: isSelected,
                onSelected: (val) {
                  if (val) {
                    setState(() => _selectedDayKey = key);
                  }
                },
                selectedColor: scheme.primary.withValues(alpha: 0.2),
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.teal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Text('Khuyến nghị ${dayLabels[_selectedDayKey]}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              Text(
                '$dailyCal kcal',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMacroColumn('Protein', '${protein}g', Colors.orange),
                  _buildMacroColumn('Carbs', '${carbs}g', Colors.blue),
                  _buildMacroColumn('Fat', '${fat}g', Colors.red),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...meals.entries.map((entry) {
          final mealName = entry.key;
          final mealItems = List<String>.from(entry.value ?? []);

          if (mealItems.isEmpty) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mealName.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const Divider(height: 12),
                  ...mealItems.map((item) => _buildBulletPoint(item)),
                ],
              ),
            ),
          );
        }),
        if (note.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Lời khuyên: $note',
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ),
        ],
        const SizedBox(height: 20),
        AppButton.primary(
          label: 'Đồng ý áp dụng thực đơn tuần này',
          icon: Icons.check_circle_rounded,
          onPressed: () async {
            try {
              final repo = ref.read(nutritionRepositoryProvider);
              await repo.saveAiMealPlan(plan);
              await repo.applyAiMealPlan(true);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã áp dụng thực đơn tuần AI thành công!'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.of(context).pop(true);
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi khi áp dụng thực đơn: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildMacroColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _buildFormLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}
