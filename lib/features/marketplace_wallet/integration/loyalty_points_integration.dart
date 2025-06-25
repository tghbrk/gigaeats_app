import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/orders/data/models/order.dart';
import '../../../features/orders/presentation/providers/order_provider.dart';
import '../../../features/customers/presentation/providers/loyalty_provider.dart';

/// Integration service that handles loyalty points earning when orders are completed
class LoyaltyPointsIntegration {
  final Ref _ref;

  LoyaltyPointsIntegration(this._ref);

  /// Handle loyalty points earning when order status changes to delivered
  Future<void> handleOrderStatusChange({
    required String orderId,
    required OrderStatus oldStatus,
    required OrderStatus newStatus,
    String? changedBy,
    String? reason,
  }) async {
    debugPrint('🎯 [LOYALTY-INTEGRATION] Handling order status change: $orderId');
    debugPrint('🎯 [LOYALTY-INTEGRATION] Status: ${oldStatus.value} → ${newStatus.value}');

    try {
      // Only process loyalty points for delivered orders
      if (newStatus == OrderStatus.delivered) {
        await _handleLoyaltyPointsEarning(orderId);
      }

      debugPrint('🎯 [LOYALTY-INTEGRATION] Order status change handling completed');
    } catch (e) {
      debugPrint('🎯 [LOYALTY-INTEGRATION] Error handling order status change: $e');
      // Don't rethrow - order status should still be updated even if loyalty operations fail
    }
  }

  /// Handle loyalty points earning for delivered orders
  Future<void> _handleLoyaltyPointsEarning(String orderId) async {
    debugPrint('🎯 [LOYALTY-INTEGRATION] Processing loyalty points for order: $orderId');

    try {
      // Get order details to extract customer ID and amount
      final ordersState = _ref.read(ordersProvider);
      final order = ordersState.orders.firstWhere(
        (o) => o.id == orderId,
        orElse: () => throw Exception('Order not found in local state'),
      );

      // The backend order completion handler Edge Function will automatically
      // call the loyalty points calculator when the order status changes to delivered
      debugPrint('🎯 [LOYALTY-INTEGRATION] Order completion will trigger loyalty points automatically');
      
      // Refresh loyalty data to reflect new points
      await _refreshLoyaltyData();

      // Show notification about points earned
      await _showLoyaltyPointsNotification(orderId, order.totalAmount);

    } catch (e) {
      debugPrint('🎯 [LOYALTY-INTEGRATION] Error handling loyalty points: $e');
      // Don't fail the order completion if loyalty points fail
      // This will be handled by the backend Edge Function
    }
  }

  /// Refresh loyalty data after points are earned
  Future<void> _refreshLoyaltyData() async {
    try {
      // Refresh loyalty provider to get updated points and tier
      final loyaltyNotifier = _ref.read(loyaltyProvider.notifier);
      await loyaltyNotifier.forceReload();
      
      debugPrint('🎯 [LOYALTY-INTEGRATION] Loyalty data refreshed');
    } catch (e) {
      debugPrint('🎯 [LOYALTY-INTEGRATION] Error refreshing loyalty data: $e');
    }
  }

  /// Show notification about loyalty points earned
  Future<void> _showLoyaltyPointsNotification(String orderId, double orderAmount) async {
    try {
      // Calculate expected points (1 point per RM)
      final expectedPoints = orderAmount.floor();
      
      debugPrint('🎯 [LOYALTY-INTEGRATION] Loyalty points notification: You earned approximately $expectedPoints points from order $orderId!');
      
      // TODO: Implement proper notification system for loyalty points
      // For now, the points earning will be handled by the backend Edge Function
      // and users will see the updated points in their loyalty dashboard
      
    } catch (e) {
      debugPrint('🎯 [LOYALTY-INTEGRATION] Error showing loyalty notification: $e');
    }
  }

  /// Get loyalty points status for an order
  Future<Map<String, dynamic>> getLoyaltyPointsStatus(String orderId) async {
    try {
      // Check if loyalty account exists and is active
      final loyaltyState = _ref.read(loyaltyProvider);
      
      if (!loyaltyState.hasLoyaltyAccount) {
        return {
          'loyalty_enabled': false,
          'reason': 'No loyalty account found',
        };
      }

      return {
        'loyalty_enabled': true,
        'current_points': loyaltyState.availablePoints,
        'current_tier': loyaltyState.currentTier.name,
        'tier_multiplier': loyaltyState.loyaltyAccount?.tierMultiplier ?? 1.0,
      };
    } catch (e) {
      debugPrint('🎯 [LOYALTY-INTEGRATION] Error getting loyalty status: $e');
      return {
        'loyalty_enabled': false,
        'error': e.toString(),
      };
    }
  }
}

/// Provider for loyalty points integration
final loyaltyPointsIntegrationProvider = Provider<LoyaltyPointsIntegration>((ref) {
  return LoyaltyPointsIntegration(ref);
});

/// Enhanced order actions provider that includes loyalty points integration
final enhancedOrderActionsWithLoyaltyProvider = Provider<EnhancedOrderActionsWithLoyalty>((ref) {
  return EnhancedOrderActionsWithLoyalty(ref);
});

/// Enhanced order actions class with loyalty points integration
class EnhancedOrderActionsWithLoyalty {
  final Ref _ref;

  EnhancedOrderActionsWithLoyalty(this._ref);

  /// Update order status with loyalty points integration
  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus newStatus,
    String? changedBy,
    String? reason,
  }) async {
    // Get current order to determine old status
    final ordersNotifier = _ref.read(ordersProvider.notifier);
    final currentOrders = _ref.read(ordersProvider);
    
    final currentOrder = currentOrders.orders.firstWhere(
      (order) => order.id == orderId,
      orElse: () => throw Exception('Order not found'),
    );

    final oldStatus = currentOrder.status;

    // Update order status through existing provider
    await ordersNotifier.updateOrderStatus(orderId, newStatus);

    // Handle loyalty points integration
    final loyaltyIntegration = _ref.read(loyaltyPointsIntegrationProvider);
    await loyaltyIntegration.handleOrderStatusChange(
      orderId: orderId,
      oldStatus: oldStatus,
      newStatus: newStatus,
      changedBy: changedBy,
      reason: reason,
    );
  }

  /// Get order completion status with loyalty points information
  Future<Map<String, dynamic>> getOrderCompletionStatus(String orderId) async {
    final loyaltyIntegration = _ref.read(loyaltyPointsIntegrationProvider);
    return await loyaltyIntegration.getLoyaltyPointsStatus(orderId);
  }
}
