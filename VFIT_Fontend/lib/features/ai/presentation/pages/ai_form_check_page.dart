import 'package:flutter/material.dart';

import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_radius.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../widgets/ai_realtime_camera_view.dart';

class AiFormCheckPage extends StatelessWidget {
  const AiFormCheckPage({
    super.key,
    required this.exerciseId,
  });

  final String exerciseId;

  @override
  Widget build(BuildContext context) {
    return AiRealtimeCameraView(
      title: 'AI Form Check',
      webSocketPath: '/ws/ai/form-check',
      queryParameters: {
        'exerciseId': exerciseId,
        'cameraView': 'side',
      },
      readyText: 'Camera đã sẵn sàng.',
      streamingText: 'AI đang kiểm tra chuyển động...',
      stoppedText: 'Đã dừng kiểm tra form.',
      feedbackBuilder: (context, feedbackJson, statusText) {
        return _FeedbackPanel(
          feedback: feedbackJson == null
              ? null
              : _FormCheckFeedback.fromJson(feedbackJson),
          statusText: statusText,
        );
      },
    );
  }
}

class _FeedbackPanel extends StatelessWidget {
  const _FeedbackPanel({
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
              Icon(Icons.auto_awesome_rounded, color: color),
              const SizedBox(width: AppSpacing.x2),
              Expanded(
                child: feedback == null
                    ? Text(
                        'Đang chờ phản hồi AI',
                        style: AppTypography.headerMediumFor(context),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Số lần: ${feedback!.repCount}',
                            style: AppTypography.headerMediumFor(context).copyWith(
                              color: AppColors.energyMagenta,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Điểm: ${feedback!.score}/100',
                            style: AppTypography.headerMediumFor(context).copyWith(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x2),
          Text(
            feedback?.message ??
                statusText ??
                'Bắt đầu kiểm tra và giữ toàn bộ chuyển động trong khung hình.',
            style: AppTypography.bodyFor(context),
          ),
          if (feedback?.coachingCue != null) ...[
            const SizedBox(height: AppSpacing.x2),
            Text(
              feedback!.coachingCue!,
              style: AppTypography.bodySmallFor(context),
            ),
          ],
          if (feedback?.fallback == true) ...[
            const SizedBox(height: AppSpacing.x2),
            Text(
              'AI đang dùng chế độ dự phòng.',
              style: AppTypography.label(color: AppColors.warning),
            ),
          ],
        ],
      ),
    );
  }
}

class _FormCheckFeedback {
  const _FormCheckFeedback({
    required this.score,
    required this.message,
    required this.severity,
    required this.fallback,
    required this.repCount,
    this.coachingCue,
  });

  final int score;
  final String message;
  final String severity;
  final bool fallback;
  final int repCount;
  final String? coachingCue;

  factory _FormCheckFeedback.fromJson(Map<String, dynamic> json) {
    return _FormCheckFeedback(
      score: (json['score'] as num?)?.toInt() ?? 0,
      message: json['summary']?.toString() ??
          json['message']?.toString() ??
          'Chưa có phản hồi.',
      severity: json['severity']?.toString() ?? 'INFO',
      fallback: json['fallback'] == true,
      repCount: (json['rep_count'] as num?)?.toInt() ?? 0,
      coachingCue: json['cue']?.toString() ?? json['coachingCue']?.toString(),
    );
  }
}
