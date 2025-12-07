import 'dart:developer' as developer;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/src/features/send/data/dtos/handshake_request.dart';
import 'package:flux/src/features/send/data/dtos/handshake_response.dart';
import 'package:flux/src/features/send/data/dtos/upload_response.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transfer_client_service.g.dart';

/// Callback for upload progress updates.
typedef TransferProgressCallback = void Function(int sent, int total);

/// Service for communicating with the file transfer server.
///
/// Handles the handshake and upload phases of the transfer protocol.
class TransferClientService {
  /// Creates a [TransferClientService] with an optional [Dio] instance.
  TransferClientService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 30),
                sendTimeout: const Duration(minutes: 5),
              ),
            );

  final Dio _dio;

  /// Timeout for handshake response.
  ///
  /// The server waits up to 60 seconds for user accept/reject decision,
  /// so client must wait longer than that (65 seconds = 60 + 5 buffer).
  static const _handshakeReceiveTimeout = Duration(seconds: 65);

  /// Performs the handshake with the receiver to initiate a transfer.
  ///
  /// Sends file metadata to the receiver and waits for acceptance.
  /// Returns a [HandshakeResponse] indicating whether the transfer
  /// was accepted and providing a session ID if successful.
  ///
  /// Note: This method has a longer timeout (65 seconds) because the server
  /// waits for user confirmation before responding.
  Future<HandshakeResponse> handshake({
    required String ip,
    required int port,
    required HandshakeRequest request,
    CancelToken? cancelToken,
  }) async {
    final url = 'http://$ip:$port/api/v1/info';

    developer.log(
      'Handshake: connecting to $url',
      name: 'TransferClientService',
    );

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        url,
        data: request.toJson(),
        options: Options(
          headers: {'Content-Type': 'application/json'},
          // Override receive timeout for handshake since server waits
          // up to 60 seconds for user accept/reject decision
          receiveTimeout: _handshakeReceiveTimeout,
        ),
        cancelToken: cancelToken,
      );

      developer.log(
        'Handshake: response ${response.statusCode} - ${response.data}',
        name: 'TransferClientService',
      );

      return HandshakeResponse.fromJson(response.data!);
    } on DioException catch (e) {
      developer.log(
        'Handshake failed: ${e.type} - ${e.message} - ${e.error}',
        name: 'TransferClientService',
        error: e,
      );
      rethrow;
    }
  }

  /// Uploads a file to the receiver.
  ///
  /// Streams the file content to the receiver with progress updates.
  /// The [sessionId] must be obtained from a successful handshake.
  Future<UploadResponse> upload({
    required String ip,
    required int port,
    required String sessionId,
    required String filePath,
    required int fileSize,
    TransferProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    final url = 'http://$ip:$port/api/v1/upload';
    final file = File(filePath);

    final response = await _dio.post<Map<String, dynamic>>(
      url,
      data: file.openRead(),
      options: Options(
        headers: {
          'Content-Type': 'application/octet-stream',
          'X-Transfer-Session': sessionId,
          'Content-Length': fileSize.toString(),
        },
      ),
      onSendProgress: onProgress,
      cancelToken: cancelToken,
    );

    return UploadResponse.fromJson(response.data!);
  }
}

/// Provider for [TransferClientService].
@riverpod
TransferClientService transferClientService(Ref ref) {
  return TransferClientService();
}
