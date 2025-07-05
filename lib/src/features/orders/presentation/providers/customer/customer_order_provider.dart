import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/order.dart';
import '../../../payments/data/services/payment_service.dart';
import '../../../data/services/customer/customer_order_service.dart';
import '../../../../marketplace_wallet/integration/wallet_checkout_integration_service.dart';
import 'customer_cart_provider.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/utils/logger.dart';

/// Provider for PaymentService
final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService();
});

/// Provider for CustomerOrderService
final customerOrderServiceProvider = Provider<CustomerOrderService>((ref) {
  final paymentService = ref.watch(paymentServiceProvider);
  final walletCheckoutService = ref.watch(walletCheckoutIntegrationServiceProvider);
  return CustomerOrderService(
    paymentService: paymentService,
    walletCheckoutService: walletCheckoutService,
  );
});

/// State for order creation process
class OrderCreationState {
  final bool isLoading;
  final Order? order;
  final String? error;
  final String? paymentClientSecret;
  final Map<String, dynamic>? paymentMetadata;

  const OrderCreationState({
    this.isLoading = false,
    this.order,
    this.error,
    this.paymentClientSecret,
    this.paymentMetadata,
  });

  OrderCreationState copyWith({
    bool? isLoading,
    Order? order,
    String? error,
    String? paymentClientSecret,
    Map<String, dynamic>? paymentMetadata,
  }) {
    return OrderCreationState(
      isLoading: isLoading ?? this.isLoading,
      order: order ?? this.order,
      error: error ?? this.error,
      paymentClientSecret: paymentClientSecret ?? this.paymentClientSecret,
      paymentMetadata: paymentMetadata ?? this.paymentMetadata,
    );
  }
}

/// Notifier for order creation
class OrderCreationNotifier extends StateNotifier<OrderCreationState> {
  final CustomerOrderService _orderService;
  final Ref _ref;
  final AppLogger _logger = AppLogger();

  OrderCreationNotifier(this._orderService, this._ref) : super(const OrderCreationState());

  /// Create order and process payment
  Future<bool> createOrderAndProcessPayment({
    required String paymentMethod,
    String? specialInstructions,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      _logger.info('OrderCreationNotifier: Starting order creation process');

      // Get cart state
      final cartState = _ref.read(customerCartProvider);

      // Validate cart before proceeding
      final cartNotifier = _ref.read(customerCartProvider.notifier);
      final validationErrors = cartNotifier.validateCart();

      if (validationErrors.isNotEmpty) {
        throw Exception('Cart validation failed: ${validationErrors.join(', ')}');
      }

      // TODO: Remove unnecessary null check when currentCustomerProfileProvider is properly typed
      // if (customerProfile == null) {
      //   throw Exception('Customer profile not found. Please complete your profile first.');
      // }

      // Step 1: Create order
      _logger.info('OrderCreationNotifier: Creating order');
      final order = await _orderService.createOrderFromCart(
        cartState: cartState,
        paymentMethod: paymentMethod,
        specialInstructions: specialInstructions,
      );

      state = state.copyWith(order: order);
      _logger.info('OrderCreationNotifier: Order created with ID: ${order.id}');

      // Step 2: Process payment via CustomerOrderService
      _logger.info('OrderCreationNotifier: Processing payment method: $paymentMethod');

      // SECURITY FIX: Actually call the payment processing logic
      final paymentResult = await _orderService.processPayment(
        orderId: order.id,
        amount: order.totalAmount,
        paymentMethod: paymentMethod,
        currency: 'myr',
      );

      // Check payment result
      bool paymentSuccessful = paymentResult['success'] == true;

      if (!paymentSuccessful) {
        final errorMessage = paymentResult['error'] ?? 'Payment processing failed';
        final errorCode = paymentResult['error_code'] ?? 'UNKNOWN_ERROR';
        final retryAllowed = paymentResult['retry_allowed'] ?? false;

        _logger.error('OrderCreationNotifier: Payment failed: $errorMessage');
        _logger.error('OrderCreationNotifier: Error code: $errorCode');
        _logger.error('OrderCreationNotifier: Retry allowed: $retryAllowed');

        // Create enhanced error with retry information
        final enhancedError = _createEnhancedPaymentError(
          errorMessage,
          errorCode,
          retryAllowed,
          paymentMethod,
        );

        throw Exception(enhancedError);
      }

      _logger.info('OrderCreationNotifier: Payment processed successfully');
      _logger.info('OrderCreationNotifier: Payment method: ${paymentResult['payment_method']}');
      _logger.info('OrderCreationNotifier: Payment status: ${paymentResult['status']}');

      // Log additional details for wallet payments
      if (paymentMethod == 'wallet' && paymentResult['transaction_id'] != null) {
        _logger.info('OrderCreationNotifier: Wallet transaction ID: ${paymentResult['transaction_id']}');
        _logger.info('OrderCreationNotifier: Amount paid: RM ${paymentResult['amount_paid']?.toStringAsFixed(2)}');
        if (paymentResult['new_wallet_balance'] != null) {
          _logger.info('OrderCreationNotifier: New wallet balance: RM ${paymentResult['new_wallet_balance']?.toStringAsFixed(2)}');
        }
      }

      if (paymentSuccessful) {
        // Clear cart after successful order creation
        _ref.read(customerCartProvider.notifier).clearCart();
        _logger.info('OrderCreationNotifier: Cart cleared after successful order');

        // Update state
        state = state.copyWith(
          isLoading: false,
          order: order,
        );

        // Refresh customer orders
        _ref.invalidate(currentCustomerOrdersProvider);
        _logger.info('OrderCreationNotifier: Order creation completed successfully');

        return true;
      } else {
        throw Exception('Payment processing failed');
      }
    } catch (e) {
      _logger.error('OrderCreationNotifier: Error in order creation process', e);

      // If we have an order but payment failed, we should consider canceling the order
      // The order creation and payment should be atomic, but since they're separate steps,
      // we need to handle cleanup if payment fails
      final currentOrder = state.order;
      if (currentOrder != null && e.toString().contains('Payment failed')) {
        _logger.warning('OrderCreationNotifier: Payment failed for order ${currentOrder.id}, order may need manual review');
        // Note: The secure wallet operations Edge Function handles rollback automatically
        // For other payment methods, the order remains in pending state for manual review
      }

      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Create enhanced payment error message with user guidance
  String _createEnhancedPaymentError(
    String errorMessage,
    String errorCode,
    bool retryAllowed,
    String paymentMethod,
  ) {
    final baseMessage = errorMessage;

    // Add specific guidance based on error type
    switch (errorCode) {
      case 'INSUFFICIENT_BALANCE':
        return '$baseMessage\n\nTo resolve this:\n• Top up your wallet from the Wallet section\n• Or select a different payment method';

      case 'NETWORK_ERROR':
        return '$baseMessage\n\nTo resolve this:\n• Check your internet connection\n• Try again in a moment\n• Switch to mobile data if using WiFi';

      case 'UNAUTHORIZED_ACCESS':
        return '$baseMessage\n\nTo resolve this:\n• Log out and log back in\n• Contact support if the issue persists';

      case 'WALLET_NOT_FOUND':
        return '$baseMessage\n\nTo resolve this:\n• Set up your wallet in the Wallet section\n• Or use a different payment method';

      case 'SERVER_ERROR':
        return '$baseMessage\n\nOur servers are temporarily busy. Please try again in a few moments.';

      case 'RATE_LIMITED':
        return '$baseMessage\n\nPlease wait a moment before trying again.';

      case 'VALIDATION_ERROR':
        return '$baseMessage\n\nPlease refresh the page and try again.';

      default:
        if (retryAllowed) {
          return '$baseMessage\n\nYou can try again or contact support if the issue persists.';
        } else {
          return '$baseMessage\n\nPlease try a different payment method or contact support.';
        }
    }
  }

  /// Clear order state
  void clearOrder() {
    state = const OrderCreationState();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Retry order creation and payment processing
  Future<bool> retryOrderCreation({
    required String paymentMethod,
    String? specialInstructions,
  }) async {
    _logger.info('OrderCreationNotifier: Retrying order creation');

    // Clear previous error state
    clearError();

    // Retry the order creation process
    return await createOrderAndProcessPayment(
      paymentMethod: paymentMethod,
      specialInstructions: specialInstructions,
    );
  }
}

/// Provider for order creation
final orderCreationProvider = StateNotifierProvider<OrderCreationNotifier, OrderCreationState>((ref) {
  final orderService = ref.watch(customerOrderServiceProvider);
  return OrderCreationNotifier(orderService, ref);
});

/// Provider for customer orders
final customerOrdersProvider = FutureProvider.family<List<Order>, String>((ref, customerId) async {
  final orderService = ref.watch(customerOrderServiceProvider);
  return orderService.getCustomerOrders(customerId);
});

/// Provider for a specific order
final orderByIdProvider = FutureProvider.family<Order?, String>((ref, orderId) async {
  final orderService = ref.watch(customerOrderServiceProvider);
  return orderService.getOrderById(orderId);
});

/// AsyncNotifier for current customer orders with better state management
class CurrentCustomerOrdersNotifier extends AsyncNotifier<List<Order>> {
  @override
  Future<List<Order>> build() async {
    debugPrint('🔍 CurrentCustomerOrdersNotifier: ===== BUILD CALLED =====');

    // Get current authenticated user ID directly
    final authState = ref.watch(authStateProvider);
    final userId = authState.user?.id;

    debugPrint('🔍 CurrentCustomerOrdersNotifier: Current user ID: $userId');

    if (userId == null) {
      debugPrint('🔍 CurrentCustomerOrdersNotifier: No authenticated user, returning empty list');
      return [];
    }

    debugPrint('🔍 CurrentCustomerOrdersNotifier: Fetching orders for user: $userId');
    final orderService = ref.watch(customerOrderServiceProvider);
    final orders = await orderService.getCustomerOrders(userId);
    debugPrint('🔍 CurrentCustomerOrdersNotifier: Retrieved ${orders.length} orders');

    for (final order in orders) {
      debugPrint('🔍 CurrentCustomerOrdersNotifier: Order ${order.orderNumber} - ${order.items.length} items');
    }

    debugPrint('🔍 CurrentCustomerOrdersNotifier: ===== RETURNING ${orders.length} ORDERS =====');
    return orders;
  }

  /// Force refresh orders
  Future<void> refresh() async {
    debugPrint('🔍 CurrentCustomerOrdersNotifier: ===== REFRESH CALLED =====');
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}

/// Provider for current customer orders (using AsyncNotifierProvider for better control)
final currentCustomerOrdersProvider = AsyncNotifierProvider<CurrentCustomerOrdersNotifier, List<Order>>(() {
  return CurrentCustomerOrdersNotifier();
});

/// Real-time provider for current customer orders with live updates
final currentCustomerOrdersRealtimeProvider = StreamProvider<List<Order>>((ref) {
  // TODO: Fix AsyncValue access - temporarily return empty stream
  debugPrint('🔄 CustomerOrdersRealtime: Temporarily disabled due to AsyncValue access issues');
  return Stream.value(<Order>[]);

});

/// Provider for current customer recent orders (limited to 5 most recent)
final currentCustomerRecentOrdersProvider = FutureProvider<List<Order>>((ref) async {
  // Get current authenticated user ID directly
  final authState = ref.watch(authStateProvider);
  final userId = authState.user?.id;

  if (userId == null) {
    return [];
  }

  final orderService = ref.watch(customerOrderServiceProvider);
  return orderService.getCustomerOrders(userId);
});
