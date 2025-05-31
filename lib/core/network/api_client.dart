import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../services/security_service.dart';
import '../utils/logger.dart';
import '../errors/exceptions.dart';
import 'network_info.dart';

/// HTTP client for API requests with security and logging
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  late final Dio _dio;
  final SecurityService _securityService = SecurityService();
  final NetworkInfo _networkInfo = NetworkInfoImpl();
  final AppLogger _logger = AppLogger();

  /// Initialize the API client
  void init({
    required String baseUrl,
    Duration connectTimeout = const Duration(seconds: 30),
    Duration receiveTimeout = const Duration(seconds: 30),
    Duration sendTimeout = const Duration(seconds: 30),
  }) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      sendTimeout: sendTimeout,
      headers: _securityService.getSecurityHeaders(),
    ));

    _setupInterceptors();
  }

  /// Setup interceptors for logging, authentication, and error handling
  void _setupInterceptors() {
    // Request interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Check network connectivity
        final isConnected = await _networkInfo.isConnected;
        if (!isConnected) {
          handler.reject(DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
            message: 'No internet connection',
          ));
          return;
        }

        // Add authentication token
        final token = await _securityService.getAccessToken();
        if (token != null && _securityService.isTokenValid(token)) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        // Log request
        _logger.logApiRequest(
          options.method,
          '${options.baseUrl}${options.path}',
          options.data,
        );

        handler.next(options);
      },
      onResponse: (response, handler) {
        // Log response
        _logger.logApiResponse(
          response.requestOptions.method,
          '${response.requestOptions.baseUrl}${response.requestOptions.path}',
          response.statusCode ?? 0,
          response.data,
        );

        handler.next(response);
      },
      onError: (error, handler) async {
        // Handle token refresh for 401 errors
        if (error.response?.statusCode == 401) {
          final refreshed = await _refreshToken();
          if (refreshed) {
            // Retry the original request
            final options = error.requestOptions;
            final token = await _securityService.getAccessToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }

            try {
              final response = await _dio.fetch(options);
              handler.resolve(response);
              return;
            } catch (e) {
              // If retry fails, continue with original error
            }
          }
        }

        // Log error
        _logger.error(
          'API Error: ${error.message}',
          error,
        );

        handler.next(error);
      },
    ));

    // Add logging interceptor in debug mode
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: true,
        responseHeader: false,
        error: true,
        logPrint: (object) => _logger.debug(object.toString()),
      ));
    }
  }

  /// Refresh authentication token
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _securityService.getRefreshToken();
      if (refreshToken == null || !_securityService.isTokenValid(refreshToken)) {
        return false;
      }

      // Make refresh token request
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(
          headers: {'Authorization': 'Bearer $refreshToken'},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final newAccessToken = data['access_token'] as String?;
        final newRefreshToken = data['refresh_token'] as String?;

        if (newAccessToken != null && newRefreshToken != null) {
          await _securityService.storeTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
          );
          return true;
        }
      }

      return false;
    } catch (e) {
      _logger.error('Token refresh failed', e);
      return false;
    }
  }

  /// GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Upload file
  Future<Response<T>> uploadFile<T>(
    String path,
    String filePath, {
    String fieldName = 'file',
    Map<String, dynamic>? data,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final formData = FormData.fromMap({
        ...?data,
        fieldName: await MultipartFile.fromFile(filePath),
      });

      return await _dio.post<T>(
        path,
        data: formData,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Download file
  Future<Response> downloadFile(
    String path,
    String savePath, {
    Map<String, dynamic>? queryParameters,
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.download(
        path,
        savePath,
        queryParameters: queryParameters,
        onReceiveProgress: onReceiveProgress,
        cancelToken: cancelToken,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle and convert errors to app exceptions
  AppException _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return TimeoutException(
            message: 'Request timeout. Please try again.',
            details: error,
          );
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          switch (statusCode) {
            case 400:
              return ValidationException(
                message: 'Bad request. Please check your input.',
                code: statusCode.toString(),
                details: error,
              );
            case 401:
              return AuthException(
                message: 'Unauthorized. Please log in again.',
                code: statusCode.toString(),
                details: error,
              );
            case 403:
              return PermissionException(
                message: 'Access forbidden.',
                code: statusCode.toString(),
                details: error,
              );
            case 404:
              return ServerException(
                message: 'Resource not found.',
                code: statusCode.toString(),
                details: error,
              );
            case 500:
              return ServerException(
                message: 'Server error. Please try again later.',
                code: statusCode.toString(),
                details: error,
              );
            default:
              return ServerException(
                message: 'HTTP error: $statusCode',
                code: statusCode.toString(),
                details: error,
              );
          }
        case DioExceptionType.cancel:
          return NetworkException(
            message: 'Request was cancelled.',
            details: error,
          );
        case DioExceptionType.connectionError:
          return NetworkException(
            message: 'Connection error. Please check your internet connection.',
            details: error,
          );
        case DioExceptionType.unknown:
        default:
          return NetworkException(
            message: 'Network error occurred.',
            details: error,
          );
      }
    }

    return ServerException(
      message: 'An unexpected error occurred: ${error.toString()}',
      details: error,
    );
  }
}
