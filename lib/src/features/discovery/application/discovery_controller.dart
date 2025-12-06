import 'dart:async';

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
@riverpod
class DiscoveryController extends _$DiscoveryController {
  StreamSubscription<DiscoveryEvent>? _scanSubscription;
  Timer? _stalenessTimer;
  static const _stalenessCheckInterval = Duration(seconds: 10);
  static const _stalenessTimeout = Duration(seconds: 30);

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
  }

  DiscoveryRepository get _repository => ref.read(discoveryRepositoryProvider);

  /// Starts scanning for devices on the network.
  Future<void> startScan() async {
    final currentState = state.valueOrNull ?? DiscoveryState.initial();
    if (currentState.isScanning) return;

    state = AsyncData(currentState.copyWith(isScanning: true, error: null));

    try {
      final stream = _repository.startScan();
      _scanSubscription = stream.listen(_handleDiscoveryEvent);
      _startStalenessTimer();
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

    final currentState = state.valueOrNull ?? DiscoveryState.initial();
    state = AsyncData(currentState.copyWith(isScanning: false, devices: []));
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
        _removeDevice(serviceInstanceName);
      case DiscoveryErrorEvent(:final message):
        state = AsyncData(currentState.copyWith(error: message));
    }
  }

  void _addOrUpdateDevice(Device device) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    // Self-filtering: skip if this is our own device
    if (currentState.ownServiceInstanceName != null &&
        device.serviceInstanceName == currentState.ownServiceInstanceName) {
      return;
    }

    final devices = List<Device>.from(currentState.devices);
    final existingIndex = devices.indexWhere(
      (d) => d.serviceInstanceName == device.serviceInstanceName,
    );

    if (existingIndex >= 0) {
      devices[existingIndex] = device;
    } else {
      devices.add(device);
    }

    state = AsyncData(currentState.copyWith(devices: devices));
  }

  void _removeDevice(String serviceInstanceName) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final devices = currentState.devices
        .where((d) => d.serviceInstanceName != serviceInstanceName)
        .toList();

    state = AsyncData(currentState.copyWith(devices: devices));
  }

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
    final freshDevices = currentState.devices.where((device) {
      return now.difference(device.lastSeen) <= _stalenessTimeout;
    }).toList();

    if (freshDevices.length != currentState.devices.length) {
      state = AsyncData(currentState.copyWith(devices: freshDevices));
    }
  }
}
