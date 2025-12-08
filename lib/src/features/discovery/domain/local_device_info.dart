import 'package:flux/src/features/discovery/domain/device_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'local_device_info.freezed.dart';

/// Information about the current device for broadcasting.
///
/// This is used when advertising the device's presence on the network
/// via mDNS/DNS-SD.
@freezed
class LocalDeviceInfo with _$LocalDeviceInfo {
  /// Creates a new LocalDeviceInfo instance.
  const factory LocalDeviceInfo({
    /// Device name (user-configured or hostname).
    required String alias,

    /// Current device category.
    required DeviceType deviceType,

    /// Operating system name.
    required String os,

    /// Port for file transfer service.
    required int port,

    /// IPv4 addresses of this device (for direct connection).
    @Default([]) List<String> ipAddresses,
  }) = _LocalDeviceInfo;

  const LocalDeviceInfo._();

  /// Converts this info to a map suitable for mDNS TXT record attributes.
  Map<String, String> toTxtAttributes() {
    return {
      'alias': alias,
      'deviceType': deviceType.name,
      'os': os,
      'version': '1',
      // Include port in TXT record as fallback (Android NSD sometimes returns 0)
      'port': port.toString(),
      // Include IP addresses for direct connection (comma-separated)
      if (ipAddresses.isNotEmpty) 'ips': ipAddresses.join(','),
    };
  }
}
