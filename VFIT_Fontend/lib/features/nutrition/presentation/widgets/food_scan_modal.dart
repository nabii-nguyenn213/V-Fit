import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vfit_frontend/features/ai/data/repositories/ai_planners_repository.dart';

import '../../../../core/utils/permission_helper.dart';
import '../../../../core/utils/rate_limiter.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../data/models/food_calorie_estimate_model.dart';

/// Modal để quét calo thức ăn từ ảnh
/// - Chụp ảnh từ camera
/// - Hoặc chọn từ gallery
/// - Hiển thị loading khi phân tích
/// - Hiển thị kết quả calo
class FoodScanModal extends ConsumerStatefulWidget {
  final Function(FoodCalorieEstimateModel) onFoodScanned;
  final VoidCallback onCancel;

  const FoodScanModal({
    Key? key,
    required this.onFoodScanned,
    required this.onCancel,
  }) : super(key: key);

  @override
  ConsumerState<FoodScanModal> createState() => _FoodScanModalState();
}

class _FoodScanModalState extends ConsumerState<FoodScanModal> {
  CameraController? _cameraController;
  bool _isCameraReady = false;
  bool _isAnalyzing = false;
  late List<CameraDescription> _cameras;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      // Request permission
      final hasPermission = await PermissionHelper.requestCameraPermission();
      if (!hasPermission) {
        if (mounted) {
          AppFeedback.error('Cần cấp quyền camera');
          widget.onCancel();
        }
        return;
      }

      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) {
          AppFeedback.error('Thiết bị không có camera');
          widget.onCancel();
        }
        return;
      }

      // Get back camera
      final backCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController?.initialize();

      if (mounted) {
        setState(() => _isCameraReady = true);
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.error('Lỗi camera: $e');
        widget.onCancel();
      }
    }
  }

  /// 📸 Chụp ảnh từ camera
  Future<void> _capturePhoto() async {
    try {
      if (_cameraController == null || !_isCameraReady) {
        return;
      }

      setState(() => _isAnalyzing = true);

      // Chụp ảnh
      final image = await _cameraController!.takePicture();
      final bytes = await image.readAsBytes();

      // Phân tích
      await _analyzeFood(bytes, image.path);

      // Cleanup - remove temporary file if it's a file path
      try {
        final file = File(image.path);
        if (file.existsSync()) {
          await file.delete();
        }
      } catch (_) {
        // Ignore cleanup errors
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.error('Lỗi chụp ảnh: $e');
        setState(() => _isAnalyzing = false);
      }
    }
  }

  /// 🖼️ Chọn ảnh từ gallery
  Future<void> _pickFromGallery() async {
    try {
      setState(() => _isAnalyzing = true);

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) {
        setState(() => _isAnalyzing = false);
        return;
      }

      final bytes = await pickedFile.readAsBytes();
      await _analyzeFood(bytes, pickedFile.path);
    } catch (e) {
      if (mounted) {
        AppFeedback.error('Lỗi chọn ảnh: $e');
        setState(() => _isAnalyzing = false);
      }
    }
  }

  /// 🤖 Phân tích ảnh để lấy thông tin calo
  Future<void> _analyzeFood(List<int> imageBytes, String imagePath) async {
    try {
      // Check rate limit
      if (!RateLimitedApiCall.canScanFood()) {
        if (mounted) {
          AppFeedback.error('Quét quá nhanh. Vui lòng chờ.');
          setState(() => _isAnalyzing = false);
        }
        return;
      }

      // Call API to analyze with file
      AppFeedback.info('Đang phân tích ảnh...');
      
      final repo = ref.read(aiPlannersRepositoryProvider);
      final response = await repo.scanFoodImage(
        bytes: imageBytes,
        filename: imagePath.split('/').last,
      );

      if (mounted) {
        setState(() => _isAnalyzing = false);
        
        final foodName = response['food_name']?.toString() ?? 'Thức ăn quét được';
        final servingSize = response['portion_estimate']?.toString() ?? '1 phần';
        final calories = (response['total_calories'] as num?)?.toInt() ?? 0;
        final proteinGrams = (response['protein_g'] as num?)?.toDouble() ?? 0.0;
        final carbGrams = (response['carbs_g'] as num?)?.toDouble() ?? 0.0;
        final fatGrams = (response['fat_g'] as num?)?.toDouble() ?? 0.0;
        final confidence = (response['confidence'] as num?)?.toDouble() ?? 0.75;
        
        final List<String> notes = [];
        if (response['note'] != null) {
          notes.add(response['note'].toString());
        }
        if (response['items'] is List) {
          notes.addAll((response['items'] as List).map((e) => e.toString()));
        }

        final result = FoodCalorieEstimateModel(
          foodName: foodName,
          servingSize: servingSize,
          calories: calories,
          proteinGrams: proteinGrams,
          carbGrams: carbGrams,
          fatGrams: fatGrams,
          confidence: confidence,
          notes: notes,
          estimatedAt: DateTime.now(),
        );
        
        // Callback với kết quả
        widget.onFoodScanned(result);
        
        // Close modal
        Navigator.pop(context, result);
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.error('Lỗi phân tích ảnh: $e');
        setState(() => _isAnalyzing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Quét calo thức ăn',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: widget.onCancel,
                ),
              ],
            ),
          ),

          // Camera preview or Analyzing
          if (_isAnalyzing)
            _buildAnalyzingWidget()
          else if (_isCameraReady && _cameraController != null)
            _buildCameraWidget()
          else
            _buildLoadingWidget(),

          // Buttons
          if (!_isAnalyzing)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Capture button
                  if (_isCameraReady)
                    ElevatedButton.icon(
                      onPressed: _capturePhoto,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Chụp ảnh'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),

                  if (_isCameraReady)
                    const SizedBox(height: 12),

                  // Gallery button
                  OutlinedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Chọn từ thư viện'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Camera preview widget
  Widget _buildCameraWidget() {
    return Container(
      height: 300,
      width: double.infinity,
      color: Colors.black,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: 100,
                height: 100 * (_cameraController?.value.aspectRatio ?? 1.0),
                child: CameraPreview(_cameraController!),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '👉 Chọn "Chụp ảnh" để quét',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Loading widget
  Widget _buildLoadingWidget() {
    return Container(
      height: 200,
      color: Colors.grey[100],
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// Analyzing widget
  Widget _buildAnalyzingWidget() {
    return Container(
      height: 300,
      color: Colors.grey[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          const Text(
            'Đang phân tích ảnh...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Vui lòng chờ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper function để show food scan modal
Future<FoodCalorieEstimateModel?> showFoodScanModal(
  BuildContext context, {
  required Function(FoodCalorieEstimateModel) onFoodScanned,
}) async {
  return showDialog<FoodCalorieEstimateModel?>(
    context: context,
    barrierDismissible: false,
    builder: (context) => FoodScanModal(
      onFoodScanned: onFoodScanned,
      onCancel: () => Navigator.pop(context),
    ),
  );
}
