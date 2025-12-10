/// Result of a file open operation.
///
/// Used by `FileOpenService` to indicate the outcome of open/reveal operations.
enum FileOpenResult {
  /// Operation completed successfully.
  success,

  /// The file does not exist at the specified path.
  fileNotFound,

  /// No application is available to open this file type.
  noAppAvailable,

  /// Permission to access the file was denied.
  permissionDenied,

  /// An unknown error occurred.
  unknownError,
}

/// Extension methods for [FileOpenResult].
extension FileOpenResultX on FileOpenResult {
  /// Returns true if the operation was successful.
  bool get isSuccess => this == FileOpenResult.success;

  /// Returns true if the operation failed.
  bool get isFailure => this != FileOpenResult.success;

  /// Returns a user-friendly error message for this result.
  ///
  /// Returns null if the result is [FileOpenResult.success].
  String? get errorMessage {
    switch (this) {
      case FileOpenResult.success:
        return null;
      case FileOpenResult.fileNotFound:
        return 'File not found. It may have been moved or deleted.';
      case FileOpenResult.noAppAvailable:
        return 'No application available to open this file type.';
      case FileOpenResult.permissionDenied:
        return 'Permission denied. Please grant file access permission.';
      case FileOpenResult.unknownError:
        return 'An error occurred while opening the file.';
    }
  }
}
