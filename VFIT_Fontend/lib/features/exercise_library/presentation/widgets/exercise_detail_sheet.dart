import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../domain/entities/exercise_catalog.dart';

class ExerciseDetailSheet extends StatelessWidget {
  const ExerciseDetailSheet({super.key, required this.exercise});

  final ExerciseItem exercise;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canOpenVideo =
        exercise.videoUrl != null && exercise.videoUrl!.isNotEmpty;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exercise.name,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            if (exercise.description != null &&
                exercise.description!.isNotEmpty)
              Text(
                exercise.description!,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            if (exercise.equipment.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: exercise.equipment
                    .map((item) => Chip(label: Text(item)))
                    .toList(),
              ),
            ],
            if (!canOpenVideo && exercise.videoSearchHint != null) ...[
              const SizedBox(height: 14),
              Text(
                exercise.videoSearchHint!,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 18),
            AppButton.primary(
              label: canOpenVideo ? 'Xem video' : 'Chưa có link video',
              icon: canOpenVideo ? Icons.play_circle_fill : Icons.link_off,
              onPressed: canOpenVideo ? () => _openVideo(context) : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openVideo(BuildContext context) async {
    final uri = Uri.parse(exercise.videoUrl!);
    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      AppFeedback.warning('Không mở được video hướng dẫn.');
    }
  }
}
