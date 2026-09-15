import 'dart:io' as io;
import 'package:flutter/services.dart';

/// Platform channel bridge communicating with native Android layer in MainActivity.kt.
class MobileNativeBridge {
  static const MethodChannel _channel = MethodChannel('com.vinx.downloader/native_channel');

  /// Checks if runtime storage permissions / manage files permission is granted.
  static Future<bool> checkStoragePermission() async {
    if (!io.Platform.isAndroid) return true;
    try {
      final result = await _channel.invokeMethod<bool>('checkStoragePermission');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Prompts system permission dialog or settings screen for storage access.
  static Future<bool> requestStoragePermission() async {
    if (!io.Platform.isAndroid) return true;
    try {
      final result = await _channel.invokeMethod<bool>('requestStoragePermission');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Gets the public device Downloads/VINX folder (/storage/emulated/0/Download/VINX).
  static Future<String?> getPublicDownloadsDirectory() async {
    if (!io.Platform.isAndroid) return null;
    try {
      return await _channel.invokeMethod<String>('getPublicDownloadsDirectory');
    } catch (_) {
      return null;
    }
  }

  /// Notifies the Android MediaScanner to immediately index the file in Gallery and MediaStore.
  static Future<void> scanMediaFile(String filePath) async {
    if (!io.Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('scanMediaFile', {'filePath': filePath});
    } catch (_) {}
  }

  /// Opens the downloaded media file with the native player/viewer.
  static Future<bool> openFile(String filePath) async {
    if (!io.Platform.isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('openFile', {'filePath': filePath});
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens the folder in the native file manager or downloads screen.
  static Future<bool> openFolder(String folderPath) async {
    if (!io.Platform.isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('openFolder', {'folderPath': folderPath});
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens the native share sheet for the given file.
  static Future<bool> shareFile(String filePath) async {
    if (!io.Platform.isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('shareFile', {'filePath': filePath});
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}
