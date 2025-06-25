import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../vendors/data/models/driver.dart';
import '../../data/models/driver_dashboard_data.dart';
import '../../data/models/driver_error.dart';
import '../../data/services/driver_dashboard_service.dart';
import 'driver_orders_provider.dart';

/// Provider for driver dashboard service
final driverDashboardServiceProvider = Provider<DriverDashboardService>((ref) {
  return DriverDashboardService();
});

/// Use the cached driver ID provider from realtime providers
/// This eliminates redundant database lookups and improves performance

/// Enhanced provider for driver dashboard data with cached driver ID and error handling
final driverDashboardDataProvider = FutureProvider<DriverDashboardData>((ref) async {
  final authState = ref.read(authStateProvider);
  final dashboardService = ref.read(driverDashboardServiceProvider);

  debugPrint('DriverDashboardProvider: Getting dashboard data');
  debugPrint('DriverDashboardProvider: Auth status: ${authState.status}');
  debugPrint('DriverDashboardProvider: User: ${authState.user?.email}');
  debugPrint('DriverDashboardProvider: User role: ${authState.user?.role}');

  if (authState.user == null) {
    debugPrint('DriverDashboardProvider: User not authenticated');
    throw DriverException('User not authenticated', DriverErrorType.authentication);
  }

  try {
    // Use the cached driver ID provider to avoid redundant lookups
    final driverId = await _getDriverIdFromProvider(ref);
    debugPrint('DriverDashboardProvider: Using cached driver ID: $driverId');

    // Get dashboard data
    final dashboardData = await dashboardService.getDashboardData(driverId);
    debugPrint('DriverDashboardProvider: Dashboard data retrieved successfully');

    return dashboardData;
  } catch (e) {
    debugPrint('DriverDashboardProvider: Error getting dashboard data: $e');

    if (e is DriverException) {
      rethrow;
    }

    // Convert generic errors to DriverException
    throw DriverException.fromException(e);
  }
});

/// Helper function to get driver ID from cached provider
/// Uses the cached provider from realtime_providers to avoid redundant lookups
Future<String> _getDriverIdFromProvider(Ref ref) async {
  // Use the cached driver ID provider from realtime providers
  final driverIdAsync = ref.read(currentDriverIdProvider.future);
  return await driverIdAsync;
}

/// Provider for driver dashboard actions
final driverDashboardActionsProvider = Provider<DriverDashboardActions>((ref) {
  return DriverDashboardActions(ref);
});

/// Driver dashboard actions class
class DriverDashboardActions {
  final Ref _ref;

  DriverDashboardActions(this._ref);

  /// Refresh dashboard data
  Future<void> refreshDashboard() async {
    try {
      debugPrint('DriverDashboardActions: Refreshing dashboard');
      _ref.invalidate(driverDashboardDataProvider);
    } catch (e) {
      debugPrint('DriverDashboardActions: Error refreshing dashboard: $e');
      rethrow;
    }
  }

  /// Update driver status (online/offline) with enhanced error handling
  Future<DriverResult<bool>> updateDriverStatus(DriverStatus status) async {
    try {
      debugPrint('DriverDashboardActions: Updating driver status to: ${status.name}');

      final authState = _ref.read(authStateProvider);
      final dashboardService = _ref.read(driverDashboardServiceProvider);

      if (authState.user == null) {
        debugPrint('DriverDashboardActions: User not authenticated');
        return DriverResult.error(
          DriverException('User not authenticated', DriverErrorType.authentication),
        );
      }

      // Use cached driver ID to avoid redundant lookup
      final driverId = await _getDriverIdFromProvider(_ref);
      debugPrint('DriverDashboardActions: Using cached driver ID: $driverId');

      final success = await dashboardService.updateDriverStatus(driverId, status);

      if (success) {
        // Refresh dashboard data to reflect the change
        _ref.invalidate(driverDashboardDataProvider);
        debugPrint('DriverDashboardActions: Driver status updated successfully');
        return DriverResult.success(true);
      } else {
        return DriverResult.error(
          DriverException('Failed to update driver status', DriverErrorType.unknown),
        );
      }
    } catch (e) {
      debugPrint('DriverDashboardActions: Error updating driver status: $e');
      return DriverResult.fromException(e);
    }
  }
}

/// Provider for driver status toggle state
final driverStatusToggleProvider = StateProvider<bool>((ref) {
  final dashboardDataAsync = ref.watch(driverDashboardDataProvider);

  return dashboardDataAsync.when(
    data: (data) => data.isOnline,
    loading: () => false,
    error: (_, _) => false,
  );
});

/// Provider for active orders count
final activeOrdersCountProvider = Provider<int>((ref) {
  final dashboardDataAsync = ref.watch(driverDashboardDataProvider);

  return dashboardDataAsync.when(
    data: (data) => data.activeOrders.length,
    loading: () => 0,
    error: (_, _) => 0,
  );
});

/// Provider for today's earnings
final todaysEarningsProvider = Provider<double>((ref) {
  final dashboardDataAsync = ref.watch(driverDashboardDataProvider);

  return dashboardDataAsync.when(
    data: (data) => data.todaySummary.earningsToday,
    loading: () => 0.0,
    error: (_, _) => 0.0,
  );
});

/// Provider for today's deliveries count
final todaysDeliveriesProvider = Provider<int>((ref) {
  final dashboardDataAsync = ref.watch(driverDashboardDataProvider);

  return dashboardDataAsync.when(
    data: (data) => data.todaySummary.deliveriesCompleted,
    loading: () => 0,
    error: (_, _) => 0,
  );
});

/// Provider for driver status display
final driverStatusDisplayProvider = Provider<String>((ref) {
  final dashboardDataAsync = ref.watch(driverDashboardDataProvider);

  return dashboardDataAsync.when(
    data: (data) => data.driverStatus.displayName,
    loading: () => 'Loading...',
    error: (_, _) => 'Offline',
  );
});

/// Provider for dashboard loading state
final dashboardLoadingProvider = Provider<bool>((ref) {
  final dashboardDataAsync = ref.watch(driverDashboardDataProvider);

  return dashboardDataAsync.isLoading;
});

/// Provider for dashboard error state with enhanced error handling
final dashboardErrorProvider = Provider<DriverException?>((ref) {
  final dashboardDataAsync = ref.watch(driverDashboardDataProvider);

  return dashboardDataAsync.when(
    data: (_) => null,
    loading: () => null,
    error: (error, _) => error is DriverException
        ? error
        : DriverException.fromException(error),
  );
});

/// Realtime-aware dashboard data provider that updates automatically
final realtimeDashboardDataProvider = StreamProvider<DriverDashboardData>((ref) async* {
  final dashboardService = ref.read(driverDashboardServiceProvider);
  final realtimeService = ref.read(driverRealtimeServiceProvider);

  try {
    // Get initial dashboard data
    final initialData = await ref.read(driverDashboardDataProvider.future);
    yield initialData;

    // Get driver ID for realtime subscriptions
    final driverId = await _getDriverIdFromProvider(ref);

    // Initialize realtime subscriptions for dashboard updates
    await realtimeService.initializeForDriver(driverId);

    // Listen to realtime updates and refresh dashboard data
    await for (final update in realtimeService.orderStatusUpdates) {
      debugPrint('RealtimeDashboardDataProvider: Received update: ${update['type']}');

      try {
        // Refresh dashboard data when realtime update received
        final updatedData = await dashboardService.getDashboardData(driverId);
        yield updatedData;
      } catch (e) {
        debugPrint('RealtimeDashboardDataProvider: Error refreshing dashboard: $e');
        // Continue with current data if refresh fails
      }
    }
  } catch (e) {
    debugPrint('RealtimeDashboardDataProvider: Error: $e');
    throw DriverException.fromException(e);
  }
});

/// Enhanced dashboard actions with realtime integration
final realtimeDashboardActionsProvider = Provider<RealtimeDashboardActions>((ref) {
  return RealtimeDashboardActions(ref);
});

/// Enhanced dashboard actions class with realtime awareness
class RealtimeDashboardActions {
  final Ref _ref;

  RealtimeDashboardActions(this._ref);

  /// Update driver status with realtime updates
  Future<DriverResult<bool>> updateDriverStatus(DriverStatus status) async {
    try {
      debugPrint('RealtimeDashboardActions: Updating driver status to: ${status.name}');

      final authState = _ref.read(authStateProvider);
      final dashboardService = _ref.read(driverDashboardServiceProvider);

      if (authState.user == null) {
        debugPrint('RealtimeDashboardActions: User not authenticated');
        return DriverResult.error(
          DriverException('User not authenticated', DriverErrorType.authentication),
        );
      }

      // Use cached driver ID to avoid redundant lookup
      final driverId = await _getDriverIdFromProvider(_ref);
      debugPrint('RealtimeDashboardActions: Using cached driver ID: $driverId');

      final success = await dashboardService.updateDriverStatus(driverId, status);

      if (success) {
        debugPrint('RealtimeDashboardActions: Driver status updated successfully');
        // No need to manually invalidate - realtime subscriptions will handle updates
        return DriverResult.success(true);
      } else {
        return DriverResult.error(
          DriverException('Failed to update driver status', DriverErrorType.unknown),
        );
      }
    } catch (e) {
      debugPrint('RealtimeDashboardActions: Error updating driver status: $e');
      return DriverResult.fromException(e);
    }
  }

  /// Refresh dashboard data manually
  Future<DriverResult<bool>> refreshDashboard() async {
    try {
      debugPrint('RealtimeDashboardActions: Manually refreshing dashboard');

      // Invalidate providers to force refresh
      _ref.invalidate(driverDashboardDataProvider);
      _ref.invalidate(realtimeDashboardDataProvider);

      return DriverResult.success(true);
    } catch (e) {
      debugPrint('RealtimeDashboardActions: Error refreshing dashboard: $e');
      return DriverResult.fromException(e);
    }
  }
}
