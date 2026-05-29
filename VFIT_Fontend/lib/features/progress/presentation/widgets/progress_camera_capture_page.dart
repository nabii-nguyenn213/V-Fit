import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/camera_error_messages.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../presentation/theme/app_colors.dart';
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
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _controller?.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed && _cameras.isNotEmpty) {
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
    } catch (error) {
      _setError(error.toString());
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
    await _controller?.dispose();
    final controller = CameraController(
      _cameras[index],
      ResolutionPreset.high,
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
        _controller = controller;
        _selectedCameraIndex = index;
        _initializing = false;
      });
    } on CameraException catch (error) {
      await controller.dispose();
      _setError(CameraErrorMessages.fromCameraException(error));
    }
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
    } catch (error) {
      if (mounted) {
        AppFeedback.error('Không thể chụp ảnh: $error');
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

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leadingWidth: 76,
        leading: const Padding(
          padding: EdgeInsets.only(left: 8),
          child: AppBackButton(),
        ),
        title: const Text('Chụp tiến độ'),
        actions: [
          IconButton(
            onPressed: _cameras.length > 1 ? _switchCamera : null,
            icon: const Icon(Icons.cameraswitch_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: ready
                  ? Center(child: CameraPreview(controller))
                  : Center(
                      child: _initializing
                          ? const CircularProgressIndicator()
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
            ),
            Positioned(
              left: AppSpacing.x4,
              right: AppSpacing.x4,
              bottom: AppSpacing.x5,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    customBorder: const CircleBorder(),
                    onTap: ready ? _capture : null,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: AppColors.primaryOf(context),
                          width: 4,
                        ),
                      ),
                      child: _capturing
                          ? const Padding(
                              padding: EdgeInsets.all(22),
                              child: CircularProgressIndicator(strokeWidth: 3),
                            )
                          : const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.black,
                              size: 34,
                            ),
                    ),
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
