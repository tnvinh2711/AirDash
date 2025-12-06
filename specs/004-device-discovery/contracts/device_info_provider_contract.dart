// Device Info Provider Contract
// Feature: 004-device-discovery
// This file defines the abstract interface for local device information.
// Implementation will use device_info_plus and settings repository.

/// Contract for providing local device information.
///
/// Used for broadcasting device presence on the network.
abstract class DeviceInfoProviderContract {
  /// Gets the device alias (user-configured or hostname).
  ///
  /// Order of precedence:
  /// 1. User-configured alias from settings
  /// 2. Device hostname from device_info_plus
  /// 3. "Unknown Device" as fallback
  Future<String> getAlias();

  /// Gets the device type based on form factor.
  ///
  /// Returns one of: phone, tablet, desktop, laptop, unknown.
  Future<String> getDeviceType();

  /// Gets the operating system name.
  ///
  /// Returns one of: iOS, Android, macOS, Windows, Linux.
  Future<String> getOperatingSystem();

  /// Gets the file transfer server port.
  ///
  /// Order of precedence:
  /// 1. User-configured port from settings
  /// 2. Application default port (e.g., 8080)
  Future<int> getPort();

  /// Gets all device info for broadcasting.
  ///
  /// Convenience method that bundles all info together.
  Future<LocalDeviceInfoContract> getLocalDeviceInfo();
}

/// Bundle of local device information.
abstract class LocalDeviceInfoContract {
  String get alias;
  String get deviceType;
  String get os;
  int get port;
}
