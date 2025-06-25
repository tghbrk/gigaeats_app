import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/models/driver_order.dart';
import '../../data/services/driver_proximity_service.dart';
import '../../data/services/driver_location_service.dart';
import '../../data/services/geocoding_service.dart';
import '../../data/services/adaptive_location_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../data/models/user_role.dart';
import 'driver_orders_provider.dart';

/// Provider for geocoding service
final geocodingServiceProvider = Provider<GeocodingService>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  return GeocodingService(prefs: prefs);
});

/// Provider for the driver proximity service
final driverProximityServiceProvider = Provider<DriverProximityService>((ref) {
  final geocodingService = ref.read(geocodingServiceProvider);
  final adaptiveLocationService = ref.read(adaptiveLocationServiceProvider);
  return DriverProximityService(
    geocodingService: geocodingService,
    adaptiveLocationService: adaptiveLocationService,
  );
});

/// Provider for driver location service
final driverLocationServiceProvider = Provider<DriverLocationService>((ref) {
  return DriverLocationService();
});

/// Provider for adaptive location service
final adaptiveLocationServiceProvider = Provider<AdaptiveLocationService>((ref) {
  return AdaptiveLocationService();
});

/// State class for proximity monitoring
@immutable
class ProximityMonitoringState {
  final bool isMonitoring;
  final String? currentOrderId;
  final String? currentDriverId;
  final Position? lastKnownPosition;
  final DateTime? lastUpdate;
  final String? error;

  const ProximityMonitoringState({
    this.isMonitoring = false,
    this.currentOrderId,
    this.currentDriverId,
    this.lastKnownPosition,
    this.lastUpdate,
    this.error,
  });

  ProximityMonitoringState copyWith({
    bool? isMonitoring,
    String? currentOrderId,
    String? currentDriverId,
    Position? lastKnownPosition,
    DateTime? lastUpdate,
    String? error,
  }) {
    return ProximityMonitoringState(
      isMonitoring: isMonitoring ?? this.isMonitoring,
      currentOrderId: currentOrderId ?? this.currentOrderId,
      currentDriverId: currentDriverId ?? this.currentDriverId,
      lastKnownPosition: lastKnownPosition ?? this.lastKnownPosition,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      error: error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProximityMonitoringState &&
        other.isMonitoring == isMonitoring &&
        other.currentOrderId == currentOrderId &&
        other.currentDriverId == currentDriverId &&
        other.lastKnownPosition == lastKnownPosition &&
        other.lastUpdate == lastUpdate &&
        other.error == error;
  }

  @override
  int get hashCode {
    return Object.hash(
      isMonitoring,
      currentOrderId,
      currentDriverId,
      lastKnownPosition,
      lastUpdate,
      error,
    );
  }
}

/// Notifier for managing proximity monitoring state
class ProximityMonitoringNotifier extends StateNotifier<ProximityMonitoringState> {
  final DriverProximityService _proximityService;
  final Ref _ref;

  ProximityMonitoringNotifier(this._proximityService, this._ref)
      : super(const ProximityMonitoringState());

  /// Start proximity monitoring for an order
  Future<bool> startMonitoring(String driverId, String orderId) async {
    try {
      debugPrint('ProximityMonitoringNotifier: Starting monitoring for order: $orderId');
      
      state = state.copyWith(
        isMonitoring: true,
        currentOrderId: orderId,
        currentDriverId: driverId,
        error: null,
      );

      final success = await _proximityService.startProximityMonitoring(driverId, orderId);
      
      if (!success) {
        state = state.copyWith(
          isMonitoring: false,
          error: 'Failed to start proximity monitoring',
        );
        return false;
      }

      // Start location tracking as well
      final locationService = _ref.read(driverLocationServiceProvider);
      await locationService.startLocationTracking(driverId, orderId);

      state = state.copyWith(lastUpdate: DateTime.now());
      
      debugPrint('ProximityMonitoringNotifier: Monitoring started successfully');
      return true;
    } catch (e) {
      debugPrint('ProximityMonitoringNotifier: Error starting monitoring: $e');
      state = state.copyWith(
        isMonitoring: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Stop proximity monitoring
  Future<void> stopMonitoring() async {
    try {
      debugPrint('ProximityMonitoringNotifier: Stopping monitoring');
      
      await _proximityService.stopProximityMonitoring();
      
      // Stop location tracking as well
      final locationService = _ref.read(driverLocationServiceProvider);
      await locationService.stopLocationTracking();

      state = const ProximityMonitoringState();
      
      debugPrint('ProximityMonitoringNotifier: Monitoring stopped');
    } catch (e) {
      debugPrint('ProximityMonitoringNotifier: Error stopping monitoring: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Update last known position
  void updatePosition(Position position) {
    state = state.copyWith(
      lastKnownPosition: position,
      lastUpdate: DateTime.now(),
    );
  }

  /// Set error state
  void setError(String error) {
    state = state.copyWith(error: error);
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for proximity monitoring state
final proximityMonitoringProvider = StateNotifierProvider<ProximityMonitoringNotifier, ProximityMonitoringState>((ref) {
  final proximityService = ref.read(driverProximityServiceProvider);
  return ProximityMonitoringNotifier(proximityService, ref);
});

/// Provider to automatically start/stop monitoring based on active orders
final autoProximityMonitoringProvider = Provider<void>((ref) {
  final authState = ref.watch(authStateProvider);
  final activeOrders = ref.watch(activeDriverOrdersProvider);
  final proximityNotifier = ref.read(proximityMonitoringProvider.notifier);
  final proximityState = ref.watch(proximityMonitoringProvider);

  // Only monitor if user is a driver and authenticated
  if (authState.user?.role != UserRole.driver || authState.user?.id == null) {
    if (proximityState.isMonitoring) {
      proximityNotifier.stopMonitoring();
    }
    return;
  }

  // activeDriverOrdersProvider returns a List<DriverOrder> directly
  if (activeOrders.isNotEmpty) {
    final activeOrder = activeOrders.first;

    // Check if we need to start monitoring for this order
    if (!proximityState.isMonitoring ||
        proximityState.currentOrderId != activeOrder.id) {

      // Only start monitoring for statuses that need GPS tracking
      if (activeOrder.status == DriverOrderStatus.onRouteToVendor ||
          activeOrder.status == DriverOrderStatus.onRouteToCustomer) {

        proximityNotifier.startMonitoring(
          authState.user!.id, // This would need to be mapped to driver ID
          activeOrder.id,
        );
      }
    }
  } else {
    // No active orders, stop monitoring
    if (proximityState.isMonitoring) {
      proximityNotifier.stopMonitoring();
    }
  }
});

/// Provider for checking if driver is near vendor
final isNearVendorProvider = FutureProvider.family<bool, String>((ref, orderId) async {
  final proximityService = ref.read(driverProximityServiceProvider);
  final proximityState = ref.watch(proximityMonitoringProvider);
  
  if (proximityState.lastKnownPosition == null) {
    return false;
  }
  
  return await proximityService.checkArrivalAtVendor(
    orderId,
    proximityState.lastKnownPosition!,
  );
});

/// Provider for checking if driver is near customer
final isNearCustomerProvider = FutureProvider.family<bool, String>((ref, orderId) async {
  final proximityService = ref.read(driverProximityServiceProvider);
  final proximityState = ref.watch(proximityMonitoringProvider);
  
  if (proximityState.lastKnownPosition == null) {
    return false;
  }
  
  return await proximityService.checkArrivalAtCustomer(
    orderId,
    proximityState.lastKnownPosition!,
  );
});

/// Provider for proximity monitoring debug info
final proximityDebugInfoProvider = Provider<Map<String, dynamic>>((ref) {
  final proximityState = ref.watch(proximityMonitoringProvider);
  final proximityService = ref.read(driverProximityServiceProvider);
  
  return {
    'isMonitoring': proximityState.isMonitoring,
    'currentOrderId': proximityState.currentOrderId,
    'currentDriverId': proximityState.currentDriverId,
    'lastUpdate': proximityState.lastUpdate?.toIso8601String(),
    'lastPosition': proximityState.lastKnownPosition != null
        ? {
            'latitude': proximityState.lastKnownPosition!.latitude,
            'longitude': proximityState.lastKnownPosition!.longitude,
            'accuracy': proximityState.lastKnownPosition!.accuracy,
          }
        : null,
    'error': proximityState.error,
    'serviceMonitoring': proximityService.isMonitoring,
    'serviceOrderId': proximityService.currentOrderId,
  };
});
