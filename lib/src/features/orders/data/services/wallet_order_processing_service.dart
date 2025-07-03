import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order.dart';
import '../models/enhanced_cart_models.dart';

import '../../../marketplace_wallet/data/models/customer_wallet.dart';
import '../../../user_management/domain/customer_profile.dart';
import '../../../marketplace_wallet/integration/wallet_checkout_integration_service.dart';
import '../../../marketplace_wallet/presentation/providers/customer_wallet_provider.dart';
import '../../../marketplace_wallet/presentation/providers/customer_payment_methods_provider.dart';
import 'enhanced_order_placement_service.dart';
import '../../presentation/providers/enhanced_payment_provider.dart';

/// Result of wallet order processing
class WalletOrderProcessingResult {
  final bool success;
  final Order? order;
  final WalletCheckoutResult? walletResult;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  const WalletOrderProcessingResult({
    required this.success,
    this.order,
    this.walletResult,
    this.errorMessage,
    this.metadata,
  });

  factory WalletOrderProcessingResult.success({
    required Order order,
    required WalletCheckoutResult walletResult,
    Map<String, dynamic>? metadata,
  }) {
    return WalletOrderProcessingResult(
      success: true,
      order: order,
      walletResult: walletResult,
      metadata: metadata,
    );
  }

  factory WalletOrderProcessingResult.failure(String errorMessage) {
    return WalletOrderProcessingResult(
      success: false,
      errorMessage: errorMessage,
    );
  }

  bool get isWalletPayment => walletResult != null;
  bool get isSplitPayment => walletResult?.isSplitPayment ?? false;
  double get walletAmountUsed => walletResult?.walletAmountUsed ?? 0.0;
  double get cardAmountUsed => walletResult?.cardAmountUsed ?? 0.0;
}

/// Service for processing orders with wallet payments
class WalletOrderProcessingService {
  final WalletCheckoutIntegrationService _walletCheckoutService;
  final EnhancedOrderPlacementService _orderPlacementService;
  final Ref _ref;

  WalletOrderProcessingService(
    this._walletCheckoutService,
    this._orderPlacementService,
    this._ref,
  );

  /// Process order with wallet payment
  Future<WalletOrderProcessingResult> processOrderWithWallet({
    required EnhancedCartState cartState,
    required String paymentMethod,
    String? specialInstructions,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      debugPrint('🛒 [WALLET-ORDER] Starting wallet order processing');
      debugPrint('🛒 [WALLET-ORDER] Payment method: $paymentMethod');
      debugPrint('🛒 [WALLET-ORDER] Cart total: RM ${cartState.totalAmount.toStringAsFixed(2)}');

      // Step 1: Validate wallet payment method
      if (paymentMethod != 'wallet') {
        return WalletOrderProcessingResult.failure('Invalid payment method for wallet processing: $paymentMethod');
      }

      // Step 2: Get customer wallet
      final walletState = _ref.read(customerWalletProvider);
      CustomerWallet? wallet;

      if (walletState.isLoading) {
        // Wait for wallet to load
        await Future.delayed(const Duration(seconds: 2));
        final updatedState = _ref.read(customerWalletProvider);
        wallet = updatedState.wallet;
      } else if (walletState.hasError) {
        wallet = null;
      } else {
        wallet = walletState.wallet;
      }

      if (wallet == null) {
        return WalletOrderProcessingResult.failure('Customer wallet not found. Please create a wallet first.');
      }

      // Step 3: Validate wallet for order
      final paymentOptions = await _walletCheckoutService.validateWalletForOrder(
        order: _createOrderFromCart(cartState, specialInstructions),
        wallet: wallet,
      );

      // Step 4: Get fallback payment method if needed
      String? fallbackPaymentMethodId;
      if (paymentOptions.needsCard) {
        final paymentMethods = await _ref.read(customerValidPaymentMethodsProvider.future);
        if (paymentMethods.isNotEmpty) {
          // Use the default payment method
          final defaultMethod = paymentMethods.firstWhere(
            (method) => method.isDefault,
            orElse: () => paymentMethods.first,
          );
          fallbackPaymentMethodId = defaultMethod.stripePaymentMethodId;
          debugPrint('🛒 [WALLET-ORDER] Using fallback payment method: ${defaultMethod.displayName}');
        } else {
          return WalletOrderProcessingResult.failure(
            'Insufficient wallet balance (${wallet.formattedAvailableBalance}) and no saved payment methods for split payment. Please add a payment method or top up your wallet.',
          );
        }
      }

      // Step 5: Create order first
      final orderResult = await _orderPlacementService.placeOrder(
        cartState: cartState,
        deliveryMethod: cartState.deliveryMethod,
        deliveryAddress: cartState.selectedAddress,
        scheduledDeliveryTime: cartState.scheduledDeliveryTime,
        specialInstructions: specialInstructions,
        paymentMethod: PaymentMethodType.wallet,
        paymentDetails: {
          'wallet_id': wallet.id,
          'fallback_payment_method_id': fallbackPaymentMethodId,
        },
        promoCode: null,
      );

      if (!orderResult.success) {
        return WalletOrderProcessingResult.failure('Failed to create order: ${orderResult.error ?? 'Unknown error'}');
      }

      final order = orderResult.order!;
      debugPrint('✅ [WALLET-ORDER] Order created: ${order.id}');

      // Step 6: Process wallet payment
      final walletPaymentResult = await _walletCheckoutService.processWalletPayment(
        order: order,
        wallet: wallet,
        fallbackPaymentMethodId: fallbackPaymentMethodId,
        metadata: {
          'order_id': order.id,
          'special_instructions': specialInstructions,
          ...?metadata,
        },
      );

      if (!walletPaymentResult.success) {
        // Payment failed, need to cancel the order
        await _cancelOrderDueToPaymentFailure(order.id, walletPaymentResult.errorMessage ?? 'Payment failed');
        return WalletOrderProcessingResult.failure(walletPaymentResult.errorMessage ?? 'Wallet payment failed');
      }

      debugPrint('✅ [WALLET-ORDER] Wallet payment successful');
      debugPrint('✅ [WALLET-ORDER] Transaction ID: ${walletPaymentResult.transactionId}');

      // Step 7: Update order with payment information
      final updatedOrder = await _updateOrderWithPaymentInfo(order, walletPaymentResult);

      return WalletOrderProcessingResult.success(
        order: updatedOrder,
        walletResult: walletPaymentResult,
        metadata: {
          'order_id': updatedOrder.id,
          'payment_type': walletPaymentResult.isSplitPayment ? 'split_payment' : 'wallet_only',
          'wallet_amount': walletPaymentResult.walletAmountUsed,
          'card_amount': walletPaymentResult.cardAmountUsed,
        },
      );
    } catch (e) {
      debugPrint('❌ [WALLET-ORDER] Error processing wallet order: $e');
      return WalletOrderProcessingResult.failure('Failed to process order with wallet: $e');
    }
  }

  /// Create order object from cart state for validation
  Order _createOrderFromCart(EnhancedCartState cartState, String? specialInstructions) {
    // This is a temporary order for validation purposes
    return Order(
      id: 'temp-order-id',
      orderNumber: 'TEMP-ORDER',
      status: OrderStatus.pending,
      items: cartState.items.map((cartItem) => OrderItem(
        id: cartItem.id,
        menuItemId: cartItem.menuItemId,
        name: cartItem.name,
        description: cartItem.description,
        quantity: cartItem.quantity,
        unitPrice: cartItem.unitPrice,
        totalPrice: cartItem.totalPrice,
        customizations: cartItem.customizations,
        notes: cartItem.notes,
      )).toList(),
      vendorId: cartState.items.first.vendorId,
      vendorName: cartState.items.first.vendorName,
      customerId: cartState.customerId ?? 'temp-customer-id',
      customerName: 'Customer',
      deliveryDate: DateTime.now().add(const Duration(hours: 1)),
      deliveryAddress: _convertCustomerAddressToAddress(cartState.selectedAddress),
      subtotal: cartState.subtotal,
      deliveryFee: cartState.deliveryFee,
      sstAmount: cartState.sstAmount,
      totalAmount: cartState.totalAmount,
      notes: specialInstructions,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Convert CustomerAddress to Address
  Address _convertCustomerAddressToAddress(CustomerAddress? customerAddress) {
    if (customerAddress == null) {
      return const Address(
        street: 'Temp Address',
        city: 'Temp City',
        state: 'Temp State',
        postalCode: '00000',
        country: 'Malaysia',
      );
    }

    return Address(
      street: customerAddress.addressLine1,
      city: customerAddress.city,
      state: customerAddress.state,
      postalCode: customerAddress.postalCode,
      country: customerAddress.country,
    );
  }

  /// Cancel order due to payment failure
  Future<void> _cancelOrderDueToPaymentFailure(String orderId, String reason) async {
    try {
      debugPrint('🚫 [WALLET-ORDER] Cancelling order due to payment failure: $orderId');
      // TODO: Implement order cancellation
      // await _orderService.cancelOrder(orderId: orderId, reason: 'Payment failed: $reason');
    } catch (e) {
      debugPrint('❌ [WALLET-ORDER] Failed to cancel order: $e');
    }
  }

  /// Update order with payment information
  Future<Order> _updateOrderWithPaymentInfo(Order order, WalletCheckoutResult walletResult) async {
    try {
      // TODO: Update order with payment transaction details
      // This would typically update the order status and add payment metadata
      return order.copyWith(
        status: OrderStatus.confirmed,
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ [WALLET-ORDER] Failed to update order with payment info: $e');
      return order;
    }
  }
}

/// Provider for wallet order processing service
final walletOrderProcessingServiceProvider = Provider<WalletOrderProcessingService>((ref) {
  final walletCheckoutService = ref.watch(walletCheckoutIntegrationServiceProvider);
  final orderPlacementService = EnhancedOrderPlacementService(); // TODO: Create provider for this
  return WalletOrderProcessingService(walletCheckoutService, orderPlacementService, ref);
});
