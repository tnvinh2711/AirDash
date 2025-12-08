import 'dart:async';
import 'dart:developer' as developer;

import 'package:bonsoir/bonsoir.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/src/core/providers/device_info_provider.dart';
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

  /// Track pending services that were found but not yet resolved.
  /// Used as fallback when TXT record resolution fails on Android.
  final Map<String, BonsoirService> _pendingServices = {};

  /// Timeout for service resolution - if resolution doesn't complete
  /// within this time, we'll try to use the service anyway.
  static const _resolveTimeout = Duration(seconds: 5);

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

    developer.log(
      'Starting broadcast: name=${service.name}, type=${service.type}, '
      'port=${service.port}, attributes=${service.attributes}',
      name: 'DiscoveryRepository',
    );

    _broadcast = BonsoirBroadcast(service: service);
    await _broadcast!.initialize();

    // Track the actual service name (may be modified if name conflict occurs)
    var actualServiceName = service.name;

    // Listen to broadcast events for debugging and name conflict handling
    _broadcast!.eventStream?.listen(
      (event) {
        developer.log(
          'Broadcast event: ${event.runtimeType} - ${event.service?.name}',
          name: 'DiscoveryRepository',
        );

        // Handle name conflict - update our tracked service name
        if (event is BonsoirBroadcastNameAlreadyExistsEvent) {
          final newName = event.service.name;
          developer.log(
            'Service name conflict, renamed to: $newName',
            name: 'DiscoveryRepository',
          );
          actualServiceName = newName;
          _ownServiceInstanceName = newName;
        }
      },
      onError: (Object error) {
        developer.log(
          'Broadcast error: $error',
          name: 'DiscoveryRepository',
          level: 1000,
        );
      },
    );

    await _broadcast!.start();

    developer.log(
      'Broadcast started successfully for ${service.name}',
      name: 'DiscoveryRepository',
    );

    _ownServiceInstanceName = actualServiceName;
    return actualServiceName;
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
    developer.log(
      'Discovery event: ${event.runtimeType}',
      name: 'DiscoveryRepository',
    );

    switch (event) {
      case BonsoirDiscoveryServiceFoundEvent():
        // Service found but not yet resolved - trigger resolution
        final discovery = _discovery;
        if (discovery == null) return;
        final service = event.service;
        developer.log(
          'Service FOUND: name=${service.name}, type=${service.type}, '
          'port=${service.port}, host=${service.host}',
          name: 'DiscoveryRepository',
        );

        // Track pending service for fallback resolution
        _pendingServices[service.name] = service;

        // Start resolution
        service.resolve(discovery.serviceResolver);

        // Schedule fallback in case resolution fails (Android TXT record bug)
        Future.delayed(_resolveTimeout, () {
          if (_pendingServices.containsKey(service.name)) {
            developer.log(
              'Resolution timeout for ${service.name}, attempting fallback',
              name: 'DiscoveryRepository',
            );
            _handleResolutionFallback(service, controller);
          }
        });
      case BonsoirDiscoveryServiceResolvedEvent():
        final service = event.service;
        // Remove from pending since resolution succeeded
        _pendingServices.remove(service.name);
        developer.log(
          'Service RESOLVED: name=${service.name}, type=${service.type}, '
          'port=${service.port}, host=${service.host}, '
          'attributes=${service.attributes}',
          name: 'DiscoveryRepository',
        );
        // Parse device async to resolve hostname to IP
        _parseDeviceAsync(service).then((device) {
          if (device != null) {
            developer.log(
              'Device parsed: ${device.alias} at ${device.ip}:${device.port}',
              name: 'DiscoveryRepository',
            );
            controller.add(DeviceFoundEvent(device));
          } else {
            developer.log(
              'Device parse returned null for ${service.name}',
              name: 'DiscoveryRepository',
            );
          }
        });
      case BonsoirDiscoveryServiceLostEvent():
        final service = event.service;
        _pendingServices.remove(service.name);
        developer.log(
          'Service LOST: ${service.name}',
          name: 'DiscoveryRepository',
        );
        controller.add(DeviceLostEvent(service.name));
      case BonsoirDiscoveryServiceUpdatedEvent():
        final service = event.service;
        _pendingServices.remove(service.name);
        developer.log(
          'Service UPDATED: name=${service.name}, '
          'port=${service.port}, host=${service.host}',
          name: 'DiscoveryRepository',
        );
        _parseDeviceAsync(service).then((device) {
          if (device != null) {
            controller.add(DeviceUpdatedEvent(device));
          }
        });
      case BonsoirDiscoveryServiceResolveFailedEvent():
        developer.log(
          'Service RESOLVE FAILED - attempting fallback for pending services',
          name: 'DiscoveryRepository',
        );
        // Try to resolve any pending services using fallback
        for (final entry in _pendingServices.entries.toList()) {
          _handleResolutionFallback(entry.value, controller);
        }
      default:
        // Lifecycle events - no action needed
        break;
    }
  }

  /// Handle fallback resolution when normal resolution fails.
  /// This is needed for Android's TXT record bug (bonsoir issue #117).
  void _handleResolutionFallback(
    BonsoirService service,
    StreamController<DiscoveryEvent> controller,
  ) {
    _pendingServices.remove(service.name);

    // If service has host (was partially resolved), try to use it
    final host = service.host;
    if (host != null && host.isNotEmpty) {
      developer.log(
        'Fallback: Using partially resolved service ${service.name} '
        'with host=$host, port=${service.port}',
        name: 'DiscoveryRepository',
      );
      _parseDeviceAsync(service).then((device) {
        if (device != null) {
          developer.log(
            'Fallback device parsed: ${device.alias} at ${device.ip}:${device.port}',
            name: 'DiscoveryRepository',
          );
          controller.add(DeviceFoundEvent(device));
        } else {
          developer.log(
            'Fallback parse returned null for ${service.name}',
            name: 'DiscoveryRepository',
          );
        }
      });
    } else {
      developer.log(
        'Fallback failed: Service ${service.name} has no host',
        name: 'DiscoveryRepository',
      );
    }
  }

  Future<Device?> _parseDeviceAsync(BonsoirService service) async {
    // host is null if the service has not been resolved yet
    if (service.host == null) {
      return null;
    }

    final attributes = service.attributes;

    // Try to get IP from TXT record first, fall back to resolved host
    // Android has a known bug where TXT records may not be available
    // (see bonsoir issue #117)
    var ip = _getIpFromAttributes(attributes);
    if (ip == null) {
      // Fall back to resolved host IP
      final host = service.host;
      if (host != null && host.isNotEmpty) {
        // Validate it looks like an IPv4 address
        final ipv4Regex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
        if (ipv4Regex.hasMatch(host)) {
          ip = host;
          developer.log(
            'Using resolved host IP (TXT record unavailable): $ip',
            name: 'DiscoveryRepository',
          );
        }
      }
    }

    if (ip == null) {
      developer.log(
        'Skipping device without valid IP: ${service.name}',
        name: 'DiscoveryRepository',
      );
      return null;
    }

    // Get port from service, fallback to TXT attribute if service.port is 0
    // (Android NSD sometimes doesn't resolve port correctly)
    var port = service.port;
    if (port == 0) {
      final portStr = attributes['port'];
      if (portStr != null) {
        port = int.tryParse(portStr) ?? 0;
        developer.log(
          'Using port from TXT record: $port (service.port was 0)',
          name: 'DiscoveryRepository',
        );
      }
    }

    // Final fallback: use default port if still 0
    // This handles Android's TXT record bug where port can't be obtained
    if (port == 0) {
      port = kDefaultPort;
      developer.log(
        'Using default port $port (service.port and TXT port unavailable)',
        name: 'DiscoveryRepository',
      );
    }

    return Device(
      serviceInstanceName: service.name,
      ip: ip,
      port: port,
      alias: attributes['alias'] ?? service.name,
      deviceType: DeviceType.fromString(attributes['deviceType'] ?? 'unknown'),
      os: attributes['os'] ?? 'unknown',
      lastSeen: DateTime.now(),
    );
  }

  /// Extracts the first valid IP address from TXT record attributes.
  String? _getIpFromAttributes(Map<String, String> attributes) {
    final ipsString = attributes['ips'];
    if (ipsString == null || ipsString.isEmpty) {
      return null;
    }

    // Parse comma-separated IPs and return the first one
    final ips = ipsString
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);
    for (final ip in ips) {
      // Validate it looks like an IPv4 address
      final ipv4Regex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
      if (ipv4Regex.hasMatch(ip)) {
        developer.log(
          'Using IP from TXT record: $ip',
          name: 'DiscoveryRepository',
        );
        return ip;
      }
    }
    return null;
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
@Riverpod(keepAlive: true)
DiscoveryRepository discoveryRepository(Ref ref) {
  final repository = DiscoveryRepository();
  ref.onDispose(repository.dispose);
  return repository;
}
