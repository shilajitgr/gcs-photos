import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'auth_service.dart';

/// HTTP client for the CGS Photos Cloud Run API.
class ApiService {
  final Dio _dio;
  final AuthService _authService;

  ApiService({
    required AuthService authService,
    Dio? dio,
  })  : _authService = authService,
        _dio = dio ?? Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl)) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _authService.getIdToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  /// Fetch paginated photo metadata.
  Future<Response<dynamic>> getPhotos({
    int page = 1,
    int limit = AppConfig.syncPageSize,
  }) {
    return _dio.get(
      '/api/v1/photos',
      queryParameters: {'page': page, 'limit': limit},
    );
  }

  /// Fetch a single photo's metadata by UID.
  Future<Response<dynamic>> getPhoto(String uid) {
    return _dio.get('/api/v1/photos/$uid');
  }

  /// Request a signed upload URL from the API.
  Future<Response<dynamic>> getUploadUrl({
    required String fileName,
    required String contentType,
    required String bucket,
  }) {
    return _dio.post(
      '/api/v1/photos/upload-url',
      data: {
        'fileName': fileName,
        'contentType': contentType,
        'bucket': bucket,
      },
    );
  }

  /// Paginated sync endpoint.
  ///
  /// [mode] is either `full` or `incremental`.
  /// [cursor] is the opaque resume cursor from the previous page.
  Future<Response<dynamic>> syncPhotos({
    required String mode,
    String? cursor,
    int limit = AppConfig.syncPageSize,
  }) {
    return _dio.get(
      '/api/v1/photos/sync',
      queryParameters: {
        'mode': mode,
        if (cursor != null) 'cursor': cursor,
        'limit': limit,
      },
    );
  }
}
