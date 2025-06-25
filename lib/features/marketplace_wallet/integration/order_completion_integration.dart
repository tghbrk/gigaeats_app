import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/orders/data/models/order.dart';
import '../../../features/orders/presentation/providers/order_provider.dart';
import '../../../features/customers/presentation/providers/loyalty_provider.dart';
import '../data/services/marketplace_payment_service.dart';
import '../data/providers/marketplace_wallet_providers.dart';
import '../data/models/escrow_account.dart';
import '../presentation/providers/wallet_state_provider.dart';
import '../presentation/providers/wallet_transactions_provider.dart';

/// Integration service that handles order completion and fund distribution
class OrderCompletionIntegration {
  final MarketplacePaymentService _marketplacePaymentService;
  final Ref _ref;

  OrderCompletionIntegration(
    this._marketplacePaymentService,
    this._ref,
  );

  /// Handle order status change with marketplace integration
  Future<void> handleOrderStatusChange({
    required String orderId,
    required OrderStatus oldStatus,
    required OrderStatus newStatus,
    String? changedBy,
    String? reason,
  }) async {
    debugPrint('🔄 [ORDER-COMPLETION] Handling order status change: $orderId');
    debugPrint('🔄 [ORDER-COMPLETION] Status: ${oldStatus.value} → ${newStatus.value}');

    try {
      // Check if this status change triggers escrow release
      if (_shouldReleaseEscrow(oldStatus, newStatus)) {
        await _handleEscrowRelease(orderId, newStatus, changedBy, reason);
      }

      // Handle loyalty points for delivered orders
      if (newStatus == OrderStatus.delivered) {
        await _handleLoyaltyPointsEarning(orderId);
      }

      // Handle other marketplace-related status changes
      await _handleMarketplaceStatusChange(orderId, oldStatus, newStatus);

      // Refresh affected stakeholder data
      await _refreshStakeholderData(orderId);

      debugPrint('🔄 [ORDER-COMPLETION] Order status change handling completed');
    } catch (e) {
      debugPrint('🔄 [ORDER-COMPLETION] Error handling order status change: $e');
      // Don't rethrow - order status should still be updated even if marketplace operations fail
    }
  }

  /// Check if escrow should be released based on status change
  bool _shouldReleaseEscrow(OrderStatus oldStatus, OrderStatus newStatus) {
    // Release escrow when order is delivered
    if (newStatus == OrderStatus.delivered) {
      return true;
    }

    // Release escrow when sales agent marks order as delivered (pickup orders)
    if (newStatus == OrderStatus.delivered && oldStatus == OrderStatus.ready) {
      return true;
    }

    return false;
  }

  /// Handle escrow release and fund distribution
  Future<void> _handleEscrowRelease(
    String orderId,
    OrderStatus newStatus,
    String? changedBy,
    String? reason,
  ) async {
    debugPrint('🔄 [ORDER-COMPLETION] Releasing escrow for order: $orderId');

    try {
      // Release escrow funds
      final releaseResult = await _marketplacePaymentService.releaseEscrowFunds(
        orderId: orderId,
        releasedBy: changedBy,
        releaseReason: reason ?? 'Order delivered',
      );

      if (releaseResult.isLeft()) {
        final failure = releaseResult.fold((l) => l, (r) => null)!;
        throw Exception('Failed to release escrow: ${failure.message}');
      }

      final releaseData = releaseResult.fold((l) => null, (r) => r)!;
      debugPrint('🔄 [ORDER-COMPLETION] Escrow released successfully: ${releaseData.escrowAccountId}');

      // Distribute funds to stakeholder wallets
      await _distributeFunds(orderId, releaseData);

      // Send notifications to stakeholders
      await _sendFundDistributionNotifications(orderId, releaseData);

      debugPrint('🔄 [ORDER-COMPLETION] Fund distribution completed');
    } catch (e) {
      debugPrint('🔄 [ORDER-COMPLETION] Error releasing escrow: $e');
      
      // Log the error but don't fail the order completion
      // The escrow can be released manually later if needed
      await _logEscrowReleaseError(orderId, e.toString());
    }
  }

  /// Distribute funds to stakeholder wallets
  Future<void> _distributeFunds(String orderId, FundDistributionResult releaseData) async {
    debugPrint('🔄 [ORDER-COMPLETION] Distributing funds for order: $orderId');

    try {
      final distributionResult = await _marketplacePaymentService.distributeFunds(
        orderId: orderId,
        escrowAccountId: releaseData.escrowAccountId,
        releaseReason: 'order_delivered',
      );

      if (distributionResult.isLeft()) {
        final failure = distributionResult.fold((l) => l, (r) => null)!;
        throw Exception('Failed to distribute funds: ${failure.message}');
      }

      final distributionData = distributionResult.fold((l) => null, (r) => r)!;
      debugPrint('🔄 [ORDER-COMPLETION] Funds distributed: ${distributionData.totalDistributed}');

      // Log successful distribution
      await _logFundDistribution(orderId, {
        'escrow_account_id': distributionData.escrowAccountId,
        'total_distributed': distributionData.totalDistributed,
        'distributions': distributionData.distributions.map((d) => {
          'user_role': d.userRole,
          'amount': d.amount,
          'transaction_type': d.transactionType,
        }).toList(),
      });
    } catch (e) {
      debugPrint('🔄 [ORDER-COMPLETION] Error distributing funds: $e');
      rethrow; // Re-throw as this is critical
    }
  }

  /// Send notifications to stakeholders about fund distribution
  Future<void> _sendFundDistributionNotifications(
    String orderId,
    FundDistributionResult releaseData,
  ) async {
    debugPrint('🔄 [ORDER-COMPLETION] Sending fund distribution notifications');

    try {
      // Get commission breakdown for notification details
      final commissionResult = await _marketplacePaymentService.getCommissionBreakdown(
        orderId: orderId,
      );

      if (commissionResult.isRight()) {
        final commission = commissionResult.fold((l) => null, (r) => r)!;
        
        // Trigger notifications through the notification system
        // The notification providers will handle the actual notification creation
        await _triggerStakeholderNotifications(orderId, commission.toJson());
      }
    } catch (e) {
      debugPrint('🔄 [ORDER-COMPLETION] Error sending notifications: $e');
      // Non-critical error, continue
    }
  }

  /// Trigger notifications for stakeholders
  Future<void> _triggerStakeholderNotifications(
    String orderId,
    Map<String, dynamic> commission,
  ) async {
    // The notification providers will automatically generate notifications
    // when wallet balances are updated through real-time subscriptions

    // We can also manually trigger specific notifications here if needed
    debugPrint('🔄 [ORDER-COMPLETION] Stakeholder notifications triggered');
  }

  /// Handle loyalty points earning for delivered orders
  Future<void> _handleLoyaltyPointsEarning(String orderId) async {
    debugPrint('🎯 [ORDER-COMPLETION] Processing loyalty points for order: $orderId');

    try {
      // Get order details to extract customer ID and amount
      final ordersState = _ref.read(ordersProvider);
      final order = ordersState.orders.firstWhere(
        (o) => o.id == orderId,
        orElse: () => throw Exception('Order not found in local state'),
      );

      // Call the order completion handler Edge Function which will handle loyalty points
      // This is already integrated in the backend, so we just need to trigger it
      debugPrint('🎯 [ORDER-COMPLETION] Order completion will trigger loyalty points automatically');

      // Refresh loyalty data to reflect new points
      await _refreshLoyaltyData();

      // Show notification about points earned
      await _showLoyaltyPointsNotification(orderId, order.totalAmount);

    } catch (e) {
      debugPrint('🎯 [ORDER-COMPLETION] Error handling loyalty points: $e');
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

      debugPrint('🎯 [ORDER-COMPLETION] Loyalty data refreshed');
    } catch (e) {
      debugPrint('🎯 [ORDER-COMPLETION] Error refreshing loyalty data: $e');
    }
  }

  /// Show notification about loyalty points earned
  Future<void> _showLoyaltyPointsNotification(String orderId, double orderAmount) async {
    try {
      // Calculate expected points (1 point per RM)
      final expectedPoints = orderAmount.floor();

      debugPrint('🎯 [ORDER-COMPLETION] Loyalty points notification: You earned approximately $expectedPoints points from order $orderId!');

      // TODO: Implement proper notification system for loyalty points
      // For now, the points earning will be handled by the backend Edge Function
      // and users will see the updated points in their loyalty dashboard

    } catch (e) {
      debugPrint('🎯 [ORDER-COMPLETION] Error showing loyalty notification: $e');
    }
  }

  /// Handle other marketplace-related status changes
  Future<void> _handleMarketplaceStatusChange(
    String orderId,
    OrderStatus oldStatus,
    OrderStatus newStatus,
  ) async {
    // Handle other status changes that might affect the marketplace
    
    if (newStatus == OrderStatus.cancelled) {
      await _handleOrderCancellation(orderId, oldStatus);
    } else if (newStatus == OrderStatus.confirmed) {
      await _handleOrderConfirmation(orderId);
    } else if (newStatus == OrderStatus.preparing) {
      await _handleOrderPreparation(orderId);
    }
  }

  /// Handle order cancellation
  Future<void> _handleOrderCancellation(String orderId, OrderStatus oldStatus) async {
    debugPrint('🔄 [ORDER-COMPLETION] Handling order cancellation: $orderId');

    try {
      // If payment was already processed, initiate refund
      if (oldStatus != OrderStatus.pending) {
        await _initiateRefund(orderId, 'Order cancelled');
      }
    } catch (e) {
      debugPrint('🔄 [ORDER-COMPLETION] Error handling cancellation: $e');
    }
  }

  /// Handle order confirmation
  Future<void> _handleOrderConfirmation(String orderId) async {
    debugPrint('🔄 [ORDER-COMPLETION] Handling order confirmation: $orderId');

    try {
      // Update escrow account status if needed
      await _updateEscrowStatus(orderId, EscrowStatus.confirmed);
    } catch (e) {
      debugPrint('🔄 [ORDER-COMPLETION] Error handling confirmation: $e');
    }
  }

  /// Handle order preparation start
  Future<void> _handleOrderPreparation(String orderId) async {
    debugPrint('🔄 [ORDER-COMPLETION] Handling order preparation: $orderId');

    try {
      // Update escrow account status
      await _updateEscrowStatus(orderId, EscrowStatus.processing);
    } catch (e) {
      debugPrint('🔄 [ORDER-COMPLETION] Error handling preparation: $e');
    }
  }

  /// Initiate refund for cancelled order
  Future<void> _initiateRefund(String orderId, String reason) async {
    debugPrint('🔄 [ORDER-COMPLETION] Initiating refund for order: $orderId');

    try {
      // Get order details to find transaction ID and amount
      final ordersState = _ref.read(ordersProvider);
      final order = ordersState.orders.firstWhere(
        (o) => o.id == orderId,
        orElse: () => throw Exception('Order not found for refund'),
      );

      final refundResult = await _marketplacePaymentService.initiateRefund(
        transactionId: order.id, // Using order ID as transaction ID for now
        amount: order.totalAmount,
        reason: reason,
      );

      if (refundResult.isLeft()) {
        final failure = refundResult.fold((l) => l, (r) => null)!;
        throw Exception('Failed to initiate refund: ${failure.message}');
      }

      debugPrint('🔄 [ORDER-COMPLETION] Refund initiated successfully');
    } catch (e) {
      debugPrint('🔄 [ORDER-COMPLETION] Error initiating refund: $e');
      // Log for manual processing
      await _logRefundError(orderId, e.toString());
    }
  }

  /// Update escrow account status
  Future<void> _updateEscrowStatus(String orderId, EscrowStatus status) async {
    try {
      // Get escrow status to find the escrow account ID
      final escrowStatusResult = await _marketplacePaymentService.getEscrowStatus(orderId);

      if (escrowStatusResult.isRight()) {
        final escrowData = escrowStatusResult.fold((l) => null, (r) => r)!;
        final escrowAccountId = escrowData['escrow_account_id'] as String?;

        if (escrowAccountId != null) {
          await _marketplacePaymentService.updateEscrowStatus(
            escrowAccountId: escrowAccountId,
            status: status,
          );
          debugPrint('🔄 [ORDER-COMPLETION] Escrow status updated: ${status.value}');
        } else {
          debugPrint('🔄 [ORDER-COMPLETION] No escrow account found for order: $orderId');
        }
      }
    } catch (e) {
      debugPrint('🔄 [ORDER-COMPLETION] Error updating escrow status: $e');
    }
  }

  /// Refresh stakeholder data after marketplace operations
  Future<void> _refreshStakeholderData(String orderId) async {
    try {
      // Refresh wallet data
      final walletActions = _ref.read(walletActionsProvider);
      await walletActions.refreshCurrentUserWallet();

      // Refresh transaction history
      final transactionActions = _ref.read(transactionActionsProvider);
      final walletState = _ref.read(currentUserWalletProvider);
      
      if (walletState.wallet != null) {
        await transactionActions.refreshTransactions(walletState.wallet!.id);
      }

      debugPrint('🔄 [ORDER-COMPLETION] Stakeholder data refreshed');
    } catch (e) {
      debugPrint('🔄 [ORDER-COMPLETION] Error refreshing data: $e');
    }
  }

  /// Log escrow release error for manual processing
  Future<void> _logEscrowReleaseError(String orderId, String error) async {
    debugPrint('🔄 [ORDER-COMPLETION] Logging escrow release error: $orderId - $error');
    // TODO: Implement error logging to database for admin review
  }

  /// Log successful fund distribution
  Future<void> _logFundDistribution(String orderId, Map<String, dynamic> data) async {
    debugPrint('🔄 [ORDER-COMPLETION] Logging fund distribution: $orderId');
    // TODO: Implement distribution logging for audit trail
  }

  /// Log refund error for manual processing
  Future<void> _logRefundError(String orderId, String error) async {
    debugPrint('🔄 [ORDER-COMPLETION] Logging refund error: $orderId - $error');
    // TODO: Implement refund error logging for admin review
  }

  /// Get order completion status with marketplace data
  Future<Map<String, dynamic>> getOrderCompletionStatus(String orderId) async {
    try {
      final escrowStatus = await _marketplacePaymentService.getEscrowStatus(orderId);
      
      if (escrowStatus.isRight()) {
        final status = escrowStatus.fold((l) => null, (r) => r)!;
        return {
          'marketplace_enabled': true,
          'escrow_status': status['status'],
          'funds_released': status['funds_released'],
          'distribution_completed': status['distribution_completed'],
          'release_date': status['release_date'],
        };
      }
    } catch (e) {
      debugPrint('🔄 [ORDER-COMPLETION] Error getting completion status: $e');
    }

    return {
      'marketplace_enabled': false,
      'legacy_mode': true,
    };
  }
}

/// Provider for order completion integration
final orderCompletionIntegrationProvider = Provider<OrderCompletionIntegration>((ref) {
  final marketplacePaymentService = ref.watch(marketplacePaymentServiceProvider);
  
  return OrderCompletionIntegration(
    marketplacePaymentService,
    ref,
  );
});

/// Enhanced order actions provider that uses the integration layer
final enhancedOrderActionsProvider = Provider<EnhancedOrderActions>((ref) {
  return EnhancedOrderActions(ref);
});

/// Enhanced order actions class
class EnhancedOrderActions {
  final Ref _ref;

  EnhancedOrderActions(this._ref);

  /// Update order status with marketplace integration
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

    // Handle marketplace integration
    final integration = _ref.read(orderCompletionIntegrationProvider);
    await integration.handleOrderStatusChange(
      orderId: orderId,
      oldStatus: oldStatus,
      newStatus: newStatus,
      changedBy: changedBy,
      reason: reason,
    );
  }

  /// Get order completion status
  Future<Map<String, dynamic>> getOrderCompletionStatus(String orderId) async {
    final integration = _ref.read(orderCompletionIntegrationProvider);
    return await integration.getOrderCompletionStatus(orderId);
  }
}
