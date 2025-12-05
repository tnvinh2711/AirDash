import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/app.dart';

/// Entry point for the FLUX application.
///
/// Wraps the app in a [ProviderScope] for Riverpod state management.
void main() {
  runApp(
    const ProviderScope(
      child: FluxApp(),
    ),
  );
}
