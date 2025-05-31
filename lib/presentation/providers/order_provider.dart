import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/order.dart';
import '../../data/models/order_status_history.dart';
import '../../data/models/order_notification.dart';
import '../../data/models/customer.dart';
import '../../data/services/order_service.dart';
import '../../data/repositories/order_repository.dart';
import '../../core/utils/debug_logger.dart';

import 'cart_provider.dart';
import 'repository_providers.dart';
import 'auth_provider.dart';

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

      final testUserId = currentUser.id;
      final testUserName = currentUser.fullName;

      if (cartState.isEmpty) {
        DebugLogger.error('Cart is empty', tag: 'OrderProvider');
        throw Exception('Cart is empty. Please add items to your cart first.');
      }

      DebugLogger.auth('Using authenticated user for order creation', userId: testUserId, email: currentUser.email);
      DebugLogger.info('Cart has ${cartState.totalItems} items', tag: 'OrderProvider');

      // For now, we'll handle single vendor orders
      // TODO: Implement multi-vendor order splitting
      final vendorItems = cartState.itemsByVendor;
      if (vendorItems.length > 1) {
        DebugLogger.error('Multi-vendor orders not supported', tag: 'OrderProvider');
        throw Exception('Multi-vendor orders not yet supported. Please order from one vendor at a time.');
      }

      final vendorId = vendorItems.keys.first;
      final items = vendorItems[vendorId]!;
      final vendorName = items.first.vendorName;

      DebugLogger.info('Creating order for vendor: $vendorName (ID: $vendorId)', tag: 'OrderProvider');

      final orderItems = items.map((cartItem) {
        DebugLogger.info('Converting cart item: ${cartItem.name} (${cartItem.runtimeType})', tag: 'OrderProvider');
        final orderItem = cartItem.toOrderItem();
        DebugLogger.info('Created order item: ${orderItem.name} (${orderItem.runtimeType})', tag: 'OrderProvider');
        return orderItem;
      }).toList();

      DebugLogger.info('Total order items created: ${orderItems.length}', tag: 'OrderProvider');

      // Use existing customer ID or create a new customer
      String finalCustomerId;
      if (customerId != null) {
        finalCustomerId = customerId;
        DebugLogger.info('Using provided customer ID: $finalCustomerId', tag: 'OrderProvider');
      } else {
        // Use test customer assigned to our test user
        finalCustomerId = '11111111-2222-3333-4444-555555555555'; // Test Customer Corp
        DebugLogger.info('Using test customer ID: $finalCustomerId', tag: 'OrderProvider');

        // Verify customer exists, create if not
        try {
          final customerRepo = _ref.read(customerRepositoryProvider);
          final existingCustomer = await customerRepo.getCustomerById(finalCustomerId);
          if (existingCustomer == null) {
            DebugLogger.warning('Test customer not found, creating new customer', tag: 'OrderProvider');
            // Create a new customer with the provided information
            final newCustomer = Customer(
              id: '',
              salesAgentId: '',
              type: CustomerType.corporate,
              organizationName: customerName,
              contactPersonName: customerName,
              email: 'customer@example.com',
              phoneNumber: contactPhone ?? '+60123456789',
              address: CustomerAddress(
                street: deliveryAddress.street,
                city: deliveryAddress.city,
                state: deliveryAddress.state,
                postcode: deliveryAddress.postalCode,
              ),
              preferences: const CustomerPreferences(),
              lastOrderDate: DateTime.now(),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            final createdCustomer = await customerRepo.createCustomer(newCustomer);
            finalCustomerId = createdCustomer.id;
            DebugLogger.success('Created new customer with ID: $finalCustomerId', tag: 'OrderProvider');
          }
        } catch (e) {
          DebugLogger.error('Error checking/creating customer: $e', tag: 'OrderProvider');
          // Continue with the fallback ID - the database will handle the error
        }
      }

      // Validate that we have a valid vendor ID from the cart items
      if (vendorId.isEmpty) {
        DebugLogger.error('No vendor ID found in cart items', tag: 'OrderProvider');
        throw Exception('Invalid vendor information. Please refresh the menu and try again.');
      }

      // Validate UUIDs before creating order
      DebugLogger.info('🔍 Validating UUIDs before order creation:', tag: 'OrderProvider');
      DebugLogger.info('  - Vendor ID: $vendorId (length: ${vendorId.length})', tag: 'OrderProvider');
      DebugLogger.info('  - Customer ID: $finalCustomerId (length: ${finalCustomerId.length})', tag: 'OrderProvider');
      DebugLogger.info('  - Sales Agent ID: $testUserId (length: ${testUserId.length})', tag: 'OrderProvider');

      // Validate UUID format using regex
      final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);

      if (!uuidRegex.hasMatch(vendorId)) {
        DebugLogger.error('Invalid vendor ID format: $vendorId', tag: 'OrderProvider');
        throw Exception('Invalid vendor ID format. Please refresh the menu and try again.');
      }

      if (!uuidRegex.hasMatch(finalCustomerId)) {
        DebugLogger.error('Invalid customer ID format: $finalCustomerId', tag: 'OrderProvider');
        throw Exception('Invalid customer ID format. Please contact support.');
      }

      if (!uuidRegex.hasMatch(testUserId)) {
        DebugLogger.error('Invalid sales agent ID format: $testUserId', tag: 'OrderProvider');
        throw Exception('Invalid sales agent ID format. Please contact support.');
      }

      DebugLogger.success('✅ All UUIDs validated successfully', tag: 'OrderProvider');

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
        salesAgentId: testUserId, // This is a valid hardcoded UUID
        salesAgentName: testUserName,
        deliveryDate: deliveryDate,
        deliveryAddress: deliveryAddress,
        subtotal: orderItems.fold(0.0, (sum, item) => sum + item.totalPrice),
        deliveryFee: 0.0, // Will be calculated by repository
        sstAmount: 0.0, // Will be calculated by repository
        totalAmount: 0.0, // Will be calculated by repository
        commissionAmount: 0.0, // Will be calculated by repository
        notes: notes,
        contactPhone: contactPhone, // Add contact phone to order
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      DebugLogger.info('📤 Calling repository to create order', tag: 'OrderProvider');

      // Log the complete order object being sent
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
      DebugLogger.error('Error creating order', tag: 'OrderProvider', error: e, stackTrace: stackTrace);

      // Log additional error details for debugging
      if (e is Exception) {
        DebugLogger.error('Exception details: ${e.toString()}', tag: 'OrderProvider-Exception');
      }

      // Provide detailed error handling with specific messages
      String errorMessage = 'Failed to create order';

      final errorString = e.toString().toLowerCase();

      if (errorString.contains('user not authenticated') || errorString.contains('jwt')) {
        errorMessage = 'Authentication error. Please log in again and try again.';
      } else if (errorString.contains('permission') || errorString.contains('42501') || errorString.contains('rls')) {
        errorMessage = 'Permission denied. Please check your account permissions.';
      } else if (errorString.contains('foreign key') || errorString.contains('violates')) {
        errorMessage = 'Invalid data reference. Please check vendor and customer information.';
      } else if (errorString.contains('not null') || errorString.contains('required')) {
        errorMessage = 'Missing required information. Please fill in all required fields.';
      } else if (errorString.contains('network') || errorString.contains('connection')) {
        errorMessage = 'Network error. Please check your internet connection and try again.';
      } else if (errorString.contains('cors') || errorString.contains('access-control')) {
        errorMessage = 'Connection error. Please refresh the page and try again.';
      } else if (errorString.contains('timeout')) {
        errorMessage = 'Request timeout. Please try again.';
      } else if (errorString.contains('duplicate') || errorString.contains('unique')) {
        errorMessage = 'Duplicate order detected. Please check if the order was already created.';
      } else if (errorString.contains('400') || errorString.contains('bad request')) {
        errorMessage = 'Invalid order data. Please check all fields and try again.';
      } else {
        // Include the actual error for debugging
        errorMessage = 'Failed to create order: ${e.toString()}';
      }

      DebugLogger.error('Final error message: $errorMessage', tag: 'OrderProvider-Final');

      state = state.copyWith(
        errorMessage: errorMessage,
      );

      // Throw the exception so the UI can handle it properly
      throw Exception(errorMessage);
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
    } catch (e) {
      debugPrint('Error updating order status: $e');
      state = state.copyWith(
        errorMessage: 'Failed to update order: ${e.toString()}',
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
    } catch (e) {
      debugPrint('Error cancelling order: $e');
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
        final updatedOrders = state.orders.map((o) {
          return o.id == orderId ? order : o;
        }).toList();

        // If order doesn't exist in local state, add it
        if (!state.orders.any((o) => o.id == orderId)) {
          updatedOrders.add(order);
        }

        state = state.copyWith(orders: updatedOrders);
      }

      return order;
    } catch (e) {
      debugPrint('Error loading order by ID: $e');
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
    String? deliveryZone,
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
        deliveryZone: deliveryZone,
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
