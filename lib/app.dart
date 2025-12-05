import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

/// The root widget for the FLUX application.
///
/// This widget configures Material 3 theming using [FlexColorScheme]
/// and will eventually integrate go_router for navigation.
class FluxApp extends StatelessWidget {
  /// Creates a [FluxApp] widget.
  const FluxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FLUX',
      debugShowCheckedModeBanner: false,
      // FlexColorScheme light theme with Material 3
      theme: FlexThemeData.light(scheme: FlexScheme.blueWhale),
      // FlexColorScheme dark theme with Material 3
      darkTheme: FlexThemeData.dark(scheme: FlexScheme.blueWhale),
      home: const _PlaceholderHomePage(),
    );
  }
}

/// Placeholder home page for initial project setup.
///
/// This will be replaced with go_router navigation in a future feature.
class _PlaceholderHomePage extends StatelessWidget {
  const _PlaceholderHomePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FLUX'),
        centerTitle: true,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.share,
              size: 64,
              color: Colors.blueGrey,
            ),
            SizedBox(height: 16),
            Text(
              'FLUX',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Peer-to-Peer File Sharing',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
