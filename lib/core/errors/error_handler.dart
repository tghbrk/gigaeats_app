import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'exceptions.dart' as app_exceptions;
import 'failures.dart';
import '../utils/logger.dart';

/// Centralized error handler for the application
class ErrorHandler {
  static final AppLogger _logger = AppLogger();

  /// Converts exceptions to failures
  static Failure handleException(Object exception, [StackTrace? stackTrace]) {
    _logger.error('Exception occurred: $exception', exception, stackTrace);

    if (exception is app_exceptions.AppException) {
      return _handleAppException(exception);
    } else if (exception is firebase_auth.FirebaseAuthException) {
      return _handleFirebaseAuthException(exception);
    } else if (exception is PostgrestException) {
      return _handleSupabaseException(exception);
    } else if (exception is DioException) {
      return _handleDioException(exception);
    } else {
      return UnexpectedFailure(
        message: 'An unexpected error occurred: ${exception.toString()}',
        details: exception,
      );
    }
  }

  /// Handles app-specific exceptions
  static Failure _handleAppException(app_exceptions.AppException exception) {
    if (exception is app_exceptions.ServerException) {
      return ServerFailure(
        message: exception.message,
        code: exception.code,
        details: exception.details,
      );
    } else if (exception is app_exceptions.NetworkException) {
      return NetworkFailure(
        message: exception.message,
        code: exception.code,
        details: exception.details,
      );
    } else if (exception is app_exceptions.AuthException) {
      return AuthFailure(
        message: exception.message,
        code: exception.code,
        details: exception.details,
      );
    } else if (exception is app_exceptions.PermissionException) {
      return PermissionFailure(
        message: exception.message,
        code: exception.code,
        details: exception.details,
      );
    } else if (exception is app_exceptions.ValidationException) {
      return ValidationFailure(
        message: exception.message,
        code: exception.code,
        details: exception.details,
      );
    } else if (exception is app_exceptions.CacheException) {
      return CacheFailure(
        message: exception.message,
        code: exception.code,
        details: exception.details,
      );
    } else if (exception is app_exceptions.StorageException) {
      return StorageFailure(
        message: exception.message,
        code: exception.code,
        details: exception.details,
      );
    } else if (exception is app_exceptions.ParseException) {
      return ParseFailure(
        message: exception.message,
        code: exception.code,
        details: exception.details,
      );
    } else if (exception is app_exceptions.TimeoutException) {
      return TimeoutFailure(
        message: exception.message,
        code: exception.code,
        details: exception.details,
      );
    } else {
      return UnexpectedFailure(
        message: exception.message,
        code: exception.code,
        details: exception.details,
      );
    }
  }

  /// Handles Firebase Auth exceptions
  static Failure _handleFirebaseAuthException(firebase_auth.FirebaseAuthException exception) {
    String message;
    switch (exception.code) {
      case 'user-not-found':
        message = 'No user found with this email address.';
        break;
      case 'wrong-password':
        message = 'Incorrect password. Please try again.';
        break;
      case 'email-already-in-use':
        message = 'An account already exists with this email address.';
        break;
      case 'weak-password':
        message = 'Password is too weak. Please choose a stronger password.';
        break;
      case 'invalid-email':
        message = 'Invalid email address format.';
        break;
      case 'user-disabled':
        message = 'This account has been disabled.';
        break;
      case 'too-many-requests':
        message = 'Too many failed attempts. Please try again later.';
        break;
      case 'network-request-failed':
        message = 'Network error. Please check your connection.';
        break;
      default:
        message = exception.message ?? 'Authentication failed.';
    }

    return AuthFailure(
      message: message,
      code: exception.code,
      details: exception,
    );
  }

  /// Handles Supabase exceptions
  static Failure _handleSupabaseException(PostgrestException exception) {
    String message;
    switch (exception.code) {
      case '23505': // Unique violation
        message = 'This record already exists.';
        break;
      case '23503': // Foreign key violation
        message = 'Referenced record does not exist.';
        break;
      case '42501': // Insufficient privilege
        message = 'You do not have permission to perform this action.';
        break;
      case 'PGRST116': // No rows found
        message = 'No data found.';
        break;
      default:
        message = exception.message;
    }

    return ServerFailure(
      message: message,
      code: exception.code,
      details: exception,
    );
  }

  /// Handles Dio HTTP exceptions
  static Failure _handleDioException(DioException exception) {
    String message;
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Connection timeout. Please try again.';
        break;
      case DioExceptionType.badResponse:
        final statusCode = exception.response?.statusCode;
        switch (statusCode) {
          case 400:
            message = 'Bad request. Please check your input.';
            break;
          case 401:
            message = 'Unauthorized. Please log in again.';
            break;
          case 403:
            message = 'Access forbidden.';
            break;
          case 404:
            message = 'Resource not found.';
            break;
          case 500:
            message = 'Server error. Please try again later.';
            break;
          default:
            message = 'HTTP error: $statusCode';
        }
        break;
      case DioExceptionType.cancel:
        message = 'Request was cancelled.';
        break;
      case DioExceptionType.connectionError:
        message = 'Connection error. Please check your internet connection.';
        break;
      case DioExceptionType.unknown:
      default:
        message = 'Network error occurred.';
    }

    return NetworkFailure(
      message: message,
      code: exception.response?.statusCode?.toString(),
      details: exception,
    );
  }

  /// Gets user-friendly error message from failure
  static String getErrorMessage(Failure failure) {
    return failure.message;
  }

  /// Logs error for debugging purposes
  static void logError(Object error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      _logger.error('Error logged: $error', error, stackTrace);
    }
  }
}
