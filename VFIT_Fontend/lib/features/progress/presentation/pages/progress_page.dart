import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:camera/camera.dart' show XFile;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_response.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_radius.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../profile/data/models/user_model.dart';
import '../../../profile/data/repositories/profile_repository.dart';
import '../../data/models/gamification_models.dart';
import '../../data/models/journey_snap_model.dart';
import '../../data/repositories/progress_repository.dart';

import '../../../challenges/data/models/participation_model.dart';
import '../../../challenges/presentation/controllers/active_challenge_notifier.dart';
import '../widgets/progress_camera_capture_page.dart';

class ProgressPage extends ConsumerStatefulWidget {
  const ProgressPage({super.key});

  @override
  ConsumerState<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends ConsumerState<ProgressPage> {
  static const _mediaChannel = MethodChannel('vfit/media');

  bool _isUploading = false;
  bool _showAllJourneyDays = false;
  final List<_LocalJourneySnap> _localSnaps = [];

  Future<void> _takeSnap() async {
    // --- Daily snap limit: max 5 per day (anti-spam) ---
    int todaysServerCount = 0;
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final snapsAsync = ref.read(journeySnapsProvider);
    if (snapsAsync is AsyncData<PageResponse<JourneySnapModel>>) {
      todaysServerCount = snapsAsync.value.content.where((snap) {
        final local = snap.createdAt.toLocal();
        return local.year == todayDate.year &&
            local.month == todayDate.month &&
            local.day == todayDate.day;
      }).length;
    } else {
      try {
        final freshSnaps =
            await ref.read(progressRepositoryProvider).getSnaps();
        todaysServerCount = freshSnaps.content.where((snap) {
          final local = snap.createdAt.toLocal();
          return local.year == todayDate.year &&
              local.month == todayDate.month &&
              local.day == todayDate.day;
        }).length;
      } catch (_) {}
    }
    // Also count local snaps still uploading today
    final todaysLocalCount = _localSnaps.where((snap) {
      return snap.createdAt.year == todayDate.year &&
          snap.createdAt.month == todayDate.month &&
          snap.createdAt.day == todayDate.day;
    }).length;
    final totalToday = todaysServerCount + todaysLocalCount;
    if (totalToday >= 5) {
      if (mounted) {
        AppFeedback.error(
          'Bạn chỉ được chụp tối đa 5 ảnh hành trình mỗi ngày. Hãy quay lại vào ngày mai nhé!',
          title: 'Đã đạt giới hạn ($totalToday/5)',
        );
      }
      return;
    }
    if (!mounted) {
      return;
    }
    final capturedFile = await Navigator.of(context).push<XFile>(
      MaterialPageRoute(
        builder: (context) => const ProgressCameraCapturePage(),
        fullscreenDialog: true,
      ),
    );

    if (capturedFile == null || !mounted) {
      return;
    }

    final snapFile = File(capturedFile.path);

    final action = await showDialog<_JourneySnapAction>(
      context: context,
      builder: (context) => _JourneySnapDialog(imageFile: snapFile),
    );

    if (action == null || !mounted) {
      return;
    }

    if (action.type == _JourneySnapActionType.saveToDevice) {
      await _saveSnapToDevice(snapFile);
      return;
    }

    final localSnap = _LocalJourneySnap(
      file: snapFile,
      note: action.note.isEmpty ? null : action.note,
      createdAt: DateTime.now(),
    );

    setState(() {
      _localSnaps.insert(0, localSnap);
      _isUploading = true;
    });
    try {
      await ref
          .read(progressRepositoryProvider)
          .uploadSnap(localSnap.file, action.note);
      if (mounted) {
        setState(() => _localSnaps.remove(localSnap));
      } else {
        _localSnaps.remove(localSnap);
      }
      ref.invalidate(journeySnapsProvider);
      ref.invalidate(activeChallengeNotifierProvider);
      if (mounted) {
        AppFeedback.success(
          'Đã tải lên ảnh tiến độ thành công! Chuỗi kỷ luật và thử thách của bạn đã được cập nhật.',
          title: 'Ghi nhận tiến độ thành công',
        );
      }
    } catch (error) {
      _localSnaps.remove(localSnap);
      if (mounted) {
        AppFeedback.error(error.toString(), title: 'Tải ảnh lên thất bại');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _saveSnapToDevice(File imageFile) async {
    try {
      await _mediaChannel.invokeMethod<String>(
        'saveImageToGallery',
        {'path': imageFile.path},
      );
      if (mounted) {
        AppFeedback.success(
          'Ảnh đã được lưu vào thư viện ảnh trên máy.',
          title: 'Đã lưu ảnh',
        );
      }
    } catch (error) {
      if (mounted) {
        AppFeedback.error(
          error.toString(),
          title: 'Không lưu được ảnh',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final metrics = ref.watch(bodyMetricsProvider);
    final badges = ref.watch(badgesProvider);
    final challenges = ref.watch(challengesProvider);
    final snaps = ref.watch(journeySnapsProvider);

    if (user == null) {
      return const _LoginRequiredView();
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _takeSnap,
        backgroundColor: AppColors.primaryOf(context),
        foregroundColor: AppColors.onAccentOf(context),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        icon: _isUploading
            ? SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.onAccentOf(context),
                ),
              )
            : const Icon(Icons.add_photo_alternate_rounded),
        label: Text(
          'Chụp tiến độ',
          style: AppTypography.label(color: AppColors.onAccentOf(context)),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(bodyMetricsProvider);
          ref.invalidate(badgesProvider);
          ref.invalidate(challengesProvider);
          ref.invalidate(journeySnapsProvider);
          ref.invalidate(activeChallengeNotifierProvider);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppResponsive.pagePadding(context).copyWith(bottom: 88),
          children: [
            _ProgressHeader(user: user),
            const SizedBox(height: 16),
            _WeeklyFocusCard(
              user: user,
              snaps: snaps.valueOrNull,
              badges: badges.valueOrNull,
              challenges: challenges.valueOrNull,
            ),
            const SizedBox(height: 16),
            metrics.when(
              data: (metric) => _BodyMetricsSection(metric: metric),
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => ErrorView(message: error.toString()),
            ),
            const SizedBox(height: 16),
            const _MuscleHeatmapCard(),
            const SizedBox(height: 20),
            _JourneySection(
              snaps: snaps,
              localSnaps: _localSnaps,
              registeredAt: user.createdAt ?? DateTime.now(),
              showAllDays: _showAllJourneyDays,
              isUploading: _isUploading,
              onDelete: _deleteSnap,
              onToggleAllDays: () {
                setState(() => _showAllJourneyDays = !_showAllJourneyDays);
              },
            ),
            const SizedBox(height: 20),
            _BadgesSection(badges: badges),
            const SizedBox(height: 20),
            _ChallengesSection(challenges: ref.watch(challengesProvider)),
            const SizedBox(height: 20),
            const _AiInsightCard(),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteSnap(JourneySnapModel snap) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa ảnh hành trình'),
        content: const Text('Bạn có chắc chắn muốn xóa bức ảnh này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) {
      return;
    }

    try {
      await ref.read(progressRepositoryProvider).deleteSnap(snap.id);
      ref.invalidate(journeySnapsProvider);
    } catch (error) {
      if (mounted) {
        AppFeedback.error(error.toString(), title: 'Xóa ảnh thất bại');
      }
    }
  }
}

class _LoginRequiredView extends StatelessWidget {
  const _LoginRequiredView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Yêu cầu đăng nhập',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Vui lòng đăng nhập để theo dõi tiến độ của bạn.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.push('/login'),
                child: const Text('Đi tới đăng nhập'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final nextLevelXp = math.max(user.level, 1) * 1000;
    final levelProgress = (user.xp % 1000) / 1000;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.x5),
      child: Row(
        children: [
          _ProgressRing(
            progress: levelProgress.clamp(0, 1),
            center: 'Lv.${user.level}',
            caption: '${user.xp} XP',
          ),
          const SizedBox(width: AppSpacing.x4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tiến độ',
                  style: AppTypography.headerLargeFor(context),
                ),
                const SizedBox(height: AppSpacing.x2),
                Text(
                  'Còn ${nextLevelXp - user.xp % 1000} XP để lên cấp tiếp theo.',
                  style: AppTypography.bodySmallFor(context),
                ),
                const SizedBox(height: AppSpacing.x3),
                Wrap(
                  spacing: AppSpacing.x2,
                  runSpacing: AppSpacing.x2,
                  children: [
                    _TinyPill(
                      icon: Icons.local_fire_department,
                      label: 'Consistency',
                      color: AppColors.primaryOf(context),
                    ),
                    _TinyPill(
                      icon: Icons.timeline,
                      label: 'Journey',
                      color: AppColors.energyMagenta,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyFocusCard extends StatelessWidget {
  const _WeeklyFocusCard({
    required this.user,
    required this.snaps,
    required this.badges,
    required this.challenges,
  });

  final UserModel user;
  final PageResponse<JourneySnapModel>? snaps;
  final PageResponse<BadgeModel>? badges;
  final PageResponse<ChallengeModel>? challenges;

  @override
  Widget build(BuildContext context) {
    final snapCount = snaps?.content.length ?? 0;
    final badgeCount = badges?.content.length ?? 0;
    final activeChallenges =
        challenges?.content.where((challenge) => challenge.active).length ?? 0;
    final score = ((snapCount * 12) + (badgeCount * 10) + user.level * 6)
        .clamp(0, 100)
        .toInt();

    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            icon: Icons.insights,
            label: 'Điểm ổn định',
            value: '$score%',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricTile(
            icon: Icons.flag_outlined,
            label: 'Thử thách',
            value: '$activeChallenges',
          ),
        ),
      ],
    );
  }
}

class _BodyMetricsSection extends StatelessWidget {
  const _BodyMetricsSection({required this.metric});

  final BodyMetricModel metric;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            icon: Icons.monitor_weight_outlined,
            label: 'Cân nặng',
            value: metric.weightKg == null
                ? '-'
                : '${metric.weightKg!.toStringAsFixed(1)} kg',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricTile(
            icon: Icons.speed,
            label: 'BMI',
            value: metric.bmi?.toStringAsFixed(1) ?? '-',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricTile(
            icon: Icons.percent,
            label: 'Body fat',
            value: metric.bodyFatPercent == null
                ? '-'
                : '${metric.bodyFatPercent!.toStringAsFixed(1)}%',
          ),
        ),
      ],
    );
  }
}

class _MuscleHeatmapCard extends StatelessWidget {
  const _MuscleHeatmapCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.accessibility_new, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                'Muscle Progress Heatmap',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Tính năng đang được phát triển để hiển thị volume tập luyện thực tế theo từng nhóm cơ.',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.52),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.construction_rounded,
                  color: scheme.primary,
                  size: 42,
                ),
                const SizedBox(height: 12),
                Text(
                  'Đang được phát triển',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Heatmap sẽ được mở khi dữ liệu workout logs sẵn sàng.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _ComingSoonChip(label: 'Workout logs'),
              _ComingSoonChip(label: 'Muscle volume'),
              _ComingSoonChip(label: 'Heat intensity'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComingSoonChip extends StatelessWidget {
  const _ComingSoonChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.pending_actions_rounded,
            size: 14,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocalJourneySnap {
  const _LocalJourneySnap({
    required this.file,
    required this.createdAt,
    this.note,
  });

  final File file;
  final DateTime createdAt;
  final String? note;
}

enum _JourneySnapActionType { uploadToApp, saveToDevice }

class _JourneySnapAction {
  const _JourneySnapAction._({
    required this.type,
    required this.note,
  });

  factory _JourneySnapAction.uploadToApp(String note) {
    return _JourneySnapAction._(
      type: _JourneySnapActionType.uploadToApp,
      note: note,
    );
  }

  factory _JourneySnapAction.saveToDevice(String note) {
    return _JourneySnapAction._(
      type: _JourneySnapActionType.saveToDevice,
      note: note,
    );
  }

  final _JourneySnapActionType type;
  final String note;
}

class _JourneySnapDialog extends StatefulWidget {
  const _JourneySnapDialog({
    required this.imageFile,
  });

  final File imageFile;

  @override
  State<_JourneySnapDialog> createState() => _JourneySnapDialogState();
}

class _JourneySnapDialogState extends State<_JourneySnapDialog> {
  late final TextEditingController _noteController;
  late final FocusNode _noteFocusNode;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    _noteFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _noteFocusNode.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String get _note => _noteController.text.trim();

  void _uploadSnap() {
    Navigator.of(context).pop(_JourneySnapAction.uploadToApp(_note));
  }

  void _saveSnapToDevice() {
    Navigator.of(context).pop(_JourneySnapAction.saveToDevice(_note));
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboardHeight = media.viewInsets.bottom;
    final keyboardVisible = keyboardHeight > 0;
    final scheme = Theme.of(context).colorScheme;

    return Dialog.fullscreen(
      backgroundColor: const Color(0xFF060814),
      child: Material(
        color: const Color(0xFF060814),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            const imageRatio = 1.18;
            final keyboardTop = size.height - keyboardHeight;
            final maxImageWidth = math.min(size.width - 28, 410.0);
            final availableImageHeight = keyboardVisible
                ? keyboardTop - media.padding.top - 34
                : size.height;
            final imageWidth = keyboardVisible
                ? math.min(
                    maxImageWidth,
                    math.max(260.0, availableImageHeight / imageRatio),
                  )
                : maxImageWidth;
            final imageHeight = imageWidth * imageRatio;
            final preferredTop =
                media.padding.top + (keyboardVisible ? 16.0 : 94.0);
            final desiredTop =
                keyboardVisible ? keyboardTop - imageHeight - 14 : preferredTop;
            final highestTop = media.padding.top + 10;
            final imageTop = math.max(
              highestTop,
              math.min(preferredTop, desiredTop),
            );

            return Stack(
              children: [
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF070912),
                          Color(0xFF11182A),
                          Color(0xFF071E25),
                        ],
                      ),
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  top: keyboardVisible
                      ? media.padding.top + 4
                      : media.padding.top + 12,
                  left: 18,
                  right: 18,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 160),
                    opacity: keyboardVisible ? 0.0 : 1.0,
                    child: Row(
                      children: [
                        IconButton.filledTonal(
                          onPressed: () => Navigator.of(context).pop(),
                          style: IconButton.styleFrom(
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.12),
                            foregroundColor: Colors.white,
                          ),
                          tooltip: 'Hủy',
                          icon: const Icon(Icons.close_rounded),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'V-FIT Journey',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              Text(
                                'Ghi lại trạng thái hôm nay',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.62),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  top: imageTop,
                  left: (size.width - imageWidth) / 2,
                  width: imageWidth,
                  height: imageHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: scheme.primary.withValues(alpha: 0.36),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.18),
                          blurRadius: 34,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(29),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(
                            widget.imageFile,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.center,
                                colors: [
                                  Color(0x99000000),
                                  Color(0x00000000),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 16,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(0xCC101420),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.18),
                                ),
                              ),
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 8, 12, 6),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.edit_note_rounded,
                                          color: scheme.primary,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextField(
                                            focusNode: _noteFocusNode,
                                            controller: _noteController,
                                            inputFormatters: [
                                              LengthLimitingTextInputFormatter(
                                                30,
                                              ),
                                            ],
                                            maxLines: 1,
                                            textInputAction:
                                                TextInputAction.done,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                            ),
                                            cursorColor: scheme.primary,
                                            decoration: InputDecoration(
                                              isDense: true,
                                              hintText: 'Thêm ghi chú tiến độ',
                                              hintStyle: TextStyle(
                                                color: Colors.white
                                                    .withValues(alpha: 0.58),
                                                fontWeight: FontWeight.w700,
                                              ),
                                              border: InputBorder.none,
                                              counterText: '',
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 6,
                                              ),
                                            ),
                                            onSubmitted: (_) =>
                                                FocusScope.of(context)
                                                    .unfocus(),
                                          ),
                                        ),
                                      ],
                                    ),
                                    ValueListenableBuilder<TextEditingValue>(
                                      valueListenable: _noteController,
                                      builder: (context, value, _) {
                                        final length =
                                            value.text.characters.length;
                                        final nearLimit = length >= 26;
                                        return Align(
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            '$length/30 ký tự',
                                            style: TextStyle(
                                              color: nearLimit
                                                  ? scheme.primary
                                                  : Colors.white.withValues(
                                                      alpha: 0.62,
                                                    ),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  left: AppResponsive.horizontalPadding(context),
                  right: AppResponsive.horizontalPadding(context),
                  bottom: keyboardVisible ? -120 : media.padding.bottom + 28,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 11,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.24),
                                ),
                              ),
                              icon: const Icon(Icons.close_rounded, size: 18),
                              label: const Text('Hủy'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _uploadSnap,
                              style: FilledButton.styleFrom(
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.14),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 11,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              icon: const Icon(
                                Icons.cloud_upload_rounded,
                                size: 18,
                              ),
                              label: const Text('Đăng ảnh'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _saveSnapToDevice,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: scheme.primary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 11,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                                side: BorderSide(
                                  color: scheme.primary.withValues(alpha: 0.72),
                                ),
                              ),
                              icon: const Icon(
                                Icons.save_alt_rounded,
                                size: 18,
                              ),
                              label: const Text('Lưu ảnh'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (keyboardVisible)
                  Positioned(
                    top: media.padding.top + 8,
                    left: 14,
                    child: IconButton.filledTonal(
                      onPressed: () => FocusScope.of(context).unfocus(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.14),
                        foregroundColor: Colors.white,
                      ),
                      tooltip: 'Ẩn bàn phím',
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _JourneySection extends StatelessWidget {
  const _JourneySection({
    required this.snaps,
    required this.localSnaps,
    required this.registeredAt,
    required this.showAllDays,
    required this.isUploading,
    required this.onDelete,
    required this.onToggleAllDays,
  });

  final AsyncValue<PageResponse<JourneySnapModel>> snaps;
  final List<_LocalJourneySnap> localSnaps;
  final DateTime registeredAt;
  final bool showAllDays;
  final bool isUploading;
  final ValueChanged<JourneySnapModel> onDelete;
  final VoidCallback onToggleAllDays;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Ảnh hành trình',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isUploading) ...[
            const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
          ],
          TextButton.icon(
            onPressed: onToggleAllDays,
            icon: Icon(
              showAllDays
                  ? Icons.photo_library_outlined
                  : Icons.calendar_month_outlined,
              size: 18,
            ),
            label: Text(showAllDays ? 'Ảnh hôm nay' : 'Tất cả ngày'),
          ),
        ],
      ),
      child: snaps.when(
        data: (page) {
          if (page.content.isEmpty && localSnaps.isEmpty && !showAllDays) {
            return const EmptyView(
              message: 'Hãy chụp một bức ảnh để bắt đầu theo dõi.',
            );
          }

          return _JourneySnapGrid(
            localSnaps: localSnaps,
            snaps: page.content,
            registeredAt: registeredAt,
            showAllDays: showAllDays,
            onDelete: onDelete,
          );
        },
        loading: () => localSnaps.isEmpty
            ? const LoadingView()
            : _JourneySnapGrid(
                localSnaps: localSnaps,
                snaps: const [],
                registeredAt: registeredAt,
                showAllDays: showAllDays,
                onDelete: onDelete,
              ),
        error: (error, _) => localSnaps.isEmpty
            ? ErrorView(message: error.toString())
            : _JourneySnapGrid(
                localSnaps: localSnaps,
                snaps: const [],
                registeredAt: registeredAt,
                showAllDays: showAllDays,
                onDelete: onDelete,
              ),
      ),
    );
  }
}

class _JourneySnapGrid extends StatelessWidget {
  const _JourneySnapGrid({
    required this.localSnaps,
    required this.snaps,
    required this.registeredAt,
    required this.showAllDays,
    required this.onDelete,
  });

  final List<_LocalJourneySnap> localSnaps;
  final List<JourneySnapModel> snaps;
  final DateTime registeredAt;
  final bool showAllDays;
  final ValueChanged<JourneySnapModel> onDelete;

  @override
  Widget build(BuildContext context) {
    final allEntries = [
      ...localSnaps.map(_JourneySnapEntry.local),
      ...snaps.map(_JourneySnapEntry.remote),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final groupedEntries = <DateTime, List<_JourneySnapEntry>>{};
    for (final entry in allEntries) {
      final day = _journeyDayKey(entry.createdAt);
      groupedEntries.putIfAbsent(day, () => []).add(entry);
    }

    if (showAllDays) {
      return _JourneyLocketTimeline(
        groupedEntries: groupedEntries,
        registeredAt: registeredAt,
      );
    }

    final today = _journeyDayKey(DateTime.now());
    final todayEntries = groupedEntries[today] ?? const <_JourneySnapEntry>[];
    if (todayEntries.isEmpty) {
      return const EmptyView(
        message:
            'Hôm nay chưa có ảnh. Bấm nút camera để chụp ảnh hành trình hôm nay.',
      );
    }

    final groups = <MapEntry<DateTime, List<_JourneySnapEntry>>>[
      MapEntry(today, todayEntries),
    ]..sort((a, b) => b.key.compareTo(a.key));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groups.map((group) {
        return Padding(
          padding: EdgeInsets.only(bottom: group.value.isEmpty ? 8 : 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${DateFormat('dd/MM/yyyy').format(group.key)} • ${group.value.length} ảnh',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              if (group.value.isEmpty)
                const SizedBox.shrink()
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: group.value.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {
                    final entry = group.value[index];
                    final localSnap = entry.localSnap;
                    if (localSnap != null) {
                      return _LocalJourneySnapCard(snap: localSnap);
                    }

                    final remoteSnap = entry.remoteSnap!;
                    return _JourneySnapCard(
                      snap: remoteSnap,
                      onDelete: () => onDelete(remoteSnap),
                    );
                  },
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

DateTime _journeyDayKey(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

List<DateTime> _journeyDaysBetween(DateTime start, DateTime end) {
  final firstDay = _journeyDayKey(start);
  final lastDay = _journeyDayKey(end);
  final days = <DateTime>[];
  for (var day = firstDay;
      !day.isAfter(lastDay);
      day = day.add(const Duration(days: 1))) {
    days.add(day);
  }
  return days;
}

List<DateTime> _journeyMonthsBetween(DateTime start, DateTime end) {
  final firstDay = _journeyDayKey(start);
  final lastDay = _journeyDayKey(end);
  final months = <DateTime>[];
  for (var month = DateTime(firstDay.year, firstDay.month);
      !month.isAfter(DateTime(lastDay.year, lastDay.month));
      month = DateTime(month.year, month.month + 1)) {
    months.add(month);
  }
  return months;
}

List<DateTime> _journeyDaysInMonth(
  DateTime month,
  DateTime registeredAt,
  DateTime end,
) {
  final firstAllowedDay = _journeyDayKey(registeredAt);
  final lastAllowedDay = _journeyDayKey(end);
  final firstMonthDay = DateTime(month.year, month.month);
  final lastMonthDay = DateTime(month.year, month.month + 1, 0);
  final startDay =
      firstMonthDay.isBefore(firstAllowedDay) ? firstAllowedDay : firstMonthDay;
  final finishDay =
      lastMonthDay.isAfter(lastAllowedDay) ? lastAllowedDay : lastMonthDay;

  return _journeyDaysBetween(startDay, finishDay);
}

class _JourneySnapEntry {
  const _JourneySnapEntry._({
    required this.createdAt,
    this.localSnap,
    this.remoteSnap,
  });

  factory _JourneySnapEntry.local(_LocalJourneySnap snap) {
    return _JourneySnapEntry._(
      createdAt: snap.createdAt,
      localSnap: snap,
    );
  }

  factory _JourneySnapEntry.remote(JourneySnapModel snap) {
    return _JourneySnapEntry._(
      createdAt: snap.createdAt,
      remoteSnap: snap,
    );
  }

  final DateTime createdAt;
  final _LocalJourneySnap? localSnap;
  final JourneySnapModel? remoteSnap;

  String? get note => localSnap?.note ?? remoteSnap?.note;
}

void _debugJourneyNavigationLog(String message) {
  debugPrint('[Journey navigation] $message');
}

class _JourneyLocketTimeline extends StatefulWidget {
  const _JourneyLocketTimeline({
    required this.groupedEntries,
    required this.registeredAt,
  });

  final Map<DateTime, List<_JourneySnapEntry>> groupedEntries;
  final DateTime registeredAt;

  @override
  State<_JourneyLocketTimeline> createState() => _JourneyLocketTimelineState();
}

class _JourneyLocketTimelineState extends State<_JourneyLocketTimeline> {
  int _monthIndex = 0;
  String? _notice;
  int _noticeVersion = 0;

  void _showTimelineLog(String message) {
    _debugJourneyNavigationLog(message);
    if (!mounted) {
      return;
    }
    final version = ++_noticeVersion;
    setState(() => _notice = message);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (!mounted || version != _noticeVersion) {
        return;
      }
      setState(() => _notice = null);
    });
  }

  void _moveMonth(int delta, int monthCount) {
    final nextIndex = _monthIndex + delta;
    if (nextIndex < 0) {
      _showTimelineLog('Đây đã là tháng mới nhất.');
      return;
    }
    if (nextIndex >= monthCount) {
      _showTimelineLog('Không còn tháng cũ hơn để xem.');
      return;
    }
    setState(() => _monthIndex = nextIndex);
  }

  @override
  Widget build(BuildContext context) {
    final months = _journeyMonthsBetween(widget.registeredAt, DateTime.now())
      ..sort((a, b) => b.compareTo(a));
    if (months.isEmpty) {
      return const SizedBox.shrink();
    }
    _monthIndex = _monthIndex.clamp(0, months.length - 1);

    return Column(
      children: [months[_monthIndex]].map((month) {
        final days = _journeyDaysInMonth(
          month,
          widget.registeredAt,
          DateTime.now(),
        );
        final monthEntries = days
            .expand(
              (day) =>
                  widget.groupedEntries[day] ?? const <_JourneySnapEntry>[],
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: AppCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: () => _moveMonth(-1, months.length),
                      icon: const Icon(Icons.chevron_left),
                      tooltip: 'Tháng mới hơn',
                    ),
                    Expanded(
                      child: Text(
                        DateFormat('MMMM yyyy').format(month),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    Text(
                      '${monthEntries.length} ảnh',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: () => _moveMonth(1, months.length),
                      icon: const Icon(Icons.chevron_right),
                      tooltip: 'Tháng cũ hơn',
                    ),
                  ],
                ),
                if (_notice != null) ...[
                  const SizedBox(height: 10),
                  _JourneyInlineNotice(message: _notice!),
                ],
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: days.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                  ),
                  itemBuilder: (context, index) {
                    final day = days[index];
                    final dayEntries = widget.groupedEntries[day] ?? const [];
                    return _JourneyMiniDayTile(
                      day: day,
                      entries: dayEntries,
                      monthEntries: monthEntries,
                      onNavigationLog: _showTimelineLog,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _JourneyInlineNotice extends StatelessWidget {
  const _JourneyInlineNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.secondary.withValues(alpha: 0.18)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: scheme.onSecondaryContainer,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _JourneyMiniDayTile extends StatelessWidget {
  const _JourneyMiniDayTile({
    required this.day,
    required this.entries,
    required this.monthEntries,
    required this.onNavigationLog,
  });

  final DateTime day;
  final List<_JourneySnapEntry> entries;
  final List<_JourneySnapEntry> monthEntries;
  final ValueChanged<String> onNavigationLog;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final entry = entries.isEmpty ? null : entries.first;

    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: entry == null
            ? null
            : () {
                showDialog<void>(
                  context: context,
                  builder: (_) => _JourneyMonthViewer(
                    entries: monthEntries,
                    initialIndex: monthEntries.indexOf(entry),
                    onNavigationLog: onNavigationLog,
                  ),
                );
              },
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (entry != null)
              _JourneyEntryImage(entry: entry)
            else
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
            Positioned(
              left: 4,
              bottom: 3,
              child: Text(
                '${day.day}',
                style: TextStyle(
                  color: entry == null ? scheme.onSurfaceVariant : Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  shadows: entry == null
                      ? null
                      : const [
                          Shadow(
                            blurRadius: 4,
                            color: Colors.black,
                          ),
                        ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JourneyMonthViewer extends StatefulWidget {
  const _JourneyMonthViewer({
    required this.entries,
    required this.initialIndex,
    required this.onNavigationLog,
  });

  final List<_JourneySnapEntry> entries;
  final int initialIndex;
  final ValueChanged<String> onNavigationLog;

  @override
  State<_JourneyMonthViewer> createState() => _JourneyMonthViewerState();
}

class _JourneyMonthViewerState extends State<_JourneyMonthViewer> {
  late int _index = widget.initialIndex.clamp(0, widget.entries.length - 1);
  String? _notice;
  int _noticeVersion = 0;

  void _showViewerLog(String message) {
    widget.onNavigationLog(message);
    if (!mounted) {
      return;
    }
    final version = ++_noticeVersion;
    setState(() => _notice = message);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (!mounted || version != _noticeVersion) {
        return;
      }
      setState(() => _notice = null);
    });
  }

  void _move(int delta) {
    if (widget.entries.isEmpty) {
      _showViewerLog('Tháng này chưa có ảnh để xem.');
      return;
    }
    final nextIndex = _index + delta;
    if (nextIndex < 0) {
      _showViewerLog('Đây đã là ảnh đầu tiên của tháng.');
      return;
    }
    if (nextIndex >= widget.entries.length) {
      _showViewerLog('Đây đã là ảnh cuối cùng của tháng.');
      return;
    }
    setState(() => _index = nextIndex);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final entry = widget.entries[_index];

    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: _JourneyEntryImage(entry: entry),
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat('dd/MM/yyyy').format(entry.createdAt),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 10,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton.filled(
                  onPressed: () => _move(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
              ),
            ),
            Positioned(
              right: 10,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton.filled(
                  onPressed: () => _move(1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ),
            ),
            if (_notice != null)
              Positioned(
                top: 68,
                left: 24,
                right: 24,
                child: _JourneyViewerNotice(message: _notice!),
              ),
            if (entry.note != null && entry.note!.isNotEmpty)
              Positioned(
                left: 24,
                right: 24,
                bottom: 24,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surface.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      entry.note!,
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _JourneyViewerNotice extends StatelessWidget {
  const _JourneyViewerNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _JourneyEntryImage extends StatelessWidget {
  const _JourneyEntryImage({required this.entry});

  final _JourneySnapEntry entry;

  @override
  Widget build(BuildContext context) {
    final localSnap = entry.localSnap;
    if (localSnap != null) {
      return Image.file(
        localSnap.file,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    final remoteSnap = entry.remoteSnap!;
    return Image.network(
      MediaUrlResolver.resolve(remoteSnap.photoUrl),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return const Center(
          child: SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('[JourneyImage] Failed to load remote entry image: $error');
        return const _JourneyImageError();
      },
    );
  }
}

class _LocalJourneySnapCard extends StatelessWidget {
  const _LocalJourneySnapCard({required this.snap});

  final _LocalJourneySnap snap;

  @override
  Widget build(BuildContext context) {
    return _JourneyPhotoTile(
      image: Image.file(
        snap.file,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      ),
      createdAt: snap.createdAt,
      note: snap.note,
      badge: 'Đang đồng bộ',
    );
  }
}

class _JourneySnapCard extends StatelessWidget {
  const _JourneySnapCard({
    required this.snap,
    required this.onDelete,
  });

  final JourneySnapModel snap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final imageUrl = MediaUrlResolver.resolve(snap.photoUrl);

    return _JourneyPhotoTile(
      image: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }

          return const Center(
            child: SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint(
            '[JourneyImage] Failed to load remote snap image: $imageUrl, error: $error',
          );
          return const _JourneyImageError();
        },
      ),
      createdAt: snap.createdAt,
      note: snap.note,
      onDelete: onDelete,
    );
  }
}

class _JourneyPhotoTile extends StatelessWidget {
  const _JourneyPhotoTile({
    required this.image,
    required this.createdAt,
    this.note,
    this.badge,
    this.onDelete,
  });

  final Widget image;
  final DateTime createdAt;
  final String? note;
  final String? badge;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: DecoratedBox(
        decoration: BoxDecoration(color: scheme.surfaceContainerHighest),
        child: Stack(
          fit: StackFit.expand,
          children: [
            image,
            // Sleek gradient overlay at the bottom for better contrast
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 64,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Locket-style Glassmorphism Pill at bottom left
            Positioned(
              left: 8,
              bottom: 8,
              right: 8,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat.MMMd().format(createdAt),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (note != null && note!.isNotEmpty)
                          Text(
                            note!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (badge != null)
              Positioned(
                top: 8,
                left: 8,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (onDelete != null)
              Positioned(
                top: 6,
                right: 6,
                child: Tooltip(
                  message: 'Xóa ảnh',
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.error.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.34),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.28),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: SizedBox.square(
                      dimension: 34,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 20,
                        color: scheme.onError,
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _JourneyImageError extends StatelessWidget {
  const _JourneyImageError();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, color: scheme.onSurfaceVariant),
          const SizedBox(height: 4),
          Text(
            'Không tải được ảnh',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgesSection extends StatelessWidget {
  const _BadgesSection({required this.badges});

  final AsyncValue<PageResponse<BadgeModel>> badges;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Huy hiệu',
      child: badges.when(
        data: (page) => page.content.isEmpty
            ? const EmptyView(message: 'Chưa đạt huy hiệu nào.')
            : Wrap(
                spacing: 12,
                runSpacing: 12,
                children: page.content
                    .map(
                      (badge) => Chip(
                        avatar: const Icon(Icons.workspace_premium, size: 18),
                        label: Text(badge.name),
                      ),
                    )
                    .toList(),
              ),
        loading: () => const LoadingView(),
        error: (error, _) => AppFeedbackPanel(
          compact: true,
          type: AppFeedbackType.warning,
          title: 'Chưa tải được huy hiệu',
          message: 'Kéo xuống để thử tải lại dữ liệu.',
        ),
      ),
    );
  }
}

class _ChallengesSection extends ConsumerWidget {
  const _ChallengesSection({required this.challenges});

  final AsyncValue<PageResponse<ChallengeModel>> challenges;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeState = ref.watch(activeChallengeNotifierProvider);
    final scheme = Theme.of(context).colorScheme;

    return _Section(
      title: 'Thử thách',
      child: challenges.when(
        data: (page) {
          if (page.content.isEmpty) {
            return const EmptyView(
              message: 'Chưa có thử thách nào đang hoạt động.',
            );
          }
          return Column(
            children: page.content.map((challenge) {
              // Find matching active participation safely
              ParticipationModel? participation;
              for (final p in activeState.activeParticipations) {
                if (p.challengeId == challenge.id) {
                  participation = p;
                  break;
                }
              }

              final isJoined = participation != null;
              // Chỉ coi là hoàn thành khi số ngày check-in thực tế >= mục tiêu
              final actualProgress =
                  isJoined ? participation.verifiedPhotos.length : 0;
              final isCompleted = isJoined &&
                  challenge.targetValue > 0 &&
                  actualProgress >= challenge.targetValue;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isCompleted
                                ? Icons.verified_rounded
                                : (isJoined
                                    ? Icons.bolt_rounded
                                    : Icons.flag_outlined),
                            color: isCompleted
                                ? Colors.green
                                : (isJoined
                                    ? scheme.primary
                                    : scheme.onSurfaceVariant),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  challenge.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                                Text(
                                  'Mục tiêu: ${challenge.targetValue} • ${challenge.xpReward} XP',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isJoined)
                            ElevatedButton(
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Xác nhận tham gia'),
                                    content: Text(
                                      'Bạn có muốn tham gia thử thách "${challenge.title}"?\n\nSau khi xác nhận, bạn không thể thay đổi mục tiêu này.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(false),
                                        child: const Text('Hủy'),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(true),
                                        child: const Text('Xác nhận tham gia'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm != true) return;
                                await ref
                                    .read(
                                      activeChallengeNotifierProvider.notifier,
                                    )
                                    .joinChallenge(challenge.id);
                                AppFeedback.success(
                                  'Đã đăng ký thử thách "${challenge.title}" thành công. Hãy chụp ảnh tiến độ mỗi ngày để duy trì kỷ luật nhé!',
                                  title: 'Tham gia thành công',
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                backgroundColor: scheme.primary,
                                foregroundColor: scheme.onPrimary,
                              ),
                              child: const Text('Tham gia'),
                            )
                          else if (isCompleted)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Đã xong',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Đang tập',
                                style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (isJoined) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tiến độ: $actualProgress / ${challenge.targetValue} ngày',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Chuỗi: ${participation.currentStreak} ngày',
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: challenge.targetValue > 0
                                ? (actualProgress / challenge.targetValue)
                                    .clamp(0.0, 1.0)
                                : 0.0,
                            backgroundColor: scheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isCompleted ? Colors.green : scheme.primary,
                            ),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            challenge.targetValue > 0
                                ? '${((actualProgress / challenge.targetValue) * 100).clamp(0, 100).toStringAsFixed(0)}% hoàn thành'
                                : '0% hoàn thành',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color:
                                  isCompleted ? Colors.green : scheme.primary,
                            ),
                          ),
                        ),
                        Builder(
                          builder: (context) {
                            final p = participation;
                            if (p == null) return const SizedBox.shrink();

                            final now = DateTime.now();
                            final lastCheckin = p.lastCheckinDate;

                            bool showRevive = false;
                            if (lastCheckin != null) {
                              try {
                                final lastDate = DateTime.parse(lastCheckin);
                                final diff = now.difference(lastDate).inDays;
                                if (diff > 1 &&
                                    p.currentStreak < p.maxStreakAchieved) {
                                  showRevive = true;
                                }
                              } catch (_) {}
                            }

                            if (!showRevive) return const SizedBox.shrink();

                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title:
                                              const Text('Cứu chuỗi kỷ luật?'),
                                          content: const Text(
                                            'Bạn có chắc chắn muốn sử dụng 150 V-Points để khôi phục chuỗi ngày kỷ luật tối đa không?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pop(false),
                                              child: const Text('Hủy'),
                                            ),
                                            FilledButton(
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pop(true),
                                              child: const Text(
                                                'Cứu chuỗi (150 VP)',
                                              ),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        await ref
                                            .read(
                                              activeChallengeNotifierProvider
                                                  .notifier,
                                            )
                                            .reviveStreak(challenge.id);
                                        AppFeedback.success(
                                          'Đã khôi phục chuỗi kỷ luật của bạn thành công!',
                                          title: 'Khôi phục thành công',
                                        );
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.favorite_rounded,
                                      color: Colors.pink,
                                      size: 16,
                                    ),
                                    label: const Text(
                                      'Cứu chuỗi (150 V-Points)',
                                      style: TextStyle(
                                        color: Colors.pink,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(message: error.toString()),
      ),
    );
  }
}

class _AiInsightCard extends StatelessWidget {
  const _AiInsightCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.auto_awesome, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Challenge Coach',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tính năng đang được phát triển để nhận diện thói quen xấu như bỏ cuộc, nghỉ tập quá lâu hoặc tập lệch nhóm cơ, rồi đề xuất thử thách có thể xác nhận bằng check-in, ảnh hành trình và lịch sử workout.',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryOf(context).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            child: Icon(icon, color: AppColors.primaryOf(context), size: 20),
          ),
          const SizedBox(height: AppSpacing.x3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.metricFor(context),
          ),
          const SizedBox(height: AppSpacing.x1),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmallFor(context),
          ),
        ],
      ),
    );
  }
}

class _TinyPill extends StatelessWidget {
  const _TinyPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({
    required this.progress,
    required this.center,
    required this.caption,
  });

  final double progress;
  final String center;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 96,
      child: CustomPaint(
        painter: _ProgressRingPainter(
          progress: progress,
          color: Theme.of(context).colorScheme.primary,
          trackColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                caption,
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  const _ProgressRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  final double progress;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 7;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
  }
}
