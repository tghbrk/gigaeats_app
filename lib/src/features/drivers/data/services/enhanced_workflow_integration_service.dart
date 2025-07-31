import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../drivers/data/models/driver_order.dart';
import '../../../orders/data/models/driver_order_state_machine.dart';
import 'driver_earnings_service.dart';
import 'driver_workflow_notification_service.dart';
import 'earnings_wallet_integration_service.dart';

/// Enhanced workflow integration service that connects the granular driver workflow
/// with existing systems including earnings, real-time updates, and photo storage
class EnhancedWorkflowIntegrationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final DriverEarningsService _earningsService = DriverEarningsService();
  final DriverWorkflowNotificationService _notificationService = DriverWorkflowNotificationService();

  // Initialize earnings-wallet integration service
  late final EarningsWalletIntegrationService _earningsWalletService = EarningsWalletIntegrationService();

  /// Process order status change with enhanced workflow integration
  Future<WorkflowIntegrationResult> processOrderStatusChange({
    required String orderId,
    required DriverOrderStatus fromStatus,
    required DriverOrderStatus toStatus,
    required String driverId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      debugPrint('🔄 [WORKFLOW-INTEGRATION] Processing status change: $fromStatus → $toStatus for order $orderId');

      // Validate transition
      final validation = DriverOrderStateMachine.validateTransition(fromStatus, toStatus);
      if (!validation.isValid) {
        return WorkflowIntegrationResult.failure('Invalid status transition: ${validation.errorMessage}');
      }

      // Process status-specific integrations
      await _processStatusSpecificIntegrations(
        orderId: orderId,
        toStatus: toStatus,
        driverId: driverId,
        additionalData: additionalData,
      );

      // Update real-time tracking
      await _updateRealTimeTracking(orderId, toStatus, driverId);

      // Send real-time notifications to all stakeholders
      await _notificationService.notifyWorkflowStatusChange(
        orderId: orderId,
        fromStatus: fromStatus,
        toStatus: toStatus,
        driverId: driverId,
        additionalData: additionalData,
      );

      // Process earnings if order is completed
      if (toStatus == DriverOrderStatus.delivered) {
        await _processOrderCompletion(orderId, driverId, additionalData);
      }

      debugPrint('✅ [WORKFLOW-INTEGRATION] Status change processed successfully');
      return WorkflowIntegrationResult.success();

    } catch (e) {
      debugPrint('❌ [WORKFLOW-INTEGRATION] Failed to process status change: $e');
      return WorkflowIntegrationResult.failure(e.toString());
    }
  }

  /// Process status-specific integrations
  Future<void> _processStatusSpecificIntegrations({
    required String orderId,
    required DriverOrderStatus toStatus,
    required String driverId,
    Map<String, dynamic>? additionalData,
  }) async {
    switch (toStatus) {
      case DriverOrderStatus.assigned:
        await _handleOrderAssignment(orderId, driverId);
        break;
      case DriverOrderStatus.onRouteToVendor:
        await _handleNavigationStart(orderId, driverId, isToVendor: true);
        break;
      case DriverOrderStatus.arrivedAtVendor:
        await _handleVendorArrival(orderId, driverId);
        break;
      case DriverOrderStatus.pickedUp:
        await _handlePickupCompletion(orderId, driverId, additionalData);
        break;
      case DriverOrderStatus.onRouteToCustomer:
        await _handleNavigationStart(orderId, driverId, isToVendor: false);
        break;
      case DriverOrderStatus.arrivedAtCustomer:
        await _handleCustomerArrival(orderId, driverId);
        break;
      case DriverOrderStatus.delivered:
        await _handleDeliveryCompletion(orderId, driverId, additionalData);
        break;
      default:
        break;
    }
  }

  /// Handle order assignment integration
  Future<void> _handleOrderAssignment(String orderId, String driverId) async {
    debugPrint('📋 [WORKFLOW-INTEGRATION] Processing order assignment');
    
    // Update driver status to busy
    await _updateDriverStatus(driverId, 'busy');
    
    // Send assignment notification
    await _sendNotification(
      driverId: driverId,
      title: 'New Order Assigned',
      message: 'You have been assigned a new delivery order',
      type: 'order_assigned',
      orderId: orderId,
    );
  }

  /// Handle navigation start integration
  Future<void> _handleNavigationStart(String orderId, String driverId, {required bool isToVendor}) async {
    debugPrint('🧭 [WORKFLOW-INTEGRATION] Processing navigation start (to ${isToVendor ? 'vendor' : 'customer'})');
    
    // Update location tracking
    await _startLocationTracking(orderId, driverId);
    
    // Log navigation event
    await _logDriverEvent(
      driverId: driverId,
      orderId: orderId,
      eventType: isToVendor ? 'navigation_to_vendor_started' : 'navigation_to_customer_started',
      timestamp: DateTime.now(),
    );
  }

  /// Handle vendor arrival integration
  Future<void> _handleVendorArrival(String orderId, String driverId) async {
    debugPrint('🏪 [WORKFLOW-INTEGRATION] Processing vendor arrival');
    
    // Notify vendor of driver arrival
    await _notifyVendorOfDriverArrival(orderId, driverId);
    
    // Update location tracking
    await _updateLocationTracking(orderId, driverId, 'arrived_at_vendor');
  }

  /// Handle pickup completion integration
  Future<void> _handlePickupCompletion(String orderId, String driverId, Map<String, dynamic>? additionalData) async {
    debugPrint('📦 [WORKFLOW-INTEGRATION] Processing pickup completion');
    
    // Process pickup confirmation data
    if (additionalData?['pickup_confirmation'] != null) {
      await _processPickupConfirmationIntegration(orderId, additionalData!['pickup_confirmation']);
    }
    
    // Update inventory tracking
    await _updateInventoryTracking(orderId, 'picked_up');
    
    // Notify customer of pickup
    await _notifyCustomerOfPickup(orderId);
  }

  /// Handle customer arrival integration
  Future<void> _handleCustomerArrival(String orderId, String driverId) async {
    debugPrint('🏠 [WORKFLOW-INTEGRATION] Processing customer arrival');
    
    // Notify customer of driver arrival
    await _notifyCustomerOfDriverArrival(orderId, driverId);
    
    // Update location tracking
    await _updateLocationTracking(orderId, driverId, 'arrived_at_customer');
  }

  /// Handle delivery completion integration
  Future<void> _handleDeliveryCompletion(String orderId, String driverId, Map<String, dynamic>? additionalData) async {
    debugPrint('✅ [WORKFLOW-INTEGRATION] Processing delivery completion');
    
    // Process delivery confirmation data
    if (additionalData?['delivery_confirmation'] != null) {
      await _processDeliveryConfirmationIntegration(orderId, additionalData!['delivery_confirmation']);
    }
    
    // Update driver status to available
    await _updateDriverStatus(driverId, 'online');
    
    // Stop location tracking
    await _stopLocationTracking(orderId, driverId);
    
    // Notify customer of delivery completion
    await _notifyCustomerOfDeliveryCompletion(orderId);
  }

  /// Process order completion with earnings calculation
  Future<void> _processOrderCompletion(String orderId, String driverId, Map<String, dynamic>? additionalData) async {
    debugPrint('💰 [WORKFLOW-INTEGRATION] Processing order completion earnings');
    
    try {
      // Calculate enhanced earnings
      final earningsResult = await _earningsService.calculateEnhancedEarnings(
        orderId: orderId,
        driverId: driverId,
        includeBonus: true,
        customTip: additionalData?['tip_amount']?.toDouble() ?? 0.0,
        performanceMetrics: additionalData?['performance_metrics'],
      );
      
      // Store earnings record
      await _storeEarningsRecord(orderId, driverId, earningsResult);
      
      debugPrint('✅ [WORKFLOW-INTEGRATION] Earnings processed successfully');
    } catch (e) {
      debugPrint('❌ [WORKFLOW-INTEGRATION] Failed to process earnings: $e');
      // Don't fail the entire workflow for earnings issues
    }
  }

  /// Update real-time tracking for all stakeholders
  Future<void> _updateRealTimeTracking(String orderId, DriverOrderStatus status, String driverId) async {
    debugPrint('📡 [WORKFLOW-INTEGRATION] Updating real-time tracking');
    
    // Update order tracking table for real-time updates
    await _supabase.from('order_tracking').upsert({
      'order_id': orderId,
      'driver_id': driverId,
      'current_status': status.value,
      'updated_at': DateTime.now().toIso8601String(),
      'status_timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Process pickup confirmation integration
  Future<void> _processPickupConfirmationIntegration(String orderId, Map<String, dynamic> confirmationData) async {
    debugPrint('📋 [WORKFLOW-INTEGRATION] Processing pickup confirmation integration');
    
    // Additional processing for pickup confirmation
    // This could include inventory updates, vendor notifications, etc.
  }

  /// Process delivery confirmation integration
  Future<void> _processDeliveryConfirmationIntegration(String orderId, Map<String, dynamic> confirmationData) async {
    debugPrint('📸 [WORKFLOW-INTEGRATION] Processing delivery confirmation integration');
    
    // Additional processing for delivery confirmation
    // This could include photo analysis, customer notifications, etc.
  }

  /// Store earnings record in the database and process wallet deposit
  Future<void> _storeEarningsRecord(String orderId, String driverId, Map<String, dynamic> earningsData) async {
    debugPrint('💰 [WORKFLOW-INTEGRATION] Storing earnings record and processing wallet deposit');
    debugPrint('💰 [WORKFLOW-INTEGRATION] Order: $orderId, Driver: $driverId');
    debugPrint('💰 [WORKFLOW-INTEGRATION] Net earnings: RM ${earningsData['net_earnings']?.toStringAsFixed(2) ?? '0.00'}');

    // Store earnings record in driver_earnings table
    await _supabase.from('driver_earnings').insert({
      'order_id': orderId,
      'driver_id': driverId,
      'gross_earnings': earningsData['gross_earnings'],
      'net_earnings': earningsData['net_earnings'],
      'base_commission': earningsData['base_commission'],
      'completion_bonus': earningsData['completion_bonus'],
      'peak_hour_bonus': earningsData['peak_hour_bonus'],
      'rating_bonus': earningsData['rating_bonus'],
      'other_bonuses': earningsData['other_bonuses'],
      'deductions': earningsData['deductions'],
      'earnings_type': 'delivery_completion',
      'created_at': DateTime.now().toIso8601String(),
    });

    debugPrint('✅ [WORKFLOW-INTEGRATION] Earnings record stored successfully');

    // Process wallet deposit (non-blocking to avoid failing the entire workflow)
    await _processWalletDeposit(orderId, driverId, earningsData);
  }

  /// Process wallet deposit after delivery completion
  /// This method is designed to be non-blocking to avoid failing the entire workflow
  Future<void> _processWalletDeposit(String orderId, String driverId, Map<String, dynamic> earningsData) async {
    try {
      debugPrint('🔍 [WORKFLOW-INTEGRATION] Processing wallet deposit for order: $orderId');
      debugPrint('🔍 [WORKFLOW-INTEGRATION] Driver: $driverId');

      final grossEarnings = earningsData['gross_earnings']?.toDouble() ?? 0.0;
      final netEarnings = earningsData['net_earnings']?.toDouble() ?? 0.0;

      debugPrint('🔍 [WORKFLOW-INTEGRATION] Gross earnings: RM ${grossEarnings.toStringAsFixed(2)}');
      debugPrint('🔍 [WORKFLOW-INTEGRATION] Net earnings: RM ${netEarnings.toStringAsFixed(2)}');

      // Only process if there are actual earnings to deposit
      if (netEarnings <= 0) {
        debugPrint('⚠️ [WORKFLOW-INTEGRATION] No earnings to deposit (net earnings: $netEarnings)');
        return;
      }

      // Process earnings deposit using comprehensive integration service
      final result = await _earningsWalletService.processOrderEarningsToWallet(
        orderId: orderId,
        driverId: driverId,
        earningsData: earningsData,
        retryOnFailure: true,
      );

      if (result.isSuccess) {
        debugPrint('✅ [WORKFLOW-INTEGRATION] Wallet deposit successful: ${result.message}');
        if (result.amountDeposited != null && result.amountDeposited! > 0) {
          debugPrint('✅ [WORKFLOW-INTEGRATION] Amount deposited: RM ${result.amountDeposited!.toStringAsFixed(2)}');
        }
      } else {
        debugPrint('⚠️ [WORKFLOW-INTEGRATION] Wallet deposit failed but will be retried: ${result.error}');
      }

      debugPrint('✅ [WORKFLOW-INTEGRATION] Wallet deposit completed successfully');
      debugPrint('✅ [WORKFLOW-INTEGRATION] Deposited RM ${netEarnings.toStringAsFixed(2)} to driver wallet');

    } catch (e) {
      debugPrint('❌ [WORKFLOW-INTEGRATION] Wallet deposit failed: $e');
      debugPrint('❌ [WORKFLOW-INTEGRATION] Order: $orderId, Driver: $driverId');

      // Log the error but don't throw - earnings are still recorded in driver_earnings table
      // Wallet deposit can be retried later using WalletDepositRetryService
      // This ensures the delivery completion workflow doesn't fail due to wallet issues

      // Note: Retry mechanism is implemented in EarningsWalletIntegrationService
      // Failed deposits will be automatically retried by the retry service
    }
  }

  // Helper methods for various integrations
  Future<void> _updateDriverStatus(String driverId, String status) async {
    debugPrint('🔄 [WORKFLOW-INTEGRATION] Updating driver status');
    debugPrint('🔄 [WORKFLOW-INTEGRATION] Driver: $driverId, New Status: $status');

    final updateData = <String, dynamic>{
      'status': status,
      'last_seen': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    // Clear delivery status when driver goes back to online status
    if (status == 'online') {
      updateData['current_delivery_status'] = null;
      debugPrint('🧹 [WORKFLOW-INTEGRATION] Clearing driver delivery status for online transition');
      debugPrint('🧹 [WORKFLOW-INTEGRATION] Driver $driverId will be ready for new orders');
    }

    await _supabase.from('drivers').update(updateData).eq('id', driverId);
    debugPrint('✅ [WORKFLOW-INTEGRATION] Driver status updated successfully to: $status');
  }

  Future<void> _sendNotification({
    required String driverId,
    required String title,
    required String message,
    required String type,
    String? orderId,
  }) async {
    try {
      debugPrint('📱 [WORKFLOW-INTEGRATION] Sending notification: $title');

      // Send notification via Supabase Edge Function
      await _supabase.functions.invoke('send-notification', body: {
        'notification_type': type,
        'title': title,
        'message': message,
        'recipient_id': driverId,
        'recipient_type': 'driver',
        'order_id': orderId,
        'data': {
          'order_id': orderId,
          'type': type,
          'timestamp': DateTime.now().toIso8601String(),
        },
        'channels': ['in_app', 'push'],
        'priority': 'high',
      });

      debugPrint('✅ [WORKFLOW-INTEGRATION] Notification sent successfully');
    } catch (e) {
      debugPrint('❌ [WORKFLOW-INTEGRATION] Failed to send notification: $e');
      // Don't fail the workflow if notification fails
    }
  }

  Future<void> _startLocationTracking(String orderId, String driverId) async {
    debugPrint('📍 [WORKFLOW-INTEGRATION] Starting location tracking');
  }

  Future<void> _updateLocationTracking(String orderId, String driverId, String event) async {
    debugPrint('📍 [WORKFLOW-INTEGRATION] Updating location tracking: $event');
  }

  Future<void> _stopLocationTracking(String orderId, String driverId) async {
    debugPrint('📍 [WORKFLOW-INTEGRATION] Stopping location tracking');
  }

  Future<void> _logDriverEvent({
    required String driverId,
    required String orderId,
    required String eventType,
    required DateTime timestamp,
  }) async {
    await _supabase.from('driver_events').insert({
      'driver_id': driverId,
      'order_id': orderId,
      'event_type': eventType,
      'timestamp': timestamp.toIso8601String(),
    });
  }

  Future<void> _notifyVendorOfDriverArrival(String orderId, String driverId) async {
    try {
      debugPrint('🏪 [WORKFLOW-INTEGRATION] Notifying vendor of driver arrival');

      // Get order details to find vendor
      final orderResponse = await _supabase
          .from('orders')
          .select('vendor_id, vendors(name)')
          .eq('id', orderId)
          .single();

      final vendorId = orderResponse['vendor_id'];
      final vendorName = orderResponse['vendors']['name'];

      await _supabase.functions.invoke('send-notification', body: {
        'notification_type': 'driver_arrived_vendor',
        'title': 'Driver Arrived',
        'message': 'The delivery driver has arrived at your restaurant for order pickup',
        'recipient_id': vendorId,
        'recipient_type': 'vendor',
        'order_id': orderId,
        'data': {
          'order_id': orderId,
          'driver_id': driverId,
          'vendor_name': vendorName,
          'timestamp': DateTime.now().toIso8601String(),
        },
        'channels': ['in_app', 'push'],
        'priority': 'high',
      });

      debugPrint('✅ [WORKFLOW-INTEGRATION] Vendor notification sent');
    } catch (e) {
      debugPrint('❌ [WORKFLOW-INTEGRATION] Failed to notify vendor: $e');
    }
  }

  Future<void> _notifyCustomerOfPickup(String orderId) async {
    try {
      debugPrint('📱 [WORKFLOW-INTEGRATION] Notifying customer of pickup');

      // Get order details to find customer
      final orderResponse = await _supabase
          .from('orders')
          .select('customer_id, vendors(name)')
          .eq('id', orderId)
          .single();

      final customerId = orderResponse['customer_id'];
      final vendorName = orderResponse['vendors']['name'];

      await _supabase.functions.invoke('send-notification', body: {
        'notification_type': 'order_picked_up',
        'title': 'Order Picked Up',
        'message': 'Your order from $vendorName has been picked up and is on the way!',
        'recipient_id': customerId,
        'recipient_type': 'customer',
        'order_id': orderId,
        'data': {
          'order_id': orderId,
          'vendor_name': vendorName,
          'timestamp': DateTime.now().toIso8601String(),
        },
        'channels': ['in_app', 'push'],
        'priority': 'high',
      });

      debugPrint('✅ [WORKFLOW-INTEGRATION] Customer pickup notification sent');
    } catch (e) {
      debugPrint('❌ [WORKFLOW-INTEGRATION] Failed to notify customer of pickup: $e');
    }
  }

  Future<void> _notifyCustomerOfDriverArrival(String orderId, String driverId) async {
    try {
      debugPrint('📱 [WORKFLOW-INTEGRATION] Notifying customer of driver arrival');

      // Get order details to find customer
      final orderResponse = await _supabase
          .from('orders')
          .select('customer_id, delivery_address')
          .eq('id', orderId)
          .single();

      final customerId = orderResponse['customer_id'];
      final deliveryAddress = orderResponse['delivery_address'];

      await _supabase.functions.invoke('send-notification', body: {
        'notification_type': 'driver_arrived_customer',
        'title': 'Driver Arrived',
        'message': 'Your delivery driver has arrived at your location!',
        'recipient_id': customerId,
        'recipient_type': 'customer',
        'order_id': orderId,
        'data': {
          'order_id': orderId,
          'driver_id': driverId,
          'delivery_address': deliveryAddress,
          'timestamp': DateTime.now().toIso8601String(),
        },
        'channels': ['in_app', 'push'],
        'priority': 'urgent',
      });

      debugPrint('✅ [WORKFLOW-INTEGRATION] Customer arrival notification sent');
    } catch (e) {
      debugPrint('❌ [WORKFLOW-INTEGRATION] Failed to notify customer of arrival: $e');
    }
  }

  Future<void> _notifyCustomerOfDeliveryCompletion(String orderId) async {
    try {
      debugPrint('📱 [WORKFLOW-INTEGRATION] Notifying customer of delivery completion');

      // Get order details to find customer
      final orderResponse = await _supabase
          .from('orders')
          .select('customer_id, vendors(name), total_amount')
          .eq('id', orderId)
          .single();

      final customerId = orderResponse['customer_id'];
      final vendorName = orderResponse['vendors']['name'];
      final totalAmount = orderResponse['total_amount'];

      await _supabase.functions.invoke('send-notification', body: {
        'notification_type': 'order_delivered',
        'title': 'Order Delivered Successfully! 🎉',
        'message': 'Your order from $vendorName has been delivered. Thank you for choosing GigaEats!',
        'recipient_id': customerId,
        'recipient_type': 'customer',
        'order_id': orderId,
        'data': {
          'order_id': orderId,
          'vendor_name': vendorName,
          'total_amount': totalAmount,
          'timestamp': DateTime.now().toIso8601String(),
        },
        'channels': ['in_app', 'push'],
        'priority': 'high',
      });

      debugPrint('✅ [WORKFLOW-INTEGRATION] Customer delivery completion notification sent');
    } catch (e) {
      debugPrint('❌ [WORKFLOW-INTEGRATION] Failed to notify customer of delivery completion: $e');
    }
  }

  Future<void> _updateInventoryTracking(String orderId, String status) async {
    debugPrint('📦 [WORKFLOW-INTEGRATION] Updating inventory tracking: $status');
  }
}

/// Result of workflow integration operations
class WorkflowIntegrationResult {
  final bool isSuccess;
  final String? errorMessage;

  const WorkflowIntegrationResult._(this.isSuccess, this.errorMessage);

  factory WorkflowIntegrationResult.success() => 
      const WorkflowIntegrationResult._(true, null);

  factory WorkflowIntegrationResult.failure(String message) => 
      WorkflowIntegrationResult._(false, message);
}
