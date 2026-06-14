import 'package:permission_handler/permission_handler.dart';

/// Helper class for handling runtime permissions
class PermissionHelper {
  const PermissionHelper._();

  /// Request camera permission
  /// Returns true if permission is granted
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    
    switch (status) {
      case PermissionStatus.granted:
        return true;
      case PermissionStatus.denied:
        return false;
      case PermissionStatus.restricted:
        // Permission is restricted by OS (iOS)
        return false;
      case PermissionStatus.limited:
        // User selected "Allow Only This Time" (iOS 14+)
        return true;
      case PermissionStatus.provisional:
        // Provisional permission (Android 12+)
        return true;
      case PermissionStatus.permanentlyDenied:
        // User selected "Don't Allow" permanently
        // Open app settings for user to enable
        openAppSettings();
        return false;
    }
  }

  /// Request photo library permission
  static Future<bool> requestPhotoLibraryPermission() async {
    final status = await Permission.photos.request();
    
    switch (status) {
      case PermissionStatus.granted:
        return true;
      case PermissionStatus.denied:
        return false;
      case PermissionStatus.restricted:
        return false;
      case PermissionStatus.limited:
        return true;
      case PermissionStatus.provisional:
        // Provisional permission (Android 12+)
        return true;
      case PermissionStatus.permanentlyDenied:
        openAppSettings();
        return false;
    }
  }

  /// Check if camera permission is granted
  static Future<bool> hasCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted || status.isLimited;
  }

  /// Check if photo library permission is granted
  static Future<bool> hasPhotoPermission() async {
    final status = await Permission.photos.status;
    return status.isGranted || status.isLimited;
  }

  /// Get human-readable permission status
  static String getPermissionStatusMessage(PermissionStatus status) {
    return switch (status) {
      PermissionStatus.granted => 'Cấp quyền thành công',
      PermissionStatus.denied => 'Bạn từ chối cấp quyền',
      PermissionStatus.restricted => 'Quyền bị giới hạn bởi hệ thống',
      PermissionStatus.limited => 'Quyền bị giới hạn (cho lần này)',
      PermissionStatus.provisional => 'Quyền sơ bộ',
      PermissionStatus.permanentlyDenied =>
        'Bạn đã từ chối vĩnh viễn. Vui lòng bật quyền trong cài đặt.',
    };
  }

  /// Open app settings to enable permission
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }
}
