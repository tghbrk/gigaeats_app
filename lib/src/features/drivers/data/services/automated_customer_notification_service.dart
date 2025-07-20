import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/batch_operation_results.dart';
import '../models/notification_models.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/utils/logger.dart';

/// Automated customer notification service for Phase 4.2
/// Provides intelligent, context-aware notifications for multi-order delivery batches
class AutomatedCustomerNotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final NotificationService _notificationService = NotificationService();
  final AppLogger _logger = AppLogger();

  // Notification templates
  static const Map<String, NotificationTemplate> _templates = {
    'batch_assigned': NotificationTemplate(
      id: 'batch_assigned',
      title: 'Your order is being prepared',
      body: 'Your driver {driverName} has been assigned and will collect your order from {vendorName}.',
      type: NotificationType.orderUpdate,
      priority: NotificationPriority.normal,
    ),
    'driver_en_route_pickup': NotificationTemplate(
      id: 'driver_en_route_pickup',
      title: 'Driver heading to restaurant',
      body: '{driverName} is on the way to {vendorName} to collect your order. ETA: {eta}',
      type: NotificationType.driverUpdate,
      priority: NotificationPriority.normal,
    ),
    'order_picked_up': NotificationTemplate(
      id: 'order_picked_up',
      title: 'Order picked up!',
      body: '{driverName} has collected your order from {vendorName} and is heading your way.',
      type: NotificationType.orderUpdate,
      priority: NotificationPriority.high,
    ),
    'driver_en_route_delivery': NotificationTemplate(
      id: 'driver_en_route_delivery',
      title: 'Your order is on the way',
      body: '{driverName} is heading to your location. ETA: {eta}. Track your order in real-time.',
      type: NotificationType.driverUpdate,
      priority: NotificationPriority.high,
    ),
    'driver_nearby': NotificationTemplate(
      id: 'driver_nearby',
      title: 'Driver is nearby',
      body: '{driverName} is just {distance} away from your location. Please be ready to receive your order.',
      type: NotificationType.driverUpdate,
      priority: NotificationPriority.urgent,
    ),
    'order_delivered': NotificationTemplate(
      id: 'order_delivered',
      title: 'Order delivered!',
      body: 'Your order has been successfully delivered. Enjoy your meal! Please rate your experience.',
      type: NotificationType.orderUpdate,
      priority: NotificationPriority.normal,
    ),
    'delivery_delayed': NotificationTemplate(
      id: 'delivery_delayed',
      title: 'Delivery update',
      body: 'Your order is running {delayMinutes} minutes behind schedule due to {reason}. New ETA: {newEta}',
      type: NotificationType.delayAlert,
      priority: NotificationPriority.high,
    ),
    'batch_optimized': NotificationTemplate(
      id: 'batch_optimized',
      title: 'Delivery optimized',
      body: 'Good news! We\'ve optimized your delivery route. Your order will arrive {timeSaved} minutes earlier.',
      type: NotificationType.orderUpdate,
      priority: NotificationPriority.normal,
    ),
  };

  /// Initialize the notification service
  Future<void> initialize() async {
    debugPrint('📱 [AUTO-NOTIFICATIONS] Initializing automated customer notification service');
    
    try {
      await _notificationService.initialize();
      debugPrint('📱 [AUTO-NOTIFICATIONS] Automated notification service initialized successfully');
    } catch (e) {
      _logger.logError('Failed to initialize automated notification service', e);
      rethrow;
    }
  }

  /// Send batch assignment notifications to all customers in the batch
  Future<void> notifyBatchAssignment({
    required String batchId,
    required String driverId,
    required String driverName,
    required List<BatchOrderWithDetails> orders,
  }) async {
    debugPrint('📱 [AUTO-NOTIFICATIONS] Sending batch assignment notifications for batch: $batchId');
    
    try {
      final notifications = <Future<void>>[];
      
      for (final orderWithDetails in orders) {
        final order = orderWithDetails.order;
        
        final notification = _createNotification(
          template: _templates['batch_assigned']!,
          customerId: order.customerId,
          orderId: order.id,
          variables: {
            'driverName': driverName,
            'vendorName': order.vendorName,
            'orderNumber': order.orderNumber,
          },
        );
        
        notifications.add(_sendNotification(notification));
      }
      
      await Future.wait(notifications);
      
      // Record analytics event
      await _recordNotificationEvent(
        eventType: 'batch_assignment_notifications_sent',
        batchId: batchId,
        driverId: driverId,
        orderCount: orders.length,
      );
      
      debugPrint('📱 [AUTO-NOTIFICATIONS] Batch assignment notifications sent successfully');
    } catch (e) {
      _logger.logError('Failed to send batch assignment notifications', e);
    }
  }

  /// Send driver en route to pickup notifications
  Future<void> notifyDriverEnRouteToPickup({
    required String batchId,
    required String driverId,
    required String driverName,
    required List<BatchOrderWithDetails> orders,
    required Duration estimatedArrival,
  }) async {
    debugPrint('📱 [AUTO-NOTIFICATIONS] Sending driver en route to pickup notifications');
    
    try {
      final notifications = <Future<void>>[];
      final eta = _formatETA(estimatedArrival);
      
      for (final orderWithDetails in orders) {
        final order = orderWithDetails.order;
        
        final notification = _createNotification(
          template: _templates['driver_en_route_pickup']!,
          customerId: order.customerId,
          orderId: order.id,
          variables: {
            'driverName': driverName,
            'vendorName': order.vendorName,
            'eta': eta,
          },
        );
        
        notifications.add(_sendNotification(notification));
      }
      
      await Future.wait(notifications);
      
      debugPrint('📱 [AUTO-NOTIFICATIONS] Driver en route to pickup notifications sent');
    } catch (e) {
      _logger.logError('Failed to send driver en route notifications', e);
    }
  }

  /// Send order picked up notifications
  Future<void> notifyOrderPickedUp({
    required String orderId,
    required String customerId,
    required String driverName,
    required String vendorName,
  }) async {
    debugPrint('📱 [AUTO-NOTIFICATIONS] Sending order picked up notification for: $orderId');
    
    try {
      final notification = _createNotification(
        template: _templates['order_picked_up']!,
        customerId: customerId,
        orderId: orderId,
        variables: {
          'driverName': driverName,
          'vendorName': vendorName,
        },
      );
      
      await _sendNotification(notification);
      
      debugPrint('📱 [AUTO-NOTIFICATIONS] Order picked up notification sent');
    } catch (e) {
      _logger.logError('Failed to send order picked up notification', e);
    }
  }

  /// Send driver en route to delivery notifications
  Future<void> notifyDriverEnRouteToDelivery({
    required String orderId,
    required String customerId,
    required String driverName,
    required Duration estimatedArrival,
  }) async {
    debugPrint('📱 [AUTO-NOTIFICATIONS] Sending driver en route to delivery notification');
    
    try {
      final eta = _formatETA(estimatedArrival);
      
      final notification = _createNotification(
        template: _templates['driver_en_route_delivery']!,
        customerId: customerId,
        orderId: orderId,
        variables: {
          'driverName': driverName,
          'eta': eta,
        },
      );
      
      await _sendNotification(notification);
      
      debugPrint('📱 [AUTO-NOTIFICATIONS] Driver en route to delivery notification sent');
    } catch (e) {
      _logger.logError('Failed to send driver en route to delivery notification', e);
    }
  }

  /// Send driver nearby notifications
  Future<void> notifyDriverNearby({
    required String orderId,
    required String customerId,
    required String driverName,
    required double distanceMeters,
  }) async {
    debugPrint('📱 [AUTO-NOTIFICATIONS] Sending driver nearby notification');
    
    try {
      final distance = _formatDistance(distanceMeters);
      
      final notification = _createNotification(
        template: _templates['driver_nearby']!,
        customerId: customerId,
        orderId: orderId,
        variables: {
          'driverName': driverName,
          'distance': distance,
        },
      );
      
      await _sendNotification(notification);
      
      debugPrint('📱 [AUTO-NOTIFICATIONS] Driver nearby notification sent');
    } catch (e) {
      _logger.logError('Failed to send driver nearby notification', e);
    }
  }

  /// Send order delivered notifications
  Future<void> notifyOrderDelivered({
    required String orderId,
    required String customerId,
  }) async {
    debugPrint('📱 [AUTO-NOTIFICATIONS] Sending order delivered notification');
    
    try {
      final notification = _createNotification(
        template: _templates['order_delivered']!,
        customerId: customerId,
        orderId: orderId,
        variables: {},
      );
      
      await _sendNotification(notification);
      
      debugPrint('📱 [AUTO-NOTIFICATIONS] Order delivered notification sent');
    } catch (e) {
      _logger.logError('Failed to send order delivered notification', e);
    }
  }

  /// Send delivery delay notifications
  Future<void> notifyDeliveryDelay({
    required String orderId,
    required String customerId,
    required Duration delayDuration,
    required String reason,
    required Duration newETA,
  }) async {
    debugPrint('📱 [AUTO-NOTIFICATIONS] Sending delivery delay notification');
    
    try {
      final notification = _createNotification(
        template: _templates['delivery_delayed']!,
        customerId: customerId,
        orderId: orderId,
        variables: {
          'delayMinutes': delayDuration.inMinutes.toString(),
          'reason': reason,
          'newEta': _formatETA(newETA),
        },
      );
      
      await _sendNotification(notification);
      
      debugPrint('📱 [AUTO-NOTIFICATIONS] Delivery delay notification sent');
    } catch (e) {
      _logger.logError('Failed to send delivery delay notification', e);
    }
  }

  /// Send batch optimization notifications
  Future<void> notifyBatchOptimization({
    required String batchId,
    required List<String> customerIds,
    required Duration timeSaved,
  }) async {
    debugPrint('📱 [AUTO-NOTIFICATIONS] Sending batch optimization notifications');
    
    try {
      final notifications = <Future<void>>[];
      
      for (final customerId in customerIds) {
        final notification = _createNotification(
          template: _templates['batch_optimized']!,
          customerId: customerId,
          orderId: null,
          variables: {
            'timeSaved': timeSaved.inMinutes.toString(),
          },
        );
        
        notifications.add(_sendNotification(notification));
      }
      
      await Future.wait(notifications);
      
      debugPrint('📱 [AUTO-NOTIFICATIONS] Batch optimization notifications sent');
    } catch (e) {
      _logger.logError('Failed to send batch optimization notifications', e);
    }
  }

  /// Create a notification from template
  CustomerNotification _createNotification({
    required NotificationTemplate template,
    required String customerId,
    required String? orderId,
    required Map<String, String> variables,
  }) {
    String title = template.title;
    String body = template.body;
    
    // Replace variables in title and body
    variables.forEach((key, value) {
      title = title.replaceAll('{$key}', value);
      body = body.replaceAll('{$key}', value);
    });
    
    return CustomerNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      customerId: customerId,
      orderId: orderId,
      title: title,
      body: body,
      type: template.type,
      priority: template.priority,
      data: variables,
      timestamp: DateTime.now(),
    );
  }

  /// Send notification to customer
  Future<void> _sendNotification(CustomerNotification notification) async {
    try {
      // Send via notification service
      await _notificationService.sendOrderNotification(
        userId: notification.customerId,
        orderId: notification.orderId ?? '',
        title: notification.title,
        message: notification.body,
        type: notification.type.name,
      );
      
      // Store in database for tracking
      await _supabase.from('customer_notifications').insert({
        'id': notification.id,
        'customer_id': notification.customerId,
        'order_id': notification.orderId,
        'title': notification.title,
        'body': notification.body,
        'type': notification.type.name,
        'priority': notification.priority.name,
        'data': notification.data,
        'sent_at': notification.timestamp.toIso8601String(),
        'is_read': false,
      });
      
    } catch (e) {
      _logger.logError('Failed to send notification', e);
      rethrow;
    }
  }

  /// Record notification analytics event
  Future<void> _recordNotificationEvent({
    required String eventType,
    required String batchId,
    required String driverId,
    required int orderCount,
  }) async {
    try {
      await _supabase.from('notification_analytics').insert({
        'event_type': eventType,
        'batch_id': batchId,
        'driver_id': driverId,
        'order_count': orderCount,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _logger.logError('Failed to record notification event', e);
    }
  }

  /// Format ETA duration
  String _formatETA(Duration duration) {
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes} minutes';
    } else {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
  }

  /// Format distance
  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()}m';
    } else {
      final km = meters / 1000;
      return '${km.toStringAsFixed(1)}km';
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    debugPrint('📱 [AUTO-NOTIFICATIONS] Disposing automated notification service');
    // Cleanup if needed
  }
}
