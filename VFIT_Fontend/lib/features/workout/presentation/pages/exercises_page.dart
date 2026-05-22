import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/utils/enum_parsers.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/state_views.dart';
import '../../data/repositories/workout_repository.dart';

class ExercisesPage extends ConsumerStatefulWidget {
  const ExercisesPage({super.key});

  @override
  ConsumerState<ExercisesPage> createState() => _ExercisesPageState();
}

class _ExercisesPageState extends ConsumerState<ExercisesPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(exerciseQueryProvider);
    final exercises = ref.watch(exercisesProvider(query));
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 76,
        leading: const Padding(
          padding: EdgeInsets.only(left: 8),
          child: AppBackButton(),
        ),
        title: const Text('Bài tập'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Tìm kiếm bài tập',
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  ref.read(exerciseQueryProvider.notifier).state =
                      query.copyWith(
                    keyword: _searchController.text,
                    page: 0,
                  );
                },
              ),
            ),
            onSubmitted: (value) {
              ref.read(exerciseQueryProvider.notifier).state =
                  query.copyWith(keyword: value, page: 0);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<DifficultyLevel>(
            initialValue: query.difficulty,
            decoration: const InputDecoration(labelText: 'Độ khó'),
            items: [
              const DropdownMenuItem<DifficultyLevel>(
                value: null,
                child: Text('Tất cả'),
              ),
              ...DifficultyLevel.values.map(
                (difficulty) => DropdownMenuItem<DifficultyLevel>(
                  value: difficulty,
                  child: Text(difficulty.name),
                ),
              ),
            ],
            onChanged: (value) {
              ref.read(exerciseQueryProvider.notifier).state = query.copyWith(
                difficulty: value,
                clearDifficulty: value == null,
                page: 0,
              );
            },
          ),
          const SizedBox(height: 16),
          _ExerciseFormScanCard(
            onTap: () {
              AppFeedback.info(
                'Camera check form tập luyện đang được phát triển.',
              );
            },
          ),
          const SizedBox(height: 16),
          exercises.when(
            data: (page) {
              if (page.content.isEmpty) {
                return const EmptyView(message: 'Không tìm thấy bài tập nào.');
              }
              return Column(
                children: page.content
                    .map(
                      (exercise) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppCard(
                          onTap: () =>
                              context.push('/exercises/${exercise.id}'),
                          child: Row(
                            children: [
                              const Icon(Icons.sports_gymnastics),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      exercise.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    Text(
                                      '${exercise.muscleGroup} • ${exercise.difficulty.name}',
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const LoadingView(),
            error: (error, _) => ErrorView(
              message: error.toString(),
              onRetry: () => ref.invalidate(exercisesProvider(query)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseFormScanCard extends StatelessWidget {
  const _ExerciseFormScanCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: scheme.secondary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: scheme.secondary.withValues(alpha: 0.42)),
            ),
            child:
                Icon(Icons.motion_photos_on_outlined, color: scheme.secondary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kiểm tra tư thế qua camera',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  'Xem trước tính năng phân tích dáng tập.',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          AppButton.ghost(
            label: 'Quét',
            icon: Icons.camera_alt_outlined,
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}
