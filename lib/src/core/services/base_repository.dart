import 'package:flutter/foundation.dart';

/// Base repository class with common functionality
abstract class BaseRepository {
  /// Execute a query with error handling
  Future<T> executeQuery<T>(Future<T> Function() query) async {
    try {
      return await query();
    } catch (e) {
      debugPrint('Repository error: $e');
      rethrow;
    }
  }
}
