import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Custom logger for the application
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  Logger? _logger;

  /// Initialize the logger
  void init() {
    _logger = Logger(
      filter: _AppLogFilter(),
      printer: _AppLogPrinter(),
      output: _AppLogOutput(),
    );
  }

  /// Get logger instance, initialize if needed
  Logger get logger {
    if (_logger == null) {
      init();
    }
    return _logger!;
  }

  /// Log debug message
  void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log info message
  void info(String message, [dynamic error, StackTrace? stackTrace]) {
    logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log warning message
  void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log error message
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log fatal error message
  void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    logger.f(message, error: error, stackTrace: stackTrace);
  }

  /// Log API request
  void logApiRequest(String method, String url, Map<String, dynamic>? data) {
    if (kDebugMode) {
      info('API Request: $method $url', data);
    }
  }

  /// Log API response
  void logApiResponse(String method, String url, int statusCode, dynamic data) {
    if (kDebugMode) {
      info('API Response: $method $url [$statusCode]', data);
    }
  }

  /// Log user action
  void logUserAction(String action, Map<String, dynamic>? context) {
    info('User Action: $action', context);
  }

  /// Log performance metric
  void logPerformance(String operation, Duration duration) {
    info('Performance: $operation took ${duration.inMilliseconds}ms');
  }

  /// Log authentication event
  void logAuth(String event, String? userId) {
    info('Auth: $event', {'userId': userId});
  }

  /// Log order event
  void logOrder(String event, String orderId, Map<String, dynamic>? context) {
    info('Order: $event', {'orderId': orderId, ...?context});
  }

  /// Log payment event
  void logPayment(String event, String? paymentId, Map<String, dynamic>? context) {
    info('Payment: $event', {'paymentId': paymentId, ...?context});
  }

  /// Log navigation event
  void logNavigation(String from, String to) {
    debug('Navigation: $from -> $to');
  }

  /// Log database operation
  void logDatabase(String operation, String table, Map<String, dynamic>? context) {
    debug('Database: $operation on $table', context);
  }
}

/// Custom log filter
class _AppLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    // In debug mode, log everything
    if (kDebugMode) {
      return true;
    }
    
    // In release mode, only log warnings and errors
    return event.level.index >= Level.warning.index;
  }
}

/// Custom log printer
class _AppLogPrinter extends LogPrinter {


  @override
  List<String> log(LogEvent event) {
    final color = PrettyPrinter.defaultLevelColors[event.level];
    final emoji = PrettyPrinter.defaultLevelEmojis[event.level];
    final message = event.message;
    final time = DateTime.now().toIso8601String();

    List<String> output = [];

    // Add timestamp and level
    output.add(color!('$emoji [$time] [${event.level.name.toUpperCase()}] $message'));

    // Add error if present
    if (event.error != null) {
      output.add(color('Error: ${event.error}'));
    }

    // Add stack trace if present and in debug mode
    if (event.stackTrace != null && kDebugMode) {
      final stackTrace = event.stackTrace.toString();
      final lines = stackTrace.split('\n');
      for (final line in lines.take(10)) { // Limit stack trace lines
        output.add(color('  $line'));
      }
    }

    return output;
  }
}

/// Custom log output
class _AppLogOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    for (final line in event.lines) {
      if (kDebugMode) {
        debugPrint(line);
      }
    }
  }
}

/// Global logger instance
final logger = AppLogger();
