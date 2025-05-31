import 'package:equatable/equatable.dart';

/// Base failure class for all failures in the app
abstract class Failure extends Equatable {
  final String message;
  final String? code;
  final dynamic details;

  const Failure({
    required this.message,
    this.code,
    this.details,
  });

  @override
  List<Object?> get props => [message, code, details];

  @override
  String toString() => 'Failure: $message';
}

/// Failure when server returns an error
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.code,
    super.details,
  });

  @override
  String toString() => 'ServerFailure: $message';
}

/// Failure when there's a network connectivity issue
class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.code,
    super.details,
  });

  @override
  String toString() => 'NetworkFailure: $message';
}

/// Failure when authentication fails
class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.code,
    super.details,
  });

  @override
  String toString() => 'AuthFailure: $message';
}

/// Failure when user doesn't have permission
class PermissionFailure extends Failure {
  const PermissionFailure({
    required super.message,
    super.code,
    super.details,
  });

  @override
  String toString() => 'PermissionFailure: $message';
}

/// Failure when data validation fails
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.code,
    super.details,
  });

  @override
  String toString() => 'ValidationFailure: $message';
}

/// Failure when cache operations fail
class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.code,
    super.details,
  });

  @override
  String toString() => 'CacheFailure: $message';
}

/// Failure when storage operations fail
class StorageFailure extends Failure {
  const StorageFailure({
    required super.message,
    super.code,
    super.details,
  });

  @override
  String toString() => 'StorageFailure: $message';
}

/// Failure when parsing data fails
class ParseFailure extends Failure {
  const ParseFailure({
    required super.message,
    super.code,
    super.details,
  });

  @override
  String toString() => 'ParseFailure: $message';
}

/// Failure when timeout occurs
class TimeoutFailure extends Failure {
  const TimeoutFailure({
    required super.message,
    super.code,
    super.details,
  });

  @override
  String toString() => 'TimeoutFailure: $message';
}

/// Failure when unexpected error occurs
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({
    required super.message,
    super.code,
    super.details,
  });

  @override
  String toString() => 'UnexpectedFailure: $message';
}
