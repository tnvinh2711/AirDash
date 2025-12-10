import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/src/core/providers/file_open_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'file_open_service_provider.g.dart';

/// Provides the singleton [FileOpenService] instance.
///
/// The service is lazily initialized on first access and persists
/// for the lifetime of the application.
///
/// Usage:
/// ```dart
/// final fileOpenService = ref.watch(fileOpenServiceProvider);
/// final result = await fileOpenService.openFile('/path/to/file');
/// ```
@Riverpod(keepAlive: true)
FileOpenService fileOpenService(Ref ref) {
  return FileOpenService();
}
