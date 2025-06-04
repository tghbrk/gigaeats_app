import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

/// Service for handling camera and storage permissions
/// Supports both legacy storage permissions (Android 12 and below)
/// and new media permissions (Android 13+)
class CameraPermissionService {
  /// Check if camera permission is granted
  static Future<bool> isCameraPermissionGranted() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  /// Check if storage/media permission is granted
  /// Uses appropriate permission based on Android version
  static Future<bool> isStoragePermissionGranted() async {
    // For Android 13+ (API 33+), use media permissions
    if (await _isAndroid13OrHigher()) {
      final photosStatus = await Permission.photos.status;
      return photosStatus.isGranted;
    } else {
      // For Android 12 and below, use storage permission
      final storageStatus = await Permission.storage.status;
      return storageStatus.isGranted;
    }
  }

  /// Check if we're running on Android 13+ (API 33+)
  static Future<bool> _isAndroid13OrHigher() async {
    // This is a simple check - in a real app you might want to use
    // device_info_plus package for more accurate version detection
    try {
      await Permission.photos.status;
      // If photos permission exists, we're on Android 13+
      return true;
    } catch (e) {
      // If photos permission doesn't exist, we're on older Android
      return false;
    }
  }

  /// Request camera permission
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Request storage/media permission
  /// Uses appropriate permission based on Android version
  static Future<bool> requestStoragePermission() async {
    // For Android 13+ (API 33+), use media permissions
    if (await _isAndroid13OrHigher()) {
      final status = await Permission.photos.request();
      return status.isGranted;
    } else {
      // For Android 12 and below, use storage permission
      final status = await Permission.storage.request();
      return status.isGranted;
    }
  }

  /// Request all required permissions for photo capture
  /// Uses appropriate permissions based on Android version
  static Future<bool> requestPhotoPermissions() async {
    // Always request camera permission
    final cameraGranted = await requestCameraPermission();

    // Request appropriate storage/media permission based on Android version
    final storageGranted = await requestStoragePermission();

    return cameraGranted && storageGranted;
  }

  /// Check if all photo permissions are granted
  static Future<bool> hasAllPhotoPermissions() async {
    final cameraGranted = await isCameraPermissionGranted();
    final storageGranted = await isStoragePermissionGranted();
    return cameraGranted && storageGranted;
  }

  /// Show permission denied dialog
  static void showPermissionDeniedDialog(BuildContext context, String permissionType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permissionType Permission Required'),
        content: Text(
          'This app needs $permissionType permission to capture delivery proof photos. '
          'Please grant permission in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  /// Handle permission request with user feedback
  static Future<bool> handlePhotoPermissionRequest(BuildContext context) async {
    // Check if permissions are already granted
    if (await hasAllPhotoPermissions()) {
      return true;
    }

    // Request permissions
    final granted = await requestPhotoPermissions();

    if (!granted) {
      // Check which specific permission was denied
      final cameraGranted = await isCameraPermissionGranted();
      final storageGranted = await isStoragePermissionGranted();

      // Only show dialog if context is still mounted
      if (context.mounted) {
        if (!cameraGranted) {
          showPermissionDeniedDialog(context, 'Camera');
        } else if (!storageGranted) {
          showPermissionDeniedDialog(context, 'Storage');
        }
      }

      return false;
    }

    return granted;
  }

  /// Check if permission is permanently denied
  static Future<bool> isCameraPermissionPermanentlyDenied() async {
    final status = await Permission.camera.status;
    return status.isPermanentlyDenied;
  }

  /// Check if storage/media permission is permanently denied
  static Future<bool> isStoragePermissionPermanentlyDenied() async {
    // For Android 13+ (API 33+), use media permissions
    if (await _isAndroid13OrHigher()) {
      final status = await Permission.photos.status;
      return status.isPermanentlyDenied;
    } else {
      // For Android 12 and below, use storage permission
      final status = await Permission.storage.status;
      return status.isPermanentlyDenied;
    }
  }

  /// Get permission status text for debugging
  static Future<String> getPermissionStatusText() async {
    final cameraStatus = await Permission.camera.status;

    // Get appropriate storage/media permission status
    String storageStatusText;
    if (await _isAndroid13OrHigher()) {
      final photosStatus = await Permission.photos.status;
      storageStatusText = 'Photos: ${photosStatus.name}';
    } else {
      final storageStatus = await Permission.storage.status;
      storageStatusText = 'Storage: ${storageStatus.name}';
    }

    return 'Camera: ${cameraStatus.name}, $storageStatusText';
  }
}
