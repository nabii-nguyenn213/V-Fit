import 'package:flutter/material.dart';

import '../../../../core/widgets/app_back_button.dart';
import '../../domain/entities/exercise_catalog.dart';
import '../widgets/exercise_detail_sheet.dart';

class ExerciseGroupDetailPage extends StatelessWidget {
  const ExerciseGroupDetailPage({
    super.key,
    required this.group,
    this.initialSubGroupId,
  });

  final MuscleGroup group;
  final String? initialSubGroupId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 76,
        leading: const Padding(
          padding: EdgeInsets.only(left: 8),
          child: AppBackButton(),
        ),
        title: Text(group.name),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: group.subGroups.length,
        itemBuilder: (context, index) {
          final subGroup = group.subGroups[index];
          return _SubGroupSection(
            subGroup: subGroup,
            initiallyExpanded: initialSubGroupId == null
                ? index == 0
                : subGroup.id == initialSubGroupId,
          );
        },
      ),
    );
  }
}

// ── SubGroup Section ────────────────────────────────────────────────────────

class _SubGroupSection extends StatefulWidget {
  const _SubGroupSection({
    required this.subGroup,
    required this.initiallyExpanded,
  });

  final SubMuscleGroup subGroup;
  final bool initiallyExpanded;

  @override
  State<_SubGroupSection> createState() => _SubGroupSectionState();
}

class _SubGroupSectionState extends State<_SubGroupSection>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late AnimationController _controller;
  late Animation<double> _iconTurn;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 220),
      vsync: this,
      value: _expanded ? 1.0 : 0.0,
    );
    _iconTurn = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _expanded
                ? scheme.primary.withValues(alpha: 0.28)
                : scheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: _toggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.fitness_center_rounded,
                        size: 18,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.subGroup.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.subGroup.exercises.length} bài tập',
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    RotationTransition(
                      turns: _iconTurn,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Exercise list ──────────────────────────────────────
            if (_expanded) ...[
              Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
              ...widget.subGroup.exercises.asMap().entries.map((entry) {
                final i = entry.key;
                final exercise = entry.value;
                return _ExerciseCard(
                  exercise: exercise,
                  isLast: i == widget.subGroup.exercises.length - 1,
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Exercise Card ───────────────────────────────────────────────────────────

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.exercise,
    required this.isLast,
  });

  final ExerciseItem exercise;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasVideo = exercise.videoUrl != null && exercise.videoUrl!.isNotEmpty;

    return Column(
      children: [
        InkWell(
          onTap: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => ExerciseDetailSheet(exercise: exercise),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Play/Link indicator
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: hasVideo
                        ? scheme.primary.withValues(alpha: 0.12)
                        : scheme.onSurface.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    hasVideo
                        ? Icons.play_circle_fill_rounded
                        : Icons.link_off_rounded,
                    color: hasVideo ? scheme.primary : scheme.onSurfaceVariant,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),

                // Name + meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Video tag
                          _MiniTag(
                            label: hasVideo ? 'Video TikTok' : 'Chưa có link',
                            icon: hasVideo
                                ? Icons.videocam_rounded
                                : Icons.videocam_off_rounded,
                            color: hasVideo
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                          ),
                          // Equipment tags
                          if (exercise.equipment.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                exercise.equipment.take(2).join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Arrow
                Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 72,
            endIndent: 16,
            color: scheme.outlineVariant.withValues(alpha: 0.3),
          ),
      ],
    );
  }
}

// ── Mini Tag ────────────────────────────────────────────────────────────────

class _MiniTag extends StatelessWidget {
  const _MiniTag({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
