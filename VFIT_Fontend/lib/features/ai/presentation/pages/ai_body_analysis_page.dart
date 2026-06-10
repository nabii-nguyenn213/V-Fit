import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_radius.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../widgets/ai_realtime_camera_view.dart';

// ─── Thời gian ──────────────────────────────────────────────────────────────
const _kWarmUpSeconds = 3; // Chờ AI service sẵn sàng
const _kScanSeconds = 4; // Thu thập kết quả trong 4 s

// ─── Trạng thái màn hình ────────────────────────────────────────────────────
enum _ScanPhase {
  warmUp, // Đếm ngược 3 s
  scanning, // Đang quét 4 s
  done, // Đã xong, hiện kết quả
}

class AiBodyAnalysisPage extends StatefulWidget {
  const AiBodyAnalysisPage({super.key});

  @override
  State<AiBodyAnalysisPage> createState() => _AiBodyAnalysisPageState();
}

class _AiBodyAnalysisPageState extends State<AiBodyAnalysisPage> {
  _ScanPhase _phase = _ScanPhase.warmUp;
  int _countdown = _kWarmUpSeconds;
  int _scanRemaining = _kScanSeconds;

  // Kết quả tốt nhất trong window 4 s
  Map<String, dynamic>? _bestFeedback;
  double _bestConfidence = -1;

  Timer? _warmUpTimer;
  Timer? _scanTimer;

  @override
  void initState() {
    super.initState();
    _startWarmUp();
  }

  @override
  void dispose() {
    _warmUpTimer?.cancel();
    _scanTimer?.cancel();
    super.dispose();
  }

  // ── Phase 1: Đếm ngược 3 s ─────────────────────────────────────────────
  void _startWarmUp() {
    setState(() {
      _phase = _ScanPhase.warmUp;
      _countdown = _kWarmUpSeconds;
    });

    _warmUpTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _countdown--);
      if (_countdown <= 0) {
        t.cancel();
        _startScan();
      }
    });
  }

  // ── Phase 2: Thu thập kết quả trong 4 s ────────────────────────────────
  void _startScan() {
    setState(() {
      _phase = _ScanPhase.scanning;
      _scanRemaining = _kScanSeconds;
      _bestFeedback = null;
      _bestConfidence = -1;
    });

    _scanTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _scanRemaining--);
      if (_scanRemaining <= 0) {
        t.cancel();
        _finishScan();
      }
    });
  }

  // ── Nhận feedback từ AiRealtimeCameraView ──────────────────────────────
  void _onFeedback(Map<String, dynamic> feedback) {
    if (_phase != _ScanPhase.scanning) return;

    final estimate = feedback['estimate'];
    final confidence = estimate is Map
        ? (estimate['confidence'] as num?)?.toDouble() ?? 0.0
        : 0.0;

    if (confidence > _bestConfidence) {
      setState(() {
        _bestConfidence = confidence;
        _bestFeedback = feedback;
      });
    }
  }

  // ── Phase 3: Hiện kết quả ──────────────────────────────────────────────
  void _finishScan() {
    setState(() => _phase = _ScanPhase.done);
  }

  // ── Quét lại ──────────────────────────────────────────────────────────
  void _rescan() {
    _warmUpTimer?.cancel();
    _scanTimer?.cancel();
    _startWarmUp();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Camera luôn chạy ở background (với showStartStopButton = false)
        AiRealtimeCameraView(
          title: 'AI Body Check',
          webSocketPath: '/ws/ai/body-analysis',
          queryParameters: const {},
          readyText: 'Camera đã sẵn sàng.',
          streamingText: 'AI đang phân tích hình thể...',
          stoppedText: 'Đã dừng phân tích body.',
          showStartStopButton: false,
          onFeedbackReceived: _onFeedback,
          feedbackBuilder: (context, feedbackJson, statusText) {
            // Panel nhỏ dưới camera — chỉ hiện trong lúc scanning/warmUp
            if (_phase == _ScanPhase.done) return const SizedBox.shrink();
            return _ScanStatusPanel(
              phase: _phase,
              countdown: _countdown,
              scanRemaining: _scanRemaining,
            );
          },
        ),

        // Overlay đếm ngược warmUp
        if (_phase == _ScanPhase.warmUp)
          _WarmUpOverlay(countdown: _countdown),

        // Overlay đang scan
        if (_phase == _ScanPhase.scanning)
          _ScanningOverlay(remaining: _scanRemaining),

        // Màn hình kết quả (full overlay)
        if (_phase == _ScanPhase.done)
          _ResultOverlay(
            feedback: _bestFeedback,
            onConfirm: () => Navigator.of(context).maybePop(),
            onRescan: _rescan,
          ),
      ],
    );
  }
}

// ─── Overlay đếm ngược warmUp ────────────────────────────────────────────────
class _WarmUpOverlay extends StatelessWidget {
  const _WarmUpOverlay({required this.countdown});
  final int countdown;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$countdown',
                    style: const TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.x3),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.x4,
                  vertical: AppSpacing.x2,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(AppRadius.input),
                ),
                child: const Text(
                  'Đứng thẳng, AI đang khởi động...',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Overlay đang scan ───────────────────────────────────────────────────────
class _ScanningOverlay extends StatelessWidget {
  const _ScanningOverlay({required this.remaining});
  final int remaining;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 80,
      right: 20,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x3,
            vertical: AppSpacing.x2,
          ),
          decoration: BoxDecoration(
            color: AppColors.energyMagenta.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.radar_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                'Quét: ${remaining}s',
                style: AppTypography.label(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Panel trạng thái nhỏ dưới camera ────────────────────────────────────────
class _ScanStatusPanel extends StatelessWidget {
  const _ScanStatusPanel({
    required this.phase,
    required this.countdown,
    required this.scanRemaining,
  });

  final _ScanPhase phase;
  final int countdown;
  final int scanRemaining;

  @override
  Widget build(BuildContext context) {
    final isWarmUp = phase == _ScanPhase.warmUp;
    final color = isWarmUp ? AppColors.warning : AppColors.success;
    final text = isWarmUp
        ? 'AI đang khởi động — còn $countdown giây...'
        : 'Đang thu thập dữ liệu — còn $scanRemaining giây...';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        color: AppColors.surface1Of(context),
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: color.withValues(alpha: 0.38)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: color,
            ),
          ),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Text(text, style: AppTypography.bodyFor(context)),
          ),
        ],
      ),
    );
  }
}

// ─── Màn hình kết quả ────────────────────────────────────────────────────────
class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay({
    required this.feedback,
    required this.onConfirm,
    required this.onRescan,
  });

  final Map<String, dynamic>? feedback;
  final VoidCallback onConfirm;
  final VoidCallback onRescan;

  @override
  Widget build(BuildContext context) {
    final result = feedback == null
        ? null
        : _BodyAnalysisFeedback.fromJson(feedback!);
    final hasResult = result != null;
    final accent = hasResult && result.fallback
        ? AppColors.warning
        : AppColors.success;

    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.85),
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
                        Icons.accessibility_new_rounded,
                        color: accent,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.x3),
                    Expanded(
                      child: Text(
                        hasResult ? 'Kết quả phân tích body' : 'Không có kết quả',
                        style: AppTypography.headerMediumFor(context)
                            .copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.x5),

                if (hasResult) ...[
                  // Posture
                  _ResultCard(
                    icon: Icons.person_outline_rounded,
                    label: 'Tư thế',
                    value: result.posture,
                    accent: accent,
                  ),
                  const SizedBox(height: AppSpacing.x3),

                  // Imbalance
                  _ResultCard(
                    icon: Icons.balance_rounded,
                    label: 'Cân bằng cơ thể',
                    value: result.imbalance,
                    accent: accent,
                  ),
                  const SizedBox(height: AppSpacing.x3),

                  // Recommendation
                  _ResultCard(
                    icon: Icons.lightbulb_outline_rounded,
                    label: 'Gợi ý',
                    value: result.recommendation,
                    accent: accent,
                  ),
                  const SizedBox(height: AppSpacing.x3),

                  // Metrics chips
                  Wrap(
                    spacing: AppSpacing.x2,
                    runSpacing: AppSpacing.x2,
                    children: [
                      if (result.waistShoulderRatio != null)
                        _ResultChip(
                          label: 'Eo/Vai',
                          value: result.waistShoulderRatio!.toStringAsFixed(2),
                          color: accent,
                        ),
                      _ResultChip(
                        label: 'Confidence',
                        value: '${(result.confidence * 100).round()}%',
                        color: accent,
                      ),
                      _ResultChip(
                        label: 'Nguồn',
                        value: result.fallback ? 'Fallback' : 'Live AI',
                        color: accent,
                      ),
                    ],
                  ),
                ] else ...[
                  Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.sentiment_dissatisfied_rounded,
                          color: Colors.white54,
                          size: 56,
                        ),
                        const SizedBox(height: AppSpacing.x3),
                        Text(
                          'AI chưa thu được dữ liệu đủ.\nThử đứng xa hơn và giữ nguyên tư thế.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyFor(context)
                              .copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],

                const Spacer(),

                // Buttons
                FilledButton.icon(
                  onPressed: onConfirm,
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Xác nhận & Thoát'),
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: AppSpacing.x3),
                OutlinedButton.icon(
                  onPressed: onRescan,
                  icon: const Icon(Icons.replay_rounded, color: Colors.white),
                  label: const Text(
                    'Quét lại',
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

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 20),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.label(color: accent),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTypography.bodyFor(context)
                      .copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultChip extends StatelessWidget {
  const _ResultChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x3,
        vertical: AppSpacing.x2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Text(
        '$label: $value',
        style: AppTypography.label(color: Colors.white),
      ),
    );
  }
}

// ─── Data model ──────────────────────────────────────────────────────────────
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
