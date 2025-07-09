import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/driver_order.dart';
import '../../../notifications/data/services/realtime_notification_service.dart';

/// Comprehensive notification service for the enhanced driver workflow
/// Handles real-time notifications for all stakeholders throughout the 7-step workflow
class DriverWorkflowNotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final RealtimeNotificationService _notificationService = RealtimeNotificationService();

  /// Send notifications for all workflow status changes
  Future<void> notifyWorkflowStatusChange({
    required String orderId,
    required DriverOrderStatus fromStatus,
    required DriverOrderStatus toStatus,
    required String driverId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      debugPrint('📱 [DRIVER-WORKFLOW-NOTIFICATIONS] Processing notifications for: $fromStatus → $toStatus');

      // Get order details for notification context
      final orderDetails = await _getOrderDetails(orderId);
      if (orderDetails == null) {
        debugPrint('❌ [DRIVER-WORKFLOW-NOTIFICATIONS] Order not found: $orderId');
        return;
      }

      // Send status-specific notifications
      switch (toStatus) {
        case DriverOrderStatus.assigned:
          await _notifyOrderAssigned(orderDetails, driverId);
          break;
        case DriverOrderStatus.onRouteToVendor:
          await _notifyDriverEnRouteToVendor(orderDetails, driverId);
          break;
        case DriverOrderStatus.arrivedAtVendor:
          await _notifyDriverArrivedAtVendor(orderDetails, driverId);
          break;
        case DriverOrderStatus.pickedUp:
          await _notifyOrderPickedUp(orderDetails, driverId, additionalData);
          break;
        case DriverOrderStatus.onRouteToCustomer:
          await _notifyDriverEnRouteToCustomer(orderDetails, driverId);
          break;
        case DriverOrderStatus.arrivedAtCustomer:
          await _notifyDriverArrivedAtCustomer(orderDetails, driverId);
          break;
        case DriverOrderStatus.delivered:
          await _notifyOrderDelivered(orderDetails, driverId, additionalData);
          break;
        default:
          debugPrint('⚠️ [DRIVER-WORKFLOW-NOTIFICATIONS] No notifications configured for status: $toStatus');
      }

      debugPrint('✅ [DRIVER-WORKFLOW-NOTIFICATIONS] Notifications sent successfully');
    } catch (e) {
      debugPrint('❌ [DRIVER-WORKFLOW-NOTIFICATIONS] Failed to send notifications: $e');
      // Don't fail the workflow if notifications fail
    }
  }

  /// Get order details for notification context
  Future<Map<String, dynamic>?> _getOrderDetails(String orderId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('''
            id, customer_id, vendor_id, sales_agent_id, total_amount, delivery_address,
            vendors(id, name, address, phone),
            customers:customer_id(id, name, phone),
            sales_agents:sales_agent_id(id, name, phone)
          ''')
          .eq('id', orderId)
          .single();

      return response;
    } catch (e) {
      debugPrint('❌ [DRIVER-WORKFLOW-NOTIFICATIONS] Failed to get order details: $e');
      return null;
    }
  }

  /// Notify order assigned (ready → assigned)
  Future<void> _notifyOrderAssigned(Map<String, dynamic> orderDetails, String driverId) async {
    final orderId = orderDetails['id'];
    final vendorName = orderDetails['vendors']['name'];
    final vendorAddress = orderDetails['vendors']['address'];

    // Notify driver
    await _sendNotification(
      recipientId: driverId,
      recipientType: 'driver',
      templateKey: 'driver_order_assigned',
      variables: {
        'order_id': orderId,
        'vendor_name': vendorName,
        'vendor_address': vendorAddress,
      },
      orderId: orderId,
      priority: 'high',
    );

    // Notify customer
    await _sendNotification(
      recipientId: orderDetails['customer_id'],
      recipientType: 'customer',
      templateKey: 'customer_driver_assigned',
      variables: {
        'order_id': orderId,
        'vendor_name': vendorName,
      },
      orderId: orderId,
      priority: 'normal',
    );
  }

  /// Notify driver en route to vendor (assigned → on_route_to_vendor)
  Future<void> _notifyDriverEnRouteToVendor(Map<String, dynamic> orderDetails, String driverId) async {
    final orderId = orderDetails['id'];
    final vendorName = orderDetails['vendors']['name'];

    // Notify vendor
    await _sendNotification(
      recipientId: orderDetails['vendor_id'],
      recipientType: 'vendor',
      templateKey: 'vendor_driver_en_route',
      variables: {
        'order_id': orderId,
        'vendor_name': vendorName,
      },
      orderId: orderId,
      priority: 'normal',
    );

    // Notify customer
    await _sendNotification(
      recipientId: orderDetails['customer_id'],
      recipientType: 'customer',
      templateKey: 'customer_driver_en_route_pickup',
      variables: {
        'order_id': orderId,
        'vendor_name': vendorName,
      },
      orderId: orderId,
      priority: 'normal',
    );
  }

  /// Notify driver arrived at vendor (on_route_to_vendor → arrived_at_vendor)
  Future<void> _notifyDriverArrivedAtVendor(Map<String, dynamic> orderDetails, String driverId) async {
    final orderId = orderDetails['id'];
    final vendorName = orderDetails['vendors']['name'];

    // Notify vendor (high priority - action required)
    await _sendNotification(
      recipientId: orderDetails['vendor_id'],
      recipientType: 'vendor',
      templateKey: 'vendor_driver_arrived',
      variables: {
        'order_id': orderId,
        'vendor_name': vendorName,
      },
      orderId: orderId,
      priority: 'high',
    );

    // Notify customer
    await _sendNotification(
      recipientId: orderDetails['customer_id'],
      recipientType: 'customer',
      templateKey: 'customer_driver_at_vendor',
      variables: {
        'order_id': orderId,
        'vendor_name': vendorName,
      },
      orderId: orderId,
      priority: 'normal',
    );
  }

  /// Notify order picked up (arrived_at_vendor → picked_up)
  Future<void> _notifyOrderPickedUp(Map<String, dynamic> orderDetails, String driverId, Map<String, dynamic>? additionalData) async {
    final orderId = orderDetails['id'];
    final vendorName = orderDetails['vendors']['name'];
    final deliveryAddress = orderDetails['delivery_address'];

    // Notify customer (high priority - order is coming)
    await _sendNotification(
      recipientId: orderDetails['customer_id'],
      recipientType: 'customer',
      templateKey: 'customer_order_picked_up',
      variables: {
        'order_id': orderId,
        'vendor_name': vendorName,
        'delivery_address': deliveryAddress,
      },
      orderId: orderId,
      priority: 'high',
    );

    // Notify vendor
    await _sendNotification(
      recipientId: orderDetails['vendor_id'],
      recipientType: 'vendor',
      templateKey: 'vendor_order_picked_up',
      variables: {
        'order_id': orderId,
        'vendor_name': vendorName,
      },
      orderId: orderId,
      priority: 'normal',
    );

    // Notify sales agent if applicable
    if (orderDetails['sales_agent_id'] != null) {
      await _sendNotification(
        recipientId: orderDetails['sales_agent_id'],
        recipientType: 'sales_agent',
        templateKey: 'sales_agent_order_picked_up',
        variables: {
          'order_id': orderId,
          'vendor_name': vendorName,
        },
        orderId: orderId,
        priority: 'normal',
      );
    }
  }

  /// Notify driver en route to customer (picked_up → on_route_to_customer)
  Future<void> _notifyDriverEnRouteToCustomer(Map<String, dynamic> orderDetails, String driverId) async {
    final orderId = orderDetails['id'];
    final vendorName = orderDetails['vendors']['name'];
    final deliveryAddress = orderDetails['delivery_address'];

    // Notify customer (high priority - delivery incoming)
    await _sendNotification(
      recipientId: orderDetails['customer_id'],
      recipientType: 'customer',
      templateKey: 'customer_driver_en_route_delivery',
      variables: {
        'order_id': orderId,
        'vendor_name': vendorName,
        'delivery_address': deliveryAddress,
      },
      orderId: orderId,
      priority: 'high',
    );
  }

  /// Notify driver arrived at customer (on_route_to_customer → arrived_at_customer)
  Future<void> _notifyDriverArrivedAtCustomer(Map<String, dynamic> orderDetails, String driverId) async {
    final orderId = orderDetails['id'];
    final vendorName = orderDetails['vendors']['name'];

    // Notify customer (urgent - driver is here)
    await _sendNotification(
      recipientId: orderDetails['customer_id'],
      recipientType: 'customer',
      templateKey: 'customer_driver_arrived',
      variables: {
        'order_id': orderId,
        'vendor_name': vendorName,
      },
      orderId: orderId,
      priority: 'urgent',
    );
  }

  /// Notify order delivered (arrived_at_customer → delivered)
  Future<void> _notifyOrderDelivered(Map<String, dynamic> orderDetails, String driverId, Map<String, dynamic>? additionalData) async {
    final orderId = orderDetails['id'];
    final vendorName = orderDetails['vendors']['name'];
    final totalAmount = orderDetails['total_amount'];

    // Notify customer (high priority - order completed)
    await _sendNotification(
      recipientId: orderDetails['customer_id'],
      recipientType: 'customer',
      templateKey: 'customer_order_delivered',
      variables: {
        'order_id': orderId,
        'vendor_name': vendorName,
        'total_amount': totalAmount,
      },
      orderId: orderId,
      priority: 'high',
    );

    // Notify vendor
    await _sendNotification(
      recipientId: orderDetails['vendor_id'],
      recipientType: 'vendor',
      templateKey: 'vendor_order_delivered',
      variables: {
        'order_id': orderId,
        'vendor_name': vendorName,
        'total_amount': totalAmount,
      },
      orderId: orderId,
      priority: 'normal',
    );

    // Notify sales agent if applicable
    if (orderDetails['sales_agent_id'] != null) {
      await _sendNotification(
        recipientId: orderDetails['sales_agent_id'],
        recipientType: 'sales_agent',
        templateKey: 'sales_agent_order_delivered',
        variables: {
          'order_id': orderId,
          'vendor_name': vendorName,
          'total_amount': totalAmount,
        },
        orderId: orderId,
        priority: 'normal',
      );
    }

    // Notify driver (completion confirmation)
    await _sendNotification(
      recipientId: driverId,
      recipientType: 'driver',
      templateKey: 'driver_delivery_completed',
      variables: {
        'order_id': orderId,
        'vendor_name': vendorName,
      },
      orderId: orderId,
      priority: 'normal',
    );
  }

  /// Send notification using template
  Future<void> _sendNotification({
    required String recipientId,
    required String recipientType,
    required String templateKey,
    required Map<String, dynamic> variables,
    required String orderId,
    required String priority,
  }) async {
    try {
      await _notificationService.createNotificationFromTemplate(
        templateKey: templateKey,
        userId: recipientId,
        variables: variables,
        relatedEntityType: 'order',
        relatedEntityId: orderId,
      );

      debugPrint('✅ [DRIVER-WORKFLOW-NOTIFICATIONS] Sent $templateKey to $recipientType: $recipientId');
    } catch (e) {
      debugPrint('❌ [DRIVER-WORKFLOW-NOTIFICATIONS] Failed to send $templateKey: $e');
    }
  }
}

/// Provider for driver workflow notification service
final driverWorkflowNotificationServiceProvider = Provider<DriverWorkflowNotificationService>((ref) {
  return DriverWorkflowNotificationService();
});
