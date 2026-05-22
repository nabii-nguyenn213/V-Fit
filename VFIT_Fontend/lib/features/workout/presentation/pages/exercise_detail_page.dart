import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/state_views.dart';
import '../../data/repositories/workout_repository.dart';

class ExerciseDetailPage extends ConsumerWidget {
  const ExerciseDetailPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercise = ref.watch(exerciseProvider(id));
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 76,
        leading: const Padding(
          padding: EdgeInsets.only(left: 8),
          child: AppBackButton(),
        ),
        title: const Text('Chi tiết bài tập'),
      ),
      body: exercise.when(
        data: (item) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              item.name,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text('${item.muscleGroup} • ${item.difficulty.name}'),
            const SizedBox(height: 20),
            Text(
              'Hướng dẫn thực hiện',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...item.instructions.map(
              (instruction) => ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: Text(instruction),
              ),
            ),
            if (item.videoUrl != null && item.videoUrl!.isNotEmpty) ...[
              const SizedBox(height: 24),
              AppButton.primary(
                label: 'Xem video hướng dẫn',
                icon: Icons.play_circle_fill,
                onPressed: () async {
                  final uri = Uri.parse(item.videoUrl!);
                  final opened = await launchUrl(
                    uri,
                    mode: LaunchMode.externalApplication,
                  );
                  if (!opened && context.mounted) {
                    AppFeedback.warning('Không mở được video hướng dẫn.');
                  }
                },
              ),
            ],
          ],
        ),
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(exerciseProvider(id)),
        ),
      ),
    );
  }
}
