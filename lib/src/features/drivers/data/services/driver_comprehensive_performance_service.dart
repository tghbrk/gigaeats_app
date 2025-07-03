import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/driver_performance_stats.dart';

/// Comprehensive service for driver performance statistics
/// Aggregates data from multiple sources for complete performance overview
class DriverComprehensivePerformanceService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get comprehensive performance statistics for a driver
  Future<DriverPerformanceStats> getComprehensiveStats(String driverId) async {
    try {
      debugPrint('DriverComprehensivePerformanceService: Getting comprehensive stats for driver: $driverId');

      // Get current date boundaries
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startOfWeek = today.subtract(Duration(days: now.weekday - 1));
      final startOfMonth = DateTime(now.year, now.month, 1);

      // Fetch all data in parallel for better performance
      final results = await Future.wait([
        _getOverallPerformance(driverId),
        _getTodayPerformance(driverId, today),
        _getWeekPerformance(driverId, startOfWeek, now),
        _getMonthPerformance(driverId, startOfMonth, now),
        _getEarningsData(driverId, today, startOfWeek, startOfMonth, now),
      ]);

      final overallPerf = results[0];
      final todayPerf = results[1];
      final weekPerf = results[2];
      final monthPerf = results[3];
      final earningsData = results[4];

      // Combine all data into comprehensive stats
      return DriverPerformanceStats(
        totalDeliveries: (overallPerf['total_deliveries'] as num?)?.toInt() ?? 0,
        successfulDeliveries: (overallPerf['successful_deliveries'] as num?)?.toInt() ?? 0,
        averageDeliveryTimeMinutes: (overallPerf['average_delivery_time_minutes'] as num?)?.toDouble() ?? 0.0,
        customerRating: (overallPerf['average_rating'] as num?)?.toDouble() ?? 0.0,
        totalRatings: (overallPerf['rating_count'] as num?)?.toInt() ?? 0,
        onTimeDeliveryRate: (overallPerf['success_rate'] as num?)?.toDouble() ?? 0.0,
        totalDistanceKm: (overallPerf['total_distance_km'] as num?)?.toDouble() ?? 0.0,
        totalEarningsToday: (earningsData['earnings_today'] as num?)?.toDouble() ?? 0.0,
        totalEarningsWeek: (earningsData['earnings_week'] as num?)?.toDouble() ?? 0.0,
        totalEarningsMonth: (earningsData['earnings_month'] as num?)?.toDouble() ?? 0.0,
        averageEarningsPerDelivery: (overallPerf['average_earnings_per_delivery'] as num?)?.toDouble() ?? 0.0,
        deliveriesToday: (todayPerf['deliveries_count'] as num?)?.toInt() ?? 0,
        deliveriesWeek: (weekPerf['deliveries_count'] as num?)?.toInt() ?? 0,
        deliveriesMonth: (monthPerf['deliveries_count'] as num?)?.toInt() ?? 0,
        lastUpdated: DateTime.now(),
        additionalMetrics: {
          'peak_hours_deliveries': overallPerf['peak_hours_deliveries'] ?? 0,
          'weekend_deliveries': overallPerf['weekend_deliveries'] ?? 0,
          'average_customer_wait_time': overallPerf['average_customer_wait_time'] ?? 0.0,
          'cancellation_rate': overallPerf['cancellation_rate'] ?? 0.0,
        },
      );
    } catch (e) {
      debugPrint('DriverComprehensivePerformanceService: Error getting comprehensive stats: $e');
      return DriverPerformanceStats.empty();
    }
  }

  /// Get overall performance metrics
  Future<Map<String, dynamic>> _getOverallPerformance(String driverId) async {
    try {
      // Skip RPC function due to schema mismatch, use direct database queries
      debugPrint('DriverComprehensivePerformanceService: Using direct database queries for performance calculation');

      // Aggregate from driver_performance table
      final performanceData = await _supabase
          .from('driver_performance')
          .select('*')
          .eq('driver_id', driverId)
          .order('date', ascending: false);

      if (performanceData.isEmpty) {
        return _getEmptyPerformanceData();
      }

      // Aggregate the data
      int totalDeliveries = 0;
      int completedDeliveries = 0;
      double totalDistance = 0.0;
      double ratingSum = 0.0;
      int ratingCount = 0;
      int totalDeliveryTimeMinutes = 0;

      for (final record in performanceData) {
        totalDeliveries += ((record['total_deliveries'] as num?)?.toInt()) ?? 0;

        // Use the correct column name from database schema
        completedDeliveries += ((record['completed_deliveries'] as num?)?.toInt()) ?? 0;

        totalDistance += (record['total_distance_km'] as num?)?.toDouble() ?? 0.0;
        ratingSum += (record['rating_sum'] as num?)?.toDouble() ?? 0.0;
        ratingCount += ((record['rating_count'] as num?)?.toInt()) ?? 0;

        // Handle interval-based delivery time
        if (record['average_delivery_time'] != null) {
          // Parse PostgreSQL interval format (e.g., '00:30:00' for 30 minutes)
          final intervalStr = record['average_delivery_time'].toString();
          final parts = intervalStr.split(':');
          if (parts.length >= 2) {
            final hours = int.tryParse(parts[0]) ?? 0;
            final minutes = int.tryParse(parts[1]) ?? 0;
            totalDeliveryTimeMinutes += (hours * 60) + minutes;
          }
        }
      }

      // Get total earnings from driver_earnings table
      double totalEarnings = 0.0;
      try {
        final earningsData = await _supabase
            .from('driver_earnings')
            .select('net_earnings')
            .eq('driver_id', driverId);

        for (final earning in earningsData) {
          totalEarnings += (earning['net_earnings'] as num?)?.toDouble() ?? 0.0;
        }
      } catch (e) {
        debugPrint('DriverComprehensivePerformanceService: Error getting earnings: $e');
      }

      return {
        'total_deliveries': totalDeliveries,
        'successful_deliveries': completedDeliveries, // Map to expected field name
        'total_earnings': totalEarnings,
        'total_distance_km': totalDistance,
        'average_rating': ratingCount > 0 ? ratingSum / ratingCount : 0.0,
        'rating_count': ratingCount,
        'success_rate': totalDeliveries > 0 ? (completedDeliveries / totalDeliveries) * 100 : 0.0,
        'average_delivery_time_minutes': completedDeliveries > 0 ? totalDeliveryTimeMinutes / completedDeliveries : 0.0,
        'average_earnings_per_delivery': completedDeliveries > 0 ? totalEarnings / completedDeliveries : 0.0,
        'peak_hours_deliveries': 0, // Would need additional calculation
        'weekend_deliveries': 0, // Would need additional calculation
        'average_customer_wait_time': 0.0, // Would need additional data
        'cancellation_rate': 0.0, // Would need additional calculation
      };
    } catch (e) {
      debugPrint('DriverComprehensivePerformanceService: Error getting overall performance: $e');
      return _getEmptyPerformanceData();
    }
  }

  /// Get today's performance
  Future<Map<String, dynamic>> _getTodayPerformance(String driverId, DateTime today) async {
    try {
      final response = await _supabase
          .from('driver_performance')
          .select('*')
          .eq('driver_id', driverId)
          .eq('date', today.toIso8601String().split('T')[0])
          .maybeSingle();

      // Use the correct column name from database schema
      final completedDeliveries = (response?['completed_deliveries'] as num?)?.toInt() ?? 0;

      return {
        'deliveries_count': completedDeliveries,
        'total_deliveries': (response?['total_deliveries'] as num?)?.toInt() ?? 0,
      };
    } catch (e) {
      debugPrint('DriverComprehensivePerformanceService: Error getting today performance: $e');
      return {'deliveries_count': 0, 'total_deliveries': 0};
    }
  }

  /// Get week performance
  Future<Map<String, dynamic>> _getWeekPerformance(String driverId, DateTime startOfWeek, DateTime endDate) async {
    try {
      final response = await _supabase
          .from('driver_performance')
          .select('*')
          .eq('driver_id', driverId)
          .gte('date', startOfWeek.toIso8601String().split('T')[0])
          .lte('date', endDate.toIso8601String().split('T')[0]);

      int totalDeliveries = 0;
      for (final record in response) {
        // Use the correct column name from database schema
        totalDeliveries += ((record['completed_deliveries'] as num?)?.toInt()) ?? 0;
      }

      return {'deliveries_count': totalDeliveries};
    } catch (e) {
      debugPrint('DriverComprehensivePerformanceService: Error getting week performance: $e');
      return {'deliveries_count': 0};
    }
  }

  /// Get month performance
  Future<Map<String, dynamic>> _getMonthPerformance(String driverId, DateTime startOfMonth, DateTime endDate) async {
    try {
      final response = await _supabase
          .from('driver_performance')
          .select('*')
          .eq('driver_id', driverId)
          .gte('date', startOfMonth.toIso8601String().split('T')[0])
          .lte('date', endDate.toIso8601String().split('T')[0]);

      int totalDeliveries = 0;
      for (final record in response) {
        // Use the correct column name from database schema
        totalDeliveries += ((record['completed_deliveries'] as num?)?.toInt()) ?? 0;
      }

      return {'deliveries_count': totalDeliveries};
    } catch (e) {
      debugPrint('DriverComprehensivePerformanceService: Error getting month performance: $e');
      return {'deliveries_count': 0};
    }
  }

  /// Get earnings data for different periods
  Future<Map<String, dynamic>> _getEarningsData(
    String driverId,
    DateTime today,
    DateTime startOfWeek,
    DateTime startOfMonth,
    DateTime now,
  ) async {
    try {
      // Get earnings from driver_earnings_summary table for better performance
      final results = await Future.wait([
        _getEarningsForPeriod(driverId, today, now, 'daily'),
        _getEarningsForPeriod(driverId, startOfWeek, now, 'weekly'),
        _getEarningsForPeriod(driverId, startOfMonth, now, 'monthly'),
      ]);

      return {
        'earnings_today': results[0],
        'earnings_week': results[1],
        'earnings_month': results[2],
      };
    } catch (e) {
      debugPrint('DriverComprehensivePerformanceService: Error getting earnings data: $e');
      return {
        'earnings_today': 0.0,
        'earnings_week': 0.0,
        'earnings_month': 0.0,
      };
    }
  }

  /// Get earnings for a specific period
  Future<double> _getEarningsForPeriod(String driverId, DateTime start, DateTime end, String periodType) async {
    try {
      final response = await _supabase
          .from('driver_earnings_summary')
          .select('total_net_earnings') // Use correct column name from database schema
          .eq('driver_id', driverId)
          .gte('period_start', start.toIso8601String().split('T')[0])
          .lte('period_end', end.toIso8601String().split('T')[0]);

      double totalEarnings = 0.0;
      for (final record in response) {
        totalEarnings += (record['total_net_earnings'] as num?)?.toDouble() ?? 0.0;
      }

      return totalEarnings;
    } catch (e) {
      debugPrint('DriverComprehensivePerformanceService: Error getting earnings for period $periodType: $e');
      return 0.0;
    }
  }

  /// Get empty performance data for error cases
  Map<String, dynamic> _getEmptyPerformanceData() {
    return {
      'total_deliveries': 0,
      'successful_deliveries': 0,
      'total_earnings': 0.0,
      'total_distance_km': 0.0,
      'average_rating': 0.0,
      'rating_count': 0,
      'success_rate': 0.0,
      'average_delivery_time_minutes': 0.0,
      'average_earnings_per_delivery': 0.0,
      'peak_hours_deliveries': 0,
      'weekend_deliveries': 0,
      'average_customer_wait_time': 0.0,
      'cancellation_rate': 0.0,
    };
  }

  /// Stream comprehensive stats with real-time updates
  Stream<DriverPerformanceStats> streamComprehensiveStats(String driverId) async* {
    // Initial load
    yield await getComprehensiveStats(driverId);

    // Listen to driver_performance table changes
    final stream = _supabase
        .from('driver_performance')
        .stream(primaryKey: ['id'])
        .eq('driver_id', driverId);

    await for (final _ in stream) {
      // Reload comprehensive stats when performance data changes
      yield await getComprehensiveStats(driverId);
    }
  }
}
