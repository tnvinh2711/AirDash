import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flux/src/core/providers/device_info_provider.dart';
import 'package:flux/src/features/discovery/domain/device.dart';
import 'package:flux/src/features/history/application/history_provider.dart';
import 'package:flux/src/features/history/domain/new_transfer_history_entry.dart';
import 'package:flux/src/features/history/domain/transfer_direction.dart';
import 'package:flux/src/features/history/domain/transfer_status.dart';
import 'package:flux/src/features/send/data/compression_service.dart';
import 'package:flux/src/features/send/data/dtos/handshake_request.dart';
import 'package:flux/src/features/send/data/transfer_client_service.dart';
import 'package:flux/src/features/send/domain/selected_item.dart';
import 'package:flux/src/features/send/domain/selected_item_type.dart';
import 'package:flux/src/features/send/domain/transfer_payload.dart';
import 'package:flux/src/features/send/domain/transfer_phase.dart';
import 'package:flux/src/features/send/domain/transfer_progress.dart';
import 'package:flux/src/features/send/domain/transfer_result.dart';
import 'package:flux/src/features/send/domain/transfer_state.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'transfer_controller.g.dart';

/// Controller for managing file transfers to a receiver device.
///
/// Handles the complete transfer flow: prepare → handshake → upload → record.
/// Supports cancellation and tracks progress for UI updates.
///
/// Keep alive to prevent transfer from being cancelled when provider
/// is not watched.
@Riverpod(keepAlive: true)
class TransferController extends _$TransferController {
  CancelToken? _cancelToken;
  final _uuid = const Uuid();
  final List<String> _tempFilesToCleanup = [];

  @override
  TransferState build() {
    ref.onDispose(() {
      _cancelToken?.cancel();
      // Cleanup temp files synchronously on dispose
      for (final path in _tempFilesToCleanup) {
        try {
          File(path).deleteSync();
        } catch (_) {
          // Ignore cleanup errors on dispose
        }
      }
      _tempFilesToCleanup.clear();
    });
    return const TransferState.idle();
  }

  Future<void> _cleanupTempFiles() async {
    final compressionService = ref.read(compressionServiceProvider);
    for (final path in _tempFilesToCleanup) {
      await compressionService.cleanup(path);
    }
    _tempFilesToCleanup.clear();
  }

  /// Sends a single item to the target device.
  ///
  /// Prepares the payload (checksum), performs handshake, uploads the file,
  /// and records the transfer in history.
  Future<TransferResult> send({
    required SelectedItem item,
    required Device target,
  }) async {
    _cancelToken = CancelToken();

    try {
      // Phase 1: Preparing
      state = TransferState.preparing(currentItem: item);
      final payload = await _preparePayload(item);

      // Phase 2: Handshaking
      state = TransferState.sending(
        progress: TransferProgress(
          currentItemIndex: 0,
          totalItems: 1,
          bytesSent: 0,
          totalBytes: payload.fileSize,
          phase: TransferPhase.handshaking,
        ),
        results: [],
        targetDeviceAlias: target.alias,
      );

      final handshakeResult = await _performHandshake(payload, target);
      if (!handshakeResult.accepted) {
        final errorMessage = _getHandshakeErrorMessage(handshakeResult.error);
        final result = TransferResult(
          selectedItem: item,
          success: false,
          error: errorMessage,
        );
        await _recordHistory(item, target, TransferStatus.failed);
        state = TransferState.failed(
          error: result.error!,
          results: [result],
          targetDeviceAlias: target.alias,
        );
        return result;
      }

      // Phase 3: Uploading
      final uploadResult = await _performUpload(
        payload,
        target,
        handshakeResult.sessionId!,
      );

      final result = TransferResult(
        selectedItem: item,
        success: uploadResult.success,
        error: uploadResult.error,
        savedPath: uploadResult.savedPath,
      );

      // Record history
      await _recordHistory(
        item,
        target,
        uploadResult.success ? TransferStatus.completed : TransferStatus.failed,
      );

      // Update state
      if (uploadResult.success) {
        state = TransferState.completed(
          results: [result],
          targetDeviceAlias: target.alias,
        );
      } else {
        state = TransferState.failed(
          error: uploadResult.error ?? 'Upload failed',
          results: [result],
          targetDeviceAlias: target.alias,
        );
      }

      return result;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        final result = TransferResult(
          selectedItem: item,
          success: false,
          error: 'Cancelled',
        );
        await _recordHistory(item, target, TransferStatus.cancelled);
        state = TransferState.cancelled(
          results: [result],
          targetDeviceAlias: target.alias,
        );
        return result;
      }
      rethrow;
    } catch (e) {
      final result = TransferResult(
        selectedItem: item,
        success: false,
        error: e.toString(),
      );
      await _recordHistory(item, target, TransferStatus.failed);
      state = TransferState.failed(
        error: e.toString(),
        results: [result],
        targetDeviceAlias: target.alias,
      );
      return result;
    }
  }

  /// Sends multiple items to the target device sequentially.
  ///
  /// Continues with remaining items on failure. Returns all results.
  Future<List<TransferResult>> sendAll({
    required List<SelectedItem> items,
    required Device target,
  }) async {
    if (items.isEmpty) {
      state = TransferState.completed(
        results: const [],
        targetDeviceAlias: target.alias,
      );
      return [];
    }

    _cancelToken = CancelToken();
    final results = <TransferResult>[];

    for (var i = 0; i < items.length; i++) {
      final item = items[i];

      // Check for cancellation
      if (_cancelToken?.isCancelled ?? false) {
        // Mark remaining items as cancelled
        for (var j = i; j < items.length; j++) {
          results.add(
            TransferResult(
              selectedItem: items[j],
              success: false,
              error: 'Cancelled',
            ),
          );
          await _recordHistory(items[j], target, TransferStatus.cancelled);
        }
        state = TransferState.cancelled(
          results: results,
          targetDeviceAlias: target.alias,
        );
        return results;
      }

      try {
        // Phase 1: Preparing
        state = TransferState.preparing(currentItem: item);
        final payload = await _preparePayload(item);

        // Phase 2: Handshaking
        state = TransferState.sending(
          progress: TransferProgress(
            currentItemIndex: i,
            totalItems: items.length,
            bytesSent: 0,
            totalBytes: payload.fileSize,
            phase: TransferPhase.handshaking,
          ),
          results: results,
          targetDeviceAlias: target.alias,
        );

        final handshakeResult = await _performHandshake(payload, target);
        if (!handshakeResult.accepted) {
          final errorMessage = _getHandshakeErrorMessage(handshakeResult.error);
          results.add(
            TransferResult(
              selectedItem: item,
              success: false,
              error: errorMessage,
            ),
          );
          await _recordHistory(item, target, TransferStatus.failed);
          continue; // Continue with next item
        }

        // Phase 3: Uploading
        final uploadResult = await _performUpload(
          payload,
          target,
          handshakeResult.sessionId!,
          itemIndex: i,
          totalItems: items.length,
          previousResults: results,
        );

        results.add(
          TransferResult(
            selectedItem: item,
            success: uploadResult.success,
            error: uploadResult.error,
            savedPath: uploadResult.savedPath,
          ),
        );

        await _recordHistory(
          item,
          target,
          uploadResult.success
              ? TransferStatus.completed
              : TransferStatus.failed,
        );
      } on DioException catch (e) {
        if (e.type == DioExceptionType.cancel) {
          // Mark this and remaining items as cancelled
          for (var j = i; j < items.length; j++) {
            results.add(
              TransferResult(
                selectedItem: items[j],
                success: false,
                error: 'Cancelled',
              ),
            );
            await _recordHistory(items[j], target, TransferStatus.cancelled);
          }
          state = TransferState.cancelled(
            results: results,
            targetDeviceAlias: target.alias,
          );
          return results;
        }
        results.add(
          TransferResult(
            selectedItem: item,
            success: false,
            error: e.message ?? 'Network error',
          ),
        );
        await _recordHistory(item, target, TransferStatus.failed);
      } catch (e) {
        results.add(
          TransferResult(
            selectedItem: item,
            success: false,
            error: e.toString(),
          ),
        );
        await _recordHistory(item, target, TransferStatus.failed);
      }
    }

    // Determine final state
    final successCount = results.where((r) => r.success).length;
    if (successCount == results.length) {
      state = TransferState.completed(
        results: results,
        targetDeviceAlias: target.alias,
      );
    } else if (successCount == 0) {
      state = TransferState.failed(
        error: 'All transfers failed',
        results: results,
        targetDeviceAlias: target.alias,
      );
    } else {
      state = TransferState.partialSuccess(
        results: results,
        targetDeviceAlias: target.alias,
      );
    }

    return results;
  }

  /// Retries failed items from a previous transfer.
  Future<List<TransferResult>> retry({
    required List<SelectedItem> failedItems,
    required Device target,
  }) async {
    return sendAll(items: failedItems, target: target);
  }

  /// Cancels the current transfer.
  void cancel() {
    _cancelToken?.cancel();
  }

  /// Resets the controller to idle state.
  void reset() {
    _cancelToken?.cancel();
    _cleanupTempFiles();
    state = const TransferState.idle();
  }

  Future<TransferPayload> _preparePayload(SelectedItem item) async {
    final compressionService = ref.read(compressionServiceProvider);

    // Handle text content - write to temp file
    if (item.type == SelectedItemType.text) {
      final tempPath = await _createTextTempFile(item);
      _tempFilesToCleanup.add(tempPath);

      final file = File(tempPath);
      final fileSize = await file.length();
      final checksum = await compressionService.computeChecksum(tempPath);

      return TransferPayload(
        selectedItem: item,
        sourcePath: tempPath,
        fileName: item.displayName,
        fileSize: fileSize,
        fileType: 'txt',
        checksum: checksum,
        isFolder: false,
        fileCount: 1,
        isTempFile: true,
      );
    }

    // Handle folder compression
    if (item.type == SelectedItemType.folder) {
      final folder = Directory(item.path!);
      if (!folder.existsSync()) {
        throw FileSystemException(
          _getUserFriendlyError('file_not_found'),
          item.path,
        );
      }

      final result = await compressionService.compressFolderWithCount(
        item.path!,
      );
      _tempFilesToCleanup.add(result.zipPath);

      final zipFile = File(result.zipPath);
      final fileSize = await zipFile.length();
      final checksum = await compressionService.computeChecksum(result.zipPath);

      return TransferPayload(
        selectedItem: item,
        sourcePath: result.zipPath,
        fileName: '${item.displayName}.zip',
        fileSize: fileSize,
        fileType: 'zip',
        checksum: checksum,
        isFolder: true,
        fileCount: result.fileCount,
        isTempFile: true,
      );
    }

    // Handle regular file
    final file = File(item.path!);
    if (!file.existsSync()) {
      throw FileSystemException(
        _getUserFriendlyError('file_not_found'),
        item.path,
      );
    }

    final checksum = await compressionService.computeChecksum(item.path!);
    final fileSize = await file.length();

    return TransferPayload(
      selectedItem: item,
      sourcePath: item.path!,
      fileName: item.displayName,
      fileSize: fileSize,
      fileType: p.extension(item.path!).replaceFirst('.', ''),
      checksum: checksum,
      isFolder: false,
      fileCount: 1,
      isTempFile: false,
    );
  }

  Future<String> _createTextTempFile(SelectedItem item) async {
    final tempDir = Directory.systemTemp;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final tempPath = p.join(tempDir.path, 'flux_text_$timestamp.txt');
    final file = File(tempPath);
    await file.writeAsString(item.content ?? '');
    return tempPath;
  }

  Future<({bool accepted, String? sessionId, String? error})> _performHandshake(
    TransferPayload payload,
    Device target,
  ) async {
    final clientService = ref.read(transferClientServiceProvider);
    final deviceInfo = ref.read(deviceInfoProviderProvider);
    final localInfo = await deviceInfo.getLocalDeviceInfo();

    final request = HandshakeRequest(
      fileName: payload.fileName,
      fileSize: payload.fileSize,
      fileType: payload.fileType,
      checksum: payload.checksum,
      isFolder: payload.isFolder,
      fileCount: payload.fileCount,
      senderDeviceId: _uuid.v4(),
      senderAlias: localInfo.alias,
    );

    final response = await clientService.handshake(
      ip: target.ip,
      port: target.port,
      request: request,
      cancelToken: _cancelToken,
    );

    return (
      accepted: response.accepted,
      sessionId: response.sessionId,
      error: response.error,
    );
  }

  Future<({bool success, String? savedPath, String? error})> _performUpload(
    TransferPayload payload,
    Device target,
    String sessionId, {
    int itemIndex = 0,
    int totalItems = 1,
    List<TransferResult> previousResults = const [],
  }) async {
    final clientService = ref.read(transferClientServiceProvider);

    final response = await clientService.upload(
      ip: target.ip,
      port: target.port,
      sessionId: sessionId,
      filePath: payload.sourcePath,
      fileName: payload.fileName,
      fileSize: payload.fileSize,
      onProgress: (sent, total) {
        state = TransferState.sending(
          progress: TransferProgress(
            currentItemIndex: itemIndex,
            totalItems: totalItems,
            bytesSent: sent,
            totalBytes: total,
            phase: TransferPhase.uploading,
          ),
          results: previousResults,
          targetDeviceAlias: target.alias,
        );
      },
      cancelToken: _cancelToken,
    );

    return (
      success: response.success,
      savedPath: response.savedPath,
      error: response.error,
    );
  }

  Future<void> _recordHistory(
    SelectedItem item,
    Device target,
    TransferStatus status,
  ) async {
    debugPrint(
      '[TransferController] Recording history: '
      '${item.displayName} -> ${target.alias} (status: $status)',
    );
    try {
      final repository = ref.read(historyRepositoryProvider);
      final entry = NewTransferHistoryEntry(
        transferId: _uuid.v4(),
        fileName: item.displayName,
        fileCount: 1,
        totalSize: item.sizeEstimate,
        fileType: p.extension(item.path ?? '').replaceFirst('.', ''),
        status: status,
        direction: TransferDirection.sent,
        remoteDeviceAlias: target.alias,
      );
      await repository.addEntry(entry);
      debugPrint('[TransferController] History entry saved successfully');
    } catch (e, stack) {
      // Log error but don't fail the transfer
      debugPrint('[TransferController] Failed to save history: $e');
      debugPrint('[TransferController] Stack trace: $stack');
    }
  }

  /// Returns a user-friendly error message for the given error code.
  String _getUserFriendlyError(String errorCode) {
    switch (errorCode) {
      case 'file_not_found':
        return 'File was deleted or moved before transfer could start';
      case 'busy':
        return 'Receiver is busy with another transfer. '
            'Please try again later.';
      case 'insufficient_storage':
        return 'Receiver does not have enough storage space for this file';
      case 'rejected':
        return 'Transfer was rejected by the receiver';
      case 'network_error':
        return 'Network connection failed. '
            'Check your connection and try again.';
      case 'timeout':
        return 'Connection timed out. The receiver may be offline.';
      case 'checksum_mismatch':
        return 'File verification failed. The file may be corrupted.';
      default:
        return 'Transfer failed: $errorCode';
    }
  }

  /// Converts a handshake rejection error to a user-friendly message.
  String _getHandshakeErrorMessage(String? error) {
    if (error == null) return 'Transfer rejected';
    if (error.contains('busy')) return _getUserFriendlyError('busy');
    if (error.contains('insufficient_storage')) {
      return _getUserFriendlyError('insufficient_storage');
    }
    if (error.contains('rejected')) return _getUserFriendlyError('rejected');
    return 'Transfer rejected: $error';
  }
}
