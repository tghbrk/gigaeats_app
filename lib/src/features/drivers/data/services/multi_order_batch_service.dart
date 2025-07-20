import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/delivery_batch.dart';
import '../models/batch_operation_results.dart';
import '../../../orders/data/models/order.dart';

/// Service for managing multi-order batch operations
/// Handles batch creation, order assignment, status management, and optimization
class MultiOrderBatchService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Configuration constants
  static const int _defaultMaxOrders = 3;
  static const double _defaultMaxDeviationKm = 5.0;
  static const double _maxDistanceBetweenOrdersKm = 10.0;

  /// Create a new delivery batch with optimized order assignment
  Future<BatchCreationResult> createOptimizedBatch({
    required String driverId,
    required List<String> orderIds,
    int maxOrders = _defaultMaxOrders,
    double maxDeviationKm = _defaultMaxDeviationKm,
  }) async {
    try {
      debugPrint('🚛 [BATCH-SERVICE] Creating optimized batch for driver: $driverId');
      debugPrint('🚛 [BATCH-SERVICE] Order IDs: $orderIds');
      debugPrint('🚛 [BATCH-SERVICE] Max orders: $maxOrders, Max deviation: ${maxDeviationKm}km');

      // 1. Validate input parameters
      if (orderIds.isEmpty) {
        return BatchCreationResult.failure('No orders provided for batch creation');
      }

      if (orderIds.length > maxOrders) {
        return BatchCreationResult.failure('Too many orders for batch (max: $maxOrders)');
      }

      // 2. Validate driver availability
      final driverValidation = await _validateDriverAvailability(driverId);
      if (!driverValidation.isValid) {
        return BatchCreationResult.failure(driverValidation.errorMessage ?? 'Driver validation failed');
      }

      // 3. Validate orders are eligible for batching
      final orderValidation = await _validateOrdersForBatching(orderIds, maxDeviationKm);
      if (!orderValidation.isValid) {
        return BatchCreationResult.failure(orderValidation.errorMessage ?? 'Order validation failed');
      }

      // 4. Get driver location for route optimization
      final driverLocation = await _getDriverLocation(driverId);
      if (driverLocation == null) {
        return BatchCreationResult.failure('Unable to determine driver location');
      }

      // 5. Calculate optimized route and sequences
      final routeOptimization = await _calculateOptimizedRoute(
        orderIds: orderIds,
        driverLocation: driverLocation,
        maxDeviationKm: maxDeviationKm,
      );

      if (!routeOptimization.isSuccess) {
        return BatchCreationResult.failure(routeOptimization.errorMessage ?? 'Route optimization failed');
      }

      // 6. Create batch in database
      final batch = await _createBatchInDatabase(
        driverId: driverId,
        orderIds: orderIds,
        routeOptimization: routeOptimization,
        maxOrders: maxOrders,
        maxDeviationKm: maxDeviationKm,
      );

      debugPrint('✅ [BATCH-SERVICE] Batch created successfully: ${batch.id}');
      return BatchCreationResult.success(batch);

    } catch (e) {
      debugPrint('❌ [BATCH-SERVICE] Error creating batch: $e');
      return BatchCreationResult.failure('Failed to create batch: ${e.toString()}');
    }
  }

  /// Get active batch for driver
  Future<DeliveryBatch?> getActiveBatchForDriver(String driverId) async {
    try {
      debugPrint('🚛 [BATCH-SERVICE] Getting active batch for driver: $driverId');

      final response = await _supabase
          .from('delivery_batches')
          .select()
          .eq('driver_id', driverId)
          .inFilter('status', ['planned', 'active', 'paused'])
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isEmpty) {
        debugPrint('📭 [BATCH-SERVICE] No active batch found for driver');
        return null;
      }

      final batch = DeliveryBatch.fromJson(response.first);
      debugPrint('✅ [BATCH-SERVICE] Found active batch: ${batch.id}');
      return batch;

    } catch (e) {
      debugPrint('❌ [BATCH-SERVICE] Error getting active batch: $e');
      return null;
    }
  }

  /// Get batch orders with full order details
  Future<List<BatchOrderWithDetails>> getBatchOrdersWithDetails(String batchId) async {
    try {
      debugPrint('🚛 [BATCH-SERVICE] Getting batch orders for batch: $batchId');

      final response = await _supabase
          .from('batch_orders')
          .select('''
            *,
            order:orders!batch_orders_order_id_fkey(
              *,
              vendor:vendors!orders_vendor_id_fkey(business_name, address),
              order_items:order_items(*)
            )
          ''')
          .eq('batch_id', batchId)
          .order('pickup_sequence', ascending: true);

      final batchOrders = response.map((json) {
        final batchOrder = BatchOrder.fromJson(json);
        final order = Order.fromJson(json['order']);
        return BatchOrderWithDetails(batchOrder: batchOrder, order: order);
      }).toList();

      debugPrint('✅ [BATCH-SERVICE] Retrieved ${batchOrders.length} batch orders');
      return batchOrders;

    } catch (e) {
      debugPrint('❌ [BATCH-SERVICE] Error getting batch orders: $e');
      return [];
    }
  }

  /// Start batch execution
  Future<BatchOperationResult> startBatch(String batchId) async {
    try {
      debugPrint('🚛 [BATCH-SERVICE] Starting batch: $batchId');

      final updateResponse = await _supabase
          .from('delivery_batches')
          .update({
            'status': 'active',
            'actual_start_time': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', batchId)
          .eq('status', 'planned') // Only start if currently planned
          .select();

      if (updateResponse.isEmpty) {
        return BatchOperationResult.failure('Batch cannot be started (may already be active)');
      }

      // Update all orders in batch to assigned status
      await _updateBatchOrdersStatus(batchId, 'assigned');

      debugPrint('✅ [BATCH-SERVICE] Batch started successfully');
      return BatchOperationResult.success('Batch started successfully');

    } catch (e) {
      debugPrint('❌ [BATCH-SERVICE] Error starting batch: $e');
      return BatchOperationResult.failure('Failed to start batch: ${e.toString()}');
    }
  }

  /// Pause batch execution
  Future<BatchOperationResult> pauseBatch(String batchId) async {
    try {
      debugPrint('🚛 [BATCH-SERVICE] Pausing batch: $batchId');

      final updateResponse = await _supabase
          .from('delivery_batches')
          .update({
            'status': 'paused',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', batchId)
          .eq('status', 'active') // Only pause if currently active
          .select();

      if (updateResponse.isEmpty) {
        return BatchOperationResult.failure('Batch cannot be paused (may not be active)');
      }

      debugPrint('✅ [BATCH-SERVICE] Batch paused successfully');
      return BatchOperationResult.success('Batch paused successfully');

    } catch (e) {
      debugPrint('❌ [BATCH-SERVICE] Error pausing batch: $e');
      return BatchOperationResult.failure('Failed to pause batch: ${e.toString()}');
    }
  }

  /// Resume batch execution
  Future<BatchOperationResult> resumeBatch(String batchId) async {
    try {
      debugPrint('🚛 [BATCH-SERVICE] Resuming batch: $batchId');

      final updateResponse = await _supabase
          .from('delivery_batches')
          .update({
            'status': 'active',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', batchId)
          .eq('status', 'paused') // Only resume if currently paused
          .select();

      if (updateResponse.isEmpty) {
        return BatchOperationResult.failure('Batch cannot be resumed (may not be paused)');
      }

      debugPrint('✅ [BATCH-SERVICE] Batch resumed successfully');
      return BatchOperationResult.success('Batch resumed successfully');

    } catch (e) {
      debugPrint('❌ [BATCH-SERVICE] Error resuming batch: $e');
      return BatchOperationResult.failure('Failed to resume batch: ${e.toString()}');
    }
  }

  /// Complete batch execution
  Future<BatchOperationResult> completeBatch(String batchId) async {
    try {
      debugPrint('🚛 [BATCH-SERVICE] Completing batch: $batchId');

      // Check if all orders in batch are delivered
      final batchOrders = await getBatchOrdersWithDetails(batchId);
      final undeliveredOrders = batchOrders.where((bo) => !bo.batchOrder.isDeliveryCompleted).toList();

      if (undeliveredOrders.isNotEmpty) {
        return BatchOperationResult.failure('Cannot complete batch: ${undeliveredOrders.length} orders not yet delivered');
      }

      final updateResponse = await _supabase
          .from('delivery_batches')
          .update({
            'status': 'completed',
            'actual_completion_time': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', batchId)
          .inFilter('status', ['active', 'paused'])
          .select();

      if (updateResponse.isEmpty) {
        return BatchOperationResult.failure('Batch cannot be completed');
      }

      debugPrint('✅ [BATCH-SERVICE] Batch completed successfully');
      return BatchOperationResult.success('Batch completed successfully');

    } catch (e) {
      debugPrint('❌ [BATCH-SERVICE] Error completing batch: $e');
      return BatchOperationResult.failure('Failed to complete batch: ${e.toString()}');
    }
  }

  /// Cancel batch execution
  Future<BatchOperationResult> cancelBatch(String batchId, String reason) async {
    try {
      debugPrint('🚛 [BATCH-SERVICE] Cancelling batch: $batchId, Reason: $reason');

      // Update batch status
      final updateResponse = await _supabase
          .from('delivery_batches')
          .update({
            'status': 'cancelled',
            'updated_at': DateTime.now().toIso8601String(),
            'metadata': {'cancellation_reason': reason},
          })
          .eq('id', batchId)
          .inFilter('status', ['planned', 'active', 'paused'])
          .select();

      if (updateResponse.isEmpty) {
        return BatchOperationResult.failure('Batch cannot be cancelled');
      }

      // Reset orders back to ready status
      await _resetBatchOrdersToReady(batchId);

      debugPrint('✅ [BATCH-SERVICE] Batch cancelled successfully');
      return BatchOperationResult.success('Batch cancelled successfully');

    } catch (e) {
      debugPrint('❌ [BATCH-SERVICE] Error cancelling batch: $e');
      return BatchOperationResult.failure('Failed to cancel batch: ${e.toString()}');
    }
  }

  /// Update batch order pickup status
  Future<BatchOperationResult> updateBatchOrderPickupStatus({
    required String batchId,
    required String orderId,
    required BatchOrderPickupStatus status,
  }) async {
    try {
      debugPrint('🚛 [BATCH-SERVICE] Updating pickup status for order $orderId to ${status.displayName}');

      final updateData = <String, dynamic>{
        'pickup_status': status.name,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (status == BatchOrderPickupStatus.completed) {
        updateData['actual_pickup_time'] = DateTime.now().toIso8601String();
      }

      final updateResponse = await _supabase
          .from('batch_orders')
          .update(updateData)
          .eq('batch_id', batchId)
          .eq('order_id', orderId)
          .select();

      if (updateResponse.isEmpty) {
        return BatchOperationResult.failure('Failed to update pickup status');
      }

      debugPrint('✅ [BATCH-SERVICE] Pickup status updated successfully');
      return BatchOperationResult.success('Pickup status updated successfully');

    } catch (e) {
      debugPrint('❌ [BATCH-SERVICE] Error updating pickup status: $e');
      return BatchOperationResult.failure('Failed to update pickup status: ${e.toString()}');
    }
  }

  /// Update batch order delivery status
  Future<BatchOperationResult> updateBatchOrderDeliveryStatus({
    required String batchId,
    required String orderId,
    required BatchOrderDeliveryStatus status,
  }) async {
    try {
      debugPrint('🚛 [BATCH-SERVICE] Updating delivery status for order $orderId to ${status.displayName}');

      final updateData = <String, dynamic>{
        'delivery_status': status.name,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (status == BatchOrderDeliveryStatus.completed) {
        updateData['actual_delivery_time'] = DateTime.now().toIso8601String();
      }

      final updateResponse = await _supabase
          .from('batch_orders')
          .update(updateData)
          .eq('batch_id', batchId)
          .eq('order_id', orderId)
          .select();

      if (updateResponse.isEmpty) {
        return BatchOperationResult.failure('Failed to update delivery status');
      }

      // If this was the last order to be delivered, check if batch can be completed
      if (status == BatchOrderDeliveryStatus.completed) {
        await _checkBatchCompletion(batchId);
      }

      debugPrint('✅ [BATCH-SERVICE] Delivery status updated successfully');
      return BatchOperationResult.success('Delivery status updated successfully');

    } catch (e) {
      debugPrint('❌ [BATCH-SERVICE] Error updating delivery status: $e');
      return BatchOperationResult.failure('Failed to update delivery status: ${e.toString()}');
    }
  }

  // Private helper methods

  /// Validate driver availability for batch creation
  Future<ValidationResult> _validateDriverAvailability(String driverId) async {
    try {
      // Check if driver exists and is active
      final driverResponse = await _supabase
          .from('drivers')
          .select('id, status, is_active')
          .eq('id', driverId)
          .single();

      if (!driverResponse['is_active']) {
        return ValidationResult.invalid('Driver is not active');
      }

      // Check if driver already has an active batch
      final activeBatch = await getActiveBatchForDriver(driverId);
      if (activeBatch != null) {
        return ValidationResult.invalid('Driver already has an active batch');
      }

      return ValidationResult.valid();
    } catch (e) {
      return ValidationResult.invalid('Driver not found or unavailable');
    }
  }

  /// Validate orders are eligible for batching
  Future<ValidationResult> _validateOrdersForBatching(List<String> orderIds, double maxDeviationKm) async {
    try {
      // Get order details
      final ordersResponse = await _supabase
          .from('orders')
          .select('''
            id, status, delivery_address, vendor_id, assigned_driver_id,
            vendor:vendors!orders_vendor_id_fkey(address)
          ''')
          .inFilter('id', orderIds);

      if (ordersResponse.length != orderIds.length) {
        return ValidationResult.invalid('Some orders not found');
      }

      final orders = ordersResponse.map((json) => Order.fromJson(json)).toList();

      // Check all orders are ready and unassigned
      for (final order in orders) {
        if (order.status != OrderStatus.ready) {
          return ValidationResult.invalid('Order ${order.id} is not ready for pickup');
        }
        if (order.assignedDriverId != null) {
          return ValidationResult.invalid('Order ${order.id} is already assigned to a driver');
        }
      }

      // Check geographical proximity
      final proximityValidation = await _validateOrderProximity(orders, maxDeviationKm);
      if (!proximityValidation.isValid) {
        return proximityValidation;
      }

      return ValidationResult.valid();
    } catch (e) {
      return ValidationResult.invalid('Error validating orders: ${e.toString()}');
    }
  }

  /// Validate orders are geographically close enough for batching
  Future<ValidationResult> _validateOrderProximity(List<Order> orders, double maxDeviationKm) async {
    if (orders.length < 2) return ValidationResult.valid();

    try {
      // Calculate distances between all order pairs
      for (int i = 0; i < orders.length; i++) {
        for (int j = i + 1; j < orders.length; j++) {
          final order1 = orders[i];
          final order2 = orders[j];

          // Check vendor proximity (using delivery address as approximation)
          // TODO: Get actual vendor coordinates from vendor table
          final vendorDistance = _calculateDistance(
            order1.deliveryAddress.latitude ?? 3.1390,
            order1.deliveryAddress.longitude ?? 101.6869,
            order2.deliveryAddress.latitude ?? 3.1390,
            order2.deliveryAddress.longitude ?? 101.6869,
          );

          if (vendorDistance > _maxDistanceBetweenOrdersKm) {
            return ValidationResult.invalid('Vendors are too far apart (${vendorDistance.toStringAsFixed(1)}km)');
          }

          // Check delivery address proximity
          final deliveryDistance = _calculateDistance(
            order1.deliveryAddress.latitude ?? 0,
            order1.deliveryAddress.longitude ?? 0,
            order2.deliveryAddress.latitude ?? 0,
            order2.deliveryAddress.longitude ?? 0,
          );

          if (deliveryDistance > maxDeviationKm) {
            return ValidationResult.invalid('Delivery addresses are too far apart (${deliveryDistance.toStringAsFixed(1)}km)');
          }
        }
      }

      return ValidationResult.valid();
    } catch (e) {
      return ValidationResult.invalid('Error validating proximity: ${e.toString()}');
    }
  }

  /// Get driver's current location
  Future<LatLng?> _getDriverLocation(String driverId) async {
    try {
      final locationResponse = await _supabase
          .from('driver_locations')
          .select('latitude, longitude')
          .eq('driver_id', driverId)
          .order('updated_at', ascending: false)
          .limit(1);

      if (locationResponse.isEmpty) {
        return null;
      }

      final location = locationResponse.first;
      return LatLng(
        location['latitude'].toDouble(),
        location['longitude'].toDouble(),
      );
    } catch (e) {
      debugPrint('❌ [BATCH-SERVICE] Error getting driver location: $e');
      return null;
    }
  }

  /// Calculate optimized route for batch orders
  Future<RouteOptimizationResult> _calculateOptimizedRoute({
    required List<String> orderIds,
    required LatLng driverLocation,
    required double maxDeviationKm,
  }) async {
    try {
      // Get full order details
      final ordersResponse = await _supabase
          .from('orders')
          .select('*')
          .inFilter('id', orderIds);

      final orders = ordersResponse.map((json) => Order.fromJson(json)).toList();

      // Simple optimization: sort by vendor proximity, then by delivery proximity
      final optimizedSequence = _calculateSimpleOptimizedSequence(orders, driverLocation);

      // Calculate route metrics
      final routeMetrics = await _calculateRouteMetrics(optimizedSequence, driverLocation);

      return RouteOptimizationResult.success(
        pickupSequence: optimizedSequence.map((order) => order.id).toList(),
        deliverySequence: optimizedSequence.map((order) => order.id).toList(),
        totalDistanceKm: routeMetrics.totalDistanceKm,
        estimatedDurationMinutes: routeMetrics.estimatedDurationMinutes,
        optimizationScore: routeMetrics.optimizationScore,
      );
    } catch (e) {
      return RouteOptimizationResult.failure('Route optimization failed: ${e.toString()}');
    }
  }

  /// Calculate simple optimized sequence (nearest neighbor approach)
  List<Order> _calculateSimpleOptimizedSequence(List<Order> orders, LatLng driverLocation) {
    if (orders.length <= 1) return orders;

    final optimized = <Order>[];
    final remaining = List<Order>.from(orders);
    LatLng currentLocation = driverLocation;

    // Greedy nearest neighbor algorithm
    while (remaining.isNotEmpty) {
      Order? nearest;
      double nearestDistance = double.infinity;

      for (final order in remaining) {
        // TODO: Get actual vendor coordinates from vendor table
        // For now, use delivery address as approximation
        final vendorLat = order.deliveryAddress.latitude ?? 3.1390; // Default to KL
        final vendorLng = order.deliveryAddress.longitude ?? 101.6869;
        final distance = _calculateDistance(
          currentLocation.latitude,
          currentLocation.longitude,
          vendorLat,
          vendorLng,
        );

        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearest = order;
        }
      }

      if (nearest != null) {
        optimized.add(nearest);
        remaining.remove(nearest);
        currentLocation = LatLng(
          nearest.deliveryAddress.latitude ?? 3.1390,
          nearest.deliveryAddress.longitude ?? 101.6869,
        );
      }
    }

    return optimized;
  }

  /// Calculate route metrics
  Future<RouteMetrics> _calculateRouteMetrics(List<Order> orders, LatLng driverLocation) async {
    double totalDistance = 0;
    int estimatedDuration = 0;
    LatLng currentLocation = driverLocation;

    // Calculate pickup route
    for (final order in orders) {
      // TODO: Get actual vendor coordinates from vendor table
      final vendorLat = order.deliveryAddress.latitude ?? 3.1390;
      final vendorLng = order.deliveryAddress.longitude ?? 101.6869;

      final distance = _calculateDistance(
        currentLocation.latitude,
        currentLocation.longitude,
        vendorLat,
        vendorLng,
      );

      totalDistance += distance;
      estimatedDuration += (distance / 40 * 60).round(); // Assume 40 km/h average speed

      currentLocation = LatLng(vendorLat, vendorLng);
    }

    // Calculate delivery route
    for (final order in orders) {
      final deliveryLat = order.deliveryAddress.latitude ?? 0;
      final deliveryLng = order.deliveryAddress.longitude ?? 0;

      final distance = _calculateDistance(
        currentLocation.latitude,
        currentLocation.longitude,
        deliveryLat,
        deliveryLng,
      );

      totalDistance += distance;
      estimatedDuration += (distance / 40 * 60).round();

      currentLocation = LatLng(deliveryLat, deliveryLng);
    }

    // Calculate optimization score (simplified)
    final optimizationScore = max(0.0, 100.0 - (totalDistance * 2)); // Penalize longer routes

    return RouteMetrics(
      totalDistanceKm: totalDistance,
      estimatedDurationMinutes: estimatedDuration,
      optimizationScore: optimizationScore,
    );
  }

  /// Calculate distance between two points in kilometers
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000;
  }

  /// Create batch in database
  Future<DeliveryBatch> _createBatchInDatabase({
    required String driverId,
    required List<String> orderIds,
    required RouteOptimizationResult routeOptimization,
    required int maxOrders,
    required double maxDeviationKm,
  }) async {
    final batchId = _generateBatchId();
    final batchNumber = _generateBatchNumber();
    final now = DateTime.now();

    // Create batch record
    final batchData = {
      'id': batchId,
      'driver_id': driverId,
      'batch_number': batchNumber,
      'status': 'planned',
      'total_distance_km': routeOptimization.totalDistanceKm,
      'estimated_duration_minutes': routeOptimization.estimatedDurationMinutes,
      'optimization_score': routeOptimization.optimizationScore,
      'max_orders': maxOrders,
      'max_deviation_km': maxDeviationKm,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };

    await _supabase.from('delivery_batches').insert(batchData);

    // Create batch order records
    final batchOrdersData = <Map<String, dynamic>>[];
    for (int i = 0; i < orderIds.length; i++) {
      final orderId = orderIds[i];
      batchOrdersData.add({
        'id': _generateBatchOrderId(),
        'batch_id': batchId,
        'order_id': orderId,
        'pickup_sequence': i + 1,
        'delivery_sequence': i + 1, // Simplified: same sequence for now
        'pickup_status': 'pending',
        'delivery_status': 'pending',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
    }

    await _supabase.from('batch_orders').insert(batchOrdersData);

    // Update orders to assigned status
    await _updateBatchOrdersStatus(batchId, 'assigned');

    return DeliveryBatch(
      id: batchId,
      driverId: driverId,
      batchNumber: batchNumber,
      status: BatchStatus.planned,
      totalDistanceKm: routeOptimization.totalDistanceKm,
      estimatedDurationMinutes: routeOptimization.estimatedDurationMinutes,
      optimizationScore: routeOptimization.optimizationScore,
      maxOrders: maxOrders,
      maxDeviationKm: maxDeviationKm,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Update batch orders status
  Future<void> _updateBatchOrdersStatus(String batchId, String status) async {
    // Get order IDs from batch
    final batchOrdersResponse = await _supabase
        .from('batch_orders')
        .select('order_id')
        .eq('batch_id', batchId);

    final orderIds = batchOrdersResponse.map((row) => row['order_id'] as String).toList();

    if (orderIds.isNotEmpty) {
      await _supabase
          .from('orders')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .inFilter('id', orderIds);
    }
  }

  /// Reset batch orders to ready status
  Future<void> _resetBatchOrdersToReady(String batchId) async {
    // Get order IDs from batch
    final batchOrdersResponse = await _supabase
        .from('batch_orders')
        .select('order_id')
        .eq('batch_id', batchId);

    final orderIds = batchOrdersResponse.map((row) => row['order_id'] as String).toList();

    if (orderIds.isNotEmpty) {
      await _supabase
          .from('orders')
          .update({
            'status': 'ready',
            'assigned_driver_id': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .inFilter('id', orderIds);
    }
  }

  /// Check if batch can be completed
  Future<void> _checkBatchCompletion(String batchId) async {
    final batchOrders = await getBatchOrdersWithDetails(batchId);
    final allDelivered = batchOrders.every((bo) => bo.batchOrder.isDeliveryCompleted);

    if (allDelivered) {
      await completeBatch(batchId);
    }
  }

  /// Generate unique batch ID
  String _generateBatchId() {
    return 'batch_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  /// Generate batch number
  String _generateBatchNumber() {
    final now = DateTime.now();
    return 'B${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${Random().nextInt(9999).toString().padLeft(4, '0')}';
  }

  /// Generate unique batch order ID
  String _generateBatchOrderId() {
    return 'bo_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }
}
