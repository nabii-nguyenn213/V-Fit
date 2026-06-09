import 'package:camera/camera.dart';

class CameraErrorMessages {
  const CameraErrorMessages._();

  static const noCameraFound = 'Thiết bị này chưa có camera khả dụng.';
  static const cameraUnavailable = 'Không thể sử dụng camera.';
  static const captureFailed = 'Không thể chụp ảnh. Vui lòng thử lại.';

  static String fromCameraException(CameraException error) {
    return switch (error.code) {
      'CameraAccessDenied' => 'Bạn chưa cấp quyền camera.',
      'CameraAccessDeniedWithoutPrompt' =>
        'Hãy bật quyền camera trong phần cài đặt.',
      'CameraAccessRestricted' => 'Quyền camera đang bị giới hạn.',
      _ => cameraUnavailable,
    };
  }
}
