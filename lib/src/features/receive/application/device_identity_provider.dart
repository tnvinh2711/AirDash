import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/src/core/providers/device_info_provider.dart';
import 'package:flux/src/features/discovery/domain/device_type.dart';
import 'package:flux/src/features/receive/domain/device_identity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'device_identity_provider.g.dart';

/// Provides the device's identity information for the Identity Card.
///
/// Combines device info (alias, type, OS) with network info (IP, port).
@riverpod
Future<DeviceIdentity> deviceIdentity(Ref ref) async {
  final deviceInfoProvider = ref.watch(deviceInfoProviderProvider);

  // Fetch all device info in parallel
  final aliasResult = deviceInfoProvider.getAlias();
  final deviceTypeResult = deviceInfoProvider.getDeviceType();
  final osResult = deviceInfoProvider.getOperatingSystem();
  final ipResult = deviceInfoProvider.getLocalIpAddress();

  final results = await Future.wait([
    aliasResult,
    deviceTypeResult,
    osResult,
    ipResult,
  ]);

  return DeviceIdentity(
    alias: results[0]! as String,
    deviceType: results[1]! as DeviceType,
    os: results[2]! as String,
    ipAddress: results[3] as String?,
    port: deviceInfoProvider.getPort(),
  );
}

/// Provides just the IP address for reactive updates.
///
/// Can be invalidated to refresh the IP address when network changes.
@riverpod
Future<String?> localIpAddress(Ref ref) async {
  final deviceInfoProvider = ref.watch(deviceInfoProviderProvider);
  return deviceInfoProvider.getLocalIpAddress();
}


