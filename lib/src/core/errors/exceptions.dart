/// Base exception class for all custom exceptions in the app
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AppException({
    required this.message,
    this.code,
    this.details,
  });

  @override
  String toString() => 'AppException: $message';
}

/// Exception thrown when server returns an error
class ServerException extends AppException {
  const ServerException({
    required super.message,
    super.code,
    super.details,
  });

  @override
  String toString() => 'ServerException: $message';
}

/// Exception thrown when there's a network connectivity issue
class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.code,
    super.details,
  });

  @override
  String toString() => 'NetworkException: $message';
}

/// Exception thrown when authentication fails
class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.code,
    super.details,
  });

  @override
  String toString() => 'AuthException: $message';
}

/// Exception thrown when user doesn't have permission
class PermissionException extends AppException {
  const PermissionException({
    required super.message,
    super.code,
    super.details,
  });

  @override
  String toString() => 'PermissionException: $message';
}

/// Exception thrown when data validation fails
class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.code,
    super.details,
  });

  @override
  String toString() => 'ValidationException: $message';
}

/// Exception thrown when cache operations fail
class CacheException extends AppException {
  const CacheException({
    required super.message,
    super.code,
    super.details,
  });

  @override
  String toString() => 'CacheException: $message';
}

/// Exception thrown when storage operations fail
class StorageException extends AppException {
  const StorageException({
    required super.message,
    super.code,
    super.details,
  });

  @override
  String toString() => 'StorageException: $message';
}

/// Exception thrown when parsing data fails
class ParseException extends AppException {
  const ParseException({
    required super.message,
    super.code,
    super.details,
  });

  @override
  String toString() => 'ParseException: $message';
}

/// Exception thrown when timeout occurs
class TimeoutException extends AppException {
  const TimeoutException({
    required super.message,
    super.code,
    super.details,
  });

  @override
  String toString() => 'TimeoutException: $message';
}
