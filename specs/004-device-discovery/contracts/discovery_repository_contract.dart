// Discovery Repository Contract
// Feature: 004-device-discovery
// This file defines the abstract interface for device discovery operations.
// Implementation will use the bonsoir package for mDNS/DNS-SD.

import 'dart:async';

/// Information about the local device for broadcasting.
abstract class LocalDeviceInfo {
  String get alias;
  String get deviceType;
  String get os;
  int get port;
}

/// A discovered device on the network.
abstract class DiscoveredDevice {
  String get serviceInstanceName;
  String get ip;
  int get port;
  String get alias;
  String get deviceType;
  String get os;
}

/// Events emitted during discovery.
sealed class DiscoveryEvent {}

/// A new device was found on the network.
class DeviceFoundEvent extends DiscoveryEvent {
  DeviceFoundEvent(this.device);
  final DiscoveredDevice device;
}

/// A device's information was updated.
class DeviceUpdatedEvent extends DiscoveryEvent {
  DeviceUpdatedEvent(this.device);
  final DiscoveredDevice device;
}

/// A device left the network.
class DeviceLostEvent extends DiscoveryEvent {
  DeviceLostEvent(this.serviceInstanceName);
  final String serviceInstanceName;
}

/// Discovery encountered an error.
class DiscoveryErrorEvent extends DiscoveryEvent {
  DiscoveryErrorEvent(this.message);
  final String message;
}

/// Contract for device discovery operations.
///
/// Implementations must handle mDNS broadcasting and discovery
/// using the DNS-SD protocol.
abstract class DiscoveryRepositoryContract {
  /// Service type for mDNS discovery.
  static const String serviceType = '_flux._tcp';

  /// Starts broadcasting this device's presence on the network.
  ///
  /// - [info]: Local device information to broadcast
  /// - Returns: The service instance name assigned to this broadcast
  /// - Throws: If broadcast fails to initialize
  Future<String> startBroadcast(LocalDeviceInfo info);

  /// Stops broadcasting this device's presence.
  ///
  /// Safe to call even if not currently broadcasting.
  Future<void> stopBroadcast();

  /// Starts scanning for other devices on the network.
  ///
  /// - Returns: Stream of discovery events
  /// - Throws: If scan fails to initialize
  Stream<DiscoveryEvent> startScan();

  /// Stops scanning for devices.
  ///
  /// Safe to call even if not currently scanning.
  Future<void> stopScan();

  /// Whether currently broadcasting.
  bool get isBroadcasting;

  /// Whether currently scanning.
  bool get isScanning;

  /// The service instance name of the current broadcast, if any.
  String? get ownServiceInstanceName;
}
