import 'package:flutter/foundation.dart';

import 'base_repository.dart';
import '../models/driver.dart';

/// Repository for managing driver data and operations
class DriverRepository extends BaseRepository {
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
    required VehicleDetails vehicleDetails,
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
    VehicleDetails? vehicleDetails,
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
    required VehicleDetails vehicleDetails,
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
}
