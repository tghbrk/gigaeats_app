import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/driver_earnings.dart';

/// Enhanced service for managing driver earnings data with real-time streaming and caching
class DriverEarningsService {
  final SupabaseClient _supabase;
  final Map<String, StreamController<List<DriverEarnings>>> _earningsStreams = {};
  final Map<String, StreamController<Map<String, dynamic>>> _summaryStreams = {};
  final Map<String, List<DriverEarnings>> _earningsCache = {};
  final Map<String, Map<String, dynamic>> _summaryCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  // Cache duration in minutes
  static const int _cacheDurationMinutes = 5;

  DriverEarningsService({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client {
    _initializeRealtimeSubscriptions();
  }

  /// Initialize real-time subscriptions for earnings updates
  void _initializeRealtimeSubscriptions() {
    debugPrint('DriverEarningsService: Initializing real-time subscriptions');

    // Subscribe to driver_earnings table changes
    _supabase
        .channel('driver_earnings_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'driver_earnings',
          callback: _handleEarningsUpdate,
        )
        .subscribe();
  }

  /// Handle real-time earnings updates
  void _handleEarningsUpdate(PostgresChangePayload payload) {
    debugPrint('DriverEarningsService: Received real-time update: ${payload.eventType}');

    try {
      final data = payload.newRecord;

      final driverId = data['driver_id'] as String?;
      if (driverId == null) return;

      // Invalidate cache for this driver
      _invalidateDriverCache(driverId);

      // Update streams if they exist
      if (_earningsStreams.containsKey(driverId)) {
        _refreshEarningsStream(driverId);
      }

      if (_summaryStreams.containsKey(driverId)) {
        _refreshSummaryStream(driverId);
      }
    } catch (e) {
      debugPrint('DriverEarningsService: Error handling real-time update: $e');
    }
  }

  /// Invalidate cache for a specific driver
  void _invalidateDriverCache(String driverId) {
    _earningsCache.remove(driverId);
    _summaryCache.remove(driverId);
    _cacheTimestamps.remove(driverId);
  }

  /// Check if cache is valid for a driver
  bool _isCacheValid(String driverId) {
    final timestamp = _cacheTimestamps[driverId];
    if (timestamp == null) return false;

    final now = DateTime.now();
    final difference = now.difference(timestamp).inMinutes;
    return difference < _cacheDurationMinutes;
  }

  /// Refresh earnings stream for a driver
  Future<void> _refreshEarningsStream(String driverId) async {
    try {
      final earnings = await _getDriverEarningsFromDatabase(driverId);
      final controller = _earningsStreams[driverId];
      if (controller != null && !controller.isClosed) {
        controller.add(earnings);
      }
    } catch (e) {
      debugPrint('DriverEarningsService: Error refreshing earnings stream: $e');
    }
  }

  /// Refresh summary stream for a driver
  Future<void> _refreshSummaryStream(String driverId) async {
    try {
      final summary = await _getDriverEarningsSummaryFromDatabase(driverId);
      final controller = _summaryStreams[driverId];
      if (controller != null && !controller.isClosed) {
        controller.add(summary);
      }
    } catch (e) {
      debugPrint('DriverEarningsService: Error refreshing summary stream: $e');
    }
  }

  /// Execute a query with enhanced error handling and retry logic
  Future<T> executeQuery<T>(Future<T> Function() query, {int retries = 3}) async {
    for (int attempt = 0; attempt < retries; attempt++) {
      try {
        return await query();
      } catch (error) {
        debugPrint('DriverEarningsService error (attempt ${attempt + 1}/$retries): $error');

        if (error is PostgrestException) {
          switch (error.code) {
            case '23505':
              throw Exception('A record with this information already exists');
            case '23503':
              throw Exception('Cannot delete this record as it is referenced by other data');
            case '42501':
              throw Exception('You do not have permission to perform this action');
            case 'PGRST301':
              // Connection error - retry
              if (attempt < retries - 1) {
                await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
                continue;
              }
              throw Exception('Connection error: ${error.message}');
            default:
              throw Exception(error.message);
          }
        }

        // For other errors, retry if not the last attempt
        if (attempt < retries - 1) {
          await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
          continue;
        }

        throw Exception(error.toString());
      }
    }

    throw Exception('Query failed after $retries attempts');
  }

  /// Get driver earnings from database (internal method)
  Future<List<DriverEarnings>> _getDriverEarningsFromDatabase(
    String driverId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    var query = _supabase
        .from('driver_earnings')
        .select('*')
        .eq('driver_id', driverId);

    if (startDate != null) {
      query = query.gte('created_at', startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('created_at', endDate.toIso8601String());
    }

    final response = await query
        .order('created_at', ascending: false)
        .limit(limit);

    return response.map((json) => DriverEarnings.fromJson(json)).toList();
  }

  /// Get driver earnings summary from database (internal method)
  Future<Map<String, dynamic>> _getDriverEarningsSummaryFromDatabase(
    String driverId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _supabase
        .from('driver_earnings')
        .select('*')
        .eq('driver_id', driverId);

    if (startDate != null) {
      debugPrint('DriverEarningsService: Filtering by startDate: ${startDate.toIso8601String()}');
      query = query.gte('created_at', startDate.toIso8601String());
    }
    if (endDate != null) {
      debugPrint('DriverEarningsService: Filtering by endDate: ${endDate.toIso8601String()}');
      query = query.lte('created_at', endDate.toIso8601String());
    }

    debugPrint('DriverEarningsService: Executing summary query for driver: $driverId');
    final response = await query;
    debugPrint('DriverEarningsService: Summary query returned ${response.length} records');

    // Calculate summary from current database schema
    double totalGrossEarnings = 0.0;
    double totalNetEarnings = 0.0;
    double totalDeductions = 0.0;
    int totalDeliveries = 0;
    Set<String> uniqueOrders = {};

    for (final record in response) {
      totalGrossEarnings += (record['gross_earnings'] as num?)?.toDouble() ?? 0.0;
      totalNetEarnings += (record['net_earnings'] as num?)?.toDouble() ?? 0.0;
      totalDeductions += (record['deductions'] as num?)?.toDouble() ?? 0.0;

      final orderId = record['order_id'] as String?;
      if (orderId != null) {
        uniqueOrders.add(orderId);
      }
    }

    totalDeliveries = uniqueOrders.length;

    return {
      'total_gross_earnings': totalGrossEarnings,
      'total_net_earnings': totalNetEarnings,
      'total_deductions': totalDeductions,
      'total_deliveries': totalDeliveries,
      'average_earnings_per_delivery': totalDeliveries > 0 ? totalNetEarnings / totalDeliveries : 0.0,
      'period_start': startDate?.toIso8601String(),
      'period_end': endDate?.toIso8601String(),
    };
  }

  /// Get driver earnings for a specific period with caching
  Future<List<DriverEarnings>> getDriverEarnings(
    String driverId, {
    DateTime? startDate,
    DateTime? endDate,
    EarningsType? earningsType,
    EarningsStatus? status,
    int limit = 50,
    bool useCache = true,
  }) async {
    return executeQuery(() async {
      debugPrint('DriverEarningsService: Getting earnings for driver: $driverId');

      // Check cache first if no specific filters and cache is enabled
      if (useCache && startDate == null && endDate == null && earningsType == null && status == null) {
        if (_isCacheValid(driverId) && _earningsCache.containsKey(driverId)) {
          debugPrint('DriverEarningsService: Returning cached earnings for driver: $driverId');
          return _earningsCache[driverId]!.take(limit).toList();
        }
      }

      var query = _supabase
          .from('driver_earnings')
          .select('*')
          .eq('driver_id', driverId);

      // Apply filters based on current schema
      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }
      if (status != null) {
        query = query.eq('payment_status', status.value);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      debugPrint('DriverEarningsService: Retrieved ${response.length} earnings records');

      final earnings = response.map((json) => DriverEarnings.fromJson(json)).toList();

      // Cache the results if no filters applied
      if (useCache && startDate == null && endDate == null && earningsType == null && status == null) {
        _earningsCache[driverId] = earnings;
        _cacheTimestamps[driverId] = DateTime.now();
      }

      return earnings;
    });
  }

  /// Get driver earnings summary for a specific period with caching
  Future<Map<String, dynamic>> getDriverEarningsSummary(
    String driverId, {
    DateTime? startDate,
    DateTime? endDate,
    bool useCache = true,
  }) async {
    return executeQuery(() async {
      debugPrint('DriverEarningsService: Getting earnings summary for driver: $driverId');

      // Check cache first if no date filters and cache is enabled
      if (useCache && startDate == null && endDate == null) {
        if (_isCacheValid(driverId) && _summaryCache.containsKey(driverId)) {
          debugPrint('DriverEarningsService: Returning cached summary for driver: $driverId');
          return _summaryCache[driverId]!;
        }
      }

      final summary = await _getDriverEarningsSummaryFromDatabase(
        driverId,
        startDate: startDate,
        endDate: endDate,
      );

      // Cache the results if no date filters applied
      if (useCache && startDate == null && endDate == null) {
        _summaryCache[driverId] = summary;
        _cacheTimestamps[driverId] = DateTime.now();
      }

      debugPrint('DriverEarningsService: Summary calculated - Net: ${summary['total_net_earnings']}, Deliveries: ${summary['total_deliveries']}');
      return summary;
    });
  }

  /// Stream real-time earnings summary updates
  Stream<Map<String, dynamic>> streamDriverEarningsSummary(String driverId) {
    debugPrint('DriverEarningsService: Starting real-time summary stream for driver: $driverId');

    // Create stream controller if it doesn't exist
    if (!_summaryStreams.containsKey(driverId)) {
      _summaryStreams[driverId] = StreamController<Map<String, dynamic>>.broadcast();

      // Initialize with current data
      getDriverEarningsSummary(driverId).then((summary) {
        final controller = _summaryStreams[driverId];
        if (controller != null && !controller.isClosed) {
          controller.add(summary);
        }
      }).catchError((error) {
        debugPrint('DriverEarningsService: Error initializing summary stream: $error');
      });
    }

    return _summaryStreams[driverId]!.stream;
  }

  /// Get driver earnings breakdown by type
  Future<Map<String, double>> getDriverEarningsBreakdown(
    String driverId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return executeQuery(() async {
      debugPrint('DriverEarningsService: Getting earnings breakdown for driver: $driverId');

      var query = _supabase
          .from('driver_earnings')
          .select('earnings_type, net_earnings, gross_earnings, base_commission, completion_bonus, peak_hour_bonus, rating_bonus, other_bonuses, deductions')
          .eq('driver_id', driverId);

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final response = await query;

      Map<String, double> breakdown = {
        'delivery_fees': 0.0,
        'tips': 0.0,
        'bonuses': 0.0,
        'commissions': 0.0,
        'penalties': 0.0,
        'total': 0.0,
      };

      for (final record in response) {
        final type = record['earnings_type'] as String?;
        final amount = (record['net_earnings'] as num?)?.toDouble() ?? 0.0;

        // Handle null earnings_type by defaulting to delivery_fee
        final earningsType = type ?? 'delivery_fee';

        switch (earningsType) {
          case 'delivery_fee':
            breakdown['delivery_fees'] = breakdown['delivery_fees']! + amount;
            break;
          case 'tip':
            breakdown['tips'] = breakdown['tips']! + amount;
            break;
          case 'bonus':
            breakdown['bonuses'] = breakdown['bonuses']! + amount;
            break;
          case 'commission':
            breakdown['commissions'] = breakdown['commissions']! + amount;
            break;
          case 'penalty':
            breakdown['penalties'] = breakdown['penalties']! + amount;
            break;
        }
        breakdown['total'] = breakdown['total']! + amount;
      }

      debugPrint('DriverEarningsService: Breakdown calculated - Total: ${breakdown['total']}');
      return breakdown;
    });
  }

  /// Get driver earnings history with pagination
  Future<List<Map<String, dynamic>>> getDriverEarningsHistory(
    String driverId, {
    int page = 1,
    int limit = 20,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return executeQuery(() async {
      debugPrint('DriverEarningsService: Getting earnings history for driver: $driverId, page: $page');

      final offset = (page - 1) * limit;

      var query = _supabase
          .from('driver_earnings')
          .select('''
            *,
            orders(order_number, delivery_address, vendor_id)
          ''')
          .eq('driver_id', driverId);

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      debugPrint('DriverEarningsService: Retrieved ${response.length} earnings history records');

      // Get vendor information for all unique vendor IDs
      final vendorIds = response
          .map((record) => record['orders']?['vendor_id'] as String?)
          .where((id) => id != null)
          .toSet()
          .cast<String>();

      Map<String, String> vendorNames = {};
      if (vendorIds.isNotEmpty) {
        try {
          final vendorsResponse = await _supabase
              .from('vendors')
              .select('id, business_name')
              .inFilter('id', vendorIds.toList());

          for (final vendor in vendorsResponse) {
            vendorNames[vendor['id']] = vendor['business_name'] ?? 'Unknown Vendor';
          }
        } catch (e) {
          debugPrint('DriverEarningsService: Error fetching vendor names: $e');
        }
      }

      return response.map((record) {
        final orderInfo = record['orders'] as Map<String, dynamic>?;
        final deliveryAddress = orderInfo?['delivery_address'] as Map<String, dynamic>?;
        final vendorId = orderInfo?['vendor_id'] as String?;

        // Format delivery address
        String formattedAddress = 'Unknown Address';
        if (deliveryAddress != null) {
          final street = deliveryAddress['street'] ?? '';
          final city = deliveryAddress['city'] ?? '';
          final state = deliveryAddress['state'] ?? '';
          formattedAddress = '$street, $city, $state'.replaceAll(RegExp(r'^,\s*|,\s*$'), '');
          if (formattedAddress.isEmpty) formattedAddress = 'Unknown Address';
        }

        return {
          'id': record['id'],
          'order_id': record['order_id'],
          'order_number': orderInfo?['order_number'] ?? 'N/A',
          'vendor_name': vendorNames[vendorId] ?? 'Unknown Vendor',
          'customer_name': 'Customer', // Default since customer_name is not available
          'delivery_address': formattedAddress,
          'earnings_type': record['earnings_type'] ?? 'delivery_fee',
          'amount': (record['net_earnings'] as num?)?.toDouble() ?? 0.0,
          'net_earnings': (record['net_earnings'] as num?)?.toDouble() ?? 0.0,
          'gross_earnings': (record['gross_earnings'] as num?)?.toDouble() ?? 0.0,
          'base_commission': (record['base_commission'] as num?)?.toDouble() ?? 0.0,
          'distance_fee': (record['distance_fee'] as num?)?.toDouble() ?? 0.0,
          'time_fee': (record['time_fee'] as num?)?.toDouble() ?? 0.0,
          'peak_hour_bonus': (record['peak_hour_bonus'] as num?)?.toDouble() ?? 0.0,
          'completion_bonus': (record['completion_bonus'] as num?)?.toDouble() ?? 0.0,
          'rating_bonus': (record['rating_bonus'] as num?)?.toDouble() ?? 0.0,
          'other_bonuses': (record['other_bonuses'] as num?)?.toDouble() ?? 0.0,
          'deductions': (record['deductions'] as num?)?.toDouble() ?? 0.0,
          'payment_status': record['payment_status'] ?? 'pending',
          'created_at': record['created_at'],
        };
      }).toList();
    });
  }

  /// Get driver commission structure
  Future<DriverCommissionStructure?> getDriverCommissionStructure(
    String driverId,
    String vendorId,
  ) async {
    return executeQuery(() async {
      debugPrint('DriverEarningsService: Getting commission structure for driver: $driverId, vendor: $vendorId');

      final response = await _supabase
          .from('driver_commission_structure')
          .select('*')
          .eq('driver_id', driverId)
          .eq('vendor_id', vendorId)
          .eq('is_active', true)
          .lte('effective_from', DateTime.now().toIso8601String().split('T')[0])
          .or('effective_until.is.null,effective_until.gte.${DateTime.now().toIso8601String().split('T')[0]}')
          .order('effective_from', ascending: false)
          .limit(1);

      if (response.isEmpty) {
        debugPrint('DriverEarningsService: No commission structure found');
        return null;
      }

      debugPrint('DriverEarningsService: Commission structure retrieved');
      return DriverCommissionStructure.fromJson(response.first);
    });
  }

  /// Get daily earnings for a specific period (for charts/analytics)
  Future<List<Map<String, dynamic>>> getDailyEarnings(
    String driverId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return executeQuery(() async {
      debugPrint('DriverEarningsService: Getting daily earnings for driver: $driverId');

      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      final response = await _supabase
          .from('driver_earnings_summary')
          .select('*')
          .eq('driver_id', driverId)
          .eq('period_type', 'daily')
          .gte('period_start', start.toIso8601String().split('T')[0])
          .lte('period_end', end.toIso8601String().split('T')[0])
          .order('period_start', ascending: true);

      debugPrint('DriverEarningsService: Retrieved ${response.length} daily earnings records');

      return response.map((record) => {
        'date': record['period_start'],
        'total_earnings': (record['total_earnings'] as num?)?.toDouble() ?? 0.0,
        'net_earnings': (record['net_earnings'] as num?)?.toDouble() ?? 0.0,
        'deliveries': (record['successful_deliveries'] as num?)?.toInt() ?? 0,
        'average_per_delivery': (record['average_earnings_per_delivery'] as num?)?.toDouble() ?? 0.0,
      }).toList();
    });
  }

  /// Stream real-time earnings updates with enhanced functionality
  Stream<List<DriverEarnings>> streamDriverEarnings(String driverId) {
    debugPrint('DriverEarningsService: Starting real-time earnings stream for driver: $driverId');

    // Create stream controller if it doesn't exist
    if (!_earningsStreams.containsKey(driverId)) {
      _earningsStreams[driverId] = StreamController<List<DriverEarnings>>.broadcast();

      // Initialize with current data
      getDriverEarnings(driverId).then((earnings) {
        final controller = _earningsStreams[driverId];
        if (controller != null && !controller.isClosed) {
          controller.add(earnings);
        }
      }).catchError((error) {
        debugPrint('DriverEarningsService: Error initializing earnings stream: $error');
      });
    }

    return _earningsStreams[driverId]!.stream;
  }

  /// Call enhanced earnings calculation Edge Function
  Future<Map<String, dynamic>> calculateEnhancedEarnings({
    required String orderId,
    required String driverId,
    bool includeBonus = true,
    double customTip = 0.0,
    Map<String, dynamic>? performanceMetrics,
  }) async {
    return executeQuery(() async {
      debugPrint('DriverEarningsService: Calculating enhanced earnings for order: $orderId');

      final response = await _supabase.functions.invoke(
        'enhanced-earnings-calculation',
        body: {
          'orderId': orderId,
          'driverId': driverId,
          'includeBonus': includeBonus,
          'customTip': customTip,
          'performanceMetrics': performanceMetrics,
        },
      );

      if (response.data == null) {
        throw Exception('No response from earnings calculation function');
      }

      final result = response.data as Map<String, dynamic>;
      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Unknown error in earnings calculation');
      }

      return result['earnings'] as Map<String, dynamic>;
    });
  }

  /// Dispose of streams and cleanup resources
  void dispose() {
    debugPrint('DriverEarningsService: Disposing streams and cleaning up resources');

    // Close all earnings streams
    for (final controller in _earningsStreams.values) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
    _earningsStreams.clear();

    // Close all summary streams
    for (final controller in _summaryStreams.values) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
    _summaryStreams.clear();

    // Clear caches
    _earningsCache.clear();
    _summaryCache.clear();
    _cacheTimestamps.clear();
  }

  /// Clear cache for a specific driver
  void clearDriverCache(String driverId) {
    debugPrint('DriverEarningsService: Clearing cache for driver: $driverId');
    _invalidateDriverCache(driverId);
  }

  /// Close streams for a specific driver to free resources
  void closeDriverStreams(String driverId) {
    debugPrint('DriverEarningsService: Closing streams for driver: $driverId');

    // Close earnings stream
    final earningsController = _earningsStreams[driverId];
    if (earningsController != null && !earningsController.isClosed) {
      earningsController.close();
    }
    _earningsStreams.remove(driverId);

    // Close summary stream
    final summaryController = _summaryStreams[driverId];
    if (summaryController != null && !summaryController.isClosed) {
      summaryController.close();
    }
    _summaryStreams.remove(driverId);
  }

  /// Force refresh all data for a driver (clears cache and refetches)
  Future<void> forceRefreshDriver(String driverId) async {
    debugPrint('DriverEarningsService: Force refreshing all data for driver: $driverId');
    clearDriverCache(driverId);

    // Refresh earnings stream
    await _refreshEarningsStream(driverId);

    // Refresh summary stream
    await _refreshSummaryStream(driverId);
  }

  /// Clear all caches
  void clearAllCaches() {
    debugPrint('DriverEarningsService: Clearing all caches');
    _earningsCache.clear();
    _summaryCache.clear();
    _cacheTimestamps.clear();
  }

  /// Get cache status for debugging
  Map<String, dynamic> getCacheStatus() {
    return {
      'earnings_cache_size': _earningsCache.length,
      'summary_cache_size': _summaryCache.length,
      'active_earnings_streams': _earningsStreams.length,
      'active_summary_streams': _summaryStreams.length,
      'cache_timestamps': _cacheTimestamps.map((key, value) => MapEntry(key, value.toIso8601String())),
    };
  }
}
