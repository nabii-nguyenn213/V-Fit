import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_radius.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../../ai/presentation/widgets/ai_realtime_camera_view.dart';
import '../../../auth/application/auth_controller.dart';
import '../../data/repositories/onboarding_repository.dart';

enum ScanState { scanning, reviewing, saving }

class AiOnboardingBodyScanPage extends ConsumerStatefulWidget {
  const AiOnboardingBodyScanPage({super.key});

  @override
  ConsumerState<AiOnboardingBodyScanPage> createState() =>
      _AiOnboardingBodyScanPageState();
}

class _AiOnboardingBodyScanPageState
    extends ConsumerState<AiOnboardingBodyScanPage> {
  static const _scanDuration = Duration(seconds: 9);

  ScanState _scanState = ScanState.scanning;
  int _countdownSeconds = _scanDuration.inSeconds;
  int _retryCount = 0;
  bool _scanStarted = false;
  Timer? _timer;
  Map<String, dynamic>? _scannedFeedback;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    if (_scanStarted || _scanState != ScanState.scanning) return;
    _timer?.cancel();
    setState(() {
      _scanStarted = true;
      _countdownSeconds = _scanDuration.inSeconds;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_countdownSeconds <= 1) {
        timer.cancel();
        _finishScan();
        return;
      }
      setState(() => _countdownSeconds--);
    });
  }

  void _finishScan() {
    if (!mounted || _scanState != ScanState.scanning) return;
    setState(() => _scanState = ScanState.reviewing);
  }

  void _restartScan() {
    setState(() {
      _scanState = ScanState.scanning;
      _scanStarted = false;
      _countdownSeconds = _scanDuration.inSeconds;
      _scannedFeedback = null;
      _retryCount++;
    });
  }

  void _handleStreamingStopped() {
    if (!mounted || _scanState != ScanState.scanning) return;
    _timer?.cancel();
    setState(() {
      _scanStarted = false;
      _countdownSeconds = _scanDuration.inSeconds;
    });
  }

  Future<void> _handleFeedbackReceived(Map<String, dynamic> feedback) async {
    if (_scanState != ScanState.scanning) return;
    _scannedFeedback = feedback;
  }

  Future<void> _confirmAndSave() async {
    final scannedFeedback = _scannedFeedback;
    if (scannedFeedback == null) return;

    setState(() => _scanState = ScanState.saving);

    try {
      final user = await ref
          .read(onboardingRepositoryProvider)
          .completeRealtimeBodyScan(scannedFeedback);
      ref.read(authControllerProvider.notifier).setUser(user);

      if (!mounted) return;
      AppFeedback.success('Da quet co the thanh cong.');
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      setState(() => _scanState = ScanState.reviewing);
      AppFeedback.error('Luu ket qua that bai: $e. Vui long thu lai.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (_scanState == ScanState.scanning)
            AiRealtimeCameraView(
              key: ValueKey(_retryCount),
              title: 'AI Body Check',
              webSocketPath: '/ws/ai/body-analysis',
              queryParameters: const {},
              readyText: 'Camera da san sang.',
              streamingText: 'AI dang phan tich hinh the...',
              stoppedText: 'Da dung phan tich body.',
              autoStartStreaming: false,
              showStartStopButton: true,
              onStreamingStarted: _startCountdown,
              onStreamingStopped: _handleStreamingStopped,
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
          if (_scanState == ScanState.scanning && _scanStarted)
            Positioned(
              top: 80,
              left: 20,
              right: 20,
              child: _ScanningBanner(secondsLeft: _countdownSeconds),
            ),
          if (_scanState == ScanState.reviewing)
            Positioned.fill(
              child: _ReviewPanel(
                feedback: _scannedFeedback,
                onRescan: _restartScan,
                onAccept: _confirmAndSave,
              ),
            ),
          if (_scanState == ScanState.saving) const _SavingOverlay(),
        ],
      ),
    );
  }
}

class _ScanningBanner extends StatelessWidget {
  const _ScanningBanner({required this.secondsLeft});

  final int secondsLeft;

  @override
  Widget build(BuildContext context) {
    return Container(
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
        children: [
          const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.energyMagenta,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Text(
              'Dang phan tich dang nguoi... ${secondsLeft}s',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewPanel extends StatelessWidget {
  const _ReviewPanel({
    required this.feedback,
    required this.onRescan,
    required this.onAccept,
  });

  final Map<String, dynamic>? feedback;
  final VoidCallback onRescan;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final result =
        feedback == null ? null : _BodyAnalysisFeedback.fromJson(feedback!);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        title: const Text('Ket qua phan tich dang nguoi'),
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
                      Icon(
                        result == null
                            ? Icons.info_outline_rounded
                            : Icons.check_circle_outline_rounded,
                        size: 72,
                        color: result == null
                            ? AppColors.warning
                            : AppColors.success,
                      ),
                      const SizedBox(height: AppSpacing.x4),
                      Text(
                        result == null
                            ? 'Chua nhan duoc du lieu'
                            : 'Da quet thanh cong',
                        textAlign: TextAlign.center,
                        style: AppTypography.headerLargeFor(context).copyWith(
                          color: result == null
                              ? AppColors.warning
                              : AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      Text(
                        result == null
                            ? 'Hay scan lai voi toan than nam trong khung hinh.'
                            : 'AI da ghi nhan thong tin hinh the. Hay kiem tra truoc khi tiep tuc.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondaryOf(context),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x6),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.x4),
                        decoration: BoxDecoration(
                          color: AppColors.surface1Of(context),
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(
                            color: AppColors.borderSubtleOf(context),
                          ),
                        ),
                        child: result == null
                            ? Text(
                                'Khong co body data de hien thi.',
                                style: AppTypography.bodyFor(context),
                              )
                            : _BodyAnalysisDetails(result: result),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.x3),
              Row(
                children: [
                  Expanded(
                    child: AppButton.secondary(
                      label: 'Scan lai',
                      icon: Icons.refresh_rounded,
                      onPressed: onRescan,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x3),
                  Expanded(
                    child: AppButton.primary(
                      label: 'Chap nhan',
                      icon: Icons.check_rounded,
                      onPressed: result == null ? null : onAccept,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BodyAnalysisDetails extends StatelessWidget {
  const _BodyAnalysisDetails({required this.result});

  final _BodyAnalysisFeedback result;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoRow(title: 'Tu the', value: result.posture),
        const SizedBox(height: AppSpacing.x4),
        _InfoRow(title: 'Lech co the', value: result.imbalance),
        const SizedBox(height: AppSpacing.x4),
        _InfoRow(title: 'Goi y', value: result.recommendation),
        const SizedBox(height: AppSpacing.x4),
        const Divider(),
        const SizedBox(height: AppSpacing.x4),
        Row(
          children: [
            Expanded(
              child: _MetricBlock(
                label: 'Eo/Vai',
                value: result.waistShoulderRatio == null
                    ? '-'
                    : result.waistShoulderRatio!.toStringAsFixed(2),
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: AppColors.borderSubtleOf(context),
            ),
            const SizedBox(width: AppSpacing.x4),
            Expanded(
              child: _MetricBlock(
                label: 'Do tin cay',
                value: '${(result.confidence * 100).round()}%',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.label(color: AppColors.textSecondaryOf(context)),
        ),
        const SizedBox(height: AppSpacing.x1),
        Text(
          value,
          style: AppTypography.bodyFor(context).copyWith(
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.label(color: AppColors.textSecondaryOf(context)),
        ),
        const SizedBox(height: AppSpacing.x1),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.energyMagenta,
          ),
        ),
      ],
    );
  }
}

class _SavingOverlay extends StatelessWidget {
  const _SavingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.energyMagenta,
              ),
            ),
            SizedBox(height: AppSpacing.x4),
            Text(
              'Dang luu ket qua...',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
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
                  result == null ? 'Dang cho phan hoi AI' : result!.posture,
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
                'Dung thang nguoi trong khung hinh de AI cap nhat chi so.',
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
