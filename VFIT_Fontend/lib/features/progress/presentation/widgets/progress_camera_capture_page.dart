import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/camera_error_messages.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';

class ProgressCameraCapturePage extends StatefulWidget {
  const ProgressCameraCapturePage({super.key});

  @override
  State<ProgressCameraCapturePage> createState() =>
      _ProgressCameraCapturePageState();
}

class _ProgressCameraCapturePageState extends State<ProgressCameraCapturePage>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  int _selectedCameraIndex = 0;
  bool _initializing = true;
  bool _capturing = false;
  bool _retriedInitialOpen = false;
  int _openRequestId = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _controller?.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.inactive && !_initializing) {
      _controller?.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed &&
        _cameras.isNotEmpty &&
        (_controller == null || !_controller!.value.isInitialized)) {
      _openCamera(_selectedCameraIndex);
    }
  }

  Future<void> _initialize() async {
    setState(() {
      _initializing = true;
      _error = null;
    });
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw StateError(CameraErrorMessages.noCameraFound);
      }
      final backIndex = cameras.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );
      _cameras = cameras;
      _selectedCameraIndex = backIndex >= 0 ? backIndex : 0;
      await _openCamera(_selectedCameraIndex);
    } on CameraException catch (error) {
      _setError(CameraErrorMessages.fromCameraException(error));
    } catch (_) {
      _setError(CameraErrorMessages.cameraUnavailable);
    }
  }

  Future<void> _openCamera(int index) async {
    if (index < 0 || index >= _cameras.length) {
      return;
    }
    setState(() {
      _initializing = true;
      _error = null;
    });
    final requestId = ++_openRequestId;
    await _controller?.dispose();
    _controller = null;
    final controller = CameraController(
      _cameras[index],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    try {
      await controller.initialize();
      if (!mounted || requestId != _openRequestId) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _selectedCameraIndex = index;
        _initializing = false;
      });
    } on CameraException catch (error) {
      await controller.dispose();
      if (!mounted || requestId != _openRequestId) {
        return;
      }
      if (_shouldRetryInitialOpen(error)) {
        _retriedInitialOpen = true;
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (mounted && requestId == _openRequestId) {
          await _openCamera(index);
        }
        return;
      }
      _setError(CameraErrorMessages.fromCameraException(error));
    } catch (_) {
      await controller.dispose();
      if (!mounted || requestId != _openRequestId) {
        return;
      }
      _setError(CameraErrorMessages.cameraUnavailable);
    }
  }

  bool _shouldRetryInitialOpen(CameraException error) {
    if (_retriedInitialOpen) {
      return false;
    }
    return error.code == 'CameraAccessDenied' ||
        error.code == 'CameraAccessDeniedWithoutPrompt' ||
        error.code == 'CameraAccessRestricted' ||
        error.description?.isNotEmpty == true;
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _capturing) {
      return;
    }
    final nextIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _openCamera(nextIndex);
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        _capturing ||
        _initializing) {
      return;
    }
    setState(() => _capturing = true);
    try {
      final file = await controller.takePicture();
      if (mounted) {
        Navigator.of(context).pop(file);
      }
    } catch (_) {
      if (mounted) {
        AppFeedback.error(CameraErrorMessages.captureFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _capturing = false);
      }
    }
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() {
      _initializing = false;
      _error = message;
    });
    AppFeedback.error(message);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview (Edge-to-edge)
          if (ready)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.previewSize?.height ?? 1,
                height: controller.value.previewSize?.width ?? 1,
                child: CameraPreview(controller),
              ),
            )
          else
            Center(
              child: _initializing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Padding(
                      padding: const EdgeInsets.all(AppSpacing.x5),
                      child: Text(
                        _error ?? CameraErrorMessages.cameraUnavailable,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyFor(context)
                            .copyWith(color: Colors.white),
                      ),
                    ),
            ),

          // Top Controls (Glassmorphism)
          Positioned(
            top: topPadding + 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildGlassButton(
                  icon: Icons.close_rounded,
                  onTap: () => Navigator.of(context).pop(),
                ),
                if (_cameras.length > 1)
                  _buildGlassButton(
                    icon: Icons.cameraswitch_rounded,
                    onTap: _switchCamera,
                  ),
              ],
            ),
          ),

          // Bottom Shutter Button
          Positioned(
            bottom: bottomPadding + 32,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: ready && !_capturing ? _capture : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _capturing ? 72 : 84,
                  height: _capturing ? 72 : 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                    border: Border.all(
                      color: Colors.white,
                      width: _capturing ? 2 : 4,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: _capturing ? 60 : 70,
                      height: _capturing ? 60 : 70,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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
