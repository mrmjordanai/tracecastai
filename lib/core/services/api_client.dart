import 'package:dio/dio.dart';

import '../constants/app_constants.dart';

/// HTTP client wrapper with interceptors and retry logic
///
/// Used for OpenRouter API calls and other external services.
class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: Duration(seconds: AppConstants.apiTimeoutSeconds),
        receiveTimeout: Duration(seconds: AppConstants.apiTimeoutSeconds),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    // Add logging interceptor in debug mode
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ),
    );

    // Add retry interceptor
    _dio.interceptors.add(_RetryInterceptor(_dio));
  }

  /// Set authorization header
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Clear authorization header
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  /// GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Upload file
  Future<Response<T>> uploadFile<T>(
    String path, {
    required String filePath,
    required String fieldName,
    Map<String, dynamic>? data,
    ProgressCallback? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      ...?data,
      fieldName: await MultipartFile.fromFile(filePath),
    });

    return await _dio.post<T>(
      path,
      data: formData,
      onSendProgress: onSendProgress,
    );
  }
}

/// Retry interceptor for handling transient failures
class _RetryInterceptor extends Interceptor {
  final Dio _dio;
  final int _maxRetries;
  final List<int> _retryDelaysMs;

  _RetryInterceptor(
    this._dio, {
    int maxRetries = AppConstants.maxRetryAttempts,
    List<int> retryDelaysMs = AppConstants.retryDelaysMs,
  })  : _maxRetries = maxRetries,
        _retryDelaysMs = retryDelaysMs;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final retryCount = err.requestOptions.extra['retryCount'] ?? 0;

    // Only retry on network errors or 5xx server errors
    final shouldRetry = retryCount < _maxRetries &&
        (err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.receiveTimeout ||
            err.type == DioExceptionType.connectionError ||
            (err.response?.statusCode ?? 0) >= 500);

    if (shouldRetry) {
      // Wait before retrying
      final delay = _retryDelaysMs[retryCount.clamp(0, _retryDelaysMs.length - 1)];
      await Future.delayed(Duration(milliseconds: delay));

      // Increment retry count
      err.requestOptions.extra['retryCount'] = retryCount + 1;

      // Retry the request
      try {
        final response = await _dio.fetch(err.requestOptions);
        return handler.resolve(response);
      } catch (e) {
        return handler.next(err);
      }
    }

    return handler.next(err);
  }
}
