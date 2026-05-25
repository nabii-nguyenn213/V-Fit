import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    // ── Header ───────────────────────────────────────
                    Text(
                      exercise.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),

                    // ── Equipment chips ───────────────────────────────
                    if (exercise.equipment.isNotEmpty) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: exercise.equipment.map((item) {
                          return Chip(
                            label: Text(
                              item,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: scheme.primary,
                              ),
                            ),
                            backgroundColor:
                                scheme.primary.withValues(alpha: 0.10),
                            side: BorderSide(
                              color: scheme.primary.withValues(alpha: 0.30),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 0,
                            ),
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ] else
                      const SizedBox(height: 12),

                    // ── Video section ─────────────────────────────────
                    _VideoCard(
                      exercise: exercise,
                      canOpenVideo: canOpenVideo,
                      onTap: () => _openVideo(context),
                    ),

                    // ── Description / Hướng dẫn ──────────────────────
                    if (exercise.description != null &&
                        exercise.description!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _SectionHeader(
                        icon: Icons.menu_book_rounded,
                        label: 'Hướng dẫn & Lưu ý',
                        color: scheme.primary,
                      ),
                      const SizedBox(height: 10),
                      _DescriptionBlock(
                        description: exercise.description!,
                        scheme: scheme,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openVideo(BuildContext context) async {
    final uri = Uri.parse(exercise.videoUrl!);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      AppFeedback.warning('Không mở được video hướng dẫn.');
    }
  }
}

// ── Video Card ──────────────────────────────────────────────────────────────

class _VideoCard extends StatelessWidget {
  const _VideoCard({
    required this.exercise,
    required this.canOpenVideo,
    required this.onTap,
  });

  final ExerciseItem exercise;
  final bool canOpenVideo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: canOpenVideo ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: canOpenVideo
              ? scheme.primary.withValues(alpha: 0.08)
              : scheme.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: canOpenVideo
                ? scheme.primary.withValues(alpha: 0.35)
                : scheme.onSurface.withValues(alpha: 0.10),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: canOpenVideo
                    ? scheme.primary.withValues(alpha: 0.15)
                    : scheme.onSurface.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                canOpenVideo
                    ? Icons.play_circle_fill_rounded
                    : Icons.link_off_rounded,
                color: canOpenVideo
                    ? scheme.primary
                    : scheme.onSurfaceVariant,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    canOpenVideo ? 'Xem video hướng dẫn' : 'Chưa có link video',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: canOpenVideo
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                  if (exercise.videoSearchHint != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      exercise.videoSearchHint!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (canOpenVideo) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.open_in_new_rounded,
                size: 18,
                color: scheme.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Section Header ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ── Description Block ───────────────────────────────────────────────────────

class _DescriptionBlock extends StatelessWidget {
  const _DescriptionBlock({
    required this.description,
    required this.scheme,
  });

  final String description;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    // Split on sentence boundaries or keyword markers
    final rawParts = description.split(RegExp(r'\. (?=[A-ZÀÁÂÃÈÉÊÌÍÒÓÔÕÙÚĂĐƠƯẠẶẦẤẢỀẾỘỐỔỖ])'));
    final parts = rawParts.where((p) => p.trim().isNotEmpty).toList();

    if (parts.length <= 1) {
      return _DescriptionCard(text: description, scheme: scheme);
    }

    // Separate cách tập / lưu ý
    final howTo = <String>[];
    final notes = <String>[];
    final tips = <String>[];

    for (final part in parts) {
      final lower = part.toLowerCase();
      if (lower.contains('lưu ý') || lower.contains('lỗi') || lower.contains('sai')) {
        notes.add(part.endsWith('.') ? part : '$part.');
      } else if (lower.contains('mẹo') || lower.contains('ưu điểm') || lower.contains('tác dụng')) {
        tips.add(part.endsWith('.') ? part : '$part.');
      } else {
        howTo.add(part.endsWith('.') ? part : '$part.');
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (howTo.isNotEmpty)
          _BulletSection(
            items: howTo,
            icon: Icons.check_circle_rounded,
            color: scheme.primary,
            scheme: scheme,
          ),
        if (notes.isNotEmpty) ...[
          const SizedBox(height: 12),
          _BulletSection(
            items: notes,
            icon: Icons.warning_amber_rounded,
            color: const Color(0xFFFF9800),
            scheme: scheme,
          ),
        ],
        if (tips.isNotEmpty) ...[
          const SizedBox(height: 12),
          _BulletSection(
            items: tips,
            icon: Icons.lightbulb_rounded,
            color: const Color(0xFF4CAF50),
            scheme: scheme,
          ),
        ],
      ],
    );
  }
}

class _BulletSection extends StatelessWidget {
  const _BulletSection({
    required this.items,
    required this.icon,
    required this.color,
    required this.scheme,
  });

  final List<String> items;
  final IconData icon;
  final Color color;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.asMap().entries.map((entry) {
          return Padding(
            padding: EdgeInsets.only(top: entry.key == 0 ? 0 : 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(icon, size: 15, color: color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.value.trim(),
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.5,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DescriptionCard extends StatelessWidget {
  const _DescriptionCard({required this.text, required this.scheme});

  final String text;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.all(14),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13.5,
          height: 1.6,
          color: scheme.onSurface,
        ),
      ),
    );
  }
}
