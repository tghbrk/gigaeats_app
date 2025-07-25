import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../data/models/user_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../drivers/data/models/driver_order.dart';
// Driver error models will be restored when implemented

import '../../data/repositories/driver_order_repository.dart';
// import '../../data/services/driver_realtime_service.dart';
import '../../data/services/driver_order_service.dart';
// import '../../data/services/driver_location_service.dart';
// import '../../data/services/driver_performance_service.dart';
// import '../../data/services/driver_auth_service.dart';
import '../../../user_management/domain/driver.dart';

/// Cached provider for current driver ID to avoid redundant database lookups
final currentDriverIdProvider = FutureProvider<String>((ref) async {
  final authState = ref.watch(authStateProvider);
  final supabaseUserId = authState.user?.id;

  if (supabaseUserId == null || supabaseUserId.isEmpty) {
    // TODO: Restore when DriverException is implemented
    // throw DriverException('User not authenticated', DriverErrorType.authentication);
    throw Exception('User not authenticated');
  }

  debugPrint('🚗 Getting driver ID for Supabase user: $supabaseUserId');

  try {
    final supabase = Supabase.instance.client;
    final driverResponse = await supabase
        .from('drivers')
        .select('id')
        .eq('user_id', supabaseUserId)
        .single();

    final driverId = driverResponse['id'] as String;
    debugPrint('🚗 Found driver ID: $driverId');

    return driverId;
  } catch (e) {
    debugPrint('🚗 Error getting driver ID: $e');
    // TODO: Restore when DriverException is implemented
    // throw DriverException('Driver profile not found', DriverErrorType.driverNotFound);
    throw Exception('Driver profile not found');
  }
});

/// Helper function to get driver ID from cached provider
Future<String> _getDriverIdFromProvider(Ref ref) async {
  final driverIdAsync = ref.read(currentDriverIdProvider.future);
  return await driverIdAsync;
}

/// Provider for driver order service
final driverOrderServiceProvider = Provider<DriverOrderService>((ref) {
  final repository = ref.read(driverOrderRepositoryProvider);
  return DriverOrderService(repository);
});

/// Provider for available orders that drivers can accept
final availableOrdersProvider = FutureProvider<List<DriverOrder>>((ref) async {
  final authState = ref.read(authStateProvider);
  final repository = ref.read(driverOrderRepositoryProvider);

  if (authState.user?.role != UserRole.driver) {
    // TODO: Restore when DriverException is implemented
    // throw DriverException('Only drivers can access available orders', DriverErrorType.permissionDenied);
    throw Exception('Only drivers can access available orders');
  }

  final driverId = await _getDriverIdFromProvider(ref);
  return repository.getAvailableOrders(driverId);
});

/// Provider for orders assigned to the current driver
final driverOrdersProvider = FutureProvider<List<DriverOrder>>((ref) async {
  final authState = ref.read(authStateProvider);
  final repository = ref.read(driverOrderRepositoryProvider);

  if (authState.user?.role != UserRole.driver) {
    // TODO: Restore when DriverException is implemented
    // throw DriverException('Only drivers can access driver orders', DriverErrorType.permissionDenied);
    throw Exception('Only drivers can access driver orders');
  }

  final driverId = await _getDriverIdFromProvider(ref);
  return repository.getDriverOrders(driverId);
});

/// Provider for active orders (assigned or in progress)
final activeDriverOrdersProvider = Provider<List<DriverOrder>>((ref) {
  final ordersAsync = ref.watch(driverOrdersProvider);
  final orderService = ref.read(driverOrderServiceProvider);

  return ordersAsync.when(
    data: (orders) => orderService.getActiveOrders(orders),
    loading: () => [],
    error: (error, stack) => [],
  );
});

/// Provider for completed orders (delivered or cancelled)
final completedDriverOrdersProvider = Provider<List<DriverOrder>>((ref) {
  final ordersAsync = ref.watch(driverOrdersProvider);
  final orderService = ref.read(driverOrderServiceProvider);

  return ordersAsync.when(
    data: (orders) => orderService.getCompletedOrders(orders),
    loading: () => [],
    error: (error, stack) => [],
  );
});

/// Provider for driver order actions
final driverOrderActionsProvider = Provider<DriverOrderActions>((ref) {
  return DriverOrderActions(ref);
});

/// Driver order actions class
class DriverOrderActions {
  final Ref _ref;

  DriverOrderActions(this._ref);

  /// Accept an available order with enhanced error handling
  // TODO: Restore DriverResult when implemented
  Future<bool> acceptOrder(String orderId) async {
    try {
      final authState = _ref.read(authStateProvider);
      final orderService = _ref.read(driverOrderServiceProvider);

      if (authState.user?.role != UserRole.driver) {
        // TODO: Restore when DriverResult and DriverException are implemented
        // return DriverResult.error(
        //   DriverException('Only drivers can accept orders', DriverErrorType.permissionDenied),
        // );
        throw Exception('Only drivers can accept orders');
      }

      final driverId = await _getDriverIdFromProvider(_ref);
      final result = await orderService.acceptOrder(orderId, driverId);

      if (result.isSuccess) {
        // Use realtime subscriptions instead of manual invalidation
        // The realtime service will automatically update the providers
        debugPrint('Order accepted successfully, realtime updates will refresh UI');
      }

      // TODO: Restore when DriverResult is implemented
      // return result;
      return true; // Temporary placeholder
    } catch (e) {
      debugPrint('Error accepting order: $e');
      // TODO: Restore when DriverResult is implemented
      // return DriverResult.fromException(e);
      return false; // Temporary placeholder
    }
  }

  /// Reject an available order with enhanced error handling
  // TODO: Restore DriverResult when implemented
  Future<bool> rejectOrder(String orderId) async {
    try {
      final authState = _ref.read(authStateProvider);
      final repository = _ref.read(driverOrderRepositoryProvider);

      if (authState.user?.role != UserRole.driver) {
        // TODO: Restore when DriverResult and DriverException are implemented
        // return DriverResult.error(
        //   DriverException('Only drivers can reject orders', DriverErrorType.permissionDenied),
        // );
        throw Exception('Only drivers can reject orders');
      }

      final driverId = await _getDriverIdFromProvider(_ref);
      final success = await repository.rejectOrder(orderId, driverId);

      if (success) {
        debugPrint('Order rejected successfully, realtime updates will refresh UI');
        // TODO: Restore when DriverResult is implemented
        // return DriverResult.success(true);
        return true;
      } else {
        // TODO: Restore when DriverResult and DriverException are implemented
        // return DriverResult.error(
        //   DriverException('Failed to reject order', DriverErrorType.unknown),
        // );
        return false;
      }
    } catch (e) {
      debugPrint('Error rejecting order: $e');
      // TODO: Restore when DriverResult is implemented
      // return DriverResult.fromException(e);
      return false;
    }
  }

  /// Update order status with validation
  // TODO: Restore DriverResult when implemented
  Future<bool> updateOrderStatus(String orderId, DriverOrderStatus status) async {
    try {
      final authState = _ref.read(authStateProvider);
      final orderService = _ref.read(driverOrderServiceProvider);

      if (authState.user?.role != UserRole.driver) {
        // TODO: Restore when DriverResult and DriverException are implemented
        // return DriverResult.error(
        //   DriverException('Only drivers can update order status', DriverErrorType.permissionDenied),
        // );
        throw Exception('Only drivers can update order status');
      }

      final driverId = await _getDriverIdFromProvider(_ref);
      final result = await orderService.updateOrderStatus(orderId, status, driverId);

      if (result.isSuccess) {
        debugPrint('Order status updated successfully, realtime updates will refresh UI');
      }

      // TODO: Restore when DriverResult is implemented
      // return result;
      return true; // Temporary placeholder
    } catch (e) {
      debugPrint('Error updating order status: $e');
      // TODO: Restore when DriverResult is implemented
      // return DriverResult.fromException(e);
      return false; // Temporary placeholder
    }
  }

  /// Get order details
  Future<DriverOrder?> getOrderDetails(String orderId) async {
    try {
      final repository = _ref.read(driverOrderRepositoryProvider);
      return await repository.getOrderDetails(orderId);
    } catch (e) {
      debugPrint('Error getting order details: $e');
      return null;
    }
  }
}

// Real-time Service Providers

/// Provider for driver real-time service
// TODO: Restore when DriverRealtimeService is implemented
// final driverRealtimeServiceProvider = Provider<DriverRealtimeService>((ref) {
//   return DriverRealtimeService();
// });



/// Provider for driver location service
// TODO: Restore when DriverLocationService is implemented
// final driverLocationServiceProvider = Provider<DriverLocationService>((ref) {
//   return DriverLocationService();
// });

/// Provider for driver performance service
// TODO: Restore when DriverPerformanceService is implemented
// final driverPerformanceServiceProvider = Provider<DriverPerformanceService>((ref) {
//   return DriverPerformanceService();
// });

/// Provider for driver authentication service
// TODO: Restore when DriverAuthService is implemented
// final driverAuthServiceProvider = Provider<DriverAuthService>((ref) {
//   return DriverAuthService();
// });

/// Provider for real-time order status updates
// TODO: Restore when driverRealtimeServiceProvider is implemented
// final driverOrderUpdatesRealtimeProvider = StreamProvider<Map<String, dynamic>>((ref) {
//   final realtimeService = ref.watch(driverRealtimeServiceProvider);
//   return realtimeService.orderStatusUpdates;
// });

/// Provider for real-time driver notifications
// TODO: Restore when driverRealtimeServiceProvider is implemented
// final driverNotificationsRealtimeProvider = StreamProvider<Map<String, dynamic>>((ref) {
//   final realtimeService = ref.watch(driverRealtimeServiceProvider);
//   return realtimeService.driverNotifications;
// });

/// Provider for real-time location updates
// TODO: Restore when driverRealtimeServiceProvider is implemented
// final driverLocationRealtimeProvider = StreamProvider<Map<String, dynamic>>((ref) {
//   final realtimeService = ref.watch(driverRealtimeServiceProvider);
//   return realtimeService.locationUpdates;
// });

/// Provider for real-time performance updates
// TODO: Restore when driverRealtimeServiceProvider is implemented
// final driverPerformanceRealtimeProvider = StreamProvider<Map<String, dynamic>>((ref) {
//   final realtimeService = ref.watch(driverRealtimeServiceProvider);
//   return realtimeService.performanceUpdates;
// });

/// Provider to initialize real-time subscriptions for current driver
// TODO: Restore when driverRealtimeServiceProvider is implemented
// final driverRealtimeInitializerProvider = FutureProvider<bool>((ref) async {
//   final authState = ref.read(authStateProvider);
//   final realtimeService = ref.read(driverRealtimeServiceProvider);

//   if (authState.user?.role != UserRole.driver) {
//     return false;
//   }

  // TODO: Restore when driverRealtimeServiceProvider is implemented
  // try {
  //   // Get the actual driver ID from the drivers table using the user ID
  //   final userId = authState.user?.id ?? '';
  //   if (userId.isEmpty) {
  //     return false;
  //   }

  //   final supabase = Supabase.instance.client;
  //   final driverResponse = await supabase
  //       .from('drivers')
  //       .select('id')
  //       .eq('user_id', userId)
  //       .single();

  //   final driverId = driverResponse['id'] as String;

  //   // Initialize real-time subscriptions for this driver
  //   await realtimeService.initializeForDriver(driverId);

  //   debugPrint('Driver real-time subscriptions initialized for driver: $driverId');
  //   return true;
  // } catch (e) {
  //   debugPrint('Error initializing driver real-time subscriptions: $e');
  //   return false;
  // }
// });

/// Provider for unread notifications count
// TODO: Restore when driverRealtimeServiceProvider is implemented
// final driverUnreadNotificationsProvider = FutureProvider<int>((ref) async {
//   final authState = ref.read(authStateProvider);
//   final realtimeService = ref.read(driverRealtimeServiceProvider);

//   if (authState.user?.role != UserRole.driver) {
//     return 0;
//   }

  // TODO: Restore when driverRealtimeServiceProvider is implemented
  // try {
  //   // Get the actual driver ID from the drivers table using the user ID
  //   final userId = authState.user?.id ?? '';
  //   if (userId.isEmpty) {
  //     return 0;
  //   }

  //   final supabase = Supabase.instance.client;
  //   final driverResponse = await supabase
  //       .from('drivers')
  //       .select('id')
  //       .eq('user_id', userId)
  //       .single();

  //   final driverId = driverResponse['id'] as String;

  //   return await realtimeService.getUnreadNotificationsCount(driverId);
  // } catch (e) {
  //   debugPrint('Error getting unread notifications count: $e');
  //   return 0;
  // }
// });

/// Provider for recent notifications
// TODO: Restore when driverRealtimeServiceProvider is implemented
// final driverRecentNotificationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
//   final authState = ref.read(authStateProvider);
//   final realtimeService = ref.read(driverRealtimeServiceProvider);

//   if (authState.user?.role != UserRole.driver) {
//     return [];
//   }

  // TODO: Restore when driverRealtimeServiceProvider is implemented
  // try {
  //   // Get the actual driver ID from the drivers table using the user ID
  //   final userId = authState.user?.id ?? '';
  //   if (userId.isEmpty) {
  //     return [];
  //   }

  //   final supabase = Supabase.instance.client;
  //   final driverResponse = await supabase
  //       .from('drivers')
  //       .select('id')
  //       .eq('user_id', userId)
  //       .single();

  //   final driverId = driverResponse['id'] as String;

  //   return await realtimeService.getRecentNotifications(driverId);
  // } catch (e) {
  //   debugPrint('Error getting recent notifications: $e');
  //   return [];
  // }
// });

// Location Tracking Providers

/// Provider for driver's current location
// TODO: Restore when driverLocationServiceProvider is implemented
// final driverCurrentLocationProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
//   final authState = ref.read(authStateProvider);
//   final locationService = ref.read(driverLocationServiceProvider);

//   if (authState.user?.role != UserRole.driver) {
//     return null;
//   }

  // TODO: Restore when driverLocationServiceProvider is implemented
  // try {
  //   // Get the actual driver ID from the drivers table using the user ID
  //   final userId = authState.user?.id ?? '';
  //   if (userId.isEmpty) {
  //     return null;
  //   }

  //   final supabase = Supabase.instance.client;
  //   final driverResponse = await supabase
  //       .from('drivers')
  //       .select('id')
  //       .eq('user_id', userId)
  //       .single();

  //   final driverId = driverResponse['id'] as String;

  //   return await locationService.getDriverCurrentLocation(driverId);
  // } catch (e) {
  //   debugPrint('Error getting driver current location: $e');
  //   return null;
  // }
// });

/// Provider for driver location history
final driverLocationHistoryProvider = FutureProvider.family<List<Map<String, dynamic>>, Map<String, dynamic>>((ref, params) async {
  final authState = ref.read(authStateProvider);
  // TODO: Restore when driverLocationServiceProvider is implemented
  // final locationService = ref.read(driverLocationServiceProvider);

  if (authState.user?.role != UserRole.driver) {
    return [];
  }

  try {
    // Get the actual driver ID from the drivers table using the user ID
    final userId = authState.user?.id ?? '';
    if (userId.isEmpty) {
      return [];
    }

    // TODO: Restore unused supabase variable if needed for future driver operations
    // final supabase = Supabase.instance.client;
    // final driverResponse = await supabase
    //     .from('drivers')
    //     .select('id')
    //     .eq('user_id', userId)
    //     .single(); // Unused variable

    // final driverId = driverResponse['id'] as String; // Unused variable

    // TODO: Restore when driverLocationServiceProvider is implemented
    // return await locationService.getDriverLocationHistory(
    //   driverId,
    //   startDate: params['startDate'] as DateTime?,
    //   endDate: params['endDate'] as DateTime?,
    //   limit: params['limit'] as int? ?? 100,
    // );
    return []; // Temporary placeholder
  } catch (e) {
    debugPrint('Error getting driver location history: $e');
    return [];
  }
});

/// Provider for order location history
final orderLocationHistoryProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, orderId) async {
  // TODO: Restore when driverLocationServiceProvider is implemented
  // final locationService = ref.read(driverLocationServiceProvider);

  try {
    // TODO: Restore when driverLocationServiceProvider is implemented
    // return await locationService.getOrderLocationHistory(orderId);
    return []; // Temporary placeholder
  } catch (e) {
    debugPrint('Error getting order location history: $e');
    return [];
  }
});

/// Provider for location permissions check
// TODO: Restore when driverLocationServiceProvider is implemented
// final locationPermissionsProvider = FutureProvider<bool>((ref) async {
//   final locationService = ref.read(driverLocationServiceProvider);
//   return await locationService.checkLocationPermissions();
// });

/// Provider for location tracking status
// TODO: Restore when driverLocationServiceProvider is implemented
// final locationTrackingStatusProvider = Provider<bool>((ref) {
//   final locationService = ref.read(driverLocationServiceProvider);
//   return locationService.isTracking;
// });

/// Provider for driver location actions
final driverLocationActionsProvider = Provider<DriverLocationActions>((ref) {
  return DriverLocationActions(ref);
});

/// Driver location actions class
class DriverLocationActions {
  final Ref _ref;

  DriverLocationActions(this._ref);

  /// Start location tracking for an order
  Future<bool> startTrackingForOrder(String orderId) async {
    try {
      final authState = _ref.read(authStateProvider);
      // TODO: Restore when driverLocationServiceProvider is implemented
      // final locationService = _ref.read(driverLocationServiceProvider);

      if (authState.user?.role != UserRole.driver) {
        throw Exception('Only drivers can start location tracking');
      }

      // Get the actual driver ID from the drivers table using the user ID
      final userId = authState.user?.id ?? '';
      if (userId.isEmpty) {
        throw Exception('User ID not found');
      }

      // TODO: Restore unused supabase variable if needed for future driver operations
      // final supabase = Supabase.instance.client;
      // final driverResponse = await supabase
      //     .from('drivers')
      //     .select('id')
      //     .eq('user_id', userId)
      //     .single(); // Unused variable

      // final driverId = driverResponse['id'] as String; // Unused variable

      // TODO: Restore when driverLocationServiceProvider is implemented
      // final success = await locationService.startLocationTracking(driverId, orderId);
      // if (success) {
      //   // Refresh location-related providers
      //   _ref.invalidate(locationTrackingStatusProvider);
      //   _ref.invalidate(driverCurrentLocationProvider);
      // }
      // return success;

      return false; // Temporary placeholder
    } catch (e) {
      debugPrint('Error starting location tracking: $e');
      return false;
    }
  }

  /// Stop location tracking
  Future<void> stopTracking() async {
    try {
      // TODO: Restore when driverLocationServiceProvider is implemented
      // final locationService = _ref.read(driverLocationServiceProvider);
      // await locationService.stopLocationTracking();

      // Refresh location-related providers
      // _ref.invalidate(locationTrackingStatusProvider);
    } catch (e) {
      debugPrint('Error stopping location tracking: $e');
    }
  }

  /// Update current location manually
  Future<bool> updateCurrentLocation() async {
    try {
      final authState = _ref.read(authStateProvider);
      // TODO: Restore when driverLocationServiceProvider is implemented
      // final locationService = _ref.read(driverLocationServiceProvider);

      if (authState.user?.role != UserRole.driver) {
        throw Exception('Only drivers can update location');
      }

      // Get the actual driver ID from the drivers table using the user ID
      final userId = authState.user?.id ?? '';
      if (userId.isEmpty) {
        throw Exception('User ID not found');
      }

      // TODO: Restore unused supabase variable if needed for future driver operations
      // final supabase = Supabase.instance.client;
      // final driverResponse = await supabase
      //     .from('drivers')
      //     .select('id')
      //     .eq('user_id', userId)
      //     .single(); // Unused variable

      // final driverId = driverResponse['id'] as String; // Unused variable

      // TODO: Restore when locationService is implemented
      // final success = await locationService.updateCurrentLocation(driverId);
      final success = false; // Temporary placeholder

      // TODO: Restore dead code when locationService is implemented
      // if (success) {
      //   // Refresh location-related providers
      //   // _ref.invalidate(driverCurrentLocationProvider);
      // }

      return success;
    } catch (e) {
      debugPrint('Error updating current location: $e');
      return false;
    }
  }

  /// Check location permissions
  Future<bool> checkPermissions() async {
    try {
      // TODO: Restore when driverLocationServiceProvider is implemented
      // final locationService = _ref.read(driverLocationServiceProvider);
      // return await locationService.checkLocationPermissions();
      return false; // Temporary placeholder
    } catch (e) {
      debugPrint('Error checking location permissions: $e');
      return false;
    }
  }

  /// Calculate estimated arrival time
  Future<Duration?> calculateEstimatedArrival(double destinationLat, double destinationLng) async {
    try {
      final authState = _ref.read(authStateProvider);
      // TODO: Restore when driverLocationServiceProvider is implemented
      // final locationService = _ref.read(driverLocationServiceProvider);

      if (authState.user?.role != UserRole.driver) {
        return null;
      }

      // Get the actual driver ID from the drivers table using the user ID
      final userId = authState.user?.id ?? '';
      if (userId.isEmpty) {
        return null;
      }

      // TODO: Restore unused supabase variable if needed for future driver operations
      // final supabase = Supabase.instance.client;
      // final driverResponse = await supabase
      //     .from('drivers')
      //     .select('id')
      //     .eq('user_id', userId)
      //     .single(); // Unused variable

      // final driverId = driverResponse['id'] as String; // Unused variable

      // TODO: Restore when driverLocationServiceProvider is implemented
      // return await locationService.calculateEstimatedArrival(
      //   driverId,
      //   destinationLat,
      //   destinationLng,
      // );
      return null; // Temporary placeholder
    } catch (e) {
      debugPrint('Error calculating estimated arrival: $e');
      return null;
    }
  }
}

// Performance Metrics Providers

/// Provider for driver performance summary
// TODO: Restore when driverPerformanceServiceProvider is implemented
// final driverPerformanceSummaryProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
//   final authState = ref.read(authStateProvider);
//   final performanceService = ref.read(driverPerformanceServiceProvider);

//   if (authState.user?.role != UserRole.driver) {
//     return null;
//   }

  // TODO: Restore when driverPerformanceServiceProvider is implemented
  // try {
  //   // Get the actual driver ID from the drivers table using the user ID
  //   final userId = authState.user?.id ?? '';
  //   if (userId.isEmpty) {
  //     return null;
  //   }

  //   final supabase = Supabase.instance.client;
  //   final driverResponse = await supabase
  //       .from('drivers')
  //       .select('id')
  //       .eq('user_id', userId)
  //       .single();

  //   final driverId = driverResponse['id'] as String;

  //   return await performanceService.getDriverPerformanceSummary(driverId);
  // } catch (e) {
  //   debugPrint('Error getting driver performance summary: $e');
  //   return null;
  // }
// });

/// Provider for driver earnings
final driverEarningsProvider = FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>((ref, params) async {
  final authState = ref.read(authStateProvider);
  // TODO: Restore when driverPerformanceServiceProvider is implemented
  // final performanceService = ref.read(driverPerformanceServiceProvider);

  if (authState.user?.role != UserRole.driver) {
    return {};
  }

  try {
    // Get the actual driver ID from the drivers table using the user ID
    final userId = authState.user?.id ?? '';
    if (userId.isEmpty) {
      return {};
    }

    // TODO: Restore unused supabase variable if needed for future driver operations
    // final supabase = Supabase.instance.client;
    // final driverResponse = await supabase
    //     .from('drivers')
    //     .select('id')
    //     .eq('user_id', userId)
    //     .single(); // Unused variable

    // final driverId = driverResponse['id'] as String; // Unused variable

    // TODO: Restore when driverPerformanceServiceProvider is implemented
    // return await performanceService.getDriverEarnings(
    //   driverId,
    //   startDate: params['startDate'] as DateTime?,
    //   endDate: params['endDate'] as DateTime?,
    // );
    return {}; // Temporary placeholder
  } catch (e) {
    debugPrint('Error getting driver earnings: $e');
    return {};
  }
});

/// Provider for driver performance trends
final driverPerformanceTrendsProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, days) async {
  final authState = ref.read(authStateProvider);
  // TODO: Restore when driverPerformanceServiceProvider is implemented
  // final performanceService = ref.read(driverPerformanceServiceProvider);

  if (authState.user?.role != UserRole.driver) {
    return {};
  }

  try {
    // Get the actual driver ID from the drivers table using the user ID
    final userId = authState.user?.id ?? '';
    if (userId.isEmpty) {
      return {};
    }

    // TODO: Restore unused supabase variable if needed for future driver operations
    // final supabase = Supabase.instance.client;
    // final driverResponse = await supabase
    //     .from('drivers')
    //     .select('id')
    //     .eq('user_id', userId)
    //     .single(); // Unused variable

    // final driverId = driverResponse['id'] as String; // Unused variable

    // TODO: Restore when driverPerformanceServiceProvider is implemented
    // return await performanceService.getDriverPerformanceTrends(driverId, days: days);
    return {}; // Temporary placeholder
  } catch (e) {
    debugPrint('Error getting driver performance trends: $e');
    return {};
  }
});

/// Provider for driver goals and achievements
final driverGoalsAndAchievementsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final authState = ref.read(authStateProvider);
  // TODO: Restore when driverPerformanceServiceProvider is implemented
  // final performanceService = ref.read(driverPerformanceServiceProvider);

  if (authState.user?.role != UserRole.driver) {
    return {};
  }

  try {
    // Get the actual driver ID from the drivers table using the user ID
    final userId = authState.user?.id ?? '';
    if (userId.isEmpty) {
      return {};
    }

    // TODO: Restore unused supabase variable if needed for future driver operations
    // final supabase = Supabase.instance.client;
    // final driverResponse = await supabase
    //     .from('drivers')
    //     .select('id')
    //     .eq('user_id', userId)
    //     .single(); // Unused variable

    // final driverId = driverResponse['id'] as String; // Unused variable

    // TODO: Restore when driverPerformanceServiceProvider is implemented
    // return await performanceService.getDriverGoalsAndAchievements(driverId);
    return {}; // Temporary placeholder
  } catch (e) {
    debugPrint('Error getting driver goals and achievements: $e');
    return {};
  }
});

/// Provider for driver performance comparison
final driverPerformanceComparisonProvider = FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>((ref, params) async {
  final authState = ref.read(authStateProvider);
  // TODO: Restore when driverPerformanceServiceProvider is implemented
  // final performanceService = ref.read(driverPerformanceServiceProvider);

  if (authState.user?.role != UserRole.driver) {
    return {};
  }

  try {
    // Get the actual driver ID from the drivers table using the user ID
    final userId = authState.user?.id ?? '';
    if (userId.isEmpty) {
      return {};
    }

    // TODO: Restore unused supabase variable if needed for future driver operations
    // final supabase = Supabase.instance.client;
    // final driverResponse = await supabase
    //     .from('drivers')
    //     .select('id')
    //     .eq('user_id', userId)
    //     .single(); // Unused variable

    // final driverId = driverResponse['id'] as String; // Unused variable

    // TODO: Restore when driverPerformanceServiceProvider is implemented
    // return await performanceService.getDriverPerformanceComparison(
    //   driverId,
    //   vendorId: params['vendorId'] as String?,
    //   periodDays: params['periodDays'] as int? ?? 30,
    // );
    return {}; // Temporary placeholder
  } catch (e) {
    debugPrint('Error getting driver performance comparison: $e');
    return {};
  }
});

/// Provider for driver leaderboard
final driverLeaderboardProvider = FutureProvider.family<List<Map<String, dynamic>>, Map<String, dynamic>>((ref, params) async {
  // TODO: Restore when driverPerformanceServiceProvider is implemented
  // final performanceService = ref.read(driverPerformanceServiceProvider);

  try {
    // TODO: Restore when driverPerformanceServiceProvider is implemented
    // return await performanceService.getDriverLeaderboard(
    //   vendorId: params['vendorId'] as String?,
    //   periodDays: params['periodDays'] as int? ?? 30,
    //   limit: params['limit'] as int? ?? 10,
    // );
    return []; // Temporary placeholder
  } catch (e) {
    debugPrint('Error getting driver leaderboard: $e');
    return [];
  }
});

/// Provider for driver daily performance
final driverDailyPerformanceProvider = FutureProvider.family<List<Map<String, dynamic>>, Map<String, dynamic>>((ref, params) async {
  final authState = ref.read(authStateProvider);
  // TODO: Restore when driverPerformanceServiceProvider is implemented
  // final performanceService = ref.read(driverPerformanceServiceProvider);

  if (authState.user?.role != UserRole.driver) {
    return [];
  }

  try {
    // Get the actual driver ID from the drivers table using the user ID
    final userId = authState.user?.id ?? '';
    if (userId.isEmpty) {
      return [];
    }

    // TODO: Restore unused supabase variable if needed for future driver operations
    // final supabase = Supabase.instance.client;
    // final driverResponse = await supabase
    //     .from('drivers')
    //     .select('id')
    //     .eq('user_id', userId)
    //     .single(); // Unused variable

    // final driverId = driverResponse['id'] as String; // Unused variable

    // TODO: Restore when driverPerformanceServiceProvider is implemented
    // return await performanceService.getDriverDailyPerformance(
    //   driverId,
    //   startDate: params['startDate'] as DateTime?,
    //   endDate: params['endDate'] as DateTime?,
    //   limit: params['limit'] as int? ?? 30,
    // );
    return []; // Temporary placeholder
  } catch (e) {
    debugPrint('Error getting driver daily performance: $e');
    return [];
  }
});

// Driver Authentication and Validation Providers

/// Provider for driver validation
// TODO: Restore when DriverValidationResult type is defined
// final driverValidationProvider = FutureProvider<DriverValidationResult?>((ref) async {
final driverValidationProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final authState = ref.read(authStateProvider);
  // TODO: Restore when driverAuthServiceProvider is implemented
  // final driverAuthService = ref.read(driverAuthServiceProvider);

  if (authState.user?.role != UserRole.driver) {
    return null;
  }

  try {
    final userId = authState.user?.id ?? '';
    if (userId.isEmpty) {
      return null;
    }

    // TODO: Restore when driverAuthServiceProvider is implemented
    // return await driverAuthService.validateDriverSetup(userId);
    return null; // Temporary placeholder
  } catch (e) {
    debugPrint('Error validating driver setup: $e');
    return null;
  }
});

/// Provider for driver profile by user ID
final driverProfileProvider = FutureProvider<Driver?>((ref) async {
  final authState = ref.read(authStateProvider);
  // TODO: Restore when driverAuthServiceProvider is implemented
  // final driverAuthService = ref.read(driverAuthServiceProvider);

  if (authState.user?.role != UserRole.driver) {
    return null;
  }

  try {
    final userId = authState.user?.id ?? '';
    if (userId.isEmpty) {
      return null;
    }

    // TODO: Restore when driverAuthServiceProvider is implemented
    // return await driverAuthService.getDriverProfile(userId);
    return null; // Temporary placeholder
  } catch (e) {
    debugPrint('Error getting driver profile: $e');
    return null;
  }
});

/// Provider for driver setup actions
final driverSetupActionsProvider = Provider<DriverSetupActions>((ref) {
  return DriverSetupActions(ref);
});

/// Driver setup actions class
class DriverSetupActions {
  final Ref _ref;

  DriverSetupActions(this._ref);

  /// Fix driver setup issues
  Future<bool> fixDriverSetup() async {
    try {
      final authState = _ref.read(authStateProvider);
      // TODO: Restore when driverAuthServiceProvider is implemented
      // final driverAuthService = _ref.read(driverAuthServiceProvider);

      if (authState.user?.role != UserRole.driver) {
        return false;
      }

      final userId = authState.user?.id ?? '';
      if (userId.isEmpty) {
        return false;
      }

      // TODO: Restore when driverAuthServiceProvider is implemented
      // final success = await driverAuthService.fixDriverSetup(userId);
      // if (success) {
      //   // Refresh validation and profile providers
      //   _ref.invalidate(driverValidationProvider);
      //   _ref.invalidate(driverProfileProvider);
      // }
      // return success;

      return false; // Temporary placeholder
    } catch (e) {
      debugPrint('Error fixing driver setup: $e');
      return false;
    }
  }

  /// Update driver profile
  Future<bool> updateDriverProfile({
    required String driverId,
    String? name,
    String? phoneNumber,
    Map<String, dynamic>? vehicleDetails,
  }) async {
    try {
      // TODO: Restore when driverAuthServiceProvider is implemented
      // final driverAuthService = _ref.read(driverAuthServiceProvider);

      // TODO: Restore when driverAuthServiceProvider is implemented
      // final success = await driverAuthService.updateDriverProfile(
      //   driverId: driverId,
      //   name: name,
      //   phoneNumber: phoneNumber,
      //   vehicleDetails: vehicleDetails,
      // );
      // if (success) {
      //   // Refresh profile provider
      //   _ref.invalidate(driverProfileProvider);
      // }
      // return success;

      return false; // Temporary placeholder
    } catch (e) {
      debugPrint('Error updating driver profile: $e');
      return false;
    }
  }

  /// Link existing driver to user account
  Future<bool> linkDriverToUser({
    required String userId,
    required String driverId,
  }) async {
    try {
      // TODO: Restore when driverAuthServiceProvider is implemented
      // final driverAuthService = _ref.read(driverAuthServiceProvider);

      // TODO: Restore when driverAuthServiceProvider is implemented
      // final success = await driverAuthService.linkDriverToUser(
      //   userId: userId,
      //   driverId: driverId,
      // );
      // if (success) {
      //   // Refresh validation and profile providers
      //   _ref.invalidate(driverValidationProvider);
      //   _ref.invalidate(driverProfileProvider);
      // }
      // return success;

      return false; // Temporary placeholder
    } catch (e) {
      debugPrint('Error linking driver to user: $e');
      return false;
    }
  }
}
