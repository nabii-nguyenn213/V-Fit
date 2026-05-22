import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../progress/data/repositories/progress_repository.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../controllers/active_challenge_notifier.dart';

class ForceCameraOverlay extends ConsumerStatefulWidget {
  const ForceCameraOverlay({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ForceCameraOverlay> createState() => _ForceCameraOverlayState();
}

class _ForceCameraOverlayState extends ConsumerState<ForceCameraOverlay> {
  bool _isUploading = false;

  Future<void> _takeMilestonePhoto(String challengeTitle) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1280,
      );

      if (pickedFile == null || !mounted) return;

      final File imageFile = File(pickedFile.path);

      // Prompt user for note/description
      final String? note = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          final controller = TextEditingController();
          final scheme = Theme.of(context).colorScheme;

          return AlertDialog(
            title: const Text('Nhập ghi chú hình thể'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    imageFile,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  maxLength: 60,
                  decoration: const InputDecoration(
                    labelText: 'Ví dụ: Cơ ngực căng tràn, ngày 30...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(''),
                child: const Text('Bỏ qua'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(controller.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                ),
                child: const Text('Xác nhận & Nộp'),
              ),
            ],
          );
        },
      );

      if (note == null || !mounted) return;

      setState(() => _isUploading = true);

      // Upload using progress repository
      await ref.read(progressRepositoryProvider).uploadSnap(imageFile, note);

      if (mounted) {
        AppFeedback.success(
          'Đã ghi nhận ảnh cột mốc thành công. Tiếp tục kỷ luật nhé!',
          title: 'Đã hoàn thành!',
        );
      }

      // Invalidate providers to force state update and automatically dismiss overlay
      ref.invalidate(journeySnapsProvider);
      ref.invalidate(activeChallengeNotifierProvider);

    } catch (e) {
      if (mounted) {
        AppFeedback.error(e.toString(), title: 'Tải ảnh thất bại');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activeChallengeNotifierProvider);
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        widget.child,
        if (state.isMilestoneDay)
          Positioned.fill(
            child: Material(
              color: Colors.black.withValues(alpha: 0.92),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_enhance_rounded,
                      size: 80,
                      color: scheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Cột Mốc Kỷ Luật V-FIT!',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Hôm nay là ngày cột mốc bắt buộc của thử thách "${state.activeChallengeTitle}". Vui lòng chụp ảnh tiến độ để duy trì chuỗi và nhận quà!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _isUploading
                        ? const Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 14),
                              Text(
                                'Đang xử lý ảnh tiến độ...',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          )
                        : ElevatedButton.icon(
                            onPressed: () => _takeMilestonePhoto(state.activeChallengeTitle),
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Chụp ảnh & Nộp bài ngay'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              backgroundColor: scheme.primary,
                              foregroundColor: scheme.onPrimary,
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
