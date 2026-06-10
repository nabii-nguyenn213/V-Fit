import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/widgets/app_back_button.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_radius.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../widgets/ai_realtime_camera_view.dart';

enum _BodyScanState { scanning, reviewing }

class AiBodyAnalysisPage extends StatefulWidget {
  const AiBodyAnalysisPage({super.key});

  @override
  State<AiBodyAnalysisPage> createState() => _AiBodyAnalysisPageState();
}

class _AiBodyAnalysisPageState extends State<AiBodyAnalysisPage> {
  static const _scanDuration = Duration(seconds: 9);

  _BodyScanState _state = _BodyScanState.scanning;
  int _scanKey = 0;
  int _secondsLeft = _scanDuration.inSeconds;
  bool _scanStarted = false;
  Timer? _timer;
  Map<String, dynamic>? _latestFeedback;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _resetScan() {
    _timer?.cancel();
    setState(() {
      _state = _BodyScanState.scanning;
      _secondsLeft = _scanDuration.inSeconds;
      _scanStarted = false;
      _latestFeedback = null;
      _scanKey++;
    });
  }

  void _startScanTimer() {
    if (_scanStarted || _state != _BodyScanState.scanning) {
      return;
    }
    _timer?.cancel();
    setState(() {
      _scanStarted = true;
      _secondsLeft = _scanDuration.inSeconds;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        timer.cancel();
        _finishScan();
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  void _finishScan() {
    if (!mounted || _state != _BodyScanState.scanning) {
      return;
    }
    setState(() => _state = _BodyScanState.reviewing);
  }

  void _handleStreamingStopped() {
    if (!mounted || _state != _BodyScanState.scanning) {
      return;
    }
    _timer?.cancel();
    setState(() {
      _scanStarted = false;
      _secondsLeft = _scanDuration.inSeconds;
    });
  }

  void _handleFeedbackReceived(Map<String, dynamic> feedback) {
    if (_state != _BodyScanState.scanning) {
      return;
    }
    _latestFeedback = feedback;
  }

  @override
  Widget build(BuildContext context) {
    if (_state == _BodyScanState.reviewing) {
      return _BodyAnalysisReviewScaffold(
        feedback: _latestFeedback,
        onRescan: _resetScan,
        onAccept: () => Navigator.of(context).maybePop(),
      );
    }

    return Stack(
      children: [
        AiRealtimeCameraView(
          key: ValueKey(_scanKey),
          title: 'AI Body Check',
          webSocketPath: '/ws/ai/body-analysis',
          queryParameters: const {},
          readyText: 'Camera da san sang.',
          streamingText: 'AI dang phan tich hinh the...',
          stoppedText: 'Da dung phan tich body.',
          autoStartStreaming: false,
          showStartStopButton: true,
          onStreamingStarted: _startScanTimer,
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
        if (_scanStarted)
          Positioned(
            top: 84,
            left: AppSpacing.x4,
            right: AppSpacing.x4,
            child: _ScanningBanner(secondsLeft: _secondsLeft),
          ),
      ],
    );
  }
}

class _BodyAnalysisReviewScaffold extends StatelessWidget {
  const _BodyAnalysisReviewScaffold({
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
    final color =
        result?.fallback == true ? AppColors.warning : AppColors.success;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 76,
        leading: const Padding(
          padding: EdgeInsets.only(left: 8),
          child: AppBackButton(),
        ),
        title: const Text('Ket qua phan tich dang nguoi'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.x4),
                    decoration: BoxDecoration(
                      color: AppColors.surface1Of(context),
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: color.withValues(alpha: 0.34)),
                    ),
                    child: result == null
                        ? Text(
                            'Chua nhan duoc du lieu dang nguoi. Hay scan lai voi toan than nam trong khung hinh.',
                            style: AppTypography.bodyFor(context),
                          )
                        : _BodyAnalysisDetails(result: result),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.x3),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onRescan,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Scan lai'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x3),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: result == null ? null : onAccept,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Chap nhan'),
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

class _ScanningBanner extends StatelessWidget {
  const _ScanningBanner({required this.secondsLeft});

  final int secondsLeft;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x4,
          vertical: AppSpacing.x3,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.76),
          borderRadius: BorderRadius.circular(AppRadius.input),
          border: Border.all(
            color: AppColors.energyMagenta.withValues(alpha: 0.52),
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
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
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
        Row(
          children: [
            Icon(
              Icons.accessibility_new_rounded,
              color: result.fallback ? AppColors.warning : AppColors.success,
            ),
            const SizedBox(width: AppSpacing.x2),
            Expanded(
              child: Text(
                result.posture,
                style: AppTypography.headerMediumFor(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x4),
        _InfoBlock(title: 'Tinh trang lech co the', value: result.imbalance),
        const SizedBox(height: AppSpacing.x3),
        _InfoBlock(title: 'Goi y tap luyen', value: result.recommendation),
        const SizedBox(height: AppSpacing.x4),
        Wrap(
          spacing: AppSpacing.x2,
          runSpacing: AppSpacing.x2,
          children: [
            _MetricChip(
              label: 'Eo/Vai',
              value: result.waistShoulderRatio == null
                  ? '-'
                  : result.waistShoulderRatio!.toStringAsFixed(2),
            ),
            _MetricChip(
              label: 'AI',
              value: result.fallback ? 'Fallback' : 'Analyzed',
            ),
            _MetricChip(
              label: 'Confidence',
              value: '${(result.confidence * 100).round()}%',
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style:
                AppTypography.label(color: AppColors.textSecondaryOf(context))),
        const SizedBox(height: AppSpacing.x1),
        Text(value, style: AppTypography.bodyFor(context)),
      ],
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
                'Dung thang nguoi trong khung hinh de AI phan tich.',
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
