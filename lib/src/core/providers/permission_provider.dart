import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'permission_provider.g.dart';

/// Result of a permission request.
enum PermissionResult {
  /// Permission was granted.
  granted,

  /// Permission was denied.
  denied,

  /// Permission was permanently denied (must go to settings).
  permanentlyDenied,

  /// Platform does not require this permission.
  notRequired,
}

/// Controller for handling storage permissions.
///
/// Handles different Android versions:
/// - Android 9 and below: No runtime permission needed for app-specific storage
/// - Android 10 (API 29): Uses legacy storage with requestLegacyExternalStorage
/// - Android 11+ (API 30+): Requires MANAGE_EXTERNAL_STORAGE for broad
///   file access
@riverpod
class PermissionController extends _$PermissionController {
  /// Completer for ongoing permission request to prevent concurrent requests.
  Completer<PermissionResult>? _pendingRequest;

  @override
  PermissionResult build() {
    // Initially unknown, will be checked when needed
    return PermissionResult.notRequired;
  }

  /// Gets the Android SDK version, returns 0 for non-Android platforms.
  Future<int> _getAndroidSdkVersion() async {
    if (!Platform.isAndroid) return 0;
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.version.sdkInt;
    } catch (e) {
      developer.log(
        'Error getting Android SDK version: $e',
        name: 'PermissionController',
      );
      return 30; // Assume Android 11+ if we can't detect
    }
  }

  /// Checks the current storage permission status.
  ///
  /// Returns [PermissionResult.notRequired] on non-Android platforms.
  Future<PermissionResult> checkStoragePermission() async {
    if (!Platform.isAndroid) {
      developer.log(
        'Storage permission not required on ${Platform.operatingSystem}',
        name: 'PermissionController',
      );
      state = PermissionResult.notRequired;
      return PermissionResult.notRequired;
    }

    try {
      final sdkVersion = await _getAndroidSdkVersion();
      developer.log(
        'Android SDK version: $sdkVersion',
        name: 'PermissionController',
      );

      PermissionStatus status;

      if (sdkVersion >= 30) {
        // Android 11+ (API 30+): Need MANAGE_EXTERNAL_STORAGE
        status = await Permission.manageExternalStorage.status;
        developer.log(
          'manageExternalStorage status: $status',
          name: 'PermissionController',
        );
      } else if (sdkVersion >= 23) {
        // Android 6-10 (API 23-29): Use regular storage permission
        status = await Permission.storage.status;
        developer.log('storage status: $status', name: 'PermissionController');
      } else {
        // Android 5 and below: No runtime permission needed
        state = PermissionResult.notRequired;
        return PermissionResult.notRequired;
      }

      final result = _mapStatus(status);
      state = result;
      return result;
    } catch (e) {
      developer.log(
        'Error checking storage permission: $e',
        name: 'PermissionController',
        error: e,
      );
      return PermissionResult.denied;
    }
  }

  /// Requests storage permission from the user.
  ///
  /// On Android 11+, this opens the system settings for MANAGE_EXTERNAL_STORAGE
  /// since it cannot be granted via a normal permission dialog.
  ///
  /// This method is safe to call concurrently - subsequent calls will wait
  /// for the first request to complete and return the same result.
  Future<PermissionResult> requestStoragePermission() async {
    if (!Platform.isAndroid) {
      state = PermissionResult.notRequired;
      return PermissionResult.notRequired;
    }

    // If a request is already in progress, wait for it to complete
    if (_pendingRequest != null) {
      developer.log(
        'Permission request already in progress, waiting...',
        name: 'PermissionController',
      );
      return _pendingRequest!.future;
    }

    // Create a new completer for this request
    _pendingRequest = Completer<PermissionResult>();

    try {
      final result = await _doRequestStoragePermission();
      _pendingRequest!.complete(result);
      return result;
    } catch (e) {
      developer.log(
        'Error requesting storage permission: $e',
        name: 'PermissionController',
        error: e,
      );
      state = PermissionResult.denied;
      _pendingRequest!.complete(PermissionResult.denied);
      return PermissionResult.denied;
    } finally {
      _pendingRequest = null;
    }
  }

  /// Internal method that actually requests the permission.
  Future<PermissionResult> _doRequestStoragePermission() async {
    final sdkVersion = await _getAndroidSdkVersion();
    developer.log(
      'Requesting storage permission for Android SDK $sdkVersion',
      name: 'PermissionController',
    );

    PermissionStatus status;

    if (sdkVersion >= 30) {
      // Android 11+ (API 30+): Need MANAGE_EXTERNAL_STORAGE
      // First check if already granted
      status = await Permission.manageExternalStorage.status;
      if (status.isGranted) {
        developer.log(
          'manageExternalStorage already granted',
          name: 'PermissionController',
        );
        state = PermissionResult.granted;
        return PermissionResult.granted;
      }

      // Request the permission - this opens a special settings page
      status = await Permission.manageExternalStorage.request();
      developer.log(
        'manageExternalStorage request result: $status',
        name: 'PermissionController',
      );
    } else if (sdkVersion >= 23) {
      // Android 6-10 (API 23-29): Use regular storage permission
      status = await Permission.storage.request();
      developer.log(
        'storage request result: $status',
        name: 'PermissionController',
      );
    } else {
      // Android 5 and below: No runtime permission needed
      state = PermissionResult.notRequired;
      return PermissionResult.notRequired;
    }

    final result = _mapStatus(status);
    state = result;
    return result;
  }

  /// Opens app settings so user can manually grant permission.
  Future<bool> openSettings() async {
    return openAppSettings();
  }

  PermissionResult _mapStatus(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
      case PermissionStatus.limited:
        return PermissionResult.granted;
      case PermissionStatus.denied:
      case PermissionStatus.restricted:
        return PermissionResult.denied;
      case PermissionStatus.permanentlyDenied:
        return PermissionResult.permanentlyDenied;
      case PermissionStatus.provisional:
        return PermissionResult.granted;
    }
  }
}

/// Provides a quick check for storage permission.
@riverpod
Future<bool> hasStoragePermission(Ref ref) async {
  if (!Platform.isAndroid) return true;

  final controller = ref.read(permissionControllerProvider.notifier);
  final result = await controller.checkStoragePermission();
  return result == PermissionResult.granted ||
      result == PermissionResult.notRequired;
}
