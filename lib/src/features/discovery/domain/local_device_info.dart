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
  }) = _LocalDeviceInfo;

  const LocalDeviceInfo._();

  /// Converts this info to a map suitable for mDNS TXT record attributes.
  Map<String, String> toTxtAttributes() {
    return {
      'alias': alias,
      'deviceType': deviceType.name,
      'os': os,
      'version': '1',
    };
  }
}
