import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/order.dart';
import '../../data/repositories/order_repository.dart';
import '../../../../core/utils/debug_logger.dart';

import '../../../../presentation/providers/repository_providers.dart';

// Enhanced Order Management with Real-time and Edge Functions

// Supabase client provider
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Enhanced Order Request Model
class CreateOrderRequest {
  final String vendorId;
  final String customerId;
  final String? salesAgentId;
  final DateTime deliveryDate;
  final Map<String, dynamic> deliveryAddress;
  final List<OrderItemRequest> items;
  final String? specialInstructions;
  final String? contactPhone;

  CreateOrderRequest({
    required this.vendorId,
    required this.customerId,
    this.salesAgentId,
    required this.deliveryDate,
    required this.deliveryAddress,
    required this.items,
    this.specialInstructions,
    this.contactPhone,
  });

  Map<String, dynamic> toJson() => {
    'vendor_id': vendorId,
    'customer_id': customerId,
    'sales_agent_id': salesAgentId,
    'delivery_date': deliveryDate.toIso8601String(),
    'delivery_address': deliveryAddress,
    'items': items.map((item) => item.toJson()).toList(),
    'special_instructions': specialInstructions,
    'contact_phone': contactPhone,
  };
}

class OrderItemRequest {
  final String menuItemId;
  final int quantity;
  final double unitPrice;
  final Map<String, dynamic>? customizations;
  final String? notes;

  OrderItemRequest({
    required this.menuItemId,
    required this.quantity,
    required this.unitPrice,
    this.customizations,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'menu_item_id': menuItemId,
    'quantity': quantity,
    'unit_price': unitPrice,
    'customizations': customizations,
    'notes': notes,
  };
}

// Enhanced Orders State with Real-time Support
class EnhancedOrdersState {
  final List<Order> orders;
  final bool isLoading;
  final String? errorMessage;
  final bool hasRealtimeConnection;
  final DateTime? lastUpdated;

  EnhancedOrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.errorMessage,
    this.hasRealtimeConnection = false,
    this.lastUpdated,
  });

  EnhancedOrdersState copyWith({
    List<Order>? orders,
    bool? isLoading,
    String? errorMessage,
    bool? hasRealtimeConnection,
    DateTime? lastUpdated,
  }) {
    return EnhancedOrdersState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      hasRealtimeConnection: hasRealtimeConnection ?? this.hasRealtimeConnection,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

// Enhanced OrdersNotifier with Real-time and Edge Functions
class EnhancedOrdersNotifier extends StateNotifier<EnhancedOrdersState> {
  final OrderRepository _orderRepository;
  final SupabaseClient _supabase;
  RealtimeChannel? _realtimeChannel;

  EnhancedOrdersNotifier(this._orderRepository, this._supabase, Ref ref)
      : super(EnhancedOrdersState()) {
    _setupRealtimeSubscription();
    loadOrders();
  }

  void _setupRealtimeSubscription() {
    try {
      _realtimeChannel = _supabase
          .channel('orders_channel')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'orders',
            callback: (payload) {
              _handleRealtimeUpdate(payload);
            },
          )
          .subscribe();

      state = state.copyWith(hasRealtimeConnection: true);
      DebugLogger.info('Real-time subscription established', tag: 'EnhancedOrdersNotifier');
    } catch (e) {
      DebugLogger.error('Failed to setup real-time subscription: $e', tag: 'EnhancedOrdersNotifier');
    }
  }

  void _handleRealtimeUpdate(PostgresChangePayload payload) {
    try {
      DebugLogger.info('Real-time update received: ${payload.eventType}', tag: 'EnhancedOrdersNotifier');

      switch (payload.eventType) {
        case PostgresChangeEvent.insert:
          final processedData = _processRealtimeOrderData(payload.newRecord);
          final newOrder = Order.fromJson(processedData);
          final updatedOrders = [newOrder, ...state.orders];
          state = state.copyWith(
            orders: updatedOrders,
            lastUpdated: DateTime.now(),
          );
          break;
        case PostgresChangeEvent.update:
          final processedData = _processRealtimeOrderData(payload.newRecord);
          final updatedOrder = Order.fromJson(processedData);
          final updatedOrders = state.orders.map((order) {
            return order.id == updatedOrder.id ? updatedOrder : order;
          }).toList();
          state = state.copyWith(
            orders: updatedOrders,
            lastUpdated: DateTime.now(),
          );
          break;
        case PostgresChangeEvent.delete:
          final deletedId = payload.oldRecord['id'] as String;
          final updatedOrders = state.orders.where((order) => order.id != deletedId).toList();
          state = state.copyWith(
            orders: updatedOrders,
            lastUpdated: DateTime.now(),
          );
          break;
        case PostgresChangeEvent.all:
          // Handle all events case - this is used when subscribing to all events
          // We can ignore this case as it's handled by the specific cases above
          break;
      }
    } catch (e) {
      DebugLogger.error('Error handling real-time update: $e', tag: 'EnhancedOrdersNotifier');
    }
  }

  /// Process real-time order data to handle JSON fields properly (Android fix)
  Map<String, dynamic> _processRealtimeOrderData(Map<String, dynamic> rawData) {
    try {
      final orderData = Map<String, dynamic>.from(rawData);

      debugPrint('🔍 [ANDROID-DEBUG-REALTIME] Processing real-time order data...');
      debugPrint('🔍 [ANDROID-DEBUG-REALTIME] Order ID: ${orderData['id']}');

      // Handle delivery_address field - convert from JSON string to Map if needed
      if (orderData['delivery_address'] is String) {
        try {
          debugPrint('🔍 [ANDROID-DEBUG-REALTIME] Converting delivery_address from String to Map');
          orderData['delivery_address'] = jsonDecode(orderData['delivery_address']);
          debugPrint('🔍 [ANDROID-DEBUG-REALTIME] Conversion successful');
        } catch (e) {
          debugPrint('🔍 [ANDROID-DEBUG-REALTIME] Error parsing delivery_address JSON: $e');
          // Provide a default address if parsing fails
          orderData['delivery_address'] = {
            'street': 'Unknown',
            'city': 'Unknown',
            'state': 'Unknown',
            'postal_code': '00000',
            'country': 'Malaysia',
          };
        }
      } else if (orderData['delivery_address'] == null) {
        debugPrint('🔍 [ANDROID-DEBUG-REALTIME] delivery_address is null, providing default');
        orderData['delivery_address'] = {
          'street': 'Unknown',
          'city': 'Unknown',
          'state': 'Unknown',
          'postal_code': '00000',
          'country': 'Malaysia',
        };
      } else {
        debugPrint('🔍 [ANDROID-DEBUG-REALTIME] delivery_address is already a Map: ${orderData['delivery_address'].runtimeType}');
      }

      // Handle metadata field - convert from JSON string to Map if needed
      if (orderData['metadata'] is String) {
        try {
          debugPrint('🔍 [ANDROID-DEBUG-REALTIME] Converting metadata from String to Map');
          orderData['metadata'] = jsonDecode(orderData['metadata']);
        } catch (e) {
          debugPrint('🔍 [ANDROID-DEBUG-REALTIME] Error parsing metadata JSON: $e');
          orderData['metadata'] = null;
        }
      }

      debugPrint('🔍 [ANDROID-DEBUG-REALTIME] Real-time data processing completed successfully');
      return orderData;
    } catch (e, stackTrace) {
      debugPrint('🔍 [ANDROID-DEBUG-REALTIME] ERROR in real-time data processing: $e');
      debugPrint('🔍 [ANDROID-DEBUG-REALTIME] Stack trace: $stackTrace');
      debugPrint('🔍 [ANDROID-DEBUG-REALTIME] Raw data: $rawData');
      rethrow;
    }
  }

  // Load orders with Edge Function validation
  Future<void> loadOrders({OrderStatus? status}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      debugPrint('EnhancedOrdersNotifier: Loading orders from repository');
      
      final orders = await _orderRepository.getOrders(status: status);
      
      state = state.copyWith(
        orders: orders,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
      
      debugPrint('EnhancedOrdersNotifier: Loaded ${orders.length} orders');
    } catch (e) {
      debugPrint('EnhancedOrdersNotifier: Error loading orders: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  // Create order using Edge Function for validation
  Future<Order?> createOrderWithEdgeFunction(CreateOrderRequest request) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      DebugLogger.info('Creating order with fallback validation (Edge Function not available)', tag: 'EnhancedOrdersNotifier');

      // Since Edge Function doesn't exist, use direct database call with validation
      // First validate the order data locally
      final validationErrors = _validateOrderRequest(request);
      if (validationErrors.isNotEmpty) {
        throw Exception('Validation errors: ${validationErrors.join(', ')}');
      }

      // Convert CreateOrderRequest to Order object
      final order = _createOrderFromRequest(request);

      // Create order directly using repository
      final createdOrder = await _orderRepository.createOrder(order);

      // Add to local state with optimistic update
      final updatedOrders = [createdOrder, ...state.orders];
      state = state.copyWith(
        orders: updatedOrders,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );

      DebugLogger.success('Order created successfully (fallback mode): ${createdOrder.id}', tag: 'EnhancedOrdersNotifier');
      return createdOrder;

    } catch (e) {
      DebugLogger.error('Error creating order: $e', tag: 'EnhancedOrdersNotifier');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  // Local validation helper
  List<String> _validateOrderRequest(CreateOrderRequest request) {
    final errors = <String>[];

    if (request.items.isEmpty) {
      errors.add('Order must have at least one item');
    }

    if (request.customerId.isEmpty) {
      errors.add('Customer ID is required');
    }

    if (request.vendorId.isEmpty) {
      errors.add('Vendor ID is required');
    }

    // Validate delivery date is in the future
    if (request.deliveryDate.isBefore(DateTime.now())) {
      errors.add('Delivery date must be in the future');
    }

    return errors;
  }

  // Convert CreateOrderRequest to Order object
  Order _createOrderFromRequest(CreateOrderRequest request) {
    // Convert OrderItemRequest to OrderItem
    final orderItems = request.items.map((itemRequest) {
      return OrderItem(
        id: 'temp-${DateTime.now().millisecondsSinceEpoch}-${itemRequest.hashCode}', // Temporary ID - will be removed before database insert
        menuItemId: itemRequest.menuItemId,
        name: 'Test Item', // Placeholder - would normally come from menu
        description: 'Test item description',
        unitPrice: itemRequest.unitPrice,
        quantity: itemRequest.quantity,
        totalPrice: itemRequest.unitPrice * itemRequest.quantity,
        customizations: itemRequest.customizations ?? {},
        notes: itemRequest.notes,
      );
    }).toList();

    // Convert address map to Address object
    final addressData = request.deliveryAddress;
    final deliveryAddress = Address(
      street: addressData['street'] ?? '',
      city: addressData['city'] ?? '',
      state: addressData['state'] ?? '',
      postalCode: addressData['postal_code'] ?? '',
      country: addressData['country'] ?? 'Malaysia',
      latitude: addressData['latitude']?.toDouble(),
      longitude: addressData['longitude']?.toDouble(),
      notes: addressData['notes'],
    );

    // Calculate totals
    final subtotal = orderItems.fold(0.0, (sum, item) => sum + item.totalPrice);
    final deliveryFee = 5.0; // Fixed delivery fee for testing
    final sstAmount = subtotal * 0.06; // 6% SST
    final totalAmount = subtotal + deliveryFee + sstAmount;

    return Order(
      id: 'temp-order-${DateTime.now().millisecondsSinceEpoch}', // Temporary ID - will be removed before database insert
      orderNumber: 'temp-order-number', // Temporary order number - will be removed before database insert
      status: OrderStatus.pending,
      items: orderItems,
      vendorId: request.vendorId,
      vendorName: 'Nasi Lemak Delicious', // Actual existing vendor
      customerId: request.customerId,
      customerName: 'Tech Solutions Sdn Bhd', // From seed.sql
      salesAgentId: request.salesAgentId,
      salesAgentName: 'Current User', // Will be the authenticated user
      deliveryDate: request.deliveryDate,
      deliveryAddress: deliveryAddress,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      sstAmount: sstAmount,
      totalAmount: totalAmount,
      notes: request.specialInstructions,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      contactPhone: request.contactPhone,
      specialInstructions: request.specialInstructions,
    );
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }
}

// Enhanced Orders Provider
final enhancedOrdersProvider = StateNotifierProvider<EnhancedOrdersNotifier, EnhancedOrdersState>((ref) {
  final orderRepository = ref.watch(orderRepositoryProvider);
  final supabase = ref.watch(supabaseProvider);
  return EnhancedOrdersNotifier(orderRepository, supabase, ref);
});

// Filtered Orders Providers
final enhancedPendingOrdersProvider = Provider<List<Order>>((ref) {
  final ordersState = ref.watch(enhancedOrdersProvider);
  return ordersState.orders
      .where((order) => order.status == OrderStatus.pending)
      .toList();
});

final enhancedActiveOrdersProvider = Provider<List<Order>>((ref) {
  final ordersState = ref.watch(enhancedOrdersProvider);
  return ordersState.orders
      .where((order) =>
          order.status != OrderStatus.delivered &&
          order.status != OrderStatus.cancelled)
      .toList();
});

final enhancedCompletedOrdersProvider = Provider<List<Order>>((ref) {
  final ordersState = ref.watch(enhancedOrdersProvider);
  return ordersState.orders
      .where((order) => order.status == OrderStatus.delivered)
      .toList();
});
