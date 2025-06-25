import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../vendors/data/models/driver.dart';
import '../models/driver_dashboard_data.dart';
import '../models/driver_order.dart';
import '../repositories/driver_order_repository.dart';
import 'driver_performance_service.dart';

/// Service for aggregating driver dashboard data
/// Combines data from multiple sources to provide comprehensive dashboard information
class DriverDashboardService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final DriverPerformanceService _performanceService = DriverPerformanceService();
  final DriverOrderRepository _orderRepository = DriverOrderRepository();

  /// Get comprehensive dashboard data for a driver
  Future<DriverDashboardData> getDashboardData(String driverId) async {
    try {
      debugPrint('DriverDashboardService: Getting dashboard data for driver: $driverId');

      // Fetch data concurrently for better performance
      final futures = await Future.wait([
        _getDriverStatus(driverId),
        _getActiveOrders(driverId),
        _getTodaysSummary(driverId),
        _getPerformanceMetrics(driverId),
      ]);

      final driverStatusData = futures[0] as Map<String, dynamic>;
      final activeOrders = futures[1] as List<DriverOrder>;
      final todaysSummary = futures[2] as DriverTodaySummary;
      final performanceMetrics = futures[3] as DriverPerformanceMetrics?;

      final dashboardData = DriverDashboardData(
        driverStatus: DriverStatus.fromString(driverStatusData['status'] ?? 'offline'),
        isOnline: driverStatusData['status'] == 'online' || driverStatusData['status'] == 'on_delivery',
        activeOrders: activeOrders,
        todaySummary: todaysSummary,
        performanceMetrics: performanceMetrics,
        lastUpdated: DateTime.now(),
      );

      debugPrint('DriverDashboardService: Dashboard data retrieved successfully');
      return dashboardData;
    } catch (e) {
      debugPrint('DriverDashboardService: Error getting dashboard data: $e');
      return DriverDashboardData.empty();
    }
  }

  /// Get driver status information
  Future<Map<String, dynamic>> _getDriverStatus(String driverId) async {
    try {
      final response = await _supabase
          .from('drivers')
          .select('status, last_seen, is_active')
          .eq('id', driverId)
          .single();

      return response;
    } catch (e) {
      debugPrint('DriverDashboardService: Error getting driver status: $e');
      return {
        'status': 'offline',
        'last_seen': null,
        'is_active': false,
      };
    }
  }

  /// Get active orders for the driver
  Future<List<DriverOrder>> _getActiveOrders(String driverId) async {
    try {
      final orders = await _orderRepository.getDriverOrders(driverId);

      // Filter for active orders only
      return orders.where((order) =>
        order.status == DriverOrderStatus.assigned ||
        order.status == DriverOrderStatus.onRouteToVendor ||
        order.status == DriverOrderStatus.arrivedAtVendor ||
        order.status == DriverOrderStatus.pickedUp ||
        order.status == DriverOrderStatus.onRouteToCustomer ||
        order.status == DriverOrderStatus.arrivedAtCustomer
      ).toList();
    } catch (e) {
      debugPrint('DriverDashboardService: Error getting active orders: $e');
      return [];
    }
  }

  /// Get today's performance summary
  Future<DriverTodaySummary> _getTodaysSummary(String driverId) async {
    try {
      debugPrint('DriverDashboardService: Getting today\'s summary for driver: $driverId');

      // Get today's performance directly from the database
      final today = DateTime.now();
      final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final response = await _supabase
          .from('driver_performance')
          .select('*')
          .eq('driver_id', driverId)
          .eq('date', todayString)
          .maybeSingle();

      if (response != null) {
        debugPrint('DriverDashboardService: Found today\'s performance data');

        final completedDeliveries = (response['completed_deliveries'] as num?)?.toInt() ?? 0;
        final totalDeliveries = (response['total_deliveries'] as num?)?.toInt() ?? 0;
        final ratingSum = (response['rating_sum'] as num?)?.toDouble() ?? 0.0;
        final ratingCount = (response['rating_count'] as num?)?.toInt() ?? 0;

        // Calculate earnings from completed deliveries (assuming average delivery fee)
        final estimatedEarnings = completedDeliveries * 8.0; // Rough estimate

        // Calculate success rate
        final successRate = totalDeliveries > 0 ? (completedDeliveries / totalDeliveries) * 100 : 0.0;

        // Calculate average rating
        final averageRating = ratingCount > 0 ? ratingSum / ratingCount : 0.0;

        return DriverTodaySummary(
          deliveriesCompleted: completedDeliveries,
          earningsToday: estimatedEarnings,
          successRate: successRate,
          averageRating: averageRating,
          totalOrders: totalDeliveries,
        );
      }

      debugPrint('DriverDashboardService: No performance data found for today, returning empty summary');
      return DriverTodaySummary.empty();
    } catch (e) {
      debugPrint('DriverDashboardService: Error getting today\'s summary: $e');
      return DriverTodaySummary.empty();
    }
  }

  /// Get performance metrics
  Future<DriverPerformanceMetrics?> _getPerformanceMetrics(String driverId) async {
    try {
      // Since driver_performance_summary table doesn't exist, calculate from driver_performance
      final now = DateTime.now();

      // Get weekly performance (last 7 days)
      final weekStart = now.subtract(const Duration(days: 7));
      final weeklyData = await _performanceService.getDriverEarnings(
        driverId,
        startDate: weekStart,
        endDate: now,
      );

      // Get monthly performance (last 30 days)
      final monthStart = now.subtract(const Duration(days: 30));
      final monthlyData = await _performanceService.getDriverEarnings(
        driverId,
        startDate: monthStart,
        endDate: now,
      );

      // Get overall performance
      final overallData = await _performanceService.getDriverEarnings(driverId);

      return DriverPerformanceMetrics(
        weeklyDeliveries: (weeklyData['successful_deliveries'] as num?)?.toInt() ?? 0,
        weeklyEarnings: (weeklyData['total_earnings'] as num?)?.toDouble() ?? 0.0,
        monthlyDeliveries: (monthlyData['successful_deliveries'] as num?)?.toInt() ?? 0,
        monthlyEarnings: (monthlyData['total_earnings'] as num?)?.toDouble() ?? 0.0,
        overallRating: 0.0, // Will be calculated from performance data
        overallSuccessRate: (overallData['success_rate'] as num?)?.toDouble() ?? 0.0,
      );
    } catch (e) {
      debugPrint('DriverDashboardService: Error getting performance metrics: $e');
      return null;
    }
  }

  /// Update driver online status
  Future<bool> updateDriverStatus(String driverId, DriverStatus status) async {
    try {
      debugPrint('DriverDashboardService: Updating driver status to: ${status.name}');
      debugPrint('DriverDashboardService: Driver ID: $driverId');
      debugPrint('DriverDashboardService: Current auth user: ${_supabase.auth.currentUser?.id}');

      final response = await _supabase
          .from('drivers')
          .update({
            'status': status.name,
            'last_seen': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', driverId)
          .select();

      debugPrint('DriverDashboardService: Update response: $response');

      if (response.isEmpty) {
        debugPrint('DriverDashboardService: No rows were updated - possible RLS policy issue');
        return false;
      }

      debugPrint('DriverDashboardService: Driver status updated successfully');
      return true;
    } catch (e) {
      debugPrint('DriverDashboardService: Error updating driver status: $e');
      return false;
    }
  }

  /// Get driver ID from user ID with automatic driver profile creation
  Future<String?> getDriverIdFromUserId(String userId) async {
    try {
      debugPrint('DriverDashboardService: Looking up driver ID for user: $userId');

      final response = await _supabase
          .from('drivers')
          .select('id, user_id, name, is_active')
          .eq('user_id', userId)
          .single();

      final driverId = response['id'] as String;
      debugPrint('DriverDashboardService: Found driver ID: $driverId for user: $userId');
      debugPrint('DriverDashboardService: Driver details - name: ${response['name']}, active: ${response['is_active']}');
      return driverId;
    } catch (e) {
      debugPrint('DriverDashboardService: Error getting driver ID for user $userId: $e');

      // Check if this is a missing driver record issue
      if (e.toString().contains('PGRST116') || e.toString().contains('0 rows')) {
        debugPrint('DriverDashboardService: No driver record found, attempting to create one');

        // Try to create missing driver record
        final createdDriverId = await _createMissingDriverRecord(userId);
        if (createdDriverId != null) {
          debugPrint('DriverDashboardService: Successfully created driver record: $createdDriverId');
          return createdDriverId;
        }
      }

      // Additional debugging: Check if driver exists at all
      try {
        final checkResponse = await _supabase
            .from('drivers')
            .select('id, user_id, name, is_active')
            .eq('user_id', userId);

        debugPrint('DriverDashboardService: Driver check query returned ${checkResponse.length} rows');
        if (checkResponse.isNotEmpty) {
          debugPrint('DriverDashboardService: Driver exists but single() failed - this suggests RLS policy issue');
          for (final driver in checkResponse) {
            debugPrint('DriverDashboardService: Found driver: ${driver['id']} for user: ${driver['user_id']}');
          }
        } else {
          debugPrint('DriverDashboardService: No driver record found for user: $userId');
        }
      } catch (checkError) {
        debugPrint('DriverDashboardService: Error in driver existence check: $checkError');
      }

      return null;
    }
  }

  /// Create missing driver record for a user
  Future<String?> _createMissingDriverRecord(String userId) async {
    try {
      debugPrint('DriverDashboardService: Creating missing driver record for user: $userId');

      // Get user information
      final userResponse = await _supabase
          .from('users')
          .select('id, email, full_name, phone_number, role')
          .eq('id', userId)
          .single();

      final userFullName = userResponse['full_name'] as String? ?? 'Driver User';
      final userPhoneNumber = userResponse['phone_number'] as String? ?? '';
      final userRole = userResponse['role'] as String;

      // Verify user has driver role
      if (userRole != 'driver') {
        debugPrint('DriverDashboardService: User does not have driver role: $userRole');
        return null;
      }

      // Create driver record
      final driverResponse = await _supabase.from('drivers').insert({
        'user_id': userId,
        'name': userFullName,
        'phone_number': userPhoneNumber,
        'status': 'offline',
        'is_active': true,
        'vehicle_details': {
          'type': 'motorcycle',
          'plateNumber': '',
          'color': '',
          'brand': '',
          'model': '',
          'year': '',
        },
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select('id').single();

      final driverId = driverResponse['id'] as String;
      debugPrint('DriverDashboardService: Created driver record with ID: $driverId');

      return driverId;
    } catch (e) {
      debugPrint('DriverDashboardService: Error creating missing driver record: $e');

      // If creation fails due to foreign key constraint, try linking to existing unlinked driver
      if (e.toString().contains('foreign key') || e.toString().contains('auth.users')) {
        debugPrint('DriverDashboardService: Foreign key constraint issue, trying to link to existing driver');
        return await _linkToExistingUnlinkedDriver(userId);
      }

      return null;
    }
  }

  /// Link user to an existing unlinked driver record
  Future<String?> _linkToExistingUnlinkedDriver(String userId) async {
    try {
      debugPrint('DriverDashboardService: Looking for unlinked driver to link to user: $userId');

      // Get user information
      final userResponse = await _supabase
          .from('users')
          .select('full_name, phone_number')
          .eq('id', userId)
          .single();

      final userFullName = userResponse['full_name'] as String? ?? '';
      final userPhoneNumber = userResponse['phone_number'] as String? ?? '';

      // Look for unlinked drivers with matching name or phone
      final unlinkedDrivers = await _supabase
          .from('drivers')
          .select('id, name, phone_number')
          .isFilter('user_id', null);

      // Try to find a matching driver
      String? matchingDriverId;
      for (final driver in unlinkedDrivers) {
        final driverName = driver['name'] as String? ?? '';
        final driverPhone = driver['phone_number'] as String? ?? '';

        if (driverName.toLowerCase().contains(userFullName.toLowerCase()) ||
            (userPhoneNumber.isNotEmpty && driverPhone == userPhoneNumber)) {
          matchingDriverId = driver['id'] as String;
          debugPrint('DriverDashboardService: Found matching unlinked driver: $matchingDriverId');
          break;
        }
      }

      // If no matching driver found, use the temporary driver we created earlier
      if (matchingDriverId == null && unlinkedDrivers.isNotEmpty) {
        // Use the most recently created unlinked driver
        matchingDriverId = unlinkedDrivers.last['id'] as String;
        debugPrint('DriverDashboardService: Using most recent unlinked driver: $matchingDriverId');
      }

      if (matchingDriverId != null) {
        // Update the driver record to link to the user
        await _supabase
            .from('drivers')
            .update({
              'user_id': userId,
              'name': userFullName.isNotEmpty ? userFullName : 'Driver User',
              'phone_number': userPhoneNumber,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', matchingDriverId);

        debugPrint('DriverDashboardService: Successfully linked driver $matchingDriverId to user $userId');
        return matchingDriverId;
      }

      debugPrint('DriverDashboardService: No suitable unlinked driver found');
      return null;
    } catch (e) {
      debugPrint('DriverDashboardService: Error linking to existing driver: $e');
      return null;
    }
  }

  /// Refresh dashboard data (invalidates cache if any)
  Future<DriverDashboardData> refreshDashboardData(String driverId) async {
    debugPrint('DriverDashboardService: Refreshing dashboard data for driver: $driverId');
    return getDashboardData(driverId);
  }
}
