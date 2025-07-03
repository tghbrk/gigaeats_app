import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../orders/data/models/order.dart';
import '../../../../core/services/auth_service.dart';

/// Provider for auth service
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Provider for active driver orders
final activeDriverOrdersProvider = FutureProvider<List<Order>>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final user = authService.currentUser;
  
  if (user == null) return [];
  
  try {
    final supabase = Supabase.instance.client;
    
    // Get orders assigned to this driver that are active
    final response = await supabase
        .from('orders')
        .select('*, order_items(*), vendors(name, image_url)')
        .eq('assigned_driver_id', user.id)
        .inFilter('status', [
          'confirmed',
          'preparing',
          'ready',
          'out_for_delivery'
        ])
        .order('created_at', ascending: false);

    return response.map((json) => Order.fromJson(json)).toList();
  } catch (e) {
    throw Exception('Failed to fetch active driver orders: $e');
  }
});

/// Provider for available orders (orders ready for pickup with no assigned driver)
final availableOrdersProvider = FutureProvider<List<Order>>((ref) async {
  try {
    final supabase = Supabase.instance.client;
    
    // Get orders that are ready and have no assigned driver
    final response = await supabase
        .from('orders')
        .select('*, order_items(*), vendors(name, image_url)')
        .eq('status', 'ready')
        .isFilter('assigned_driver_id', null)
        .eq('delivery_method', 'own_fleet')
        .order('created_at', ascending: true);

    return response.map((json) => Order.fromJson(json)).toList();
  } catch (e) {
    throw Exception('Failed to fetch available orders: $e');
  }
});

/// Provider for driver order history
final driverOrderHistoryProvider = FutureProvider.family<List<Order>, String>((ref, driverId) async {
  try {
    final supabase = Supabase.instance.client;
    
    final response = await supabase
        .from('orders')
        .select('*, order_items(*), vendors(name, image_url)')
        .eq('assigned_driver_id', driverId)
        .eq('status', 'delivered')
        .order('delivered_at', ascending: false)
        .limit(50);

    return response.map((json) => Order.fromJson(json)).toList();
  } catch (e) {
    throw Exception('Failed to fetch driver order history: $e');
  }
});

/// Provider for driver statistics
final driverStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final user = authService.currentUser;
  
  if (user == null) return {};
  
  try {
    final supabase = Supabase.instance.client;
    
    // Get all orders for this driver
    final response = await supabase
        .from('orders')
        .select('id, total_amount, status, created_at, delivered_at')
        .eq('assigned_driver_id', user.id);

    final totalOrders = response.length;
    final completedOrders = response.where((o) => o['status'] == 'delivered').toList();
    final totalEarnings = completedOrders.fold<double>(
      0, 
      (sum, order) => sum + ((order['total_amount'] as num).toDouble() * 0.1) // 10% commission
    );

    // Calculate today's stats
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    final todayOrders = response.where((o) {
      final orderDate = DateTime.parse(o['created_at']);
      return orderDate.isAfter(startOfDay);
    }).toList();

    final todayEarnings = todayOrders
        .where((o) => o['status'] == 'delivered')
        .fold<double>(0, (sum, order) => sum + ((order['total_amount'] as num).toDouble() * 0.1));

    // Calculate average delivery time
    double averageDeliveryTime = 0;
    if (completedOrders.isNotEmpty) {
      final totalDeliveryTime = completedOrders.fold<int>(0, (sum, order) {
        if (order['delivered_at'] != null) {
          final created = DateTime.parse(order['created_at']);
          final delivered = DateTime.parse(order['delivered_at']);
          return sum + delivered.difference(created).inMinutes;
        }
        return sum;
      });
      averageDeliveryTime = totalDeliveryTime / completedOrders.length;
    }

    return {
      'total_orders': totalOrders,
      'completed_orders': completedOrders.length,
      'total_earnings': totalEarnings,
      'today_orders': todayOrders.length,
      'today_earnings': todayEarnings,
      'average_delivery_time': averageDeliveryTime,
      'completion_rate': totalOrders > 0 ? (completedOrders.length / totalOrders) * 100 : 0,
    };
  } catch (e) {
    throw Exception('Failed to fetch driver stats: $e');
  }
});

/// Notifier for managing driver order actions
class DriverOrderNotifier extends StateNotifier<AsyncValue<void>> {
  DriverOrderNotifier() : super(const AsyncValue.data(null));

  /// Accept an available order
  Future<void> acceptOrder(String orderId) async {
    state = const AsyncValue.loading();
    
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await supabase
          .from('orders')
          .update({
            'assigned_driver_id': user.id,
            'status': 'confirmed',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Update order status (for driver workflow)
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    state = const AsyncValue.loading();
    
    try {
      final supabase = Supabase.instance.client;
      
      final updateData = {
        'status': newStatus.name,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Add status-specific timestamps
      switch (newStatus) {
        case OrderStatus.outForDelivery:
          updateData['out_for_delivery_at'] = DateTime.now().toIso8601String();
          break;
        case OrderStatus.delivered:
          updateData['delivered_at'] = DateTime.now().toIso8601String();
          updateData['actual_delivery_time'] = DateTime.now().toIso8601String();
          break;
        default:
          break;
      }

      await supabase
          .from('orders')
          .update(updateData)
          .eq('id', orderId);

      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Mark order as picked up from vendor
  Future<void> markOrderPickedUp(String orderId) async {
    await updateOrderStatus(orderId, OrderStatus.outForDelivery);
  }

  /// Mark order as delivered
  Future<void> markOrderDelivered(String orderId) async {
    await updateOrderStatus(orderId, OrderStatus.delivered);
  }
}

/// Provider for driver order actions
final driverOrderNotifierProvider = StateNotifierProvider<DriverOrderNotifier, AsyncValue<void>>((ref) {
  return DriverOrderNotifier();
});

/// Provider for real-time driver orders stream
final driverOrdersStreamProvider = StreamProvider<List<Order>>((ref) {
  final authService = ref.watch(authServiceProvider);
  final user = authService.currentUser;
  
  if (user == null) {
    return Stream.value([]);
  }

  final supabase = Supabase.instance.client;
  
  return supabase
      .from('orders')
      .stream(primaryKey: ['id'])
      .eq('assigned_driver_id', user.id)
      .map((data) {
        // Filter in memory for stream compatibility
        final filteredData = data.where((json) {
          final status = json['status'] as String?;
          return status != null && ['confirmed', 'preparing', 'ready', 'out_for_delivery'].contains(status);
        }).toList();
        return filteredData.map((json) => Order.fromJson(json)).toList();
      });
});

/// Provider for driver status management
class DriverStatusNotifier extends StateNotifier<String> {
  DriverStatusNotifier() : super('offline');

  /// Update driver availability status
  Future<void> updateStatus(String status) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      
      if (user == null) return;

      await supabase
          .from('drivers')
          .update({
            'status': status,
            'last_active_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', user.id);

      state = status;
    } catch (e) {
      // Handle error silently for now
    }
  }

  /// Go online
  Future<void> goOnline() async {
    await updateStatus('online');
  }

  /// Go offline
  Future<void> goOffline() async {
    await updateStatus('offline');
  }

  /// Set as busy
  Future<void> setBusy() async {
    await updateStatus('busy');
  }
}

/// Provider for driver status
final driverStatusProvider = StateNotifierProvider<DriverStatusNotifier, String>((ref) {
  return DriverStatusNotifier();
});
