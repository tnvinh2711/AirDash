import 'package:flux/src/features/discovery/domain/device.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'discovery_state.freezed.dart';

/// State container for the discovery system.
///
/// This is the main state object managed by `DiscoveryController`.
/// It tracks scanning/broadcasting status, discovered devices, and errors.
@freezed
class DiscoveryState with _$DiscoveryState {
  /// Creates a new DiscoveryState instance.
  const factory DiscoveryState({
    /// Whether active scanning is in progress.
    @Default(false) bool isScanning,

    /// Whether broadcasting own presence.
    @Default(false) bool isBroadcasting,

    /// Currently discovered devices (excluding self).
    @Default([]) List<Device> devices,

    /// Error message if discovery or broadcast failed.
    String? error,

    /// Service instance name of own broadcast (for self-filtering).
    String? ownServiceInstanceName,
  }) = _DiscoveryState;

  const DiscoveryState._();

  /// Creates an initial state (not scanning, not broadcasting, empty list).
  factory DiscoveryState.initial() => const DiscoveryState();

  /// Creates a scanning state.
  factory DiscoveryState.scanning() => const DiscoveryState(isScanning: true);

  /// Creates an error state with the given message.
  factory DiscoveryState.withError(String message) =>
      DiscoveryState(error: message);

  /// Returns true if there are no discovered devices.
  bool get isEmpty => devices.isEmpty;

  /// Returns the number of discovered devices.
  int get deviceCount => devices.length;

  /// Returns a device by its unique key, or null if not found.
  Device? findByUniqueKey(String uniqueKey) {
    return devices.cast<Device?>().firstWhere(
      (d) => d?.uniqueKey == uniqueKey,
      orElse: () => null,
    );
  }
}
