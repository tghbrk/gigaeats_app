import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../user_management/domain/driver.dart';

/// Repository for driver-related operations
class DriverRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all drivers
  Future<List<Driver>> getDrivers({
    DriverStatus? status,
    bool? isActive,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabase
          .from('drivers')
          .select('*');

      if (status != null) {
        query = query.eq('status', status.name);
      }

      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map((json) => Driver.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch drivers: $e');
    }
  }

  /// Get driver by ID
  Future<Driver?> getDriverById(String driverId) async {
    try {
      final response = await _supabase
          .from('drivers')
          .select('*')
          .eq('id', driverId)
          .maybeSingle();

      if (response == null) return null;
      return Driver.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch driver: $e');
    }
  }

  /// Get driver by user ID
  Future<Driver?> getDriverByUserId(String userId) async {
    try {
      final response = await _supabase
          .from('drivers')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return Driver.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch driver by user ID: $e');
    }
  }

  /// Create driver
  Future<Driver> createDriver(Driver driver) async {
    try {
      final response = await _supabase
          .from('drivers')
          .insert(driver.toJson())
          .select()
          .single();

      return Driver.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create driver: $e');
    }
  }

  /// Update driver
  Future<Driver> updateDriver(Driver driver) async {
    try {
      final response = await _supabase
          .from('drivers')
          .update(driver.toJson())
          .eq('id', driver.id)
          .select()
          .single();

      return Driver.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update driver: $e');
    }
  }

  /// Delete driver
  Future<void> deleteDriver(String driverId) async {
    try {
      await _supabase
          .from('drivers')
          .delete()
          .eq('id', driverId);
    } catch (e) {
      throw Exception('Failed to delete driver: $e');
    }
  }

  /// Update driver status
  Future<void> updateDriverStatus(String driverId, DriverStatus status) async {
    try {
      await _supabase
          .from('drivers')
          .update({
            'status': status.name,
            'last_active_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', driverId);
    } catch (e) {
      throw Exception('Failed to update driver status: $e');
    }
  }

  /// Update driver location
  Future<void> updateDriverLocation({
    required String driverId,
    required double latitude,
    required double longitude,
    double? accuracy,
    double? speed,
    double? heading,
  }) async {
    try {
      await _supabase
          .from('drivers')
          .update({
            'current_latitude': latitude,
            'current_longitude': longitude,
            'last_location_update': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', driverId);

      // Also store in driver_locations table for history
      await _supabase
          .from('driver_locations')
          .insert({
            'driver_id': driverId,
            'latitude': latitude,
            'longitude': longitude,
            'accuracy': accuracy,
            'speed': speed,
            'heading': heading,
            'timestamp': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      throw Exception('Failed to update driver location: $e');
    }
  }

  /// Get available drivers
  Future<List<Driver>> getAvailableDrivers({
    double? latitude,
    double? longitude,
    double? radiusKm,
  }) async {
    try {
      var query = _supabase
          .from('drivers')
          .select('*')
          .eq('status', DriverStatus.online.name)
          .eq('is_active', true)
          .eq('is_verified', true);

      // TODO: Add geospatial filtering when PostGIS is available
      // For now, return all online drivers
      final response = await query.order('last_active_at', ascending: false);

      return response.map((json) => Driver.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch available drivers: $e');
    }
  }

  /// Get driver statistics
  Future<DriverStats> getDriverStats(String driverId) async {
    try {
      // Get orders for this driver
      final ordersResponse = await _supabase
          .from('orders')
          .select('id, total_amount, status, created_at, delivered_at')
          .eq('assigned_driver_id', driverId);

      final totalDeliveries = ordersResponse.length;
      final completedDeliveries = ordersResponse.where((o) => o['status'] == 'delivered').length;
      
      final completedOrders = ordersResponse.where((o) => o['status'] == 'delivered').toList();
      final totalEarnings = completedOrders.fold<double>(
        0, 
        (sum, order) => sum + ((order['total_amount'] as num).toDouble() * 0.1) // 10% commission
      );

      // Calculate time-based stats
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfMonth = DateTime(now.year, now.month, 1);

      final todayOrders = ordersResponse.where((o) {
        final orderDate = DateTime.parse(o['created_at']);
        return orderDate.isAfter(startOfDay);
      }).toList();

      final thisWeekOrders = ordersResponse.where((o) {
        final orderDate = DateTime.parse(o['created_at']);
        return orderDate.isAfter(startOfWeek);
      }).toList();

      final thisMonthOrders = ordersResponse.where((o) {
        final orderDate = DateTime.parse(o['created_at']);
        return orderDate.isAfter(startOfMonth);
      }).toList();

      // Calculate average delivery time
      double averageDeliveryTime = 0;
      if (completedOrders.isNotEmpty) {
        final totalDeliveryTime = completedOrders.fold<int>(0, (sum, order) {
          if (order['delivered_at'] != null) {
            final created = DateTime.parse(order['created_at']);
            final delivered = DateTime.parse(order['delivered_at']);
            return sum + delivered.difference(created).inMinutes;
          }
          return sum;
        });
        averageDeliveryTime = totalDeliveryTime / completedOrders.length;
      }

      return DriverStats(
        driverId: driverId,
        totalDeliveries: totalDeliveries,
        completedDeliveries: completedDeliveries,
        totalEarnings: totalEarnings,
        averageRating: 4.5, // TODO: Calculate from ratings
        averageDeliveryTime: averageDeliveryTime,
        todayDeliveries: todayOrders.length,
        todayEarnings: todayOrders.where((o) => o['status'] == 'delivered').fold<double>(
          0, (sum, order) => sum + ((order['total_amount'] as num).toDouble() * 0.1)
        ),
        thisWeekDeliveries: thisWeekOrders.length,
        thisWeekEarnings: thisWeekOrders.where((o) => o['status'] == 'delivered').fold<double>(
          0, (sum, order) => sum + ((order['total_amount'] as num).toDouble() * 0.1)
        ),
        thisMonthDeliveries: thisMonthOrders.length,
        thisMonthEarnings: thisMonthOrders.where((o) => o['status'] == 'delivered').fold<double>(
          0, (sum, order) => sum + ((order['total_amount'] as num).toDouble() * 0.1)
        ),
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to fetch driver stats: $e');
    }
  }

  /// Search drivers
  Future<List<Driver>> searchDrivers({
    required String query,
    DriverStatus? status,
    int limit = 20,
  }) async {
    try {
      var searchQuery = _supabase
          .from('drivers')
          .select('*')
          .or('full_name.ilike.%$query%,email.ilike.%$query%,phone_number.ilike.%$query%');

      if (status != null) {
        searchQuery = searchQuery.eq('status', status.name);
      }

      final response = await searchQuery
          .order('full_name')
          .limit(limit);

      return response.map((json) => Driver.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to search drivers: $e');
    }
  }
}
