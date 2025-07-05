import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../orders/data/models/order.dart';
// Wallet services will be imported when integration is fully implemented
// import '../data/services/enhanced_customer_wallet_service.dart';
// import '../data/services/enhanced_transaction_service.dart';
import '../data/models/customer_wallet.dart';
// import '../presentation/providers/enhanced_customer_wallet_provider.dart';
// import '../presentation/providers/enhanced_transaction_provider.dart';
import '../presentation/providers/wallet_validation_provider.dart' as validation;
import '../../orders/data/services/enhanced_payment_service.dart';
import '../../orders/presentation/providers/enhanced_payment_provider.dart';

/// Wallet checkout integration result
class WalletCheckoutResult {
  final bool success;
  final String? transactionId;
  final double? walletAmountUsed;
  final double? cardAmountUsed;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  const WalletCheckoutResult({
    required this.success,
    this.transactionId,
    this.walletAmountUsed,
    this.cardAmountUsed,
    this.errorMessage,
    this.metadata,
  });

  factory WalletCheckoutResult.success({
    required String transactionId,
    required double walletAmountUsed,
    double? cardAmountUsed,
    Map<String, dynamic>? metadata,
  }) {
    return WalletCheckoutResult(
      success: true,
      transactionId: transactionId,
      walletAmountUsed: walletAmountUsed,
      cardAmountUsed: cardAmountUsed,
      metadata: metadata,
    );
  }

  factory WalletCheckoutResult.failure(String errorMessage) {
    return WalletCheckoutResult(
      success: false,
      errorMessage: errorMessage,
    );
  }

  bool get isSplitPayment => cardAmountUsed != null && cardAmountUsed! > 0;
  bool get isWalletOnly => cardAmountUsed == null || cardAmountUsed == 0;
}

/// Service for integrating wallet payments with checkout flow
class WalletCheckoutIntegrationService {
  // Services will be used when wallet integration is fully implemented
  // final EnhancedCustomerWalletService _walletService;
  // final EnhancedTransactionService _transactionService;
  final EnhancedPaymentService _paymentService;

  WalletCheckoutIntegrationService(
    // this._walletService,
    // this._transactionService,
    this._paymentService,
  );

  /// Process wallet payment for order
  Future<WalletCheckoutResult> processWalletPayment({
    required Order order,
    required CustomerWallet wallet,
    String? fallbackPaymentMethodId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      debugPrint('🔍 [WALLET-CHECKOUT] Processing wallet payment for order: ${order.id}');
      debugPrint('🔍 [WALLET-CHECKOUT] Order amount: RM ${order.totalAmount.toStringAsFixed(2)}');
      debugPrint('🔍 [WALLET-CHECKOUT] Wallet balance: RM ${wallet.availableBalance.toStringAsFixed(2)}');

      final orderAmount = order.totalAmount;
      final walletBalance = wallet.availableBalance;

      // Check if wallet can cover full amount
      if (walletBalance >= orderAmount) {
        return await _processFullWalletPayment(
          order: order,
          wallet: wallet,
          amount: orderAmount,
          metadata: metadata,
        );
      } else if (fallbackPaymentMethodId != null) {
        return await _processSplitPayment(
          order: order,
          wallet: wallet,
          walletAmount: walletBalance,
          cardAmount: orderAmount - walletBalance,
          fallbackPaymentMethodId: fallbackPaymentMethodId,
          metadata: metadata,
        );
      } else {
        return WalletCheckoutResult.failure(
          'Insufficient wallet balance (RM ${wallet.formattedAvailableBalance}) for order total (RM ${order.totalAmount.toStringAsFixed(2)}). Please add a payment method for the remaining amount.',
        );
      }
    } catch (e) {
      debugPrint('❌ [WALLET-CHECKOUT] Error processing wallet payment: $e');
      return WalletCheckoutResult.failure('Failed to process wallet payment: $e');
    }
  }

  /// Process full wallet payment
  Future<WalletCheckoutResult> _processFullWalletPayment({
    required Order order,
    required CustomerWallet wallet,
    required double amount,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      debugPrint('💰 [WALLET-CHECKOUT] Processing full wallet payment: RM ${amount.toStringAsFixed(2)}');

      // Process wallet deduction via Edge Function
      final deductionResult = await _paymentService.processPayment(
        orderId: order.id,
        paymentMethod: PaymentMethodType.wallet,
        amount: amount,
        metadata: {
          'order_id': order.id,
          'order_number': order.orderNumber,
          'vendor_id': order.vendorId,
          'payment_method': 'wallet',
          'description': 'Payment for order ${order.orderNumber}',
          ...?metadata,
        },
      );

      if (deductionResult.success) {
        debugPrint('✅ [WALLET-CHECKOUT] Full wallet payment successful: ${deductionResult.transactionId}');
        return WalletCheckoutResult.success(
          transactionId: deductionResult.transactionId!,
          walletAmountUsed: amount,
          metadata: {
            'payment_type': 'wallet_only',
            'transaction_id': deductionResult.transactionId,
          },
        );
      } else {
        debugPrint('❌ [WALLET-CHECKOUT] Wallet deduction failed: ${deductionResult.errorMessage}');
        return WalletCheckoutResult.failure(deductionResult.errorMessage ?? 'Wallet payment failed');
      }
    } catch (e) {
      debugPrint('❌ [WALLET-CHECKOUT] Error in full wallet payment: $e');
      return WalletCheckoutResult.failure('Failed to process wallet payment: $e');
    }
  }

  /// Process split payment (wallet + card)
  Future<WalletCheckoutResult> _processSplitPayment({
    required Order order,
    required CustomerWallet wallet,
    required double walletAmount,
    required double cardAmount,
    required String fallbackPaymentMethodId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      debugPrint('💳 [WALLET-CHECKOUT] Processing split payment:');
      debugPrint('💳 [WALLET-CHECKOUT] Wallet: RM ${walletAmount.toStringAsFixed(2)}');
      debugPrint('💳 [WALLET-CHECKOUT] Card: RM ${cardAmount.toStringAsFixed(2)}');

      // Step 1: Process wallet portion first
      final walletPaymentResult = await _paymentService.processPayment(
        orderId: order.id,
        paymentMethod: PaymentMethodType.wallet,
        amount: walletAmount,
        metadata: {
          'order_id': order.id,
          'order_number': order.orderNumber,
          'vendor_id': order.vendorId,
          'payment_method': 'split_payment',
          'payment_portion': 'wallet',
          'total_order_amount': order.totalAmount,
          'wallet_portion': walletAmount,
          'card_portion': cardAmount,
          ...?metadata,
        },
      );

      if (!walletPaymentResult.success) {
        return WalletCheckoutResult.failure('Wallet payment failed: ${walletPaymentResult.errorMessage}');
      }

      final walletTransactionId = walletPaymentResult.transactionId!;
      debugPrint('✅ [WALLET-CHECKOUT] Wallet portion processed: $walletTransactionId');

      // Step 2: Process card payment for remaining amount
      try {
        final cardPaymentResult = await _paymentService.processPayment(
          orderId: order.id,
          paymentMethod: PaymentMethodType.card,
          amount: cardAmount,
          savedCardId: fallbackPaymentMethodId,
          metadata: {
            'payment_type': 'split_payment',
            'payment_portion': 'card',
            'wallet_transaction_id': walletTransactionId,
            'wallet_amount': walletAmount,
            'card_amount': cardAmount,
            ...?metadata,
          },
        );

        if (cardPaymentResult.success) {
          debugPrint('✅ [WALLET-CHECKOUT] Split payment successful');
          return WalletCheckoutResult.success(
            transactionId: '${walletTransactionId}_${cardPaymentResult.transactionId}',
            walletAmountUsed: walletAmount,
            cardAmountUsed: cardAmount,
            metadata: {
              'payment_type': 'split_payment',
              'wallet_transaction_id': walletTransactionId,
              'card_transaction_id': cardPaymentResult.transactionId,
              'wallet_balance_after': wallet.availableBalance - walletAmount,
            },
          );
        } else {
          // Card payment failed, need to refund wallet
          await _refundWalletPayment(walletTransactionId, walletAmount, order);
          return WalletCheckoutResult.failure(
            'Card payment failed: ${cardPaymentResult.errorMessage}. Wallet amount has been refunded.',
          );
        }
      } catch (e) {
        // Card payment failed, need to refund wallet
        await _refundWalletPayment(walletTransactionId, walletAmount, order);
        return WalletCheckoutResult.failure(
          'Card payment failed: $e. Wallet amount has been refunded.',
        );
      }
    } catch (e) {
      debugPrint('❌ [WALLET-CHECKOUT] Error in split payment: $e');
      return WalletCheckoutResult.failure('Failed to process split payment: $e');
    }
  }

  /// Refund wallet payment in case of split payment failure
  Future<void> _refundWalletPayment(String walletTransactionId, double amount, Order order) async {
    try {
      debugPrint('🔄 [WALLET-CHECKOUT] Refunding wallet payment: RM ${amount.toStringAsFixed(2)}');

      // TODO: Implement wallet refund via Edge Function
      // For now, we'll log the refund requirement
      debugPrint('⚠️ [WALLET-CHECKOUT] Wallet refund required but not implemented: RM ${amount.toStringAsFixed(2)}');
      debugPrint('⚠️ [WALLET-CHECKOUT] Original transaction: $walletTransactionId');
      debugPrint('⚠️ [WALLET-CHECKOUT] Order: ${order.orderNumber}');
      debugPrint('⚠️ [WALLET-CHECKOUT] Manual intervention may be required');

      debugPrint('✅ [WALLET-CHECKOUT] Wallet refund completed');
    } catch (e) {
      debugPrint('❌ [WALLET-CHECKOUT] Failed to refund wallet: $e');
      // This is a critical error that should be logged for manual intervention
    }
  }

  /// Validate wallet for order payment
  Future<validation.PaymentOptions> validateWalletForOrder({
    required Order order,
    required CustomerWallet wallet,
  }) async {
    try {
      final orderAmount = order.totalAmount;
      final walletBalance = wallet.availableBalance;

      if (walletBalance >= orderAmount) {
        return validation.PaymentOptions(
          totalAmount: orderAmount,
          walletAmount: orderAmount,
          cardAmount: 0.0,
          canPayWithWalletOnly: true,
          needsCard: false,
          needsTopUp: false,
          suggestedTopUp: 0.0,
        );
      } else {
        final shortfall = orderAmount - walletBalance;
        return validation.PaymentOptions(
          totalAmount: orderAmount,
          walletAmount: walletBalance,
          cardAmount: shortfall,
          canPayWithWalletOnly: false,
          needsCard: true,
          needsTopUp: false,
          suggestedTopUp: shortfall,
        );
      }
    } catch (e) {
      debugPrint('❌ [WALLET-CHECKOUT] Error validating wallet: $e');
      return validation.PaymentOptions.cardOnly(order.totalAmount);
    }
  }
}

/// Provider for wallet checkout integration service
final walletCheckoutIntegrationServiceProvider = Provider<WalletCheckoutIntegrationService>((ref) {
  // final walletService = ref.watch(enhancedCustomerWalletServiceProvider);
  // final transactionService = ref.watch(enhancedTransactionServiceProvider);
  final paymentService = EnhancedPaymentService(); // TODO: Create provider for this
  return WalletCheckoutIntegrationService(paymentService);
});
