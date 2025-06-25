import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/orders/data/models/order.dart';
import '../../../features/payments/data/models/payment_result.dart' as models;
import '../../../features/payments/data/services/payment_service.dart';
import '../../../features/payments/presentation/screens/payment_screen.dart' as payment_screen;
import '../data/services/marketplace_payment_service.dart';
import '../data/models/escrow_account.dart';

import '../data/models/marketplace_payment_method.dart';
import '../data/providers/marketplace_wallet_providers.dart';
import '../presentation/providers/wallet_state_provider.dart';
import '../presentation/providers/wallet_transactions_provider.dart';

/// Integration service that bridges the existing payment system with the new marketplace wallet
class PaymentFlowIntegration {
  final PaymentService _legacyPaymentService;
  final MarketplacePaymentService _marketplacePaymentService;
  final Ref _ref;

  PaymentFlowIntegration(
    this._legacyPaymentService,
    this._marketplacePaymentService,
    this._ref,
  );

  /// Enhanced payment processing that integrates marketplace wallet functionality
  Future<models.PaymentResult> processOrderPayment({
    required Order order,
    required String paymentMethod,
    Map<String, dynamic>? gatewayData,
    String? callbackUrl,
    String? redirectUrl,
  }) async {
    debugPrint('🔄 [PAYMENT-INTEGRATION] Processing order payment with marketplace integration');
    debugPrint('🔄 [PAYMENT-INTEGRATION] Order ID: ${order.id}, Method: $paymentMethod, Amount: ${order.totalAmount}');

    try {
      // Step 1: Create escrow account for the order
      final escrowResult = await _marketplacePaymentService.createEscrowAccount(
        orderId: order.id,
        totalAmount: order.totalAmount,
        currency: 'MYR',
        releaseTrigger: EscrowReleaseTrigger.orderDelivered,
        holdDurationHours: 168, // 7 days
      );

      if (escrowResult.isLeft()) {
        final failure = escrowResult.fold((l) => l, (r) => null)!;
        throw Exception('Failed to create escrow account: ${failure.message}');
      }

      final escrowAccount = escrowResult.fold((l) => null, (r) => r)!;
      debugPrint('🔄 [PAYMENT-INTEGRATION] Escrow account created: ${escrowAccount.id}');

      // Step 2: Calculate commission breakdown
      final commissionResult = await _marketplacePaymentService.calculateCommissionBreakdown(
        orderId: order.id,
      );

      if (commissionResult.isLeft()) {
        final failure = commissionResult.fold((l) => l, (r) => null)!;
        throw Exception('Failed to calculate commission: ${failure.message}');
      }

      final commissionBreakdown = commissionResult.fold((l) => null, (r) => r)!;
      debugPrint('🔄 [PAYMENT-INTEGRATION] Commission calculated - Vendor: ${commissionBreakdown.vendorAmount}, Platform: ${commissionBreakdown.platformFee}');

      // Step 3: Process payment through marketplace payment processor
      final marketplacePaymentResult = await _marketplacePaymentService.processPayment(
        orderId: order.id,
        paymentMethod: _mapPaymentMethod(paymentMethod).value,
        amount: order.totalAmount,
        currency: 'MYR',
        gatewayData: gatewayData,
        callbackUrl: callbackUrl,
        redirectUrl: redirectUrl,
        autoEscrow: true,
        releaseTrigger: EscrowReleaseTrigger.orderDelivered,
        holdDurationHours: 168,
      );

      if (marketplacePaymentResult.isLeft()) {
        final failure = marketplacePaymentResult.fold((l) => l, (r) => null)!;
        throw Exception('Marketplace payment failed: ${failure.message}');
      }

      final paymentData = marketplacePaymentResult.fold((l) => null, (r) => r)!;
      debugPrint('🔄 [PAYMENT-INTEGRATION] Marketplace payment processed: ${paymentData.transactionId}');

      // Step 4: Return enhanced payment result with marketplace data
      return models.PaymentResult.success(
        transactionId: paymentData.transactionId ?? '',
        metadata: {
          'payment_method': paymentMethod,
          'client_secret': paymentData.clientSecret,
          'escrow_account_id': escrowAccount.id,
          'commission_breakdown': commissionBreakdown.toJson(),
          'marketplace_enabled': true,
          'auto_escrow': true,
          'gateway': paymentData.metadata?['gateway'],
          'payment_intent_id': paymentData.metadata?['payment_intent_id'],
        },
      );
    } catch (e) {
      debugPrint('🔄 [PAYMENT-INTEGRATION] Payment processing failed: $e');
      
      // Fallback to legacy payment system for backward compatibility
      debugPrint('🔄 [PAYMENT-INTEGRATION] Falling back to legacy payment system');
      return await _legacyPaymentService.createPaymentIntent(
        orderId: order.id,
        amount: order.totalAmount,
        currency: 'myr',
      ).then((result) {
        return models.PaymentResult.success(
          transactionId: result['transaction_id'] ?? '',
          metadata: {
            'payment_method': paymentMethod,
            'client_secret': result['client_secret'],
            'marketplace_enabled': false,
            'fallback_mode': true,
          },
        );
      }).catchError((error) {
        return models.PaymentResult.failure(
          errorMessage: error.toString(),
          metadata: {'fallback_failed': true},
        );
      });
    }
  }

  /// Handle payment success callback with marketplace integration
  Future<void> handlePaymentSuccess({
    required String orderId,
    required String transactionId,
    required Map<String, dynamic> paymentMetadata,
  }) async {
    debugPrint('🔄 [PAYMENT-INTEGRATION] Handling payment success for order: $orderId');

    try {
      final isMarketplacePayment = paymentMetadata['marketplace_enabled'] == true;
      
      if (isMarketplacePayment) {
        // Handle marketplace payment success
        await _handleMarketplacePaymentSuccess(orderId, transactionId, paymentMetadata);
      } else {
        // Handle legacy payment success
        await _handleLegacyPaymentSuccess(orderId, transactionId, paymentMetadata);
      }

      // Refresh wallet data for all affected stakeholders
      await _refreshStakeholderWallets(orderId);
      
      debugPrint('🔄 [PAYMENT-INTEGRATION] Payment success handling completed');
    } catch (e) {
      debugPrint('🔄 [PAYMENT-INTEGRATION] Error handling payment success: $e');
      rethrow;
    }
  }

  /// Handle marketplace payment success
  Future<void> _handleMarketplacePaymentSuccess(
    String orderId,
    String transactionId,
    Map<String, dynamic> metadata,
  ) async {
    debugPrint('🔄 [PAYMENT-INTEGRATION] Processing marketplace payment success');

    // The marketplace webhook handler will automatically:
    // 1. Update payment transaction status
    // 2. Move funds to escrow
    // 3. Create wallet transactions for stakeholders
    // 4. Update order payment status
    
    // We just need to trigger any additional business logic
    await _triggerPostPaymentActions(orderId, metadata);
  }

  /// Handle legacy payment success
  Future<void> _handleLegacyPaymentSuccess(
    String orderId,
    String transactionId,
    Map<String, dynamic> metadata,
  ) async {
    debugPrint('🔄 [PAYMENT-INTEGRATION] Processing legacy payment success');

    // For legacy payments, we need to manually create marketplace records
    // This ensures backward compatibility while gradually migrating to the new system
    
    try {
      // Create escrow account retroactively
      await _marketplacePaymentService.createEscrowAccount(
        orderId: orderId,
        totalAmount: metadata['amount'] ?? 0.0,
        currency: 'MYR',
        releaseTrigger: EscrowReleaseTrigger.orderDelivered,
        holdDurationHours: 168,
      );

      // Calculate and distribute commissions
      await _marketplacePaymentService.calculateCommissionBreakdown(orderId: orderId);
      
      debugPrint('🔄 [PAYMENT-INTEGRATION] Legacy payment migrated to marketplace system');
    } catch (e) {
      debugPrint('🔄 [PAYMENT-INTEGRATION] Failed to migrate legacy payment: $e');
      // Continue without marketplace features for this payment
    }
  }

  /// Trigger post-payment actions
  Future<void> _triggerPostPaymentActions(String orderId, Map<String, dynamic> metadata) async {
    // Trigger any additional business logic after successful payment
    // This could include:
    // - Sending notifications
    // - Updating inventory
    // - Triggering order fulfillment workflows
    // - Analytics tracking
    
    debugPrint('🔄 [PAYMENT-INTEGRATION] Triggering post-payment actions for order: $orderId');
  }

  /// Refresh wallet data for all stakeholders involved in the order
  Future<void> _refreshStakeholderWallets(String orderId) async {
    try {
      // Refresh current user wallet
      final walletActions = _ref.read(walletActionsProvider);
      await walletActions.refreshCurrentUserWallet();

      // Refresh transaction history
      final transactionActions = _ref.read(transactionActionsProvider);
      final walletState = _ref.read(currentUserWalletProvider);
      
      if (walletState.wallet != null) {
        await transactionActions.refreshTransactions(walletState.wallet!.id);
      }

      debugPrint('🔄 [PAYMENT-INTEGRATION] Stakeholder wallets refreshed');
    } catch (e) {
      debugPrint('🔄 [PAYMENT-INTEGRATION] Error refreshing wallets: $e');
      // Non-critical error, continue
    }
  }

  /// Map payment method from legacy format to marketplace format
  MarketplacePaymentMethod _mapPaymentMethod(String legacyMethod) {
    switch (legacyMethod.toLowerCase()) {
      case 'credit_card':
      case 'card':
        return MarketplacePaymentMethod.creditCard;
      case 'fpx':
        return MarketplacePaymentMethod.fpx;
      case 'grabpay':
        return MarketplacePaymentMethod.grabpay;
      case 'tng':
        return MarketplacePaymentMethod.tng;
      case 'boost':
        return MarketplacePaymentMethod.boost;
      case 'shopeepay':
        return MarketplacePaymentMethod.shopeepay;
      default:
        return MarketplacePaymentMethod.creditCard;
    }
  }

  /// Check if marketplace features are available for an order
  Future<bool> isMarketplaceEnabled(String orderId) async {
    try {
      // Check if the order has marketplace features enabled
      // This could be based on:
      // - Feature flags
      // - Order type
      // - Customer preferences
      // - System configuration
      
      return true; // Enable marketplace for all orders by default
    } catch (e) {
      debugPrint('🔄 [PAYMENT-INTEGRATION] Error checking marketplace availability: $e');
      return false; // Fallback to legacy system
    }
  }

  /// Get payment status with marketplace integration
  Future<Map<String, dynamic>> getPaymentStatus(String orderId) async {
    try {
      // Try to get marketplace payment status first
      final marketplaceStatus = await _marketplacePaymentService.getPaymentStatus(orderId: orderId);

      if (marketplaceStatus.isRight()) {
        final status = marketplaceStatus.fold((l) => null, (r) => r)!;
        return {
          'status': status.orderPaymentStatus ?? 'unknown',
          'marketplace_enabled': true,
          'escrow_status': status.escrowStatus ?? 'none',
          'commission_calculated': true,
          'funds_distributed': status.isReleased,
          'payment_reference': status.paymentReference,
          'escrow_amount': status.escrowAmount,
          'transaction_status': status.transactionStatus,
        };
      }
    } catch (e) {
      debugPrint('🔄 [PAYMENT-INTEGRATION] Error getting marketplace status: $e');
    }

    // Fallback to legacy payment status
    try {
      final legacyStatus = await _legacyPaymentService.getPaymentStatus(orderId);
      return {
        'status': legacyStatus?.status.name ?? 'unknown',
        'marketplace_enabled': false,
        'legacy_mode': true,
      };
    } catch (e) {
      debugPrint('🔄 [PAYMENT-INTEGRATION] Error getting legacy status: $e');
      return {
        'status': 'unknown',
        'marketplace_enabled': false,
        'error': e.toString(),
      };
    }
  }
}

/// Provider for payment flow integration
final paymentFlowIntegrationProvider = Provider<PaymentFlowIntegration>((ref) {
  final legacyPaymentService = ref.watch(payment_screen.paymentServiceProvider);
  final marketplacePaymentService = ref.watch(marketplacePaymentServiceProvider);

  return PaymentFlowIntegration(
    legacyPaymentService,
    marketplacePaymentService,
    ref,
  );
});

/// Enhanced payment actions provider that uses the integration layer
final enhancedPaymentActionsProvider = Provider<EnhancedPaymentActions>((ref) {
  return EnhancedPaymentActions(ref);
});

/// Enhanced payment actions class
class EnhancedPaymentActions {
  final Ref _ref;

  EnhancedPaymentActions(this._ref);

  /// Process order payment with marketplace integration
  Future<models.PaymentResult> processOrderPayment({
    required Order order,
    required String paymentMethod,
    Map<String, dynamic>? gatewayData,
    String? callbackUrl,
    String? redirectUrl,
  }) async {
    final integration = _ref.read(paymentFlowIntegrationProvider);
    return await integration.processOrderPayment(
      order: order,
      paymentMethod: paymentMethod,
      gatewayData: gatewayData,
      callbackUrl: callbackUrl,
      redirectUrl: redirectUrl,
    );
  }

  /// Handle payment success
  Future<void> handlePaymentSuccess({
    required String orderId,
    required String transactionId,
    required Map<String, dynamic> paymentMetadata,
  }) async {
    final integration = _ref.read(paymentFlowIntegrationProvider);
    await integration.handlePaymentSuccess(
      orderId: orderId,
      transactionId: transactionId,
      paymentMetadata: paymentMetadata,
    );
  }

  /// Get payment status
  Future<Map<String, dynamic>> getPaymentStatus(String orderId) async {
    final integration = _ref.read(paymentFlowIntegrationProvider);
    return await integration.getPaymentStatus(orderId);
  }

  /// Check if marketplace is enabled
  Future<bool> isMarketplaceEnabled(String orderId) async {
    final integration = _ref.read(paymentFlowIntegrationProvider);
    return await integration.isMarketplaceEnabled(orderId);
  }
}
