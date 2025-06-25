import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for driver performance metrics and analytics
/// Handles performance calculations, leaderboards, and earnings tracking
class DriverPerformanceService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get comprehensive performance summary for a driver
  Future<Map<String, dynamic>?> getDriverPerformanceSummary(String driverId) async {
    try {
      debugPrint('DriverPerformanceService: Getting performance summary for driver: $driverId');

      final response = await _supabase
          .from('driver_performance_summary')
          .select('*')
          .eq('driver_id', driverId)
          .single();

      debugPrint('DriverPerformanceService: Performance summary retrieved successfully');
      return response;
    } catch (e) {
      debugPrint('DriverPerformanceService: Error getting performance summary: $e');
      return null;
    }
  }

  /// Calculate driver performance for a specific period
  Future<Map<String, dynamic>?> calculateDriverPerformance(
    String driverId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      debugPrint('DriverPerformanceService: Calculating performance for driver: $driverId');
      debugPrint('DriverPerformanceService: Date range: ${startDate?.toIso8601String().split('T')[0]} to ${endDate?.toIso8601String().split('T')[0]}');

      // Skip RPC function due to schema mismatch, use direct database queries
      debugPrint('DriverPerformanceService: Using direct database queries for performance calculation');

      // Query driver_performance table directly
      var query = _supabase
          .from('driver_performance')
          .select('*')
          .eq('driver_id', driverId);

      if (startDate != null) {
        query = query.gte('date', startDate.toIso8601String().split('T')[0]);
      }
      if (endDate != null) {
        query = query.lte('date', endDate.toIso8601String().split('T')[0]);
      }

      final performanceData = await query.order('date', ascending: false);

      if (performanceData.isEmpty) {
        debugPrint('DriverPerformanceService: No performance data found');
        return null;
      }

      // Aggregate the data
      int totalDeliveries = 0;
      int completedDeliveries = 0;
      double totalEarnings = 0.0;
      double totalDistance = 0.0;
      double ratingSum = 0.0;
      int ratingCount = 0;

      for (final record in performanceData) {
        totalDeliveries += (record['total_deliveries'] as num?)?.toInt() ?? 0;
        completedDeliveries += (record['completed_deliveries'] as num?)?.toInt() ?? 0;
        totalEarnings += (record['total_earnings'] as num?)?.toDouble() ?? 0.0;
        totalDistance += (record['total_distance_km'] as num?)?.toDouble() ?? 0.0;
        ratingSum += (record['rating_sum'] as num?)?.toDouble() ?? 0.0;
        ratingCount += (record['rating_count'] as num?)?.toInt() ?? 0;
      }

      final result = {
        'total_deliveries': totalDeliveries,
        'successful_deliveries': completedDeliveries,
        'total_earnings': totalEarnings,
        'total_distance_km': totalDistance,
        'average_rating': ratingCount > 0 ? ratingSum / ratingCount : 0.0,
        'rating_count': ratingCount,
        'success_rate': totalDeliveries > 0 ? (completedDeliveries / totalDeliveries) * 100 : 0.0,
        'average_earnings_per_delivery': completedDeliveries > 0 ? totalEarnings / completedDeliveries : 0.0,
      };

      debugPrint('DriverPerformanceService: Performance calculated successfully: $result');
      return result;
    } catch (e) {
      debugPrint('DriverPerformanceService: Error calculating performance: $e');
      return null;
    }
  }

  /// Get driver leaderboard
  Future<List<Map<String, dynamic>>> getDriverLeaderboard({
    String? vendorId,
    int periodDays = 30,
    int limit = 10,
  }) async {
    try {
      debugPrint('DriverPerformanceService: Getting driver leaderboard');

      final response = await _supabase.rpc('get_driver_leaderboard', params: {
        'p_vendor_id': vendorId,
        'p_period_days': periodDays,
        'p_limit': limit,
      });

      debugPrint('DriverPerformanceService: Leaderboard retrieved with ${response.length} drivers');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('DriverPerformanceService: Error getting leaderboard: $e');
      return [];
    }
  }

  /// Get driver daily performance history
  Future<List<Map<String, dynamic>>> getDriverDailyPerformance(
    String driverId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 30,
  }) async {
    try {
      debugPrint('DriverPerformanceService: Getting daily performance for driver: $driverId');

      var query = _supabase
          .from('driver_performance')
          .select('*')
          .eq('driver_id', driverId);

      if (startDate != null) {
        query = query.gte('date', startDate.toIso8601String().split('T')[0]);
      }
      if (endDate != null) {
        query = query.lte('date', endDate.toIso8601String().split('T')[0]);
      }

      final response = await query
          .order('date', ascending: false)
          .limit(limit);

      debugPrint('DriverPerformanceService: Found ${response.length} daily performance records');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('DriverPerformanceService: Error getting daily performance: $e');
      return [];
    }
  }

  /// Update driver rating
  Future<bool> updateDriverRating(String driverId, double rating, {DateTime? date}) async {
    try {
      debugPrint('DriverPerformanceService: Updating rating for driver: $driverId, rating: $rating');

      await _supabase.rpc('update_driver_rating', params: {
        'p_driver_id': driverId,
        'p_rating': rating,
        'p_date': (date ?? DateTime.now()).toIso8601String().split('T')[0],
      });

      debugPrint('DriverPerformanceService: Rating updated successfully');
      return true;
    } catch (e) {
      debugPrint('DriverPerformanceService: Error updating rating: $e');
      return false;
    }
  }

  /// Get driver earnings for a specific period
  Future<Map<String, dynamic>> getDriverEarnings(
    String driverId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      debugPrint('DriverPerformanceService: Getting earnings for driver: $driverId');

      var query = _supabase
          .from('driver_performance')
          .select('date, total_earnings, completed_deliveries, total_deliveries')
          .eq('driver_id', driverId);

      if (startDate != null) {
        query = query.gte('date', startDate.toIso8601String().split('T')[0]);
      }
      if (endDate != null) {
        query = query.lte('date', endDate.toIso8601String().split('T')[0]);
      }

      final response = await query.order('date', ascending: false);

      double totalEarnings = 0;
      int totalDeliveries = 0;
      int successfulDeliveries = 0;
      int workingDays = 0;

      for (final record in response) {
        totalEarnings += (record['total_earnings'] as num?)?.toDouble() ?? 0;
        totalDeliveries += ((record['total_deliveries'] as num?)?.toInt()) ?? 0;
        successfulDeliveries += ((record['completed_deliveries'] as num?)?.toInt()) ?? 0;
        if ((((record['total_deliveries'] as num?)?.toInt()) ?? 0) > 0) {
          workingDays++;
        }
      }

      final result = {
        'total_earnings': totalEarnings,
        'total_deliveries': totalDeliveries,
        'successful_deliveries': successfulDeliveries,
        'working_days': workingDays,
        'average_earnings_per_day': workingDays > 0 ? totalEarnings / workingDays : 0,
        'average_earnings_per_delivery': successfulDeliveries > 0 ? totalEarnings / successfulDeliveries : 0,
        'success_rate': totalDeliveries > 0 ? (successfulDeliveries / totalDeliveries) * 100 : 0,
        'daily_breakdown': response,
      };

      debugPrint('DriverPerformanceService: Earnings calculated - Total: $totalEarnings, Deliveries: $successfulDeliveries');
      return result;
    } catch (e) {
      debugPrint('DriverPerformanceService: Error getting earnings: $e');
      return {
        'total_earnings': 0.0,
        'total_deliveries': 0,
        'successful_deliveries': 0,
        'working_days': 0,
        'average_earnings_per_day': 0.0,
        'average_earnings_per_delivery': 0.0,
        'success_rate': 0.0,
        'daily_breakdown': [],
      };
    }
  }

  /// Get driver performance trends
  Future<Map<String, dynamic>> getDriverPerformanceTrends(
    String driverId, {
    int days = 30,
  }) async {
    try {
      debugPrint('DriverPerformanceService: Getting performance trends for driver: $driverId');

      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));

      final response = await _supabase
          .from('driver_performance')
          .select('*')
          .eq('driver_id', driverId)
          .gte('date', startDate.toIso8601String().split('T')[0])
          .lte('date', endDate.toIso8601String().split('T')[0])
          .order('date', ascending: true);

      if (response.isEmpty) {
        return {
          'trend_data': [],
          'total_earnings_trend': 0.0,
          'success_rate_trend': 0.0,
          'delivery_time_trend': 0.0,
          'rating_trend': 0.0,
        };
      }

      // Calculate trends
      final firstWeek = response.take(7).toList();
      final lastWeek = response.skip(response.length - 7).toList();

      double firstWeekEarnings = firstWeek.fold(0, (sum, record) => sum + ((record['total_earnings'] as num?)?.toDouble() ?? 0));
      double lastWeekEarnings = lastWeek.fold(0, (sum, record) => sum + ((record['total_earnings'] as num?)?.toDouble() ?? 0));

      double firstWeekSuccessRate = firstWeek.fold(0.0, (sum, record) => sum + ((record['success_rate'] as num?)?.toDouble() ?? 0)) / firstWeek.length;
      double lastWeekSuccessRate = lastWeek.fold(0.0, (sum, record) => sum + ((record['success_rate'] as num?)?.toDouble() ?? 0)) / lastWeek.length;

      double firstWeekDeliveryTime = firstWeek.fold(0.0, (sum, record) => sum + ((record['average_delivery_time_minutes'] as num?)?.toDouble() ?? 0)) / firstWeek.length;
      double lastWeekDeliveryTime = lastWeek.fold(0.0, (sum, record) => sum + ((record['average_delivery_time_minutes'] as num?)?.toDouble() ?? 0)) / lastWeek.length;

      double firstWeekRating = firstWeek.fold(0.0, (sum, record) => sum + ((record['average_rating'] as num?)?.toDouble() ?? 0)) / firstWeek.length;
      double lastWeekRating = lastWeek.fold(0.0, (sum, record) => sum + ((record['average_rating'] as num?)?.toDouble() ?? 0)) / lastWeek.length;

      final result = {
        'trend_data': response,
        'total_earnings_trend': lastWeekEarnings - firstWeekEarnings,
        'success_rate_trend': lastWeekSuccessRate - firstWeekSuccessRate,
        'delivery_time_trend': firstWeekDeliveryTime - lastWeekDeliveryTime, // Negative is better (faster)
        'rating_trend': lastWeekRating - firstWeekRating,
      };

      debugPrint('DriverPerformanceService: Performance trends calculated successfully');
      return result;
    } catch (e) {
      debugPrint('DriverPerformanceService: Error getting performance trends: $e');
      return {
        'trend_data': [],
        'total_earnings_trend': 0.0,
        'success_rate_trend': 0.0,
        'delivery_time_trend': 0.0,
        'rating_trend': 0.0,
      };
    }
  }

  /// Get driver performance comparison with peers
  Future<Map<String, dynamic>> getDriverPerformanceComparison(
    String driverId, {
    String? vendorId,
    int periodDays = 30,
  }) async {
    try {
      debugPrint('DriverPerformanceService: Getting performance comparison for driver: $driverId');

      // Get driver's performance
      final driverPerformance = await calculateDriverPerformance(
        driverId,
        startDate: DateTime.now().subtract(Duration(days: periodDays)),
        endDate: DateTime.now(),
      );

      if (driverPerformance == null) {
        return {'error': 'Driver performance not found'};
      }

      // Get leaderboard to compare with peers
      final leaderboard = await getDriverLeaderboard(
        vendorId: vendorId,
        periodDays: periodDays,
        limit: 100,
      );

      // Find driver's position in leaderboard
      int driverRank = 0;
      for (int i = 0; i < leaderboard.length; i++) {
        if (leaderboard[i]['driver_id'] == driverId) {
          driverRank = i + 1;
          break;
        }
      }

      // Calculate averages for comparison
      double avgEarnings = leaderboard.fold(0.0, (sum, driver) => sum + ((driver['total_earnings'] as num?)?.toDouble() ?? 0)) / leaderboard.length;
      double avgSuccessRate = leaderboard.fold(0.0, (sum, driver) => sum + ((driver['success_rate'] as num?)?.toDouble() ?? 0)) / leaderboard.length;
      double avgRating = leaderboard.fold(0.0, (sum, driver) => sum + ((driver['average_rating'] as num?)?.toDouble() ?? 0)) / leaderboard.length;

      final result = {
        'driver_performance': driverPerformance,
        'driver_rank': driverRank,
        'total_drivers': leaderboard.length,
        'percentile': driverRank > 0 ? ((leaderboard.length - driverRank + 1) / leaderboard.length * 100).round() : 0,
        'peer_averages': {
          'earnings': avgEarnings,
          'success_rate': avgSuccessRate,
          'rating': avgRating,
        },
        'performance_vs_peers': {
          'earnings_difference': (driverPerformance['total_earnings'] as num).toDouble() - avgEarnings,
          'success_rate_difference': (driverPerformance['success_rate'] as num).toDouble() - avgSuccessRate,
          'rating_difference': (driverPerformance['average_rating'] as num).toDouble() - avgRating,
        },
      };

      debugPrint('DriverPerformanceService: Performance comparison calculated - Rank: $driverRank/${leaderboard.length}');
      return result;
    } catch (e) {
      debugPrint('DriverPerformanceService: Error getting performance comparison: $e');
      return {'error': 'Failed to calculate performance comparison'};
    }
  }

  /// Get driver performance goals and achievements
  Future<Map<String, dynamic>> getDriverGoalsAndAchievements(String driverId) async {
    try {
      debugPrint('DriverPerformanceService: Getting goals and achievements for driver: $driverId');

      // Get current month performance
      final currentMonth = await calculateDriverPerformance(
        driverId,
        startDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
        endDate: DateTime.now(),
      );

      if (currentMonth == null) {
        return {'goals': [], 'achievements': []};
      }

      // Define goals and check achievements
      final goals = [
        {
          'id': 'monthly_deliveries',
          'title': 'Monthly Deliveries',
          'description': 'Complete 100 deliveries this month',
          'target': 100,
          'current': currentMonth['successful_deliveries'],
          'progress': ((currentMonth['successful_deliveries'] as int) / 100 * 100).clamp(0, 100),
          'achieved': (currentMonth['successful_deliveries'] as int) >= 100,
        },
        {
          'id': 'success_rate',
          'title': 'Success Rate',
          'description': 'Maintain 95% success rate',
          'target': 95.0,
          'current': currentMonth['success_rate'],
          'progress': ((currentMonth['success_rate'] as num).toDouble() / 95 * 100).clamp(0, 100),
          'achieved': (currentMonth['success_rate'] as num).toDouble() >= 95,
        },
        {
          'id': 'average_rating',
          'title': 'Customer Rating',
          'description': 'Maintain 4.5+ star rating',
          'target': 4.5,
          'current': currentMonth['average_rating'],
          'progress': ((currentMonth['average_rating'] as num).toDouble() / 4.5 * 100).clamp(0, 100),
          'achieved': (currentMonth['average_rating'] as num).toDouble() >= 4.5,
        },
        {
          'id': 'monthly_earnings',
          'title': 'Monthly Earnings',
          'description': 'Earn RM 2000 this month',
          'target': 2000.0,
          'current': currentMonth['total_earnings'],
          'progress': ((currentMonth['total_earnings'] as num).toDouble() / 2000 * 100).clamp(0, 100),
          'achieved': (currentMonth['total_earnings'] as num).toDouble() >= 2000,
        },
      ];

      // Calculate achievements
      final achievements = goals.where((goal) => goal['achieved'] == true).map((goal) => {
        'id': goal['id'],
        'title': goal['title'],
        'description': goal['description'],
        'achieved_at': DateTime.now().toIso8601String(),
      }).toList();

      debugPrint('DriverPerformanceService: Goals and achievements calculated - ${achievements.length} achievements');
      return {
        'goals': goals,
        'achievements': achievements,
        'total_goals': goals.length,
        'achieved_goals': achievements.length,
        'completion_rate': (achievements.length / goals.length * 100).round(),
      };
    } catch (e) {
      debugPrint('DriverPerformanceService: Error getting goals and achievements: $e');
      return {'goals': [], 'achievements': []};
    }
  }
}
