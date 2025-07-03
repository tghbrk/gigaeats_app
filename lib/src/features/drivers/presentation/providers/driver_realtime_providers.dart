import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/user_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../user_management/domain/driver.dart';
import '../../../orders/data/models/driver_order.dart';
import '../../data/models/driver_error.dart';
import '../../../orders/data/repositories/driver_order_repository.dart';
import '../../data/services/driver_realtime_service.dart';
import '../../data/services/driver_order_service.dart';


import 'driver_dashboard_provider.dart';
import '../../../user_management/presentation/providers/driver_profile_provider.dart';

/// Driver Realtime Service Provider
final driverRealtimeServiceProvider = Provider<DriverRealtimeService>((ref) {
  return DriverRealtimeService();
});

/// Driver Order Service Provider
final driverOrderServiceProvider = Provider<DriverOrderService>((ref) {
  final repository = ref.watch(driverOrderRepositoryProvider);
  return DriverOrderService(repository: repository);
});

/// Current Driver ID Provider
final currentDriverIdProvider = FutureProvider<String>((ref) async {
  final authState = ref.read(authStateProvider);
  final dashboardService = ref.read(driverDashboardServiceProvider);

  if (authState.user == null) {
    throw DriverException('User not authenticated', DriverErrorType.authentication);
  }

  final driverId = await dashboardService.getDriverIdFromUserId(authState.user!.id);
  if (driverId == null) {
    throw DriverException(
      'Driver profile not found. Please contact support or try logging out and back in.',
      DriverErrorType.driverNotFound,
    );
  }

  return driverId;
});

/// Helper function to get driver ID from cached provider
Future<String> _getDriverIdFromProvider(Ref ref) async {
  final authState = ref.read(authStateProvider);
  final dashboardService = ref.read(driverDashboardServiceProvider);

  if (authState.user == null) {
    throw DriverException('User not authenticated', DriverErrorType.authentication);
  }

  final driverId = await dashboardService.getDriverIdFromUserId(authState.user!.id);
  if (driverId == null) {
    throw DriverException(
      'Driver profile not found. Please contact support or try logging out and back in.',
      DriverErrorType.driverNotFound,
    );
  }

  return driverId;
}

/// Enhanced realtime-aware provider for driver orders
/// Automatically updates when realtime events occur
final realtimeDriverOrdersProvider = StreamProvider<List<DriverOrder>>((ref) async* {
  final authState = ref.read(authStateProvider);
  final repository = ref.read(driverOrderRepositoryProvider);
  final realtimeService = ref.read(driverRealtimeServiceProvider);

  if (authState.user?.role != UserRole.driver) {
    throw DriverException('Only drivers can access driver orders', DriverErrorType.permissionDenied);
  }

  try {
    final driverId = await _getDriverIdFromProvider(ref);
    
    // Initialize realtime subscriptions
    await realtimeService.initializeForDriver(driverId);
    
    // Get initial data
    List<DriverOrder> currentOrders = await repository.getDriverOrders(driverId);
    yield currentOrders;

    // Listen to realtime updates and refresh data when changes occur
    await for (final update in realtimeService.orderStatusUpdates) {
      debugPrint('RealtimeDriverOrdersProvider: Received update: ${update['type']}');
      
      try {
        // Refresh orders when realtime update received
        currentOrders = await repository.getDriverOrders(driverId);
        yield currentOrders;
      } catch (e) {
        debugPrint('RealtimeDriverOrdersProvider: Error refreshing orders: $e');
        // Continue with current orders if refresh fails
      }
    }
  } catch (e) {
    debugPrint('RealtimeDriverOrdersProvider: Error: $e');
    throw DriverException.fromException(e);
  }
});

/// Enhanced realtime-aware provider for available orders
final realtimeAvailableOrdersProvider = StreamProvider<List<DriverOrder>>((ref) async* {
  final authState = ref.read(authStateProvider);
  final repository = ref.read(driverOrderRepositoryProvider);
  final realtimeService = ref.read(driverRealtimeServiceProvider);

  if (authState.user?.role != UserRole.driver) {
    throw DriverException('Only drivers can access available orders', DriverErrorType.permissionDenied);
  }

  try {
    final driverId = await _getDriverIdFromProvider(ref);
    debugPrint('🚗 RealtimeAvailableOrdersProvider: Starting for driver: $driverId');

    // Get initial data
    List<DriverOrder> currentOrders = await repository.getAvailableOrders(driverId);
    debugPrint('🚗 RealtimeAvailableOrdersProvider: Initial data - ${currentOrders.length} orders');
    for (final order in currentOrders) {
      debugPrint('🚗   - Order: ${order.orderNumber} (${order.status.displayName})');
    }
    yield currentOrders;

    // Listen to realtime updates for order changes that might affect availability
    await for (final update in realtimeService.orderStatusUpdates) {
      debugPrint('RealtimeAvailableOrdersProvider: Received update: ${update['type']}');

      try {
        // Refresh available orders when realtime update received
        currentOrders = await repository.getAvailableOrders(driverId);
        debugPrint('🚗 RealtimeAvailableOrdersProvider: Updated data - ${currentOrders.length} orders');
        yield currentOrders;
      } catch (e) {
        debugPrint('RealtimeAvailableOrdersProvider: Error refreshing orders: $e');
        // Continue with current orders if refresh fails
      }
    }
  } catch (e) {
    debugPrint('🚗 RealtimeAvailableOrdersProvider: Error: $e');
    throw DriverException.fromException(e);
  }
});

/// Status-aware available orders provider that only fetches when driver is online
final statusAwareAvailableOrdersProvider = Provider<List<DriverOrder>>((ref) {
  final authState = ref.read(authStateProvider);

  if (authState.user?.role != UserRole.driver) {
    return [];
  }

  // Watch driver profile for status
  final driverProfileAsync = ref.watch(driverProfileStreamProvider);

  return driverProfileAsync.when(
    data: (driver) {
      if (driver == null) {
        debugPrint('🚗 StatusAwareAvailableOrdersProvider: No driver profile found');
        return <DriverOrder>[];
      }

      debugPrint('🚗 StatusAwareAvailableOrdersProvider: Driver status: ${driver.status.displayName}');

      // Only fetch available orders if driver is online
      if (driver.status == DriverStatus.online) {
        debugPrint('🚗 StatusAwareAvailableOrdersProvider: Driver is online, watching available orders');

        // Watch the realtime available orders when online
        final availableOrdersAsync = ref.watch(realtimeAvailableOrdersProvider);
        return availableOrdersAsync.when(
          data: (orders) {
            debugPrint('🚗 StatusAwareAvailableOrdersProvider: Returning ${orders.length} available orders');
            return orders;
          },
          loading: () {
            debugPrint('🚗 StatusAwareAvailableOrdersProvider: Loading available orders...');
            return <DriverOrder>[];
          },
          error: (error, stack) {
            debugPrint('🚗 StatusAwareAvailableOrdersProvider: Error loading orders: $error');
            return <DriverOrder>[];
          },
        );
      } else {
        debugPrint('🚗 StatusAwareAvailableOrdersProvider: Driver is ${driver.status.displayName}, returning empty list');
        return <DriverOrder>[];
      }
    },
    loading: () {
      debugPrint('🚗 StatusAwareAvailableOrdersProvider: Loading driver profile...');
      return <DriverOrder>[];
    },
    error: (error, stack) {
      debugPrint('🚗 StatusAwareAvailableOrdersProvider: Error loading driver profile: $error');
      return <DriverOrder>[];
    },
  );
});

/// Realtime-aware active orders provider
final realtimeActiveDriverOrdersProvider = Provider<List<DriverOrder>>((ref) {
  final ordersAsync = ref.watch(realtimeDriverOrdersProvider);
  final orderService = ref.read(driverOrderServiceProvider);

  return ordersAsync.when(
    data: (orders) => orderService.getActiveOrders(orders),
    loading: () => [],
    error: (error, stack) {
      debugPrint('RealtimeActiveDriverOrdersProvider: Error: $error');
      return [];
    },
  );
});

/// Realtime-aware completed orders provider
final realtimeCompletedDriverOrdersProvider = StreamProvider<List<DriverOrder>>((ref) async* {
  final authState = ref.read(authStateProvider);
  final repository = ref.read(driverOrderRepositoryProvider);
  final realtimeService = ref.read(driverRealtimeServiceProvider);

  if (authState.user?.role != UserRole.driver) {
    throw DriverException('Only drivers can access completed orders', DriverErrorType.permissionDenied);
  }

  try {
    final driverId = await _getDriverIdFromProvider(ref);
    debugPrint('🚗 RealtimeCompletedDriverOrdersProvider: Starting for driver: $driverId');

    // Get initial completed orders data
    List<DriverOrder> currentOrders = await repository.getDriverOrderHistory(driverId);
    debugPrint('🚗 RealtimeCompletedDriverOrdersProvider: Initial data - ${currentOrders.length} completed orders');
    yield currentOrders;

    // Listen to realtime updates for order status changes that might affect completed orders
    await for (final update in realtimeService.orderStatusUpdates) {
      debugPrint('RealtimeCompletedDriverOrdersProvider: Received update: ${update['type']}');

      try {
        // Refresh completed orders when realtime update received
        currentOrders = await repository.getDriverOrderHistory(driverId);
        debugPrint('🚗 RealtimeCompletedDriverOrdersProvider: Updated data - ${currentOrders.length} completed orders');
        yield currentOrders;
      } catch (e) {
        debugPrint('RealtimeCompletedDriverOrdersProvider: Error refreshing orders: $e');
        // Continue with current orders if refresh fails
      }
    }
  } catch (e) {
    debugPrint('🚗 RealtimeCompletedDriverOrdersProvider: Error: $e');
    throw DriverException.fromException(e);
  }
});

/// Provider for realtime order notifications
final realtimeOrderNotificationsProvider = StreamProvider<DriverOrderNotification?>((ref) async* {
  final realtimeService = ref.read(driverRealtimeServiceProvider);
  
  await for (final update in realtimeService.orderStatusUpdates) {
    final notification = _parseOrderNotification(update);
    if (notification != null) {
      yield notification;
    }
  }
});

/// Provider for realtime driver notifications
final realtimeDriverNotificationsProvider = StreamProvider<DriverNotification?>((ref) async* {
  final realtimeService = ref.read(driverRealtimeServiceProvider);
  
  await for (final update in realtimeService.driverNotifications) {
    final notification = _parseDriverNotification(update);
    if (notification != null) {
      yield notification;
    }
  }
});

/// Enhanced driver order actions with realtime integration
final realtimeDriverOrderActionsProvider = Provider<RealtimeDriverOrderActions>((ref) {
  return RealtimeDriverOrderActions(ref);
});

/// Enhanced driver order actions class with realtime awareness
class RealtimeDriverOrderActions {
  final Ref _ref;

  RealtimeDriverOrderActions(this._ref);

  /// Accept an order with realtime updates
  Future<DriverResult<bool>> acceptOrder(String orderId) async {
    try {
      final authState = _ref.read(authStateProvider);
      final orderService = _ref.read(driverOrderServiceProvider);

      if (authState.user?.role != UserRole.driver) {
        return DriverResult.error(
          DriverException('Only drivers can accept orders', DriverErrorType.permissionDenied),
        );
      }

      final driverId = await _getDriverIdFromProvider(_ref);
      final success = await orderService.acceptOrder(orderId, driverId);

      if (success) {
        debugPrint('Order accepted successfully, realtime subscriptions will update UI automatically');
        // No manual invalidation needed - realtime providers will update automatically
        return DriverResult.success(true);
      } else {
        return DriverResult.error(
          DriverException('Failed to accept order', DriverErrorType.orderAcceptance),
        );
      }
    } catch (e) {
      debugPrint('Error accepting order: $e');
      return DriverResult.fromException(e);
    }
  }

  /// Reject an order with realtime updates
  Future<DriverResult<bool>> rejectOrder(String orderId) async {
    try {
      final authState = _ref.read(authStateProvider);
      final repository = _ref.read(driverOrderRepositoryProvider);

      if (authState.user?.role != UserRole.driver) {
        return DriverResult.error(
          DriverException('Only drivers can reject orders', DriverErrorType.permissionDenied),
        );
      }

      final driverId = await _getDriverIdFromProvider(_ref);
      final success = await repository.rejectOrder(orderId, driverId);
      
      if (success) {
        debugPrint('Order rejected successfully, realtime subscriptions will update UI automatically');
        return DriverResult.success(true);
      } else {
        return DriverResult.error(
          DriverException('Failed to reject order', DriverErrorType.unknown),
        );
      }
    } catch (e) {
      debugPrint('Error rejecting order: $e');
      return DriverResult.fromException(e);
    }
  }

  /// Update order status with realtime updates
  Future<DriverResult<bool>> updateOrderStatus(String orderId, DriverOrderStatus status) async {
    try {
      final authState = _ref.read(authStateProvider);
      final orderService = _ref.read(driverOrderServiceProvider);

      if (authState.user?.role != UserRole.driver) {
        return DriverResult.error(
          DriverException('Only drivers can update order status', DriverErrorType.permissionDenied),
        );
      }

      // Note: Driver ID validation is handled by the auth check above
      final success = await orderService.updateOrderStatus(orderId, status);

      if (success) {
        debugPrint('Order status updated successfully, realtime subscriptions will update UI automatically');
        return DriverResult.success(true);
      } else {
        return DriverResult.error(
          DriverException('Failed to update order status', DriverErrorType.statusUpdate),
        );
      }
    } catch (e) {
      debugPrint('Error updating order status: $e');
      return DriverResult.fromException(e);
    }
  }
}

/// Helper function to parse order notifications from realtime updates
DriverOrderNotification? _parseOrderNotification(Map<String, dynamic> update) {
  try {
    final type = update['type'] as String?;
    final newRecord = update['new_record'] as Map<String, dynamic>?;
    
    if (type == 'order_status_update' && newRecord != null) {
      return DriverOrderNotification(
        orderId: newRecord['id'] as String,
        orderNumber: newRecord['order_number'] as String,
        status: newRecord['status'] as String,
        message: 'Order ${newRecord['order_number']} status updated to ${newRecord['status']}',
        timestamp: DateTime.now(),
      );
    }
    return null;
  } catch (e) {
    debugPrint('Error parsing order notification: $e');
    return null;
  }
}

/// Helper function to parse driver notifications from realtime updates
DriverNotification? _parseDriverNotification(Map<String, dynamic> update) {
  try {
    final notification = update['notification'] as Map<String, dynamic>?;
    
    if (notification != null) {
      return DriverNotification(
        id: notification['id'] as String,
        title: notification['title'] as String,
        message: notification['message'] as String,
        type: notification['type'] as String,
        timestamp: DateTime.parse(notification['created_at'] as String),
        isRead: notification['is_read'] as bool? ?? false,
      );
    }
    return null;
  } catch (e) {
    debugPrint('Error parsing driver notification: $e');
    return null;
  }
}

/// Realtime-aware provider for individual order details
final realtimeOrderDetailsProvider = StreamProvider.family<DriverOrder?, String>((ref, orderId) async* {
  final repository = ref.read(driverOrderRepositoryProvider);
  final realtimeService = ref.read(driverRealtimeServiceProvider);

  try {
    // Get initial order details
    DriverOrder? currentOrder = await repository.getOrderDetails(orderId);
    yield currentOrder;

    // Listen to realtime updates for this specific order
    await for (final update in realtimeService.orderStatusUpdates) {
      final updatedOrderId = update['new_record']?['id'] as String?;

      // Only refresh if this is the order we're watching
      if (updatedOrderId == orderId) {
        debugPrint('RealtimeOrderDetailsProvider: Order $orderId updated, refreshing details');

        try {
          currentOrder = await repository.getOrderDetails(orderId);
          yield currentOrder;
        } catch (e) {
          debugPrint('RealtimeOrderDetailsProvider: Error refreshing order details: $e');
          // Continue with current order if refresh fails
        }
      }
    }
  } catch (e) {
    debugPrint('RealtimeOrderDetailsProvider: Error: $e');
    throw DriverException.fromException(e);
  }
});

/// Data classes for notifications
class DriverOrderNotification {
  final String orderId;
  final String orderNumber;
  final String status;
  final String message;
  final DateTime timestamp;

  const DriverOrderNotification({
    required this.orderId,
    required this.orderNumber,
    required this.status,
    required this.message,
    required this.timestamp,
  });
}

class DriverNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  final DateTime timestamp;
  final bool isRead;

  const DriverNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    required this.isRead,
  });
}
