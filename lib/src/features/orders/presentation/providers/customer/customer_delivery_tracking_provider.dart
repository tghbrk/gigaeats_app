import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// TODO: Restore when CustomerDeliveryTrackingService is implemented
// import '../../data/services/customer_delivery_tracking_service.dart';
import '../../../../core/utils/logger.dart';

/// Provider for CustomerDeliveryTrackingService
// TODO: Restore when CustomerDeliveryTrackingService and DeliveryTrackingInfo are implemented
// final customerDeliveryTrackingServiceProvider = Provider<CustomerDeliveryTrackingService>((ref) {
//   return CustomerDeliveryTrackingService();
// });

/// State for customer delivery tracking
class CustomerDeliveryTrackingState {
  // TODO: Restore when DeliveryTrackingInfo is implemented
  // final DeliveryTrackingInfo? trackingInfo;
  final dynamic trackingInfo;
  final bool isLoading;
  final String? error;
  final bool isTracking;
  final List<LatLng> routePoints;
  final Set<Marker> markers;
  final Set<Polyline> polylines;

  const CustomerDeliveryTrackingState({
    this.trackingInfo,
    this.isLoading = false,
    this.error,
    this.isTracking = false,
    this.routePoints = const [],
    this.markers = const {},
    this.polylines = const {},
  });

  CustomerDeliveryTrackingState copyWith({
    // TODO: Restore when DeliveryTrackingInfo is implemented
    dynamic trackingInfo,
    bool? isLoading,
    String? error,
    bool? isTracking,
    List<LatLng>? routePoints,
    Set<Marker>? markers,
    Set<Polyline>? polylines,
  }) {
    return CustomerDeliveryTrackingState(
      trackingInfo: trackingInfo ?? this.trackingInfo,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isTracking: isTracking ?? this.isTracking,
      routePoints: routePoints ?? this.routePoints,
      markers: markers ?? this.markers,
      polylines: polylines ?? this.polylines,
    );
  }
}

/// Notifier for customer delivery tracking
// TODO: Restore when CustomerDeliveryTrackingService and DeliveryTrackingInfo are implemented
class CustomerDeliveryTrackingNotifier extends StateNotifier<CustomerDeliveryTrackingState> {
  // final CustomerDeliveryTrackingService _trackingService;
  final AppLogger _logger = AppLogger();

  // StreamSubscription<DeliveryTrackingInfo?>? _trackingSubscription;
  String? _currentOrderId;

  // TODO: Restore when CustomerDeliveryTrackingService is implemented
  // CustomerDeliveryTrackingNotifier(this._trackingService) : super(const CustomerDeliveryTrackingState());
  CustomerDeliveryTrackingNotifier() : super(const CustomerDeliveryTrackingState());

  /// Start tracking an order
  // TODO: Restore when CustomerDeliveryTrackingService is implemented
  Future<void> startTracking(String orderId) async {
    try {
      _logger.info('CustomerDeliveryTrackingNotifier: Starting tracking for order $orderId');

      // Stop any existing tracking
      // await stopTracking();

      _currentOrderId = orderId;
      state = state.copyWith(isLoading: true, error: null);

      // TODO: Implement when service is available
      // Get initial tracking info
      // final initialInfo = await _trackingService.getOrderDeliveryTracking(orderId);
      // if (initialInfo != null) {
      //   state = state.copyWith(
      //     trackingInfo: initialInfo,
      //     isLoading: false,
      //     isTracking: true,
      //   );
      //   await _updateMapData();
      // }

      // Start real-time tracking
      // _trackingSubscription = _trackingService.trackOrderRealtime(orderId).listen(
      //   (trackingInfo) async {
      //     if (trackingInfo != null) {
      //       state = state.copyWith(
      //         trackingInfo: trackingInfo,
      //         isLoading: false,
      //         error: null,
      //       );
      //       await _updateMapData();
      //     }
      //   },
      //   onError: (error) {
      //     _logger.error('CustomerDeliveryTrackingNotifier: Tracking stream error', error);
      //     state = state.copyWith(
      //       error: error.toString(),
      //       isLoading: false,
      //     );
      //   },
      // );

      state = state.copyWith(isLoading: false, isTracking: false);
    } catch (e) {
      _logger.error('CustomerDeliveryTrackingNotifier: Error starting tracking', e);
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
        isTracking: false,
      );
    }
  }

  /// Stop tracking
  // TODO: Restore when tracking services are implemented
  Future<void> stopTracking() async {
    try {
      // _trackingSubscription?.cancel();
      // _trackingSubscription = null;
      // _trackingService.stopTracking();
      
      state = state.copyWith(
        isTracking: false,
        trackingInfo: null,
        routePoints: [],
        markers: {},
        polylines: {},
      );
      
      _currentOrderId = null;
      _logger.info('CustomerDeliveryTrackingNotifier: Tracking stopped');
    } catch (e) {
      _logger.error('CustomerDeliveryTrackingNotifier: Error stopping tracking', e);
    }
  }

  /// Update map data (markers, polylines)
  // ignore: unused_element
  Future<void> _updateMapData() async {
    try {
      final trackingInfo = state.trackingInfo;
      if (trackingInfo == null) return;

      final markers = <Marker>{};
      final polylines = <Polyline>{};

      // Add driver marker
      final driverLocation = trackingInfo.currentDriverLocation;
      if (driverLocation != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('driver'),
            position: driverLocation,
            infoWindow: InfoWindow(
              title: 'Driver: ${trackingInfo.driver.name}',
              snippet: 'On the way to you',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
      }

      // Add delivery destination marker
      final deliveryLocation = trackingInfo.deliveryDestination;
      if (deliveryLocation != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('delivery'),
            position: deliveryLocation,
            infoWindow: const InfoWindow(
              title: 'Delivery Address',
              snippet: 'Your order will be delivered here',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );

        // Add route polyline
        if (driverLocation != null) {
          // TODO: Restore when tracking service is implemented
          // final routePoints = await _trackingService.getDeliveryRoute(_currentOrderId!);
          final routePoints = <LatLng>[]; // Temporary empty list
          if (routePoints.isNotEmpty) {
            polylines.add(
              Polyline(
                polylineId: const PolylineId('delivery_route'),
                points: routePoints,
                color: const Color(0xFF4CAF50),
                width: 4,
                patterns: [PatternItem.dash(20), PatternItem.gap(10)],
              ),
            );
          }

          state = state.copyWith(
            routePoints: routePoints,
            markers: markers,
            polylines: polylines,
          );
        }
      }
    } catch (e) {
      _logger.error('CustomerDeliveryTrackingNotifier: Error updating map data', e);
    }
  }

  /// Refresh tracking data
  Future<void> refresh() async {
    if (_currentOrderId != null) {
      await startTracking(_currentOrderId!);
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}

/// Provider for customer delivery tracking
// TODO: Restore when customerDeliveryTrackingServiceProvider is implemented
final customerDeliveryTrackingProvider = StateNotifierProvider.autoDispose<CustomerDeliveryTrackingNotifier, CustomerDeliveryTrackingState>((ref) {
  // final trackingService = ref.watch(customerDeliveryTrackingServiceProvider);
  // return CustomerDeliveryTrackingNotifier(trackingService);
  return CustomerDeliveryTrackingNotifier();
});

/// Provider for tracking a specific order
// TODO: Restore when customerDeliveryTrackingServiceProvider is implemented
final orderTrackingProvider = StateNotifierProvider.family.autoDispose<CustomerDeliveryTrackingNotifier, CustomerDeliveryTrackingState, String>((ref, orderId) {
  // final trackingService = ref.watch(customerDeliveryTrackingServiceProvider);
  // final notifier = CustomerDeliveryTrackingNotifier(trackingService);
  final notifier = CustomerDeliveryTrackingNotifier();

  // Auto-start tracking when provider is created
  Future.microtask(() => notifier.startTracking(orderId));

  return notifier;
});

/// Provider for checking if an order is trackable
// TODO: Restore when customerDeliveryTrackingServiceProvider is implemented
final orderTrackableProvider = FutureProvider.family<bool, String>((ref, orderId) async {
  // final trackingService = ref.watch(customerDeliveryTrackingServiceProvider);
  // final trackingInfo = await trackingService.getOrderDeliveryTracking(orderId);
  // return trackingInfo != null && trackingInfo.latestTracking != null;
  return false; // Temporarily return false until service is implemented
});

/// Provider for delivery ETA
final deliveryETAProvider = Provider.family<String?, String>((ref, orderId) {
  final trackingState = ref.watch(orderTrackingProvider(orderId));
  return trackingState.trackingInfo?.estimatedTimeRemaining;
});

/// Provider for driver location
final driverLocationProvider = Provider.family<LatLng?, String>((ref, orderId) {
  final trackingState = ref.watch(orderTrackingProvider(orderId));
  return trackingState.trackingInfo?.currentDriverLocation;
});

/// Provider for checking if driver is currently tracking
final isDriverTrackingProvider = Provider.family<bool, String>((ref, orderId) {
  final trackingState = ref.watch(orderTrackingProvider(orderId));
  return trackingState.trackingInfo?.isDriverTracking ?? false;
});
