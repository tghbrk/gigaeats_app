import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/order.dart';
import '../../data/services/order_service.dart';
import 'auth_provider.dart';
import 'cart_provider.dart';

// Order Service Provider
final orderServiceProvider = Provider<OrderService>((ref) {
  return OrderService();
});

// Orders List State
class OrdersState {
  final List<Order> orders;
  final bool isLoading;
  final String? errorMessage;

  OrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  OrdersState copyWith({
    List<Order>? orders,
    bool? isLoading,
    String? errorMessage,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// Orders Provider
class OrdersNotifier extends StateNotifier<OrdersState> {
  final OrderService _orderService;
  final Ref _ref;

  OrdersNotifier(this._orderService, this._ref) : super(OrdersState()) {
    // Generate mock data for development
    OrderService.generateMockOrders();
    loadOrders();
  }

  Future<void> loadOrders({
    OrderStatus? status,
    String? vendorId,
    String? customerId,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;

      String? salesAgentId;
      if (user?.role.name == 'salesAgent') {
        salesAgentId = user?.id;
      }

      final orders = await _orderService.getOrders(
        salesAgentId: salesAgentId,
        vendorId: vendorId,
        customerId: customerId,
        status: status,
      );

      state = state.copyWith(
        orders: orders,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error loading orders: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load orders: ${e.toString()}',
      );
    }
  }

  Future<Order?> createOrder({
    required String customerId,
    required String customerName,
    required DateTime deliveryDate,
    required Address deliveryAddress,
    String? notes,
  }) async {
    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;
      final cartState = _ref.read(cartProvider);

      if (user == null) {
        throw Exception('User not authenticated');
      }

      if (cartState.isEmpty) {
        throw Exception('Cart is empty');
      }

      // For now, we'll handle single vendor orders
      // TODO: Implement multi-vendor order splitting
      final vendorItems = cartState.itemsByVendor;
      if (vendorItems.length > 1) {
        throw Exception('Multi-vendor orders not yet supported');
      }

      final vendorId = vendorItems.keys.first;
      final items = vendorItems[vendorId]!;
      final vendorName = items.first.vendorName;

      final orderItems = items.map((cartItem) => cartItem.toOrderItem()).toList();

      final order = await _orderService.createOrder(
        items: orderItems,
        vendorId: vendorId,
        vendorName: vendorName,
        customerId: customerId,
        customerName: customerName,
        salesAgentId: user.id,
        salesAgentName: user.fullName,
        deliveryDate: deliveryDate,
        deliveryAddress: deliveryAddress,
        notes: notes,
      );

      // Clear cart after successful order creation
      _ref.read(cartProvider.notifier).clearCart();

      // Refresh orders list
      await loadOrders();

      return order;
    } catch (e) {
      debugPrint('Error creating order: $e');
      state = state.copyWith(
        errorMessage: 'Failed to create order: ${e.toString()}',
      );
      return null;
    }
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      await _orderService.updateOrderStatus(orderId, newStatus);

      // Update local state
      final updatedOrders = state.orders.map((order) {
        if (order.id == orderId) {
          return order.copyWith(
            status: newStatus,
            updatedAt: DateTime.now(),
          );
        }
        return order;
      }).toList();

      state = state.copyWith(orders: updatedOrders);
    } catch (e) {
      debugPrint('Error updating order status: $e');
      state = state.copyWith(
        errorMessage: 'Failed to update order: ${e.toString()}',
      );
    }
  }

  Future<void> cancelOrder(String orderId, String reason) async {
    try {
      await _orderService.cancelOrder(orderId, reason);

      // Update local state
      final updatedOrders = state.orders.map((order) {
        if (order.id == orderId) {
          return order.copyWith(
            status: OrderStatus.cancelled,
            updatedAt: DateTime.now(),
          );
        }
        return order;
      }).toList();

      state = state.copyWith(orders: updatedOrders);
    } catch (e) {
      debugPrint('Error cancelling order: $e');
      state = state.copyWith(
        errorMessage: 'Failed to cancel order: ${e.toString()}',
      );
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// Provider
final ordersProvider = StateNotifierProvider<OrdersNotifier, OrdersState>((ref) {
  final orderService = ref.watch(orderServiceProvider);
  return OrdersNotifier(orderService, ref);
});

// Individual Order Provider
final orderProvider = FutureProvider.family<Order?, String>((ref, orderId) async {
  final orderService = ref.watch(orderServiceProvider);
  return await orderService.getOrderById(orderId);
});

// Filtered Orders Providers
final pendingOrdersProvider = Provider<List<Order>>((ref) {
  final ordersState = ref.watch(ordersProvider);
  return ordersState.orders
      .where((order) => order.status == OrderStatus.pending)
      .toList();
});

final activeOrdersProvider = Provider<List<Order>>((ref) {
  final ordersState = ref.watch(ordersProvider);
  return ordersState.orders
      .where((order) =>
          order.status != OrderStatus.delivered &&
          order.status != OrderStatus.cancelled)
      .toList();
});

final completedOrdersProvider = Provider<List<Order>>((ref) {
  final ordersState = ref.watch(ordersProvider);
  return ordersState.orders
      .where((order) => order.status == OrderStatus.delivered)
      .toList();
});

// Statistics Providers
final totalEarningsProvider = Provider<double>((ref) {
  final ordersState = ref.watch(ordersProvider);
  return ordersState.orders
      .where((order) => order.status == OrderStatus.delivered)
      .fold(0.0, (sum, order) => sum + (order.commissionAmount ?? 0.0));
});

final monthlyEarningsProvider = Provider<double>((ref) {
  final ordersState = ref.watch(ordersProvider);
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);

  return ordersState.orders
      .where((order) =>
          order.status == OrderStatus.delivered &&
          order.createdAt.isAfter(startOfMonth))
      .fold(0.0, (sum, order) => sum + (order.commissionAmount ?? 0.0));
});
