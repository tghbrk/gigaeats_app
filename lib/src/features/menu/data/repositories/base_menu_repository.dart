import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/errors/menu_exceptions.dart';
import '../../../../core/utils/logger.dart';

/// Base repository class for menu-related operations with common functionality
abstract class BaseMenuRepository {
  final SupabaseClient supabase;
  final AppLogger _logger = AppLogger();

  BaseMenuRepository({SupabaseClient? client}) 
      : supabase = client ?? Supabase.instance.client;

  /// Get the current authenticated user
  User? get currentUser => supabase.auth.currentUser;

  /// Execute a query with comprehensive error handling
  Future<T> executeQuery<T>(Future<T> Function() query) async {
    try {
      _logger.debug('Executing database query');
      final result = await query();
      _logger.debug('Query executed successfully');
      return result;
    } on PostgrestException catch (e) {
      _logger.error('Database error: ${e.message}', e);
      throw _handlePostgrestException(e);
    } on AuthException catch (e) {
      _logger.error('Authentication error: ${e.message}', e);
      throw MenuUnauthorizedException(e.message);
    } catch (e) {
      _logger.error('Unexpected error: $e', e);
      throw MenuRepositoryException('An unexpected error occurred: $e');
    }
  }

  /// Execute a stream query with error handling
  Stream<T> executeStreamQuery<T>(Stream<T> Function() streamQuery) {
    try {
      _logger.debug('Executing stream query');
      return streamQuery().handleError((error) {
        _logger.error('Stream error: $error', error);
        if (error is PostgrestException) {
          throw _handlePostgrestException(error);
        } else if (error is AuthException) {
          throw MenuUnauthorizedException(error.message);
        } else {
          throw MenuRepositoryException('Stream error: $error');
        }
      });
    } catch (e) {
      _logger.error('Failed to create stream: $e', e);
      throw MenuRepositoryException('Failed to create stream: $e');
    }
  }

  /// Handle PostgrestException and convert to appropriate menu exception
  MenuException _handlePostgrestException(PostgrestException e) {
    switch (e.code) {
      case '23505': // Unique violation
        return MenuValidationException('A record with this information already exists');
      case '23503': // Foreign key violation
        return MenuValidationException('Cannot perform this action due to related data');
      case '23502': // Not null violation
        return MenuValidationException('Required field is missing');
      case '42501': // Insufficient privilege
        return MenuUnauthorizedException('You do not have permission to perform this action');
      case '42P01': // Undefined table
        return MenuRepositoryException('Database table not found');
      case 'PGRST116': // No rows found
        return MenuNotFoundException('Requested data not found');
      case 'PGRST301': // Row level security violation
        return MenuUnauthorizedException('Access denied by security policy');
      default:
        return MenuRepositoryException('Database error: ${e.message}');
    }
  }

  /// Validate that a string is a valid UUID
  bool isValidUuid(String? value) {
    if (value == null || value.isEmpty) return false;
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
    );
    return uuidRegex.hasMatch(value);
  }

  /// Validate required fields
  void validateRequired(Map<String, dynamic> fields) {
    final missingFields = <String>[];
    
    fields.forEach((key, value) {
      if (value == null || 
          (value is String && value.trim().isEmpty) ||
          (value is List && value.isEmpty)) {
        missingFields.add(key);
      }
    });

    if (missingFields.isNotEmpty) {
      throw MenuValidationException(
        'Required fields are missing: ${missingFields.join(', ')}'
      );
    }
  }

  /// Validate price values
  void validatePrice(double? price, String fieldName) {
    if (price == null) {
      throw MenuValidationException('$fieldName is required');
    }
    if (price < 0) {
      throw MenuValidationException('$fieldName cannot be negative');
    }
    if (price > 999999.99) {
      throw MenuValidationException('$fieldName is too large');
    }
  }

  /// Validate quantity values
  void validateQuantity(int? quantity, String fieldName) {
    if (quantity == null) {
      throw MenuValidationException('$fieldName is required');
    }
    if (quantity < 0) {
      throw MenuValidationException('$fieldName cannot be negative');
    }
    if (quantity > 999999) {
      throw MenuValidationException('$fieldName is too large');
    }
  }

  /// Validate date ranges
  void validateDateRange(DateTime? startDate, DateTime? endDate) {
    if (startDate != null && endDate != null) {
      if (endDate.isBefore(startDate)) {
        throw MenuValidationException('End date cannot be before start date');
      }
      if (startDate.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
        throw MenuValidationException('Start date cannot be in the past');
      }
    }
  }

  /// Validate percentage values
  void validatePercentage(double? percentage, String fieldName) {
    if (percentage == null) return; // Allow null for optional percentages
    
    if (percentage < 0 || percentage > 100) {
      throw MenuValidationException('$fieldName must be between 0 and 100');
    }
  }

  /// Get current vendor ID for the authenticated user
  Future<String?> getCurrentVendorId() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final response = await supabase
          .from('vendors')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      return response?['id'] as String?;
    } catch (e) {
      _logger.error('Failed to get current vendor ID: $e');
      return null;
    }
  }

  /// Check if current user is a vendor
  Future<bool> isCurrentUserVendor() async {
    final vendorId = await getCurrentVendorId();
    return vendorId != null;
  }

  /// Validate vendor ownership of a menu item
  Future<void> validateMenuItemOwnership(String menuItemId) async {
    final vendorId = await getCurrentVendorId();
    if (vendorId == null) {
      throw MenuUnauthorizedException('User is not a vendor');
    }

    final response = await supabase
        .from('menu_items')
        .select('vendor_id')
        .eq('id', menuItemId)
        .maybeSingle();

    if (response == null) {
      throw MenuNotFoundException('Menu item not found');
    }

    if (response['vendor_id'] != vendorId) {
      throw MenuUnauthorizedException('User does not own this menu item');
    }
  }

  /// Sanitize text input to prevent injection attacks
  String sanitizeText(String? input) {
    if (input == null) return '';

    // Remove potentially dangerous characters
    return input
        .replaceAll(RegExp(r'''[<>"']'''), '')
        .trim();
  }

  /// Validate and sanitize JSON data
  Map<String, dynamic> sanitizeJsonData(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};
    
    data.forEach((key, value) {
      if (value is String) {
        sanitized[key] = sanitizeText(value);
      } else if (value is Map<String, dynamic>) {
        sanitized[key] = sanitizeJsonData(value);
      } else if (value is List) {
        sanitized[key] = value.map((item) {
          if (item is String) {
            return sanitizeText(item);
          } else if (item is Map<String, dynamic>) {
            return sanitizeJsonData(item);
          }
          return item;
        }).toList();
      } else {
        sanitized[key] = value;
      }
    });
    
    return sanitized;
  }

  /// Log operation for debugging
  void logOperation(String operation, Map<String, dynamic>? data) {
    if (kDebugMode) {
      _logger.debug('$operation: ${data?.toString() ?? 'No data'}');
    }
  }

  /// Create a standardized error response
  Map<String, dynamic> createErrorResponse(String message, {String? code}) {
    return {
      'success': false,
      'message': message,
      'code': code,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Create a standardized success response
  Map<String, dynamic> createSuccessResponse(dynamic data, {String? message}) {
    return {
      'success': true,
      'data': data,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Batch operation helper
  Future<List<T>> executeBatchOperation<T>(
    List<Future<T> Function()> operations,
    {int batchSize = 10}
  ) async {
    final results = <T>[];
    
    for (int i = 0; i < operations.length; i += batchSize) {
      final batch = operations.skip(i).take(batchSize);
      final batchResults = await Future.wait(
        batch.map((operation) => operation()),
      );
      results.addAll(batchResults);
    }
    
    return results;
  }

  /// Dispose resources
  void dispose() {
    // Override in subclasses if needed
    _logger.debug('Disposing repository resources');
  }
}
