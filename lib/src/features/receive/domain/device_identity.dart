import 'package:flux/src/features/discovery/domain/device_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'device_identity.freezed.dart';

/// Device identity information for the Identity Card.
///
/// Contains all the information needed to display the device's
/// identity in the Receive tab UI.
@freezed
class DeviceIdentity with _$DeviceIdentity {
  /// Creates a [DeviceIdentity] instance.
  const factory DeviceIdentity({
    /// Device alias (friendly name).
    required String alias,

    /// Device type (phone, tablet, laptop, desktop).
    required DeviceType deviceType,

    /// Operating system name.
    required String os,

    /// Local IP address (null if not connected).
    String? ipAddress,

    /// Server port number.
    required int port,
  }) = _DeviceIdentity;
}


