import 'package:flutter/foundation.dart';

import '../../../../core/data/repositories/base_repository.dart';
import '../../user_management/domain/driver.dart';
import '../../../user_management/domain/driver.dart' as old_driver;
import '../models/driver_order.dart';

/// Repository for managing driver data and operations
class DriverRepository extends BaseRepository {
  /// Get all drivers across all vendors (admin function)
  Future<List<Driver>> getAllDrivers() async {
    return executeQuery(() async {
      debugPrint('DriverRepository: Getting all drivers');

      final response = await supabase
          .from('drivers')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      debugPrint('DriverRepository: Found ${response.length} drivers');

      return response.map((json) => Driver.fromJson(json)).toList();
    });
  }

  /// Get all driver statistics across all vendors (admin function)
  Future<Map<String, dynamic>> getAllDriverStatistics() async {
    return executeQuery(() async {
      debugPrint('DriverRepository: Getting all driver statistics');

      final response = await supabase
          .from('drivers')
          .select('status, vendor_id')
          .eq('is_active', true);

      final stats = <String, int>{
        'total': response.length,
        'online': 0,
        'offline': 0,
        'on_delivery': 0,
      };

      final vendorStats = <String, Map<String, int>>{};

      for (final driver in response) {
        final status = driver['status'] as String;
        final vendorId = driver['vendor_id'] as String;

        // Update global stats
        stats[status] = (stats[status] ?? 0) + 1;

        // Update vendor-specific stats
        if (!vendorStats.containsKey(vendorId)) {
          vendorStats[vendorId] = {
            'total': 0,
            'online': 0,
            'offline': 0,
            'on_delivery': 0,
          };
        }
        vendorStats[vendorId]!['total'] = vendorStats[vendorId]!['total']! + 1;
        vendorStats[vendorId]![status] = (vendorStats[vendorId]![status] ?? 0) + 1;
      }

      final result = {
        'global': stats,
        'by_vendor': vendorStats,
      };

      debugPrint('DriverRepository: All driver statistics: $result');

      return result;
    });
  }

  /// Get all drivers for a specific vendor
  Future<List<Driver>> getDriversForVendor(String vendorId) async {
    return executeQuery(() async {
      debugPrint('DriverRepository: Getting drivers for vendor: $vendorId');
      
      final response = await supabase
          .from('drivers')
          .select()
          .eq('vendor_id', vendorId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      debugPrint('DriverRepository: Found ${response.length} drivers');
      
      return response.map((json) => Driver.fromJson(json)).toList();
    });
  }

  /// Get available drivers for a vendor (online status)
  Future<List<Driver>> getAvailableDriversForVendor(String vendorId) async {
    return executeQuery(() async {
      debugPrint('DriverRepository: Getting available drivers for vendor: $vendorId');
      
      final response = await supabase
          .from('drivers')
          .select()
          .eq('vendor_id', vendorId)
          .eq('is_active', true)
          .eq('status', 'online')
          .order('last_seen', ascending: false);

      debugPrint('DriverRepository: Found ${response.length} available drivers');
      
      return response.map((json) => Driver.fromJson(json)).toList();
    });
  }

  /// Get a specific driver by ID
  Future<Driver?> getDriverById(String driverId) async {
    return executeQuery(() async {
      debugPrint('DriverRepository: Getting driver by ID: $driverId');
      
      final response = await supabase
          .from('drivers')
          .select()
          .eq('id', driverId)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) {
        debugPrint('DriverRepository: Driver not found');
        return null;
      }

      return Driver.fromJson(response);
    });
  }

  /// Create a new driver
  Future<Driver> createDriver({
    required String vendorId,
    required String name,
    required String phoneNumber,
    required old_driver.VehicleDetails vehicleDetails,
    String? userId,
  }) async {
    return executeQuery(() async {
      debugPrint('DriverRepository: Creating new driver: $name');
      
      final driverData = {
        'vendor_id': vendorId,
        'user_id': userId,
        'name': name.trim(),
        'phone_number': phoneNumber.trim(),
        'vehicle_details': vehicleDetails.toJsonB(),
        'status': 'offline',
        'is_active': true,
      };

      final response = await supabase
          .from('drivers')
          .insert(driverData)
          .select()
          .single();

      debugPrint('DriverRepository: Driver created successfully');
      
      return Driver.fromJson(response);
    });
  }

  /// Update driver information
  Future<Driver> updateDriver({
    required String driverId,
    String? name,
    String? phoneNumber,
    old_driver.VehicleDetails? vehicleDetails,
    DriverStatus? status,
  }) async {
    return executeQuery(() async {
      debugPrint('DriverRepository: Updating driver: $driverId');
      
      final updateData = <String, dynamic>{};
      
      if (name != null) updateData['name'] = name.trim();
      if (phoneNumber != null) updateData['phone_number'] = phoneNumber.trim();
      if (vehicleDetails != null) updateData['vehicle_details'] = vehicleDetails.toJsonB();
      if (status != null) updateData['status'] = status.name;
      
      if (updateData.isEmpty) {
        throw ArgumentError('No fields to update');
      }

      final response = await supabase
          .from('drivers')
          .update(updateData)
          .eq('id', driverId)
          .select()
          .single();

      debugPrint('DriverRepository: Driver updated successfully');
      
      return Driver.fromJson(response);
    });
  }

  /// Update driver status
  Future<void> updateDriverStatus(String driverId, DriverStatus status) async {
    return executeQuery(() async {
      debugPrint('DriverRepository: Updating driver status: $driverId -> ${status.name}');
      
      await supabase
          .from('drivers')
          .update({
            'status': status.name,
            'last_seen': DateTime.now().toIso8601String(),
          })
          .eq('id', driverId);

      debugPrint('DriverRepository: Driver status updated successfully');
    });
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
    return executeQuery(() async {
      debugPrint('DriverRepository: Updating driver location: $driverId');
      
      // Create PostGIS point
      final locationData = {
        'last_location': 'POINT($longitude $latitude)',
        'last_seen': DateTime.now().toIso8601String(),
      };

      await supabase
          .from('drivers')
          .update(locationData)
          .eq('id', driverId);

      debugPrint('DriverRepository: Driver location updated successfully');
    });
  }

  /// Soft delete a driver (set is_active to false)
  Future<void> deleteDriver(String driverId) async {
    return executeQuery(() async {
      debugPrint('DriverRepository: Soft deleting driver: $driverId');
      
      await supabase
          .from('drivers')
          .update({'is_active': false})
          .eq('id', driverId);

      debugPrint('DriverRepository: Driver soft deleted successfully');
    });
  }

  /// Get driver performance metrics for a specific date range
  Future<List<Map<String, dynamic>>> getDriverPerformance({
    required String driverId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return executeQuery(() async {
      debugPrint('DriverRepository: Getting driver performance: $driverId');

      var query = supabase
          .from('driver_performance')
          .select()
          .eq('driver_id', driverId);

      // Apply date filters if provided
      if (startDate != null) {
        final startDateStr = startDate.toIso8601String().split('T')[0];
        query = query.gte('date', startDateStr);
      }

      if (endDate != null) {
        final endDateStr = endDate.toIso8601String().split('T')[0];
        query = query.lte('date', endDateStr);
      }

      final response = await query.order('date', ascending: false);

      debugPrint('DriverRepository: Found ${response.length} performance records');

      return List<Map<String, dynamic>>.from(response);
    });
  }

  /// Get drivers with their current order assignments
  Future<List<Map<String, dynamic>>> getDriversWithCurrentOrders(String vendorId) async {
    return executeQuery(() async {
      debugPrint('DriverRepository: Getting drivers with current orders for vendor: $vendorId');
      
      final response = await supabase
          .from('drivers')
          .select('''
            *,
            current_order:orders!orders_assigned_driver_id_fkey(
              id,
              order_number,
              status,
              customer_name,
              delivery_address
            )
          ''')
          .eq('vendor_id', vendorId)
          .eq('is_active', true)
          .order('status', ascending: true); // Show on_delivery drivers first

      debugPrint('DriverRepository: Found ${response.length} drivers with order data');
      
      return List<Map<String, dynamic>>.from(response);
    });
  }

  /// Search drivers by name or phone number
  Future<List<Driver>> searchDrivers({
    required String vendorId,
    required String searchTerm,
  }) async {
    return executeQuery(() async {
      debugPrint('DriverRepository: Searching drivers: $searchTerm');
      
      final response = await supabase
          .from('drivers')
          .select()
          .eq('vendor_id', vendorId)
          .eq('is_active', true)
          .or('name.ilike.%$searchTerm%,phone_number.ilike.%$searchTerm%')
          .order('name', ascending: true);

      debugPrint('DriverRepository: Found ${response.length} matching drivers');
      
      return response.map((json) => Driver.fromJson(json)).toList();
    });
  }

  /// Get driver statistics for a vendor
  Future<Map<String, dynamic>> getDriverStatistics(String vendorId) async {
    return executeQuery(() async {
      debugPrint('DriverRepository: Getting driver statistics for vendor: $vendorId');
      
      final response = await supabase
          .from('drivers')
          .select('status')
          .eq('vendor_id', vendorId)
          .eq('is_active', true);

      final stats = <String, int>{
        'total': response.length,
        'online': 0,
        'offline': 0,
        'on_delivery': 0,
      };

      for (final driver in response) {
        final status = driver['status'] as String;
        stats[status] = (stats[status] ?? 0) + 1;
      }

      debugPrint('DriverRepository: Driver statistics: $stats');
      
      return stats;
    });
  }

  /// Stream driver status changes for real-time updates
  Stream<List<Driver>> streamDriversForVendor(String vendorId) {
    debugPrint('DriverRepository: Starting driver stream for vendor: $vendorId');

    return supabase
        .from('drivers')
        .stream(primaryKey: ['id'])
        .map((data) {
          debugPrint('DriverRepository: Stream update received: ${data.length} drivers');
          // Filter in memory since stream doesn't support eq() method
          final filteredData = data.where((json) =>
            json['vendor_id'] == vendorId &&
            json['is_active'] == true
          ).toList();
          return filteredData.map((json) => Driver.fromJson(json)).toList();
        });
  }

  /// Validate driver data before creation/update
  Future<void> validateDriverData({
    required String name,
    required String phoneNumber,
    required old_driver.VehicleDetails vehicleDetails,
    String? existingDriverId,
  }) async {
    // Validate name
    if (name.trim().length < 2) {
      throw ArgumentError('Driver name must be at least 2 characters long');
    }

    // Validate Malaysian phone number format
    final phoneRegex = RegExp(r'^\+60[0-9]{8,10}$');
    if (!phoneRegex.hasMatch(phoneNumber.trim())) {
      throw ArgumentError('Phone number must be in Malaysian format (+60xxxxxxxxx)');
    }

    // Validate vehicle details
    if (vehicleDetails.plateNumber.trim().isEmpty) {
      throw ArgumentError('Vehicle plate number is required');
    }

    // Check for duplicate phone number
    final existingDriver = await supabase
        .from('drivers')
        .select('id')
        .eq('phone_number', phoneNumber.trim())
        .eq('is_active', true)
        .maybeSingle();

    if (existingDriver != null && existingDriver['id'] != existingDriverId) {
      throw ArgumentError('A driver with this phone number already exists');
    }
  }

  /// Get driver orders for a specific driver
  Future<List<DriverOrder>> getDriverOrders(String driverId, {
    DriverOrderStatus? status,
    int? limit,
    int? offset,
  }) async {
    return executeQuery(() async {
      debugPrint('DriverRepository: Getting orders for driver: $driverId');

      dynamic query = supabase
          .from('driver_orders')
          .select('''
            *,
            orders!inner(
              id, order_number, total_amount, payment_method,
              customers!inner(id, contact_person_name, phone_number),
              vendors!inner(id, business_name, contact_phone, business_address)
            )
          ''')
          .eq('driver_id', driverId);

      if (status != null) {
        query = query.eq('status', status.name);
      }

      // Apply ordering first
      query = query.order('assigned_at', ascending: false);

      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 20) - 1);
      } else if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      debugPrint('DriverRepository: Found ${response.length} orders for driver');

      return response.map((json) => DriverOrder.fromJson(json)).toList();
    });
  }

  /// Watch driver location for real-time updates
  Stream<Map<String, dynamic>?> watchDriverLocation(String driverId) {
    debugPrint('DriverRepository: Watching driver location: $driverId');

    return supabase
        .from('drivers')
        .stream(primaryKey: ['id'])
        .eq('id', driverId)
        .map((data) {
          if (data.isEmpty) return null;
          return data.first['current_location'] as Map<String, dynamic>?;
        });
  }
}
