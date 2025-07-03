import 'package:flutter/foundation.dart';

import '../../../../core/data/repositories/base_repository.dart';
import '../models/delivery_tracking.dart';

/// Repository for managing delivery tracking data and GPS operations
class DeliveryTrackingRepository extends BaseRepository {
  /// Record a new tracking point during delivery
  Future<DeliveryTracking> recordTrackingPoint({
    required String orderId,
    required String driverId,
    required double latitude,
    required double longitude,
    double? speed,
    double? heading,
    double? accuracy,
    Map<String, dynamic>? metadata,
  }) async {
    return executeQuery(() async {
      debugPrint('DeliveryTrackingRepository: Recording tracking point for order: $orderId');
      
      final trackingData = {
        'order_id': orderId,
        'driver_id': driverId,
        'location': 'POINT($longitude $latitude)', // PostGIS format
        'speed': speed,
        'heading': heading,
        'accuracy': accuracy,
        'metadata': metadata ?? {},
        'recorded_at': DateTime.now().toIso8601String(),
      };

      final response = await supabase
          .from('delivery_tracking')
          .insert(trackingData)
          .select()
          .single();

      debugPrint('DeliveryTrackingRepository: Tracking point recorded successfully');
      
      return DeliveryTracking.fromJson(response);
    });
  }

  /// Get tracking history for a specific order
  Future<List<DeliveryTracking>> getTrackingHistory(String orderId) async {
    return executeQuery(() async {
      debugPrint('DeliveryTrackingRepository: Getting tracking history for order: $orderId');
      
      final response = await supabase
          .from('delivery_tracking')
          .select()
          .eq('order_id', orderId)
          .order('recorded_at', ascending: true);

      debugPrint('DeliveryTrackingRepository: Found ${response.length} tracking points');
      
      return response.map((json) => DeliveryTracking.fromJson(json)).toList();
    });
  }

  /// Get latest tracking point for an order
  Future<DeliveryTracking?> getLatestTrackingPoint(String orderId) async {
    return executeQuery(() async {
      debugPrint('DeliveryTrackingRepository: Getting latest tracking point for order: $orderId');
      
      final response = await supabase
          .from('delivery_tracking')
          .select()
          .eq('order_id', orderId)
          .order('recorded_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        debugPrint('DeliveryTrackingRepository: No tracking points found');
        return null;
      }

      return DeliveryTracking.fromJson(response);
    });
  }

  /// Get tracking points for a driver within a time range
  Future<List<DeliveryTracking>> getDriverTrackingHistory({
    required String driverId,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    return executeQuery(() async {
      debugPrint('DeliveryTrackingRepository: Getting driver tracking history: $driverId');
      
      var query = supabase
          .from('delivery_tracking')
          .select()
          .eq('driver_id', driverId);

      if (startTime != null) {
        query = query.gte('recorded_at', startTime.toIso8601String());
      }
      
      if (endTime != null) {
        query = query.lte('recorded_at', endTime.toIso8601String());
      }

      final response = await query.order('recorded_at', ascending: true);
      
      debugPrint('DeliveryTrackingRepository: Found ${response.length} tracking points for driver');
      
      return response.map((json) => DeliveryTracking.fromJson(json)).toList();
    });
  }

  /// Get delivery route for an order
  Future<DeliveryRoute> getDeliveryRoute(String orderId) async {
    return executeQuery(() async {
      debugPrint('DeliveryTrackingRepository: Getting delivery route for order: $orderId');
      
      final trackingPoints = await getTrackingHistory(orderId);
      
      if (trackingPoints.isEmpty) {
        throw Exception('No tracking data found for order: $orderId');
      }

      // Get driver ID from first tracking point
      final driverId = trackingPoints.first.driverId;
      
      final route = DeliveryRoute.fromTrackingPoints(
        orderId: orderId,
        driverId: driverId,
        trackingPoints: trackingPoints,
      );

      debugPrint('DeliveryTrackingRepository: Route created with ${trackingPoints.length} points');
      
      return route;
    });
  }

  /// Stream real-time tracking updates for an order
  Stream<List<DeliveryTracking>> streamTrackingUpdates(String orderId) {
    debugPrint('DeliveryTrackingRepository: Starting tracking stream for order: $orderId');
    
    return supabase
        .from('delivery_tracking')
        .stream(primaryKey: ['id'])
        .map((data) {
          debugPrint('DeliveryTrackingRepository: Stream update received: ${data.length} points');
          // Filter for specific order
          final filteredData = data.where((json) => json['order_id'] == orderId).toList();
          return filteredData.map((json) => DeliveryTracking.fromJson(json)).toList();
        });
  }

  /// Get tracking statistics for a driver
  Future<Map<String, dynamic>> getDriverTrackingStats({
    required String driverId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return executeQuery(() async {
      debugPrint('DeliveryTrackingRepository: Getting tracking stats for driver: $driverId');
      
      var query = supabase
          .from('delivery_tracking')
          .select('speed, recorded_at')
          .eq('driver_id', driverId);

      if (startDate != null) {
        query = query.gte('recorded_at', startDate.toIso8601String());
      }
      
      if (endDate != null) {
        query = query.lte('recorded_at', endDate.toIso8601String());
      }

      final response = await query;
      
      if (response.isEmpty) {
        return {
          'total_points': 0,
          'average_speed': 0.0,
          'max_speed': 0.0,
          'total_time_hours': 0.0,
        };
      }

      // Calculate statistics
      final speeds = response
          .where((point) => point['speed'] != null)
          .map((point) => (point['speed'] as num).toDouble())
          .toList();

      final averageSpeed = speeds.isNotEmpty 
          ? speeds.reduce((a, b) => a + b) / speeds.length 
          : 0.0;
      
      final maxSpeed = speeds.isNotEmpty ? speeds.reduce((a, b) => a > b ? a : b) : 0.0;
      
      // Calculate total time from first to last point
      final times = response.map((point) => DateTime.parse(point['recorded_at'])).toList();
      times.sort();
      final totalTimeHours = times.length > 1 
          ? times.last.difference(times.first).inMinutes / 60.0 
          : 0.0;

      final stats = {
        'total_points': response.length,
        'average_speed': averageSpeed,
        'max_speed': maxSpeed,
        'total_time_hours': totalTimeHours,
      };

      debugPrint('DeliveryTrackingRepository: Tracking stats: $stats');
      
      return stats;
    });
  }

  /// Delete tracking data for an order (cleanup)
  Future<void> deleteTrackingData(String orderId) async {
    return executeQuery(() async {
      debugPrint('DeliveryTrackingRepository: Deleting tracking data for order: $orderId');
      
      await supabase
          .from('delivery_tracking')
          .delete()
          .eq('order_id', orderId);

      debugPrint('DeliveryTrackingRepository: Tracking data deleted successfully');
    });
  }

  /// Get nearby drivers based on location
  Future<List<Map<String, dynamic>>> getNearbyDrivers({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    String? vendorId,
  }) async {
    return executeQuery(() async {
      debugPrint('DeliveryTrackingRepository: Getting nearby drivers within ${radiusKm}km');
      
      // Use PostGIS ST_DWithin function for geospatial query
      final point = 'POINT($longitude $latitude)';
      final radiusMeters = radiusKm * 1000;
      
      var query = supabase
          .from('drivers')
          .select('''
            *,
            distance:ST_Distance(last_location, ST_GeomFromText('$point', 4326))
          ''')
          .eq('is_active', true)
          .eq('status', 'online')
          .not('last_location', 'is', null);

      if (vendorId != null) {
        query = query.eq('vendor_id', vendorId);
      }

      final response = await query;
      
      // Filter by distance in application layer (simpler than complex PostGIS query)
      final nearbyDrivers = response.where((driver) {
        final distance = driver['distance'] as num?;
        return distance != null && distance <= radiusMeters;
      }).toList();

      debugPrint('DeliveryTrackingRepository: Found ${nearbyDrivers.length} nearby drivers');
      
      return nearbyDrivers;
    });
  }

  /// Batch insert tracking points for efficiency
  Future<List<DeliveryTracking>> batchInsertTrackingPoints(
    List<Map<String, dynamic>> trackingData,
  ) async {
    return executeQuery(() async {
      debugPrint('DeliveryTrackingRepository: Batch inserting ${trackingData.length} tracking points');
      
      // Convert location data to PostGIS format
      final formattedData = trackingData.map((data) {
        final longitude = data['longitude'];
        final latitude = data['latitude'];
        return {
          ...data,
          'location': 'POINT($longitude $latitude)',
          'recorded_at': data['recorded_at'] ?? DateTime.now().toIso8601String(),
        }..remove('longitude')..remove('latitude');
      }).toList();

      final response = await supabase
          .from('delivery_tracking')
          .insert(formattedData)
          .select();

      debugPrint('DeliveryTrackingRepository: Batch insert completed successfully');
      
      return response.map((json) => DeliveryTracking.fromJson(json)).toList();
    });
  }
}
