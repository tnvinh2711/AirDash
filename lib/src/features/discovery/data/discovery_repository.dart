import 'dart:async';

import 'package:bonsoir/bonsoir.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/src/features/discovery/domain/device.dart';
import 'package:flux/src/features/discovery/domain/device_type.dart';
import 'package:flux/src/features/discovery/domain/local_device_info.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'discovery_repository.g.dart';

/// Service type for mDNS discovery.
const String kServiceType = '_flux._tcp';

/// Events emitted during discovery.
sealed class DiscoveryEvent {}

/// A new device was found and resolved on the network.
class DeviceFoundEvent extends DiscoveryEvent {
  /// Creates a DeviceFoundEvent.
  DeviceFoundEvent(this.device);

  /// The discovered device.
  final Device device;
}

/// A device's information was updated.
class DeviceUpdatedEvent extends DiscoveryEvent {
  /// Creates a DeviceUpdatedEvent.
  DeviceUpdatedEvent(this.device);

  /// The updated device.
  final Device device;
}

/// A device left the network.
class DeviceLostEvent extends DiscoveryEvent {
  /// Creates a DeviceLostEvent.
  DeviceLostEvent(this.serviceInstanceName);

  /// The service instance name of the lost device.
  final String serviceInstanceName;
}

/// Discovery encountered an error.
class DiscoveryErrorEvent extends DiscoveryEvent {
  /// Creates a DiscoveryErrorEvent.
  DiscoveryErrorEvent(this.message);

  /// The error message.
  final String message;
}

/// Repository for mDNS device discovery operations.
///
/// Uses the bonsoir package for mDNS/DNS-SD discovery and broadcasting.
class DiscoveryRepository {
  BonsoirBroadcast? _broadcast;
  BonsoirDiscovery? _discovery;
  String? _ownServiceInstanceName;

  /// Whether currently broadcasting.
  bool get isBroadcasting => _broadcast != null;

  /// Whether currently scanning.
  bool get isScanning => _discovery != null;

  /// The service instance name of the current broadcast, if any.
  String? get ownServiceInstanceName => _ownServiceInstanceName;

  /// Starts broadcasting this device's presence on the network.
  ///
  /// Returns the service instance name assigned to this broadcast.
  Future<String> startBroadcast(LocalDeviceInfo info) async {
    if (_broadcast != null) {
      await stopBroadcast();
    }

    final service = BonsoirService(
      name: info.alias,
      type: kServiceType,
      port: info.port,
      attributes: info.toTxtAttributes(),
    );

    _broadcast = BonsoirBroadcast(service: service);
    await _broadcast!.initialize();
    await _broadcast!.start();

    _ownServiceInstanceName = service.name;
    return service.name;
  }

  /// Stops broadcasting this device's presence.
  Future<void> stopBroadcast() async {
    await _broadcast?.stop();
    _broadcast = null;
    _ownServiceInstanceName = null;
  }

  /// Starts scanning for other devices on the network.
  ///
  /// Returns a stream of discovery events.
  Stream<DiscoveryEvent> startScan() {
    final controller = StreamController<DiscoveryEvent>.broadcast();

    unawaited(_startScanInternal(controller));

    return controller.stream;
  }

  Future<void> _startScanInternal(
    StreamController<DiscoveryEvent> controller,
  ) async {
    if (_discovery != null) {
      await stopScan();
    }

    try {
      _discovery = BonsoirDiscovery(type: kServiceType);
      await _discovery!.initialize();

      _discovery!.eventStream!.listen(
        (event) => _handleDiscoveryEvent(event, controller),
        onError: (Object error) {
          controller.add(DiscoveryErrorEvent(error.toString()));
        },
      );

      await _discovery!.start();
    } catch (e) {
      controller.add(DiscoveryErrorEvent(e.toString()));
    }
  }

  void _handleDiscoveryEvent(
    BonsoirDiscoveryEvent event,
    StreamController<DiscoveryEvent> controller,
  ) {
    switch (event) {
      case BonsoirDiscoveryServiceFoundEvent():
        // Service found but not yet resolved - trigger resolution
        final service = event.service;
        service.resolve(_discovery!.serviceResolver);
      case BonsoirDiscoveryServiceResolvedEvent():
        final service = event.service;
        final device = _parseDevice(service);
        if (device != null) {
          controller.add(DeviceFoundEvent(device));
        }
      case BonsoirDiscoveryServiceLostEvent():
        final service = event.service;
        controller.add(DeviceLostEvent(service.name));
      case BonsoirDiscoveryServiceUpdatedEvent():
        final service = event.service;
        final device = _parseDevice(service);
        if (device != null) {
          controller.add(DeviceUpdatedEvent(device));
        }
      default:
        // Lifecycle events - no action needed
        break;
    }
  }

  Device? _parseDevice(BonsoirService service) {
    // host is null if the service has not been resolved yet
    if (service.host == null) {
      return null;
    }

    final attributes = service.attributes;
    return Device(
      serviceInstanceName: service.name,
      ip: service.host!,
      port: service.port,
      alias: attributes['alias'] ?? service.name,
      deviceType: DeviceType.fromString(attributes['deviceType'] ?? 'unknown'),
      os: attributes['os'] ?? 'unknown',
      lastSeen: DateTime.now(),
    );
  }

  /// Stops scanning for devices.
  Future<void> stopScan() async {
    await _discovery?.stop();
    _discovery = null;
  }

  /// Disposes all resources.
  Future<void> dispose() async {
    await stopBroadcast();
    await stopScan();
  }
}

/// Provider for [DiscoveryRepository].
@riverpod
DiscoveryRepository discoveryRepository(Ref ref) {
  final repository = DiscoveryRepository();
  ref.onDispose(repository.dispose);
  return repository;
}
