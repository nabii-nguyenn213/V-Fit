
import 'package:flutter/material.dart';

import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_radius.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../widgets/ai_realtime_camera_view.dart';

// ─── Trạng thái màn hình ────────────────────────────────────────────────────
enum _FormPhase {
  ready,    // Màn hình chờ, chưa bắt đầu
  checking, // Đang kiểm tra realtime
  summary,  // Hiện tổng kết
}

class AiFormCheckPage extends StatefulWidget {
  const AiFormCheckPage({
    super.key,
    required this.exerciseId,
  });

  final String exerciseId;

  @override
  State<AiFormCheckPage> createState() => _AiFormCheckPageState();
}

class _AiFormCheckPageState extends State<AiFormCheckPage> {
  _FormPhase _phase = _FormPhase.ready;

  // Tích lũy trong session
  _FormCheckFeedback? _latestFeedback;
  int _maxRepCount = 0;
  int _bestScore = 0;
  final List<Map<String, dynamic>> _allErrors = [];

  void _onFeedback(Map<String, dynamic> feedback) {
    if (_phase != _FormPhase.checking) return;
    final parsed = _FormCheckFeedback.fromJson(feedback);
    setState(() {
      _latestFeedback = parsed;
      if (parsed.repCount > _maxRepCount) _maxRepCount = parsed.repCount;
      if (parsed.score > _bestScore) _bestScore = parsed.score;
      for (final e in parsed.errors) {
        _allErrors.add(e);
      }
    });
  }

  void _startChecking() {
    setState(() {
      _phase = _FormPhase.checking;
      _latestFeedback = null;
      _maxRepCount = 0;
      _bestScore = 0;
      _allErrors.clear();
    });
  }

  void _stopChecking() {
    setState(() => _phase = _FormPhase.summary);
  }

  void _restart() {
    setState(() => _phase = _FormPhase.ready);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Camera luôn sẵn sàng ở background
        AiRealtimeCameraView(
          title: 'AI Form Check',
          webSocketPath: '/ws/ai/form-check',
          queryParameters: {
            'exerciseId': widget.exerciseId,
            'cameraView': 'side',
          },
          captureInterval: const Duration(milliseconds: 200),
          readyText: 'Camera đã sẵn sàng.',
          streamingText: 'AI đang kiểm tra chuyển động...',
          stoppedText: 'Đã dừng kiểm tra form.',
          showStartStopButton: false,
          onFeedbackReceived: _onFeedback,
          feedbackBuilder: (context, feedbackJson, statusText) {
            if (_phase == _FormPhase.ready || _phase == _FormPhase.summary) {
              return const SizedBox.shrink();
            }
            return _LiveFeedbackPanel(
              feedback: _latestFeedback,
              statusText: statusText,
            );
          },
        ),

        // Màn hình chờ
        if (_phase == _FormPhase.ready)
          _ReadyOverlay(
            exerciseId: widget.exerciseId,
            onStart: _startChecking,
          ),

        // Nút dừng khi đang check
        if (_phase == _FormPhase.checking)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _StopBar(onStop: _stopChecking),
          ),

        // Màn hình tổng kết
        if (_phase == _FormPhase.summary)
          _SummaryOverlay(
            repCount: _maxRepCount,
            bestScore: _bestScore,
            allErrors: _allErrors,
            onRestart: _restart,
            onExit: () => Navigator.of(context).maybePop(),
          ),
      ],
    );
  }
}

// ─── Màn hình chờ (Ready) ─────────────────────────────────────────────────────
class _ReadyOverlay extends StatelessWidget {
  const _ReadyOverlay({
    required this.exerciseId,
    required this.onStart,
  });

  final String exerciseId;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.80),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.x5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.x4),
                // Icon + tiêu đề
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primaryOf(context).withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryOf(context).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Icon(
                      Icons.sports_gymnastics_rounded,
                      color: AppColors.primaryOf(context),
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.x4),
                Text(
                  'Kiểm tra form tập',
                  textAlign: TextAlign.center,
                  style: AppTypography.headerLargeFor(context)
                      .copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.x2),
                Text(
                  'AI sẽ phân tích tư thế và đếm rep theo thời gian thực.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyFor(context)
                      .copyWith(color: Colors.white70),
                ),
                const SizedBox(height: AppSpacing.x5),

                // Hướng dẫn
                _TipCard(
                  icon: Icons.smartphone_rounded,
                  text: 'Đặt điện thoại ngang tầm hông, nhìn từ bên cạnh.',
                ),
                const SizedBox(height: AppSpacing.x2),
                _TipCard(
                  icon: Icons.person_outline_rounded,
                  text: 'Giữ toàn thân trong khung hình khi tập.',
                ),
                const SizedBox(height: AppSpacing.x2),
                _TipCard(
                  icon: Icons.light_mode_outlined,
                  text: 'Đảm bảo ánh sáng đủ để camera nhận diện rõ.',
                ),

                const Spacer(),

                FilledButton.icon(
                  onPressed: onStart,
                  icon: const Icon(Icons.play_circle_outline_rounded),
                  label: const Text('Bắt đầu kiểm tra'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: AppSpacing.x3),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white38),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Quay lại',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmallFor(context)
                  .copyWith(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Nút Dừng khi đang check ──────────────────────────────────────────────────
class _StopBar extends StatelessWidget {
  const _StopBar({required this.onStop});
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x4,
        0,
        AppSpacing.x4,
        AppSpacing.x5,
      ),
      child: FilledButton.icon(
        onPressed: onStop,
        icon: const Icon(Icons.stop_circle_outlined),
        label: const Text('Dừng & Xem kết quả'),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.error,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

// ─── Panel feedback realtime ──────────────────────────────────────────────────
class _LiveFeedbackPanel extends StatelessWidget {
  const _LiveFeedbackPanel({
    required this.feedback,
    required this.statusText,
  });

  final _FormCheckFeedback? feedback;
  final String? statusText;

  @override
  Widget build(BuildContext context) {
    final color = switch (feedback?.severity) {
      'WARN' => AppColors.warning,
      'RATE_LIMITED' => AppColors.error,
      'ERROR' => AppColors.error,
      'UNKNOWN' => AppColors.error,
      _ => AppColors.success,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        color: AppColors.surface1Of(context),
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: color, size: 24),
              const SizedBox(width: AppSpacing.x2),
              Expanded(
                child: feedback == null
                    ? Text(
                        'Đang chờ phản hồi AI...',
                        style: AppTypography.headerMediumFor(context),
                      )
                    : Text(
                        'Số rep: ${feedback!.repCount}',
                        style: AppTypography.headerLargeFor(context).copyWith(
                          color: AppColors.energyMagenta,
                          fontWeight: FontWeight.bold,
                          fontSize: 26,
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x2),
          Text(
            feedback?.message ??
                statusText ??
                'Giữ toàn bộ chuyển động trong khung hình.',
            style: AppTypography.headerMediumFor(context).copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (feedback?.coachingCue != null &&
              feedback?.coachingCue !=
                  'Tiếp tục giữ nhịp độ và kiểm soát động tác.') ...[
            const SizedBox(height: AppSpacing.x1),
            Text(
              feedback!.coachingCue!,
              style: AppTypography.bodyFor(context).copyWith(
                color: AppColors.textSecondaryOf(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Màn hình tổng kết ────────────────────────────────────────────────────────
class _SummaryOverlay extends StatelessWidget {
  const _SummaryOverlay({
    required this.repCount,
    required this.bestScore,
    required this.allErrors,
    required this.onRestart,
    required this.onExit,
  });

  final int repCount;
  final int bestScore;
  final List<Map<String, dynamic>> allErrors;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  // Nhóm lỗi và lấy top 3 phổ biến nhất
  List<String> get _topErrors {
    final freq = <String, int>{};
    for (final e in allErrors) {
      final key = e['message']?.toString() ?? e['code']?.toString() ?? '';
      if (key.isNotEmpty) freq[key] = (freq[key] ?? 0) + 1;
    }
    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(3).map((e) => e.key).toList();
  }

  Color _scoreColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 50) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final accent = _scoreColor(bestScore);
    final errors = _topErrors;

    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.88),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.x5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                        border: Border.all(color: accent.withValues(alpha: 0.5)),
                      ),
                      child: Icon(
                        Icons.sports_score_rounded,
                        color: accent,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.x3),
                    Expanded(
                      child: Text(
                        'Kết quả kiểm tra form',
                        style: AppTypography.headerMediumFor(context)
                            .copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.x5),

                // Thống kê chính
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Số rep',
                        value: '$repCount',
                        icon: Icons.repeat_rounded,
                        color: AppColors.energyMagenta,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.x3),
                    Expanded(
                      child: _StatCard(
                        label: 'Điểm form',
                        value: '$bestScore',
                        icon: Icons.star_rounded,
                        color: accent,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.x4),

                // Lỗi phổ biến
                if (errors.isNotEmpty) ...[
                  Text(
                    'Lỗi thường gặp',
                    style: AppTypography.label(color: Colors.white70),
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  ...errors.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.x2),
                      child: _ErrorRow(message: e),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.x4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.input),
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: AppSpacing.x3),
                        Expanded(
                          child: Text(
                            repCount == 0
                                ? 'Chưa ghi nhận rep nào. Thử lại với tư thế rõ hơn.'
                                : 'Không phát hiện lỗi form đáng kể!',
                            style: AppTypography.bodyFor(context)
                                .copyWith(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const Spacer(),

                FilledButton.icon(
                  onPressed: onRestart,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Làm lại'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: AppSpacing.x3),
                OutlinedButton.icon(
                  onPressed: onExit,
                  icon: const Icon(Icons.exit_to_app_rounded, color: Colors.white),
                  label: const Text(
                    'Thoát',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white38),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: AppSpacing.x2),
          Text(
            value,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.label(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x3,
        vertical: AppSpacing.x2,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.warning, size: 16,),
          const SizedBox(width: AppSpacing.x2),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmallFor(context)
                  .copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Data model ──────────────────────────────────────────────────────────────
class _FormCheckFeedback {
  const _FormCheckFeedback({
    required this.score,
    required this.message,
    required this.severity,
    required this.fallback,
    required this.repCount,
    required this.phase,
    required this.repLabel,
    required this.repCounterEnabled,
    required this.repConfidence,
    required this.keypointsCount,
    required this.frameIndex,
    required this.metrics,
    required this.errors,
    required this.feedbackDetails,
    this.coachingCue,
  });

  final int score;
  final String message;
  final String severity;
  final bool fallback;
  final int repCount;
  final String phase;
  final String repLabel;
  final bool repCounterEnabled;
  final double repConfidence;
  final int keypointsCount;
  final int frameIndex;
  final Map<String, dynamic> metrics;
  final List<Map<String, dynamic>> errors;
  final List<Map<String, dynamic>> feedbackDetails;
  final String? coachingCue;

  String get phaseLabel {
    if (!repCounterEnabled && phase != 'no_pose') return 'AI rep offline';
    return switch (phase) {
      'down' => 'Xuống',
      'up' => 'Lên',
      'other' => 'Ngoài form',
      'unknown' => 'Đang bắt form',
      'no_pose' => 'Chưa thấy người',
      _ => phase,
    };
  }

  factory _FormCheckFeedback.fromJson(Map<String, dynamic> json) {
    final feedbackDetails = _listOfMaps(
      json['feedback_details'] ?? json['feedbackDetails'] ?? json['feedback'],
    );
    final errors = _listOfMaps(json['errors'] ?? json['formErrors']);
    final firstFeedback =
        feedbackDetails.isEmpty ? null : feedbackDetails.first;

    return _FormCheckFeedback(
      score: (json['score'] as num?)?.toInt() ?? 0,
      message: json['summary']?.toString() ??
          json['message']?.toString() ??
          firstFeedback?['warning']?.toString() ??
          'Chưa có phản hồi.',
      severity: json['severity']?.toString() ?? 'INFO',
      fallback: json['fallback'] == true,
      repCount: (json['rep_count'] as num?)?.toInt() ??
          (json['repCount'] as num?)?.toInt() ??
          0,
      phase: json['phase']?.toString() ??
          json['rep_phase']?.toString() ??
          json['repPhase']?.toString() ??
          'unknown',
      repLabel:
          json['rep_label']?.toString() ?? json['repLabel']?.toString() ?? '',
      repCounterEnabled: json['rep_counter_enabled'] == true ||
          json['repCounterEnabled'] == true,
      repConfidence: (json['rep_confidence'] as num?)?.toDouble() ??
          (json['repConfidence'] as num?)?.toDouble() ??
          0,
      keypointsCount: (json['keypoints_count'] as num?)?.toInt() ??
          (json['keypointsCount'] as num?)?.toInt() ??
          0,
      frameIndex: (json['frame_index'] as num?)?.toInt() ??
          (json['frameIndex'] as num?)?.toInt() ??
          0,
      metrics: Map<String, dynamic>.from((json['metrics'] as Map?) ?? {}),
      errors: errors,
      feedbackDetails: feedbackDetails,
      coachingCue: json['cue']?.toString() ??
          json['coachingCue']?.toString() ??
          firstFeedback?['correction']?.toString(),
    );

  }

  static List<Map<String, dynamic>> _listOfMaps(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
