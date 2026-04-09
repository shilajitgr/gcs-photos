import 'dart:io';

import 'package:dio/dio.dart';

import 'api_service.dart';

/// Handles photo upload via signed GCS URLs.
class UploadService {
  final ApiService _apiService;
  final Dio _uploadDio;

  UploadService({
    required ApiService apiService,
    Dio? uploadDio,
  })  : _apiService = apiService,
        _uploadDio = uploadDio ?? Dio();

  /// Upload a file to GCS using a signed URL obtained from the API.
  ///
  /// Returns the GCS object path on success.
  Future<String> uploadPhoto({
    required File file,
    required String fileName,
    required String contentType,
    required String bucket,
    void Function(int sent, int total)? onProgress,
  }) async {
    // 1. Get a signed upload URL from the Cloud Run API.
    final urlResponse = await _apiService.getUploadUrl(
      fileName: fileName,
      contentType: contentType,
      bucket: bucket,
    );

    final data = urlResponse.data as Map<String, dynamic>;
    final signedUrl = data['uploadURL'] as String;
    final gcsPath = data['objectPath'] as String;

    // 2. Upload the file directly to GCS via the signed URL.
    final fileLength = await file.length();
    await _uploadDio.put(
      signedUrl,
      data: file.openRead(),
      options: Options(
        headers: {
          Headers.contentTypeHeader: contentType,
          Headers.contentLengthHeader: fileLength,
        },
      ),
      onSendProgress: onProgress,
    );

    return gcsPath;
  }
}
