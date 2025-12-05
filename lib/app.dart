import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flux/src/core/routing/app_router.dart';

/// The root widget for the FLUX application.
///
/// This widget configures Material 3 theming using [FlexColorScheme]
/// and integrates go_router for navigation with 3 main tabs.
class FluxApp extends StatelessWidget {
  /// Creates a [FluxApp] widget.
  const FluxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FLUX',
      debugShowCheckedModeBanner: false,
      // FlexColorScheme light theme with Material 3
      theme: FlexThemeData.light(scheme: FlexScheme.blueWhale),
      // FlexColorScheme dark theme with Material 3
      darkTheme: FlexThemeData.dark(scheme: FlexScheme.blueWhale),
      // go_router configuration
      routerConfig: appRouter,
    );
  }
}
