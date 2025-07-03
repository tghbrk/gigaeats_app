// TODO: Remove unused imports when dependencies are restored
// import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// TODO: Remove unused import when Supabase usage is restored
// import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/order.dart';
import '../../../payments/data/services/payment_service.dart';
import '../../../data/services/customer/customer_order_service.dart';
import 'customer_cart_provider.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/utils/logger.dart';

/// Provider for PaymentService
final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService();
});

/// Provider for CustomerOrderService
final customerOrderServiceProvider = Provider<CustomerOrderService>((ref) {
  return CustomerOrderService();
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
  // TODO: Remove unused field when service methods are restored
  // ignore: unused_field
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

      // Step 2: Process payment (simplified for now)
      _logger.info('OrderCreationNotifier: Processing payment method: $paymentMethod');

      // For now, we'll consider all payments as successful
      // In a real implementation, this would integrate with Stripe
      bool paymentSuccessful = true;

      if (paymentMethod == 'credit_card') {
        _logger.info('OrderCreationNotifier: Processing credit card payment');
        // TODO: Integrate with Stripe payment processing
        paymentSuccessful = true;
      } else if (paymentMethod == 'cash') {
        _logger.info('OrderCreationNotifier: Cash on delivery selected');
        paymentSuccessful = true;
      } else {
        _logger.info('OrderCreationNotifier: Other payment method: $paymentMethod');
        paymentSuccessful = true;
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
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
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
}

/// Provider for order creation
final orderCreationProvider = StateNotifierProvider<OrderCreationNotifier, OrderCreationState>((ref) {
  final orderService = ref.watch(customerOrderServiceProvider);
  return OrderCreationNotifier(orderService, ref);
});

/// Provider for customer orders
final customerOrdersProvider = FutureProvider.family<List<Order>, String>((ref, customerId) async {
  final orderService = ref.watch(customerOrderServiceProvider);
  // TODO: Restore when getCustomerOrders method signature is fixed
  // return orderService.getCustomerOrders(customerId);
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
