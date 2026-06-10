import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

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

class AiRealtimeCameraView extends StatefulWidget {
  const AiRealtimeCameraView({
    super.key,
    required this.title,
    required this.webSocketPath,
    required this.queryParameters,
    required this.readyText,
    required this.streamingText,
    required this.stoppedText,
    required this.feedbackBuilder,
    this.captureInterval = const Duration(milliseconds: 800),
    this.onFeedbackReceived,
    this.showStartStopButton = true,
  });

  final String title;
  final String webSocketPath;
  final Map<String, String> queryParameters;
  final String readyText;
  final String streamingText;
  final String stoppedText;
  final Duration captureInterval;
  final Widget Function(
    BuildContext context,
    Map<String, dynamic>? feedback,
    String? statusText,
  ) feedbackBuilder;
  final void Function(Map<String, dynamic> feedback)? onFeedbackReceived;
  final bool showStartStopButton;

  @override
  State<AiRealtimeCameraView> createState() => _AiRealtimeCameraViewState();
}

class _AiRealtimeCameraViewState extends State<AiRealtimeCameraView>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  WebSocket? _socket;
  Timer? _captureTimer;
  List<CameraDescription> _cameras = const [];
  int _selectedCameraIndex = 0;
  bool _initializing = true;
  bool _streaming = false;
  bool _capturing = false;
  bool _waitingForFeedback = false;
  DateTime? _lastFrameSentAt;
  String? _statusText;
  Map<String, dynamic>? _latestFeedback;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopStreaming(fromDispose: true);
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
      _cameras = cameras;
      final backIndex = cameras.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );
      _selectedCameraIndex = backIndex >= 0 ? backIndex : 0;
      await _openCamera(_selectedCameraIndex, autoStartStreaming: true);
    } on CameraException catch (error) {
      _showSetupError(CameraErrorMessages.fromCameraException(error));
    } catch (error) {
      _showSetupError(error.toString());
    }
  }

  Future<void> _openCamera(int index, {bool autoStartStreaming = false}) async {
    if (index < 0 || index >= _cameras.length) {
      return;
    }
    setState(() {
      _initializing = true;
      _statusText = 'Đang chuẩn bị camera...';
    });

    final wasStreaming = _streaming;
    if (wasStreaming) {
      await _stopStreaming();
    }

    final oldController = _cameraController;
    _cameraController = null;
    if (oldController != null) {
      await oldController.dispose();
    }

    final controller = CameraController(
      _cameras[index],
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _cameraController = controller;
        _selectedCameraIndex = index;
        _initializing = false;
        _statusText = widget.readyText;
      });
      if (wasStreaming || autoStartStreaming) {
        unawaited(_startStreaming());
      }
    } on CameraException catch (error) {
      _showSetupError(CameraErrorMessages.fromCameraException(error));
    } catch (error) {
      _showSetupError(error.toString());
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _capturing || _initializing) {
      return;
    }
    final nextIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _openCamera(nextIndex);
  }

  Future<void> _startStreaming() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized || _streaming) {
      return;
    }

    try {
      final token = await getOrRefreshAccessToken();
      if (token == null || token.isEmpty) {
        AppFeedback.error('Phiên đăng nhập đã hết hạn. Hãy đăng nhập lại.');
        return;
      }

      final socket = await WebSocket.connect(_webSocketUrl(token));
      _socket = socket;
      _streaming = true;
      _waitingForFeedback = false;
      setState(() => _statusText = widget.streamingText);

      unawaited(_listenForFeedback(socket));
      _captureTimer = Timer.periodic(
        widget.captureInterval,
        (_) => _sendSnapshot(),
      );
      await _sendSnapshot();
    } catch (error) {
      await _stopStreaming();
      if (mounted) {
        AppFeedback.error('Không thể bắt đầu phân tích AI: $error');
        setState(() => _statusText = 'Kết nối AI thất bại.');
      }
    }
  }

  Future<void> _stopStreaming({bool fromDispose = false}) async {
    _captureTimer?.cancel();
    _captureTimer = null;
    _streaming = false;
    _waitingForFeedback = false;
    final socket = _socket;
    _socket = null;
    if (socket != null) {
      await socket.close();
    }
    if (mounted && !fromDispose) {
      setState(() => _statusText = widget.stoppedText);
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

    if (_waitingForFeedback && !_feedbackTimedOut) {
      return;
    }

    _capturing = true;
    _waitingForFeedback = true;
    _lastFrameSentAt = DateTime.now();
    try {
      final image = await controller.takePicture();
      final bytes = await image.readAsBytes();
      print('[AI CAMERA] Successfully captured frame, size: ${bytes.length} bytes');
      socket.add(bytes);
    } catch (error) {
      _waitingForFeedback = false;
      print('[AI CAMERA] Error capturing frame: $error');
      if (mounted) {
        setState(() => _statusText = 'Bỏ qua một khung hình: $error');
      }
    } finally {
      _capturing = false;
    }
  }

  bool get _feedbackTimedOut {
    final sentAt = _lastFrameSentAt;
    return sentAt != null && DateTime.now().difference(sentAt).inSeconds >= 3;
  }

  Future<void> _listenForFeedback(WebSocket socket) async {
    try {
      await for (final message in socket) {
        if (!mounted || message is! String) {
          continue;
        }
        final decoded = jsonDecode(message);
        if (decoded is Map) {
          final feedbackMap = Map<String, dynamic>.from(decoded);
          setState(() {
            _waitingForFeedback = false;
            _latestFeedback = feedbackMap;
          });

          if (widget.onFeedbackReceived != null) {
            widget.onFeedbackReceived!(feedbackMap);
          }
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

  Color get _feedbackBorderColor {
    if (!_streaming || _latestFeedback == null) {
      return Colors.transparent;
    }
    final severity = _latestFeedback?['severity']?.toString().toUpperCase();
    if (severity != null) {
      return switch (severity) {
        'WARN' => AppColors.warning,
        'RATE_LIMITED' => AppColors.error,
        'ERROR' => AppColors.error,
        'UNKNOWN' => AppColors.error,
        'OK' => AppColors.success,
        _ => AppColors.success,
      };
    }
    final fallback = _latestFeedback?['fallback'] == true;
    if (fallback) {
      return AppColors.warning;
    }
    return AppColors.success;
  }

  String _webSocketUrl(String token) {
    return WebSocketUrlBuilder.build(
      path: widget.webSocketPath,
      queryParameters: {
        'token': token,
        ...widget.queryParameters,
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

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 76,
        leading: const Padding(
          padding: EdgeInsets.only(left: 8),
          child: AppBackButton(),
        ),
        title: Text(widget.title),
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
                        if (cameraReady) ...[
                          CameraPreview(controller),
                          IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _feedbackBorderColor,
                                  width: 6,
                                ),
                                borderRadius: BorderRadius.circular(AppRadius.large),
                              ),
                            ),
                          ),
                        ] else
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
                        if (cameraReady && _cameras.length > 1)
                          Positioned(
                            bottom: AppSpacing.x3,
                            right: AppSpacing.x3,
                            child: _buildGlassButton(
                              icon: Icons.cameraswitch_rounded,
                              onTap: _switchCamera,
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
                  widget.feedbackBuilder(
                    context,
                    _latestFeedback,
                    _statusText,
                  ),
                  if (widget.showStartStopButton) ...[
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
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
