import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

import '../../../../core/utils/logger.dart';

/// Enhanced error handling service with circuit breaker pattern and retry logic
class EnhancedErrorHandlingService {
  final AppLogger _logger = AppLogger();
  final Map<String, CircuitBreaker> _circuitBreakers = {};


  /// Execute operation with comprehensive error handling
  Future<T> executeWithErrorHandling<T>({
    required String operationName,
    required Future<T> Function() operation,
    RetryPolicy? retryPolicy,
    CircuitBreakerConfig? circuitBreakerConfig,
    T? fallbackValue,
    Future<T> Function()? fallbackOperation,
  }) async {
    final circuitBreaker = _getOrCreateCircuitBreaker(
      operationName,
      circuitBreakerConfig ?? CircuitBreakerConfig.defaultConfig(),
    );

    final retry = retryPolicy ?? RetryPolicy.defaultPolicy();

    return await _executeWithCircuitBreaker(
      circuitBreaker: circuitBreaker,
      operation: () => _executeWithRetry(
        operationName: operationName,
        operation: operation,
        retryPolicy: retry,
      ),
      fallbackValue: fallbackValue,
      fallbackOperation: fallbackOperation,
    );
  }

  /// Execute operation with circuit breaker protection
  Future<T> _executeWithCircuitBreaker<T>({
    required CircuitBreaker circuitBreaker,
    required Future<T> Function() operation,
    T? fallbackValue,
    Future<T> Function()? fallbackOperation,
  }) async {
    if (circuitBreaker.state == CircuitBreakerState.open) {
      debugPrint('🔴 [ERROR-HANDLING] Circuit breaker is OPEN for ${circuitBreaker.name}');
      
      if (fallbackOperation != null) {
        try {
          return await fallbackOperation();
        } catch (e) {
          _logger.error('Fallback operation failed for ${circuitBreaker.name}', e);
          if (fallbackValue != null) return fallbackValue;
          rethrow;
        }
      }
      
      if (fallbackValue != null) return fallbackValue;
      throw CircuitBreakerOpenException('Circuit breaker is open for ${circuitBreaker.name}');
    }

    try {
      final result = await operation();
      circuitBreaker.recordSuccess();
      return result;
    } catch (e) {
      circuitBreaker.recordFailure();
      
      if (circuitBreaker.state == CircuitBreakerState.open) {
        debugPrint('🔴 [ERROR-HANDLING] Circuit breaker opened for ${circuitBreaker.name}');
        
        if (fallbackOperation != null) {
          try {
            return await fallbackOperation();
          } catch (fallbackError) {
            _logger.error('Fallback operation failed for ${circuitBreaker.name}', fallbackError);
            if (fallbackValue != null) return fallbackValue;
            rethrow;
          }
        }
        
        if (fallbackValue != null) return fallbackValue;
      }
      
      rethrow;
    }
  }

  /// Execute operation with retry logic
  Future<T> _executeWithRetry<T>({
    required String operationName,
    required Future<T> Function() operation,
    required RetryPolicy retryPolicy,
  }) async {
    int attempt = 0;
    Exception? lastException;

    while (attempt < retryPolicy.maxAttempts) {
      try {
        final result = await operation();
        if (attempt > 0) {
          debugPrint('✅ [ERROR-HANDLING] Operation $operationName succeeded on attempt ${attempt + 1}');
        }
        return result;
      } catch (e) {
        attempt++;
        lastException = e is Exception ? e : Exception(e.toString());
        
        if (!retryPolicy.shouldRetry(e)) {
          debugPrint('❌ [ERROR-HANDLING] Non-retryable error for $operationName: $e');
          throw lastException;
        }
        
        if (attempt >= retryPolicy.maxAttempts) {
          debugPrint('❌ [ERROR-HANDLING] Max retry attempts reached for $operationName');
          break;
        }
        
        final delay = retryPolicy.getDelay(attempt);
        debugPrint('🔄 [ERROR-HANDLING] Retrying $operationName (attempt $attempt) after ${delay.inMilliseconds}ms delay');
        
        await Future.delayed(delay);
      }
    }

    throw lastException!;
  }

  /// Get or create circuit breaker for operation
  CircuitBreaker _getOrCreateCircuitBreaker(String name, CircuitBreakerConfig config) {
    return _circuitBreakers.putIfAbsent(
      name,
      () => CircuitBreaker(name: name, config: config),
    );
  }

  /// Get circuit breaker statistics
  Map<String, CircuitBreakerStats> getCircuitBreakerStats() {
    return _circuitBreakers.map(
      (name, breaker) => MapEntry(name, breaker.getStats()),
    );
  }

  /// Reset circuit breaker
  void resetCircuitBreaker(String name) {
    _circuitBreakers[name]?.reset();
  }

  /// Reset all circuit breakers
  void resetAllCircuitBreakers() {
    for (final breaker in _circuitBreakers.values) {
      breaker.reset();
    }
  }

  /// Handle specific error types with appropriate strategies
  Future<T> handleSpecificError<T>({
    required Future<T> Function() operation,
    required String context,
    T? fallbackValue,
  }) async {
    try {
      return await operation();
    } on TimeoutException catch (e) {
      _logger.error('Timeout error in $context', e);
      return _handleTimeoutError(context, fallbackValue);
    } on FormatException catch (e) {
      _logger.error('Format error in $context', e);
      return _handleFormatError(context, fallbackValue);
    } on StateError catch (e) {
      _logger.error('State error in $context', e);
      return _handleStateError(context, fallbackValue);
    } catch (e) {
      _logger.error('Unexpected error in $context', e);
      return _handleUnexpectedError(context, e, fallbackValue);
    }
  }

  T _handleTimeoutError<T>(String context, T? fallbackValue) {
    if (fallbackValue != null) return fallbackValue;
    throw EnhancedErrorHandlingException(
      'Operation timed out in $context',
      ErrorType.timeout,
      isRetryable: true,
    );
  }

  T _handleFormatError<T>(String context, T? fallbackValue) {
    if (fallbackValue != null) return fallbackValue;
    throw EnhancedErrorHandlingException(
      'Data format error in $context',
      ErrorType.format,
      isRetryable: false,
    );
  }

  T _handleStateError<T>(String context, T? fallbackValue) {
    if (fallbackValue != null) return fallbackValue;
    throw EnhancedErrorHandlingException(
      'Invalid state error in $context',
      ErrorType.state,
      isRetryable: false,
    );
  }

  T _handleUnexpectedError<T>(String context, dynamic error, T? fallbackValue) {
    if (fallbackValue != null) return fallbackValue;
    throw EnhancedErrorHandlingException(
      'Unexpected error in $context: $error',
      ErrorType.unknown,
      isRetryable: true,
    );
  }
}

/// Circuit breaker implementation
class CircuitBreaker {
  final String name;
  final CircuitBreakerConfig config;
  
  CircuitBreakerState _state = CircuitBreakerState.closed;
  int _failureCount = 0;
  int _successCount = 0;
  DateTime? _lastFailureTime;
  DateTime? _nextAttemptTime;

  CircuitBreaker({required this.name, required this.config});

  CircuitBreakerState get state {
    if (_state == CircuitBreakerState.open && _canAttemptReset()) {
      _state = CircuitBreakerState.halfOpen;
      debugPrint('🟡 [CIRCUIT-BREAKER] $name transitioned to HALF-OPEN');
    }
    return _state;
  }

  void recordSuccess() {
    _successCount++;
    if (_state == CircuitBreakerState.halfOpen) {
      if (_successCount >= config.successThreshold) {
        _reset();
        debugPrint('🟢 [CIRCUIT-BREAKER] $name transitioned to CLOSED');
      }
    }
  }

  void recordFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();
    
    if (_state == CircuitBreakerState.closed && _failureCount >= config.failureThreshold) {
      _open();
    } else if (_state == CircuitBreakerState.halfOpen) {
      _open();
    }
  }

  void _open() {
    _state = CircuitBreakerState.open;
    _nextAttemptTime = DateTime.now().add(config.timeout);
    debugPrint('🔴 [CIRCUIT-BREAKER] $name opened (failures: $_failureCount)');
  }

  void _reset() {
    _state = CircuitBreakerState.closed;
    _failureCount = 0;
    _successCount = 0;
    _lastFailureTime = null;
    _nextAttemptTime = null;
  }

  void reset() {
    _reset();
    debugPrint('🔄 [CIRCUIT-BREAKER] $name manually reset');
  }

  bool _canAttemptReset() {
    return _nextAttemptTime != null && DateTime.now().isAfter(_nextAttemptTime!);
  }

  CircuitBreakerStats getStats() {
    return CircuitBreakerStats(
      name: name,
      state: _state,
      failureCount: _failureCount,
      successCount: _successCount,
      lastFailureTime: _lastFailureTime,
      nextAttemptTime: _nextAttemptTime,
    );
  }
}

/// Circuit breaker configuration
class CircuitBreakerConfig {
  final int failureThreshold;
  final int successThreshold;
  final Duration timeout;

  const CircuitBreakerConfig({
    required this.failureThreshold,
    required this.successThreshold,
    required this.timeout,
  });

  factory CircuitBreakerConfig.defaultConfig() {
    return const CircuitBreakerConfig(
      failureThreshold: 5,
      successThreshold: 3,
      timeout: Duration(minutes: 1),
    );
  }

  factory CircuitBreakerConfig.aggressive() {
    return const CircuitBreakerConfig(
      failureThreshold: 3,
      successThreshold: 2,
      timeout: Duration(seconds: 30),
    );
  }

  factory CircuitBreakerConfig.lenient() {
    return const CircuitBreakerConfig(
      failureThreshold: 10,
      successThreshold: 5,
      timeout: Duration(minutes: 5),
    );
  }
}

/// Retry policy configuration
class RetryPolicy {
  final int maxAttempts;
  final Duration baseDelay;
  final Duration maxDelay;
  final double backoffMultiplier;
  final bool Function(dynamic error) shouldRetryFunction;

  const RetryPolicy({
    required this.maxAttempts,
    required this.baseDelay,
    required this.maxDelay,
    required this.backoffMultiplier,
    required this.shouldRetryFunction,
  });

  factory RetryPolicy.defaultPolicy() {
    return RetryPolicy(
      maxAttempts: 3,
      baseDelay: const Duration(milliseconds: 500),
      maxDelay: const Duration(seconds: 10),
      backoffMultiplier: 2.0,
      shouldRetryFunction: (error) => _isRetryableError(error),
    );
  }

  factory RetryPolicy.aggressive() {
    return RetryPolicy(
      maxAttempts: 5,
      baseDelay: const Duration(milliseconds: 200),
      maxDelay: const Duration(seconds: 5),
      backoffMultiplier: 1.5,
      shouldRetryFunction: (error) => _isRetryableError(error),
    );
  }

  factory RetryPolicy.conservative() {
    return RetryPolicy(
      maxAttempts: 2,
      baseDelay: const Duration(seconds: 1),
      maxDelay: const Duration(seconds: 30),
      backoffMultiplier: 3.0,
      shouldRetryFunction: (error) => _isRetryableError(error),
    );
  }

  bool shouldRetry(dynamic error) => shouldRetryFunction(error);

  Duration getDelay(int attempt) {
    final delay = baseDelay * pow(backoffMultiplier, attempt - 1);
    return Duration(
      milliseconds: min(delay.inMilliseconds, maxDelay.inMilliseconds),
    );
  }

  static bool _isRetryableError(dynamic error) {
    if (error is TimeoutException) return true;
    if (error is SocketException) return true;
    if (error is HttpException) return true;
    if (error is EnhancedErrorHandlingException) return error.isRetryable;
    
    // Check error message for common retryable patterns
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('temporary')) {
      return true;
    }
    
    return false;
  }
}

/// Circuit breaker states
enum CircuitBreakerState { closed, open, halfOpen }

/// Error types for classification
enum ErrorType { network, timeout, format, state, authentication, authorization, unknown }

/// Circuit breaker statistics
class CircuitBreakerStats {
  final String name;
  final CircuitBreakerState state;
  final int failureCount;
  final int successCount;
  final DateTime? lastFailureTime;
  final DateTime? nextAttemptTime;

  const CircuitBreakerStats({
    required this.name,
    required this.state,
    required this.failureCount,
    required this.successCount,
    this.lastFailureTime,
    this.nextAttemptTime,
  });

  @override
  String toString() {
    return 'CircuitBreakerStats(name: $name, state: $state, failures: $failureCount, successes: $successCount)';
  }
}

/// Enhanced error handling exception
class EnhancedErrorHandlingException implements Exception {
  final String message;
  final ErrorType type;
  final bool isRetryable;
  final dynamic originalError;

  const EnhancedErrorHandlingException(
    this.message,
    this.type, {
    this.isRetryable = false,
    this.originalError,
  });

  @override
  String toString() => 'EnhancedErrorHandlingException: $message (type: $type, retryable: $isRetryable)';
}

/// Circuit breaker open exception
class CircuitBreakerOpenException implements Exception {
  final String message;

  const CircuitBreakerOpenException(this.message);

  @override
  String toString() => 'CircuitBreakerOpenException: $message';
}

/// Common exceptions for import
class SocketException implements Exception {
  final String message;
  const SocketException(this.message);
  @override
  String toString() => 'SocketException: $message';
}

class HttpException implements Exception {
  final String message;
  const HttpException(this.message);
  @override
  String toString() => 'HttpException: $message';
}
