import 'package:flutter/material.dart';

import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/exercise_catalog.dart';

class MuscleGroupCard extends StatelessWidget {
  const MuscleGroupCard({
    super.key,
    required this.group,
    required this.onTap,
  });

  final MuscleGroup group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.primary.withValues(alpha: 0.32)),
            ),
            child: Icon(_iconFor(group.id), color: scheme.primary),
          ),
          const Spacer(),
          Text(
            group.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            '${group.exerciseCount} bài tập',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String id) {
    return switch (id) {
      'chest' => Icons.fitness_center,
      'back' => Icons.accessibility_new,
      'shoulders' => Icons.sports_gymnastics,
      'legs' => Icons.directions_run,
      'biceps' => Icons.sports_martial_arts,
      'triceps' => Icons.flash_on,
      _ => Icons.self_improvement,
    };
  }
}
