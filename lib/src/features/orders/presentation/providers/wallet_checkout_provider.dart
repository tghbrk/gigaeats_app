import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../marketplace_wallet/integration/wallet_checkout_integration_service.dart';
import '../../../marketplace_wallet/presentation/providers/customer_wallet_provider.dart';
import '../../../marketplace_wallet/presentation/providers/wallet_validation_provider.dart';
import '../../data/services/wallet_order_processing_service.dart';
import '../../data/models/enhanced_cart_models.dart';
import '../../data/models/order.dart';
import 'enhanced_cart_provider.dart';
import 'checkout_flow_provider.dart';

/// Wallet checkout state
class WalletCheckoutState {
  final bool isProcessing;
  final WalletOrderProcessingResult? result;
  final String? errorMessage;
  final DateTime lastUpdated;

  const WalletCheckoutState({
    this.isProcessing = false,
    this.result,
    this.errorMessage,
    required this.lastUpdated,
  });

  WalletCheckoutState copyWith({
    bool? isProcessing,
    WalletOrderProcessingResult? result,
    String? errorMessage,
    DateTime? lastUpdated,
  }) {
    return WalletCheckoutState(
      isProcessing: isProcessing ?? this.isProcessing,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  bool get hasError => errorMessage != null;
  bool get isSuccess => result?.success == true;
  bool get hasResult => result != null;
}

/// Wallet checkout notifier
class WalletCheckoutNotifier extends StateNotifier<WalletCheckoutState> {
  final WalletOrderProcessingService _orderProcessingService;
  final Ref _ref;

  WalletCheckoutNotifier(this._orderProcessingService, this._ref)
      : super(WalletCheckoutState(lastUpdated: DateTime.now()));

  /// Process checkout with wallet payment
  Future<void> processWalletCheckout({
    String? specialInstructions,
    Map<String, dynamic>? metadata,
  }) async {
    state = state.copyWith(
      isProcessing: true,
      errorMessage: null,
      result: null,
      lastUpdated: DateTime.now(),
    );

    try {
      debugPrint('🛒 [WALLET-CHECKOUT] Starting wallet checkout process');

      // Get current cart state
      final cartState = _ref.read(enhancedCartProvider);
      
      // Validate cart
      if (cartState.items.isEmpty) {
        throw Exception('Cart is empty');
      }

      if (cartState.selectedAddress == null) {
        throw Exception('Delivery address not selected');
      }

      // Get checkout flow state to ensure wallet is selected
      final checkoutState = _ref.read(checkoutFlowProvider);
      if (checkoutState.selectedPaymentMethod != 'wallet') {
        throw Exception('Wallet payment method not selected');
      }

      debugPrint('🛒 [WALLET-CHECKOUT] Cart validated, processing order...');

      // Process order with wallet payment
      final result = await _orderProcessingService.processOrderWithWallet(
        cartState: cartState,
        paymentMethod: 'wallet',
        specialInstructions: specialInstructions,
        metadata: {
          'checkout_timestamp': DateTime.now().toIso8601String(),
          'delivery_method': cartState.deliveryMethod?.name,
          'scheduled_delivery': cartState.scheduledDeliveryTime?.toIso8601String(),
          ...?metadata,
        },
      );

      if (result.success) {
        debugPrint('✅ [WALLET-CHECKOUT] Wallet checkout successful');
        debugPrint('✅ [WALLET-CHECKOUT] Order ID: ${result.order?.id}');
        debugPrint('✅ [WALLET-CHECKOUT] Payment type: ${result.isSplitPayment ? 'Split' : 'Wallet only'}');
        
        state = state.copyWith(
          isProcessing: false,
          result: result,
          errorMessage: null,
          lastUpdated: DateTime.now(),
        );

        // Clear cart after successful order
        _ref.read(enhancedCartProvider.notifier).clearCart();
        
        // Reset checkout flow
        _ref.read(checkoutFlowProvider.notifier).reset();
      } else {
        debugPrint('❌ [WALLET-CHECKOUT] Wallet checkout failed: ${result.errorMessage}');
        state = state.copyWith(
          isProcessing: false,
          errorMessage: result.errorMessage,
          lastUpdated: DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('❌ [WALLET-CHECKOUT] Checkout error: $e');
      state = state.copyWith(
        isProcessing: false,
        errorMessage: e.toString(),
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// Validate wallet for current cart
  Future<PaymentOptions?> validateWalletForCurrentCart() async {
    try {
      final cartState = _ref.read(enhancedCartProvider);
      if (cartState.items.isEmpty) {
        return null;
      }

      final walletCheckoutService = _ref.read(walletCheckoutIntegrationServiceProvider);
      
      // Create temporary order for validation
      final tempOrder = _createTempOrderFromCart(cartState);
      
      // Get wallet from provider
      final walletState = _ref.read(customerWalletProvider);
      final wallet = walletState.wallet;

      if (wallet == null) {
        return null;
      }

      return await walletCheckoutService.validateWalletForOrder(
        order: tempOrder,
        wallet: wallet,
      );
    } catch (e) {
      debugPrint('❌ [WALLET-CHECKOUT] Validation error: $e');
      return null;
    }
  }

  /// Create temporary order from cart for validation
  Order _createTempOrderFromCart(EnhancedCartState cartState) {
    return Order(
      id: 'temp-validation-order',
      orderNumber: 'TEMP-VALIDATION',
      status: OrderStatus.pending,
      items: cartState.items.map((cartItem) => OrderItem(
        id: cartItem.id,
        menuItemId: cartItem.menuItemId,
        name: cartItem.name,
        description: cartItem.description ?? '',
        quantity: cartItem.quantity,
        unitPrice: cartItem.unitPrice,
        totalPrice: cartItem.totalPrice,
        customizations: cartItem.customizations,
        notes: cartItem.notes,
      )).toList(),
      vendorId: cartState.items.first.vendorId,
      vendorName: cartState.items.first.vendorName,
      customerId: cartState.customerId ?? 'temp-customer',
      customerName: 'Customer',
      deliveryDate: DateTime.now().add(const Duration(hours: 1)),
      deliveryAddress: cartState.selectedAddress != null
          ? Address(
              street: cartState.selectedAddress!.addressLine1,
              city: cartState.selectedAddress!.city,
              state: cartState.selectedAddress!.state,
              postalCode: cartState.selectedAddress!.postalCode,
              country: cartState.selectedAddress!.country,
            )
          : const Address(
              street: 'Temp Address',
              city: 'Temp City',
              state: 'Temp State',
              postalCode: '00000',
              country: 'Malaysia',
            ),
      subtotal: cartState.subtotal,
      deliveryFee: cartState.deliveryFee,
      sstAmount: cartState.sstAmount,
      totalAmount: cartState.totalAmount,
      notes: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Clear checkout state
  void clearState() {
    state = WalletCheckoutState(lastUpdated: DateTime.now());
  }

  /// Retry last failed checkout
  Future<void> retryCheckout() async {
    if (state.hasError) {
      await processWalletCheckout();
    }
  }
}

/// Wallet checkout provider
final walletCheckoutProvider = StateNotifierProvider<WalletCheckoutNotifier, WalletCheckoutState>((ref) {
  final orderProcessingService = ref.watch(walletOrderProcessingServiceProvider);
  return WalletCheckoutNotifier(orderProcessingService, ref);
});

/// Provider for wallet payment validation for current cart
final walletPaymentValidationProvider = FutureProvider<PaymentOptions?>((ref) async {
  final notifier = ref.read(walletCheckoutProvider.notifier);
  return notifier.validateWalletForCurrentCart();
});

/// Provider to check if wallet checkout is available
final isWalletCheckoutAvailableProvider = Provider<bool>((ref) {
  final cartState = ref.watch(enhancedCartProvider);
  final walletState = ref.watch(customerWalletProvider);
  
  // Cart must have items
  if (cartState.items.isEmpty) {
    return false;
  }

  // Wallet must be available
  return walletState.hasWallet && (walletState.wallet?.isActive ?? false);
});

/// Provider for wallet checkout button state
final walletCheckoutButtonStateProvider = Provider<Map<String, dynamic>>((ref) {
  final checkoutState = ref.watch(walletCheckoutProvider);
  final cartState = ref.watch(enhancedCartProvider);
  final isAvailable = ref.watch(isWalletCheckoutAvailableProvider);
  
  return {
    'enabled': isAvailable && !checkoutState.isProcessing && cartState.items.isNotEmpty,
    'loading': checkoutState.isProcessing,
    'text': checkoutState.isProcessing 
        ? 'Processing...' 
        : 'Pay with Wallet',
  };
});
