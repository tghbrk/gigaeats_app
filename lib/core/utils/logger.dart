import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

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
  static final _deviceStackTraceRegex = RegExp(r'#[0-9]+[\s]+(.+) \(([^\s]+)\)');
  static final _webStackTraceRegex = RegExp(r'^((packages\/[^\/]+\/)?([^\/]+\/)*[^\/]+\.dart):([0-9]+):([0-9]+)$');
  static final _browserStackTraceRegex = RegExp(r'^(?:package:)?(.*\.dart):([0-9]+):([0-9]+)$');

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
      final stackTrace = _formatStackTrace(event.stackTrace!);
      if (stackTrace.isNotEmpty) {
        output.add(color('Stack Trace:'));
        output.addAll(stackTrace.map((line) => color('  $line')));
      }
    }

    return output;
  }

  List<String> _formatStackTrace(StackTrace stackTrace) {
    final lines = stackTrace.toString().split('\n');
    final formatted = <String>[];

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      Match? match;
      if (kIsWeb) {
        match = _webStackTraceRegex.firstMatch(line) ?? _browserStackTraceRegex.firstMatch(line);
      } else {
        match = _deviceStackTraceRegex.firstMatch(line);
      }

      if (match != null) {
        if (kIsWeb) {
          final file = match.group(1);
          final lineNumber = match.group(2);
          final columnNumber = match.group(3);
          formatted.add('$file:$lineNumber:$columnNumber');
        } else {
          final method = match.group(1);
          final location = match.group(2);
          formatted.add('$method ($location)');
        }
      } else {
        formatted.add(line);
      }

      // Limit stack trace lines
      if (formatted.length >= 10) break;
    }

    return formatted;
  }
}

/// Custom log output
class _AppLogOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    for (final line in event.lines) {
      if (kDebugMode) {
        // In debug mode, print to console
        debugPrint(line);
      }
      // In production, you might want to send logs to a service like Crashlytics
      // FirebaseCrashlytics.instance.log(line);
    }
  }
}

/// Extension for easy logging
extension LoggerExtension on Object {
  void logDebug(String message) => AppLogger().debug('${runtimeType}: $message');
  void logInfo(String message) => AppLogger().info('${runtimeType}: $message');
  void logWarning(String message) => AppLogger().warning('${runtimeType}: $message');
  void logError(String message, [dynamic error, StackTrace? stackTrace]) {
    AppLogger().error('${runtimeType}: $message', error, stackTrace);
  }
}
