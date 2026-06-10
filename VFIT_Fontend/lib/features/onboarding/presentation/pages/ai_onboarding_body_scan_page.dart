import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../auth/application/auth_controller.dart';
import '../../data/repositories/onboarding_repository.dart';
import '../../../ai/presentation/widgets/ai_realtime_camera_view.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_radius.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';

enum ScanState { scanning, reviewing, saving }

class AiOnboardingBodyScanPage extends ConsumerStatefulWidget {
  const AiOnboardingBodyScanPage({super.key});

  @override
  ConsumerState<AiOnboardingBodyScanPage> createState() => _AiOnboardingBodyScanPageState();
}

class _AiOnboardingBodyScanPageState extends ConsumerState<AiOnboardingBodyScanPage> {
  ScanState _scanState = ScanState.scanning;
  int _countdownSeconds = 9; // Tăng thêm 4 giây thành 9 giây tổng cộng
  Timer? _timer;
  int _retryCount = 0;
  Map<String, dynamic>? _scannedFeedback;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    setState(() {
      _countdownSeconds = 9;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_countdownSeconds > 0) {
          _countdownSeconds--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool _isValidResult(Map<String, dynamic>? json) {
    if (json == null) return false;
    final feedback = _BodyAnalysisFeedback.fromJson(json);
    final postureLower = feedback.posture.toLowerCase();
    return !feedback.fallback &&
           feedback.confidence >= 0.8 &&
           !postureLower.contains('pending');
  }

  Future<void> _handleFeedbackReceived(Map<String, dynamic> feedback) async {
    if (_countdownSeconds > 0) {
      // Bỏ qua kết quả cho đến khi đếm ngược kết thúc để đảm bảo người dùng đứng yên
      return;
    }
    if (_scanState != ScanState.scanning) return;
    if (!_isValidResult(feedback)) return;

    // Khi có kết quả hợp lệ đầu tiên sau thời gian đếm ngược:
    // Dừng camera và dừng gọi sang AI (bằng cách chuyển sang trạng thái Reviewing để unmount CameraView)
    setState(() {
      _scannedFeedback = feedback;
      _scanState = ScanState.reviewing;
    });
  }

  Future<void> _confirmAndSave() async {
    if (_scannedFeedback == null) return;
    setState(() {
      _scanState = ScanState.saving;
    });

    try {
      final user = await ref.read(onboardingRepositoryProvider).completeRealtimeBodyScan(_scannedFeedback!);
      
      // Cập nhật trạng thái người dùng trong auth controller
      ref.read(authControllerProvider.notifier).setUser(user);
      
      if (mounted) {
        AppFeedback.success('Quét cơ thể thành công! Đang chuyển hướng...');
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _scanState = ScanState.reviewing;
        });
        AppFeedback.error('Lưu kết quả thất bại: $e. Vui lòng thử lại.');
      }
    }
  }

  Widget _buildReviewPanel() {
    final feedback = _BodyAnalysisFeedback.fromJson(_scannedFeedback!);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        title: const Text('Xác nhận kết quả phân tích'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(
                        child: Icon(
                          Icons.check_circle_outline_rounded,
                          size: 72,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x4),
                      Center(
                        child: Text(
                          'Đã quét thành công!',
                          style: AppTypography.headerLargeFor(context).copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      const Center(
                        child: Text(
                          'AI đã ghi nhận và phân tích hình thể của bạn. Vui lòng kiểm tra lại kết quả trước khi tiếp tục.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, height: 1.4),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x6),
                      
                      // Result Card
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.x4),
                        decoration: BoxDecoration(
                          color: AppColors.surface1Of(context),
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: AppColors.borderSubtleOf(context)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'KẾT QUẢ TƯ THẾ (POSTURE)',
                              style: AppTypography.label(color: Colors.grey),
                            ),
                            const SizedBox(height: AppSpacing.x1),
                            Text(
                              feedback.posture,
                              style: AppTypography.headerMediumFor(context).copyWith(
                                color: AppColors.energyMagenta,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.x4),
                            const Divider(),
                            const SizedBox(height: AppSpacing.x4),
                            _buildInfoRow('Tình trạng lệch cơ thể (Imbalance)', feedback.imbalance),
                            const SizedBox(height: AppSpacing.x4),
                            _buildInfoRow('Lời khuyên & Khuyến nghị (Recommendation)', feedback.recommendation),
                            const SizedBox(height: AppSpacing.x4),
                            const Divider(),
                            const SizedBox(height: AppSpacing.x4),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildMetricBlock(
                                    'Tỷ lệ Eo/Vai',
                                    feedback.waistShoulderRatio == null
                                        ? '-'
                                        : feedback.waistShoulderRatio!.toStringAsFixed(2),
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: AppColors.borderSubtleOf(context),
                                ),
                                const SizedBox(width: AppSpacing.x4),
                                Expanded(
                                  child: _buildMetricBlock(
                                    'Độ tin cậy',
                                    '${(feedback.confidence * 100).round()}%',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Bottom Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.x2),
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton.secondary(
                        label: 'Quét lại',
                        icon: Icons.refresh_rounded,
                        onPressed: () {
                          setState(() {
                            _scannedFeedback = null;
                            _scanState = ScanState.scanning;
                            _retryCount++;
                            _startCountdown();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.x3),
                    Expanded(
                      child: AppButton.primary(
                        label: 'Xác nhận & Lưu',
                        icon: Icons.check_rounded,
                        onPressed: _confirmAndSave,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.label(color: Colors.grey),
        ),
        const SizedBox(height: AppSpacing.x1),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildMetricBlock(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: AppSpacing.x1),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.energyMagenta),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (_scanState == ScanState.scanning)
            AiRealtimeCameraView(
              key: ValueKey(_retryCount),
              title: 'Quét cơ thể Realtime',
              webSocketPath: '/ws/ai/body-analysis',
              queryParameters: const {},
              readyText: 'Camera đã sẵn sàng.',
              streamingText: 'AI đang phân tích hình thể...',
              stoppedText: 'Đã dừng phân tích body.',
              showStartStopButton: false,
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
          
          // Countdown overlay during scanning
          if (_scanState == ScanState.scanning)
            Positioned(
              top: 80,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.x3,
                  horizontal: AppSpacing.x4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  border: Border.all(
                    color: AppColors.energyMagenta.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.energyMagenta),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.x3),
                    Expanded(
                      child: Text(
                        _countdownSeconds > 0
                            ? 'Hãy đứng thẳng và giữ nguyên tư thế: $_countdownSeconds giây...'
                            : 'Đang ghi nhận kết quả tối ưu...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (_scanState == ScanState.reviewing && _scannedFeedback != null)
            Positioned.fill(child: _buildReviewPanel()),

          if (_scanState == ScanState.saving)
            Container(
              color: Colors.black.withValues(alpha: 0.75),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.energyMagenta),
                    ),
                    SizedBox(height: AppSpacing.x4),
                    Text(
                      'Đang xử lý & lưu kết quả...',
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
