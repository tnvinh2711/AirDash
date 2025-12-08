import 'package:flux/src/features/discovery/domain/device_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'device.freezed.dart';

/// A discovered peer on the local network.
///
/// Represents a device that was found via mDNS/DNS-SD discovery.
/// The [lastSeen] timestamp is used for staleness detection
/// (30-second timeout).
@freezed
class Device with _$Device {
  /// Creates a new Device instance.
  const factory Device({
    /// mDNS service instance identifier (e.g., "MyMacBook._flux._tcp.local").
    required String serviceInstanceName,

    /// IPv4 address for connection.
    required String ip,

    /// Service port for file transfer.
    required int port,

    /// Human-readable device name.
    required String alias,

    /// Category of device.
    required DeviceType deviceType,

    /// Platform identifier (iOS, Android, macOS, Windows, Linux).
    required String os,

    /// Last mDNS announcement timestamp (for staleness detection).
    required DateTime lastSeen,
  }) = _Device;

  const Device._();

  /// Unique key for deduplication: serviceInstanceName + ip.
  String get uniqueKey => '$serviceInstanceName|$ip';

  /// Returns true if this device is stale (not seen for more than [timeout]).
  bool isStale({Duration timeout = const Duration(seconds: 30)}) {
    return DateTime.now().difference(lastSeen) > timeout;
  }
}
