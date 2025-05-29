import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum ErrorType {
  network,
  authentication,
  validation,
  notFound,
  serverError,
  unknown,
}

class AppError {
  final String message;
  final ErrorType type;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppError({
    required this.message,
    required this.type,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  factory AppError.network({
    String? message,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return AppError(
      message: message ?? 'Network connection failed. Please check your internet connection.',
      type: ErrorType.network,
      code: code,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  factory AppError.authentication({
    String? message,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return AppError(
      message: message ?? 'Authentication failed. Please sign in again.',
      type: ErrorType.authentication,
      code: code,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  factory AppError.validation({
    String? message,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return AppError(
      message: message ?? 'Invalid input. Please check your data and try again.',
      type: ErrorType.validation,
      code: code,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  factory AppError.notFound({
    String? message,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return AppError(
      message: message ?? 'The requested resource was not found.',
      type: ErrorType.notFound,
      code: code,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  factory AppError.serverError({
    String? message,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return AppError(
      message: message ?? 'Server error occurred. Please try again later.',
      type: ErrorType.serverError,
      code: code,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  factory AppError.unknown({
    String? message,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return AppError(
      message: message ?? 'An unexpected error occurred. Please try again.',
      type: ErrorType.unknown,
      code: code,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  @override
  String toString() {
    return 'AppError(message: $message, type: $type, code: $code)';
  }
}

class ErrorHandler {
  static AppError handleError(dynamic error, [StackTrace? stackTrace]) {
    if (error is AppError) {
      return error;
    }

    // Log error in debug mode
    if (kDebugMode) {
      debugPrint('Error: $error');
      if (stackTrace != null) {
        debugPrint('StackTrace: $stackTrace');
      }
    }

    // Handle different types of errors
    if (error is FormatException) {
      return AppError.validation(
        message: 'Invalid data format: ${error.message}',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (error is ArgumentError) {
      return AppError.validation(
        message: 'Invalid argument: ${error.message}',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (error is StateError) {
      return AppError.unknown(
        message: 'Application state error: ${error.message}',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Default to unknown error
    return AppError.unknown(
      message: error.toString(),
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  static void showErrorSnackBar(BuildContext context, AppError error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getErrorIcon(error.type),
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                error.message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: _getErrorColor(error.type),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  static void showErrorDialog(BuildContext context, AppError error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getErrorIcon(error.type),
              color: _getErrorColor(error.type),
            ),
            const SizedBox(width: 8),
            Text(_getErrorTitle(error.type)),
          ],
        ),
        content: Text(error.message),
        actions: [
          if (kDebugMode && error.originalError != null)
            TextButton(
              onPressed: () {
                _showDebugInfo(context, error);
              },
              child: const Text('Debug Info'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static IconData _getErrorIcon(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.authentication:
        return Icons.lock;
      case ErrorType.validation:
        return Icons.warning;
      case ErrorType.notFound:
        return Icons.search_off;
      case ErrorType.serverError:
        return Icons.server_error;
      case ErrorType.unknown:
        return Icons.error;
    }
  }

  static Color _getErrorColor(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Colors.orange;
      case ErrorType.authentication:
        return Colors.red;
      case ErrorType.validation:
        return Colors.amber;
      case ErrorType.notFound:
        return Colors.blue;
      case ErrorType.serverError:
        return Colors.red;
      case ErrorType.unknown:
        return Colors.grey;
    }
  }

  static String _getErrorTitle(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return 'Network Error';
      case ErrorType.authentication:
        return 'Authentication Error';
      case ErrorType.validation:
        return 'Validation Error';
      case ErrorType.notFound:
        return 'Not Found';
      case ErrorType.serverError:
        return 'Server Error';
      case ErrorType.unknown:
        return 'Error';
    }
  }

  static void _showDebugInfo(BuildContext context, AppError error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Type: ${error.type}'),
              if (error.code != null) Text('Code: ${error.code}'),
              const SizedBox(height: 8),
              Text('Message: ${error.message}'),
              const SizedBox(height: 8),
              if (error.originalError != null) ...[
                Text('Original Error: ${error.originalError}'),
                const SizedBox(height: 8),
              ],
              if (error.stackTrace != null) ...[
                const Text('Stack Trace:'),
                const SizedBox(height: 4),
                Text(
                  error.stackTrace.toString(),
                  style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// Extension for easy error handling in widgets
extension ErrorHandlerExtension on BuildContext {
  void showError(dynamic error, [StackTrace? stackTrace]) {
    final appError = ErrorHandler.handleError(error, stackTrace);
    ErrorHandler.showErrorSnackBar(this, appError);
  }

  void showErrorDialog(dynamic error, [StackTrace? stackTrace]) {
    final appError = ErrorHandler.handleError(error, stackTrace);
    ErrorHandler.showErrorDialog(this, appError);
  }
}
