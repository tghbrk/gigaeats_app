import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/order.dart';
import '../models/order_tracking_models.dart';
import '../../../core/utils/logger.dart';
import '../../../../core/services/notification_service.dart';

/// Enhanced order tracking service with real-time updates
class EnhancedOrderTrackingService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final NotificationService _notificationService = NotificationService();
  final AppLogger _logger = AppLogger();

  final Map<String, StreamController<OrderTrackingUpdate>> _trackingControllers = {};
  final Map<String, RealtimeChannel> _realtimeChannels = {};
  final Map<String, StreamSubscription> _subscriptions = {};

  /// Start tracking an order with real-time updates
  Stream<OrderTrackingUpdate> trackOrder(String orderId) {
    _logger.info('📍 [ORDER-TRACKING] Starting tracking for order: $orderId');

    // Return existing stream if already tracking
    if (_trackingControllers.containsKey(orderId)) {
      return _trackingControllers[orderId]!.stream;
    }

    // Create new tracking stream
    final controller = StreamController<OrderTrackingUpdate>.broadcast();
    _trackingControllers[orderId] = controller;

    // Setup real-time subscriptions
    _setupOrderSubscription(orderId);
    _setupDeliveryTrackingSubscription(orderId);
    _setupStatusHistorySubscription(orderId);

    // Get initial tracking data
    _getInitialTrackingData(orderId);

    return controller.stream;
  }

  /// Stop tracking an order
  void stopTracking(String orderId) {
    _logger.info('🛑 [ORDER-TRACKING] Stopping tracking for order: $orderId');

    // Close controller
    _trackingControllers[orderId]?.close();
    _trackingControllers.remove(orderId);

    // Unsubscribe from real-time updates
    _realtimeChannels[orderId]?.unsubscribe();
    _realtimeChannels.remove(orderId);

    // TODO: Restored proper subscription cleanup - cancel all subscriptions for this order
    // Cancel delivery tracking subscription
    _subscriptions['delivery_$orderId']?.cancel();
    _subscriptions.remove('delivery_$orderId');

    // Cancel status history subscription
    _subscriptions['history_$orderId']?.cancel();
    _subscriptions.remove('history_$orderId');
  }

  /// Get current order tracking status
  Future<OrderTrackingStatus> getOrderTrackingStatus(String orderId) async {
    try {
      _logger.info('📊 [ORDER-TRACKING] Getting tracking status for: $orderId');

      // Get order details
      final orderResponse = await _supabase
          .from('orders')
          .select('''
            *,
            vendor:vendors!orders_vendor_id_fkey(business_name, phone_number),
            driver:drivers!orders_assigned_driver_id_fkey(
              user:users!drivers_user_id_fkey(full_name, phone_number)
            )
          ''')
          .eq('id', orderId)
          .single();

      final order = Order.fromJson(orderResponse);

      // Get status history
      final statusHistory = await _getOrderStatusHistory(orderId);

      // Get delivery tracking if applicable
      DeliveryTracking? deliveryTracking;
      if (order.status == OrderStatus.outForDelivery || order.status == OrderStatus.delivered) {
        deliveryTracking = await _getLatestDeliveryTracking(orderId);
      }

      // Calculate progress
      final progress = _calculateOrderProgress(order.status);

      // Get estimated times
      final estimatedTimes = await _getEstimatedTimes(orderId, order);

      return OrderTrackingStatus(
        orderId: orderId,
        orderNumber: order.orderNumber,
        currentStatus: order.status,
        progress: progress,
        statusHistory: statusHistory,
        deliveryTracking: deliveryTracking,
        estimatedTimes: estimatedTimes,
        vendorInfo: OrderVendorInfo(
          name: order.vendorName,
          phone: orderResponse['vendor']?['phone_number'],
        ),
        customerInfo: OrderCustomerInfo(
          name: order.customerName,
          phone: orderResponse['customer']?['contact_person_name'],
        ),
        driverInfo: order.assignedDriverId != null
            ? OrderDriverInfo(
                name: orderResponse['driver']?['user']?['full_name'],
                phone: orderResponse['driver']?['user']?['phone_number'],
              )
            : null,
        lastUpdated: DateTime.now(),
      );

    } catch (e) {
      _logger.error('❌ [ORDER-TRACKING] Failed to get tracking status', e);
      throw Exception('Failed to get order tracking status: $e');
    }
  }

  /// Setup order status subscription
  void _setupOrderSubscription(String orderId) {
    final channel = _supabase
        .channel('order_tracking_$orderId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: orderId,
          ),
          callback: (payload) => _handleOrderUpdate(orderId, payload),
        )
        .subscribe();

    _realtimeChannels[orderId] = channel;
  }

  /// Setup delivery tracking subscription
  void _setupDeliveryTrackingSubscription(String orderId) {
    final subscription = _supabase
        .from('delivery_tracking')
        .stream(primaryKey: ['id'])
        .eq('order_id', orderId)
        .listen((data) => _handleDeliveryTrackingUpdate(orderId, data));

    _subscriptions['delivery_$orderId'] = subscription;
  }

  /// Setup status history subscription
  void _setupStatusHistorySubscription(String orderId) {
    final subscription = _supabase
        .from('order_status_history')
        .stream(primaryKey: ['id'])
        .eq('order_id', orderId)
        .listen((data) => _handleStatusHistoryUpdate(orderId, data));

    _subscriptions['history_$orderId'] = subscription;
  }

  /// Handle order update
  Future<void> _handleOrderUpdate(String orderId, PostgresChangePayload payload) async {
    try {
      _logger.info('📱 [ORDER-TRACKING] Order update received for: $orderId');

      final orderData = payload.newRecord;
      final oldOrderData = payload.oldRecord;

      final newStatus = OrderStatus.values.firstWhere(
        (status) => status.value == orderData['status'],
        orElse: () => OrderStatus.pending,
      );

      final oldStatus = OrderStatus.values.firstWhere(
        (status) => status.value == oldOrderData['status'],
        orElse: () => OrderStatus.pending,
      );

      // Create tracking update
      final update = OrderTrackingUpdate(
        orderId: orderId,
        type: OrderTrackingUpdateType.statusChange,
        newStatus: newStatus,
        oldStatus: oldStatus,
        message: _getStatusChangeMessage(newStatus),
        timestamp: DateTime.now(),
        data: orderData,
      );

      // Send to tracking stream
      _trackingControllers[orderId]?.add(update);

      // Send notification
      await _sendTrackingNotification(orderId, update);

      _logger.info('✅ [ORDER-TRACKING] Order update processed: ${newStatus.value}');

    } catch (e) {
      _logger.error('❌ [ORDER-TRACKING] Failed to handle order update', e);
    }
  }

  /// Handle delivery tracking update
  Future<void> _handleDeliveryTrackingUpdate(String orderId, List<Map<String, dynamic>> data) async {
    try {
      if (data.isEmpty) return;

      _logger.info('🚚 [ORDER-TRACKING] Delivery tracking update for: $orderId');

      final latestTracking = data.last;
      final deliveryTracking = DeliveryTracking.fromJson(latestTracking);

      final update = OrderTrackingUpdate(
        orderId: orderId,
        type: OrderTrackingUpdateType.locationUpdate,
        message: 'Driver location updated',
        timestamp: DateTime.now(),
        deliveryTracking: deliveryTracking,
      );

      _trackingControllers[orderId]?.add(update);

    } catch (e) {
      _logger.error('❌ [ORDER-TRACKING] Failed to handle delivery tracking update', e);
    }
  }

  /// Handle status history update
  Future<void> _handleStatusHistoryUpdate(String orderId, List<Map<String, dynamic>> data) async {
    try {
      if (data.isEmpty) return;

      _logger.info('📋 [ORDER-TRACKING] Status history update for: $orderId');

      final statusHistory = data.map((json) => OrderStatusHistoryEntry.fromJson(json)).toList();

      final update = OrderTrackingUpdate(
        orderId: orderId,
        type: OrderTrackingUpdateType.historyUpdate,
        message: 'Order history updated',
        timestamp: DateTime.now(),
        statusHistory: statusHistory,
      );

      _trackingControllers[orderId]?.add(update);

    } catch (e) {
      _logger.error('❌ [ORDER-TRACKING] Failed to handle status history update', e);
    }
  }

  /// Get initial tracking data
  Future<void> _getInitialTrackingData(String orderId) async {
    try {
      final trackingStatus = await getOrderTrackingStatus(orderId);

      final update = OrderTrackingUpdate(
        orderId: orderId,
        type: OrderTrackingUpdateType.initialData,
        newStatus: trackingStatus.currentStatus,
        message: 'Initial tracking data loaded',
        timestamp: DateTime.now(),
        trackingStatus: trackingStatus,
      );

      _trackingControllers[orderId]?.add(update);

    } catch (e) {
      _logger.error('❌ [ORDER-TRACKING] Failed to get initial tracking data', e);
    }
  }

  /// Get order status history
  Future<List<OrderStatusHistoryEntry>> _getOrderStatusHistory(String orderId) async {
    final response = await _supabase
        .from('order_status_history')
        .select()
        .eq('order_id', orderId)
        .order('created_at', ascending: true);

    return response.map((json) => OrderStatusHistoryEntry.fromJson(json)).toList();
  }

  /// Get latest delivery tracking
  Future<DeliveryTracking?> _getLatestDeliveryTracking(String orderId) async {
    try {
      final response = await _supabase
          .from('delivery_tracking')
          .select()
          .eq('order_id', orderId)
          .order('created_at', ascending: false)
          .limit(1)
          .single();

      return DeliveryTracking.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Calculate order progress percentage
  double _calculateOrderProgress(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 0.1;
      case OrderStatus.confirmed:
        return 0.2;
      case OrderStatus.preparing:
        return 0.4;
      case OrderStatus.ready:
        return 0.6;
      case OrderStatus.outForDelivery:
        return 0.8;
      case OrderStatus.delivered:
        return 1.0;
      case OrderStatus.cancelled:
        return 0.0;
    }
  }

  /// Get estimated times for order
  Future<OrderEstimatedTimes> _getEstimatedTimes(String orderId, Order order) async {
    // Calculate estimated times based on order data and current status
    final now = DateTime.now();
    
    DateTime? estimatedPreparation;
    DateTime? estimatedReady;
    DateTime? estimatedDelivery;

    switch (order.status) {
      case OrderStatus.pending:
      case OrderStatus.confirmed:
        estimatedPreparation = now.add(const Duration(minutes: 5));
        estimatedReady = now.add(const Duration(minutes: 25));
        estimatedDelivery = now.add(const Duration(minutes: 55));
        break;
      case OrderStatus.preparing:
        estimatedReady = now.add(const Duration(minutes: 20));
        estimatedDelivery = now.add(const Duration(minutes: 50));
        break;
      case OrderStatus.ready:
        estimatedDelivery = now.add(const Duration(minutes: 30));
        break;
      case OrderStatus.outForDelivery:
        estimatedDelivery = now.add(const Duration(minutes: 15));
        break;
      default:
        break;
    }

    return OrderEstimatedTimes(
      preparation: estimatedPreparation,
      ready: estimatedReady,
      delivery: estimatedDelivery,
    );
  }

  /// Get status change message
  String _getStatusChangeMessage(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Order received and pending confirmation';
      case OrderStatus.confirmed:
        return 'Order confirmed by restaurant';
      case OrderStatus.preparing:
        return 'Your order is being prepared';
      case OrderStatus.ready:
        return 'Order is ready for pickup/delivery';
      case OrderStatus.outForDelivery:
        return 'Order is out for delivery';
      case OrderStatus.delivered:
        return 'Order has been delivered';
      case OrderStatus.cancelled:
        return 'Order has been cancelled';
    }
  }

  /// Send tracking notification
  Future<void> _sendTrackingNotification(String orderId, OrderTrackingUpdate update) async {
    try {
      if (update.type == OrderTrackingUpdateType.statusChange && update.newStatus != null) {
        await _notificationService.sendOrderNotification(
          userId: 'current_user', // TODO: Get actual user ID
          orderId: orderId,
          title: 'Order Update',
          message: update.message,
          type: 'order_tracking',
        );
      }
    } catch (e) {
      _logger.warning('⚠️ [ORDER-TRACKING] Failed to send notification: $e');
    }
  }

  /// Dispose all tracking resources
  void dispose() {
    _logger.info('🧹 [ORDER-TRACKING] Disposing tracking service');

    // Close all controllers
    for (final controller in _trackingControllers.values) {
      controller.close();
    }
    _trackingControllers.clear();

    // Unsubscribe from all channels
    for (final channel in _realtimeChannels.values) {
      channel.unsubscribe();
    }
    _realtimeChannels.clear();

    // Cancel all subscriptions
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }
}
