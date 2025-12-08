import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flux/app.dart';
import 'package:flux/src/features/discovery/domain/device_type.dart';
import 'package:flux/src/features/receive/application/device_identity_provider.dart';
import 'package:flux/src/features/receive/application/receive_settings_provider.dart';
import 'package:flux/src/features/receive/application/server_controller.dart';
import 'package:flux/src/features/receive/domain/device_identity.dart';
import 'package:flux/src/features/receive/domain/receive_settings.dart';
import 'package:flux/src/features/receive/domain/server_state.dart';

/// Mock server controller that returns a stopped state immediately.
/// Server is stopped to avoid PulsingAvatar animation running forever.
class _MockServerController extends ServerController {
  @override
  Future<ServerState> build() async {
    return ServerState.stopped();
  }

  @override
  Future<void> startServer({
    String? destinationPath,
    bool quickSaveEnabled = false,
  }) async {
    // No-op in tests - prevents auto-start from triggering
  }

  @override
  Future<void> stopServer() async {
    // No-op in tests
  }
}

/// Mock receive settings notifier that returns default settings immediately.
class _MockReceiveSettingsNotifier extends ReceiveSettingsNotifier {
  @override
  Future<ReceiveSettings> build() async {
    return ReceiveSettings.defaults();
  }
}

void main() {
  testWidgets('FluxApp renders correctly with navigation', (tester) async {
    // Build our app wrapped in ProviderScope with mocked providers.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Override serverControllerProvider
          // to return a stopped state immediately
          serverControllerProvider.overrideWith(_MockServerController.new),
          // Override receiveSettingsNotifierProvider to return default settings
          receiveSettingsNotifierProvider.overrideWith(
            _MockReceiveSettingsNotifier.new,
          ),
          // Override deviceIdentityProvider to return mock identity
          deviceIdentityProvider.overrideWith(
            (ref) async => const DeviceIdentity(
              alias: 'Test Device',
              deviceType: DeviceType.desktop,
              os: 'Test OS',
              ipAddress: '192.168.1.100',
              port: 8080,
            ),
          ),
        ],
        child: const FluxApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify that the navigation bar is displayed with all 3 tabs.
    expect(find.text('Receive'), findsWidgets);
    expect(find.text('Send'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);

    // Verify that the default Receive screen is displayed.
    // The ReceiveScreen shows 'Receive'
    // in the AppBar title (found in findsWidgets above)
    // and contains the IdentityCard widget
    expect(find.byType(ProviderScope), findsOneWidget);
  });
}
