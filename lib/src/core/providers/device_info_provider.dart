import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/src/features/discovery/domain/device_type.dart';
import 'package:flux/src/features/discovery/domain/local_device_info.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'device_info_provider.g.dart';

/// Default port for the file transfer service.
const int kDefaultPort = 8080;

/// Provider for device information operations.
///
/// Uses device_info_plus to detect platform-specific device information.
class DeviceInfoProvider {
  /// Creates a DeviceInfoProvider.
  DeviceInfoProvider(this._deviceInfo);

  final DeviceInfoPlugin _deviceInfo;

  /// Gets the device type based on the current platform.
  Future<DeviceType> getDeviceType() async {
    if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      // Check if it's a tablet based on screen size hint from systemFeatures
      // Android tablets typically have 'android.hardware.telephony' absent
      final isTablet = !info.systemFeatures.contains(
        'android.hardware.telephony',
      );
      return isTablet ? DeviceType.tablet : DeviceType.phone;
    } else if (Platform.isIOS) {
      final info = await _deviceInfo.iosInfo;
      // iPad vs iPhone detection
      final model = info.model.toLowerCase();
      if (model.contains('ipad')) {
        return DeviceType.tablet;
      }
      return DeviceType.phone;
    } else if (Platform.isMacOS) {
      final info = await _deviceInfo.macOsInfo;
      // MacBooks are laptops, others are desktops
      final model = info.model.toLowerCase();
      if (model.contains('book')) {
        return DeviceType.laptop;
      }
      return DeviceType.desktop;
    } else if (Platform.isWindows) {
      // Windows doesn't easily distinguish laptop vs desktop
      // Default to desktop
      return DeviceType.desktop;
    } else if (Platform.isLinux) {
      // Linux doesn't easily distinguish laptop vs desktop
      // Default to desktop
      return DeviceType.desktop;
    }
    return DeviceType.unknown;
  }

  /// Gets the operating system name and version.
  Future<String> getOperatingSystem() async {
    if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      return 'Android ${info.version.release}';
    } else if (Platform.isIOS) {
      final info = await _deviceInfo.iosInfo;
      return 'iOS ${info.systemVersion}';
    } else if (Platform.isMacOS) {
      final info = await _deviceInfo.macOsInfo;
      return 'macOS ${info.osRelease}';
    } else if (Platform.isWindows) {
      final info = await _deviceInfo.windowsInfo;
      return 'Windows ${info.displayVersion}';
    } else if (Platform.isLinux) {
      final info = await _deviceInfo.linuxInfo;
      return info.prettyName;
    }
    return Platform.operatingSystem;
  }

  /// Gets the device alias (hostname or device name).
  // TODO(settings): Add settings fallback for user-configured alias.
  Future<String> getAlias() async {
    if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      return info.model;
    } else if (Platform.isIOS) {
      final info = await _deviceInfo.iosInfo;
      return info.name;
    } else if (Platform.isMacOS) {
      final info = await _deviceInfo.macOsInfo;
      return info.computerName;
    } else if (Platform.isWindows) {
      final info = await _deviceInfo.windowsInfo;
      return info.computerName;
    } else if (Platform.isLinux) {
      final info = await _deviceInfo.linuxInfo;
      return info.machineId ?? Platform.localHostname;
    }
    return Platform.localHostname;
  }

  /// Gets the port for the file transfer service.
  // TODO(settings): Add settings fallback for user-configured port.
  int getPort() {
    return kDefaultPort;
  }

  /// Gets complete local device information for broadcasting.
  Future<LocalDeviceInfo> getLocalDeviceInfo() async {
    final results = await Future.wait([
      getAlias(),
      getDeviceType(),
      getOperatingSystem(),
    ]);

    return LocalDeviceInfo(
      alias: results[0] as String,
      deviceType: results[1] as DeviceType,
      os: results[2] as String,
      port: getPort(),
    );
  }

  /// Gets the device's local IP address for display.
  ///
  /// Returns `null` if no suitable network connection is available.
  /// Filters out loopback, Docker, and virtual interfaces.
  Future<String?> getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      for (final interface in interfaces) {
        // Skip loopback and virtual interfaces
        if (interface.name.startsWith('lo') ||
            interface.name.startsWith('docker') ||
            interface.name.startsWith('veth') ||
            interface.name.startsWith('br-')) {
          continue;
        }

        for (final addr in interface.addresses) {
          if (!addr.isLoopback) {
            return addr.address;
          }
        }
      }
      return null; // No network connection
    } catch (_) {
      return null; // Error retrieving network interfaces
    }
  }
}

/// Provider for [DeviceInfoProvider].
@riverpod
DeviceInfoProvider deviceInfoProvider(Ref ref) {
  return DeviceInfoProvider(DeviceInfoPlugin());
}
