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
/// Handles different Android versions using Scoped Storage:
/// - Android 9 and below: Uses READ/WRITE_EXTERNAL_STORAGE
/// - Android 10-12 (API 29-32): Uses Scoped Storage with legacy fallback
/// - Android 13+ (API 33+): Uses READ_MEDIA_* permissions for specific media types
/// - No MANAGE_EXTERNAL_STORAGE needed - uses MediaStore API and SAF
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
  /// For Android 10+ (API 29+), uses Scoped Storage which doesn't require
  /// runtime permissions for app-specific directories and MediaStore.
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

      // Android 10+ (API 29+): Scoped Storage - no permission needed
      // We use MediaStore API for Downloads and SAF for user file selection
      if (sdkVersion >= 29) {
        developer.log(
          'Android 10+ detected - using Scoped Storage (no permission needed)',
          name: 'PermissionController',
        );
        state = PermissionResult.notRequired;
        return PermissionResult.notRequired;
      }

      // Android 6-9 (API 23-28): Need READ/WRITE_EXTERNAL_STORAGE
      if (sdkVersion >= 23) {
        final status = await Permission.storage.status;
        developer.log('storage status: $status', name: 'PermissionController');
        final result = _mapStatus(status);
        state = result;
        return result;
      }

      // Android 5 and below: No runtime permission needed
      state = PermissionResult.notRequired;
      return PermissionResult.notRequired;
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
  /// For Android 10+ (API 29+), returns [PermissionResult.notRequired] since
  /// Scoped Storage doesn't need runtime permissions.
  /// For Android 6-9, requests READ/WRITE_EXTERNAL_STORAGE permission.
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

    // Android 10+ (API 29+): Scoped Storage - no permission needed
    if (sdkVersion >= 29) {
      developer.log(
        'Android 10+ detected - using Scoped Storage (no permission needed)',
        name: 'PermissionController',
      );
      state = PermissionResult.notRequired;
      return PermissionResult.notRequired;
    }

    // Android 6-9 (API 23-28): Request READ/WRITE_EXTERNAL_STORAGE
    if (sdkVersion >= 23) {
      final status = await Permission.storage.request();
      developer.log(
        'storage request result: $status',
        name: 'PermissionController',
      );
      final result = _mapStatus(status);
      state = result;
      return result;
    }

    // Android 5 and below: No runtime permission needed
    state = PermissionResult.notRequired;
    return PermissionResult.notRequired;
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
