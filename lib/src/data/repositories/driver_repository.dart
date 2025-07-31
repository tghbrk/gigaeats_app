// Import models
import '../../features/drivers/data/models/driver_order.dart';

// Import core services
import '../../core/utils/logger.dart';

// Import base repository
import 'base_repository.dart';

/// Repository for driver management operations
class DriverRepository extends BaseRepository {
  final AppLogger _logger = AppLogger();

  DriverRepository() : super();

  /// Get driver orders
  Future<List<DriverOrder>> getDriverOrders(String driverId, {
    DriverOrderStatus? status,
    int? limit,
    int? offset,
  }) async {
    return executeQuery(() async {
      _logger.info('🚚 [DRIVER-REPO] Getting orders for driver: $driverId');

      dynamic query = client
          .from('driver_orders')
          .select('''
            *,
            orders!inner(
              id, order_number, total_amount, payment_method,
              customers!inner(id, name, phone_number),
              vendors!inner(id, business_name, contact_phone, business_address)
            )
          ''')
          .eq('driver_id', driverId);

      if (status != null) {
        query = query.eq('status', status.value);
      }

      // Apply ordering first
      query = query.order('assigned_at', ascending: false);

      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 20) - 1);
      } else if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      final driverOrders = response.map((json) => DriverOrder.fromJson(json)).toList();
      
      _logger.info('✅ [DRIVER-REPO] Retrieved ${driverOrders.length} driver orders');
      return driverOrders;
    });
  }

  /// Get available orders for driver
  Future<List<DriverOrder>> getAvailableOrders(String driverId, {
    double? latitude,
    double? longitude,
    double? radiusKm,
  }) async {
    return executeQuery(() async {
      _logger.info('📋 [DRIVER-REPO] Getting available orders for driver: $driverId');

      dynamic query = client
          .from('driver_orders')
          .select('''
            *,
            orders!inner(
              id, order_number, total_amount, delivery_address,
              customers!inner(id, name, phone_number),
              vendors!inner(id, business_name, contact_phone, business_address)
            )
          ''')
          .eq('status', DriverOrderStatus.assigned.name)
          .isFilter('driver_id', null); // Unassigned orders

      // If location provided, filter by proximity
      if (latitude != null && longitude != null && radiusKm != null) {
        // This would require a custom RPC function for distance calculation
        final response = await client.rpc('get_nearby_driver_orders', params: {
          'driver_lat': latitude,
          'driver_lng': longitude,
          'radius_km': radiusKm,
        });
        
        final driverOrders = (response as List).map((json) => DriverOrder.fromJson(json)).toList();
        _logger.info('✅ [DRIVER-REPO] Retrieved ${driverOrders.length} nearby available orders');
        return driverOrders;
      }

      query = query.order('assigned_at', ascending: true);

      final response = await query;
      final driverOrders = response.map((json) => DriverOrder.fromJson(json)).toList();
      
      _logger.info('✅ [DRIVER-REPO] Retrieved ${driverOrders.length} available orders');
      return driverOrders;
    });
  }

  /// Accept order
  Future<void> acceptOrder(String driverOrderId, String driverId) async {
    return executeQuery(() async {
      _logger.info('✅ [DRIVER-REPO] Driver $driverId accepting order: $driverOrderId');

      await client
          .from('driver_orders')
          .update({
            'driver_id': driverId,
            'status': DriverOrderStatus.assigned.name,
            'accepted_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', driverOrderId);

      _logger.info('✅ [DRIVER-REPO] Order accepted successfully');
    });
  }

  /// Update order status
  Future<void> updateOrderStatus(String driverOrderId, DriverOrderStatus newStatus) async {
    return executeQuery(() async {
      _logger.info('🔄 [DRIVER-REPO] Updating order $driverOrderId status to ${newStatus.name}');

      final updateData = {
        'status': newStatus.value,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Add status-specific timestamps
      switch (newStatus) {
        case DriverOrderStatus.onRouteToVendor:
          updateData['started_route_at'] = DateTime.now().toIso8601String();
          break;
        case DriverOrderStatus.arrivedAtVendor:
          updateData['arrived_at_vendor_at'] = DateTime.now().toIso8601String();
          break;
        case DriverOrderStatus.pickedUp:
          updateData['picked_up_at'] = DateTime.now().toIso8601String();
          break;
        case DriverOrderStatus.onRouteToCustomer:
          updateData['started_delivery_at'] = DateTime.now().toIso8601String();
          break;
        case DriverOrderStatus.arrivedAtCustomer:
          updateData['arrived_at_customer_at'] = DateTime.now().toIso8601String();
          break;
        case DriverOrderStatus.delivered:
          updateData['actual_delivery_time'] = DateTime.now().toIso8601String();
          break;
        case DriverOrderStatus.cancelled:
        case DriverOrderStatus.failed:
          updateData['cancelled_at'] = DateTime.now().toIso8601String();
          break;
        default:
          break;
      }

      await client
          .from('driver_orders')
          .update(updateData)
          .eq('id', driverOrderId);

      _logger.info('✅ [DRIVER-REPO] Order status updated successfully');
    });
  }

  /// Update driver location
  Future<void> updateDriverLocation(String driverId, double latitude, double longitude, {
    double? accuracy,
    double? speed,
    double? heading,
  }) async {
    return executeQuery(() async {
      _logger.info('📍 [DRIVER-REPO] Updating location for driver: $driverId');

      final locationData = {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'speed': speed,
        'heading': heading,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Update driver's current location
      await client
          .from('drivers')
          .update({
            'current_location': locationData,
            'last_location_update': DateTime.now().toIso8601String(),
          })
          .eq('id', driverId);

      // Add to location tracking history
      await client
          .from('driver_location_history')
          .insert({
            'driver_id': driverId,
            ...locationData,
          });

      _logger.info('✅ [DRIVER-REPO] Driver location updated successfully');
    });
  }

  /// Add tracking point to order
  Future<void> addTrackingPoint(String driverOrderId, double latitude, double longitude, {
    double? accuracy,
    double? speed,
    double? heading,
  }) async {
    return executeQuery(() async {
      _logger.info('📍 [DRIVER-REPO] Adding tracking point for order: $driverOrderId');

      final trackingPoint = {
        'driver_order_id': driverOrderId,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'speed': speed,
        'heading': heading,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await client
          .from('driver_order_tracking')
          .insert(trackingPoint);

      // Update current location in driver order
      await client
          .from('driver_orders')
          .update({
            'current_location': {
              'latitude': latitude,
              'longitude': longitude,
              'timestamp': DateTime.now().toIso8601String(),
              'accuracy': accuracy,
              'speed': speed,
              'heading': heading,
            },
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', driverOrderId);

      _logger.info('✅ [DRIVER-REPO] Tracking point added successfully');
    });
  }

  /// Get driver statistics
  Future<Map<String, dynamic>> getDriverStatistics(String driverId) async {
    return executeQuery(() async {
      _logger.info('📊 [DRIVER-REPO] Getting statistics for driver: $driverId');

      final response = await client
          .rpc('get_driver_statistics', params: {'driver_id': driverId});

      _logger.info('✅ [DRIVER-REPO] Retrieved driver statistics');
      return response as Map<String, dynamic>;
    });
  }

  /// Get driver earnings
  Future<Map<String, dynamic>> getDriverEarnings(String driverId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return executeQuery(() async {
      _logger.info('💰 [DRIVER-REPO] Getting earnings for driver: $driverId');

      final params = {'driver_id': driverId};
      if (startDate != null) {
        params['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        params['end_date'] = endDate.toIso8601String();
      }

      final response = await client
          .rpc('get_driver_earnings', params: params);

      _logger.info('✅ [DRIVER-REPO] Retrieved driver earnings');
      return response as Map<String, dynamic>;
    });
  }

  /// Watch driver location for real-time updates
  Stream<Map<String, dynamic>?> watchDriverLocation(String driverId) {
    _logger.info('👁️ [DRIVER-REPO] Watching driver location: $driverId');

    return client
        .from('drivers')
        .stream(primaryKey: ['id'])
        .eq('id', driverId)
        .map((data) {
          if (data.isEmpty) return null;
          return data.first['current_location'] as Map<String, dynamic>?;
        });
  }

  /// Watch order tracking for real-time updates
  Stream<List<Map<String, dynamic>>> watchOrderTracking(String driverOrderId) {
    _logger.info('👁️ [DRIVER-REPO] Watching order tracking: $driverOrderId');

    return client
        .from('driver_order_tracking')
        .stream(primaryKey: ['id'])
        .eq('driver_order_id', driverOrderId)
        .order('timestamp', ascending: true)
        .map((data) => data.cast<Map<String, dynamic>>());
  }

  /// Report issue with order
  Future<void> reportOrderIssue(String driverOrderId, String issueType, String description) async {
    return executeQuery(() async {
      _logger.info('⚠️ [DRIVER-REPO] Reporting issue for order: $driverOrderId');

      await client
          .from('driver_order_issues')
          .insert({
            'driver_order_id': driverOrderId,
            'issue_type': issueType,
            'description': description,
            'reported_at': DateTime.now().toIso8601String(),
            'status': 'open',
          });

      _logger.info('✅ [DRIVER-REPO] Issue reported successfully');
    });
  }

  /// Complete delivery with proof
  Future<void> completeDelivery(String driverOrderId, {
    String? deliveryNotes,
    String? proofImageUrl,
    double? customerRating,
    String? customerFeedback,
  }) async {
    return executeQuery(() async {
      _logger.info('🎯 [DRIVER-REPO] Completing delivery for order: $driverOrderId');

      final updateData = {
        'status': DriverOrderStatus.delivered.name,
        'actual_delivery_time': DateTime.now().toIso8601String(),
        'delivery_notes': deliveryNotes,
        'proof_image_url': proofImageUrl,
        'customer_rating': customerRating,
        'customer_feedback': customerFeedback,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await client
          .from('driver_orders')
          .update(updateData)
          .eq('id', driverOrderId);

      _logger.info('✅ [DRIVER-REPO] Delivery completed successfully');
    });
  }
}
