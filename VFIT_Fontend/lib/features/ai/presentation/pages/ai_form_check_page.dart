import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../../core/network/network_providers.dart';
import '../../../../core/network/web_socket_url_builder.dart';
import '../../../../core/utils/camera_error_messages.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_radius.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';

class AiFormCheckPage extends StatefulWidget {
  const AiFormCheckPage({
    super.key,
    required this.exerciseId,
  });

  final String exerciseId;

  @override
  State<AiFormCheckPage> createState() => _AiFormCheckPageState();
}

class _AiFormCheckPageState extends State<AiFormCheckPage>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  WebSocket? _socket;
  Timer? _captureTimer;
  bool _initializing = true;
  bool _streaming = false;
  bool _capturing = false;
  String? _statusText;
  _FormCheckFeedback? _latestFeedback;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopStreaming();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _stopStreaming();
    }
  }

  Future<void> _initialize() async {
    setState(() {
      _initializing = true;
      _statusText = 'Đang chuẩn bị camera...';
    });

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw StateError(CameraErrorMessages.noCameraFound);
      }
      final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _cameraController = controller;
        _initializing = false;
        _statusText = 'Camera đã sẵn sàng.';
      });
    } on CameraException catch (error) {
      _showSetupError(CameraErrorMessages.fromCameraException(error));
    } catch (error) {
      _showSetupError(error.toString());
    }
  }

  Future<void> _startStreaming() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized || _streaming) {
      return;
    }

    try {
      final token = await appTokenStorage.readAccessToken();
      if (token == null || token.isEmpty) {
        AppFeedback.error('Phiên đăng nhập đã hết hạn. Hãy đăng nhập lại.');
        return;
      }

      final socket = await WebSocket.connect(_formCheckWebSocketUrl(token));
      _socket = socket;
      _streaming = true;
      setState(() => _statusText = 'AI đang kiểm tra chuyển động...');

      unawaited(_listenForFeedback(socket));
      _captureTimer = Timer.periodic(
        const Duration(milliseconds: 1200),
        (_) => _sendSnapshot(),
      );
      await _sendSnapshot();
    } catch (error) {
      await _stopStreaming();
      if (mounted) {
        AppFeedback.error('Không thể bắt đầu kiểm tra form: $error');
        setState(() => _statusText = 'Kết nối AI thất bại.');
      }
    }
  }

  Future<void> _stopStreaming() async {
    _captureTimer?.cancel();
    _captureTimer = null;
    _streaming = false;
    final socket = _socket;
    _socket = null;
    if (socket != null) {
      await socket.close();
    }
    if (mounted) {
      setState(() => _statusText = 'Đã dừng kiểm tra form.');
    }
  }

  Future<void> _sendSnapshot() async {
    final controller = _cameraController;
    final socket = _socket;
    if (!_streaming ||
        _capturing ||
        controller == null ||
        socket == null ||
        !controller.value.isInitialized) {
      return;
    }

    _capturing = true;
    try {
      final image = await controller.takePicture();
      final bytes = await image.readAsBytes();
      socket.add(bytes);
    } catch (error) {
      if (mounted) {
        setState(() => _statusText = 'Bỏ qua một khung hình: $error');
      }
    } finally {
      _capturing = false;
    }
  }

  Future<void> _listenForFeedback(WebSocket socket) async {
    try {
      await for (final message in socket) {
        if (!mounted || message is! String) {
          continue;
        }
        final decoded = jsonDecode(message);
        if (decoded is Map) {
          setState(() {
            _latestFeedback = _FormCheckFeedback.fromJson(
              Map<String, dynamic>.from(decoded),
            );
          });
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() => _statusText = 'Kết nối AI đã đóng: $error');
      }
    } finally {
      if (mounted && _streaming) {
        await _stopStreaming();
      }
    }
  }

  String _formCheckWebSocketUrl(String token) {
    return WebSocketUrlBuilder.build(
      path: '/ws/ai/form-check',
      queryParameters: {
        'token': token,
        'exerciseId': widget.exerciseId,
      },
    ).toString();
  }

  void _showSetupError(String message) {
    if (!mounted) return;
    setState(() {
      _initializing = false;
      _statusText = message;
    });
    AppFeedback.error(message);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _cameraController;
    final cameraReady = controller != null && controller.value.isInitialized;
    final feedback = _latestFeedback;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 76,
        leading: const Padding(
          padding: EdgeInsets.only(left: 8),
          child: AppBackButton(),
        ),
        title: const Text('AI Form Check'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.x4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.large),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(AppRadius.large),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (cameraReady)
                          CameraPreview(controller)
                        else
                          Center(
                            child: _initializing
                                ? const CircularProgressIndicator()
                                : Text(
                                    _statusText ??
                                        CameraErrorMessages.cameraUnavailable,
                                    textAlign: TextAlign.center,
                                    style: AppTypography.bodyFor(context)
                                        .copyWith(color: Colors.white),
                                  ),
                          ),
                        if (_streaming)
                          Positioned(
                            top: AppSpacing.x3,
                            right: AppSpacing.x3,
                            child: _LiveBadge(
                              color: AppColors.energyMagenta,
                              label: 'LIVE',
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x4,
                0,
                AppSpacing.x4,
                AppSpacing.x4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _FeedbackPanel(
                    feedback: feedback,
                    statusText: _statusText,
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  FilledButton.icon(
                    onPressed: cameraReady
                        ? (_streaming ? _stopStreaming : _startStreaming)
                        : null,
                    icon: Icon(
                      _streaming
                          ? Icons.stop_circle_outlined
                          : Icons.play_circle_outline_rounded,
                    ),
                    label: Text(_streaming ? 'Dừng kiểm tra' : 'Bắt đầu'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Text(
        label,
        style: AppTypography.label(color: Colors.white),
      ),
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
                child: Text(
                  feedback == null
                      ? 'Đang chờ phản hồi AI'
                      : 'Điểm ${feedback!.score}/100',
                  style: AppTypography.headerMediumFor(context),
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
    this.coachingCue,
  });

  final int score;
  final String message;
  final String severity;
  final String? coachingCue;

  factory _FormCheckFeedback.fromJson(Map<String, dynamic> json) {
    return _FormCheckFeedback(
      score: (json['score'] as num?)?.toInt() ?? 0,
      message: json['message']?.toString() ?? 'Chưa có phản hồi.',
      severity: json['severity']?.toString() ?? 'INFO',
      coachingCue: json['coachingCue']?.toString(),
    );
  }
}
