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
      readyText: 'Camera da san sang.',
      streamingText: 'AI dang kiem tra chuyen dong...',
      stoppedText: 'Da dung kiem tra form.',
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
                        'Dang cho phan hoi AI',
                        style: AppTypography.headerMediumFor(context),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'So lan: ${feedback!.repCount} - ${feedback!.phaseLabel}',
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.headerMediumFor(context)
                                  .copyWith(
                                color: AppColors.energyMagenta,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.x2),
                          Text(
                            'Diem: ${feedback!.score}/100',
                            style:
                                AppTypography.headerMediumFor(context).copyWith(
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
                'Bat dau kiem tra va giu toan bo chuyen dong trong khung hinh.',
            style: AppTypography.bodyFor(context),
          ),
          if (feedback?.coachingCue != null) ...[
            const SizedBox(height: AppSpacing.x2),
            Text(
              feedback!.coachingCue!,
              style: AppTypography.bodySmallFor(context),
            ),
          ],
          if (feedback != null) ...[
            const SizedBox(height: AppSpacing.x3),
            Wrap(
              spacing: AppSpacing.x2,
              runSpacing: AppSpacing.x2,
              children: [
                _InfoChip(label: 'Phase', value: feedback!.phaseLabel),
                _InfoChip(
                  label: 'Rep AI',
                  value: feedback!.repCounterEnabled ? 'online' : 'offline',
                ),
                _InfoChip(
                  label: 'Tin cay',
                  value: '${(feedback!.repConfidence * 100).round()}%',
                ),
                _InfoChip(
                  label: 'Pose',
                  value: '${feedback!.keypointsCount} diem',
                ),
                _InfoChip(label: 'Frame', value: '#${feedback!.frameIndex}'),
              ],
            ),
          ],
          if (feedback?.primaryError != null) ...[
            const SizedBox(height: AppSpacing.x2),
            Text(
              feedback!.primaryError!,
              style: AppTypography.bodySmallFor(context).copyWith(color: color),
            ),
          ],
          if (feedback?.metricsSummary.isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.x2),
            Text(
              feedback!.metricsSummary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmallFor(context),
            ),
          ],
          if (feedback?.fallback == true) ...[
            const SizedBox(height: AppSpacing.x2),
            Text(
              'AI dang dung che do du phong.',
              style: AppTypography.label(color: AppColors.warning),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface2Of(context),
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Text(
        '$label: $value',
        style: AppTypography.label(color: AppColors.textSecondaryOf(context)),
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
    if (!repCounterEnabled && phase != 'no_pose') {
      return 'AI rep offline';
    }
    return switch (phase) {
      'down' => 'xuong',
      'up' => 'len',
      'other' => 'ngoai form',
      'unknown' => 'dang bat form',
      'no_pose' => 'chua thay nguoi',
      _ => phase,
    };
  }

  String? get primaryError {
    if (errors.isEmpty) {
      return null;
    }
    final error = errors.first;
    final code = error['code']?.toString();
    final message = error['message']?.toString();
    if (message == null || message.isEmpty) {
      return code;
    }
    return code == null || code.isEmpty ? message : '$code: $message';
  }

  String get metricsSummary {
    if (metrics.isEmpty) {
      return '';
    }
    return metrics.entries
        .take(3)
        .map((entry) => '${entry.key}: ${entry.value}')
        .join(' | ');
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
          'Chua co phan hoi.',
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
    if (value is! List) {
      return const [];
    }
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
