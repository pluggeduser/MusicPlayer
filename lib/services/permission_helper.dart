import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  /// Request storage/media permission for Android.
  /// Returns true if permission granted or not needed (iOS, web, etc.)
  static Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    // Android 13+ uses READ_MEDIA_AUDIO
    if (await _isAndroid13OrAbove()) {
      final status = await Permission.audio.request();
      return status.isGranted;
    } else {
      // Older Android uses READ_EXTERNAL_STORAGE
      final status = await Permission.storage.request();
      return status.isGranted;
    }
  }

  static Future<bool> _isAndroid13OrAbove() async {
    try {
      // Android SDK version detection
      // We try requesting audio first; if not available the exception leads to fallback
      return await Permission.audio.status != PermissionStatus.permanentlyDenied
          && await Permission.audio.request().isGranted != false;
    } catch (_) {
      return false;
    }
  }

  /// Returns true if storage permission is already granted
  static Future<bool> hasStoragePermission() async {
    if (!Platform.isAndroid) return true;
    if (await Permission.audio.isGranted) return true;
    if (await Permission.storage.isGranted) return true;
    return false;
  }
}
