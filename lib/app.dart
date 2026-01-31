import 'dart:io';

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/src/core/providers/permission_provider.dart';
import 'package:flux/src/core/routing/app_router.dart';
import 'package:flux/src/features/settings/application/settings_controller.dart';

/// The root widget for the FLUX application.
///
/// This widget configures Material 3 theming using [FlexColorScheme]
/// and integrates go_router for navigation with 3 main tabs.
/// Requests storage permission on Android when the app opens.
class FluxApp extends ConsumerStatefulWidget {
  /// Creates a [FluxApp] widget.
  const FluxApp({super.key});

  @override
  ConsumerState<FluxApp> createState() => _FluxAppState();
}

class _FluxAppState extends ConsumerState<FluxApp> {
  @override
  void initState() {
    super.initState();
    // Request storage permission on Android when app opens
    _requestStoragePermission();
  }

  Future<void> _requestStoragePermission() async {
    if (!Platform.isAndroid) return;

    // Use addPostFrameCallback to ensure the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = ref.read(permissionControllerProvider.notifier);
      await controller.requestStoragePermission();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsControllerProvider);

    return settingsAsync.when(
      data: (settings) => MaterialApp.router(
        title: 'FLUX',
        debugShowCheckedModeBanner: false,
        // FlexColorScheme light theme with Material 3
        theme: FlexThemeData.light(scheme: settings.colorScheme),
        // FlexColorScheme dark theme with Material 3
        darkTheme: FlexThemeData.dark(scheme: settings.colorScheme),
        // Theme mode from settings
        themeMode: settings.themeMode,
        // go_router configuration
        routerConfig: appRouter,
      ),
      loading: () => const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (_, __) => MaterialApp.router(
        title: 'FLUX',
        debugShowCheckedModeBanner: false,
        theme: FlexThemeData.light(scheme: FlexScheme.barossa),
        darkTheme: FlexThemeData.dark(scheme: FlexScheme.barossa),
        routerConfig: appRouter,
      ),
    );
  }
}
