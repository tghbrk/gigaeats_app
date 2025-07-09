import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import 'dart:convert';

/// Enhanced debugging utility for Flutter applications (optimized for Android emulator)
class DebugLogger {
  static const String _appName = 'GigaEats';

  /// Log general information (Android emulator optimized)
  static void info(String message, {String? tag}) {
    final logTag = tag ?? _appName;
    if (kDebugMode) {
      if (kIsWeb) {
        developer.log('ℹ️ $message', name: logTag);
      } else {
        // Android emulator - enhanced logging
        debugPrint('[$logTag] ℹ️ $message');
        developer.log('ℹ️ $message', name: logTag);
      }
    }
  }
  
  /// Log errors
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    final logTag = tag ?? '$_appName-Error';
    if (kIsWeb && kDebugMode) {
      developer.log('❌ $message', name: logTag, error: error, stackTrace: stackTrace);
    } else {
      debugPrint('[$logTag] ERROR: $message');
      if (error != null) debugPrint('Error details: $error');
      if (stackTrace != null) debugPrint('Stack trace: $stackTrace');
    }
  }
  
  /// Log warnings
  static void warning(String message, {String? tag}) {
    final logTag = tag ?? '$_appName-Warning';
    if (kIsWeb && kDebugMode) {
      developer.log('⚠️ $message', name: logTag);
    } else {
      debugPrint('[$logTag] WARNING: $message');
    }
  }
  
  /// Log success messages
  static void success(String message, {String? tag}) {
    final logTag = tag ?? _appName;
    if (kIsWeb && kDebugMode) {
      developer.log('✅ $message', name: logTag);
    } else {
      debugPrint('[$logTag] SUCCESS: $message');
    }
  }
  
  /// Log network requests
  static void networkRequest(String method, String url, {Map<String, dynamic>? data, Map<String, String>? headers}) {
    final logTag = '$_appName-Network';
    final message = '🌐 $method $url';
    
    if (kIsWeb && kDebugMode) {
      developer.log(message, name: logTag);
      if (headers != null && headers.isNotEmpty) {
        developer.log('📋 Headers: ${_formatJson(headers)}', name: logTag);
      }
      if (data != null && data.isNotEmpty) {
        developer.log('📦 Request Data: ${_formatJson(data)}', name: logTag);
      }
    } else {
      debugPrint('[$logTag] $message');
      if (headers != null && headers.isNotEmpty) {
        debugPrint('[$logTag] Headers: ${_formatJson(headers)}');
      }
      if (data != null && data.isNotEmpty) {
        debugPrint('[$logTag] Request Data: ${_formatJson(data)}');
      }
    }
  }
  
  /// Log network responses
  static void networkResponse(String method, String url, int statusCode, {dynamic data, String? error}) {
    final logTag = '$_appName-Network';
    final statusEmoji = statusCode >= 200 && statusCode < 300 ? '✅' : '❌';
    final message = '$statusEmoji $method $url - $statusCode';
    
    if (kIsWeb && kDebugMode) {
      developer.log(message, name: logTag);
      if (error != null) {
        developer.log('💥 Error: $error', name: '$logTag-Error');
      } else if (data != null) {
        developer.log('📥 Response Data: ${_formatJson(data)}', name: logTag);
      }
    } else {
      debugPrint('[$logTag] $message');
      if (error != null) {
        debugPrint('[$logTag] Error: $error');
      } else if (data != null) {
        debugPrint('[$logTag] Response Data: ${_formatJson(data)}');
      }
    }
  }
  
  /// Log object data with detailed field information
  static void logObject(String title, Map<String, dynamic> data, {String? tag}) {
    final logTag = tag ?? _appName;
    
    if (kIsWeb && kDebugMode) {
      developer.log('📊 $title', name: logTag);
      data.forEach((key, value) {
        developer.log('  $key: $value (${value.runtimeType})', name: logTag);
      });
    } else {
      debugPrint('[$logTag] $title');
      data.forEach((key, value) {
        debugPrint('[$logTag]   $key: $value (${value.runtimeType})');
      });
    }
  }
  
  /// Format JSON for logging
  static String _formatJson(dynamic data) {
    try {
      if (data is String) return data;
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (e) {
      return data.toString();
    }
  }
  
  /// Log provider state changes
  static void providerState(String providerName, String action, {dynamic data}) {
    final logTag = '$_appName-Provider';
    final message = '🔄 $providerName: $action';
    
    if (kIsWeb && kDebugMode) {
      developer.log(message, name: logTag);
      if (data != null) {
        developer.log('📋 Data: ${_formatJson(data)}', name: logTag);
      }
    } else {
      debugPrint('[$logTag] $message');
      if (data != null) {
        debugPrint('[$logTag] Data: ${_formatJson(data)}');
      }
    }
  }
  
  /// Log authentication events
  static void auth(String event, {String? userId, String? email, String? error}) {
    final logTag = '$_appName-Auth';
    
    if (kIsWeb && kDebugMode) {
      developer.log('🔐 $event', name: logTag);
      if (userId != null) developer.log('👤 User ID: $userId', name: logTag);
      if (email != null) developer.log('📧 Email: $email', name: logTag);
      if (error != null) developer.log('❌ Error: $error', name: '$logTag-Error');
    } else {
      debugPrint('[$logTag] $event');
      if (userId != null) debugPrint('[$logTag] User ID: $userId');
      if (email != null) debugPrint('[$logTag] Email: $email');
      if (error != null) debugPrint('[$logTag] Error: $error');
    }
  }
}
