import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../orders/data/models/order.dart';
import '../../../../data/models/user_role.dart';

/// Provider for current driver status (online/offline)
final currentDriverStatusProvider = StreamProvider.autoDispose<String>((ref) async* {
  final authState = ref.read(authStateProvider);
  
  if (authState.user?.role != UserRole.driver) {
    yield 'offline';
    return;
  }

  final userId = authState.user?.id;
  if (userId == null) {
    yield 'offline';
    return;
  }

  try {
    final supabase = Supabase.instance.client;
    
    // Get initial status
    final initialResponse = await supabase
        .from('drivers')
        .select('status')
        .eq('user_id', userId)
        .single();
    
    yield initialResponse['status'] as String? ?? 'offline';

    // Stream status changes
    yield* supabase
        .from('drivers')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) {
          if (data.isEmpty) return 'offline';
          return data.first['status'] as String? ?? 'offline';
        });
  } catch (e) {
    debugPrint('Error streaming driver status: $e');
    yield 'offline';
  }
});

/// Provider for available orders (status: 'ready', no assigned driver)
final availableOrdersProvider = StreamProvider.autoDispose<List<Order>>((ref) async* {
  final authState = ref.read(authStateProvider);
  
  if (authState.user?.role != UserRole.driver) {
    yield <Order>[];
    return;
  }

  final driverStatus = ref.watch(currentDriverStatusProvider);
  
  // Only fetch orders if driver is online
  if (driverStatus.value != 'online') {
    yield <Order>[];
    return;
  }

  try {
    final supabase = Supabase.instance.client;
    
    debugPrint('🚗 Streaming available orders for driver');
    
    // First get initial data with order_items
    final initialResponse = await supabase
        .from('orders')
        .select('''
          *,
          order_items:order_items(
            *,
            menu_item:menu_items!order_items_menu_item_id_fkey(
              id,
              name,
              image_url
            )
          ),
          vendors:vendors!orders_vendor_id_fkey(
            business_name,
            business_address
          )
        ''')
        .eq('status', 'ready')
        .isFilter('assigned_driver_id', null)
        .order('created_at', ascending: true);

    debugPrint('🚗 Initial available orders loaded: ${initialResponse.length} orders');
    final initialOrders = initialResponse.map((json) => Order.fromJson(json)).toList();
    yield initialOrders;

    // Then listen for real-time updates (note: stream doesn't support complex selects)
    yield* supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('status', 'ready')
        .order('created_at', ascending: true)
        .asyncMap((data) async {
          debugPrint('🚗 Available orders stream update: ${data.length} orders');
          // Filter out orders that already have an assigned driver
          final availableOrderIds = data
              .where((json) => json['assigned_driver_id'] == null)
              .map((json) => json['id'] as String)
              .toList();

          if (availableOrderIds.isEmpty) {
            debugPrint('🚗 No available orders after filtering');
            return <Order>[];
          }

          // Fetch full order data with order_items for the filtered orders
          final fullResponse = await supabase
              .from('orders')
              .select('''
                *,
                order_items:order_items(
                  *,
                  menu_item:menu_items!order_items_menu_item_id_fkey(
                    id,
                    name,
                    image_url
                  )
                ),
                vendors:vendors!orders_vendor_id_fkey(
                  business_name,
                  business_address
                )
              ''')
              .inFilter('id', availableOrderIds)
              .order('created_at', ascending: true);

          debugPrint('🚗 Fetched full data for ${fullResponse.length} available orders');
          final orders = fullResponse.map((json) => Order.fromJson(json)).toList();

          // Debug order items count
          for (final order in orders) {
            debugPrint('🚗 Order ${order.orderNumber}: ${order.items.length} items');
          }

          return orders;
        });
  } catch (e) {
    debugPrint('Error streaming available orders: $e');
    yield <Order>[];
  }
});

/// Provider for current driver's assigned order
final currentDriverOrderProvider = StreamProvider.autoDispose<Order?>((ref) async* {
  final authState = ref.read(authStateProvider);
  
  if (authState.user?.role != UserRole.driver) {
    yield null;
    return;
  }

  final userId = authState.user?.id;
  if (userId == null) {
    yield null;
    return;
  }

  try {
    final supabase = Supabase.instance.client;
    
    debugPrint('🚗 Streaming current driver order');
    
    // First get initial data with order_items
    final initialResponse = await supabase
        .from('orders')
        .select('''
          *,
          order_items:order_items(
            *,
            menu_item:menu_items!order_items_menu_item_id_fkey(
              id,
              name,
              image_url
            )
          ),
          vendors:vendors!orders_vendor_id_fkey(
            business_name,
            business_address
          )
        ''')
        .eq('assigned_driver_id', userId)
        .inFilter('status', [
          'assigned',
          'confirmed',
          'preparing',
          'ready',
          'out_for_delivery',
          'on_route_to_vendor',
          'arrived_at_vendor',
          'picked_up',
          'on_route_to_customer',
          'arrived_at_customer'
        ])
        .order('created_at', ascending: false)
        .limit(1);

    debugPrint('🚗 Initial current order loaded: ${initialResponse.length} orders');
    if (initialResponse.isNotEmpty) {
      final initialOrder = Order.fromJson(initialResponse.first);
      debugPrint('🚗 Current order ${initialOrder.orderNumber}: ${initialOrder.items.length} items');
      yield initialOrder;
    } else {
      yield null;
    }

    // Then listen for real-time updates
    yield* supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('assigned_driver_id', userId)
        .order('created_at', ascending: false)
        .asyncMap((data) async {
          debugPrint('🚗 Current order stream update: ${data.length} orders');
          // Filter for active statuses - include all driver workflow statuses
          final activeStatuses = [
            'assigned',
            'confirmed',
            'preparing',
            'ready',
            'out_for_delivery',
            'on_route_to_vendor',
            'arrived_at_vendor',
            'picked_up',
            'on_route_to_customer',
            'arrived_at_customer'
          ];
          final activeOrders = data.where((json) =>
            activeStatuses.contains(json['status'])
          ).toList();
          debugPrint('🚗 Filtered active orders: ${activeOrders.length} orders');

          if (activeOrders.isEmpty) return null;

          final orderId = activeOrders.first['id'] as String;

          // Fetch full order data with order_items
          final fullResponse = await supabase
              .from('orders')
              .select('''
                *,
                order_items:order_items(
                  *,
                  menu_item:menu_items!order_items_menu_item_id_fkey(
                    id,
                    name,
                    image_url
                  )
                ),
                vendors:vendors!orders_vendor_id_fkey(
                  business_name,
                  business_address
                )
              ''')
              .eq('id', orderId)
              .single();

          final order = Order.fromJson(fullResponse);
          debugPrint('🚗 Current order ${order.orderNumber}: ${order.items.length} items');
          return order;
        });
  } catch (e) {
    debugPrint('Error streaming current driver order: $e');
    yield null;
  }
});

/// Provider for today's earnings summary
final todayEarningsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final authState = ref.read(authStateProvider);
  
  if (authState.user?.role != UserRole.driver) {
    return {
      'totalEarnings': 0.0,
      'orderCount': 0,
      'commission': 0.0,
    };
  }

  final userId = authState.user?.id;
  if (userId == null) {
    return {
      'totalEarnings': 0.0,
      'orderCount': 0,
      'commission': 0.0,
    };
  }

  try {
    final supabase = Supabase.instance.client;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    debugPrint('🚗 Fetching today\'s earnings for driver');
    
    // Get today's completed orders
    final response = await supabase
        .from('orders')
        .select('id, total_amount, delivery_fee, commission_amount')
        .eq('assigned_driver_id', userId)
        .eq('status', 'delivered')
        .gte('actual_delivery_time', startOfDay.toIso8601String())
        .lt('actual_delivery_time', endOfDay.toIso8601String());

    final orderCount = response.length;
    final totalEarnings = response.fold<double>(
      0.0,
      (sum, order) => sum + ((order['commission_amount'] as num?)?.toDouble() ?? 
                            (order['delivery_fee'] as num?)?.toDouble() ?? 0.0),
    );
    
    // Calculate commission (10% of total order value as fallback)
    final commission = response.fold<double>(
      0.0,
      (sum, order) => sum + ((order['commission_amount'] as num?)?.toDouble() ?? 
                            ((order['total_amount'] as num?)?.toDouble() ?? 0.0) * 0.1),
    );

    debugPrint('🚗 Today\'s earnings: RM$totalEarnings, Orders: $orderCount');

    return {
      'totalEarnings': totalEarnings,
      'orderCount': orderCount,
      'commission': commission,
    };
  } catch (e) {
    debugPrint('Error fetching today\'s earnings: $e');
    return {
      'totalEarnings': 0.0,
      'orderCount': 0,
      'commission': 0.0,
    };
  }
});

/// Provider for driver status management
final driverStatusNotifierProvider = StateNotifierProvider<DriverStatusNotifier, AsyncValue<String>>((ref) {
  return DriverStatusNotifier(ref);
});

/// Notifier for managing driver online/offline status
class DriverStatusNotifier extends StateNotifier<AsyncValue<String>> {
  final Ref _ref;
  
  DriverStatusNotifier(this._ref) : super(const AsyncValue.loading());

  /// Toggle driver status between online and offline
  Future<void> toggleStatus() async {
    final authState = _ref.read(authStateProvider);
    
    if (authState.user?.role != UserRole.driver) {
      state = AsyncValue.error('User is not a driver', StackTrace.current);
      return;
    }

    final userId = authState.user?.id;
    if (userId == null) {
      state = AsyncValue.error('User ID not found', StackTrace.current);
      return;
    }

    try {
      state = const AsyncValue.loading();
      
      final supabase = Supabase.instance.client;
      
      // Get current status
      final currentResponse = await supabase
          .from('drivers')
          .select('status')
          .eq('user_id', userId)
          .single();
      
      final currentStatus = currentResponse['status'] as String? ?? 'offline';
      final newStatus = currentStatus == 'online' ? 'offline' : 'online';
      
      // Update status
      await supabase
          .from('drivers')
          .update({
            'status': newStatus,
            'last_active_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);

      debugPrint('🚗 Driver status updated to: $newStatus');
      state = AsyncValue.data(newStatus);
    } catch (e) {
      debugPrint('Error toggling driver status: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Set driver status to online
  Future<void> goOnline() async {
    await _updateStatus('online');
  }

  /// Set driver status to offline
  Future<void> goOffline() async {
    await _updateStatus('offline');
  }

  Future<void> _updateStatus(String status) async {
    final authState = _ref.read(authStateProvider);
    
    if (authState.user?.role != UserRole.driver) {
      state = AsyncValue.error('User is not a driver', StackTrace.current);
      return;
    }

    final userId = authState.user?.id;
    if (userId == null) {
      state = AsyncValue.error('User ID not found', StackTrace.current);
      return;
    }

    try {
      state = const AsyncValue.loading();
      
      final supabase = Supabase.instance.client;
      
      await supabase
          .from('drivers')
          .update({
            'status': status,
            'last_active_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);

      debugPrint('🚗 Driver status updated to: $status');
      state = AsyncValue.data(status);
    } catch (e) {
      debugPrint('Error updating driver status: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
