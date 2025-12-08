import 'dart:async';
import 'dart:developer' as developer;

import 'package:flux/src/features/discovery/data/discovery_repository.dart';
import 'package:flux/src/features/discovery/domain/device.dart';
import 'package:flux/src/features/discovery/domain/discovery_state.dart';
import 'package:flux/src/features/discovery/domain/local_device_info.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'discovery_controller.g.dart';

/// Controller for managing device discovery state.
///
/// Uses [DiscoveryRepository] for mDNS operations and maintains
/// the current discovery state including discovered devices.
///
/// Keep alive to prevent broadcast from being stopped when provider
/// is not watched.
@Riverpod(keepAlive: true)
class DiscoveryController extends _$DiscoveryController {
  StreamSubscription<DiscoveryEvent>? _scanSubscription;
  Timer? _stalenessTimer;
  static const _stalenessCheckInterval = Duration(seconds: 60);
  // Keep devices visible for 10 minutes - mDNS doesn't send continuous updates,
  // so we need a long timeout. DeviceLostEvent + grace period handles normal removal.
  static const _stalenessTimeout = Duration(minutes: 10);

  // US2: Scan timeout timer - sets isScanning=false after timeout
  Timer? _scanTimeoutTimer;
  static const _scanTimeout = Duration(seconds: 5);

  // US1: Grace period for device removal - delays removal on DeviceLostEvent
  final Map<String, Timer> _pendingRemovalTimers = {};
  static const _removalGracePeriod = Duration(seconds: 30);

  /// Own device's IP address for self-filtering (set externally).
  String? _ownIpAddress;

  @override
  Future<DiscoveryState> build() async {
    ref.onDispose(_cleanup);
    return DiscoveryState.initial();
  }

  void _cleanup() {
    _scanSubscription?.cancel();
    _scanSubscription = null;
    _stalenessTimer?.cancel();
    _stalenessTimer = null;
    // US2: Cancel scan timeout timer
    _scanTimeoutTimer?.cancel();
    _scanTimeoutTimer = null;
    // US1: Cancel all pending removal timers
    for (final timer in _pendingRemovalTimers.values) {
      timer.cancel();
    }
    _pendingRemovalTimers.clear();
  }

  DiscoveryRepository get _repository => ref.read(discoveryRepositoryProvider);

  /// Sets the own IP address for self-filtering.
  ///
  /// Call this before starting scan to filter out own device.
  void setOwnIpAddress(String? ip) {
    _ownIpAddress = ip;
    developer.log('Own IP address set to: $ip', name: 'DiscoveryController');
  }

  /// Starts scanning for devices on the network.
  Future<void> startScan() async {
    final currentState = state.valueOrNull ?? DiscoveryState.initial();
    if (currentState.isScanning) return;

    // Keep existing devices when starting scan (don't clear)
    state = AsyncData(currentState.copyWith(isScanning: true, error: null));

    try {
      final stream = _repository.startScan();
      _scanSubscription = stream.listen(_handleDiscoveryEvent);
      _startStalenessTimer();
      // US2: Start scan timeout timer to set isScanning=false after timeout
      _startScanTimeoutTimer();
    } catch (e) {
      state = AsyncData(
        currentState.copyWith(isScanning: false, error: e.toString()),
      );
    }
  }

  /// Stops scanning for devices.
  Future<void> stopScan() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    _stopStalenessTimer();

    await _repository.stopScan();

    // Keep devices when stopping scan (don't clear)
    final currentState = state.valueOrNull ?? DiscoveryState.initial();
    state = AsyncData(currentState.copyWith(isScanning: false));
  }

  /// Starts broadcasting this device's presence.
  Future<void> startBroadcast(LocalDeviceInfo info) async {
    final currentState = state.valueOrNull ?? DiscoveryState.initial();
    if (currentState.isBroadcasting) return;

    try {
      final serviceName = await _repository.startBroadcast(info);
      state = AsyncData(
        currentState.copyWith(
          isBroadcasting: true,
          ownServiceInstanceName: serviceName,
          error: null,
        ),
      );
    } catch (e) {
      state = AsyncData(currentState.copyWith(error: e.toString()));
    }
  }

  /// Stops broadcasting this device's presence.
  Future<void> stopBroadcast() async {
    await _repository.stopBroadcast();

    final currentState = state.valueOrNull ?? DiscoveryState.initial();
    state = AsyncData(
      currentState.copyWith(
        isBroadcasting: false,
        ownServiceInstanceName: null,
      ),
    );
  }

  /// Restarts the discovery scan (clears stale entries and refreshes).
  Future<void> refresh() async {
    await stopScan();
    await startScan();
  }

  void _handleDiscoveryEvent(DiscoveryEvent event) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    switch (event) {
      case DeviceFoundEvent(:final device):
        _addOrUpdateDevice(device);
      case DeviceUpdatedEvent(:final device):
        _addOrUpdateDevice(device);
      case DeviceLostEvent(:final serviceInstanceName):
        // US1: Schedule removal with grace period instead of immediate removal
        _scheduleDeviceRemoval(serviceInstanceName);
      case DiscoveryErrorEvent(:final message):
        state = AsyncData(currentState.copyWith(error: message));
    }
  }

  void _addOrUpdateDevice(Device device) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    // US1: Cancel any pending removal for this device (it's back!)
    _cancelPendingRemoval(device.serviceInstanceName);

    // Self-filtering by service name
    if (currentState.ownServiceInstanceName != null &&
        device.serviceInstanceName == currentState.ownServiceInstanceName) {
      developer.log(
        'Filtered own device by service name: ${device.serviceInstanceName}',
        name: 'DiscoveryController',
      );
      return;
    }

    // Self-filtering by IP address
    if (_ownIpAddress != null && device.ip == _ownIpAddress) {
      developer.log(
        'Filtered own device by IP: ${device.ip}',
        name: 'DiscoveryController',
      );
      return;
    }

    final devices = List<Device>.from(currentState.devices);

    // Deduplicate by IP address only (same device may use different ports
    // on restart)
    final existingByIpIndex = devices.indexWhere((d) => d.ip == device.ip);

    // Also check by service instance name for updates
    final existingByNameIndex = devices.indexWhere(
      (d) => d.serviceInstanceName == device.serviceInstanceName,
    );

    // Handle case where both indices are found but different
    // (shouldn't happen normally)
    final hasBothDifferent =
        existingByIpIndex >= 0 &&
        existingByNameIndex >= 0 &&
        existingByIpIndex != existingByNameIndex;
    if (hasBothDifferent) {
      // Remove the duplicate by name, keep by IP
      devices.removeAt(existingByNameIndex);
      // Recalculate IP index after removal
      final newIpIndex = devices.indexWhere((d) => d.ip == device.ip);
      if (newIpIndex >= 0) {
        // Verify port before updating (async, update only if reachable)
        _verifyAndUpdateDevice(devices, newIpIndex, device);
        return;
      } else {
        // New device - verify before adding
        _verifyAndAddDevice(device);
        return;
      }
    } else if (existingByIpIndex >= 0) {
      // Update existing device with same IP
      final oldDevice = devices[existingByIpIndex];
      if (oldDevice.port != device.port) {
        developer.log(
          'Device port changed: ${device.alias} '
          '${oldDevice.port} -> ${device.port}, verifying...',
          name: 'DiscoveryController',
        );
        // Port changed - verify new port before updating
        _verifyAndUpdateDevice(devices, existingByIpIndex, device);
        return;
      }
      // Same port, just update lastSeen
      devices[existingByIpIndex] = device;
    } else if (existingByNameIndex >= 0) {
      // Update existing device with same service name
      devices[existingByNameIndex] = device;
    } else {
      // New device - verify before adding
      _verifyAndAddDevice(device);
      return;
    }

    state = AsyncData(currentState.copyWith(devices: devices));
  }

  /// Adds a new device to the list.
  ///
  /// Previously verified port reachability, but this caused issues when
  /// the server was still starting up. Now we add devices immediately
  /// and let the transfer fail gracefully if the device is unreachable.
  void _verifyAndAddDevice(Device device) {
    developer.log(
      'Adding discovered device: ${device.alias} '
      'at ${device.ip}:${device.port}',
      name: 'DiscoveryController',
    );

    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final devices = List<Device>.from(currentState.devices);
    // Check if device was already added
    final existingIndex = devices.indexWhere((d) => d.ip == device.ip);
    if (existingIndex >= 0) {
      devices[existingIndex] = device;
    } else {
      devices.add(device);
    }
    state = AsyncData(currentState.copyWith(devices: devices));
  }

  /// Updates a device with new information.
  ///
  /// Previously verified port reachability, but this caused issues when
  /// the server was still starting up. Now we update devices immediately
  /// and let the transfer fail gracefully if the device is unreachable.
  void _verifyAndUpdateDevice(
    List<Device> currentDevices,
    int index,
    Device newDevice,
  ) {
    developer.log(
      'Updating device: ${newDevice.alias} with port ${newDevice.port}',
      name: 'DiscoveryController',
    );

    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final devices = List<Device>.from(currentState.devices);
    final existingIndex = devices.indexWhere((d) => d.ip == newDevice.ip);
    if (existingIndex >= 0) {
      devices[existingIndex] = newDevice;
    }
    state = AsyncData(currentState.copyWith(devices: devices));
  }

  void _removeDevice(String serviceInstanceName) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    // Find the device to get its IP for thorough cleanup
    final deviceToRemove = currentState.devices
        .where((d) => d.serviceInstanceName == serviceInstanceName)
        .firstOrNull;

    final devices = currentState.devices.where((d) {
      // Remove by service name
      if (d.serviceInstanceName == serviceInstanceName) return false;
      // Also remove any device with same IP (duplicate entries)
      if (deviceToRemove != null && d.ip == deviceToRemove.ip) return false;
      return true;
    }).toList();

    state = AsyncData(currentState.copyWith(devices: devices));
  }

  // =========================================================================
  // US1: Grace Period for Device Removal
  // =========================================================================

  /// Schedules a device for removal after a grace period.
  ///
  /// Instead of immediately removing a device when DeviceLostEvent is received,
  /// we wait for [_removalGracePeriod] to allow for temporary mDNS hiccups.
  void _scheduleDeviceRemoval(String serviceInstanceName) {
    // Cancel any existing timer for this device
    _pendingRemovalTimers[serviceInstanceName]?.cancel();

    developer.log(
      'Scheduling device removal in ${_removalGracePeriod.inSeconds}s: '
      '$serviceInstanceName',
      name: 'DiscoveryController',
    );

    // Start grace period timer
    _pendingRemovalTimers[serviceInstanceName] = Timer(
      _removalGracePeriod,
      () => _executeDeviceRemoval(serviceInstanceName),
    );
  }

  /// Executes the actual device removal after grace period expires.
  void _executeDeviceRemoval(String serviceInstanceName) {
    developer.log(
      'Removing device after grace period: $serviceInstanceName',
      name: 'DiscoveryController',
    );
    _removeDevice(serviceInstanceName);
    _pendingRemovalTimers.remove(serviceInstanceName);
  }

  /// Cancels a pending device removal (called when device re-appears).
  void _cancelPendingRemoval(String serviceInstanceName) {
    final timer = _pendingRemovalTimers.remove(serviceInstanceName);
    if (timer != null) {
      timer.cancel();
      developer.log(
        'Cancelled pending removal for: $serviceInstanceName',
        name: 'DiscoveryController',
      );
    }
  }

  // =========================================================================
  // US2: Scan Timeout Timer
  // =========================================================================

  /// Starts the scan timeout timer.
  ///
  /// After [_scanTimeout] seconds, sets isScanning to false so the refresh
  /// button becomes available again. Discovery continues in the background.
  void _startScanTimeoutTimer() {
    _scanTimeoutTimer?.cancel();
    _scanTimeoutTimer = Timer(_scanTimeout, _onScanTimeout);
  }

  /// Called when scan timeout expires.
  void _onScanTimeout() {
    final currentState = state.valueOrNull;
    if (currentState != null && currentState.isScanning) {
      developer.log(
        'Scan timeout reached, setting isScanning to false',
        name: 'DiscoveryController',
      );
      state = AsyncData(currentState.copyWith(isScanning: false));
    }
  }

  // =========================================================================
  // Staleness Timer (existing)
  // =========================================================================

  void _startStalenessTimer() {
    _stalenessTimer?.cancel();
    _stalenessTimer = Timer.periodic(_stalenessCheckInterval, (_) {
      _pruneStaleDevices();
    });
  }

  void _stopStalenessTimer() {
    _stalenessTimer?.cancel();
    _stalenessTimer = null;
  }

  void _pruneStaleDevices() {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final now = DateTime.now();
    final staleDevices = <Device>[];
    final freshDevices = currentState.devices.where((device) {
      final isStale = now.difference(device.lastSeen) > _stalenessTimeout;
      if (isStale) staleDevices.add(device);
      return !isStale;
    }).toList();

    if (staleDevices.isNotEmpty) {
      developer.log(
        'Pruning ${staleDevices.length} stale device(s): '
        '${staleDevices.map((d) => d.alias).join(', ')}',
        name: 'DiscoveryController',
      );
      state = AsyncData(currentState.copyWith(devices: freshDevices));
    }
  }
}
