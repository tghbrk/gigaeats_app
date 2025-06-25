import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../orders/data/models/order.dart';
import '../../../payments/data/services/payment_service.dart';
import '../../data/services/customer_order_service.dart';
import 'customer_cart_provider.dart';
import 'customer_profile_provider.dart';
import '../../../../core/utils/logger.dart';

/// Provider for PaymentService
final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService();
});

/// Provider for CustomerOrderService
final customerOrderServiceProvider = Provider<CustomerOrderService>((ref) {
  final paymentService = ref.watch(paymentServiceProvider);
  return CustomerOrderService(paymentService: paymentService);
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

      // Get cart state and customer profile
      final cartState = _ref.read(customerCartProvider);
      final customerProfile = _ref.read(currentCustomerProfileProvider);

      if (customerProfile == null) {
        throw Exception('Customer profile not found. Please complete your profile first.');
      }

      // Step 1: Create order
      _logger.info('OrderCreationNotifier: Creating order');
      final order = await _orderService.createOrderFromCart(
        cartState: cartState,
        customerProfile: customerProfile,
        paymentMethod: paymentMethod,
        specialInstructions: specialInstructions,
      );

      state = state.copyWith(order: order);
      _logger.info('OrderCreationNotifier: Order created with ID: ${order.id}');

      // Step 2: Process payment
      if (paymentMethod == 'credit_card') {
        _logger.info('OrderCreationNotifier: Processing credit card payment');
        
        final paymentResult = await _orderService.processPayment(
          orderId: order.id,
          amount: order.totalAmount,
          paymentMethod: paymentMethod,
        );

        if (paymentResult['success'] == true) {
          state = state.copyWith(
            isLoading: false,
            paymentClientSecret: paymentResult['client_secret'],
            paymentMetadata: paymentResult,
          );
          _logger.info('OrderCreationNotifier: Payment intent created successfully');

          // Refresh customer orders provider to refresh the list
          final ordersNotifier = _ref.read(currentCustomerOrdersProvider.notifier);
          await ordersNotifier.refresh();
          _ref.invalidate(currentCustomerRecentOrdersProvider);
          _logger.info('OrderCreationNotifier: Refreshed customer orders providers');

          return true;
        } else {
          throw Exception(paymentResult['error_message'] ?? 'Payment processing failed');
        }
      } else if (paymentMethod == 'cash') {
        // Cash on delivery - order is complete
        state = state.copyWith(isLoading: false);
        _logger.info('OrderCreationNotifier: Cash on delivery order completed');

        // Refresh customer orders provider to refresh the list
        final ordersNotifier = _ref.read(currentCustomerOrdersProvider.notifier);
        await ordersNotifier.refresh();
        _ref.invalidate(currentCustomerRecentOrdersProvider);
        _logger.info('OrderCreationNotifier: Refreshed customer orders providers');

        return true;
      } else {
        throw Exception('Unsupported payment method: $paymentMethod');
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

    final customerProfile = ref.watch(currentCustomerProfileProvider);
    debugPrint('🔍 CurrentCustomerOrdersNotifier: Customer profile: ${customerProfile?.id}');

    if (customerProfile == null) {
      debugPrint('🔍 CurrentCustomerOrdersNotifier: No customer profile, returning empty list');
      return [];
    }

    debugPrint('🔍 CurrentCustomerOrdersNotifier: Fetching orders for customer: ${customerProfile.id}');
    final orderService = ref.watch(customerOrderServiceProvider);
    final orders = await orderService.getCustomerOrders(customerProfile.id);
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
  final customerProfile = ref.watch(currentCustomerProfileProvider);
  if (customerProfile == null) {
    debugPrint('🔄 CustomerOrdersRealtime: No customer profile, returning empty stream');
    return Stream.value([]);
  }

  debugPrint('🔄 CustomerOrdersRealtime: Setting up real-time subscription for customer: ${customerProfile.id}');
  final supabase = Supabase.instance.client;

  return supabase
      .from('orders')
      .stream(primaryKey: ['id'])
      .eq('customer_id', customerProfile.id)
      .order('created_at', ascending: false)
      .asyncMap((data) async {
        debugPrint('🔄 CustomerOrdersRealtime: Received ${data.length} orders from real-time stream');

        // Fetch complete order data with order_items for each order
        final List<Order> completeOrders = [];

        for (final orderData in data) {
          try {
            final orderId = orderData['id'] as String;
            debugPrint('🔄 CustomerOrdersRealtime: Fetching complete data for order: $orderId');

            // Fetch order with order_items
            final completeOrderResponse = await supabase
                .from('orders')
                .select('''
                  *,
                  order_items(*)
                ''')
                .eq('id', orderId)
                .single();

            // Handle delivery_address field if it's a string
            if (completeOrderResponse['delivery_address'] is String) {
              try {
                completeOrderResponse['delivery_address'] = jsonDecode(completeOrderResponse['delivery_address']);
              } catch (e) {
                completeOrderResponse['delivery_address'] = {
                  'street': 'Unknown',
                  'city': 'Unknown',
                  'state': 'Unknown',
                  'postal_code': '00000',
                  'country': 'Malaysia',
                };
              }
            }

            final order = Order.fromJson(completeOrderResponse);
            debugPrint('🔄 CustomerOrdersRealtime: Parsed order ${order.orderNumber} with ${order.items.length} items');
            completeOrders.add(order);
          } catch (e) {
            debugPrint('❌ CustomerOrdersRealtime: Error fetching complete order data: $e');
            // Fallback to basic order data without items
            try {
              // Handle delivery_address field if it's a string
              if (orderData['delivery_address'] is String) {
                try {
                  orderData['delivery_address'] = jsonDecode(orderData['delivery_address']);
                } catch (e) {
                  orderData['delivery_address'] = {
                    'street': 'Unknown',
                    'city': 'Unknown',
                    'state': 'Unknown',
                    'postal_code': '00000',
                    'country': 'Malaysia',
                  };
                }
              }

              // Ensure order_items is an empty list if not present
              if (orderData['order_items'] == null) {
                orderData['order_items'] = [];
              }

              final order = Order.fromJson(orderData);
              debugPrint('🔄 CustomerOrdersRealtime: Fallback - parsed order ${order.orderNumber} with ${order.items.length} items');
              completeOrders.add(order);
            } catch (fallbackError) {
              debugPrint('❌ CustomerOrdersRealtime: Error in fallback parsing: $fallbackError');
            }
          }
        }

        debugPrint('🔄 CustomerOrdersRealtime: Returning ${completeOrders.length} complete orders');
        return completeOrders;
      });
});

/// Provider for current customer recent orders (limited to 5 most recent)
final currentCustomerRecentOrdersProvider = FutureProvider<List<Order>>((ref) async {
  final customerProfile = ref.watch(currentCustomerProfileProvider);
  if (customerProfile == null) {
    return [];
  }

  final orderService = ref.watch(customerOrderServiceProvider);
  return orderService.getCustomerOrders(customerProfile.id, limit: 5);
});
