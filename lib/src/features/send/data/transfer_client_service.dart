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
  TransferClientService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  /// Performs the handshake with the receiver to initiate a transfer.
  ///
  /// Sends file metadata to the receiver and waits for acceptance.
  /// Returns a [HandshakeResponse] indicating whether the transfer
  /// was accepted and providing a session ID if successful.
  Future<HandshakeResponse> handshake({
    required String ip,
    required int port,
    required HandshakeRequest request,
    CancelToken? cancelToken,
  }) async {
    final url = 'http://$ip:$port/api/v1/info';

    final response = await _dio.post<Map<String, dynamic>>(
      url,
      data: request.toJson(),
      options: Options(headers: {'Content-Type': 'application/json'}),
      cancelToken: cancelToken,
    );

    return HandshakeResponse.fromJson(response.data!);
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
