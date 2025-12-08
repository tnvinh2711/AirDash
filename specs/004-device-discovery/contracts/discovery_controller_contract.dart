// Discovery Controller Contract
// Feature: 004-device-discovery
// This file defines the abstract interface for the discovery state controller.
// Implementation will use Riverpod AsyncNotifier pattern.

/// State of the discovery system.
///
/// Implementation should use Freezed for immutability.
abstract class DiscoveryStateContract {
  /// Whether active scanning is in progress.
  bool get isScanning;

  /// Whether broadcasting own presence.
  bool get isBroadcasting;

  /// Currently discovered devices (excluding self).
  List<DeviceContract> get devices;

  /// Error message if discovery or broadcast failed.
  String? get error;
}

/// A discovered device.
///
/// Implementation should use Freezed for immutability.
abstract class DeviceContract {
  /// mDNS service instance identifier.
  String get serviceInstanceName;

  /// IPv4 address for connection.
  String get ip;

  /// Service port for file transfer.
  int get port;

  /// Human-readable device name.
  String get alias;

  /// Category of device (phone, tablet, desktop, laptop, unknown).
  String get deviceType;

  /// Platform identifier (iOS, Android, macOS, Windows, Linux).
  String get os;

  /// Last mDNS announcement timestamp (for staleness detection).
  DateTime get lastSeen;
}

/// Contract for the discovery controller.
///
/// Implementation should extend AsyncNotifier<DiscoveryState>
/// using riverpod_generator.
abstract class DiscoveryControllerContract {
  /// Starts broadcasting this device's presence.
  ///
  /// Retrieves device info from settings and device_info_plus.
  /// Updates state.isBroadcasting on success.
  /// Updates state.error on failure.
  Future<void> startBroadcast();

  /// Stops broadcasting this device's presence.
  ///
  /// Updates state.isBroadcasting to false.
  Future<void> stopBroadcast();

  /// Starts scanning for devices on the network.
  ///
  /// Updates state.isScanning to true.
  /// Subscribes to discovery events and updates state.devices.
  /// Filters out own device based on service instance name.
  /// Starts staleness timer for 30-second cleanup.
  Future<void> startScan();

  /// Stops scanning for devices.
  ///
  /// Updates state.isScanning to false.
  /// Clears device list.
  /// Stops staleness timer.
  Future<void> stopScan();

  /// Restarts the discovery scan.
  ///
  /// Stops current scan (if any), clears stale entries,
  /// and starts a fresh scan.
  Future<void> refresh();
}
