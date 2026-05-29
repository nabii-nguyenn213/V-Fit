import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../challenges/data/models/challenge_model.dart';
import '../../../challenges/presentation/controllers/active_challenge_notifier.dart';

class ChallengeProgressSection extends ConsumerWidget {
  const ChallengeProgressSection({
    required this.state,
    super.key,
  });

  final ActiveChallengeState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null) {
      return Center(child: Text(state.errorMessage!));
    }
    if (state.activeParticipations.isEmpty) {
      return const Center(child: Text('Bạn chưa tham gia thử thách nào.'));
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: state.activeParticipations.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (ctx, i) {
        final part = state.activeParticipations[i];
        final challenge = state.allChallenges.firstWhere(
          (c) => c.id == part.challengeId,
          orElse: () => ChallengeModel(
            id: part.challengeId,
            title: 'Thử thách',
            description: '',
            active: true,
            type: null,
            durationDays: 30,
            rewards: null,
            requiredPhotoMilestones: [],
          ),
        );

        final total = challenge.durationDays;
        final completed = part.verifiedPhotos.length;

        return Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challenge.title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (challenge.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    challenge.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: (completed / total).clamp(0.0, 1.0),
                  backgroundColor: Colors.grey.shade200,
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 6),
                Text('Tiến độ: $completed / $total ngày',
                    style: Theme.of(context).textTheme.bodySmall),
                const Divider(),
                // Join button for challenges not yet participated
                if (!state.activeParticipations
                    .any((p) => p.challengeId == challenge.id)) ...[
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Tham gia thử thách'),
                          content: Text(
                              'Bạn có muốn tham gia "${challenge.title}"?\nSau khi đồng ý, không thể thay đổi mục tiêu.'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.of(c).pop(false),
                                child: const Text('Hủy')),
                            FilledButton(
                              onPressed: () => Navigator.of(c).pop(true),
                              child: const Text('Xác nhận'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await ref
                            .read(activeChallengeNotifierProvider.notifier)
                            .joinChallenge(challenge.id);
                        // Refresh state automatically via notifier
                      }
                    },
                    child: const Text('Tham gia'),
                  ),
                ],
                // Simple daily checklist (read‑only)
                for (int day = 1; day <= total; day++)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      day <= completed
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: day <= completed ? Colors.green : Colors.grey,
                    ),
                    title: Text('Ngày $day'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
