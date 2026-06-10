import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_feedback.dart';
import '../../../auth/application/auth_controller.dart';
import '../../data/repositories/onboarding_repository.dart';
import '../../../ai/presentation/widgets/ai_realtime_camera_view.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_radius.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';

class AiOnboardingBodyScanPage extends ConsumerStatefulWidget {
  const AiOnboardingBodyScanPage({super.key});

  @override
  ConsumerState<AiOnboardingBodyScanPage> createState() => _AiOnboardingBodyScanPageState();
}

class _AiOnboardingBodyScanPageState extends ConsumerState<AiOnboardingBodyScanPage> {
  bool _isSaving = false;

  Future<void> _handleFeedbackReceived(Map<String, dynamic> feedback) async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
    });

    try {
      final user = await ref.read(onboardingRepositoryProvider).completeRealtimeBodyScan(feedback);
      
      // Update auth controller state
      ref.read(authControllerProvider.notifier).setUser(user);
      
      if (mounted) {
        AppFeedback.success('Quét cơ thể thành công! Đang chuyển hướng...');
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        AppFeedback.error('Lưu kết quả thất bại: $e. Vui lòng thử lại.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AiRealtimeCameraView(
            title: 'Quét cơ thể Realtime',
            webSocketPath: '/ws/ai/body-analysis',
            queryParameters: const {},
            readyText: 'Camera đã sẵn sàng.',
            streamingText: 'AI đang phân tích hình thể...',
            stoppedText: 'Đã dừng phân tích body.',
            onFeedbackReceived: _handleFeedbackReceived,
            feedbackBuilder: (context, feedbackJson, statusText) {
              return _BodyAnalysisPanel(
                result: feedbackJson == null
                    ? null
                    : _BodyAnalysisFeedback.fromJson(feedbackJson),
                statusText: statusText,
              );
            },
          ),
          if (_isSaving)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.energyMagenta),
                    ),
                    SizedBox(height: AppSpacing.x4),
                    Text(
                      'Đang lưu kết quả phân tích...',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BodyAnalysisPanel extends StatelessWidget {
  const _BodyAnalysisPanel({
    required this.result,
    required this.statusText,
  });

  final _BodyAnalysisFeedback? result;
  final String? statusText;

  @override
  Widget build(BuildContext context) {
    final color =
        result?.fallback == true ? AppColors.warning : AppColors.success;

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
              Icon(Icons.accessibility_new_rounded, color: color),
              const SizedBox(width: AppSpacing.x2),
              Expanded(
                child: Text(
                  result == null ? 'Đang chờ phản hồi AI' : result!.posture,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.headerMediumFor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x2),
          Text(
            result?.imbalance ??
                statusText ??
                'Đứng thẳng người trong khung hình để AI cập nhật chỉ số liên tục.',
            style: AppTypography.bodyFor(context),
          ),
          if (result != null) ...[
            const SizedBox(height: AppSpacing.x3),
            Wrap(
              spacing: AppSpacing.x2,
              runSpacing: AppSpacing.x2,
              children: [
                _MetricChip(
                  label: 'Eo/Vai',
                  value: result!.waistShoulderRatio == null
                      ? '-'
                      : result!.waistShoulderRatio!.toStringAsFixed(2),
                ),
                _MetricChip(
                  label: 'AI',
                  value: result!.fallback ? 'Fallback' : 'Live',
                ),
                _MetricChip(
                  label: 'Confidence',
                  value: '${(result!.confidence * 100).round()}%',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x2),
            Text(
              result!.recommendation,
              style: AppTypography.bodySmallFor(context),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x3,
        vertical: AppSpacing.x2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface2Of(context),
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Text(
        '$label: $value',
        style: AppTypography.label(color: AppColors.textPrimaryOf(context)),
      ),
    );
  }
}

class _BodyAnalysisFeedback {
  const _BodyAnalysisFeedback({
    required this.posture,
    required this.imbalance,
    required this.recommendation,
    required this.confidence,
    required this.fallback,
    this.waistShoulderRatio,
  });

  final String posture;
  final String imbalance;
  final String recommendation;
  final double confidence;
  final bool fallback;
  final double? waistShoulderRatio;

  factory _BodyAnalysisFeedback.fromJson(Map<String, dynamic> json) {
    final posture = _asMap(json['posture']);
    final imbalance = _asMap(json['imbalance']);
    final estimate = _asMap(json['estimate']);
    final recommendation = _asMap(json['recommendation']);
    return _BodyAnalysisFeedback(
      posture: posture['summary']?.toString() ?? 'Body analysis pending',
      imbalance: imbalance['summary']?.toString() ??
          'No imbalance estimate available.',
      recommendation:
          recommendation['focus']?.toString() ?? 'Continue current routine.',
      confidence: (estimate['confidence'] as num?)?.toDouble() ?? 0,
      fallback: json['fallback'] == true,
      waistShoulderRatio: (estimate['waistShoulderRatio'] as num?)?.toDouble(),
    );
  }

  static Map<String, dynamic> _asMap(Object? value) {
    return value is Map ? Map<String, dynamic>.from(value) : const {};
  }
}
