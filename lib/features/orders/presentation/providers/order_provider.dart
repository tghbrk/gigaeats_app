import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/order.dart';
import '../../data/models/order_status_history.dart';
import '../../data/models/order_notification.dart';
import '../../../customers/data/models/customer.dart';
// Address is defined in order.dart, no separate import needed
import '../../data/services/order_service.dart';
import '../../data/repositories/order_repository.dart';
import '../../../../core/utils/debug_logger.dart';

import '../../../sales_agent/presentation/providers/cart_provider.dart';
import '../../../../presentation/providers/repository_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// Order Service Provider (Mock for development)
final orderServiceProvider = Provider<OrderService>((ref) {
  return OrderService();
});

// Order Repository Provider (Real implementation)
final orderRepositoryServiceProvider = Provider<OrderRepository>((ref) {
  return ref.watch(orderRepositoryProvider);
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
  final OrderRepository _orderRepository;
  final Ref _ref;

  OrdersNotifier(this._orderRepository, this._ref) : super(OrdersState()) {
    // Load real orders from repository
    loadOrders();
  }

  Future<void> loadOrders({
    OrderStatus? status,
    String? vendorId,
    String? customerId,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      debugPrint('OrderProvider: Loading orders from repository');

      final orders = await _orderRepository.getOrders(
        status: status,
      );

      debugPrint('OrderProvider: Loaded ${orders.length} orders');

      state = state.copyWith(
        orders: orders,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('OrderProvider: Error loading orders: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load orders: ${e.toString()}',
      );
    }
  }

  Future<Order?> createOrder({
    String? customerId, // Made optional - will be generated if null
    required String customerName,
    required DateTime deliveryDate,
    required Address deliveryAddress,
    String? notes,
    String? contactPhone, // Added contact phone parameter
  }) async {
    try {
      DebugLogger.info('🚀 Starting order creation process', tag: 'OrderProvider');

      final cartState = _ref.read(cartProvider);

      // Get current authenticated user
      final authState = _ref.read(authStateProvider);
      final currentUser = authState.user;
      if (currentUser == null) {
        throw Exception('User not authenticated. Please log in and try again.');
      }

      DebugLogger.info('Cart has ${cartState.totalItems} items', tag: 'OrderProvider');

      // For now, we'll handle single vendor orders
      // TODO: Implement multi-vendor order splitting
      final vendorItems = cartState.itemsByVendor;
      if (vendorItems.length > 1) {
        DebugLogger.error('Multi-vendor orders not supported', tag: 'OrderProvider');
        throw Exception('Multi-vendor orders are not currently supported. Please order from one vendor at a time.');
      }

      if (vendorItems.isEmpty) {
        DebugLogger.error('No items in cart', tag: 'OrderProvider');
        throw Exception('Cart is empty. Please add items before creating an order.');
      }

      // Get the single vendor's items
      final vendorEntry = vendorItems.entries.first;
      final vendorId = vendorEntry.key;
      final cartItems = vendorEntry.value;

      DebugLogger.info('Creating order for vendor: $vendorId with ${cartItems.length} items', tag: 'OrderProvider');

      // Get vendor name from the first cart item
      final vendorName = cartItems.first.vendorName;

      // Generate customer ID if not provided
      String finalCustomerId;
      if (customerId == null) {
        // Generate a test customer ID for development
        finalCustomerId = 'cust_${DateTime.now().millisecondsSinceEpoch}';
        DebugLogger.info('Generated customer ID: $finalCustomerId', tag: 'OrderProvider');

        // Verify customer exists, create if not
        try {
          final customerRepo = _ref.read(customerRepositoryProvider);
          final existingCustomer = await customerRepo.getCustomerById(finalCustomerId);
          if (existingCustomer == null) {
            DebugLogger.warning('Test customer not found, creating new customer', tag: 'OrderProvider');
            
            // Create a new customer using correct constructor parameters
            final newCustomer = Customer(
              id: finalCustomerId,
              salesAgentId: currentUser.id,
              type: CustomerType.corporate, // Use corporate instead of business
              organizationName: customerName, // Use organizationName instead of businessName
              contactPersonName: customerName,
              email: 'test@example.com',
              phoneNumber: contactPhone ?? '+60123456789',
              address: CustomerAddress(
                street: deliveryAddress.street,
                city: deliveryAddress.city,
                state: deliveryAddress.state,
                postcode: deliveryAddress.postalCode,
                country: deliveryAddress.country,
                deliveryInstructions: deliveryAddress.notes,
              ),
              preferences: const CustomerPreferences(), // Use default preferences
              isActive: true,
              totalSpent: 0.0,
              totalOrders: 0,
              averageOrderValue: 0.0,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            
            await customerRepo.createCustomer(newCustomer);
            DebugLogger.success('Created new test customer: $finalCustomerId', tag: 'OrderProvider');
          }
        } catch (e) {
          DebugLogger.warning('Could not verify/create customer: $e', tag: 'OrderProvider');
          // Continue with order creation anyway for testing
        }
      } else {
        finalCustomerId = customerId;
      }

      // Convert cart items to order items using correct field names
      final orderItems = cartItems.map((cartItem) {
        return OrderItem(
          id: '', // Will be generated by database
          menuItemId: cartItem.productId, // Use productId instead of menuItemId
          name: cartItem.name,
          description: cartItem.description,
          unitPrice: cartItem.unitPrice, // Use unitPrice instead of price
          quantity: cartItem.quantity,
          totalPrice: cartItem.totalPrice,
          imageUrl: cartItem.imageUrl,
          customizations: cartItem.customizations,
          notes: cartItem.notes,
        );
      }).toList();

      DebugLogger.info('Converted ${orderItems.length} cart items to order items', tag: 'OrderProvider');

      // Use current authenticated user as sales agent
      final salesAgentId = currentUser.id;
      final salesAgentName = currentUser.fullName;

      // Create order object for repository
      final newOrder = Order(
        id: '', // Will be generated by database - this will be removed in toJson()
        orderNumber: '', // Will be generated by database - this will be removed in toJson()
        status: OrderStatus.pending,
        items: orderItems,
        vendorId: vendorId, // This should be a valid UUID from cart items
        vendorName: vendorName,
        customerId: finalCustomerId, // This is a valid hardcoded UUID
        customerName: customerName,
        salesAgentId: salesAgentId, // Use current authenticated user's ID
        salesAgentName: salesAgentName,
        deliveryDate: deliveryDate,
        deliveryAddress: deliveryAddress,
        subtotal: orderItems.fold(0.0, (sum, item) => sum + item.totalPrice),
        deliveryFee: 0.0, // Will be calculated by repository
        sstAmount: 0.0, // Will be calculated by repository
        totalAmount: 0.0, // Will be calculated by repository
        commissionAmount: 0.0, // Will be calculated by repository
        // Individual payment fields (replaces PaymentInfo object)
        paymentMethod: PaymentMethod.fpx.value, // Use fpx as default
        paymentStatus: PaymentStatus.pending.value,
        paymentReference: null, // Will be set when payment is processed
        notes: notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      DebugLogger.info('Created order object with vendor: $vendorId, customer: $finalCustomerId', tag: 'OrderProvider');

      // Log the order object being sent to repository
      final orderJson = newOrder.toJson();
      DebugLogger.logObject('Order object being sent to repository', orderJson, tag: 'OrderProvider');

      final order = await _orderRepository.createOrder(newOrder);

      DebugLogger.success('Order created successfully - ID: ${order.id}', tag: 'OrderProvider');

      // Clear cart after successful order creation
      _ref.read(cartProvider.notifier).clearCart();
      DebugLogger.info('Cart cleared after successful order creation', tag: 'OrderProvider');

      // Refresh orders list
      await loadOrders();

      return order;
    } catch (e, stackTrace) {
      DebugLogger.error('Failed to create order: $e', tag: 'OrderProvider');
      DebugLogger.error('Stack trace: $stackTrace', tag: 'OrderProvider');
      
      state = state.copyWith(
        errorMessage: 'Failed to create order: ${e.toString()}',
      );
      
      rethrow;
    }
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      debugPrint('OrderProvider: Updating order status - ID: $orderId, Status: ${newStatus.value}');
      await _orderRepository.updateOrderStatus(orderId, newStatus);

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
      debugPrint('OrderProvider: Order status updated successfully');
    } catch (e) {
      debugPrint('OrderProvider: Error updating order status: $e');
      state = state.copyWith(
        errorMessage: 'Failed to update order status: ${e.toString()}',
      );
    }
  }

  Future<void> cancelOrder(String orderId, String reason) async {
    try {
      debugPrint('OrderProvider: Cancelling order - ID: $orderId, Reason: $reason');
      await _orderRepository.cancelOrder(orderId, reason);

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
      debugPrint('OrderProvider: Order cancelled successfully');
    } catch (e) {
      debugPrint('OrderProvider: Error cancelling order: $e');
      state = state.copyWith(
        errorMessage: 'Failed to cancel order: ${e.toString()}',
      );
    }
  }

  Future<Order?> loadOrderById(String orderId) async {
    try {
      final order = await _orderRepository.getOrderById(orderId);

      if (order != null) {
        // Update the order in the local state if it exists
        final updatedOrders = state.orders.map((existingOrder) {
          return existingOrder.id == orderId ? order : existingOrder;
        }).toList();

        // If order doesn't exist in local state, add it
        if (!state.orders.any((existingOrder) => existingOrder.id == orderId)) {
          updatedOrders.add(order);
        }

        state = state.copyWith(orders: updatedOrders);
      }

      return order;
    } catch (e) {
      debugPrint('OrderProvider: Error loading order by ID: $e');
      state = state.copyWith(
        errorMessage: 'Failed to load order: ${e.toString()}',
      );
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// Provider
final ordersProvider = StateNotifierProvider<OrdersNotifier, OrdersState>((ref) {
  final orderRepository = ref.watch(orderRepositoryServiceProvider);
  return OrdersNotifier(orderRepository, ref);
});

// Individual Order Provider
final orderProvider = FutureProvider.family<Order?, String>((ref, orderId) async {
  final orderRepository = ref.watch(orderRepositoryServiceProvider);
  return await orderRepository.getOrderById(orderId);
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
  final activeOrders = ordersState.orders
      .where((order) =>
          order.status != OrderStatus.delivered &&
          order.status != OrderStatus.cancelled &&
          order.status != OrderStatus.ready)
      .toList();

  // Sort by creation date in descending order (newest first)
  activeOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return activeOrders;
});

final readyOrdersProvider = Provider<List<Order>>((ref) {
  final ordersState = ref.watch(ordersProvider);
  final readyOrders = ordersState.orders
      .where((order) => order.status == OrderStatus.ready)
      .toList();

  // Sort by creation date in descending order (newest first)
  readyOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return readyOrders;
});

final historyOrdersProvider = Provider<List<Order>>((ref) {
  final ordersState = ref.watch(ordersProvider);
  final historyOrders = ordersState.orders
      .where((order) =>
          order.status == OrderStatus.delivered ||
          order.status == OrderStatus.cancelled)
      .toList();

  // Sort by creation date in descending order (newest first)
  historyOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return historyOrders;
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

// Order Status History Provider
final orderStatusHistoryProvider = FutureProvider.family<List<OrderStatusHistory>, String>((ref, orderId) async {
  final orderRepository = ref.watch(orderRepositoryServiceProvider);
  return await orderRepository.getOrderStatusHistory(orderId);
});

// Order Notifications Providers
final orderNotificationsProvider = FutureProvider<List<OrderNotification>>((ref) async {
  final orderRepository = ref.watch(orderRepositoryServiceProvider);
  return await orderRepository.getOrderNotifications();
});

final unreadNotificationsProvider = FutureProvider<List<OrderNotification>>((ref) async {
  final orderRepository = ref.watch(orderRepositoryServiceProvider);
  return await orderRepository.getOrderNotifications(isRead: false);
});

final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  final orderRepository = ref.watch(orderRepositoryServiceProvider);
  return await orderRepository.getUnreadNotificationCount();
});

// Real-time Order Notifications Stream
final orderNotificationsStreamProvider = StreamProvider<List<OrderNotification>>((ref) {
  final orderRepository = ref.watch(orderRepositoryServiceProvider);
  return orderRepository.getOrderNotificationsStream();
});

// Enhanced Order Tracking Provider
class OrderTrackingNotifier extends StateNotifier<AsyncValue<Order?>> {
  final OrderRepository _orderRepository;
  final String orderId;

  OrderTrackingNotifier(this._orderRepository, this.orderId) : super(const AsyncValue.loading()) {
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      final order = await _orderRepository.getOrderById(orderId);
      state = AsyncValue.data(order);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateOrderStatus(OrderStatus newStatus) async {
    try {
      state = const AsyncValue.loading();
      final updatedOrder = await _orderRepository.updateOrderStatus(orderId, newStatus);
      state = AsyncValue.data(updatedOrder);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateOrderTracking({
    DateTime? estimatedDeliveryTime,
    DateTime? actualDeliveryTime,
    DateTime? preparationStartedAt,
    DateTime? readyAt,
    DateTime? outForDeliveryAt,
    String? specialInstructions,
    String? contactPhone,
  }) async {
    try {
      state = const AsyncValue.loading();
      final updatedOrder = await _orderRepository.updateOrderTracking(
        orderId,
        estimatedDeliveryTime: estimatedDeliveryTime,
        actualDeliveryTime: actualDeliveryTime,
        preparationStartedAt: preparationStartedAt,
        readyAt: readyAt,
        outForDeliveryAt: outForDeliveryAt,
        specialInstructions: specialInstructions,
        contactPhone: contactPhone,
      );
      state = AsyncValue.data(updatedOrder);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> cancelOrder(String reason) async {
    try {
      state = const AsyncValue.loading();
      final cancelledOrder = await _orderRepository.cancelOrder(orderId, reason);
      state = AsyncValue.data(cancelledOrder);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void refresh() {
    _loadOrder();
  }
}

final orderTrackingProvider = StateNotifierProvider.family<OrderTrackingNotifier, AsyncValue<Order?>, String>((ref, orderId) {
  final orderRepository = ref.watch(orderRepositoryServiceProvider);
  return OrderTrackingNotifier(orderRepository, orderId);
});

// Notification Management Provider
class NotificationNotifier extends StateNotifier<AsyncValue<List<OrderNotification>>> {
  final OrderRepository _orderRepository;

  NotificationNotifier(this._orderRepository) : super(const AsyncValue.loading()) {
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final notifications = await _orderRepository.getOrderNotifications();
      state = AsyncValue.data(notifications);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    await _orderRepository.markNotificationAsRead(notificationId);
    _loadNotifications(); // Refresh the list
  }

  Future<void> markAllAsRead() async {
    await _orderRepository.markAllNotificationsAsRead();
    _loadNotifications(); // Refresh the list
  }

  void refresh() {
    _loadNotifications();
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, AsyncValue<List<OrderNotification>>>((ref) {
  final orderRepository = ref.watch(orderRepositoryServiceProvider);
  return NotificationNotifier(orderRepository);
});
