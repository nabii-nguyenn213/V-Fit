import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/coming_soon_view.dart';
import '../../../../core/widgets/state_views.dart';
import '../../data/repositories/workout_repository.dart';

class WorkoutDetailPage extends ConsumerWidget {
  const WorkoutDetailPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final program = ref.watch(workoutProgramProvider(id));
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 76,
        leading: const Padding(
          padding: EdgeInsets.only(left: 8),
          child: AppBackButton(),
        ),
        title: const Text('Chi tiết bài tập'),
      ),
      body: program.when(
        data: (item) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              item.title,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text('${item.durationMinutes} phút • ${item.difficulty.name}'),
            if (item.description != null) ...[
              const SizedBox(height: 16),
              Text(item.description!),
            ],
            const SizedBox(height: 20),
            const ComingSoonView(
              title: 'Bắt đầu luyện tập',
              message: 'Tính năng này sẽ khả dụng khi Backend hỗ trợ.',
            ),
            const SizedBox(height: 20),
            Text(
              'Danh sách ID bài tập',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...item.exerciseIds
                .map((exerciseId) => ListTile(title: Text(exerciseId))),
          ],
        ),
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(workoutProgramProvider(id)),
        ),
      ),
    );
  }
}
