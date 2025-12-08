import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:faker/faker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/src/features/discovery/domain/device_type.dart';
import 'package:flux/src/features/discovery/domain/local_device_info.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'device_info_provider.g.dart';

/// Default port for the file transfer service.
const int kDefaultPort = 53318;

/// Generates a unique device name using faker.
/// Uses a seed based on device-specific info for consistency.
String _generateUniqueDeviceName(String deviceId) {
  // Use device ID hash as seed for consistent name per device
  final seed = deviceId.hashCode.abs();
  final fakerInstance = Faker.withGenerator(RandomGenerator(seed: seed));

  // Generate a memorable name: color + animal
  final color = fakerInstance.color.commonColor();
  final animal = fakerInstance.animal.name();

  // Capitalize first letters
  final colorCapitalized = color[0].toUpperCase() + color.substring(1);
  final animalCapitalized = animal[0].toUpperCase() + animal.substring(1);

  return '$colorCapitalized $animalCapitalized';
}

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

  /// Gets the device alias using faker-generated unique name.
  ///
  /// Generates a consistent unique name based on device-specific identifier.
  // TODO(settings): Add settings fallback for user-configured alias.
  Future<String> getAlias() async {
    String deviceId;

    if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      // Use Android ID for unique identification
      deviceId = info.id;
    } else if (Platform.isIOS) {
      final info = await _deviceInfo.iosInfo;
      deviceId = info.identifierForVendor ?? info.name;
    } else if (Platform.isMacOS) {
      final info = await _deviceInfo.macOsInfo;
      deviceId = info.systemGUID ?? info.computerName;
    } else if (Platform.isWindows) {
      final info = await _deviceInfo.windowsInfo;
      deviceId = info.deviceId;
    } else if (Platform.isLinux) {
      final info = await _deviceInfo.linuxInfo;
      deviceId = info.machineId ?? Platform.localHostname;
    } else {
      deviceId = Platform.localHostname;
    }

    return _generateUniqueDeviceName(deviceId);
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
      getAllIpAddresses(),
    ]);

    return LocalDeviceInfo(
      alias: results[0] as String,
      deviceType: results[1] as DeviceType,
      os: results[2] as String,
      port: getPort(),
      ipAddresses: results[3] as List<String>,
    );
  }

  /// Gets the device's local IP address for display.
  ///
  /// Returns `null` if no suitable network connection is available.
  /// Filters out loopback, Docker, and virtual interfaces.
  Future<String?> getLocalIpAddress() async {
    final addresses = await getAllIpAddresses();
    return addresses.isNotEmpty ? addresses.first : null;
  }

  /// Gets all local IPv4 addresses for broadcasting.
  ///
  /// Returns a list of all valid IPv4 addresses on non-virtual interfaces.
  /// Filters out loopback, Docker, and virtual interfaces.
  Future<List<String>> getAllIpAddresses() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );

      final addresses = <String>[];
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
            addresses.add(addr.address);
          }
        }
      }
      return addresses;
    } catch (_) {
      return []; // Error retrieving network interfaces
    }
  }
}

/// Provider for [DeviceInfoProvider].
@riverpod
DeviceInfoProvider deviceInfoProvider(Ref ref) {
  return DeviceInfoProvider(DeviceInfoPlugin());
}
