import 'package:flutter/material.dart';

import '../../../../core/widgets/app_back_button.dart';
import '../../domain/entities/exercise_catalog.dart';
import '../widgets/exercise_detail_sheet.dart';

class ExerciseGroupDetailPage extends StatelessWidget {
  const ExerciseGroupDetailPage({super.key, required this.group});

  final MuscleGroup group;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 76,
        leading: const Padding(
          padding: EdgeInsets.only(left: 8),
          child: AppBackButton(),
        ),
        title: Text(group.name),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: group.subGroups.length,
        itemBuilder: (context, index) {
          final subGroup = group.subGroups[index];

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              initiallyExpanded: index == 0,
              title: Text(
                subGroup.name,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text('${subGroup.exercises.length} bài tập'),
              children: subGroup.exercises
                  .map(
                    (exercise) => ListTile(
                      title: Text(exercise.name),
                      subtitle: Text(
                        exercise.videoUrl == null
                            ? 'Chưa có link trực tiếp'
                            : 'TikTok hướng dẫn',
                      ),
                      leading: const Icon(Icons.play_circle_outline),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => showModalBottomSheet<void>(
                        context: context,
                        showDragHandle: true,
                        builder: (context) =>
                            ExerciseDetailSheet(exercise: exercise),
                      ),
                    ),
                  )
                  .toList(),
            ),
          );
        },
      ),
    );
  }
}
