import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/state_views.dart';
import '../../data/repositories/exercise_library_repository_impl.dart';
import '../bloc/exercise_library_bloc.dart';
import '../widgets/interactive_muscle_model_viewer.dart';
import '../widgets/muscle_group_card.dart';
import 'exercise_group_detail_page.dart';

class ExerciseLibraryPage extends ConsumerWidget {
  const ExerciseLibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BlocProvider(
      create: (_) => ExerciseLibraryBloc(ref.read(getExerciseCatalogProvider))
        ..add(const ExerciseLibraryRequested()),
      child: const ExerciseLibraryView(),
    );
  }
}

class ExerciseLibraryView extends StatefulWidget {
  const ExerciseLibraryView({super.key});

  @override
  State<ExerciseLibraryView> createState() => ExerciseLibraryViewState();
}

class ExerciseLibraryViewState extends State<ExerciseLibraryView> {
  bool _showMap = true;

  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<ExerciseLibraryBloc>();
    bloc.add(const ExerciseLibraryRequested(forceRefresh: true));
    await bloc.stream.firstWhere((state) => !state.loading);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<ExerciseLibraryBloc, ExerciseLibraryState>(
      builder: (context, state) {
        if (state.loading && !state.hasData) {
          return const LoadingView();
        }
        if (!state.hasData && state.errorMessage != null) {
          return ErrorView(
            message: state.errorMessage!,
            onRetry: () => context
                .read<ExerciseLibraryBloc>()
                .add(const ExerciseLibraryRequested(forceRefresh: true)),
          );
        }

        final catalog = state.catalog;
        final groups = catalog?.groups ?? const [];

        return RefreshIndicator(
          onRefresh: () => _refresh(context),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppResponsive.pagePadding(context),
            children: [
              Text(
                'Thư viện bài tập',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                'Chạm vào từng nhóm cơ trên bản đồ để xem bài tập phù hợp.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              if (catalog?.isStale == true) ...[
                const SizedBox(height: 12),
                MaterialBanner(
                  content: const Text(
                    'Đang hiển thị dữ liệu đã lưu vì chưa kết nối được máy chủ.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => context.read<ExerciseLibraryBloc>().add(
                            const ExerciseLibraryRequested(forceRefresh: true),
                          ),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _ViewModeTab(
                        icon: Icons.accessibility_new,
                        label: 'Bản đồ cơ',
                        isSelected: _showMap,
                        onTap: () => setState(() => _showMap = true),
                      ),
                    ),
                    Expanded(
                      child: _ViewModeTab(
                        icon: Icons.grid_view,
                        label: 'Danh sách',
                        isSelected: !_showMap,
                        onTap: () => setState(() => _showMap = false),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (_showMap)
                InteractiveMuscleModelViewer(
                  key: const ValueKey('interactive-muscle-model-viewer'),
                  groups: groups,
                  onSelection: (selection) => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => ExerciseGroupDetailPage(
                        group: selection.group,
                        initialSubGroupId: selection.subGroupId,
                      ),
                    ),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: groups.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.08,
                  ),
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    return MuscleGroupCard(
                      group: group,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) =>
                              ExerciseGroupDetailPage(group: group),
                        ),
                      ),
                    );
                  },
                ),
              if (groups.isEmpty)
                const EmptyView(
                  message: 'Chưa có dữ liệu thư viện bài tập.',
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ViewModeTab extends StatelessWidget {
  const _ViewModeTab({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: isSelected,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? scheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? scheme.onPrimary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                    color:
                        isSelected ? scheme.onPrimary : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
